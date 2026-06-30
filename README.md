# dotfiles

## 目的

このリポジトリーは、ホームディレクトリー直下と `~/.config` 配下の設定ファイルを symlink で管理し、複数 PC で同一状態を再現できるようにする。
`install.sh` でリンク作成と既存ファイルの退避を自動化し、手動作業による事故を減らす。

## 前提

Linux を想定する。

導入には Git が必要。`install.sh` は bash で動作する。
追加で必要なコマンドがある場合は、`install.sh` が不足をエラーメッセージとして表示して終了する。

## 導入手順

```bash
git clone <REPO_URL> ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

## `install.sh` の動作

- `~/dotfiles` 配下の設定ファイルを、`$HOME` 配下へ symlink で反映する。
- 既存ファイルがある場合は、`*.bak.<timestamp>` へ退避してからリンクする。
- 同一リンク済みの場合は変更せず、`already linked:` としてスキップする。
- 外部リソース (フォントなど) をダウンロードして配置する場合がある。
- ローカル専用の設定を混入させないため、一部は symlink ではなく include 構成で反映する。

## 秘密情報とローカル差分

このリポジトリーでは、秘密情報や個人情報は管理しない。
各 PC 固有の値は、ローカルファイルに分離して運用する。

例として、Git の個人情報 (`user.name`、`user.email`) は、`~/.gitconfig.local` に分離する。
このファイルは git 管理しない。

`install.sh` は `~/.gitconfig` をローカルファイルとして扱い、次の include を設定する (共有設定とローカル差分の分離)。

- `~/.config/git/config`
- `~/.gitconfig.local`

初回セットアップ例を以下に示す。

```bash
cp ~/dotfiles/home/.gitconfig.local.example ~/.gitconfig.local
git config --file ~/.gitconfig.local user.name "YOUR_NAME"
git config --file ~/.gitconfig.local user.email "you@example.com"
```

`git config --global ...` は `~/.gitconfig` へ書き込まれるため、`~/.gitconfig.local` へ書き込みたい場合は `--file ~/.gitconfig.local` を使用すること。

## エージェント設定

Claude Code および Codex 向けのスキル設定は `.claude/` で管理している。
各プロジェクトへの導入方法は [.claude/README.md](./.claude/README.md) を参照すること。

## 反映確認

```bash
./install.sh
# 2 回目以降の実行で `already linked:` が増えることを確認する。
./install.sh
```

1 回目の実行で `linked:` が出力され、2 回目以降の実行で同一リンク済みの項目が `already linked:` としてスキップされることを確認すること。
