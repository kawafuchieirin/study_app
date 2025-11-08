# CLAUDE.md — 学習管理アプリ

このリポジトリで AI アシスタント（Claude など）が作業する際のガイドです。**確実な情報のみ**を扱い、**わからない場合は「わからない」と答える**こと。

---

## 目的（MVP）
最小構成で「学習の記録（時間・内容・理解/未理解）」を、素早く・気持ちよく保存/閲覧できる Web アプリを作る。

### 達成条件
- ログイン後、フォームから学習ログを作成できる
- 一覧/詳細/編集/削除が可能
- 期間を指定して合計時間と理解度内訳を表示
- IaC（Terraform）で主要インフラが再現可能

### 非目標（初期）
- 複雑なレコメンド/分析
- 多人数組織機能

---

## 技術スタック
- **Front**: React + TypeScript + Vite（SPA, S3+CloudFront）
- **API**: Python + FastAPI（API Gateway + Lambda, Mangum）
- **Auth**: Amazon Cognito（User Pool, Hosted UI）
- **DB**: DynamoDB（`learning_logs` テーブル）
- **IaC**: Terraform（環境: dev/prod）
- **CI/CD**: GitHub Actions → S3/CloudFront, Lambda デプロイ

> 代替: 将来の分析用途に Aurora Serverless v2 へ移行可。現時点では DynamoDB を採用。

---

## データモデル
**User**
- `user_id` (Cognito sub)
- `display_name`
- `created_at`

**LearningLog**（1行=1学習セッション）
- `log_id` (ULID/UUID)
- `user_id`
- `start_time` (ISO8601)
- `end_time` (ISO8601)
- `duration_min` (冗長保持, 集計高速化)
- `what` (string)
- `understanding` (`understood|partial|not_understood`)
- `did_well` (string, 任意)
- `didnt_get` (string, 任意)
- `tags` (string[])
- **GSI**: GSI1=`user_id` + `start_time`（最新順）

---

## API 仕様（/v1）
- `POST /logs` — 学習ログ作成
- `GET /logs?from=&to=&tag=&limit=&next=` — 一覧（期間/タグ/ページング）
- `GET /logs/{log_id}` — 参照
- `PUT /logs/{log_id}` — 更新
- `DELETE /logs/{log_id}` — 削除
- `GET /stats/summary?from=&to=` — 集計（合計時間・理解度）
- `GET /me` — プロフィール

**認可**: API Gateway で Cognito JWT を検証。`sub` を `user_id` として使用。

### リクエスト・レスポンス例
```http
POST /v1/logs
Content-Type: application/json
Authorization: Bearer <JWT>

{
  "start_time": "2025-11-08T09:00:00Z",
  "end_time": "2025-11-08T10:15:00Z",
  "what": "React useEffect",
  "understanding": "partial",
  "didnt_get": "依存配列の扱い",
  "tags": ["react","hooks"]
}
```

---

## ディレクトリ構成（確定案）
```
/ (repo root)
  README.md              # セットアップ/開発手順/デプロイ手順
  front/                 # React + TypeScript (Vite)
    index.html
    vite.config.ts
    package.json
    src/
      main.tsx
      app/
        routes/          # 画面（/ , /logs , /stats など）
        components/      # 再利用可能なUI（UnderstandingPicker/TagInput/StatsCard等）
        hooks/
        lib/             # APIクライアント/型/ユーティリティ
      assets/
      types/
      tests/
    public/

  backend/
    apis/                # FastAPI アプリ（AWS Lambda 想定 / Mangum）
      app/
        __init__.py
        main.py          # FastAPIエントリ
        handler.py       # Lambdaエントリ（Mangum）
        deps.py          # 認証・依存解決
        models.py        # Pydanticモデル
        repos/           # DynamoDBアクセス層
        routers/
          logs.py        # /v1/logs
          stats.py       # /v1/stats
          me.py          # /v1/me
        core/
          config.py      # 設定値（環境変数）
          logging.py
      tests/
        api/
          test_logs.py
          test_stats.py
      requirements.txt
      runtime.txt        # (必要なら) ランタイムヒント

  infra/
    README.md            # 使い方・注意点
    dev/                 # 開発環境用Terraform
      backend.tf         # remote state (S3+DynamoDB)
      main.tf
      variables.tf
      outputs.tf
    prod/                # 本番環境用Terraform
      backend.tf         # remote state (S3+DynamoDB)
      main.tf
      variables.tf
      outputs.tf
    modules/             # 共通モジュール
      s3_cloudfront_spa/
      api_lambda/
      cognito/
      dynamodb/

  .github/workflows/
    ci.yml               # lint/test/build
    deploy.yml           # デプロイ（env毎にジョブ分岐）
```

