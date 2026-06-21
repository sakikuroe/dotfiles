# 実装とコミット

## 概要

Issue の内容を作業用 worktree で実装し, 検証してローカルコミットを積む.

## 手順

- 作業用 worktree で対象 branch にいることを確認する.
    - 実行場所: 以降の編集・検証・コミット作業はすべて作業用 worktree (`~/.worktrees/<repo>-<branch>`) で行うこと. メインリポジトリーでは作業しない.
    - Issue のコメント履歴に記録された branch 名と一致すること.
    - worktree path は Step 01 の配置規則に従うこと.
    - branch または worktree が存在しない場合は Step 04 に戻ること.
    - コマンド例:
        ```bash
        # 実行場所: 作業用 worktree
        cd ~/.worktrees/<repo>-<branch>
        git branch --show-current  # 想定 branch と一致することを確認
        ```
- 実装前に Issue を再読する.
    - 目的, 今回やること / やらないこと, 完了条件を確認する.
- 進捗コメントで状態を `実装中` に記録する.
    - `bash ${CLAUDE_SKILL_DIR}/scripts/add_progress_comment.sh <issue番号> <body_file>` で投稿する.
    - コマンド例:
        ```bash
        cat <<'EOF' > /tmp/progress.md
        状態: 実装中
        EOF
        bash ${CLAUDE_SKILL_DIR}/scripts/add_progress_comment.sh <issue番号> /tmp/progress.md
        ```
- 実装を進め, 検証する.
    - テスト, ビルド, 静的解析, 手動確認など, 必要なものを実行する.
    - 作業しやすい粒度でローカルコミットを積む. 切り戻しや確認がしやすい細かい commit で構わない.
    - `git commit` の代わりに `bash ${CLAUDE_SKILL_DIR}/scripts/commit_with_signature.sh "<メッセージ>"` を使うこと. これによりコミットメッセージ末尾に `Co-authored-by: AI Agent` trailer が自動付加される.
- 差分を Issue と照合する.
    - 実装が Issue の範囲を超えていないか確認すること.
    - スコープ変更が必要な場合はユーザーの承認を得たうえで, Step 02 に基づき Issue を更新すること.

## 原則

- 編集, 検証, コミットは作業用 worktree で行うこと.
- 作業用ブランチのみを変更し, 他のブランチに修正を加えないこと.
- 判断に迷う場合は作業を中断し, ユーザーに報告・相談すること.

## この phase の完了条件

- [ ] 作業用 worktree で実装とローカルコミットが完了している.
- [ ] 進捗コメントで `実装中` が記録されている.
- [ ] Step 06 を開始できる状態になっている.
