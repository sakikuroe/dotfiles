# `main` の同期

## 概要

開発着手前に, 元の clone を制御用 worktree (`main` 固定) とし, `main` を `origin/main` に同期する.
この制御用 worktree を fetch, 同期, worktree 管理の起点とし, 実装やコミットには使わない.

## 手順

- 制御用 worktree が使える状態かを確認する.
    - git リポジトリーかつ `origin` 設定済み, `gh auth` 認証済みであること.
    - GitHub の default branch が `main` であること. 異なる場合は中断すること.
- `git fetch origin --prune` でリモートを最新化する.
    - `origin/main` が存在しない場合は中断すること.
- `git pull --ff-only` で `main` を `origin/main` に同期する.
    - `ahead` / `diverged` や未コミット差分がある場合は中断し, ユーザーと合意すること.

## worktree の配置先

作業用 worktree は `~/.worktrees/<リポジトリー名>-<ブランチ名>` に配置する. ブランチ名の `/` は `-` に置換する.
path は Issue に記録せず, branch 名からこの規則で都度求める.

例: `my-app` + `feature/123-add-search` → `~/.worktrees/my-app-feature-123-add-search`

## 原則

- 制御用 worktree では実装やコミットを行わないこと.
- default branch が `main` でない, または `origin/main` が存在しない場合は自動復旧せず中断すること.
- 判断に迷う場合は作業を中断し, ユーザーに報告・相談すること.

## この段階の完了条件

- [ ] `main` が `origin/main` と同期している.
- [ ] 作業ブランチと worktree の作成に進める状態になっている.
