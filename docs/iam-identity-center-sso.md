# IAM Identity Center（SSO）ログイン用ユーザー発行手順

本資料は、AWS IAM Identity Center（旧 AWS SSO）を利用して、
**開発者が AWS に SSO ログインできるようになるまでの最小手順**を整理したものです。

想定シナリオは以下のとおりです。

* グループ：`develop`
* ユーザー：`taro`
* 権限：PowerUser 相当の権限

---

## 全体像（何を作るか）

1. IAM Identity Center を有効化する
2. ユーザー `taro` を作成する
3. グループ `develop` を作成し、`taro` を所属させる
4. Permission Set（PowerUser 権限）を作成する
5. Permission Set を AWS アカウントに割り当てる（グループ単位）
6. `taro` に SSO ログイン情報を発行・共有する

---

## 1. IAM Identity Center を有効化する

1. AWS マネジメントコンソールに管理者でログイン
2. **IAM Identity Center** を開く
3. 「有効化」を実行

IAM Identity Center コンソール:
- https://console.aws.amazon.com/singlesignon/

※ この時点では、まだ誰もログインできません。

---

## 2. ユーザー `taro` を作成する

1. IAM Identity Center 画面で **Users** を開く
2. **Add user** を選択
3. 以下を入力

* Username: `taro`
* 表示名 / メールアドレス: 組織ルールに従って設定

4. 作成を完了する

※ このユーザーは **IAM ユーザーではありません**。
※ 認証専用の Identity User です。

---

## 3. グループ `develop` を作成し、`taro` を追加する

### グループ作成

1. **Groups** を開く
2. **Create group** を選択
3. Group name: `develop`

### ユーザー追加

1. 作成した `develop` グループを開く
2. **Add users** を選択
3. `taro` を追加

---

## 4. Permission Set（PowerUser）を作成する（SSM 利用前提・短時間セッション）

Permission Set は、**IAM ロールを生成するための設計図**です。
SSM（Session Manager）利用を前提とするため、**セッション時間は短め**に設定します。

> 本資料では「SSM のための SSO 導入」を目的とし、
> セキュリティを優先して短時間セッションを採用します。

1. **Permission sets** を開く
2. **Create permission set** を選択
3. 以下を設定

* Type: AWS managed policy
* Policy: `PowerUserAccess`
* Session duration: **2 hours（推奨）**

4. 作成を完了

※ Session duration は「ログイン有効期間」ではなく、
**ロールを引き受けた後の一時クレデンシャルの有効時間**です。

---

## 5. Permission Set を AWS アカウントに割り当てる

ここで初めて、AWS アカウント上に **IAM ロールが自動生成**されます。

1. **AWS accounts** を開く
2. 対象の AWS アカウントを選択
3. **Assign users or groups** を選択
4. 以下を指定

* Principal type: Group
* Group: `develop`
* Permission set: `PowerUserAccess`

5. 割り当てを完了

※ この操作により、AWS アカウント内に
`AWSReservedSSO_...` という IAM ロールが作成されます。

---

## 6. `taro` に SSO ログイン情報を発行・共有する

### 管理者が行うこと

* IAM Identity Center の **Settings** から
  SSO ユーザーポータルの URL を確認

SSO ユーザーポータル URL の例:
- https://d-xxxxxxxxxx.awsapps.com/start
- https://<subdomain>.awsapps.com/start

### `taro` に共有する情報

* SSO ログイン URL
* 初期ユーザー名（`taro`）
* 初期パスワード（初回ログイン用）

※ 初回ログイン後のパスワード管理はユーザー自身が行います。
※ 管理者がログインのたびに何かを発行する必要はありません。

### `taro` のログイン手順（利用者視点）

1. SSO ポータル URL にアクセス
2. ユーザー名・パスワードでログイン
3. 表示された AWS アカウントを選択
4. `PowerUserAccess` 権限で AWS コンソールへ遷移

---

## 7. SSM Session Manager を使って EC2 に接続する

本構成では、SSH や踏み台サーバを使わず、
**SSM Session Manager** を用いて EC2 に接続します。

### 事前条件（管理者側）

* EC2 インスタンスに以下が設定されていること

  * SSM Agent がインストール済み
  * IAM ロールに `AmazonSSMManagedInstanceCore` が付与されている
* 対象インスタンスが SSM に「Managed Instance」として認識されていること

---

### コンソールから接続する手順（利用者）

1. SSO 経由で AWS マネジメントコンソールにログイン
2. **Systems Manager** を開く
3. 左メニューから **Session Manager** を選択
4. **Start session** をクリック
5. 一覧から対象の EC2 インスタンスを選択
6. セッションを開始

→ ブラウザ上でシェル接続が開始されます

---

### CLI から接続する手順（参考）

```bash
aws sso login
aws ssm start-session --target <instance-id>
```

* セッション有効期限（例：2 時間）を超えると自動切断されます
* 再接続する場合は `aws sso login` を再実行します

---

## 補足：重要な設計上のポイント

* グループ自体がログインすることはありません
* 実際に操作する主体は常に **User（taro）** です
* 権限は User ではなく **Permission Set → IAM ロール** に存在します
* 退職・異動時は

  * グループから外す or ユーザーを無効化するだけで対応可能です

---

## まとめ

* User / Group：人の管理（認証）
* Permission Set：権限の設計図
* IAM ロール：AWS が実際に評価する権限の実体
* SSO ログイン：User が IAM ロールを一時的に引き受ける仕組み

本手順により、IAM ユーザーを作成せずに、安全な AWS アクセスを提供できます。
