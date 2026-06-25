---
name: review-response
description: レビュー対応を担うスキル. PR の状態を確認し, レビュー指摘や CI 不具合に対応するときに使用する. 単独で PR のレビュー対応を行う場面でも使用する.
---

## 概要

PR の状態から次に行うことを判定し, レビュー指摘, PR コメント, CI 不具合に対して 1 件ずつ対応する.

## 規約

- **認証**: PR を draft → ready に切り替える操作, レビュー依頼の追加・再設定はユーザーの認証を得てから実行する. コミット, push, PR コメント・返答の投稿は認証不要.
- **署名**: review thread や PR コメントへの返答の末尾に `*This comment was posted by AI Agent.*` を付ける. スクリプト (`reply_review.sh`, `reply_inline.sh`) が自動付加するため本文ファイルに含めなくてよい. `gh` を直接使う場合はファイル末尾に含める.
- **本文の渡し方**: 返答本文はヒアドキュメント (`<<'EOF'`) で一時ファイルに書き出し, `<body_file>` 引数でファイル経由で渡す.
- **コミット**: 修正コミットは `git-committer` サブエージェントに委託する. 1 指摘につき 1 コミットの単位で委託し, 返ったハッシュをインライン返答で使う. push はこのスキルが行う.
- **進捗の記録**: Issue の description には進捗を書かず, 状態変化のたびに `add_progress_comment.sh` でコメントを追記する. このスキルで記録する状態は `指摘対応中` / `再レビュー待ち` / `ドラフトレビュー中` / `レビュー待ち`.

## 参照文書

- [wait_user_review.md](./references/wait_user_review.md): PR の状態から修正対応が必要か, マージ可能か, まだレビュー待ちかを判定する手順.
- [address_review.md](./references/address_review.md): レビュー指摘に 1 件ずつ対応する手順.

## スクリプト

操作ミスが起きやすい手順はスクリプトに委譲する. `${CLAUDE_SKILL_DIR}` はこのファイルのディレクトリーに展開される.

- [fetch_reviews.sh](./scripts/fetch_reviews.sh): PR 状態 / 全体レビュー / インライン review comment を 1 回で取得し JSON で返す.
- [reply_review.sh](./scripts/reply_review.sh): レビュー全体へ引用付きで返答する.
- [reply_inline.sh](./scripts/reply_inline.sh): インライン review comment に返答する. 本文末尾に署名を自動付加する. コミットハッシュを指定するとそのコミットの URL を署名直前に挿入する. ハッシュの代わりに `-` を渡すとコミット URL の挿入をスキップする. ハッシュ指定時は該当指摘に対応したコミットを明示的に指定すること.
- [set_ready.sh](./scripts/set_ready.sh): draft PR を ready for review に切り替える.
- [add_progress_comment.sh](./scripts/add_progress_comment.sh): Issue に進捗コメントを追加投稿する. 状態変化のたびに使う.

## 連携

- コミットは `git-committer` サブエージェントに委託する. 1 指摘につき 1 コミットの単位で委託し, 返ったハッシュを返答に使う. push はこのスキルが行う.
- `git-committer` はコミットの作法を [git-commit](../git-commit/SKILL.md) スキルから参照する. このスキルを単体で利用する場合は, git-committer サブエージェントと git-commit スキルも併せて取得すること.