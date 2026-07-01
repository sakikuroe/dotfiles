---
name: implementation
description: 計画に沿った実装を担うスキルである。作業用 worktree で実装、検証、コミットを行うときに使用する。単独で実装・コミットを行う場面でも使用する。
---

## 概要

Issue の内容を作業用 worktree で実装し、検証してローカルコミットを積む。

## 参照文書

- [implement_and_commit.md](./references/implement_and_commit.md): 作業用 worktree で実装、検証、コミットを行う手順

## スクリプト

- [add_progress_comment.sh](./scripts/add_progress_comment.sh): `bash .claude/skills/implementation/scripts/add_progress_comment.sh <issue番号> <body_file>` で Issue に進捗コメントを投稿する。実装開始時に `状態: 実装中` を記録するために使う。

## 連携サブエージェント

- git-committer: コミットを担う。作業ディレクトリとコミットの単位・意図を伝えて委譲する。
