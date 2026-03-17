# 作業ブランチと worktree の作成

## 概要

Issue に紐付く短寿命ブランチを作成し, 開発用の worktree を用意します.
既存作業の再開時は branch と worktree を再利用します.

## 手順

- ブランチを用意します.
    - 形式: `<kind>/<issue番号>-<short-description>`
        - `kind`: `feature` / `fix` / `hotfix` / `chore` / `docs` / `refactor`.
        - 例: `feature/123-add-search-filters`.
    - `git fetch` でリモートを最新化してから, local / remote の有無を確認します.
    - 対応する branch が存在する場合は再利用します.
- worktree を用意します.
    - `~/.worktrees/<リポジトリー名>-<ブランチ名>` に置きます. ブランチ名の `/` は `-` に置換します.
        - 例: リポジトリー `my-app`, ブランチ `feature/123-add-search` → `~/.worktrees/my-app-feature-123-add-search`.
    - 対応する worktree が存在する場合は再利用します. 存在しない場合は branch の状態に応じて追加します.
- Issue の `進捗` を更新します.
    - `ブランチ` に branch 名を記録します.
    - `次` を `Step 04 (作業用 worktree で実装とコミット)` に更新します.

## 原則

- branch の衝突や worktree の不整合など, 判断に迷う場合は作業を中断し, ユーザーに報告, 相談します.

## この phase の完了条件

- [ ] Issue 番号付きの作業 branch が作成または再開されている.
- [ ] 作業用 worktree が作成または再開されている.
- [ ] Issue の `進捗` が作業に基づいて更新されている.
- [ ] Step 04 を開始できる状態になっている.
