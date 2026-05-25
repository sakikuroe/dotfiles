# レビュー指摘への対応

## 概要

レビュー指摘, PR コメント, CI 不具合に対し, ユーザーと採否を合意したうえで 1 件ずつ修正します.
作業用 worktree で修正と検証を行い, push と返答を済ませて PR を再レビュー可能な状態に戻します.

## 手順

- 対象 branch と worktree を特定します.
    - Issue の `進捗` から branch 名と PR を確認します.
    - worktree path は Step 01 の配置規則に従います (`~/.worktrees/<リポジトリー名>-<ブランチ名>`).
    - worktree がない場合は Step 03 に戻ります.
- Issue の `進捗` を `指摘対応中` に更新します.
    - `bash ${CLAUDE_SKILL_DIR}/scripts/update_issue_body.sh <issue番号> <body_file>` を使います.
- 未対応の指摘がなくなるまで, 1 件ずつ「修正 → コミット → push → 返答」のサイクルを繰り返します. 複数の指摘をまとめて 1 コミットにしてはいけません.
    - 未対応の指摘を取得し, 対象コードを特定します.
        - GitHub: `bash ${CLAUDE_SKILL_DIR}/scripts/fetch_reviews.sh <PR番号>` で全体レビューとインライン comment を一括取得します. CI 結果は出力中の `checks` で確認します.
        - 代替: ユーザーが Web 画面の内容を貼り付ける.
        - 対象コードは `path`, `original_commit_id`, `original_line`, `original_start_line` から特定します. `diff_hunk` や現在の行番号から推測しません.
        - `git show <original_commit_id>:<path> | nl -ba` で comment 時点のコードを確認してから修正に入ります.
        - コメント本文, パス, commit, 行番号, 対象コードの抜粋をセットで整理します.
    - 方針をユーザーへ提示し, 採否を確定します.
        - 採用 / 非採用 / 別 Issue へ送る / 要件変更として Step 02 に戻す.
    - 採用の場合 → 作業用 worktree で修正し, 検証します.
        - 実行場所: 作業用 worktree (`~/.worktrees/<repo>-<branch>`).
    - コミットし, push します.
        - 通常 → `git push`, 履歴書き換え → `git push --force-with-lease`.
        - 次の指摘へ進む前に必ず push まで完了させます.
    - 該当 review thread または PR コメントへ quote reply で返答します.
        - 返答本文の末尾には必ず署名 `*This comment was posted by AI Agent.*` を含めます. スクリプトは署名を自動付加しません.
        - 採用 → 何をどう直したかと commit URL を返答します (インライン返答は `--with-commit` で自動付加).
        - 非採用 / 別 Issue / 要件変更 → 理由と今後の扱いを返答します.
        - レビュー全体への返答: `bash ${CLAUDE_SKILL_DIR}/scripts/reply_review.sh <PR番号> <review_node_id> <body_file>` を使います.
            - 実行場所: 作業用 worktree (`gh pr comment` がリポジトリを判定するため worktree でもメインリポジトリでも可).
            - コマンド例:
                ```bash
                cat <<'EOF' > /tmp/reply.md
                ご指摘ありがとうございます. 〇〇を修正しました.

                *This comment was posted by AI Agent.*
                EOF

                bash ${CLAUDE_SKILL_DIR}/scripts/reply_review.sh 123 PRR_xxxx /tmp/reply.md
                ```
        - インライン review comment への返答: `bash ${CLAUDE_SKILL_DIR}/scripts/reply_inline.sh <PR番号> <comment_id> <body_file> [--with-commit]` を使います.
            - 実行場所: 作業用 worktree. `--with-commit` を付ける場合は反映済みコミットの HEAD にいる worktree で実行する.
            - `--with-commit` を付けると, 直近の HEAD コミット URL を本文中の署名直前に挿入してくれます.
            - コマンド例 (採用・コミット URL 付き):
                ```bash
                cat <<'EOF' > /tmp/reply_inline.md
                ご指摘ありがとうございます. 〇〇を修正しました.

                *This comment was posted by AI Agent.*
                EOF

                bash ${CLAUDE_SKILL_DIR}/scripts/reply_inline.sh 123 456789 /tmp/reply_inline.md --with-commit
                ```
- Issue の `完了条件` を実態に合わせて更新します.
    - スコープ変更が入る場合は, チェック状態だけを動かさず, 先に本文を更新します.
    - 新しい独立要求は現 Issue を肥大化させず, 後続 Issue に分離します.
- 必要に応じて PR の状態を更新します.
    - ready PR の場合 → ユーザー認証後に再レビュー依頼します.
    - draft から ready に切り替える場合 → ユーザー認証後に `bash ${CLAUDE_SKILL_DIR}/scripts/set_ready.sh <PR番号>` を実行し, `Refs` を `Closes` に更新します.
- Issue の `進捗` を更新します.
    - ready PR の再レビュー待ち → `再レビュー待ち`.
    - draft のまま継続 → `ドラフトレビュー中`.
    - draft → ready に切り替え → `レビュー待ち`.
    - 更新には `bash ${CLAUDE_SKILL_DIR}/scripts/update_issue_body.sh <issue番号> <body_file>` を使います.
- Step 06 に戻り, 再レビューを待ちます.

### Step 02 に戻すべきケース

以下に該当する場合は, 現 Issue 内で処理せず Step 02 に戻って Issue を見直します.

- 指摘が新機能追加や別要件の持ち込みになっている.
- 既存の `完了条件` では受け止めきれない.
- 当初の非対象を今回の対象へ変更する必要がある.

## 原則

- ユーザー認証が必要な操作: draft → ready の切り替え, レビュー依頼の追加・再設定.
- resolve はレビュアーが行い, AI Agent は行いません.
- 合意した内容だけを反映し, Issue のスコープを勝手に広げません.
- 判断に迷う場合は作業を中断し, ユーザーに報告, 相談します.

## この phase の完了条件

- [ ] 指摘ごとの採否がユーザー確認済みである.
- [ ] 修正が作業用 worktree で検証済みである.
- [ ] 指摘への返答と再レビュー依頼が完了している.
- [ ] PR が再レビュー可能な状態になっている.
- [ ] Issue の `進捗` が PR 状態に一致している.
