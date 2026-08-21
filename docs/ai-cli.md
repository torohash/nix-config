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
Nix 環境では `npm install -g` の既定の prefix が読み取り専用になる場合があります。
このリポジトリでは Home Manager で `NPM_CONFIG_PREFIX=~/.local` を設定し、`~/.local/bin` を PATH に追加します。

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

### Codexのグローバル設定

このリポジトリは`dotfiles/codex/config.toml`と`dotfiles/codex/AGENTS.md`を、Home Managerで`~/.codex/`へ強制配置します。Home Manager管理後のファイルは読み取り専用リンクになるため、以後の変更はリポジトリ側で行い、Home Managerを適用してください。変更を反映するには新しいCodexセッションを開始します。

グローバル`AGENTS.md`の配置は次のMediumサイズの静的検査で確認できます。複数のHome Configurationを評価するため、Smallサイズではありません。

```bash
nix build .#checks.x86_64-linux.codex-global-rules-medium
```

### OpenCode

```bash
# 公式インストーラーを使用
curl -fsSL https://opencode.ai/install | bash
```

公式ドキュメント: https://opencode.ai/docs/

インストール先の変更方法は公式ドキュメントに記載がないため、既定の配置先に従ってください。

### OpenCodeのsubagent

このリポジトリは、OpenCodeネイティブのMarkdown形式で定義した次のsubagentをHome Managerから `~/.config/opencode/agents/` へ配置します。

- `coding`: コード、テスト、設定、ビルド定義を変更する唯一の書き込み担当。
- `project-research`: プロジェクト内のコード、設定、テスト、文書を調べる読み取り専用担当。
- `code-review`: 実装差分のバグ、回帰、安全性、データ損失、テスト不足を確認する読み取り専用担当。
- `web-research`: 公式文書と一次資料を優先して最新情報を調べる、Webアクセス専用の担当。

subagentのモデルと推論強度は、担当する作業に合わせて次のように決めています。

- `coding`: 通常の機能追加・修正を担うため、`openai/gpt-5.6-terra`、`high`。
- `project-research`: 複数ファイルを横断して調査するため、`openai/gpt-5.6-terra`、`high`。
- `code-review`: 実装差分を詳しく確認するため、`openai/gpt-5.6-sol`、`xhigh`。
- `web-research`: 複数の一次資料を統合するため、`openai/gpt-5.6-terra`、`high`。

OpenCodeでは `variant` がOpenAIモデルの `reasoningEffort` に対応します。すべてのsubagentで追加のsubagent起動を禁止し、再帰的な委譲を防ぎます。

primary agentはdescriptionを基に自動でsubagentを選択できます。明示的に指定する場合は `@` メンションを使います。

```text
@coding この不具合を修正してテストしてください
@project-research 認証処理の流れを調べてください
@code-review 現在の変更差分をレビューしてください
@web-research OpenCodeの最新のpermission仕様を調べてください
```

定義の確認には次のコマンドを使います。

```bash
opencode agent list
opencode debug agent coding
nix build .#checks.x86_64-linux.opencode-agent-definitions-medium
```

agentファイルはOpenCode起動時に読み込まれます。Home Manager適用後は、実行中のOpenCodeを終了してから起動し直してください。

### OpenCodeのグローバルルール

`dotfiles/opencode/AGENTS.md`を `~/.config/opencode/AGENTS.md` へ配置し、すべてのOpenCodeセッションへ適用します。初期状態は空です。内容を変更するときは、Home Managerの配置先ではなくリポジトリ側のファイルを編集し、`home-manager switch`を再実行してからOpenCodeを再起動します。

### OpenCodeのプロジェクト初期化Skill

`dotfiles/opencode/skills/bun-init`と`uv-init`を `~/.config/opencode/skills/` へ個別配置します。外部skillsの走査を無効にしていても、このOpenCode native Skillは利用できます。

両SkillはCodex hookやPluginを作成しません。プロジェクトの`AGENTS.md`を作成または既存内容へ統合し、対象コードや設定を変更した場合だけ整形、lint、型検査、テストを実行して、すべて成功するまで修正を繰り返す指示を追加します。

