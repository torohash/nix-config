# Home Manager stateVersion と更新ライフサイクル

## 概要

`home.stateVersion` は、Home Manager 設定が互換性を持つリリースバージョンを示す重要な設定です。この値により、Home Manager が新しいバージョンで後方互換性のない変更を導入した際に、設定の破損を防ぐことができます。

**重要**: `home.stateVersion` は初回インストール時のバージョンに維持し、変更しないことが推奨されています。

## 設定場所

このリポジトリでは `nix/home/config.nix` で設定しています。

## 何时に更新すべきか

### 基本原則

- **通常は変更しないでください**: Home Manager 自体を更新しても、この値を変更する必要はありません
- **意図的に更新する場合のみ**: リリースノートを確認し、マイグレーション手順がある場合のみ更新を検討してください

公式マニュアルより:

> This value determines the Home Manager release that your configuration is
> compatible with. This helps avoid breakage when a new Home Manager release
> introduces backwards incompatible changes.
>
> You can update Home Manager without changing this value. See
> the Home Manager release notes for a list of state version
> changes in each release.

### State Version を変更する前に

リリースノートの "State Version Changes" セクションを確認してください。新しいバージョンへの変更には、以下のような手動操作が必要になる場合があります:

- データの変換
- ファイルの移動
- 設定オプションの調整

## 有効な stateVersion 値

有効な値は公式のオプション定義に列挙されています。最新の一覧は必ず参照先を確認してください。

## State Version の変更を確認する

### リリースノート

各リリースのリリースノートには "State Version Changes" セクションが含まれています。このセクションには、そのリリースで導入された breaking changes のみが記載されています。

### 公式ドキュメント

以下の公式ドキュメントを参照してください:

1. **Home Manager マニュアル** - 設定例と stateVersion の説明
   - https://nix-community.github.io/home-manager/

2. **リリースノート** - 各バージョンの State Version Changes
   - https://nix-community.github.io/home-manager/release-notes.xhtml

3. **stateVersion オプション定義** - ソースコードと説明
   - https://github.com/nix-community/home-manager/blob/master/modules/misc/version.nix

4. **MyNixOS オプションリファレンス** - 日本語アクセス可能な説明
   - https://mynixos.com/home-manager/option/home.stateVersion

## 注意点

- **公式の非推奨リストは存在しません**: 古い stateVersion を使用していても、問題なく機能し続けます
- **マイグレーションが必要な場合のみ更新**: リリースノートに明示的なマイグレーション手順がある場合にのみ更新を検討してください
- **バックアップを推奨**: stateVersion を変更する前に、重要な設定ファイルとデータのバックアップを作成してください

## 関連リンク

- Home Manager Manual: https://nix-community.github.io/home-manager/
- Release Notes: https://nix-community.github.io/home-manager/release-notes.xhtml
- stateVersion Source: https://github.com/nix-community/home-manager/blob/master/modules/misc/version.nix
- MyNixOS option reference: https://mynixos.com/home-manager/option/home.stateVersion
