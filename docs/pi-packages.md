# Pi の package 手順書

Pi の package (拡張) は **Home Manager で管理しない**。Pi 自身の `pi install` で入れ、入れるものはこの手順書に書く。
エージェントはこの手順書をなぞって導入・追加・削除してよい。

## 方針

- `~/.pi/agent/settings.json` の `packages` は Pi が書き換える。Home Manager は `compaction` だけを書き、`packages` には触れない (`nix/home/common/agents.nix`)。
- 全ホストで使うものは下の「入れる package」に書く。ホストやプロジェクト固有のものはここに書かず、`-l` でプロジェクトに入れる。
- version は固定しない。実体は Pi が `~/.pi/agent/npm/` に入れる。

## 入れる package

| source | 用途 |
|--------|------|
| `npm:pi-web-access` | Web 検索・取得。設定は `~/.pi/web-search.json` (Home Manager が配置) |
| `npm:@ff-labs/pi-fff` | ファイル検索 |
| `npm:@ogulcancelik/pi-session-recall` | 過去セッションの参照 |
| `npm:pi-token-speed` | トークン速度の表示 |

## 導入

```bash
pi install npm:pi-web-access
pi install npm:@ff-labs/pi-fff
pi install npm:@ogulcancelik/pi-session-recall
pi install npm:pi-token-speed
```

`-l` を付けないと、グローバルの `~/.pi/agent/settings.json` に追加される。

## 追加・削除

```bash
# 全ホストで使う: 入れてから、上の表と導入コマンドに追記する
pi install <source>

# そのプロジェクトだけで使う: .pi/settings.json に書かれる。この手順書には書かない
pi install -l <source>

# ローカルのリポジトリを使う (例): パスは clone した場所に合わせる
pi install ~/dev/photo-sync

# 削除: 表と導入コマンドからも消す
pi remove <source>
```

source の書き方: `npm:<pkg>` / `git:github.com/<user>/<repo>` / `https://github.com/<user>/<repo>` / ローカルパス。

## 検証

```bash
pi list
# => User packages:
#      npm:pi-web-access
#        /home/<user>/.pi/agent/npm/node_modules/pi-web-access
#      … (上の表の4つがすべて出る)
jq '.packages' ~/.pi/agent/settings.json   # => 上の表の source が並ぶ
jq '.compaction' ~/.pi/agent/settings.json # => {"enabled": true, "reserveTokens": 150000} (Home Manager 適用後)
```

## 更新

```bash
pi update --extensions      # 入れている package を更新する
```

## ハマりどころ

- **Home Manager に `packages` を戻さない**: activation が `packages` を丸ごと書くと、`pi install` で足したものが `home-manager switch` のたびに消える。
- **ローカルパスを全ホスト共通にしない**: clone していないホストでは存在しないパスになる。
