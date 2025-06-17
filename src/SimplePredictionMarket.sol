// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "../lib/solmate/src/utils/SafeTransferLib.sol";
import {BaseDispatcher} from "./base/BaseDispatcher.sol";
import {ICreditToken} from "./interface/ICreditToken.sol";
import {AmountMathLib} from "./lib/AmountMathLib.sol";
import {ReentrancyGuardUpgradeable} from
    "../lib/openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {LMSRLib} from "./lib/LMSRLib.sol";

struct CreatePredictionMarketParams {
    address token;
    string name;
    string description;
    uint256 expiry;
    string[] options;
    uint256 entryAmount;
    uint256 oracleDuration;
}

/**
 * @title SimplePredictionMarket
 * @notice シンプルな予測市場
 * ユーザーは市場を作成し、指定された選択肢にベットすることができます。
 * 市場が終了した後は、勝利オプションにベットしたユーザーだけが報酬を受け取ることができます。
 * オラクルが設定されずに、oracleDurationが経過したら期限切れになります。
 * 期限切れになったら、解約できます。
 * NotStarted -> Active -> Closed
 *                      -> OracleTimedOut
 */
contract SimplePredictionMarket is BaseDispatcher, ReentrancyGuardUpgradeable {
    using SafeTransferLib for ERC20;

    enum MarketStatus {
        NotStarted,
        // 開始中
        Active,
        // 終了済み
        Closed,
        // オラクルが設定されずに、oracleDurationが経過したら期限切れ
        OracleTimedOut
    }

    struct PredictionMarket {
        address creator;
        address paymentToken;
        string marketName;
        string description;
        uint256 expiry;
        uint256 entryAmount;
        string[] optionLabels;
        uint256[] optionShares;
        uint256 traderBetAmount;
        MarketStatus status;
        uint8 winningOptionIndex;
        uint256 oracleDuration;
    }

    struct BetStatus {
        uint256 portion;
        uint256 betAmount;
    }

    uint256 public marketCount;

    /// @notice 予測市場の情報
    mapping(uint256 => PredictionMarket) public markets;

    /// @notice オーナーの最新の予測市場のID
    mapping(address creator => uint256 marketId) public latestMarketId;

    /// @notice ユーザーのベット情報
    mapping(uint256 marketId => mapping(address user => mapping(uint8 optionId => BetStatus))) public userBets;

    uint256 private constant PRICE_PRECISION = 1e18;

    uint256 private constant LMSR_B = 16 * 1e18;

    uint256 private constant LP_MULTIPLIER = 12;

    // errors
    error MarketNotActive();
    error MarketExpired();
    error MarketNotExpired();
    error MarketNotClosed();
    error OnlyCreator();
    error MarketNotTimedOut();
    error NoReward();
    error InvalidInput();
    error InvalidPrice();
    error SlippageExceeded();

    // events
    event PredictionMarketCreated(
        uint256 indexed marketId,
        address indexed creator,
        address indexed token,
        uint256 expiry,
        uint256 entryAmount,
        string name,
        string description
    );
    event OptionAdded(uint256 indexed marketId, uint8 optionId, string optionLabel);
    event BetPlaced(
        uint256 indexed marketId, address indexed user, uint8 optionId, uint256 stakeAmount, uint256 portion
    );
    event MarketClosed(uint256 indexed marketId, uint8 oracleIndex, uint256 lpBalance);
    event LogMarketExpired(uint256 indexed marketId);
    event RewardClaimed(uint256 indexed marketId, address indexed user, uint8 optionId, uint256 rewardAmount);
    event MarketExpiredRedeemed(uint256 indexed marketId, address indexed user, uint256 redeemAmount);
    event LiquidityProviderRedeemed(uint256 indexed marketId, address indexed user, uint256 redeemAmount);

    modifier onlyCreator(uint256 marketId) {
        if (markets[marketId].creator != msg.sender) {
            revert OnlyCreator();
        }
        _;
    }

    constructor() {}

    /**
     * @notice 初期化する
     * @param _creditToken クレジットトークンのアドレス
     * @param _owner オーナーのアドレス
     */
    function initialize(address _creditToken, address _owner) public initializer {
        __BaseDispatcher_init(_owner, _creditToken);
        __ReentrancyGuard_init();

        creditPrice = 0;

        marketCount = 1;
    }

    function getMarket(uint256 marketId) public view returns (PredictionMarket memory) {
        return markets[marketId];
    }

    /**
     * @notice ベットするためのコストを取得する
     * @param marketId 予測市場のID
     * @param oracleIndex 正解のオラクルインデックス
     * @return ベットするためのコスト
     */
    function getPurchaseCost(uint256 marketId, uint8 oracleIndex, uint256 portion) public view returns (uint256) {
        return _getPurchaseCost(marketId, oracleIndex, portion);
    }

    /**
     * @notice ベットするためのコストを取得する
     * @param marketId 予測市場のID
     * @param oracleIndex 正解のオラクルインデックス
     * @return ベットするためのコスト
     */
    function _getPurchaseCost(uint256 marketId, uint8 oracleIndex, uint256 portion) internal view returns (uint256) {
        PredictionMarket memory market = markets[marketId];

        // Create arrays for current and future states
        uint256[] memory quantityBefore = new uint256[](market.optionShares.length);
        uint256[] memory quantityAfter = new uint256[](market.optionShares.length);

        // Copy current shares
        for (uint256 i = 0; i < market.optionShares.length; i++) {
            quantityBefore[i] = market.optionShares[i];
            quantityAfter[i] = market.optionShares[i];
        }

        // Add portion to the selected option
        quantityAfter[oracleIndex] += portion;

        uint256 costBefore = LMSRLib.calcCost(quantityBefore, LMSR_B);
        uint256 costAfter = LMSRLib.calcCost(quantityAfter, LMSR_B);

        return costAfter - costBefore;
    }

    /**
     * @notice 流動性提供者の残高を計算する
     * @param marketId 予測市場のID
     * @return 流動性提供者の残高
     */
    function _calcLiquidityProviderBalance(uint256 marketId) internal view returns (uint256) {
        PredictionMarket memory market = markets[marketId];

        // 勝者に支払う報酬
        uint256 reward = market.optionShares[market.winningOptionIndex] * market.entryAmount / PRICE_PRECISION;

        return market.entryAmount * LP_MULTIPLIER + market.traderBetAmount - reward;
    }

    /**
     * @notice 予測市場を作成する
     * @param params 予測市場のパラメータ
     * @return 予測市場のID
     */
    function createPredictionMarket(CreatePredictionMarketParams memory params) public nonReentrant returns (uint256) {
        // オプションが2つ以上必要
        if (params.options.length < 2) {
            revert InvalidInput();
        }

        // 10ファントークン以上必要
        if (params.entryAmount < 10 * 1e18) {
            revert InvalidInput();
        }

        // 1時間以上必要
        if (params.expiry < block.timestamp + 1 hours) {
            revert InvalidInput();
        }

        _consumeCredit(creditPrice);

        uint256 marketId = marketCount++;

        address creator = msg.sender;

        markets[marketId].creator = creator;
        markets[marketId].paymentToken = params.token;
        markets[marketId].marketName = params.name;
        markets[marketId].description = params.description;
        markets[marketId].expiry = params.expiry;
        markets[marketId].oracleDuration = params.oracleDuration;
        markets[marketId].entryAmount = params.entryAmount;
        markets[marketId].optionLabels = params.options;
        markets[marketId].optionShares = new uint256[](params.options.length);
        markets[marketId].status = MarketStatus.Active;

        latestMarketId[creator] = marketId;

        emit PredictionMarketCreated(
            marketId, creator, params.token, params.expiry, params.entryAmount, params.name, params.description
        );

        for (uint8 i = 0; i < params.options.length; i++) {
            emit OptionAdded(marketId, i, params.options[i]);
        }

        ERC20(params.token).safeTransferFrom(msg.sender, address(this), params.entryAmount * LP_MULTIPLIER);

        return marketId;
    }

    /**
     * @notice 予測市場にベットする
     * @param marketId 予測市場のID
     * @param optionId ベットするオプションのID
     * @param portion ベットする部分
     * @param maxCost 支払い可能な最大コスト（スリッページ保護）
     */
    function bet(uint256 marketId, uint8 optionId, uint256 portion, uint256 maxCost) public nonReentrant {
        PredictionMarket memory market = markets[marketId];

        if (market.status != MarketStatus.Active) {
            revert MarketNotActive();
        }

        if (block.timestamp > market.expiry) {
            revert MarketExpired();
        }

        _bet(marketId, optionId, portion, maxCost);
    }

    function _bet(uint256 marketId, uint8 optionId, uint256 portion, uint256 maxCost) internal {
        PredictionMarket storage market = markets[marketId];

        if (optionId >= market.optionLabels.length) {
            revert InvalidInput();
        }

        uint256 currentPrice = _getPurchaseCost(marketId, optionId, portion);

        uint256 entryAmount = AmountMathLib.ceil(currentPrice * market.entryAmount / PRICE_PRECISION, 1e18);

        if (entryAmount > maxCost) {
            revert SlippageExceeded();
        }

        __bet(marketId, msg.sender, optionId, portion, entryAmount);
    }

    function __bet(uint256 marketId, address user, uint8 optionId, uint256 portion, uint256 stakeAmount) internal {
        PredictionMarket storage market = markets[marketId];
        BetStatus storage betStatus = userBets[marketId][user][optionId];

        market.optionShares[optionId] += portion;
        market.traderBetAmount += stakeAmount;
        betStatus.betAmount += stakeAmount;
        betStatus.portion += portion;

        ERC20(market.paymentToken).safeTransferFrom(user, address(this), stakeAmount);

        emit BetPlaced(marketId, user, optionId, stakeAmount, portion);
    }

    /**
     * @notice 予測市場を閉じる
     * @param marketId 予測市場のID
     * @param oracleIndex 正解のオラクルインデックス
     */
    function closeMarket(uint256 marketId, uint8 oracleIndex) public nonReentrant onlyCreator(marketId) {
        PredictionMarket storage market = markets[marketId];

        if (market.status != MarketStatus.Active) {
            revert MarketNotActive();
        }

        if (block.timestamp < market.expiry) {
            revert MarketNotExpired();
        }

        if (oracleIndex >= market.optionLabels.length) {
            revert InvalidInput();
        }

        market.status = MarketStatus.Closed;
        market.winningOptionIndex = oracleIndex;

        // マーケット作成者が、資金を回収する
        uint256 lpBalance = AmountMathLib.ceil(_calcLiquidityProviderBalance(marketId), 1e18);

        ERC20(market.paymentToken).safeTransfer(msg.sender, lpBalance);

        emit MarketClosed(marketId, oracleIndex, lpBalance);
    }

    /**
     * @notice 報酬を請求する
     * @param marketId 予測市場のID
     */
    function claimReward(uint256 marketId) public nonReentrant {
        PredictionMarket memory market = markets[marketId];

        address user = msg.sender;

        if (market.status != MarketStatus.Closed) {
            revert MarketNotClosed();
        }

        uint256 portion = userBets[marketId][user][market.winningOptionIndex].portion;

        if (portion == 0) {
            revert NoReward();
        }

        uint256 redeemAmount = portion * market.entryAmount / PRICE_PRECISION;

        userBets[marketId][user][market.winningOptionIndex].portion = 0;
        userBets[marketId][user][market.winningOptionIndex].betAmount = 0;

        ERC20(market.paymentToken).safeTransfer(user, redeemAmount);

        emit RewardClaimed(marketId, user, market.winningOptionIndex, redeemAmount);
    }

    /**
     * @notice 期限切れになった予測市場を解約する
     * @param marketId 予測市場のID
     */
    function redeem(uint256 marketId) public nonReentrant {
        _expireMarketIfNeeded(marketId);

        PredictionMarket memory market = markets[marketId];

        address user = msg.sender;

        if (market.status != MarketStatus.OracleTimedOut) {
            revert MarketNotTimedOut();
        }

        uint256 betAmount = 0;

        for (uint8 i = 0; i < market.optionLabels.length; i++) {
            betAmount += userBets[marketId][user][i].betAmount;
        }

        if (betAmount == 0) {
            revert InvalidInput();
        }

        for (uint8 i = 0; i < market.optionLabels.length; i++) {
            userBets[marketId][user][i].portion = 0;
            userBets[marketId][user][i].betAmount = 0;
        }

        ERC20(market.paymentToken).safeTransfer(user, betAmount);

        emit MarketExpiredRedeemed(marketId, user, betAmount);
    }

    /**
     * @notice 流動性提供者がLPを解約する
     * @param marketId 予測市場のID
     */
    function redeemLiquidityProvider(uint256 marketId) public nonReentrant {
        _expireMarketIfNeeded(marketId);

        PredictionMarket memory market = markets[marketId];

        address user = msg.sender;

        if (market.status != MarketStatus.OracleTimedOut) {
            revert MarketNotTimedOut();
        }

        if (market.creator != user) {
            revert OnlyCreator();
        }

        uint256 lpBalance = market.entryAmount * LP_MULTIPLIER;

        ERC20(market.paymentToken).safeTransfer(user, lpBalance);

        emit LiquidityProviderRedeemed(marketId, user, lpBalance);
    }

    /**
     * @notice 予測市場を期限切れにする
     * Activeから遷移する
     * @param marketId 予測市場のID
     */
    function _expireMarketIfNeeded(uint256 marketId) internal {
        PredictionMarket storage market = markets[marketId];

        if (market.status != MarketStatus.Active && market.status != MarketStatus.OracleTimedOut) {
            revert MarketNotActive();
        }

        if (block.timestamp < market.expiry + market.oracleDuration) {
            revert MarketNotTimedOut();
        }

        if (market.status == MarketStatus.Active) {
            market.status = MarketStatus.OracleTimedOut;
            emit LogMarketExpired(marketId);
        }
    }
}
