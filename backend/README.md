# Backend - 学習管理アプリ API

FastAPI + AWS Lambda で構築されたサーバーレスバックエンド API です。

---

## 📑 目次

1. [プロジェクト概要](#1-プロジェクト概要)
2. [技術スタック](#2-技術スタック)
3. [ディレクトリ構成](#3-ディレクトリ構成)
4. [前提条件](#4-前提条件)
5. [セットアップ](#5-セットアップ)
6. [開発](#6-開発)
7. [テスト](#7-テスト)
8. [デプロイ](#8-デプロイ)
9. [API仕様](#9-api仕様)
10. [データベース](#10-データベース)
11. [環境変数](#11-環境変数)
12. [トラブルシューティング](#12-トラブルシューティング)

---

## 1. プロジェクト概要

学習ログの作成・管理・統計表示を行うREST APIです。

### 主な機能

- **学習ログ管理**: CRUD操作（作成・読取・更新・削除）
- **統計情報**: 期間指定での合計時間・理解度内訳
- **認証**: Amazon Cognito JWT検証
- **データ永続化**: DynamoDB

### API エンドポイント

- `POST /v1/logs` - 学習ログ作成
- `GET /v1/logs` - 一覧取得（期間・タグフィルタ対応）
- `GET /v1/logs/{log_id}` - 詳細取得
- `PUT /v1/logs/{log_id}` - 更新
- `DELETE /v1/logs/{log_id}` - 削除
- `GET /v1/stats/summary` - 統計情報取得
- `GET /v1/me` - プロフィール取得

---

## 2. 技術スタック

| カテゴリ | 技術 |
|---------|------|
| **Framework** | FastAPI 0.104+ |
| **Runtime** | Python 3.11+ |
| **Database** | DynamoDB |
| **Authentication** | Amazon Cognito (JWT) |
| **Deployment** | AWS Lambda + API Gateway (Mangum) |
| **Testing** | pytest + pytest-asyncio |
| **Validation** | Pydantic v2 |
| **Linter/Formatter** | Ruff + Black |

---

## 3. ディレクトリ構成

```
backend/
├── apis/                       # FastAPI アプリケーション
│   ├── app/
│   │   ├── main.py            # FastAPI エントリーポイント
│   │   ├── handler.py         # Lambda ハンドラー (Mangum)
│   │   ├── deps.py            # 依存性注入 (認証など)
│   │   ├── models.py          # Pydantic モデル
│   │   ├── routers/           # API ルーター
│   │   │   ├── logs.py        # /v1/logs エンドポイント
│   │   │   ├── stats.py       # /v1/stats エンドポイント
│   │   │   └── me.py          # /v1/me エンドポイント
│   │   ├── repos/             # データアクセス層
│   │   │   └── dynamodb.py    # DynamoDB 操作
│   │   └── core/              # 共通設定
│   │       ├── config.py      # 環境変数・設定
│   │       └── logging.py     # ログ設定
│   ├── tests/                 # テストコード
│   │   ├── conftest.py        # pytest fixtures
│   │   ├── test_logs.py       # ログAPI テスト
│   │   └── test_stats.py      # 統計API テスト
│   ├── requirements.txt       # 本番依存関係
│   └── requirements-dev.txt   # 開発用依存関係
│
└── infra/                     # インフラ (Terraform)
    ├── _shared/               # 共通 Terraform コード
    ├── dev/                   # Dev 環境
    ├── prod/                  # Prod 環境
    └── modules/               # Terraform モジュール
        ├── cognito/           # Cognito User Pool
        ├── api_lambda/        # Lambda + API Gateway
        └── dynamodb/          # DynamoDB テーブル
```

---

## 4. 前提条件

### 必須

- **Python**: >= 3.11
- **pip**: 最新版
- **AWS CLI**: 最新版 (デプロイ時)
- **Terraform**: >= 1.5.0 (インフラ構築時)

### 推奨

- **pyenv**: Python バージョン管理
  ```bash
  pyenv install 3.11
  pyenv local 3.11
  ```

- **venv**: 仮想環境
  ```bash
  python -m venv .venv
  source .venv/bin/activate  # macOS/Linux
  ```

### バージョン確認

```bash
python --version
pip --version
aws --version
terraform --version
```

---

## 5. セットアップ

### 5.1 リポジトリのクローン

```bash
git clone <repository-url>
cd study_app/backend/apis
```

### 5.2 仮想環境の作成と有効化

```bash
# 仮想環境作成
python -m venv .venv

# 有効化
source .venv/bin/activate  # macOS/Linux
# または
.venv\Scripts\activate     # Windows
```

### 5.3 依存関係のインストール

```bash
# 本番 + 開発用依存関係
pip install -r requirements.txt -r requirements-dev.txt

# または本番のみ
pip install -r requirements.txt
```

### 5.4 環境変数の設定

`.env` ファイルを作成（ローカル開発用）:

```bash
# backend/apis/.env
AWS_REGION=ap-northeast-1
DYNAMODB_TABLE_NAME=study-app-learning-logs-dev
COGNITO_USER_POOL_ID=ap-northeast-1_XXXXXXXXX
COGNITO_APP_CLIENT_ID=XXXXXXXXXXXXXXXXXXXXXXXXXX
LOG_LEVEL=DEBUG
```

---

## 6. 開発

### 6.1 ローカルサーバーの起動

```bash
cd backend/apis
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

サーバーが起動したら以下にアクセス:

- **API**: http://localhost:8000/v1
- **ドキュメント (Swagger UI)**: http://localhost:8000/docs
- **ドキュメント (ReDoc)**: http://localhost:8000/redoc

### 6.2 開発フロー

1. **コードを編集**
   - `app/routers/` でエンドポイント追加
   - `app/repos/` でデータアクセス実装
   - `app/models.py` でPydanticモデル定義

2. **Linterでチェック**
   ```bash
   ruff check .
   ```

3. **フォーマット**
   ```bash
   black .
   ```

4. **テスト実行**
   ```bash
   pytest
   ```

5. **動作確認**
   - Swagger UI (`/docs`) で手動テスト
   - または `curl` / `httpie` でテスト

---

## 7. テスト

### 7.1 全テスト実行

```bash
cd backend/apis
pytest
```

### 7.2 特定のテストを実行

```bash
# ログAPIのテストのみ
pytest tests/test_logs.py

# 特定のテスト関数
pytest tests/test_logs.py::test_create_log
```

### 7.3 カバレッジ測定

```bash
pytest --cov=app --cov-report=html
open htmlcov/index.html
```

### 7.4 テストオプション

```bash
# 詳細出力
pytest -v

# 失敗時に停止
pytest -x

# 並列実行
pytest -n auto
```

---

## 8. デプロイ

### 8.1 インフラのデプロイ

#### 初回: Terraform State用S3バケット作成

```bash
aws s3 mb s3://study-app-backend-tfstate-dev
aws s3api put-bucket-versioning \
  --bucket study-app-backend-tfstate-dev \
  --versioning-configuration Status=Enabled
```

#### インフラ構築

```bash
cd backend/infra/dev
terraform init
terraform plan
terraform apply
```

### 8.2 Lambda関数のデプロイ

#### 方法1: デプロイスクリプト（作成予定）

```bash
cd backend/apis
./deploy.sh dev
```

#### 方法2: 手動デプロイ

```bash
# 1. 依存関係をパッケージング
cd backend/apis
pip install -r requirements.txt -t package/
cp -r app package/

# 2. ZIP作成
cd package
zip -r ../lambda_function.zip .

# 3. Lambda更新
aws lambda update-function-code \
  --function-name study-app-api-dev \
  --zip-file fileb://../lambda_function.zip
```

---

## 9. API仕様

### 認証

すべてのエンドポイントは Cognito JWT が必要です。

```http
Authorization: Bearer <JWT_TOKEN>
```

### エンドポイント一覧

#### POST /v1/logs - 学習ログ作成

```http
POST /v1/logs
Content-Type: application/json
Authorization: Bearer <JWT>

{
  "start_time": "2025-11-08T09:00:00Z",
  "end_time": "2025-11-08T10:15:00Z",
  "what": "React useEffect",
  "understanding": "partial",
  "did_well": "基本的な使い方は理解できた",
  "didnt_get": "依存配列の扱いが不明確",
  "tags": ["react", "hooks"]
}
```

**レスポンス**:
```json
{
  "log_id": "01HKJM9Q5Z8X7Y6W5V4T3S2R1P",
  "user_id": "cognito-sub-id",
  "start_time": "2025-11-08T09:00:00Z",
  "end_time": "2025-11-08T10:15:00Z",
  "duration_min": 75,
  "what": "React useEffect",
  "understanding": "partial",
  "did_well": "基本的な使い方は理解できた",
  "didnt_get": "依存配列の扱いが不明確",
  "tags": ["react", "hooks"],
  "created_at": "2025-11-08T10:20:00Z",
  "updated_at": "2025-11-08T10:20:00Z"
}
```

#### GET /v1/logs - 一覧取得

```http
GET /v1/logs?from=2025-11-01&to=2025-11-30&tag=react&limit=20
Authorization: Bearer <JWT>
```

#### GET /v1/stats/summary - 統計情報

```http
GET /v1/stats/summary?from=2025-11-01&to=2025-11-30
Authorization: Bearer <JWT>
```

**レスポンス**:
```json
{
  "total_duration_min": 450,
  "log_count": 6,
  "understanding_breakdown": {
    "understood": 2,
    "partial": 3,
    "not_understood": 1
  }
}
```

詳細は **Swagger UI** (`http://localhost:8000/docs`) を参照してください。

---

## 10. データベース

### DynamoDB テーブル設計

**テーブル名**: `study-app-learning-logs-{env}`

| 属性 | 型 | 説明 |
|------|----|----|
| `log_id` | String (PK) | ULID |
| `user_id` | String | Cognito sub |
| `start_time` | String | ISO8601 |
| `end_time` | String | ISO8601 |
| `duration_min` | Number | 分単位 |
| `what` | String | 学習内容 |
| `understanding` | String | `understood` / `partial` / `not_understood` |
| `did_well` | String | うまくいったこと |
| `didnt_get` | String | 理解できなかったこと |
| `tags` | List | タグ配列 |
| `created_at` | String | ISO8601 |
| `updated_at` | String | ISO8601 |

### GSI (Global Secondary Index)

**GSI1**: `user_id` (PK) + `start_time` (SK)
- 用途: ユーザーごとの学習ログを時系列で取得

---

## 11. 環境変数

### ローカル開発 (`.env`)

```bash
AWS_REGION=ap-northeast-1
DYNAMODB_TABLE_NAME=study-app-learning-logs-dev
COGNITO_USER_POOL_ID=ap-northeast-1_XXXXXXXXX
COGNITO_APP_CLIENT_ID=XXXXXXXXXXXXXXXXXXXXXXXXXX
LOG_LEVEL=DEBUG
CORS_ORIGINS=http://localhost:3000
```

### Lambda環境 (Terraform管理)

Lambda環境変数はTerraformで設定:

```hcl
# backend/infra/modules/api_lambda/main.tf
environment {
  variables = {
    DYNAMODB_TABLE_NAME    = var.dynamodb_table_name
    COGNITO_USER_POOL_ID   = var.cognito_user_pool_id
    COGNITO_APP_CLIENT_ID  = var.cognito_app_client_id
    LOG_LEVEL              = var.log_level
  }
}
```

---

## 12. トラブルシューティング

### Import Error: ModuleNotFoundError

```bash
# 仮想環境を有効化
source .venv/bin/activate

# 依存関係を再インストール
pip install -r requirements.txt
```

### DynamoDB接続エラー

```bash
# AWS認証情報を確認
aws sts get-caller-identity

# プロファイルを設定
export AWS_PROFILE=your-profile-name

# リージョンを確認
export AWS_REGION=ap-northeast-1
```

### Cognito JWT検証エラー

```bash
# 環境変数を確認
echo $COGNITO_USER_POOL_ID
echo $COGNITO_APP_CLIENT_ID

# JWTトークンをデコード（デバッグ用）
# https://jwt.io でトークンを確認
```

### Lambda デプロイエラー

```bash
# パッケージサイズを確認（250MB制限）
du -sh lambda_function.zip

# 不要な依存関係を除外
pip install --no-deps -r requirements.txt -t package/
```

---

## 📚 関連ドキュメント

- [ルートREADME](../README.md) - プロジェクト全体の概要
- [CLAUDE.md](../CLAUDE.md) - AI開発者向けガイド
- [front/README.md](../front/README.md) - フロントエンド開発ガイド
- [FastAPI ドキュメント](https://fastapi.tiangolo.com/ja/)
- [AWS Lambda Python](https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/lambda-python.html)

---

## 📝 開発ガイドライン

### コーディング規約

- **型ヒント必須**: すべての関数に型アノテーションを付ける
- **Pydantic活用**: リクエスト/レスポンスはPydanticモデルで定義
- **例外処理**: 適切なHTTPExceptionを返す
- **ログ出力**: 重要な処理はログに記録

### 命名規則

- **関数**: `snake_case`
- **クラス**: `PascalCase`
- **定数**: `UPPER_SNAKE_CASE`
- **プライベート**: `_leading_underscore`

### コミットメッセージ

```bash
feat(api): add GET /v1/stats endpoint
fix(db): handle empty query results
refactor(auth): extract JWT validation logic
test(logs): add test for DELETE endpoint
```

---

## ライセンス

このプロジェクトのライセンスは LICENSE ファイルに従います。
