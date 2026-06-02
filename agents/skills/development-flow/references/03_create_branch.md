# 作業ブランチと worktree の作成

## 概要

Issue に紐付く短寿命ブランチを作成し, 開発用の worktree を用意する.
既存作業の再開時は branch と worktree を再利用する.

## 手順

- ブランチを用意する.
    - 形式: `<kind>/<issue番号>-<short-description>`
        - `kind`: `feature` / `fix` / `hotfix` / `chore` / `docs` / `refactor`.
        - 例: `feature/123-add-search-filters`.
    - `git fetch origin --prune` でリモートを最新化してから, local / remote の有無を確認する.
    - 対応する branch が存在する場合は再利用する.
    - 新規作成する場合: `git checkout -b <branch-name>`
- worktree を用意する.
    - `~/.worktrees/<リポジトリー名>-<ブランチ名>` に置く. ブランチ名の `/` は `-` に置換する.
        - 例: リポジトリー `my-app`, ブランチ `feature/123-add-search` → `~/.worktrees/my-app-feature-123-add-search`.
    - `bash ${CLAUDE_SKILL_DIR}/scripts/create_worktree.sh <branch-name>` で作成・再利用を一括して行う.
        - 実行場所: メインリポジトリーから実行するのが基本. worktree 内からでも動作する (スクリプトが `git worktree list` の先頭行でメインリポジトリーを特定する).
        - コマンド例:
            ```bash
            # 実行場所: メインリポジトリー
            bash ${CLAUDE_SKILL_DIR}/scripts/create_worktree.sh feature/123-add-search-filters
            ```
- ブランチ名を進捗コメントで記録する.
    - コマンド例:
        ```bash
        cat <<'EOF' > /tmp/progress.md
        ブランチ: <branch-name>

        *This comment was posted by AI Agent.*
        EOF
        bash ${CLAUDE_SKILL_DIR}/scripts/add_progress_comment.sh <issue番号> /tmp/progress.md
        ```

## 原則

- branch の衝突や worktree の不整合など, 判断に迷う場合は作業を中断し, ユーザーに報告・相談すること.

## この phase の完了条件

- [ ] Issue 番号付きの作業 branch が作成または再開されている.
- [ ] 作業用 worktree が作成または再開されている.
- [ ] 進捗コメントでブランチ名が記録されている.
- [ ] Step 04 を開始できる状態になっている.
