# Frontend - 学習管理アプリ

学習ログを記録・閲覧するSPA（Single Page Application）です。
React + TypeScript + Vite を使用し、AWS S3 + CloudFront 上にホスティングします。

---

## 📑 目次

- [1. 前提条件](#1-前提条件)
- [2. セットアップ](#2-セットアップ)
- [3. 開発](#3-開発)
- [4. ビルド](#4-ビルド)
- [5. テスト](#5-テスト)
- [6. デプロイ](#6-デプロイ)
- [7. 環境変数](#7-環境変数)
- [8. 技術スタック](#8-技術スタック)
- [9. ディレクトリ構成](#9-ディレクトリ構成)
- [10. インフラ構成](#10-インフラ構成)
- [11. 開発ガイドライン](#11-開発ガイドライン)
- [12. トラブルシューティング](#12-トラブルシューティング)

---

## 1. 前提条件

開発を始める前に、以下がインストールされていることを確認してください。

- **Node.js**: >= 18.0.0
- **npm**: >= 9.0.0

```bash
# バージョン確認
node --version
npm --version
```

---

## 2. セットアップ

### 依存関係のインストール

```bash
cd front
npm install
```

これにより、`package.json`に記載されたすべての依存関係がインストールされます。

---

## 3. 開発

### 開発サーバーの起動

```bash
npm run dev
```

- ブラウザで自動的に http://localhost:3000 が開きます
- ファイルを編集すると、自動的にリロードされます（Hot Module Replacement）

### 利用可能なコマンド

| コマンド | 説明 |
|---------|------|
| `npm run dev` | 開発サーバー起動 |
| `npm run build` | 本番用ビルド |
| `npm run preview` | ビルド結果のプレビュー |
| `npm run lint` | ESLintによる静的解析 |
| `npm run format` | Prettierによるコード整形 |
| `npm run type-check` | TypeScriptの型チェック |
| `npm run test` | Vitestによるテスト実行 |
| `npm run deploy:dev` | Dev環境へのデプロイ |
| `npm run deploy:prod` | Prod環境へのデプロイ |

---

## 4. ビルド

### 本番用ビルドの作成

```bash
npm run build
```

- ビルド成果物は `dist/` ディレクトリに出力されます
- TypeScriptのコンパイルとViteのビルドが実行されます
- 最適化とminifyが自動的に行われます

### ビルド結果のプレビュー

```bash
npm run preview
```

ローカルでビルド結果を確認できます。

---

## 5. テスト

### テストの実行

```bash
npm run test
```

- **フレームワーク**: Vitest + React Testing Library
- **対象**: コンポーネント単位のユニットテスト
- **配置場所**: `src/tests/`

### テストファイルの命名規則

- `*.test.tsx` または `*.test.ts`
- 例: `Home.test.tsx`

---

## 6. デプロイ

### 6.1 自動デプロイ（推奨）

デプロイスクリプト（`deploy.sh`）を使用して、ビルドからデプロイまでを自動化できます。

#### フロントエンドのみデプロイ

インフラが既にデプロイ済みの場合、フロントエンドのみをデプロイします。

```bash
# Dev環境
npm run deploy:dev
# または
./deploy.sh dev

# Prod環境
npm run deploy:prod
# または
./deploy.sh prod
```

#### インフラも含めてデプロイ

初回デプロイ時や、インフラに変更がある場合は `--with-infra` オプションを使用します。

```bash
# Dev環境（インフラ + フロントエンド）
npm run deploy:dev:infra
# または
./deploy.sh dev --with-infra

# Prod環境（インフラ + フロントエンド）
npm run deploy:prod:infra
# または
./deploy.sh prod --with-infra
```

#### デプロイスクリプトの動作内容

##### フロントエンドのみ（デフォルト）

1. ✅ 依存関係のインストール確認
2. 🏗️ フロントエンドのビルド（`npm run build`）
3. ☁️ S3バケットへのアップロード（`aws s3 sync`）
4. 🔍 Terraformから CloudFront ディストリビューションIDを取得
5. 🔄 CloudFrontキャッシュの無効化

##### インフラも含む場合（`--with-infra`）

1. 🏗️ インフラのデプロイ（`terraform init` + `terraform plan` + `terraform apply`）
2. ✅ 依存関係のインストール確認
3. 🏗️ フロントエンドのビルド（`npm run build`）
4. ☁️ S3バケットへのアップロード（`aws s3 sync`）
5. 🔍 Terraformから CloudFront ディストリビューションIDを取得
6. 🔄 CloudFrontキャッシュの無効化

#### 前提条件

デプロイを実行する前に、以下を確認してください：

- ✅ AWS CLIがインストールされ、認証設定が完了していること
  ```bash
  aws sts get-caller-identity
  ```

- ✅ Terraformがインストールされていること（`--with-infra` 使用時）
  ```bash
  terraform --version
  ```

- ✅ （初回のみ）Terraform State用のS3バケットが作成されていること
  ```bash
  aws s3 mb s3://study-app-front-tfstate-dev
  aws s3api put-bucket-versioning \
    --bucket study-app-front-tfstate-dev \
    --versioning-configuration Status=Enabled
  ```

#### デプロイ後の確認

デプロイが完了すると、CloudFront URLが表示されます。

```
========================================
デプロイ完了！
========================================

アクセスURL: https://d1234567890abc.cloudfront.net
```

※ CloudFrontのキャッシュ無効化には数分かかる場合があります。

---

### 6.2 手動デプロイ

スクリプトを使わずに手動でデプロイする場合：

```bash
# 1. ビルド
npm run build

# 2. S3にアップロード
aws s3 sync dist/ s3://study-app-front-dev --delete

# 3. CloudFrontキャッシュ無効化
aws cloudfront create-invalidation \
  --distribution-id <DISTRIBUTION_ID> \
  --paths "/*"
```

`<DISTRIBUTION_ID>` は以下のコマンドで取得できます：

```bash
cd ../infra/dev
terraform output frontend_cloudfront_distribution_id
```

---

## 7. 環境変数

### 環境変数の設定方法

Viteでは `VITE_` プレフィックスを持つ環境変数のみがクライアントに公開されます。

#### 開発環境（`.env.development`）

```env
VITE_API_BASE_URL=https://api-dev.example.com/v1
VITE_COGNITO_DOMAIN=study-app-auth-dev.auth.ap-northeast-1.amazoncognito.com
VITE_COGNITO_CLIENT_ID=xxxxxxxxxxxxxxxxxxxxxxxxxx
VITE_COGNITO_REDIRECT_URI=http://localhost:3000/login/callback
VITE_COGNITO_LOGOUT_REDIRECT_URI=http://localhost:3000
```

#### 本番環境（`.env.production`）

```env
VITE_API_BASE_URL=https://api-prod.example.com/v1
VITE_COGNITO_DOMAIN=study-app-auth-prod.auth.ap-northeast-1.amazoncognito.com
VITE_COGNITO_CLIENT_ID=xxxxxxxxxxxxxxxxxxxxxxxxxx
VITE_COGNITO_REDIRECT_URI=https://d1234567890abc.cloudfront.net/login/callback
VITE_COGNITO_LOGOUT_REDIRECT_URI=https://d1234567890abc.cloudfront.net
```

### 環境変数の使用方法

TypeScriptで環境変数を使用する場合：

```typescript
const apiBaseUrl = import.meta.env.VITE_API_BASE_URL
const cognitoDomain = import.meta.env.VITE_COGNITO_DOMAIN
```

---

## 8. 技術スタック

| カテゴリ | 技術 |
|---------|------|
| **Framework** | React 18 + TypeScript + Vite |
| **Router** | react-router-dom |
| **Form管理** | react-hook-form + zod |
| **HTTP Client** | axios |
| **Testing** | Vitest + React Testing Library |
| **Lint/Format** | ESLint + Prettier |
| **認証** | Amazon Cognito Hosted UI (JWT) |
| **ホスティング** | AWS S3 + CloudFront |

---

## 9. ディレクトリ構成

```
front/
├── index.html              # HTMLテンプレート
├── vite.config.ts          # Vite設定
├── tsconfig.json           # TypeScript設定
├── package.json            # 依存関係とスクリプト
├── deploy.sh               # デプロイスクリプト
├── src/
│   ├── main.tsx            # エントリーポイント
│   ├── App.tsx             # ルートコンポーネント
│   ├── index.css           # グローバルスタイル
│   ├── app/
│   │   ├── routes/         # ページコンポーネント
│   │   │   ├── Home.tsx
│   │   │   ├── Logs.tsx
│   │   │   └── Stats.tsx
│   │   ├── components/     # 再利用可能なUIコンポーネント
│   │   ├── hooks/          # カスタムフック
│   │   └── lib/            # APIクライアント・ユーティリティ
│   ├── types/              # 型定義
│   │   └── index.ts
│   └── tests/              # テストファイル
└── public/                 # 静的ファイル
```

### ディレクトリの役割

| ディレクトリ | 役割 |
|------------|------|
| `app/routes/` | 各ページのコンポーネント（`/`, `/logs`, `/stats` など） |
| `app/components/` | 再利用可能なUIコンポーネント |
| `app/hooks/` | カスタムフック（`useAuth`, `useLogs` など） |
| `app/lib/` | APIクライアント、ユーティリティ関数 |
| `types/` | TypeScriptの型定義 |
| `tests/` | ユニットテスト |

---

## 10. インフラ構成

### 全体像

```
ユーザー
  ↓
CloudFront (CDN)
  ↓
S3 (静的サイト)
```

### AWSリソース

#### S3設定

- **パブリックアクセス**: 無効
- **アクセス許可**: CloudFront の OAC (Origin Access Control) のみ
- **配置内容**: `dist/` のビルド成果物
- **インデックスドキュメント**: `index.html`
- **エラードキュメント**: `index.html` (SPA ルーティング対策)

#### CloudFront設定

- **Origin**: S3バケット
- **Default Root Object**: `index.html`
- **Cache Policy**: 静的ファイルのみキャッシュ（`index.html`はキャッシュしない）
- **Error Responses**: 404/403 → `index.html` にリダイレクト（React Router対応）
- **HTTPS**: 強制リダイレクト

### リソース命名

| 環境 | S3バケット | CloudFront Distribution |
|-----|-----------|------------------------|
| **Dev** | `study-app-front-dev` | 自動生成 |
| **Prod** | `study-app-front-prod` | 自動生成 |

### Terraformモジュール

インフラは `infra/modules/s3_cloudfront_spa/` モジュールで管理されています。

```hcl
module "frontend" {
  source = "../modules/s3_cloudfront_spa"

  bucket_name = "study-app-front-dev"
  price_class = "PriceClass_200"
  comment     = "Study App Frontend - Dev Environment"
}
```

詳細は `../infra/README.md` を参照してください。

---

## 11. 開発ガイドライン

### コーディング規約

#### TypeScript

- ✅ 厳格な型チェックを有効化
- ❌ `any`の使用は避ける
- ✅ 型定義は `src/types/` に配置

#### React

- ✅ 関数コンポーネントを使用
- ✅ Hooksを活用
- ✅ propsの型定義は必須
- ❌ クラスコンポーネントは使用しない

#### 状態管理

- ✅ React Hooks を使用（`useState`, `useEffect`, `useContext`）
- ❌ グローバルステート管理ライブラリ（Redux等）は非MVP

#### API呼び出し

- ✅ `lib/apiClient.ts` に集約
- ✅ エラーハンドリングを適切に行う
- ✅ ローディング状態を管理

#### 認証フロー

- Cognito Hosted UI を使用
- JWT トークンを取得して API と連携

### コードフォーマット

コミット前に必ず実行：

```bash
npm run format
npm run lint
```

### インポート順序

1. React関連
2. サードパーティライブラリ
3. 内部モジュール（`@/`から始まるパス）
4. 相対パス

```typescript
// ✅ Good
import React from 'react'
import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { LearningLog } from '@/types'
import { apiClient } from './apiClient'

// ❌ Bad（順序がバラバラ）
import { apiClient } from './apiClient'
import React from 'react'
import { LearningLog } from '@/types'
```

---

## 12. トラブルシューティング

### ビルドエラー

#### エラー: `node_modules` が破損している

```bash
# node_modulesとキャッシュをクリア
rm -rf node_modules dist .vite
npm install
npm run build
```

#### エラー: TypeScriptの型エラー

```bash
# 型チェックを実行
npm run type-check
```

---

### デプロイエラー

#### エラー: AWS認証失敗

```bash
# AWS CLIの認証情報を確認
aws sts get-caller-identity

# プロファイルを使用する場合
export AWS_PROFILE=your-profile-name
```

#### エラー: S3アップロード失敗

```bash
# バケットの存在確認
aws s3 ls s3://study-app-front-dev

# 権限確認
aws iam get-user
```

#### エラー: CloudFront無効化失敗

```bash
# ディストリビューションIDの確認
cd ../infra/dev
terraform output frontend_cloudfront_distribution_id
```

---

### 開発サーバーのエラー

#### エラー: ポート3000が既に使用されている

```bash
# ポートを使用しているプロセスを確認
lsof -i :3000

# プロセスを終了
kill -9 <PID>
```

または、`vite.config.ts`でポート番号を変更：

```typescript
export default defineConfig({
  server: {
    port: 3001,
  },
})
```

---

## 📄 ライセンス

本プロジェクトのライセンスはリポジトリルートの LICENSE に従います。
