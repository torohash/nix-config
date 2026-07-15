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

このリポジトリは`~/.codex/config.toml`を管理しません。`[agents]`を利用環境で設定していない場合、Codexの既定値は`max_threads = 6`、`max_depth = 1`です。カスタムエージェントのモデルと推論レベルは各TOMLで管理し、起動時には上書きしません。

定義とSkillの対応は次のMediumサイズの静的検査で確認できます。必須キー、`name`の一意性とファイル名一致、役割ごとのモデル・推論レベル・sandbox、読み取り専用担当の禁止指示、Skillの機械判定用役割一覧を検査します。ローカルディスク上の複数ファイルを読むため、Smallサイズではありません。

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

### OpenCode 設定ファイル

OpenCode の設定は Home Manager 経由で `~/.config/opencode` に配置します。

- `dotfiles/opencode/opencode.json`
- `dotfiles/opencode/oh-my-opencode.json`
- `dotfiles/opencode/AGENTS.md`
- `dotfiles/opencode/skills/`

`dotfiles/opencode/skills/` 配下の `SKILL.md` は `~/.config/opencode/skills/` に同期され、OpenCode からユーザースキルとして読み込まれます。

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
