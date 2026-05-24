# Nushell 設定

## プロンプトのデザイン

3 行構成のプロンプトです.

```
[2026-05-25 10:30:00+09:00] (ws:default)
saki@myhost:~/dotfiles [git main]
>>>
```

### 各要素の説明

| 要素 | 内容 |
|------|------|
| `[datetime]` | 現在日時 (タイムゾーン付き ISO 形式) |
| `(ws:名前)` | WezTerm のワークスペース名. WezTerm 外では非表示 |
| `user@host:path` | ユーザー名・ホスト名・カレントディレクトリー |
| `[git branch]` | git ブランチ名と状態. git リポジトリー外では非表示 |
| `>>>` | 入力インジケーター |

### git ブロックの状態表示

| 表示 | 意味 |
|------|------|
| `*` | ブランチ名の末尾に付く. staged / unstaged / untracked のいずれかあり |
| `↑N` | upstream より N コミット ahead |
| `↓N` | upstream より N コミット behind |
| `+N` | N ファイルが staged |
| `~N` | N ファイルが unstaged |
| `?N` | N ファイルが untracked |

### path の短縮ルール

深いディレクトリーでは中間セグメントを頭文字 (または先頭 2 文字) に短縮します.

例: `~/Nextcloud/Apps/dotfiles` → `~/N/A/dotfiles`
