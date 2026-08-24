---
name: unity-cli
description: UnityプロジェクトでScene、Prefab、GameObject、Component、Inspector参照、Assetを変更するとき、またはUnity Editorの起動、import、C#コンパイル、テスト、ビルドを操作・検証するときに使用する。ローカルに導入済みのUnity CLIをbashから利用する。
compatibility: Unity CLIがPATH上で利用できるLinux、macOS、Windows環境
---

# Unity CLIでUnityプロジェクトを操作する

UnityのScene、Prefab、Assetなど、Unity Editorが所有するデータはUnity CLI経由の操作を優先する。インストール済みCLIの仕様を`--help`と実行結果から確認し、利用できないコマンド名や引数を推測しない。

## プロジェクトを確認する

1. `Assets/`、`Packages/`、`ProjectSettings/`を持つディレクトリをUnityプロジェクトルートとして特定する。Gitリポジトリのルートと同じとは限らない。
2. CLIとプロジェクト情報を確認する。

   ```bash
   command -v unity
   unity --version
   unity projects info "$project_path" --format json
   ```

3. `ProjectSettings/ProjectVersion.txt`のEditorバージョンと、インストール済みEditorを確認する。

   ```bash
   unity editors --format json
   ```

4. プロジェクトが要求するEditorバージョンを維持する。EditorやPipeline packageのインストール、更新、プロジェクトのバージョン変更は、依頼に含まれる場合だけ行う。

## 実行経路を選ぶ

### Editorへ接続できる場合

同じプロジェクトを開いているEditorとPipeline packageの状態を確認する。

```bash
unity status --project-path "$project_path" --format json
unity pipeline list --format json
```

Pipelineサーバーへ接続できる場合は、登録済みコマンドを列挙してから必要なコマンドを実行する。

```bash
unity list --project-path "$project_path" --format json
unity command --project-path "$project_path" <command> <args...> --format json
```

- `unity list`が返したコマンド名と引数だけを使用する。
- Scene、Prefab、GameObject、Component、Inspector参照、Assetの作成・更新・保存は、対応する登録済みコマンドがあればそれを使う。
- コマンド実行後は、対象を保存するコマンドの成否まで確認する。
- Editorが同じプロジェクトを開いている間は、同じプロジェクトへ別のbatch mode Editorを起動しない。

### Editor操作が必要だが接続できない場合

SceneやPrefabなどのEditor操作が必要なら、要求されたバージョンのEditorがインストール済みであることを確認してからプロジェクトを開く。

```bash
unity open "$project_path"
```

起動後は`unity status`と`unity pipeline list`を再確認する。既存のEditorプロセスが動作しているのにPipelineサーバーへ接続できない場合は、別のEditorを起動せず状態とエラーを報告する。未保存データを失う可能性があるため、既存Editorの終了や再起動は確認を得てから行う。壊れやすいUnity YAMLの直接編集へ無条件に切り替えない。

### Headless実行する場合

同じプロジェクトのEditorが動作していないことを確認してから実行する。

C#コンパイルとimportの確認には、プロジェクト指定の追加引数がなければ次を基準にする。

```bash
unity run "$project_path" --timeout 600 -- -quit -logFile -
```

テストがある場合は、結果XMLを作業ツリー外へ出力する。

```bash
result_file="$(mktemp)"
unity test "$project_path" --mode EditMode --output "$result_file" --timeout 600
```

PlayModeが必要なテストは`--mode PlayMode`で別に実行する。ビルドはプロジェクト内の文書と既存のビルド用Editorメソッドを確認し、存在する`--execute-method`だけを使用する。ビルド用メソッドがなければ名前を推測して作らない。

## Unityデータを変更する

- SceneとPrefabは、可能な限り接続中のEditorへ登録されたコマンドで変更する。
- `.meta`とGUIDはUnityに生成・維持させる。既存参照のGUIDを手作業で置き換えない。
- UI変更ではGameObject階層、RectTransform、参照先Component、Canvasの基準解像度を確認する。
- ScriptableObjectやPrefabのInspector参照を設定した場合は、保存後に参照切れがないことを確認する。
- 毎回`unity <command> --help`を利用できるため、CLIのversion差が疑われる場合はローカルのhelpを正とする。

## 完了前に確認する

1. Unityコマンドの終了状態とEditorログにコンパイルエラーがないことを確認する。
2. `git status --short`と`git diff`で、意図したAsset、Scene、Prefab、`.meta`だけが変更されたことを確認する。
3. SceneやPrefabを変更した場合は、保存済みであることとInspector参照が維持されていることを確認する。
4. テストが存在する場合は対象のEditModeまたはPlayModeテストを実行する。
5. ビルドが依頼またはプロジェクトの完了条件に含まれる場合だけ、既存のビルド経路で実行する。
