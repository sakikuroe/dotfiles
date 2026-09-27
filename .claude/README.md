# .claude

このディレクトリーでは、Claude Code および OpenCode 向けのスキル設定を管理している。
各スキルは `skills/<skill-name>/` に配置されており、それぞれ `SKILL.md` を起点として読み込まれる。

## スキル一覧

- `coding-rules`: C++ と Rust のコーディングルール
- `development-flow`: GitHub Issue を起点とする AI 主導の開発フロー。全体の進行を統括し、ワークスペースの準備 (main の同期、ブランチや worktree の作成) とマージ・後処理を直接担う。
- `issue-planning`: Issue の起票
- `implementation`: 計画に沿った実装作業。コミット作業は git-committer サブエージェントに委託する。
- `pr-creation`: push と PR の作成
- `review-response`: レビュー対応
- `git-commit`: コミットの作法 (メッセージの書式と運用原則)。git-committer サブエージェントが参照する。
- `writing-rules`: 日本語の文体・記述ルールと Markdown の書き方
- `documentation`: 機能コード以外の開発情報に関する配置ルール。Issue・PR・ADR・docs・CHANGELOG にそれぞれ何を書くべきか、または書くべきではないかを示すマップに加え、ADR・Diátaxis・CHANGELOG の運用方法を定義している。

## サブエージェント

`.claude/agents/` 配下に Claude Code 用のサブエージェントを配置している。OpenCode 用のサブエージェントは `.opencode/agents/` に配置している (frontmatter に互換性がないため分離している)。

## 各プロジェクトへの導入

`install.sh` を実行すると、このリポジトリ内にある任意のディレクトリーやファイルを、導入先プロジェクトの同一パスに取得できる。たとえば `.claude/skills/coding-rules` を選択した場合、導入先プロジェクトの `.claude/skills/coding-rules/` にその内容が配置される。

導入先のプロジェクトルートで、以下のコマンドを実行する。

```bash
curl -fsSL https://raw.githubusercontent.com/sakikuroe/dotfiles/main/.claude/install.sh \
  | bash -s -- https://github.com/sakikuroe/dotfiles.git
```

`fzf` が利用可能な環境であれば、取得したいディレクトリーやファイルを一覧から選択できる。利用できない場合は、GitHub 上で対象のディレクトリーやファイルを開いた際の URL を貼り付けて直接指定する。

### `CLAUDE.md` (ルート)

リポジトリルートの `CLAUDE.md` には、スキルとサブエージェントの活用を促す短い指示文のみを記載している。開発フローにおける共通事項 (認証、署名、本文の扱い、進捗の記録、状態値など) は各スキル内に含めているため、任意のスキルディレクトリーを単体で取得しても完結して機能する。ただし、`CLAUDE.md` 自体がスキルの利用を促す役割を持つため、導入先のプロジェクトに存在しない場合は併せて取得することを推奨する。

### 安全性

`install.sh` は、取得先のパスに同名のディレクトリーやファイルがすでに存在する場合、上書きせずにそのまま処理を終了する。また、取得したディレクトリーやファイルは `.git/info/exclude` に追記され、自動的に Git の管理対象外となる。