### 命名・規約
- **front**: Reactは `app/` 配下を基本に、小さなコンポーネントへ分割。
- **backend/apis**: ルータは機能単位（`logs.py`, `stats.py`, `me.py`）。DynamoDBは `repos/` で抽象化。
- **infra**: すべてTerraform化。環境(dev/prod)はディレクトリで分離。共通ロジックは `modules/` で再利用。
- **テスト**: `front/src/tests` と `backend/apis/tests` に配置。
- **Secrets**: 直接コミットしない。SSM Parameter Store / Secrets Manager を使用。

---


## 作業手順（マイルストーン）
- **M0**: 雛形（web/app/infra）と `/healthz`、Terraform remote state
- **M1**: 認証（Cognito）+ `POST /logs`（フロントから送信）
- **M2**: 一覧/編集/削除
- **M3**: 集計（合計時間・理解度内訳）
- **M4**: デプロイ/監視（CloudWatch Logs）

---

## Terraform 要点
- S3(静的) + CloudFront + ACM
- API Gateway HTTP + Lambda(FastAPI) + IAM
- DynamoDB テーブル（PK: `log_id`, GSI1: `user_id`+`start_time`）
- Cognito（User Pool, App Client, Domain）

> 機密は SSM Parameter Store / Secrets Manager。CORS はフロントのドメインに限定。

### インフラ構成方針
- **環境分離**: dev と prod は完全に独立したディレクトリとして管理（`infra/dev/`, `infra/prod/`）
- **モジュール化**: 共通ロジックは `infra/modules/` で再利用
- **State管理**: 環境ごとに独立した remote state（S3 + DynamoDB）
- **デプロイ**: 各環境ディレクトリで独立して `terraform apply` を実行

### AWS リソース命名規則

**命名パターン**: `study-app-{resource-type}-{env}`

| リソース | 命名例（dev） | 命名例（prod） |
|---------|-------------|---------------|
| S3バケット（フロント） | `study-app-front-dev` | `study-app-front-prod` |
| S3バケット（Terraform State） | `study-app-tfstate-dev` | `study-app-tfstate-prod` |
| DynamoDBテーブル（learning_logs） | `study-app-learning-logs-dev` | `study-app-learning-logs-prod` |
| DynamoDBテーブル（Terraform Lock） | `study-app-tfstate-lock-dev` | `study-app-tfstate-lock-prod` |
| Cognito User Pool | `study-app-user-pool-dev` | `study-app-user-pool-prod` |
| Cognito User Pool Client | `study-app-client-dev` | `study-app-client-prod` |
| Cognito Domain | `study-app-auth-dev` | `study-app-auth-prod` |
| Lambda関数 | `study-app-api-dev` | `study-app-api-prod` |
| API Gateway | `study-app-api-dev` | `study-app-api-prod` |
| CloudWatch Log Group | `/aws/lambda/study-app-api-dev` | `/aws/lambda/study-app-api-prod` |
| IAM Role（Lambda実行用） | `study-app-lambda-exec-dev` | `study-app-lambda-exec-prod` |

**注意事項**:
- S3バケット名はグローバルで一意である必要があるため、必要に応じてAWSアカウントIDやランダムサフィックスを追加
- リソース名は小文字とハイフンを使用（アンダースコアは避ける）
- DynamoDBテーブル名はアンダースコアも使用可能
- タグは必ず付与: `Environment` (dev/prod), `Project` (study-app), `ManagedBy` (terraform)

---

## コーディング規約 / 返答規約（AI向け）
- 事実ベースで回答し、**推測しない**。
- 不明点は「わからない」と明示する。
- 型を優先（FastAPI/Pydantic, React/TypeScript）。
- 小さな PR を短いサイクルで。大規模変更は設計メモを添付。
- 例外/エラー発生時は再現手順・ログ・期待/実際をセットで記載。

### commit メッセージ（テンプレ）
```
feat(api): add POST /logs with Cognito auth
fix(web): handle empty tags in LogForm
chore(infra): provision DynamoDB table with GSI1
```

### PR テンプレ
- 目的 / 変更点
- スクリーンショット（UI）
- 動作確認手順
- 影響範囲 / 互換性
- チェックリスト（lint/test/pass）

---

