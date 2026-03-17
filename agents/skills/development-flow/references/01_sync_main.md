# 開始地点の判定と `main` の同期

## 概要

新規着手か再開かを判定し, 適切な Step へ振り分けます.
元の clone を制御用 worktree として `main` に固定し, fetch, 同期, worktree 管理の起点にします.

## 手順

- 制御用 worktree が使える状態かを確認します.
    - git リポジトリーかつ `origin` 設定済み, `gh auth` 認証済みであること.
    - GitHub の default branch が `main` であること. 異なる場合は中断します.
- `git fetch origin --prune` でリモートを最新化します.
    - `origin/main` が存在しない場合は中断します.
- `git worktree list --porcelain` で worktree 一覧を取得します.
    - 作業用 worktree の有無と, branch - path の対応を把握します.
- 新規着手か再開かを判定します.
    - Issue が未作成, または branch / PR / worktree が存在しない場合:
        - `git pull --ff-only` で `main` を `origin/main` に同期します.
        - `ahead` / `diverged` や未コミット差分がある場合は中断し, ユーザーと合意します.
        - Step 02 へ進みます.
    - Issue, branch, PR, worktree のいずれかが存在する場合:
        - Issue の `進捗` から状態, branch 名, PR 番号, `次` を確認します.
        - branch, worktree, PR の現在状態と照合し, 次の Step を決めます.
        - 対応関係が一意に決まらない場合は中断し, ユーザーに確認します.

### 再開時の次 Step

Issue, branch, PR, worktree の存在状況から次の Step を判断します.

- Issue あり, branch なし → Step 03.
- branch あり, worktree なし → Step 03.
- worktree あり, PR なし → Step 04 または 05.
- draft / ready PR でレビュー待ち → Step 06.
- レビュー指摘, CI 失敗, 競合あり → Step 07.
- PR が `MERGED` → Step 08.

### worktree の配置先

worktree は `~/.worktrees/<リポジトリー名>-<ブランチ名>` に配置します. ブランチ名の `/` は `-` に置換します.
path は Issue に記録せず, branch 名からこの規則で都度求めます.

例: `my-app` + `feature/123-add-search` → `~/.worktrees/my-app-feature-123-add-search`

### 再開情報の取得優先順位

再開時は以下の順に情報を取得し, 上位を優先します.

1. Issue の `進捗` (`状態`, `ブランチ`, `PR`, `次`).
2. `git worktree list --porcelain`.
3. `gh pr list --head "<branch名>" --state all`.

## 原則

- 制御用 worktree では実装やコミットを行いません.
- default branch が `main` でない, または `origin/main` が存在しない場合は自動復旧せず中断します.
- 判断に迷う場合は作業を中断し, ユーザーに報告, 相談します.

## この phase の完了条件

- [ ] 新規着手 / 再開の判定が完了している.
- [ ] 新規着手の場合, `main` が `origin/main` と同期している.
- [ ] 再開の場合, 次に進む Step が特定できている.
