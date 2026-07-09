# 作業ブランチと worktree の作成

## 概要

起票した Issue に対して、Issue に紐付く短寿命の作業ブランチと、開発用の worktree を用意する。既存作業を再開する場合は、新しく作らずに既存のブランチと worktree を再利用する。同じ Issue に対してブランチや worktree が乱立すると、どれが正かを判断できなくなるためである。

## 手順

まず、ブランチ名を `<kind>/<issue番号>-<short-description>` の形式で決める。`kind` には変更の性質に応じて `feature` / `fix` / `hotfix` / `chore` / `docs` / `refactor` のいずれかを選ぶ。たとえば検索フィルターを追加する Issue #123 であれば、`feature/123-add-search-filters` のようになる。

ブランチ名が決まったら、メインリポジトリー (制御用 worktree) で次のスクリプトを実行する。このスクリプトは、リモートの最新化、local / remote ブランチの有無の確認、worktree の作成までを一括して行い、対応するブランチや worktree がすでに存在する場合はそれを再利用する。ブランチが存在しない場合は origin の default branch を起点に worktree と同時に新規作成するため、制御用 worktree 上で `git checkout -b` を実行してはならない。実行すると、default branch に固定しておくべき制御用 worktree が作業ブランチへ移ってしまう。

```bash
# 実行場所: メインリポジトリー
bash .claude/skills/development-flow/scripts/create_worktree.sh feature/123-add-search-filters
```

worktree の配置先は [sync_main.md](./sync_main.md) の規則に従う。なお、スクリプトは worktree 内から実行しても動作する (`git worktree list` の先頭行からメインリポジトリーを特定するため)。

worktree が用意できたら、ブランチ名を Issue の進捗コメントとして記録する。コメント本文をファイルに書き出し、`bash .claude/skills/development-flow/scripts/add_progress_comment.sh <issue番号> <body_file>` で投稿する。中断・再開のときに、コメント履歴だけから作業ブランチを特定できるようにするためである。

ブランチの衝突や worktree の不整合など、判断に迷う状態に遭遇した場合は、作業を中断してユーザーに報告・相談する。

## この段階の完了条件

- [ ] Issue 番号付きの作業ブランチが作成または再開されている。
- [ ] 作業用 worktree が作成または再開されている。
- [ ] 進捗コメントでブランチ名が記録されている。
- [ ] implementation スキルを開始できる状態になっている。
