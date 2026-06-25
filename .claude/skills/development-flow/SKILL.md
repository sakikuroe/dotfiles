---
name: development-flow
description: GitHub Issue を起点とする AI 主導の開発フロー. 開発タスクに着手するとき, Issue を作成するとき, または Issue から PR・マージまでの手順を進めるときは必ずこのフローに従う. ユーザーが「実装して」「直して」「ブランチを作って」「PRを出して」のように Issue に明示的に言及せず開発を依頼した場合も, 必ずこのフローに従う.
---

## 概要

GitHub Issue を要求の起点とし, AI Agent が実装, 検証, git/gh 操作を担う開発フロー.
元の clone を制御用 worktree (`main` 固定) とし, 実装は `~/.worktrees/` 配下の作業用 worktree で行う.
対象範囲は 1 Issue の着手準備から merge 完了まで.

本スキルは全体の順序を統括し, ワークスペースの準備 (`main` 同期, 作業ブランチ・worktree の作成) と マージ・後処理を直接担う. 途中の各段階 (Issue 起票, 実装, PR 作成, レビュー対応) は対応するスキルを参照すること.

## 手順

先頭から順に進める. 各スキルは単独でも利用できるが, 1 Issue を着手から merge まで通す場合はこの順序に従う.

1. `main` を同期する — [references/sync_main.md](./references/sync_main.md).
2. Issue を起票し, 実装方針の承認を得る — [issue-planning](../issue-planning/SKILL.md).
3. 作業ブランチと worktree を作成する — [references/create_branch.md](./references/create_branch.md).
4. 作業用 worktree で実装, 検証, コミットを行う — [implementation](../implementation/SKILL.md).
5. push して `main` 向け PR を作成する — [pr-creation](../pr-creation/SKILL.md).
6. PR の状態を判定し, レビュー指摘や CI 不具合に対応する — [review-response](../review-response/SKILL.md).
7. マージを依頼し, 後処理を行う — [references/merge_and_cleanup.md](./references/merge_and_cleanup.md).

中断・再開する場合は, Issue のコメント履歴 (ブランチ名・PR・状態) と `git worktree list` / `gh pr view` の現在状態から, 上記のどの段階にいるかを判断して該当段階から進める.

## 参照文書

- [references/sync_main.md](./references/sync_main.md): `main` を `origin/main` に同期し, worktree 配置規則を定める.
- [references/create_branch.md](./references/create_branch.md): 作業ブランチと worktree を作成する.
- [references/merge_and_cleanup.md](./references/merge_and_cleanup.md): マージ依頼と後処理を行う.

## スクリプト

操作ミスが起きやすい手順はスクリプトに委譲する. `${CLAUDE_SKILL_DIR}` はこのファイルのディレクトリーに展開される.

- [scripts/create_worktree.sh](./scripts/create_worktree.sh): 作業ブランチと worktree を命名規則通りに作成・再利用する.
- [scripts/cleanup.sh](./scripts/cleanup.sh): マージ後の後処理 (remote branch 削除 → worktree 削除 → local branch 削除 → main 同期) を順に実行する.
- [scripts/add_progress_comment.sh](./scripts/add_progress_comment.sh): Issue に進捗コメントを追加投稿する.
