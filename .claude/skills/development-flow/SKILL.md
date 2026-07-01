---
name: development-flow
description: GitHub Issue を起点とする AI 主導の開発フローを定めるスキルである。開発タスクに着手するとき、Issue を作成するとき、または Issue から PR・マージまでの手順を進めるときは必ずこのフローに従う。ユーザーが「実装して」「直して」「ブランチを作って」「PRを出して」のように Issue に明示的に言及せず開発を依頼した場合も、必ずこのフローに従う。
---

## 概要

GitHub Issue を要求の起点とし、AI Agent が実装、検証、git/gh 操作を担う開発フローである。
元の clone を制御用 worktree (default branch 固定) とし、実装は `~/.worktrees/` 配下の作業用 worktree で行う。
対象範囲は 1 Issue の着手準備から merge 完了までである。

本スキルは全体の順序を統括し、ワークスペースの準備 (default branch 同期、作業ブランチ・worktree の作成) と マージ・後処理を直接担う。途中の各段階 (Issue 起票、実装、PR 作成、レビュー対応) は対応するスキルを参照すること。

## 手順

先頭から順に進める。各スキルは単独でも利用できるが、1 Issue を着手から merge まで通す場合はこの順序に従う。

1. default branch を同期する — [references/sync_main.md](./references/sync_main.md)。
2. Issue を起票し、実装方針の承認を得る — [issue-planning](../issue-planning/SKILL.md)。
3. 作業ブランチと worktree を作成する — [references/create_branch.md](./references/create_branch.md)。
4. 作業用 worktree で実装、検証、コミットを行う — [implementation](../implementation/SKILL.md)。
5. push して default branch 向け PR を作成する — [pr-creation](../pr-creation/SKILL.md)。
6. PR の状態を判定し、レビュー指摘や CI 不具合に対応する — [review-response](../review-response/SKILL.md)。
7. マージを依頼し、後処理を行う — [references/merge_and_cleanup.md](./references/merge_and_cleanup.md)。

中断・再開する場合は、Issue のコメント履歴 (ブランチ名・PR・状態) と `git worktree list` / `gh pr view` の現在状態から、上記のどの段階にいるかを判断して該当段階から進める。

## 前提

- default branch を持つ GitHub リポジトリーであること (既定では `main`)。
- default branch への直接 push は行わず、作業ブランチと PR を経由すること。
- 初回着手時は `gh auth status` とリポジトリーの保護ルール (必須承認数、status checks、merge queue の有無) を確認すること。
- 単独開発で他者承認が必須の保護ルールがある場合は、別アカウントかルール調整が先に必要である。

## 役割

- AI Agent: Issue 草案、実装、検証、git/gh 操作、レビュー指摘への返答
- ユーザー: 承認と認証、GitHub Web レビュー、最終マージ判断

## 認証ルール

以下の操作のみ、ユーザーの認証を得てから実行すること。各段階のスキルもこれに従う。

- `gh issue create`
- `gh pr create`, `gh pr merge`
- PR を draft → ready に切り替える操作
- レビュー依頼の追加・再設定
- `git push origin --delete <branch>` (リモートブランチの削除)

上記以外 (push、コミット、Issue 進捗更新、PR コメント) は認証が不要である。

このフローで development-flow 自身が行う認証対象は、マージ (`gh pr merge`) とリモートブランチ削除である。

## 状態値

AI Agent が作業中の状態は「〜中」、外部の応答を待つ状態は「〜待ち」で表す。各状態は括弧内のスキルが記録する。

- `方針レビュー待ち` — 実装方針コメントを投稿し、ユーザーの承認を待っている (issue-planning)。
- `実装中` — 実装、検証を進めている (implementation)。
- `ドラフトレビュー中` — draft PR で相談や途中レビューを受けている (pr-creation / review-response)。
- `レビュー待ち` — ready PR で正式レビューを待っている (pr-creation / review-response)。
- `指摘対応中` — レビュー指摘や CI 不具合に対応している (review-response)。
- `再レビュー待ち` — 指摘対応を反映し、再レビューを待っている (review-response)。
- `マージ待ち` — ユーザーへ最終マージを依頼済みである (development-flow)。
- `merge queue 待ち` — merge queue に投入済みである (development-flow)。
- `完了` — merge と後処理を確認済みである (development-flow)。

## 参照文書

development-flow が直接担う段階の手順

- [references/sync_main.md](./references/sync_main.md): default branch を origin と同期し、worktree 配置規則を定める。
- [references/create_branch.md](./references/create_branch.md): 作業ブランチと worktree を作成する。
- [references/merge_and_cleanup.md](./references/merge_and_cleanup.md): マージ依頼と後処理 (remote branch / worktree / local branch の削除と default branch 同期) を行う。

## スクリプト

- [scripts/create_worktree.sh](./scripts/create_worktree.sh): `bash .claude/skills/development-flow/scripts/create_worktree.sh <branch-name>` で、作業ブランチと worktree を命名規則通りに作成・再利用する。
- [scripts/cleanup.sh](./scripts/cleanup.sh): `bash .claude/skills/development-flow/scripts/cleanup.sh <PR番号> [--yes]` で、マージ後の後処理 (remote branch 削除 → worktree 削除 → local branch 削除 → default branch 同期) を順に実行する。
- [scripts/add_progress_comment.sh](./scripts/add_progress_comment.sh): `bash .claude/skills/development-flow/scripts/add_progress_comment.sh <issue番号> <body_file>` で、Issue に進捗コメントを投稿する。状態変化のたびに呼ぶ。