```text
bun-initで素のBun／TypeScriptプロジェクトを初期化してください
uv-initで素のPythonプロジェクトを初期化してください
```

定義の確認には`opencode debug skill`と`nix build .#checks.x86_64-linux.opencode-skill-definitions-medium`を使います。

### OpenCodeの基本権限

`dotfiles/opencode/opencode.json`を `~/.config/opencode/opencode.json` へ配置します。main agentであるbuilt-in `build` は、作業ツリー外へのアクセス、`.env`を含むファイル読み取り、同一ツールの再実行を許可します。この緩和は `build` だけに適用し、Planと各subagentは既存の制限を維持します。

top-levelにはprimary agentとsubagent共通のrm基底ルールを設定します。直接実行する `rm` は確認を要求し、既知の形式で `/`、絶対パス、`~`、`$HOME`を対象にした再帰削除は拒否します。agent固有のbash denyはこの基底ルールより優先されます。OpenCodeを `--auto` で起動した場合も、明示的な `deny` は維持されます。

個人用の `~/.config/opencode/opencode.jsonc` は管理対象外です。OpenCodeは `opencode.json` と `opencode.jsonc` をマージするため、provider、モデル、TUIなどの個人設定を `opencode.jsonc` に保持できます。

### OpenCodeの分離方針

このリポジトリはOpenCodeのグローバルルール、native Skill、共通rm権限、main agentの承認不要な基本権限を管理し、個人用 `opencode.jsonc`、provider、認証情報は管理しません。Home ManagerはClaude Code互換設定と外部skillsだけをOpenCodeから隔離します。

- `OPENCODE_DISABLE_CLAUDE_CODE=true`: `~/.claude/CLAUDE.md`、プロジェクトと親ディレクトリの `CLAUDE.md`、プロジェクトとグローバル（`~/.claude/skills`）の `.claude/skills` の読み込みを無効にします。
- `OPENCODE_DISABLE_EXTERNAL_SKILLS=true`: `~/.claude/`、`~/.agents/`、プロジェクトと親ディレクトリの `.claude/skills`、`.agents/skills` 配下の外部 skills の走査を無効にします。

projectの`AGENTS.md`に追加した継続検証指示を自動読込するため、project configは有効です。これに伴い、projectの`opencode.json`、`.opencode/`、project Pluginも読込対象になるため、信頼できるprojectで利用してください。

旧設定を読み込んだshellやデスクトップセッションには`OPENCODE_DISABLE_PROJECT_CONFIG=true`が残ります。Home Manager適用後は、現在のshellで`unset OPENCODE_DISABLE_PROJECT_CONFIG`してOpenCodeを起動するか、ログアウトしてから再ログインしてください。`OPENCODE_DISABLE_EXTERNAL_SKILLS`は公式文書に記載された回避設定です。`OPENCODE_DISABLE_CLAUDE_CODE`は現行実装に依存するため、OpenCodeのアップデート時に挙動を再確認してください。

Home Manager は `~/.opencode/bin` を PATH に追加します。

### OpenCode agent設計の方針

- 複雑なpromptは `opencode.json` へ埋め込まず、役割ごとのMarkdownファイルへ分離します。
- descriptionには「何をするか」と「いつ使うか」を書き、自動選択の誤りを減らします。
- 書き込み権限は `coding` だけに与え、調査・レビュー担当では `edit: deny` を明示します。
- `permission.task: deny` によりsubagentからの再委譲を禁止し、作業経路と責任を明確にします。
- agentごとのモデルとvariantは、対応するCodex agentの役割・判断難度に合わせて固定します。
- subagentのpromptでも、projectの`AGENTS.md`とREADMEを明示的に確認させます。

公式仕様:

- https://opencode.ai/docs/agents/
- https://opencode.ai/docs/skills/
- https://opencode.ai/docs/rules/
- https://opencode.ai/docs/permissions/
- https://opencode.ai/docs/config/

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
