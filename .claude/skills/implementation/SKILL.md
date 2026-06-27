---
name: implementation
description: 計画に沿った実装を担うスキル. 作業用 worktree で実装, 検証, コミットを行うときに使用する. 単独で実装・コミットを行う場面でも使用する. コミットは git-committer サブエージェントに委託する.
---

## 概要

Issue の内容を作業用 worktree で実装し, 検証してローカルコミットを積む. コミットは `git-committer` サブエージェントに委託する.

## 参照文書

- [implement_and_commit.md](./references/implement_and_commit.md): 作業用 worktree で実装, 検証, コミットを行う手順.

## スクリプト

- [add_progress_comment.sh](./scripts/add_progress_comment.sh): Issue に進捗コメントを追加投稿する. 実装開始時に `状態: 実装中` を記録するために使う.

## 連携

- コミットは `git-committer` サブエージェントに委託する. 作業用 worktree のパスと「作業中の変更を 1 関心事ごとに分割してコミットする」意図を渡し, 作成されたコミットのハッシュとメッセージを受け取る.
- `git-committer` はコミットの作法を [git-commit](../git-commit/SKILL.md) スキルから参照する. このスキルを単体で利用する場合は, git-committer サブエージェントと git-commit スキルも併せて取得すること.
