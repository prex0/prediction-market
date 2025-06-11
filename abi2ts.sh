#!/bin/bash

# パラメータ確認
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <input_dir> <output_dir>"
  exit 1
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"

# 入力フォルダの存在確認
if [ ! -d "$INPUT_DIR" ]; then
  echo "❌ Error: Input directory '$INPUT_DIR' does not exist."
  exit 1
fi

# 出力フォルダを作成（なければ）
mkdir -p "$OUTPUT_DIR"

# 各JSONファイルを処理
for file in "$INPUT_DIR"/*.json; do
  filename=$(basename -- "$file")            # 例: OrderExecutor.json
  name="${filename%.*}"                      # 例: OrderExecutor
  varname=$(echo "$name" | tr '-' '_' | tr '[:lower:]' '[:upper:]')_ABI

  output_file="$OUTPUT_DIR/$name.ts"

  # jq -c で1行のJSONとして読み取り → 変数に格納
  json=$(jq -c . "$file")

  # export 文全体を1行で書き出す
  echo "export const $varname = $json as const;" > "$output_file"

  echo "✅ Converted $filename → $output_file"
done