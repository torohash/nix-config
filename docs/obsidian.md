# Obsidian 再構築ガイド（開発者向け）

このドキュメントは、Obsidian 環境を再作成するときに、現在の要件を短時間で再現するための手順をまとめたものです。

## 目的

- Obsidian 本体は Nix（Home Manager）で管理する。
- デイリーノートを `notes/YYYY/MM/YYYY-MM-DD.md` で作成する。
- 貼り付け画像を `assets/YYYY/MM/file-YYYYMMDDHHmmssSSS.png` 形式で保存する。
- Dataview と Obsidian Git を利用可能にする。

## 運用方針

- **Nix 管理**: Obsidian アプリ本体（`pkgs.obsidian`）。
- **Vault ローカル管理**: `.obsidian` 配下の設定・プラグイン設定。
- **Vault Git**: 現在は `.obsidian/*` を ignore（設定は Git 管理しない）。

理由: Obsidian の設定は実行中に変化しやすく、完全宣言管理にすると運用コストが高くなるため。

## Nix 側の前提（このリポジトリ）

以下が満たされていれば Obsidian 本体は導入済みになります。

- `nix/home/platforms/ubuntu/modules.nix`: `home.packages` に `obsidian`
- `nix/home/platforms/fedora/modules.nix`: `home.packages` に `obsidian`
- `nix/home/common/dotfiles.nix`: `allowUnfreePredicate` に `"obsidian"`

適用コマンド例:

```bash
home-manager switch --flake /home/torohash/nix-config#torohash_fedora
```

## Vault 側の必須設定

Vault のルートを `<vault>` とします（例: `/home/torohash/Documents/vault`）。

### 1) デイリーノート設定

`<vault>/.obsidian/daily-notes.json`

```json
{
  "folder": "notes",
  "format": "YYYY/MM/YYYY-MM-DD",
  "template": "",
  "autorun": false
}
```

これで生成先は `notes/YYYY/MM/YYYY-MM-DD.md` になります。

### 2) 添付先の基本設定

`<vault>/.obsidian/app.json`

```json
{
  "attachmentFolderPath": "assets",
  "promptDelete": false
}
```

### 3) Community Plugins

有効化対象:

- `dataview`
- `obsidian-custom-attachment-location`
- `obsidian-git`

設定ファイル:

`<vault>/.obsidian/community-plugins.json`

```json
[
  "dataview",
  "obsidian-custom-attachment-location",
  "obsidian-git"
]
```

### 4) 画像保存ルール（Custom Attachment Location）

`<vault>/.obsidian/plugins/obsidian-custom-attachment-location/data.json`

最低限必要なキー:

```json
{
  "attachmentFolderPath": "assets/${date:{momentJsFormat:'YYYY/MM'}}",
  "attachmentRenameMode": "Only pasted images",
  "generatedAttachmentFileName": "file-${date:{momentJsFormat:'YYYYMMDDHHmmssSSS'}}",
  "shouldRenameAttachmentFiles": true,
  "shouldRenameAttachmentFolder": false
}
```

これで貼り付け画像は `assets/YYYY/MM/file-YYYYMMDDHHmmssSSS.*` 形式になります。

## プラグインの再導入手順

### 手順A（推奨: Obsidian UI）

1. Settings → Community plugins → Safe mode off
2. Browse から以下をインストールして有効化
   - Dataview
   - Custom Attachment Location
   - Git
3. 上記 JSON 設定を反映

### 手順B（CLI で手動配置）

`obsidian-custom-attachment-location` と `obsidian-git` は `main.js` / `manifest.json` / `styles.css` を
`<vault>/.obsidian/plugins/<plugin-id>/` に配置すれば動作します。

## 検証チェックリスト

1. デイリーノート作成で `notes/YYYY/MM/YYYY-MM-DD.md` に作成される
2. 画像貼り付けで `assets/YYYY/MM/file-*.png` に作成される
3. Vault ルートに `not556/` や `assets/YYYY-MM-DD/` が作られない
4. Dataview のコマンドが利用可能
5. Obsidian Git の Source Control View が開ける

## トラブルシュート

- 期待と違う場所にファイルが作られる:
  - `daily-notes.json` の `folder` / `format` を再確認
  - `obsidian-custom-attachment-location/data.json` の `attachmentFolderPath` を再確認
  - Obsidian を再起動して設定再読込
- 以前の誤設定が残る:
  - `workspace.json` の `lastOpenFiles` は履歴なので必要なら手動で整理
