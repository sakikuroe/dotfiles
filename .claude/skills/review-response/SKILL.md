---
name: review-response
description: レビュー対応を担うスキルである。PR の状態を確認し、レビュー指摘や CI 不具合に対応するときに使用する。単独で PR のレビュー対応を行う場面でも使用する。
---

## 概要

PR の状態から次に行うことを判定し、レビュー指摘、PR コメント、CI 不具合に対して 1 件ずつ対応する。

## 参照文書

- [wait_user_review.md](./references/wait_user_review.md): PR の状態から修正対応が必要か、マージ可能か、まだレビュー待ちかを判定する手順
- [address_review.md](./references/address_review.md): レビュー指摘に 1 件ずつ対応する手順

## スクリプト

- [fetch_reviews.sh](./scripts/fetch_reviews.sh): `bash .claude/skills/review-response/scripts/fetch_reviews.sh <PR番号>` で、PR 状態 / 全体レビュー / インライン review comment を 1 回で取得し JSON で返す。
- [reply_review.sh](./scripts/reply_review.sh): `bash .claude/skills/review-response/scripts/reply_review.sh <PR番号> <review_node_id> <body_file>` で、レビュー全体へ引用付きで返答する。
- [reply_inline.sh](./scripts/reply_inline.sh): `bash .claude/skills/review-response/scripts/reply_inline.sh <PR番号> <comment_id> <body_file> <commit_hash|->` で、インライン review comment に返答する。
- [set_ready.sh](./scripts/set_ready.sh): `bash .claude/skills/review-response/scripts/set_ready.sh <PR番号>` で draft PR を ready for review に切り替える。
- [add_progress_comment.sh](./scripts/add_progress_comment.sh): `bash .claude/skills/review-response/scripts/add_progress_comment.sh <issue番号> <body_file>` で Issue に進捗コメントを投稿する。状態変化のたびに使う。

## 連携サブエージェント

- git-committer: コミットを担う。作業ディレクトリとコミットの単位・意図を伝えて委譲する。