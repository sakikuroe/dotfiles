# ユーザーレビューの待機

## 概要

PR の状態を確認し, Step 07 (修正対応) か Step 08 (マージ) のどちらに進むかを判定します.
どちらにも該当しない場合はレビュー待ちとして本 Step を継続します.

## 手順

- 実行場所: メインリポジトリでも worktree でもどちらでも可 (`gh` の API 問い合わせのみのため).
- `bash ${CLAUDE_SKILL_DIR}/scripts/fetch_reviews.sh <PR番号>` で PR の状態 / 全体レビュー / インライン review comment を 1 回で取得します.
    - インライン review comment は `gh pr view --json reviews` には含まれないため, 個別取得すると見落とす. このスクリプトは両者をまとめて JSON で返します.
    - コマンド例:
        ```bash
        bash ${CLAUDE_SKILL_DIR}/scripts/fetch_reviews.sh <PR番号> | jq .
        ```
    - 出力フィールド:
        - `state`, `isDraft`, `reviewDecision`, `mergeable`, `mergeStateStatus`: PR の状態判定に使う
        - `checks`: CI ステータス
        - `reviews`: 全体レビュー一覧. `body` に具体的な指摘や要求があれば Step 07 へ
        - `inline_comments`: インライン comment 一覧. `in_reply_to_id` が null のものが起点コメント, 値が入っているものは既存スレッドへの返信. 未対応の起点コメントがあれば Step 07 へ
- 状態に応じて次の Step を決めます.
    - `MERGED` の場合 → Step 08.
    - `CHANGES_REQUESTED` がある場合, または CI 失敗, 競合がある場合 → Step 07.
    - draft のまま正式レビューに進めない場合 → ready 化するか Step 07 で作業継続するか決めます.
    - `reviewDecision` が `APPROVED` の場合 → Step 08.
    - `reviewDecision` が `""` (required review なし) かつ `mergeable: MERGEABLE`, `mergeStateStatus: CLEAN`, draft でない場合 → ユーザーに「required review が設定されていないためそのままマージできます. 進めますか？」と確認し, 了承を得たら Step 08.
    - 上記に該当しない場合 (レビュー未完了, merge queue 待ち) → 本 Step を継続します.
- Issue の `進捗` が PR 状態と一致しているか確認し, 不一致があれば更新します.
    - draft PR → `ドラフトレビュー中`.
    - ready PR でレビュー待ち → `レビュー待ち`.
    - 修正反映後の再レビュー待ち → `再レビュー待ち`.
    - merge queue 投入済み → `merge queue 待ち`.
- 現在状態を要約してユーザーへ返します.
    - 何待ちか, 次の Step 候補, ユーザーに依頼する行動を伝えます.

## 原則

- GitHub 上の状態を変える操作 (レビュー依頼, ready 化) は, ユーザー認証後に行います.
- `reviewDecision` だけでなくコメント内容も確認します. 具体的な修正依頼があれば Step 07 へ進みます.
- 承認済みに見えても, 競合や base 追従不足があれば Step 08 へは進めません.
- レビュー待ちの間は不要な差し替え commit / push を避けます. 必要なら Step 07 の手順で行います.
- 判断に迷う場合は作業を中断し, ユーザーに報告, 相談します.

## この phase の完了条件

- [ ] 次の Step (07 / 08) が確定している, またはレビュー待ちの理由が明確である.
- [ ] Issue の `進捗` が PR 状態と一致している.
