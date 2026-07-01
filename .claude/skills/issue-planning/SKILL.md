---
name: issue-planning
description: GitHub Issue の起票と実装計画の作成・提示を担うスキルである。ユーザーの要求から Issue を作成するとき、実装方針をコメントで投稿しユーザーの承認を得るときに使用する。単独で Issue 起票や計画作成を行う場面でも使用する。
---

## 概要

ユーザーの要求をもとに GitHub Issue を作成し、実装方針を Issue コメントとして投稿してユーザーの承認を得る。

## 参照文書

- [create_issue.md](./references/create_issue.md): ユーザーの要求から Issue を作成する手順
- [review_implementation_plan.md](./references/review_implementation_plan.md): 実装方針をコメントで投稿し、ユーザーの承認を得る手順

## テンプレート

- [bug.md](./references/templates/bug.md): バグ修正 Issue の本文テンプレート
- [feature.md](./references/templates/feature.md): 機能追加・機能改善 Issue の本文テンプレート
- [implementation_plan.md](./references/templates/implementation_plan.md): 実装方針コメントのテンプレート

## スクリプト

- [create_issue.sh](./scripts/create_issue.sh): `bash .claude/skills/issue-planning/scripts/create_issue.sh <タイトル> <body_file>` で Issue を作成する。
- [post_implementation_plan.sh](./scripts/post_implementation_plan.sh): `bash .claude/skills/issue-planning/scripts/post_implementation_plan.sh <issue番号> <body_file>` で実装方針コメントを Issue に投稿する。
- [update_issue_body.sh](./scripts/update_issue_body.sh): `bash .claude/skills/issue-planning/scripts/update_issue_body.sh <issue番号> <body_file>` で Issue 本文をファイル内容に置き換える。完了条件や背景・動機など description 内の節の書き換えに使う。
