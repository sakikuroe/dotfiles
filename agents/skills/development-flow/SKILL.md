---
name: development-flow
description: GitHub Issue を起点とする AI 主導の開発フロー. 開発タスクに着手するとき, Issue を作成するとき, または Issue から PR・マージまでの手順を進めるときは必ずこのフローに従う.
---

## 概要

GitHub Issue を要求の起点とし, AI Agent が実装, 検証, git/gh 操作を担う開発フローです.
元の clone を制御用 worktree (`main` 固定) とし, 実装は `~/.worktrees/` 配下の作業用 worktree で行います.
対象範囲は 1 Issue の着手準備から merge 完了までです.

## 前提

- default branch が `main` の GitHub リポジトリーであること.
- `main` への直接 push は行わず, 作業ブランチと PR を経由すること.
- 初回着手時は `gh auth status` とリポジトリーの保護ルール (必須承認数, status checks, merge queue の有無) を確認すること.
- 単独開発で他者承認が必須の保護ルールがある場合は, 別アカウントかルール調整が先に必要.

## 役割

- AI Agent: Issue 草案, 実装, 検証, git/gh 操作, レビュー指摘への返答.
- ユーザー: 承認と認証, GitHub Web レビュー, 最終マージ判断.

## 認証ルール

以下の操作のみ, ユーザーの認証を得てから実行します.

- `gh issue create`
- `gh pr create`, `gh pr merge`
- PR を draft → ready に切り替える操作
- レビュー依頼の追加・再設定
- `git push origin --delete <branch>` (リモートブランチの削除)

上記以外 (push, コミット, Issue 進捗更新, PR コメント) は認証不要です.

## AI Agent の署名

AI Agent が GitHub 上に投稿するすべてのテキスト (PR 本文, PR コメント, review thread への返答) の末尾に, 以下の署名を付けます.

```
*This comment was posted by AI Agent.*
```

## スクリプト

操作ミスが起きやすい手順はスクリプトに委譲します. `${CLAUDE_SKILL_DIR}` はこのファイルのディレクトリーに展開されます.

- [scripts/create_worktree.sh](./scripts/create_worktree.sh): branch と worktree を命名規則通りに作成・再利用する (Step 03).
- [scripts/create_issue.sh](./scripts/create_issue.sh): タイトルと本文ファイルで Issue を作成する (Step 02).
- [scripts/update_issue_body.sh](./scripts/update_issue_body.sh): Issue 本文をファイル内容で置き換える. 進捗更新で頻出 (Step 02, 04, 07, 08).
- [scripts/add_reviewer.sh](./scripts/add_reviewer.sh): レビュー依頼を追加する (Step 05, 07).
- [scripts/fetch_reviews.sh](./scripts/fetch_reviews.sh): PR 状態 / 全体レビュー / インライン review comment を 1 回で取得し JSON で返す (Step 06, 07).
- [scripts/reply_review.sh](./scripts/reply_review.sh): レビュー全体へ引用付きで返答する (Step 07).
- [scripts/reply_inline.sh](./scripts/reply_inline.sh): インライン review comment に返答する. `--with-commit` で直近の commit URL を本文の署名直前に挿入 (Step 07).
- [scripts/set_ready.sh](./scripts/set_ready.sh): draft PR を ready に切り替える (Step 07).
- [scripts/cleanup.sh](./scripts/cleanup.sh): マージ後の後処理を正しい順序で実行する (Step 08).

## 本文を扱うコマンドの原則

`gh issue create`, `gh pr create`, `gh pr comment`, 各スクリプトなど, 長い本文を渡すコマンドはすべて
ファイル経由 (`--body-file <file>` または `<body_file>` 引数) で渡します.
シェルのヒアドキュメント内でバッククォートをエスケープする事故を防ぐためです.

本文は次の手順で渡します.

1. ヒアドキュメントで一時ファイルに本文を書き出す.
   ```bash
   cat <<'EOF' > /tmp/body.md
   ...本文...
   EOF
   ```
   `<<'EOF'` (シングルクォート) で書くと, バッククォートやドル記号がそのまま書き込まれるため
   コードブロック (` ``` `) も安全に含められます.
2. ファイルを `--body-file` または `<body_file>` 引数として渡す.

## 手順

初回は Step 01 から順に進めます. 再開時は Step 01 で判定し, 該当 Step から再開します.

- [01_sync_main.md](./references/01_sync_main.md): 新規着手か再開かを判定し, 新規なら `main` を同期する.
- [02_create_issue.md](./references/02_create_issue.md): ユーザーの要求から Issue を作成する.
- [03_create_branch.md](./references/03_create_branch.md): 作業ブランチと worktree を作成する.
- [04_implement_and_commit.md](./references/04_implement_and_commit.md): 作業用 worktree で実装, 検証, コミットを行う.
- [05_push_and_open_pr.md](./references/05_push_and_open_pr.md): 履歴を整形し, `main` 向け PR を作成する.
- [06_wait_user_review.md](./references/06_wait_user_review.md): PR の状態から次の Step を判定する.
- [07_address_review.md](./references/07_address_review.md): レビュー指摘に 1 件ずつ対応する.
- [08_merge_and_cleanup.md](./references/08_merge_and_cleanup.md): マージ依頼と後処理を行う.

## 進捗の仕様

Issue 本文の `## 進捗` は 4 フィールドで構成します.

- `状態`: 下記の状態値.
- `ブランチ`: branch 名 (worktree path は書かない).
- `PR`: PR 番号または URL.
- `次`: 次に進む Step.

### 状態値

AI Agent が作業中の状態は「〜中」, 外部の応答を待つ状態は「〜待ち」で表します.

- `未着手` — Issue 作成直後.
- `実装中` — 実装, 検証を進めている.
- `ドラフトレビュー中` — draft PR で相談や途中レビューを受けている.
- `レビュー待ち` — ready PR で正式レビューを待っている.
- `指摘対応中` — レビュー指摘や CI 不具合に対応している.
- `再レビュー待ち` — 指摘対応を反映し, 再レビューを待っている.
- `マージ待ち` — ユーザーへ最終マージを依頼済み.
- `merge queue 待ち` — merge queue に投入済み.
- `完了` — merge と後処理を確認済み.
