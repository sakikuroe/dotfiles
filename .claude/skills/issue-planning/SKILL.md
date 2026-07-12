---
name: issue-planning
description: GitHub Issue の起票を担うスキル。ユーザーの要求をもとに Issue を作成する際や、単独で Issue を起票する場面で使用する。
---

## 概要

ユーザーの要求をもとに GitHub Issue を作成する。

## 参照文書

- [create_issue.md](./references/create_issue.md): ユーザーの要求をもとに Issue を作成する手順

## テンプレート

- [bug.md](./references/templates/bug.md): バグ修正 Issue の本文テンプレート
- [feature.md](./references/templates/feature.md): 機能追加・機能改善 Issue の本文テンプレート

## スクリプト

- [create_issue.sh](./scripts/create_issue.sh): `bash .claude/skills/issue-planning/scripts/create_issue.sh <タイトル> <body_file>` で Issue を作成する。
- [update_issue_body.sh](./scripts/update_issue_body.sh): `bash .claude/skills/issue-planning/scripts/update_issue_body.sh <issue番号> <body_file>` で Issue 本文を指定したファイルの内容で置き換える。完了条件や背景・動機など、description 内の節を書き換える際に使用する。