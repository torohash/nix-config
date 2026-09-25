# Omarchy との分担

Omarchy (Arch Linux + Hyprland) では **Omarchy を優先**する。
Home Manager は Omarchy が扱わないものだけを受け持つ。

- 構成: `homeConfigurations.torohash_omarchy`
- 入口: `nix/home/hosts/torohash_omarchy.nix` → `nix/home/platforms/omarchy/modules.nix`
- `common/modules.nix` は読み込まない。シェル・エディタ・git・端末が Omarchy の管理と競合するため。
- Home Manager が扱うのは Pi の `models.json` と `web-search.json`、`settings.json` の `compaction` だけ(`common/agents.nix`)。

## 所有者

**1ファイル = 1所有者**。

| 対象 | 所有者 | 理由 / 方法 |
|------|--------|-------------|
| Hyprland / Omarchy shell / テーマ | Omarchy | `~/.config/hypr/`, `~/.config/omarchy/` |
| 端末 (ghostty / alacritty / foot / kitty) | Omarchy | テーマを `config-file` で読み込み、`omarchy theme set` で追従する |
| `~/.bashrc` | Omarchy | Omarchy の `env-bootstrap` と `rc` を読み込む |
| git (`~/.config/git/config`) | Omarchy | Omarchy の既定 (rebase / histogram / rerere など) を使う |
| nvim | Omarchy | LazyVim (`omarchy-nvim`)。テーマのホットリロード付き |
| tmux / lazygit / btop / starship | Omarchy | Omarchy が配置し、btop はテーマに追従する |
| herdr | Omarchy | Omarchy の既定に、agent / workspace 移動キーを足す (Omarchy 側の手順で管理) |
| fcitx5 + Mozc | Omarchy | pacman 版の fcitx5 が自動起動する。Home Manager の `i18n.inputMethod` は使わない |
| CLI / 言語ランタイム | Omarchy | pacman (`omarchy pkg add`) と mise |
| AI CLI 本体 (claude / codex / pi / opencode) | Omarchy | `omarchy-mise-install` が `~/.local/bin/` に mise の wrapper を置く |
| `~/.pi/agent/models.json`, `~/.pi/web-search.json` | **Nix** | `common/agents.nix` |
| `~/.pi/agent/settings.json` | **Nix + Omarchy + Pi** | `piSettings` activation が `compaction` だけを書き換える。package は `pi install` で入れる (`docs/pi-packages.md`)。`theme` は Omarchy が書き、Pi 自身も書く |
| その他のエージェント設定 (`~/.claude/`, `~/.codex/`, `~/.config/opencode/` など) | 管理しない | Nix では持たない。Omarchy がテーマ・skills の symlink を書き、ツール自身も書き込む |
| 既定エージェント | Omarchy | `omarchy default agent <name>` |

`nix flake check` の `omarchy-ownership-medium` は、この表の Omarchy 側のファイルを Home Manager が管理していないことを検査する。

### Omarchy が書き込む場所 (調査元)

| 何を | どこに | Omarchy の出どころ |
|------|--------|--------------------|
| AI CLI の wrapper | `~/.local/bin/{claude,codex,pi,opencode,…}` | `install/user/mise.sh` |
| skills の symlink | `~/.agents/skills` `~/.claude/skills` `~/.codex/skills` `~/.pi/agent/skills` | `bin/omarchy-provision-user`, migrations |
| Claude Code のテーマ | `~/.claude/settings.json` の `theme`, `~/.claude/themes/omarchy.json` | `bin/omarchy-theme-set-claude` |
| Pi のテーマ | `~/.pi/agent/settings.json` の `theme`, `~/.pi/agent/themes/` | `bin/omarchy-theme-set-pi` |
| OpenCode の設定 | `~/.config/opencode/opencode.json` | `config/opencode/opencode.json` |

(いずれも `/usr/share/omarchy/` からの相対パス)

## 入れるパッケージ

**なし**。バイナリは Omarchy が入れるもの (`/usr/share/omarchy/install/omarchy-base.packages` と `install/user/mise.sh`) を使う。
足りないものは Omarchy の流儀で入れる:

```bash
omarchy pkg add <pkg>         # pacman
omarchy pkg aur add <pkg>     # AUR
mise use -g <tool>            # CLI / ランタイム
```

## 適用手順

### 1. Nix を入れる

```bash
omarchy pkg add nix
sudo systemctl enable --now nix-daemon.socket
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

Arch の `nix` パッケージには `nix-users` グループが無い。`/etc/nix/nix.conf` の `allowed-users` は既定で `*` なので、グループに入らなくても daemon を使える。

### 2. Home Manager を適用する

```bash
nix registry add nixcfg path:$HOME/dev/nix-config
nix run github:nix-community/home-manager -- switch --flake nixcfg#torohash_omarchy   # 初回
home-manager switch --flake nixcfg#torohash_omarchy                                  # 2回目以降
```

## 検証

```bash
nix flake check                                   # omarchy-ownership-medium を含めて成功する
readlink ~/.pi/agent/models.json                  # => /nix/store/…-home-manager-files/.pi/agent/models.json
readlink ~/.pi/web-search.json                    # => /nix/store/…-home-manager-files/.pi/web-search.json
ls -l ~/.claude/skills                            # omarchy / diagnose-crash の symlink はそのまま
readlink ~/.bashrc                                # => 何も出ない (Home Manager の symlink ではない)
```

## ハマりどころ

- **Pi の `settings.json` は symlink にしない**: Omarchy のテーマ切替と Pi 自身が書き込むため。activation のマージで `theme` などは残る。
- **npm でグローバルにインストールしない**: `~/.local/bin/` にある Omarchy の wrapper を上書きしかねない。他ホスト用の `NPM_CONFIG_PREFIX` は Omarchy では設定しない。
