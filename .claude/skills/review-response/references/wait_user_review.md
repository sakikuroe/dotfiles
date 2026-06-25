# ユーザーレビューの待機

## 概要

PR の状態を確認し、修正対応が必要か、マージ可能か、まだレビュー待ちかを判定する。

## 手順

- 実行場所: メインリポジトリーでも worktree でも構わない (`gh` の API 問い合わせのみのため)。
- `bash ${CLAUDE_SKILL_DIR}/scripts/fetch_reviews.sh <PR番号>` で PR の状態 / 全体レビュー / インライン review comment を 1 回で取得する。
    - インライン review comment は `gh pr view --json reviews` には含まれないため、個別取得すると見落とす。このスクリプトは両者をまとめて JSON で返す。
    - コマンド例:
        ```bash
        bash ${CLAUDE_SKILL_DIR}/scripts/fetch_reviews.sh <PR番号> | jq 。
        ```
    - 出力フィールド:
        - `state`、`isDraft`、`reviewDecision`、`mergeable`、`mergeStateStatus`: PR の状態判定に使う
        - `checks`: CI ステータス
        - `reviews`: 全体レビュー一覧。`body` に具体的な指摘や要求があれば修正対応が必要
        - `inline_comments`: インライン comment 一覧。`in_reply_to_id` が null のものが起点コメント、値が入っているものは既存スレッドへの返信。未対応の起点コメントがあれば修正対応が必要
- 状態に応じて判定結果を記録する。
    - `MERGED` の場合 → マージ済み
    - `CHANGES_REQUESTED` がある場合、または CI 失敗、競合がある場合 → 修正対応が必要
    - draft のまま正式レビューに進めない場合 → ready 化するか修正対応で作業継続するか決める
    - `reviewDecision` が `APPROVED` の場合 → マージ可能
    - `reviewDecision` が `""` (required review なし) かつ `mergeable: MERGEABLE`、`mergeStateStatus: CLEAN`、draft でない場合 → ユーザーに「required review が設定されていないためそのままマージできます。進めますか?」と確認し、了承を得たらマージ可能
    - 上記に該当しない場合 (レビュー未完了、merge queue 待ち) → レビュー待ちを継続する
- 最新の進捗コメントと PR 状態が一致しているか確認し、不一致があれば `add_progress_comment.sh` で記録する。
    - draft PR → `ドラフトレビュー中`。
    - ready PR でレビュー待ち → `レビュー待ち`。
    - 修正反映後の再レビュー待ち → `再レビュー待ち`。
    - merge queue 投入済み → `merge queue 待ち`。
- 現在状態を要約してユーザーへ返す。
    - 何待ちか、ユーザーに依頼する行動を伝える。

## 原則

- GitHub 上の状態を変える操作 (レビュー依頼、ready 化) は、ユーザー認証後に行うこと。
- `reviewDecision` だけでなくコメント内容も確認すること。具体的な修正依頼があれば修正対応が必要である。
- 承認済みに見えても、競合や base 追従不足があればマージ不可である。
- レビュー待ちの間は不要な差し替え commit / push を避けること。必要なら address_review の手順で行う。
- 判断に迷う場合は作業を中断し、ユーザーに報告・相談すること。

## この段階の完了条件

- [ ] PR の状態判定が完了している。
- [ ] 進捗コメントが PR 状態と一致している。
