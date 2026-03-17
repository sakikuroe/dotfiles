---
name: development-flow
description: GitHub Issue 駆動の開発フロー. 開発を行う際は常にこの skill を使用する.
metadata:
  short-description: AI と人間が協働する開発フロー.
---

## 概要

GitHub Issue を要求の起点とし, AI Agent が実装, 検証, git/gh 操作を担う開発フローです.
元の clone を制御用 worktree (`main` 固定) とし, 実装は `~/.worktrees/` 配下の作業用 worktree で行います.
対象範囲は 1 Issue の着手準備から merge 完了までです.

## 前提

- default branch が `main` の GitHub リポジトリーであること.
- `main` への直接 push は行わず, 作業ブランチと PR を経由すること.
- 初回着手時は `gh auth status` とリポジトリーの保護ルール (必須承認数, status checks, merge queue の有無) を確認すること.
- 単独開発で他者承認が必須の保護ルールがある場合は, 別アカウントかルール調整が先に必要.

## 役割

- AI Agent: Issue 草案, 実装, 検証, git/gh 操作, レビュー指摘への返答.
- ユーザー: 承認と認証, GitHub Web レビュー, 最終マージ判断.

## 認証ルール

以下の操作のみ, ユーザーの認証を得てから実行します.

- `gh issue create`
- `gh pr create`, `gh pr ready`, `gh pr edit`, `gh pr merge`

上記以外 (push, コミット, Issue 進捗更新, PR コメント) は認証不要です.

## AI Agent の署名

AI Agent が GitHub 上に投稿するすべてのテキスト (PR 本文, PR コメント, review thread への返答) の末尾に, 以下の署名を付けます.

```
*This comment was posted by AI Agent (model: <モデル名>).*
```

## 手順

初回は Step 01 から順に進めます. 再開時は Step 01 で判定し, 該当 Step から再開します.

- [01_sync_main.md](./references/01_sync_main.md): 新規着手か再開かを判定し, 新規なら `main` を同期する.
- [02_create_issue.md](./references/02_create_issue.md): ユーザーの要求から Issue を作成する.
- [03_create_branch.md](./references/03_create_branch.md): 作業ブランチと worktree を作成する.
- [04_implement_and_commit.md](./references/04_implement_and_commit.md): 作業用 worktree で実装, 検証, コミットを行う.
- [05_push_and_open_pr.md](./references/05_push_and_open_pr.md): 履歴を整形し, `main` 向け PR を作成する.
- [06_wait_user_review.md](./references/06_wait_user_review.md): PR の状態から次の Step を判定する.
- [07_address_review.md](./references/07_address_review.md): レビュー指摘に 1 件ずつ対応する.
- [08_merge_and_cleanup.md](./references/08_merge_and_cleanup.md): マージ依頼と後処理を行う.

## 進捗の仕様

Issue 本文の `## 進捗` は 4 フィールドで構成します.

- `状態`: 下記の状態値.
- `ブランチ`: branch 名 (worktree path は書かない).
- `PR`: PR 番号または URL.
- `次`: 次に進む Step.

### 状態値

AI Agent が作業中の状態は「〜中」, 外部の応答を待つ状態は「〜待ち」で表します.

- `未着手` — Issue 作成直後.
- `実装中` — 実装, 検証を進めている.
- `ドラフトレビュー中` — draft PR で相談や途中レビューを受けている.
- `レビュー待ち` — ready PR で正式レビューを待っている.
- `指摘対応中` — レビュー指摘や CI 不具合に対応している.
- `再レビュー待ち` — 指摘対応を反映し, 再レビューを待っている.
- `マージ待ち` — ユーザーへ最終マージを依頼済み.
- `merge queue 待ち` — merge queue に投入済み.
- `完了` — merge と後処理を確認済み.
