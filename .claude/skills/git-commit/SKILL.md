---
name: git-commit
description: Git コミットの作法 (メッセージの書式と、1 コミット 1 関心事などの運用原則) を定めたスキル。コミットメッセージを作成、修正、レビューするとき、またはユーザーが単に「コミットして」と依頼したときも、git commit を実行する前に必ず参照する。git-committer サブエージェントもこのスキルの作法に従う。
---

- [git_commit.md](./references/git_commit.md): コミットメッセージの書式と、1 コミット 1 関心事などの運用原則。

## スクリプト

- [commit_with_signature.sh](./scripts/commit_with_signature.sh): コミットメッセージ末尾に `Co-authored-by: AI Agent` trailer を追加して `git commit` する。
