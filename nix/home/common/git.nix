{ ... }:
{
  programs.git = {
    enable = true;
    # 素材などの大容量ファイル管理に Git LFS を使う（git lfs install 相当の設定も自動で入る）
    lfs.enable = true;
    settings.user = {
      name = "torohash";
      email = "123091263+torohash@users.noreply.github.com";
    };
  };
}
