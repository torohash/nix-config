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

### Codexのカスタムサブエージェント

`dotfiles/codex/AGENTS.md`は委譲の不変条件、各delegate Skillは具体的な実行手順、この節はCodex CLIの仕様と設定を扱います。

このリポジトリでは、`dotfiles/codex/agents/*.toml`をHome Managerで`~/.codex/agents/`へ配置します。各ファイルは独立したカスタムエージェント定義であり、`name`、`description`、`developer_instructions`を必須とします。Codexが役割を識別する名前はTOMLの`name`です。ファイル名は管理上`<name>.toml`へ一致させますが、表示nicknameや追跡用の`task_name`は役割選択には使いません。

`dotfiles/codex/skills/delegate-*/SKILL.md`は、依頼の種類と判断の難しさからTOMLの`name`を1つ選び、利用中のネイティブな起動機能にカスタムエージェント名を指定する公開された入力がある場合だけ起動します。その入力がない場合は、built-inの`default`、`worker`、`explorer`や依頼文だけの汎用エージェントへ代替しません。起動機能ごとの公開された入力を使い、仕様にない`agent_role`などの引数は作りません。Skill内の「選択対象のCodex識別名」は、Codexが読む選択規則であると同時に、SkillとTOMLの対応を静的検査する機械判定可能な唯一の許可一覧です。

カスタムエージェントを起動するときは、起動機能に会話履歴の引き継ぎ範囲を指定する公開された入力があれば`none`相当を選び、必要な文脈を委譲契約へ自己完結的に記載します。利用中の機能が全履歴の引き継ぎとカスタムエージェント指定の併用を明示的に保証する場合だけ例外とします。追跡用の`task_name`は役割名と独立した作業名です。

調査担当とコードレビュー担当は、TOMLの`sandbox_mode = "read-only"`と担当指示の両方で読み取り専用にします。親turnのlive permission overrideが優先される場合に備え、ファイル変更、コミット、追加のサブエージェント起動を禁止する指示も維持します。コード変更の書き込み担当は常に1体だけ起動します。

起動、タスクの経路選択、待機、終了処理はCodexのネイティブなサブエージェント機能に任せます。起動後は、返されたagentまたはthreadの識別子と担当を対応付け、完了通知または完了・失敗など実行が終わった状態まで待ちます。ただし、識別子をどの操作にも渡せるとは限りません。追加指示、状態照会、待機、中断ごとに公開された入力を確認し、対象を指定する入力がある操作にだけ識別子を渡します。

待機機能が待機時間だけを受け取る場合は、対象識別子を渡さずに待ちます。待機区間の終了後に一覧・状態照会または`/agent`で対象状態を確認します。対象指定付き待機が公開されている場合だけ、その入力へ識別子を渡します。待機呼び出しが通知なしで終了しても、agentまたはthreadが起動準備中または実行中なら待機を続けます。通常の直接起動には一律の短い制限時間を設けません。推論レベルが`high`または`xhigh`の担当は長時間実行される場合があります。`agents.job_max_runtime_seconds`は`spawn_agents_on_csv`のjob専用で、通常の直接起動の待機時間ではありません。

Codex CLIでは`/agent`を使って、実行中のthreadと状態を確認できます。長時間作業ではメインエージェントが利用者へ進捗を伝えます。通知が見えない場合や長期間状態が変わらない場合は、状態、thread、直近の活動、承認・tool・外部入力待ちの有無を確認し、同じ催促を繰り返しません。利用者の取消、依頼の置換、明示的な失敗、または承認・tool・外部入力待ちがなく進行が止まり、具体的な追加情報か1回の進行方向の修正でも再開しないことを確認した場合だけ中断または再選定します。経過時間だけでは失敗と判定しません。

実行状態が`completed`相当でも、委譲契約が求める結果をメインエージェントが確認するまでは成功としません。結果の欠落、error、interrupted、not found相当は成功として扱いません。同じ担当へ情報を追加する場合は既存の識別子を使い、別の役割へ再選定する場合は旧担当の終了を確認してから起動します。

このリポジトリは`dotfiles/codex/config.toml`をHome Managerで`~/.codex/config.toml`へ強制配置します。Home Manager管理後のファイルは読み取り専用リンクになるため、以後の変更はリポジトリ側で行い、Home Managerを適用してください。`[features.multi_agent_v2]`の`hide_spawn_agent_metadata = false`と`tool_namespace = "agents"`は、GPT-5.6 SolのMultiAgent V2で`spawn_agent`にカスタムエージェント選択用の`agent_type`を公開し、予約済みの`collaboration`名前空間とのスキーマ衝突を避ける回避設定です。変更を反映するには新しいCodexセッションを開始します。`[agents]`を利用環境で設定していない場合、Codexの既定値は`max_threads = 6`、`max_depth = 1`です。カスタムエージェントのモデルと推論レベルは各TOMLで管理し、起動時には上書きしません。

