# 実装とコミット

## 概要

Issue の内容を作業用 worktree で実装し, 検証してローカルコミットを積む.

## 手順

- 作業用 worktree で対象 branch にいることを確認する.
    - 実行場所: 以降の編集・検証・コミット作業はすべて作業用 worktree (`~/.worktrees/<repo>-<branch>`) で行うこと. メインリポジトリーでは作業しない.
    - Issue のコメント履歴に記録された branch 名と一致すること.
    - worktree path は `~/.worktrees/<リポジトリー名>-<ブランチ名>` とする (ブランチ名の `/` は `-` に置換).
    - branch または worktree が存在しない場合は, 先に作業ブランチと worktree を用意すること.
    - コマンド例:
        ```bash
        # 実行場所: 作業用 worktree
        cd ~/.worktrees/<repo>-<branch>
        git branch --show-current  # 想定 branch と一致することを確認
        ```
- 実装前に Issue を再読する.
    - 目的, 今回やること / やらないこと, 完了条件を確認する.
- 進捗コメントで状態を `実装中` に記録する.
    - `bash .claude/skills/implementation/scripts/add_progress_comment.sh <issue番号> <body_file>` で投稿する.
    - コマンド例:
        ```bash
        cat <<'EOF' > /tmp/progress.md
        状態: 実装中
        EOF
        bash .claude/skills/implementation/scripts/add_progress_comment.sh <issue番号> /tmp/progress.md
        ```
- 実装を進め, 検証する.
    - テスト, ビルド, 静的解析, 手動確認など, 必要なものを実行する.
    - `git commit` の代わりに `git-commit` スキルの `commit_with_signature.sh` でコミットする. 切り戻しや確認がしやすい細かい単位で構わない.
        - コマンド例: `bash .claude/skills/git-commit/scripts/commit_with_signature.sh "<メッセージ>"`. メッセージ末尾に `Co-authored-by: AI Agent` trailer が自動付加される. コミットの作法 (メッセージ書式, 1 コミット 1 関心事) は `git-commit` スキルに従う.
- 差分を Issue と照合する.
    - 実装が Issue の範囲を超えていないか確認すること.
    - スコープ変更が必要な場合はユーザーの承認を得たうえで, issue-planning スキルに基づき Issue を更新すること.

## 原則

- 編集, 検証, コミットは作業用 worktree で行うこと.
- 作業用ブランチのみを変更し, 他のブランチに修正を加えないこと.
- 判断に迷う場合は作業を中断し, ユーザーに報告・相談すること.

## この段階の完了条件

- [ ] 作業用 worktree で実装とローカルコミットが完了している.
- [ ] 進捗コメントで `実装中` が記録されている.
- [ ] pr-creation スキルを開始できる状態になっている.
