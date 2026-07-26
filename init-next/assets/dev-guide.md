# 開発ガイド

## 原則

可読性と保守性を最優先にし、そのために**関心を分離する**。

- **状態とロジックを分離する**: データ構造と操作を混ぜない
- **コントラクト層を厳密に、実装層は再生成可能に**: API・型（公開インターフェース）は安定させ、実装の詳細はいつでも書き直せるようにする
- **class は使わず関数型で書く**: データは plain な型、ロジックは純粋関数、更新は新しい値を返す形で表現する
- **設計に妥協しない**: 「こちらの方が既存の変更が少なくて済む」といった現状維持バイアスで設計を選ばない。常にその場でのベストな形を選び、既存コードはそれに合わせて書き換える

## 技術スタック

- Next.js (App Router) / TypeScript / Mantine
- DB: PostgreSQL (docker compose) / マイグレーション: Atlas (schema-as-code) / クライアント: Prisma
- ツール: pnpm / Biome / aqua (CLI バージョン管理)

## アーキテクチャ

- `src/app` — Next.js App Router。page に最も近い場所に `_components` / `_lib` を置き、そこでしか使わないものを押し込める。`_lib` には zod のスキーマ定義や server action を置く
- `src/domain` — 純粋なドメインロジック（外部依存なし）
- `src/usecases` — domain と boundaries を使うアプリケーションロジック
- `src/boundaries/ports` — 外部システムとの境界のインターフェース（ヘキサゴナル）
- `src/boundaries/adapters` — ports の実装
- `src/lib` — このアプリに依存しない独立した汎用コード（domain と混同しないこと）
- `src/components` — 共通コンポーネント
- `src/queries` — Prisma による DB 呼び出し（client は `src/queries/client.ts` のシングルトンを使う）

## コマンド

- `pnpm dev` / `pnpm build` / `pnpm start`
- `pnpm lint`（biome check）/ `pnpm format` / `pnpm typecheck`
- `pnpm db:up` / `pnpm db:down` — compose の PostgreSQL 起動/停止

### DB スキーマ変更フロー

スキーマは `db/schema.sql` に宣言的に書き、マイグレーションは Atlas が生成する。Prisma の migrate は使わない。

1. `db/schema.sql` を編集（desired state）
2. `pnpm db:diff <migration_name>` — `db/migrations/` に差分マイグレーションを生成
3. `pnpm db:apply` — ローカル DB に適用
4. `pnpm db:pull` — Prisma スキーマへ introspect + client 生成（`src/generated/prisma`、git 管理外）

## 可読性

### 並び順

ファイル・interface・定数いずれにおいても、**理解に必要なものが先、参照用のものが後**。上から読めば概要がわかり、下に進むほど詳細になるように構成する。この原則は再帰的に働き、export グループ内・private グループ内でも同じく適用する。

#### ファイル内

1. imports
2. export する型・定数（API の形。関数シグネチャ理解の前提）
3. export 関数（公開 API。ファイルの目的が一目でわかる）
4. private 関数（export 関数内での出現順に並べ、呼び出し先を直後に置く）
5. private データ（マップテーブル等。参照されるだけの末端データ）

#### interface のフィールド

ドメインの自然な順序に従って並べる。

識別子 → コア属性 → 条件・コンテキスト → 詳細・メタデータ

#### enum 的な定数・マップテーブル

ドメイン固有の序列に従う（階層の高低、強度の軽重、公式の番号順など）。マップテーブルのキー順は、対応する const 定義の順序と一致させる。

### コメント

**コードは What を、コメントは Why だけを語る。** 名前から読み取れることは繰り返さない。コードだけでは理由がわからない場合にのみ書く:

- 意味が自明でないマジックバリュー
- 外部のバグや非自明な仕様に合わせている箇所（例: ベンダー側の typo に追従）
- 汎用的な型で中身がわからない場合の具体例（例: `Record<string, string>` が実際は何と何の対応か）
- 複数の選択肢がある中でなぜその方法を選んだか
- 非自明な変換（例: `year % 100`）

## コーディングルール

### null チェック

`== null`（緩い比較）で null と undefined の両方を防ぐ。`!x` での nullish チェックは使わない（`0` や `''` で誤爆するため）。

## 言語

- **コード（識別子・コメント・ログメッセージ・エラーメッセージ）は英語で書く**
- **コミットメッセージも英語で書く**
- ユーザー向けの画面表示文言など、仕様として日本語が必要なものは除く