定義とSkillの対応、およびMultiAgent V2の回避設定は次のMediumサイズの静的検査で確認できます。必須キー、`name`の一意性とファイル名一致、役割ごとのモデル・推論レベル・sandbox、読み取り専用担当の禁止指示、Skillの機械判定用役割一覧、`hide_spawn_agent_metadata`と`tool_namespace`を検査します。ローカルディスク上の複数ファイルを読むため、Smallサイズではありません。

```bash
nix build .#checks.x86_64-linux.codex-agent-definitions-medium
```

公式仕様: https://learn.chatgpt.com/docs/agent-configuration/subagents.md

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

subagentのモデルと推論強度は、対応するCodex agentの役割から次のように決めています。

- `coding`: 通常の機能追加・修正を担う `code-change-standard` 相当として `openai/gpt-5.6-terra`、`high`。
- `project-research`: 複数ファイルを横断する `project-research-synthesis` 相当として `openai/gpt-5.6-terra`、`high`。
- `code-review`: Codexの `code-review` と同じ `openai/gpt-5.6-sol`、`xhigh`。
- `web-research`: 複数の一次資料を統合する `web-research-synthesis` 相当として `openai/gpt-5.6-terra`、`high`。

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

### OpenCodeの共通権限

`dotfiles/opencode/opencode.json`を `~/.config/opencode/opencode.json` へ配置し、すべてのprimary agentとsubagentへ共通のrm権限を適用します。通常の `rm` は確認を要求し、`/`、絶対パス、`~`、`$HOME`を対象にした再帰削除は拒否します。OpenCodeを `--auto` で起動した場合も、明示的な `deny` は維持されます。

個人用の `~/.config/opencode/opencode.jsonc` は管理対象外です。OpenCodeは `opencode.json` と `opencode.jsonc` をマージするため、provider、モデル、TUIなどの個人設定を `opencode.jsonc` に保持できます。

### OpenCodeの分離方針

このリポジトリは共通rm権限を持つ最小の `opencode.json` だけを管理し、個人用 `opencode.jsonc`、グローバルルール、skills、provider、認証情報は管理しません。Home Managerは次の環境変数で、Claude Code・他ハーネス・プロジェクト共有の設定からOpenCodeを隔離します。

- `OPENCODE_DISABLE_CLAUDE_CODE=true`: `~/.claude/CLAUDE.md`、プロジェクトと親ディレクトリの `CLAUDE.md`、プロジェクトとグローバル（`~/.claude/skills`）の `.claude/skills` の読み込みを無効にします。
- `OPENCODE_DISABLE_EXTERNAL_SKILLS=true`: `~/.claude/`、`~/.agents/`、プロジェクトと親ディレクトリの `.claude/skills`、`.agents/skills` 配下の外部 skills の走査を無効にします。
- `OPENCODE_DISABLE_PROJECT_CONFIG=true`: プロジェクト内・親ディレクトリの共有 `AGENTS.md`、プロジェクト固有の `.opencode/`、`opencode.json` を無効にします。この副作用により、プロジェクトの OpenCode 設定も読み込まれません。

`~/.config/opencode/opencode.jsonc` の個人用グローバル設定は引き続き利用できます。`OPENCODE_DISABLE_EXTERNAL_SKILLS` と `OPENCODE_DISABLE_PROJECT_CONFIG` は公式文書に記載された回避設定です。`OPENCODE_DISABLE_CLAUDE_CODE` は現行実装に依存するため、OpenCodeのアップデート時に挙動を再確認してください。

Home Manager は `~/.opencode/bin` を PATH に追加します。

### OpenCode agent設計の方針

- 複雑なpromptは `opencode.json` へ埋め込まず、役割ごとのMarkdownファイルへ分離します。
- descriptionには「何をするか」と「いつ使うか」を書き、自動選択の誤りを減らします。
- 書き込み権限は `coding` だけに与え、調査・レビュー担当では `edit: deny` を明示します。
- `permission.task: deny` によりsubagentからの再委譲を禁止し、作業経路と責任を明確にします。
- agentごとのモデルとvariantは、対応するCodex agentの役割・判断難度に合わせて固定します。
- プロジェクト設定の自動読み込みを無効化しているため、ローカル担当のpromptで `AGENTS.md` とREADMEを明示的に確認させます。

公式仕様:

- https://opencode.ai/docs/agents/
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
