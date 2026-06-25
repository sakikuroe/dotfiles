---
name: issue-planning
description: GitHub Issue の起票と実装計画の作成・提示を担うスキル. ユーザーの要求から Issue を作成するとき, 実装方針をコメントで投稿しユーザーの承認を得るときに使用する. 単独で Issue 起票や計画作成を行う場面でも使用する.
---

## 概要

ユーザーの要求をもとに GitHub Issue を作成し, 実装方針を Issue コメントとして投稿してユーザーの承認を得る.

## 規約

- **認証**: `gh issue create` はユーザーの認証を得てから実行する. それ以外 (Issue 進捗コメントの追記など) は認証不要.
- **署名**: Issue 本文・コメントなど GitHub へ投稿するテキストの末尾に `*This comment was posted by AI Agent.*` を付ける. スクリプト経由なら自動付加されるため本文ファイルに含めなくてよい. `gh` を直接使う場合はファイル末尾に含める.
- **本文の渡し方**: 長い本文はヒアドキュメント (`<<'EOF'`) で一時ファイルに書き出し, `--body-file` または `<body_file>` 引数でファイル経由で渡す. バッククォートのエスケープ事故を防ぐためである.
- **進捗の記録**: Issue の description には進捗を書かず, 状態変化のたびに `add_progress_comment.sh` でコメントを追記する. このスキルで記録する状態は `方針レビュー待ち` (実装方針コメントを投稿し, ユーザーの承認を待っている状態).

## 参照文書

- [create_issue.md](./references/create_issue.md): ユーザーの要求から Issue を作成する手順.
- [review_implementation_plan.md](./references/review_implementation_plan.md): 実装方針をコメントで投稿し, ユーザーの承認を得る手順.

## テンプレート

- [bug.md](./references/templates/bug.md): バグ修正 Issue の本文テンプレート.
- [feature.md](./references/templates/feature.md): 機能追加・機能改善 Issue の本文テンプレート.
- [implementation_plan.md](./references/templates/implementation_plan.md): 実装方針コメントのテンプレート.

## スクリプト

操作ミスが起きやすい手順はスクリプトに委譲する.

- [create_issue.sh](./scripts/create_issue.sh): タイトルと本文ファイルで Issue を作成する.
- [post_implementation_plan.sh](./scripts/post_implementation_plan.sh): 実装方針コメントを Issue に投稿する.
- [update_issue_body.sh](./scripts/update_issue_body.sh): Issue 本文をファイル内容で置き換える. 完了条件や背景・動機など, Issue description 内の節の書き換えに使う.
