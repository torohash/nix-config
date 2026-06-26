## 委譲前の曖昧性解決（/delegate）
- タスク開始前に ambiguity-detector を呼び曖昧点を洗い出す。
- 各ギャップは最も安いチャネルで解決：
  - inferable_from があれば自分で解決（訊かない）
  - statable × high-consequence → 人間にバッチで質問
  - recognizable（dark, colorfull, white 等の質感語）→ 捨てプロトタイプを見せ反応を取る
  - low-consequence → 既定値で仮置きし spec に「(仮定)」と明記
- high-consequence の定義: 公開API・DBスキーマ・認可・データ削除・外部契約に関わる判断。
