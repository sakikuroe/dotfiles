# レビュー指摘への対応

## 概要

レビュー指摘、PR コメント、CI 不具合に対し、ユーザーと採否を合意したうえで 1 件ずつ修正する。
作業用 worktree で修正と検証を行い、push と返答を済ませて PR を再レビュー可能な状態に戻す。

## 手順

- 対象 branch と worktree を特定する。
    - Issue のコメント履歴から branch 名と PR を確認する。
    - worktree path は `~/.worktrees/<リポジトリー名>-<ブランチ名>` とする (ブランチ名の `/` は `-` に置換)。
    - worktree がない場合は、先に作業 worktree を用意すること。
- 進捗コメントで状態を `指摘対応中` に記録する。
    - `bash .claude/skills/review-response/scripts/add_progress_comment.sh <issue番号> <body_file>` で投稿する。
- 未対応の指摘がなくなるまで、1 件ずつ「修正 → コミット → push → 返答」のサイクルを繰り返す。
    - 未対応の指摘を取得し、対象コードを特定する。
        - GitHub: `bash .claude/skills/review-response/scripts/fetch_reviews.sh <PR番号>` で全体レビューとインライン comment を一括取得する。CI 結果は出力中の `checks` で確認する。
        - 代替: ユーザーが Web 画面の内容を貼り付ける。
        - 対象コードは `path`、`original_commit_id`、`original_line`、`original_start_line` から特定する。`diff_hunk` や現在の行番号から推測しないこと。
        - `git show <original_commit_id>:<path> | nl -ba` で comment 時点のコードを確認してから修正に入る。
        - コメント本文、パス、commit、行番号、対象コードの抜粋をセットで整理する。
    - 方針をユーザーへ提示し、採否を確定する。
        - 採用 / 非採用 / 別 Issue へ送る / 要件変更として issue-planning スキルに戻す。
    - 採用の場合 → 作業用 worktree で修正し、検証する。
        - 実行場所: 作業用 worktree (`~/.worktrees/<repo>-<branch>`)。
    - コミットし、push する。
        - コミットは `git-committer` サブエージェントに委譲する。この指摘への修正だけを 1 コミットにまとめるよう伝え、返ってきたコミットハッシュを後段のインライン返答で使う。
        - push はこのスキルが行う。通常 → `git push`、履歴書き換え → `git push --force-with-lease`。
    - 該当 review thread または PR コメントへ返答する。
        - 採用 → 何をどう直したかを返答する。
        - 非採用 / 別 Issue / 要件変更 → 理由と今後の扱いを返答する。
        - レビュー全体への返答: `bash .claude/skills/review-response/scripts/reply_review.sh <PR番号> <review_node_id> <body_file>` を使う。
        - インライン返答: `bash .claude/skills/review-response/scripts/reply_inline.sh <PR番号> <comment_id> <body_file> <commit_hash|->` を使う。`<commit_hash>` には必ずその指摘に対応したコミットを指定すること。コミット URL 不要な場合は `-` を渡す。
- Issue の `完了条件` を実態に合わせて更新する。
    - スコープ変更が入る場合は、チェック状態だけを動かさず、先に本文を更新すること。
    - 新しい独立要求は現 Issue を肥大化させず、後続 Issue に分離すること。
- 必要に応じて PR の状態を更新する。
    - ready PR の場合 → ユーザー認証後に再レビュー依頼する。
    - draft から ready に切り替える場合 → ユーザー認証後に `bash .claude/skills/review-response/scripts/set_ready.sh <PR番号>` を実行し、`Refs` を `Closes` に更新する。
- 進捗コメントで状態を記録する。
    - ready PR の再レビュー待ち → `再レビュー待ち`。
    - draft のまま継続 → `ドラフトレビュー中`。
    - draft → ready に切り替え → `レビュー待ち`。
    - `bash .claude/skills/review-response/scripts/add_progress_comment.sh <issue番号> <body_file>` で投稿する。
- wait_user_review に戻り、再レビューを待つ。

### issue-planning スキルに戻すべきケース

以下に該当する場合は、現 Issue 内で処理せず issue-planning スキルに戻って Issue を見直すこと。

- 指摘が新機能追加や別要件の持ち込みになっている。
- 既存の `完了条件` では受け止めきれない。
- 当初の非対象を今回の対象へ変更する必要がある。

## 原則

- ユーザー認証が必要な操作: draft → ready の切り替え、レビュー依頼の追加・再設定。
- レビューへの返答は `writing-rules` スキルの `prose_structure.md` に従うこと。
- resolve はレビュアーが行い、AI Agent は行わないこと。
- 合意した内容だけを反映し、Issue のスコープを勝手に広げないこと。
- 判断に迷う場合は作業を中断し、ユーザーに報告・相談すること。

## この段階の完了条件

- [ ] 指摘ごとの採否がユーザー確認済みである。
- [ ] 修正が作業用 worktree で検証済みである。
- [ ] 指摘への返答と再レビュー依頼が完了している。
- [ ] PR が再レビュー可能な状態になっている。
- [ ] 進捗コメントが PR 状態と一致している。
