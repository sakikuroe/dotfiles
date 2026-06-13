# .claude

このディレクトリーは, Claude Code および Codex 向けのスキル設定を管理しています.
各スキルは `skills/<skill-name>/` に配置されており, `SKILL.md` を起点として Claude Code に読み込まれます.

## スキル一覧

- `coding-rules`: C++ と Rust のコーディングルール.
- `development-flow`: GitHub Issue を起点とする AI 主導の開発フロー.
- `git-commit`: Git コミットメッセージの記述ルール.
- `writing-rules`: 日本語の文体・記述ルールと Markdown の書き方.

## 各プロジェクトへの導入

`install.sh` を実行すると, このリポジトリ内の任意のディレクトリー・ファイルを, 導入先プロジェクトの同じパスへ取得できます. たとえば `.claude/skills/coding-rules` を選択すると, 導入先プロジェクトの `.claude/skills/coding-rules/` にその内容が配置されます.

導入先プロジェクトのルートで, 次のコマンドを実行してください.

```bash
curl -fsSL https://raw.githubusercontent.com/sakikuroe/dotfiles/main/.claude/install.sh \
  | bash -s -- https://github.com/sakikuroe/dotfiles.git
```

`fzf` が利用可能な場合は, 取得するディレクトリー・ファイルを一覧から選択できます. `fzf` が無い場合は, GitHub 上で対象のディレクトリー・ファイルを開いたときの URL を貼り付けて指定します.

### 安全性

`install.sh` は, 取得先のパスに既に同名のディレクトリーやファイルが存在する場合, 何もせずに終了します. 取得したディレクトリー・ファイルは `.git/info/exclude` に追記され, git の管理対象外として扱われます.
