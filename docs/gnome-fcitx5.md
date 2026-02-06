# GNOMEとfcitx5の関係

## まとめ

- GNOMEの入力ソース切替とfcitx5のIM切替は別物で、基本的に同期しない。
- GNOMEの入力ソースはXKB/IBus前提、fcitx5は独立したIMフレームワーク。
- kimpanel拡張は候補ウィンドウ表示用で、入力ソース同期の役割はない。

## GNOMEの入力ソース

GNOMEは `org.gnome.desktop.input-sources` で入力ソースを管理する。
ここで扱うのはXKBレイアウトとIBusエンジンで、fcitx5の内部状態は管理しない。

## fcitx5のIM切替

fcitx5は独自のホットキーと状態管理を持つ。
切替はfcitx5側の設定（`~/.config/fcitx5/config` など）で行う。

## GNOME + Wayland + fcitx5の挙動

- GNOMEはWayland上でIBusのDBusプロトコルを使用。
- fcitx5はIBusフロントエンドで互換を提供するが、GNOME入力ソースと自動同期はしない。

## 運用方針

- GNOME入力ソースの切替ではなく、fcitx5側の切替を主に使う。
- GNOMEの入力ソース設定は必要な場合にだけ使う。
