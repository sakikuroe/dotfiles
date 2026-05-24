# WezTerm 設定

## SSH 接続先の設定方法

このリポジトリーの `wezterm.lua` は `wezterm.default_ssh_domains()` を使って `~/.ssh/config` から SSH 接続先を自動的に読み込みます.
接続先のホスト名・アドレス・ユーザー名は `~/.ssh/config` に記述し, このリポジトリーには含めません.

### ~/.ssh/config の記述例

```
Host myserver
  HostName 192.168.1.100
  User myuser
```

## SSH マルチプレクサーへの接続

`~/.ssh/config` に Host を定義すると, 以下のコマンドで接続できます.

```
wezterm connect SSHMUX:myserver
```

`SSHMUX:<host>` はサーバー上で動いている WezTerm マルチプレクサーに接続します.
サーバー上にワークスペースが 2 つ以上ある場合は, 接続直後に選択画面が自動表示されます.

## ワークスペース操作

| キー | 動作 |
|------|------|
| Alt+Shift+W | ワークスペース一覧を表示して切り替える |
| Alt+W | 新しいワークスペースを名前をつけて作成する |
