# default branch の同期

## 概要

開発に着手する前に、元の clone を制御用 worktree (default branch 固定) として整え、default branch を origin と同期する。制御用 worktree は fetch、同期、worktree 管理の起点としてのみ使い、実装やコミットには使わない。実装の差分が混ざると、以降のブランチ作成や後処理の起点として信頼できなくなるためである。

## 手順

まず、制御用 worktree が使える状態かを確認する。具体的には、git リポジトリーであること、`origin` が設定済みであること、`gh auth status` で認証済みであることを確かめる。あわせて default branch 名を `git symbolic-ref refs/remotes/origin/HEAD` などで取得しておく。既定では `main` だが `master` や `develop` の場合もあるため、名前を思い込みで決めない。

次に、`git fetch origin --prune` でリモートの状態を最新化する。origin に default branch が存在しない場合は、自動での復旧を試みず、中断してユーザーに報告する。

最後に、制御用 worktree で `git pull --ff-only` を実行し、default branch を origin と一致させる。ローカルが ahead や diverged になっている場合や、未コミットの差分が残っている場合は、勝手に整理せず中断し、扱いをユーザーと合意する。このほかにも判断に迷う状態に遭遇した場合は、作業を中断してユーザーに報告・相談する。

## worktree の配置先

作業用 worktree は `~/.worktrees/<リポジトリー名>-<ブランチ名>` に配置し、ブランチ名に含まれる `/` は `-` に置換する。たとえばリポジトリー `my-app` とブランチ `feature/123-add-search` の組であれば、配置先は `~/.worktrees/my-app-feature-123-add-search` となる。path は Issue に記録せず、ブランチ名からこの規則で都度求める。path を記録すると、環境の違いや再作成のたびに実態とずれていくためである。

## この段階の完了条件

- [ ] default branch が origin と同期している。
- [ ] 作業ブランチと worktree の作成に進める状態になっている。
