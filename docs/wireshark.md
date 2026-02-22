# Wireshark

## 概要

Wiresharkはネットワークパケットキャプチャ・解析ツール。
ネットワーク上を流れるパケットをリアルタイムで傍受・表示し、中身を詳細に解析できる。

## 主な用途

- ネットワークトラブルシューティング（TCP handshake 失敗、DNS 解決問題など）
- プロトコル解析（HTTP, TCP, UDP, DNS, TLS など）
- セキュリティ調査（不審な通信の検出）
- 開発時のデバッグ（API 通信の確認、WebSocket フレームの確認など）

## Fedora へのインストール

ライブパケットキャプチャには `dumpcap` に `CAP_NET_RAW` ケーパビリティが必要。
Nix（home-manager）経由ではこの権限が自動設定されないため、Fedora の dnf でインストールする。

```bash
sudo dnf install wireshark
sudo usermod -aG wireshark $(whoami)
```

グループ変更の反映にはログアウト→ログインが必要。

## Nix でインストールしない理由

- Nix の home-manager では `dumpcap` に `CAP_NET_RAW` / `CAP_NET_ADMIN` が付与されない
- NixOS であれば `programs.wireshark.enable = true` で自動設定されるが、Fedora 上の home-manager では不可
- 手動で `sudo setcap cap_net_raw,cap_net_admin=eip $(readlink -f ~/.nix-profile/bin/dumpcap)` を実行すれば動作するが、パッケージ更新のたびに再設定が必要
- Qt6 ベースの GUI アプリのため nixGL ラッピングも必要になり、管理コストが高い

## 基本的な使い方

```bash
# GUI を起動
wireshark

# CLI でキャプチャ（tshark）
tshark -i eth0

# 特定ポートのみキャプチャ
tshark -i eth0 -f "port 443"

# pcap ファイルの読み込み
wireshark capture.pcap
```

## キャプチャフィルタの例

| フィルタ | 説明 |
|---------|------|
| `tcp.port == 80` | HTTP 通信 |
| `tcp.port == 443` | HTTPS 通信 |
| `dns` | DNS クエリ/レスポンス |
| `ip.addr == 192.168.1.1` | 特定 IP のトラフィック |
| `http.request.method == "POST"` | HTTP POST リクエスト |
