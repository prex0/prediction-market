#!/bin/bash

# Usage: ./extract_abi.sh <ContractName> <OutputPath>

# 引数チェック
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <ContractName> <OutputPath>"
  exit 1
fi

CONTRACT_NAME="$1"
OUTPUT_PATH="$2"

# forge inspect を使って ABI を出力
forge inspect "$CONTRACT_NAME" abi --json > "$OUTPUT_PATH/$CONTRACT_NAME.json"

# 結果確認
if [ $? -eq 0 ]; then
  echo "✅ ABI for $CONTRACT_NAME written to $OUTPUT_PATH/$CONTRACT_NAME.json"
else
  echo "❌ Failed to extract ABI for $CONTRACT_NAME"
fi