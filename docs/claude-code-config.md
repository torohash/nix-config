# Claude Code 設定ファイル一覧

Claude Code で使用される設定ファイルの一覧、役割、配置場所をまとめます。

## 設定ファイルの全体像

Claude Code の設定は「ユーザーレベル」「プロジェクトレベル」「組織レベル（マネージド）」の 3 層で構成されます。プロジェクトレベルにはさらに「共有用」と「個人用（gitignore 対象）」の区分があります。

## CLAUDE.md（プロジェクトメモリ・指示ファイル）

セッション開始時に自動で読み込まれるマークダウン形式の指示ファイルです。コーディング規約、ビルドコマンド、アーキテクチャの概要などを記述します。

| 配置場所 | スコープ | Git 共有 | 用途 |
|----------|----------|----------|------|
| `CLAUDE.md` または `.claude/CLAUDE.md` | プロジェクト | する | チーム共有のプロジェクト指示 |
| `.claude/CLAUDE.local.md` | プロジェクト（個人） | しない（自動で gitignore） | 個人のプロジェクト固有設定 |
| `~/.claude/CLAUDE.md` | ユーザー | - | 全プロジェクト共通の個人設定 |
| `/etc/claude-code/CLAUDE.md` | 組織（マネージド） | - | 組織全体の指示 |

### 特徴

- `@path/to/file` 構文で外部ファイルをインポート可能。
- 親ディレクトリ・子ディレクトリの CLAUDE.md を再帰的に読み込む（子ディレクトリは該当ファイルをアクセスした時点でオンデマンド読み込み）。

## .claude/rules/（モジュール式ルールディレクトリ）

CLAUDE.md を分割して管理するためのディレクトリです。個別のトピックごとにマークダウンファイルを配置できます。

| 配置場所 | スコープ |
|----------|----------|
| `.claude/rules/*.md` | プロジェクト |
| `~/.claude/rules/*.md` | ユーザー |

### 特徴

- ディレクトリ内の全 `.md` ファイルが自動で読み込まれる。
- サブディレクトリによる整理が可能（例: `.claude/rules/frontend/`, `.claude/rules/backend/`）。
- YAML フロントマターでパス条件付きルールを定義可能。

```markdown
---
paths:
  - "src/api/**/*.ts"
  - "lib/**/*.ts"
---
# マッチしたパスのファイルにのみ適用されるルール
```

## settings.json（設定ファイル）

Claude Code の動作を制御する JSON 設定ファイルです。権限、モデル、サンドボックス、フックなどを定義します。

| 配置場所 | スコープ | Git 共有 | 用途 |
|----------|----------|----------|------|
| `~/.claude/settings.json` | ユーザー | - | 全プロジェクト共通の個人設定 |
| `.claude/settings.json` | プロジェクト | する | チーム共有のプロジェクト設定 |
| `.claude/settings.local.json` | プロジェクト（個人） | しない（自動で gitignore） | 個人のプロジェクト固有設定 |
| `/etc/claude-code/managed-settings.json` | 組織（マネージド） | - | 組織全体の強制設定 |

### 適用優先順位（高い順）

1. マネージド設定（組織管理、上書き不可）
2. コマンドライン引数
3. `.claude/settings.local.json`（プロジェクトローカル）
4. `.claude/settings.json`（プロジェクト共有）
5. `~/.claude/settings.json`（ユーザー）

### 主な設定項目

| カテゴリ | 項目例 | 説明 |
|----------|--------|------|
| 権限 | `permissions.allow`, `permissions.deny` | ツールの許可・拒否ルール |
| モデル | `model`, `availableModels` | 使用モデルの指定 |
| サンドボックス | `sandbox.enabled`, `sandbox.network` | サンドボックス設定 |
| フック | `hooks` | イベント駆動の自動処理 |
| 表示 | `outputStyle`, `language` | 出力スタイルと言語 |
| 帰属表示 | `attribution.commit`, `attribution.pr` | コミット・PR の帰属設定 |

## keybindings.json（キーバインド設定）

| 配置場所 | スコープ |
|----------|----------|
| `~/.claude/keybindings.json` | ユーザー |

Claude Code のキーボードショートカットをカスタマイズする JSON ファイルです。コンテキスト（Chat、Global など）ごとにバインドを定義します。

```json
{
  "$schema": "https://www.schemastore.org/claude-code-keybindings.json",
  "bindings": [
    {
      "context": "Chat",
      "bindings": {
        "ctrl+e": "chat:externalEditor",
        "ctrl+u": null
      }
    }
  ]
}
```

## .mcp.json（MCP サーバー設定）

MCP（Model Context Protocol）サーバーの接続情報を定義する JSON ファイルです。

| 配置場所 | スコープ | Git 共有 | 用途 |
|----------|----------|----------|------|
| `.mcp.json` | プロジェクト | する | チーム共有の MCP サーバー定義 |
| `~/.claude.json` 内の設定 | ユーザー / ローカル | - | 個人の MCP サーバー定義 |
| `/etc/claude-code/managed-mcp.json` | 組織（マネージド） | - | 組織管理の MCP サーバー定義 |

### サポートするトランスポート

- `http`: リモート HTTP サーバー（推奨）。
- `sse`: リモート SSE サーバー（非推奨）。
- `stdio`: ローカルプロセスとして実行。

```json
{
  "mcpServers": {
    "server-name": {
      "type": "stdio",
      "command": "/path/to/server",
      "args": ["--config", "file.json"],
      "env": { "KEY": "value" }
    }
  }
}
```

