# AWS CLI / SSM

common-store に awscli2 と ssm-session-manager-plugin を含めています。
このリポジトリでは認証情報やプロファイル設定の中身は管理しません。

## セットアップ（SSO）

SSO は AWS IAM Identity Center（旧 AWS SSO）を使ったサインイン方式です。
ブラウザでログインしてトークンを取得し、CLI から AWS にアクセスします。

IAM Identity Center のユーザー発行・権限割り当て手順は以下を参照してください。
- `docs/iam-identity-center-sso.md`

### 事前準備

SSO に必要な情報は IAM Identity Center のコンソールで確認できます。

1. IAM Identity Center コンソールを開く
   - https://console.aws.amazon.com/singlesignon/
2. 画面の Dashboard から Settings summary を開き、以下を確認する
   - Start URL（AWS access portal URL）
   - Region
   - Start URL の例: https://d-xxxxxxxxxx.awsapps.com/start または https://<subdomain>.awsapps.com/start
3. 2 で確認した Start URL にアクセスし、ポータルにサインインできることを確認する

この Start URL と Region を `aws configure sso` の入力に使います。

SSO プロファイルを作成します。

```bash
aws configure sso --profile <profile>
```

サインインします。

```bash
aws sso login --profile <profile>
```

公式ドキュメント: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html

## プロファイル切替

プロファイルは `AWS_PROFILE` または `--profile` で切り替えます。

```bash
AWS_PROFILE=<profile> aws sts get-caller-identity
aws sts get-caller-identity --profile <profile>
```

公式ドキュメント: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html

## .envrc の活用

AWS プロファイルの切替はプロジェクトごとの `.envrc` に `AWS_PROFILE` を書くと簡単です。

```bash
# 既存の .envrc に追記
export AWS_PROFILE=<profile>
```

初回のみ `direnv allow` を実行します。
`direnv` が有効であれば、ディレクトリを離れると環境変数は元に戻ります。
認証情報やトークンは書かないでください。

## SSM Session Manager

SSM Session Manager の例です。

```bash
aws ssm start-session --target i-xxxxxxxx --profile <profile>
```

`ssm-session-manager-plugin` が必要です（common-store に含まれています）。
ターゲット側には SSM Agent と必要な権限・到達性が必要です。

公式ドキュメント: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-prerequisites.html
