
# シンプル予測市場

## 概要

シンプル予測市場は、ユーザーが予測市場を作成し、参加できる分散型アプリケーションです。ユーザーは指定されたオプションにベットし、市場が終了した後、勝利したオプションにベットしたユーザーのみが報酬を受け取ります。オラクルが設定されずに`oracleDuration`が経過した場合、市場は期限切れとなり、解約可能です。

## 特徴

- **市場の作成**: ユーザーはトークン、名前、説明、期限、オプション、エントリー金額、オラクル期間などのカスタムパラメータで予測市場を作成できます。
- **ベッティング**: 参加者は市場内の異なるオプションにベットを行うことができます。
- **市場のステータス**: 市場は、NotStarted、Active、Closed、OracleTimedOutの様々なステータスを経て遷移します。
- **オラクル統合**: 指定された期間内にオラクルが設定されない場合、市場は期限切れとなります。

## コントラクト

### SimplePredictionMarket.sol

- **市場管理**: 予測市場の作成と管理を行います。
- **ベッティングロジック**: ユーザーがベットを行い、報酬の分配を管理します。
- **セキュリティ**: `ReentrancyGuardUpgradeable`を使用してリエントランシー攻撃を防ぎます。

### ライブラリ

- **AmountMathLib**: 精度を持った金額を扱うための数学関数を提供します。
- **LMSRLib**: 予測市場のためのLMSRコスト関数と価格設定を実装します。

## デプロイ

デプロイスクリプト`DeploySimplePredictionMarketScript`は、透明なアップグレード可能なプロキシパターンを使用して`SimplePredictionMarket`コントラクトをデプロイするために使用されます。スクリプトは検証のためにデプロイされたコントラクトのアドレスをログに記録します。

## 使用方法

コントラクトのABIを抽出するには、`abi.sh`スクリプトを使用します。



