# agents

このディレクトリは, Claude Code および Codex 向けのスキル設定を管理します.
各スキルは `skills/<skill-name>/` に配置され, `SKILL.md` を起点として Claude Code に読み込まれます.

## スキル一覧

| スキル | 説明 |
|---|---|
| `coding-rules` | C++ と Rust のコーディングルール |
| `development-flow` | GitHub Issue を起点とする AI 主導の開発フロー |
| `git-commit` | Git コミットメッセージの記述ルール |
| `writing-rules` | 日本語の文体・記述ルールと Markdown の書き方 |

## 各プロジェクトへの導入

スキルは symlink で `~/.claude/skills/`（グローバル）または `.claude/skills/`（プロジェクトローカル）に反映します.

### グローバルインストール（推奨）

すべてのプロジェクトでスキルが有効になります.

```bash
./agents/install.sh
```

### プロジェクトローカルインストール

特定のプロジェクトにのみ有効にしたい場合は, そのプロジェクトのルートで実行します.

```bash
cd /path/to/your-project
/path/to/dotfiles/agents/install.sh --project
```

このモードでは, `.claude/CLAUDE.md` が存在しない場合に限り, `agents/CLAUDE.md`（`.claude/skills/` 配下のスキルを積極的に確認し使用するよう指示する短いファイル）も symlink します. 既存の `.claude/CLAUDE.md` がある場合は何もしません.

### 安全性

`install.sh` はインストール先に同名のディレクトリ・ファイル・symlink が存在する場合, 上書きせずにスキップします.
`.claude/CLAUDE.md` への symlink（プロジェクトローカルインストール時のみ）を除き, 既存の `.claude/` 配下の設定（`settings.json` など）には一切触れません.

スクリプトは冪等であり, 複数回実行しても安全です.
