---
name: git-commit
description: Git コミットの作法 (メッセージの書式と、1 コミット 1 関心事などの運用原則) を定めたスキル。コミットメッセージを作成、修正、レビューするとき、またはユーザーがコミットを依頼したときも、git commit を実行する前に必ず参照する。
---

## 概要

Git コミットの作法 (コミットメッセージの書式と、1 コミット 1 関心事などの運用原則) を定める。コミットを作成・修正・レビューするときに参照する。

## 参照文書

- [git_commit.md](./references/git_commit.md): コミットメッセージの書式と、1 コミット 1 関心事などの運用原則。

## スクリプト

- [commit_with_signature.sh](./scripts/commit_with_signature.sh): `git commit` の代わりにコミット時に使う。`bash .claude/skills/git-commit/scripts/commit_with_signature.sh "<メッセージ>"` のようにメッセージを引数で渡すと、末尾に `Co-authored-by: AI Agent` trailer を付けてコミットする。直前のコミットを修正するときは `--amend` を渡す。