## テスト
- Front: Vitest + React Testing Library
- API: pytest（FastAPI TestClient）
- IaC: `terraform validate` / `terraform plan`、静的解析（tfsec/checkov 任意）

---

## セキュリティ&運用
- JWT 検証は API Gateway（Lambda は最小）
- すべてのデータアクセスは `user_id` でスコープ
- 最小権限 IAM, 環境変数は SSM/Secrets
- 監視: CloudWatch Logs、必要に応じて X-Ray

---

## 依存関係（最小）
- **API**: `fastapi`, `pydantic`, `boto3`, `mangum`, `uvicorn`, `ulid-py`
- **Web**: `react`, `react-router-dom`, `react-hook-form`, `zod`, `axios`

---

## pre-commit 導入
**目的**: 余計な差分（空白・改行）やフォーマット崩れ、Terraformの整形忘れをコミット前に自動検出/修正する。

### 手順
1. ルートに `.pre-commit-config.yaml` を追加（下記テンプレ参照）
2. ツール導入
   - Python: `pip install pre-commit`（または `pipx` 推奨）
   - Node(Front): `npm i -D eslint prettier`（必要に応じて）
   - Terraform: 事前に `terraform` コマンドが使えること
3. フックを有効化
   ```bash
   pre-commit install
   # 既存全ファイルに実行（初回推奨）
   pre-commit run -a
   ```

### `.pre-commit-config.yaml`（テンプレ）
> **rev** は固定タグに必ずピン留めしてください（例をコメントに記載）。
```yaml
repos:
  # 1) 低リスクの基本チェック（外部依存なし）
  - repo: https://github.com/pre-commit/pre-commit-hooks
    # 例: v4.6.0 など安定タグに固定
    rev: <pin-stable-tag>
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: check-merge-conflict

  # 2) Python（フォーマッタ/リンタ） — 使用する場合のみ有効化
  # Black/ Ruff を使う場合はコメントアウトを外し、rev を安定版に固定
  # - repo: https://github.com/psf/black
  #   rev: <black-tag>
  #   hooks:
  #     - id: black
  #       files: ^backend/
  # - repo: https://github.com/astral-sh/ruff-pre-commit
  #   rev: <ruff-tag>
  #   hooks:
  #     - id: ruff
  #       args: ["--fix"]
  #       files: ^backend/

  # 3) Terraform — fmt/validate を自動実行
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: <pre-commit-terraform-tag>
    hooks:
      - id: terraform_fmt
        files: ^infra/
      - id: terraform_validate
        files: ^infra/

  # 4) JavaScript/TypeScript — ESLint/Prettier を npm script 経由で（プロジェクト依存を使用）
  - repo: local
    hooks:
      - id: frontend-prettier
        name: frontend-prettier
        entry: npm run -w front format
        language: system
        pass_filenames: true
        files: ^front/
      - id: frontend-eslint
        name: frontend-eslint
        entry: npm run -w front lint
        language: system
        pass_filenames: true
        files: ^front/.*\.(ts|tsx|js|jsx)$
```

### `front/package.json` 推奨スクリプト例
```json
{
  "scripts": {
    "lint": "eslint .",
    "format": "prettier --write ."
  }
}
```

### 運用ルール
- rev は必ず固定（`main`や`master`参照は禁止）。
- フェイル時はコミットを止める。必要に応じて `pre-commit run -a` で一括修正。
- CI でも `pre-commit run -a` を実行し、ローカルと同一判定にする。

---


## 受け入れ基準チェックリスト
- [ ] ログイン→ダッシュボード遷移
- [ ] ログ作成→一覧反映
- [ ] 編集/削除が権限内で成功
- [ ] 指定期間の合計時間・理解度内訳が一致
- [ ] Terraform で dev 環境をクリーンプロビジョン可能

---

## よくある質問（AI用）
- **Q: Aurora への移行は？** A: 可能。現状不要。必要になったら読み取り層を抽象化して移行計画を追記。
- **Q: 未ログイン時の挙動は？** A: `/login` へ誘導。公開ページは無し。
- **Q: タグ検索は？** A: MVP では期間フィルタのみ。需要発生後に GSI を追加。

---

## 変更履歴
- v0.3 AWSリソース命名規則を追加。インフラ構成方針を明記（環境ごとにディレクトリ分離）。
- v0.2 stg環境を削除、dev/prod環境のみに変更。infraディレクトリを環境ごとに分離。
- v0.1 初版（MVP 設計・手順・規約を定義）

