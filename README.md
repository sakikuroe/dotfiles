# dotfiles

## 目的

このリポジトリーは, Nushell と Git の設定を symlink で管理します.
現在の対象は, `config/nushell/config.nu`, `config/nushell/env.nu`, `home/.gitconfig`, `config/git/ignore` です.

## 前提

- Git
- Nushell (`nu`)

## 導入手順

```bash
git clone <REPO_URL> ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

## `install.sh` の動作

- `config/nushell/config.nu` を `~/.config/nushell/config.nu` にリンクします.
- `config/nushell/env.nu` を `~/.config/nushell/env.nu` にリンクします.
- `config/git/ignore` を `~/.config/git/ignore` にリンクします.
- `home/.gitconfig` を `~/.gitconfig` にリンクします.
- 既存ファイルがある場合は `*.bak.<timestamp>` へ退避します.
- 同一リンク済みの場合は変更せずスキップします.

## Git の個人情報分離

`user.name` と `user.email` は `~/.gitconfig.local` に分離します.
このファイルは git 管理しません.
`home/.gitconfig` には `include.path = ~/.gitconfig.local` を設定しています.

```bash
cp ~/dotfiles/home/.gitconfig.local.example ~/.gitconfig.local
git config --file ~/.gitconfig.local user.name "YOUR_NAME"
git config --file ~/.gitconfig.local user.email "you@example.com"
```

`git config --global user.name ...` と `git config --global user.email ...` は `~/.gitconfig` へ書き込まれます.
`~/.gitconfig.local` へ書き込む場合は, `--file ~/.gitconfig.local` を使用します.

## 反映確認

```bash
ls -l ~/.config/nushell/config.nu ~/.config/nushell/env.nu
ls -l ~/.config/git/ignore
nu -i -c 'exit'
git config --global --get core.excludesfile
git config --show-origin --get-all include.path
git check-ignore -v .github/copilot-instructions.md
git config --global --list --show-origin
```

`nu` 起動時に設定読込エラーが出ないこと, `core.excludesfile` に `~/.config/git/ignore` が表示されること, `include.path` に `~/.gitconfig.local` が表示されること, `~/.gitconfig` / `~/.gitconfig.local` が読み込まれていることを確認してください.
