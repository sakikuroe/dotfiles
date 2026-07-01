# Push と PR の作成

## 概要

作業用 worktree のブランチを origin へ push し、default branch 向けの PR を作成する。
初回 push 前には origin の default branch を基点に履歴を整形する。
既存の open PR がある場合は再利用する。

## 手順

- 作業用 worktree で対象 branch にいることを確認する。
    - 実行場所: push と履歴整形は作業用 worktree で行うこと。
    - コマンド例:
        ```bash
        # 実行場所: 作業用 worktree
        cd ~/.worktrees/<repo>-<branch>
        git fetch origin --prune
        git status   # 未コミット差分がないことを確認
        ```
- origin の default branch の存在を確認する。
- 未コミット差分がないことを確認する。
    - 意図しない差分がある場合は、コミット / 破棄 / 退避の方針を決めてから進むこと。
- push 方法を決める。
    - remote に branch が未公開の場合 → 公開前に履歴を整形してから push する。
        - origin の default branch に `git rebase` → `git reset --soft` → 適切な粒度で commit を作り直す。
    - 公開済みの場合 → 通常 push する。
    - コマンド例:
        ```bash
        # 実行場所: 作業用 worktree
        git push -u origin <branch>           # 初回 (upstream を設定)
        # または
        git push                              # 2 回目以降
        git push --force-with-lease           # 履歴整形した場合
        ```
- PR を決定する。
    - `gh pr list --head "$HEAD_BRANCH" --state all` で既存 PR を確認し、open PR があれば再利用する。
    - Issue の完了条件がすべて満たされていれば ready PR、そうでなければ draft PR とする。
    - ready PR は `Closes #<issue番号>`、draft PR は `Refs #<issue番号>` を使う。
- PR の内容をユーザーへ提示し、認証を得る。
    - PR タイトル、本文、draft / ready の別を提示する。
- ユーザーの認証後に PR を作成または更新する。
    - 実行場所はメインリポジトリーとすること。`gh pr create` はカレントブランチから PR を作るため、worktree から実行すると default branch から作ろうとしてエラーになる事故が起きやすい。
    - PR 本文は `templates/pr.md` を参照して書くこと。
    - PR 作成は `bash .claude/skills/pr-creation/scripts/create_pr.sh <タイトル> <body_file> <head_branch>` を使うこと。
    - コマンド例:
        ```bash
        # 実行場所: メインリポジトリー
        cat <<'EOF' > /tmp/pr_body.md
        ## 本 PR に対応する Issue

        Closes #<issue番号>

        ## 本 PR で行った変更の概要

        ...

        ## 動作を確認する手順

        ...
        EOF

        bash .claude/skills/pr-creation/scripts/create_pr.sh "<タイトル>" /tmp/pr_body.md <branch>
        ```
- ready PR の場合、レビュー依頼先をユーザーに確認する。
    - 「レビューを依頼するユーザーがいれば GitHub ユーザー名を教えてください」と尋ねる。
    - ユーザーが指定した場合は `bash .claude/skills/pr-creation/scripts/add_reviewer.sh <PR番号> <username>` で依頼する。
    - 不要と回答した場合はスキップする。
- PR URL と状態を進捗コメントで記録する。`add_progress_comment.sh` で投稿すること。
    - ready PR → 状態は `レビュー待ち`、draft PR → `ドラフトレビュー中`。

## 原則

- PR のタイトルおよび本文は日本語で書くこと。
- PR 本文は `writing-rules` スキルの `prose_structure.md` に従うこと。
- `--force` は使わず、必要時は `--force-with-lease` のみ使うこと。
- ユーザーの認証を得ずに PR を作成しないこと。
- 判断に迷う場合は作業を中断し、ユーザーに報告・相談すること。

## この段階の完了条件

- [ ] 作業ブランチが origin に push 済みである。
- [ ] PR が default branch 向けに作成または再利用されている。
- [ ] 進捗コメントが PR 状態と一致している。
- [ ] review-response スキルを開始できる状態になっている。
