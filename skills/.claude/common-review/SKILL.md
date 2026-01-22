
Oracleを利用し、現在の差分からレビューを実行させる。
レビューの内容をもとに修正。修正指摘がなければ終了
修正作業を行った場合再びレビューを実行し、修正指摘がなくなるまで繰り返す。

git diff HEAD && git ls-files --others --exclude-standard \
  | xargs -I{} git diff --no-index /dev/null {}

差分は上記コマンドを利用し取得する
