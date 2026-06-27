---
name: pr-creation
description: push と PR 作成を担うスキル. 作業ブランチを push し, default branch 向けの PR を作成するときに使用する. 単独で PR を作成する場面でも使用する.
---

## 概要

作業ブランチを origin へ push し, default branch 向けの PR を作成する. PR 本文はテンプレートに基づいて作成し, スクリプトで署名を自動付加する.

## 参照文書

- [push_and_open_pr.md](./references/push_and_open_pr.md): 履歴を整形し, default branch 向け PR を作成する手順.

## テンプレート

- [pr.md](./references/templates/pr.md): PR 本文のテンプレート.

## スクリプト

操作ミスが起きやすい手順はスクリプトに委譲する.

- [create_pr.sh](./scripts/create_pr.sh): 本文末尾に署名を自動付加して PR を作成する.
- [add_reviewer.sh](./scripts/add_reviewer.sh): レビュー依頼を追加する.
- [set_ready.sh](./scripts/set_ready.sh): draft PR を ready に切り替える.
- [add_progress_comment.sh](./scripts/add_progress_comment.sh): Issue に進捗コメントを追加投稿する. PR 作成時に PR URL と状態を記録するために使う.
