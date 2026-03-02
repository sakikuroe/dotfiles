# dotfiles

## 目的

このリポジトリーは, Nushell と Git の設定を symlink で管理します.
現在の対象は, `config/nushell/config.nu`, `config/nushell/env.nu`, `config/git/config`, `config/git/ignore` です.

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
- `config/git/config` を `~/.config/git/config` にリンクします.
- `config/git/ignore` を `~/.config/git/ignore` にリンクします.
- `~/.gitconfig` が symlink の場合は退避し, ローカルファイルとして再作成します.
- `~/.gitconfig` に `~/.config/git/config` と `~/.gitconfig.local` の `include.path` を設定します.
- 既存ファイルがある場合は `*.bak.<timestamp>` へ退避します.
- 同一リンク済みの場合は変更せずスキップします.

## Git の個人情報分離

`user.name` と `user.email` は `~/.gitconfig.local` に分離します.
このファイルは git 管理しません.
`install.sh` は `~/.gitconfig` をローカル専用ファイルとして扱い, `include.path` だけを設定します.

```bash
cp ~/dotfiles/home/.gitconfig.local.example ~/.gitconfig.local
git config --file ~/.gitconfig.local user.name "YOUR_NAME"
git config --file ~/.gitconfig.local user.email "you@example.com"
```

`git config --global user.name ...` と `git config --global user.email ...` は `~/.gitconfig` へ書き込まれます.
共有設定は `~/.config/git/config` で管理されるため, `~/.gitconfig` に個人情報が追記されても dotfiles 管理対象へ混入しません.
`~/.gitconfig.local` へ明示的に書き込む場合は, `--file ~/.gitconfig.local` を使用します.

## 反映確認

```bash
ls -l ~/.config/nushell/config.nu ~/.config/nushell/env.nu
ls -l ~/.config/git/config ~/.config/git/ignore
nu -i -c 'exit'
git config --get core.excludesfile
git config --show-origin --get-all include.path
git check-ignore -v .github/copilot-instructions.md
git config --global --list --show-origin
```

`nu` 起動時に設定読込エラーが出ないこと, `core.excludesfile` に `~/.config/git/ignore` が表示されること, `include.path` に `~/.config/git/config` と `~/.gitconfig.local` が表示されること, `~/.gitconfig` / `~/.gitconfig.local` が読み込まれていることを確認してください.
