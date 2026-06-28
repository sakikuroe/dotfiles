# .claude

このディレクトリーは、Claude Code および OpenCode 向けのスキル設定を管理しています。
各スキルは `skills/<skill-name>/` に配置されており、`SKILL.md` を起点として読み込まれます。

## スキル一覧

- `coding-rules`: C++ と Rust のコーディングルール。
- `development-flow`: GitHub Issue を起点とする AI 主導の開発フロー。全体の順序を統括し、ワークスペース準備 (main 同期、ブランチ・worktree 作成) とマージ・後処理を直接担う。
- `issue-planning`: Issue の起票と実装計画の作成・提示。
- `implementation`: 計画に沿った実装。コミットは git-committer サブエージェントに委託する。
- `pr-creation`: push と PR 作成。
- `review-response`: レビュー対応。
- `git-commit`: コミットの作法 (メッセージ書式と運用原則)。git-committer サブエージェントが参照する。
- `writing-rules`: 日本語の文体・記述ルールと Markdown の書き方。
- `documentation`: 機能コード以外の開発情報の置き場を定める。Issue・PR・ADR・docs・CHANGELOG に何を書き、どこには書かないかの置き場マップと、ADR・Diátaxis・CHANGELOG の運用。

## サブエージェント

`.claude/agents/` 配下に Claude Code 用のサブエージェントを配置しています。OpenCode 用は `.opencode/agents/` に配置しています (frontmatter が非互換のため分離)。

## 各プロジェクトへの導入

`install.sh` を実行すると、このリポジトリ内の任意のディレクトリー・ファイルを、導入先プロジェクトの同じパスへ取得できます。たとえば `.claude/skills/coding-rules` を選択すると、導入先プロジェクトの `.claude/skills/coding-rules/` にその内容が配置されます。

導入先プロジェクトのルートで、次のコマンドを実行してください。

```bash
curl -fsSL https://raw.githubusercontent.com/sakikuroe/dotfiles/main/.claude/install.sh \
  | bash -s -- https://github.com/sakikuroe/dotfiles.git
```

`fzf` が利用可能な場合は、取得するディレクトリー・ファイルを一覧から選択できます。`fzf` が無い場合は、GitHub 上で対象のディレクトリー・ファイルを開いたときの URL を貼り付けて指定します。

### `CLAUDE.md` (ルート)

リポジトリルートの `CLAUDE.md` は、スキルとサブエージェントの使用を促す短い指示文だけを記載しています。開発フローの共通事項 (認証、署名、本文の扱い、進捗の記録、状態値) は各スキル内に持たせてあるため、スキルのディレクトリーを単体で取得しても完結します。`CLAUDE.md` 自体は、スキルの使用そのものを促すため、導入先プロジェクトに無い場合は併せて取得することを推奨します。

### 安全性

`install.sh` は、取得先のパスに既に同名のディレクトリーやファイルが存在する場合、何もせずに終了します。取得したディレクトリー・ファイルは `.git/info/exclude` に追記され、git の管理対象外として扱われます。
