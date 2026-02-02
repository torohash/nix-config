# AI CLI ツール

このリポジトリでは、AI 開発支援 CLI ツール（Claude Code、Codex CLI、OpenCode、agent-browser）を以下のアプローチで導入します。

## アプローチの理由

### Node.js の配置
Node.js は `common-store` に含めます。これにより、すべての CLI ツールが共通のランタイム環境を共有し、インストール管理が簡素化されます。

### CLI ツールのインストール方法
各 CLI ツールは公式のインストーラーまたは npm からインストールします。Nix パッケージとして固定せずに以下の理由があります：

- **更新頻度**: AI CLI ツールは頻繁に更新され、新機能が継続的に追加されます
- **セルフアップデート**: 各ツールには独自のセルフアップデート機能があり、最新版を維持しやすくなります
- **柔軟性**: 公式のインストール方法を使用することで、最新の機能やバグ修正を迅速に利用できます

## インストールコマンド

### npm のインストール先
Nix 環境では `npm install -g` の既定の prefix が読み取り専用になる場合があります。必要に応じてユーザーディレクトリへ切り替えてください。

```bash
npm config set prefix ~/.local
```

`~/.local/bin` が PATH に含まれていない場合は追加してください。

### Claude Code

```bash
# 公式インストーラーを使用
curl -fsSL https://claude.ai/install.sh | bash
```

公式ドキュメント: https://code.claude.com/docs/en/setup

インストール先の変更方法は公式ドキュメントに記載がないため、既定の配置先に従ってください。

### Codex CLI

```bash
# npm からインストール
npm install -g @openai/codex
```

公式ドキュメント: https://developers.openai.com/codex/cli/

### OpenCode

```bash
# 公式インストーラーを使用
curl -fsSL https://opencode.ai/install | bash
```

公式ドキュメント: https://opencode.ai/docs/

インストール先の変更方法は公式ドキュメントに記載がないため、既定の配置先に従ってください。

### agent-browser

```bash
# npm からインストール
npm install -g agent-browser
```

Chromium のダウンロード方法（Linux では依存ライブラリの導入も必要）は以下の通りです。

```bash
# Linux 以外（macOS/Windows）、または Linux で依存ライブラリ導入済みの場合
agent-browser install

# Linux: 方法1（依存ライブラリ + Chromium）
agent-browser install --with-deps

# Linux: 方法2（依存ライブラリを先に導入）
npx playwright install-deps chromium
agent-browser install
```

## 注意点

各 CLI ツールのセルフアップデート動作はツールごとに異なります。バージョンを固定しないことで、各ツールの推奨される更新方法に従うことができます。

更新方法は公式ドキュメントに従ってください。npm で導入したツールは `npm update -g` や再インストールで更新できます。

インストーラーのインストール先を変更できないため、必要に応じて PATH へ追加してください。
