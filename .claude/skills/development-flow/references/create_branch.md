# 作業ブランチと worktree の作成

## 概要

起票された Issue に対して、紐づく短命の作業ブランチと開発用の worktree を用意する。既存の作業を再開する場合は、ブランチや worktree が乱立してどれが正しい状態か分からなくなるのを防ぐため、新しく作成せずに既存のものを再利用する。

## 手順

まず、ブランチ名を `<kind>/<issue番号>-<short-description>` の形式で決める。`kind` には変更の性質に応じて `feature` / `fix` / `hotfix` / `chore` / `docs` / `refactor` のいずれかを選ぶ。たとえば、検索フィルターを追加する Issue #123 であれば、`feature/123-add-search-filters` のようになる。

ブランチ名が決まったら、メインリポジトリー (制御用 worktree) で次のスクリプトを実行する。このスクリプトは、リモートの最新化、local / remote ブランチの有無の確認、worktree の作成までを一括して行い、対応するブランチや worktree がすでに存在する場合はそれを再利用する。ブランチが存在しない場合は、origin の default branch を起点として新しいブランチと worktree を同時に作成する。そのため、制御用 worktree 上で直接 `git checkout -b` を実行してはならない。これを実行すると、default branch に固定しておくべき制御用 worktree 自体が、作業ブランチへと切り替わってしまうからである。

```bash
# 実行場所: メインリポジトリー
bash .claude/skills/development-flow/scripts/create_worktree.sh feature/123-add-search-filters
```

worktree の配置先は [sync_main.md](./sync_main.md) の規則に従う。なお、このスクリプトは `git worktree list` の先頭行からメインリポジトリーを特定するため、worktree 内から実行しても正常に動作する。

worktree が用意できたら、ブランチ名を Issue の進捗コメントとして記録する。これは、作業の中断や再開時に、コメント履歴から作業ブランチを特定できるようにするためである。コメント本文をファイルに書き出し、`bash .claude/skills/development-flow/scripts/add_progress_comment.sh <issue番号> <body_file>` を実行して投稿する。

ブランチの衝突や worktree の不整合など、判断に迷うような事象が発生した場合は、作業を中断してユーザーに報告・相談する。

## この段階の完了条件

- [ ] Issue 番号付きの作業ブランチが新規作成、または再利用されている。
- [ ] 作業用の worktree が新規作成、または再利用されている。
- [ ] 進捗コメントにブランチ名が記録されている。
- [ ] implementation スキルを開始できる状態になっている。