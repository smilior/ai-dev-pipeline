# AI Dev Pipeline

**— Issue を入れたら、PR が出る —**

GitHub Issues をタスクキューとして扱い、Self-hosted Runner 上の Claude Code が Issue を順番に拾って実装し、PR を作成・自動マージする開発自動化パイプライン。

## アーキテクチャ

```
[Issue Queue] → [Runner が検知] → [Claude Code が実装] → [PR 作成]
     ↑                                                        │
     └──────── 次の Issue にラベル付与 ←── [自動マージ] ←──────┘
```

## セットアップ

### 1. テンプレートからリポジトリ作成

このリポジトリをテンプレートとして新しいリポジトリを作成する。

### 2. Claude Code Max プランの認証

ホストマシンで Claude Code を起動し、Max プランでログインする:

```bash
claude
# ブラウザが開くので Max プランのアカウントでログイン
# ~/.claude/ に認証情報が保存される
```

Docker コンテナはこの `~/.claude/` を読み取り専用でマウントして認証する。

### 3. Branch Protection 設定

`main` ブランチに以下の保護ルールを設定（auto-merge に必要）:

- [x] Require a pull request before merging
- [x] Require status checks to pass before merging
  - `lint-test-build` を必須チェックに追加
- [x] Allow auto-merge

### 4. Self-hosted Runner の起動

```bash
cd docker
cp .env.example .env
# .env を編集して各値を設定

# Runner 登録トークンの取得
gh api repos/{owner}/{repo}/actions/runners/registration-token --jq '.token'

# 起動
docker compose up -d
```

### 5. CLAUDE.md のカスタマイズ

`CLAUDE.md` をプロジェクトに合わせて編集する。ここが実装品質を左右する最重要ファイル。

## 使い方

### Issue の作成

Issue テンプレート（機能実装 / バグ修正）を使って Issue を作成する。`queued` ラベルが自動で付与される。

### パイプラインの開始

最初の Issue の `queued` ラベルを `auto-implement` に変更する（初回のみ手動）。以降は自動で次の Issue に進む。

### Issue ライフサイクル

```
queued → auto-implement → in-progress → pr-created → (auto-merge) → done
```

### 依存関係

Issue 本文に以下を記述すると、依存 Issue が完了するまで実行を待機する:

```
depends-on: #3
depends-on: #3, #5    # 複数依存も可
```

## ラベル一覧

| ラベル | 意味 |
|--------|------|
| `queued` | 実装待ちキュー |
| `auto-implement` | 実装開始トリガー |
| `in-progress` | Claude Code 実装中 |
| `pr-created` | PR作成済み・マージ待ち |
| `done` | 完了 |
| `failed` | 実装失敗（要確認） |

## 安全機構

| 保護 | 内容 |
|------|------|
| ターン上限 | 1 Issue あたり最大 50 ターン |
| タイムアウト | 1 Issue あたり最大 60 分 |
| 日次上限 | 1日最大 10 件 |
| CI ゲート | lint + test + build が通らないとマージしない |
| 失敗通知 | `failed` ラベル + Issue コメントでログURL通知 |

## ファイル構成

```
.github/
├── workflows/
│   ├── auto-implement.yml    # Issue → 実装 → PR
│   ├── orchestrator.yml      # PR マージ → 次 Issue トリガー
│   ├── auto-merge.yml        # CI 通過後の自動マージ
│   └── ci.yml                # lint + test + build
└── ISSUE_TEMPLATE/
    ├── feature.yml
    └── bugfix.yml
docker/
├── Dockerfile
├── docker-compose.yml
├── entrypoint.sh
└── .env.example
CLAUDE.md                     # AI への指示書（要カスタマイズ）
```
