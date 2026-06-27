---
name: pr-creation
description: push と PR 作成を担うスキル. 作業ブランチを push し, default branch 向けの PR を作成するときに使用する. 単独で PR を作成する場面でも使用する.
---

## 概要

作業ブランチを origin へ push し, default branch 向けの PR を作成する. PR 本文はテンプレートに基づいて作成し, スクリプトで署名を自動付加する.

## 規約

- **前提**: default branch への直接 push は行わず, 作業ブランチと PR を経由する. PR は default branch 向けに作成する.
- **認証**: `gh pr create`, PR を draft → ready に切り替える操作, レビュー依頼の追加・再設定はユーザーの認証を得てから実行する. push は認証不要.
- **署名**: PR 本文・コメントなど GitHub へ投稿するテキストの末尾に `*This comment was posted by AI Agent.*` を付ける. スクリプト経由なら自動付加されるため本文ファイルに含めなくてよい. `gh` を直接使う場合はファイル末尾に含める.
- **本文の渡し方**: 長い本文はヒアドキュメント (`<<'EOF'`) で一時ファイルに書き出し, `--body-file` または `<body_file>` 引数でファイル経由で渡す. バッククォートのエスケープ事故を防ぐためである.
- **進捗の記録**: Issue の description には進捗を書かず, 状態変化のたびに `add_progress_comment.sh` でコメントを追記する. このスキルで記録する状態は `レビュー待ち` (ready PR) / `ドラフトレビュー中` (draft PR).

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
