#!/bin/bash
set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 使用方法
usage() {
  echo "使用方法: $0 <env> [--with-infra]"
  echo ""
  echo "引数:"
  echo "  env           デプロイ先環境 (dev または prod)"
  echo "  --with-infra  インフラも含めてデプロイ (オプション)"
  echo ""
  echo "例:"
  echo "  $0 dev                    # フロントエンドのみデプロイ"
  echo "  $0 dev --with-infra       # インフラ + フロントエンドをデプロイ"
  echo "  $0 prod --with-infra      # 本番環境のインフラ + フロントエンドをデプロイ"
  exit 1
}

# 引数チェック
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  echo -e "${RED}エラー: 引数が不正です${NC}"
  usage
fi

ENV=$1
WITH_INFRA=false

# オプション解析
if [ $# -eq 2 ]; then
  if [ "$2" == "--with-infra" ]; then
    WITH_INFRA=true
  else
    echo -e "${RED}エラー: 不正なオプションです: $2${NC}"
    usage
  fi
fi

# 環境の検証
if [ "$ENV" != "dev" ] && [ "$ENV" != "prod" ]; then
  echo -e "${RED}エラー: 環境は 'dev' または 'prod' を指定してください${NC}"
  usage
fi

# 設定
BUCKET_NAME="study-app-front-${ENV}"
INFRA_DIR="./infra/${ENV}"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Frontend デプロイ: ${ENV} 環境${NC}"
if [ "$WITH_INFRA" = true ]; then
  echo -e "${GREEN}モード: インフラ + フロントエンド${NC}"
else
  echo -e "${GREEN}モード: フロントエンドのみ${NC}"
fi
echo -e "${GREEN}========================================${NC}"
echo ""

# インフラのデプロイ（--with-infraオプション指定時のみ）
if [ "$WITH_INFRA" = true ]; then
  echo -e "${YELLOW}[1/6] インフラをデプロイ中...${NC}"

  if [ ! -d "$INFRA_DIR" ]; then
    echo -e "${RED}エラー: インフラディレクトリが見つかりません: ${INFRA_DIR}${NC}"
    exit 1
  fi

  cd "$INFRA_DIR"

  # Terraform初期化
  echo "terraform init を実行中..."
  terraform init

  # Terraform plan
  echo ""
  echo "terraform plan を実行中..."
  terraform plan -out=tfplan

  # ユーザーに確認
  echo ""
  echo -e "${YELLOW}上記のTerraform planを確認してください。${NC}"
  read -p "デプロイを続行しますか? (yes/no): " confirm

  if [ "$confirm" != "yes" ]; then
    echo -e "${RED}デプロイをキャンセルしました${NC}"
    exit 1
  fi

  # Terraform apply
  echo ""
  echo "terraform apply を実行中..."
  terraform apply tfplan

  echo -e "${GREEN}✓ インフラのデプロイ完了${NC}"
  cd - > /dev/null
  echo ""

  STEP_OFFSET=1
  TOTAL_STEPS=6
else
  STEP_OFFSET=0
  TOTAL_STEPS=5
fi

# 依存関係のインストール確認
STEP=$((1 + STEP_OFFSET))
echo -e "${YELLOW}[${STEP}/${TOTAL_STEPS}] 依存関係を確認中...${NC}"
if [ ! -d "node_modules" ]; then
  echo "node_modules が見つかりません。npm install を実行します..."
  npm install
else
  echo "依存関係は既にインストール済みです"
fi
echo ""

# ビルド
STEP=$((2 + STEP_OFFSET))
echo -e "${YELLOW}[${STEP}/${TOTAL_STEPS}] フロントエンドをビルド中...${NC}"
npm run build
echo -e "${GREEN}✓ ビルド完了${NC}"
echo ""

# S3へアップロード
STEP=$((3 + STEP_OFFSET))
echo -e "${YELLOW}[${STEP}/${TOTAL_STEPS}] S3にアップロード中...${NC}"
echo "バケット: ${BUCKET_NAME}"
aws s3 sync dist/ "s3://${BUCKET_NAME}" --delete
echo -e "${GREEN}✓ S3アップロード完了${NC}"
echo ""

# CloudFront ディストリビューションIDを取得
STEP=$((4 + STEP_OFFSET))
echo -e "${YELLOW}[${STEP}/${TOTAL_STEPS}] CloudFront ディストリビューションIDを取得中...${NC}"
if [ ! -d "$INFRA_DIR" ]; then
  echo -e "${RED}エラー: インフラディレクトリが見つかりません: ${INFRA_DIR}${NC}"
  exit 1
fi

cd "$INFRA_DIR"
DISTRIBUTION_ID=$(terraform output -raw frontend_cloudfront_distribution_id 2>/dev/null)

if [ -z "$DISTRIBUTION_ID" ]; then
  echo -e "${RED}エラー: CloudFront ディストリビューションIDを取得できませんでした${NC}"
  echo "terraform output が正しく設定されているか確認してください"
  exit 1
fi

echo "ディストリビューションID: ${DISTRIBUTION_ID}"
cd - > /dev/null
echo ""

# CloudFrontキャッシュ無効化
STEP=$((5 + STEP_OFFSET))
echo -e "${YELLOW}[${STEP}/${TOTAL_STEPS}] CloudFrontキャッシュを無効化中...${NC}"
INVALIDATION_ID=$(aws cloudfront create-invalidation \
  --distribution-id "${DISTRIBUTION_ID}" \
  --paths "/*" \
  --query 'Invalidation.Id' \
  --output text)

echo "無効化ID: ${INVALIDATION_ID}"
echo -e "${GREEN}✓ キャッシュ無効化リクエスト送信完了${NC}"
echo ""

# CloudFront URLを表示
cd "$INFRA_DIR"
CLOUDFRONT_URL=$(terraform output -raw frontend_cloudfront_url 2>/dev/null)
cd - > /dev/null

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}デプロイ完了！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "アクセスURL: ${CLOUDFRONT_URL}"
echo ""
echo "※ CloudFrontのキャッシュ無効化には数分かかる場合があります"
echo ""
