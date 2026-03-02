# dotfiles

## 目的

このリポジトリーは, Nushell 設定を symlink で管理します.
現在の対象は `config.nu` と `env.nu` です.

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
- 既存ファイルがある場合は `*.bak.<timestamp>` へ退避します.
- 同一リンク済みの場合は変更せずスキップします.

## 反映確認

```bash
ls -l ~/.config/nushell/config.nu ~/.config/nushell/env.nu
nu -c 'version'
```

`nu` 起動時に設定読込エラーが出ないことを確認してください.