環境変数の展開（`${VAR}`, `${VAR:-default}`）に対応しています。

## .claudeignore（除外パターン）

| 配置場所 | スコープ |
|----------|----------|
| `.claudeignore`（プロジェクトルート） | プロジェクト |

Claude Code がアクセスしないファイル・ディレクトリを指定します。`.gitignore` と同じ構文です。

> **注意**: `.claudeignore` はプロジェクトルートのみ対応しており、`~/.claudeignore` のようなグローバル（ユーザーレベル）設定は存在しません。他の設定ファイル（`settings.json`, `CLAUDE.md`, `rules/` など）にはユーザーレベルがありますが、`.claudeignore` にはありません。

```
node_modules/
.git/
*.log
.env
.env.local
dist/
build/
```

## .claude/agents/（カスタムエージェント）

サブエージェントとして呼び出せるカスタムエージェントをマークダウン形式で定義します。

| 配置場所 | スコープ |
|----------|----------|
| `.claude/agents/*.md` | プロジェクト |
| `~/.claude/agents/*.md` | ユーザー |

YAML フロントマターで名前、説明、使用モデル、ツール制限などを設定できます。

## .claude/skills/（カスタムスキル）

再利用可能なスラッシュコマンドをマークダウン形式で定義します。

| 配置場所 | スコープ |
|----------|----------|
| `.claude/skills/*.md` | プロジェクト |
| `~/.claude/skills/*.md` | ユーザー |

YAML フロントマターで名前、説明、ツール制限、フックなどを設定できます。

## .claude/output-styles/（出力スタイル）

Claude の応答フォーマットやコミュニケーションスタイルをカスタマイズするマークダウンファイルです。

| 配置場所 | スコープ |
|----------|----------|
| `.claude/output-styles/*.md` | プロジェクト |
| `~/.claude/output-styles/*.md` | ユーザー |

## フック設定（settings.json 内）

settings.json の `hooks` キー配下に定義するイベント駆動の自動処理です。独立した `hooks.json` ファイルは存在せず、必ず settings.json 内に記述します（`hooks/hooks.json` はプラグイン専用の仕組み）。設定するだけで自動的に有効になり、追加のセットアップは不要です。

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "npx prettier --write",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

### フックイベント一覧

| イベント | タイミング |
|----------|-----------|
| `SessionStart` | セッション開始・再開時 |
| `UserPromptSubmit` | ユーザーがプロンプトを送信した時 |
| `PreToolUse` | ツール実行前 |
| `PostToolUse` | ツール実行成功後 |
| `PostToolUseFailure` | ツール実行失敗後 |
| `PermissionRequest` | 権限ダイアログ表示時 |
| `Stop` | Claude の応答完了時 |
| `SubagentStart` / `SubagentStop` | サブエージェントのライフサイクル |
| `SessionEnd` | セッション終了時 |
| `Notification` | 通知送信時 |

### フックの種類

| 種類 | 説明 |
|------|------|
| `command` | シェルスクリプトを実行 |
| `prompt` | LLM で評価（軽量モデルを指定可） |
| `agent` | サブエージェントを起動して検証 |

## ~/.claude.json（ユーザープリファレンス）

Claude Code が自動管理するユーザーレベルの設定ファイルです。テーマ、OAuth セッション、MCP サーバー（ユーザー・ローカルスコープ）、信頼設定などが含まれます。通常は手動編集不要です。

## 自動メモリ

| 配置場所 | 用途 |
|----------|------|
| `~/.claude/projects/<project-path>/memory/MEMORY.md` | プロジェクトごとの自動メモリ |

Claude が会話を通じて学んだパターンやプロジェクト固有の知識を自動的に記録するファイルです。セッション間で保持されます。

## 主要な環境変数

| 変数名 | 説明 |
|--------|------|
| `ANTHROPIC_API_KEY` | API 認証キー |
| `ANTHROPIC_MODEL` | 使用モデルの上書き |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | 出力トークン上限 |
| `CLAUDE_CODE_DISABLE_AUTO_MEMORY` | 自動メモリの無効化（`1` で無効） |
| `DISABLE_TELEMETRY` | テレメトリの無効化 |
| `DISABLE_AUTOUPDATER` | 自動更新の無効化 |
| `MCP_TIMEOUT` | MCP サーバー起動タイムアウト |

## このプロジェクトで管理対象とするファイル

Nix/Home Manager で dotfiles として管理する候補は以下の通りです。

| ファイル | Git 共有 | 管理方針 |
|----------|----------|----------|
| `.claude/settings.json` | する | プロジェクトごとに配置 |
| `.claude/settings.local.json` | しない | gitignore 対象、手動管理 |
| `~/.claude/settings.json` | - | Home Manager で配置 |
| `CLAUDE.md` / `.claude/CLAUDE.md` | する | プロジェクトごとに配置 |
| `.claude/CLAUDE.local.md` | しない | gitignore 対象、手動管理 |
| `~/.claude/CLAUDE.md` | - | Home Manager で配置 |
| `.claude/rules/*.md` | する | プロジェクトごとに配置 |
| `~/.claude/rules/*.md` | - | Home Manager で配置 |
| `~/.claude/keybindings.json` | - | Home Manager で配置 |
| `.mcp.json` | する | プロジェクトごとに配置 |
| `.claudeignore` | する | プロジェクトごとに配置 |
| `.claude/agents/*.md` | する | プロジェクトごとに配置 |
| `.claude/skills/*.md` | する | プロジェクトごとに配置 |
