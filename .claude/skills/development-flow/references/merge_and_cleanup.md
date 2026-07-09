# default branch へのマージと後処理

## 概要

マージ可能条件を確認し、ユーザーへ最終マージを依頼する。マージ前には origin の default branch への追従と、書いた ADR・Design Doc があればそのステータス確定を行い、マージ後には Issue、worktree、ブランチの後処理を行って、次の作業に入れる状態へ戻す。PR がすでに merge 済みの場合は、後処理だけを実行する。

## 手順

### 事前確認

この段階は制御用 worktree (メインリポジトリー) で実行する。まず、default branch にいることと、無関係な未コミット差分がないことを確認する。次に、Issue のコメント履歴からブランチ名と PR を特定する。特定できない場合は中断し、ユーザーに確認する。作業用 worktree の path は、ブランチ名から [sync_main.md](./sync_main.md) の配置規則で求める。

続いて PR の状態を確認し、進み方を分岐する。`MERGED` の場合はマージ後の確認と後処理へ進む。`CLOSED` かつ未マージの場合は中断し、作業を継続するか abandon するかをユーザーに確認する。`OPEN` の場合は以降の手順へ進む。

### default branch への追従

マージの前に、作業用 worktree で origin の default branch に rebase して追従する。worktree が存在しない場合は [create_branch.md](./create_branch.md) に戻って用意し直す。rebase で HEAD が変わった場合は `push --force-with-lease` で反映し、review-response スキルに戻って checks とレビューの状態を再確認する。履歴が変わると、既存の承認や CI の結果が最新のコードに対するものでなくなるためである。なお、強制 push に `--force` は使わず、必ず `--force-with-lease` を使う。リモートに自分の知らないコミットが積まれていた場合に、気づかず上書きしてしまう事故を防ぐためである。

### ADR・Design Doc のステータス確定

この時点で PR のレビューが Approve 済みであることを確認する。Approve 前であれば review-response スキルに戻り、指摘対応と再レビューの依頼を続ける。

Approve 済みであれば、マージを依頼する前に、この PR で ADR や Design Doc を書いていないかを確認する。ADR を Proposed で書いていれば Accepted に、Design Doc を Approved のまま実装を進めてきていれば Implemented に変更する (documentation スキルの [adr.md](../../documentation/references/adr.md)・[design_doc.md](../../documentation/references/design_doc.md) を参照)。変更は git-committer サブエージェントに委譲してコミットし、push する。

この push はステータス行だけの変更であり、設計や実装の内容そのものは変えないため、レビューを取り直す必要はない。ただし、push によってレビュー承認が失効する設定 (dismiss stale reviews) が有効なリポジトリでは承認が失効することがあるため、失効していないかを確認し、失効していた場合は review-response スキルに戻ってレビューを依頼し直す。また push によって checks が再実行されることがあるため、次の「マージ可否の判定」で改めて通過を確認する。

この PR に ADR も Design Doc もない場合、この手順は不要である。

### マージ可否の判定

Issue の完了条件がすべて達成済みであることと、PR が open であり、draft でなく、レビュー承認済みで、checks を通過し、競合がなく、ADR や Design Doc を書いている場合はそのステータスが確定済みであることを確認する。ひとつでも満たさない場合は、レビュー指摘が原因であれば review-response スキルに、ステータス確定が済んでいないことが原因であれば前節の手順に戻る。

### マージの依頼

マージの進め方は、merge queue を使うかどうかで分かれる。どちらの場合も、進捗コメントの投稿には `bash .claude/skills/development-flow/scripts/add_progress_comment.sh <issue番号> <body_file>` を使う。

merge queue を使わない場合は、進捗コメントで状態を「マージ待ち」に記録し、下記のマージ依頼テンプレートでユーザーへマージを依頼する。マージはユーザーが GitHub Web で行うことを基本とし、AI Agent が代行する場合は承認を得てから `gh pr merge` を実行する。

merge queue を使う場合は、進捗コメントで状態を「merge queue 待ち」に記録し、下記の投入依頼テンプレートで queue への投入を依頼する。AI Agent が代行する場合は承認を得てから `gh pr merge --auto` を実行する。投入後は PR が `MERGED` になるまで待ち、checks の失敗などで queue から外れた場合は review-response スキルに戻って対応する。

### マージ後の確認と後処理

PR が `MERGED` になったことを確認したら、Issue のクローズ状態 (`Closes` による自動クローズ、または手動クローズ) を確かめる。後処理 (worktree やブランチの削除) をマージ確定より前に行ってはならない。マージ前に消してしまうと、指摘対応などで作業へ戻る手段を失うためである。

後処理は次のスクリプトで一括して行う。リモートブランチの削除という取り消しの難しい操作を含むため、実行前に必ずユーザーの承認を得る。

```bash
# 実行場所: メインリポジトリー
cd /path/to/repo
bash .claude/skills/development-flow/scripts/cleanup.sh 123 --yes
```

実行場所は必ずメインリポジトリーとする。削除対象の worktree 内から実行すると、削除後にカレントディレクトリーが消えてシェルが追従できなくなるためである。`--yes` はリモートブランチ削除の確認プロンプトをスキップするオプションであり、承認を対話プロンプトではなく事前のやり取りで得ている非対話環境 (Claude Code など) では、これを付けて実行する。

スクリプトは、remote branch の削除、worktree の削除、local branch の削除、default branch の同期をこの順で実行する。worktree を先に削除しないと local branch の削除が失敗するため、順序を入れ替えてはならない。なお、`Squash and merge` や `Rebase and merge` でマージした場合は、local の作業ブランチが default branch の祖先にならず `git branch -d` が失敗することがあるが、PR が `MERGED` で変更が取り込まれていれば問題はなく、スクリプトが `git branch -D` にフォールバックして削除する。

後処理まで終えたら、進捗コメントで状態を「完了」に記録し、最終結果 (マージされた PR、Issue のクローズ状態、後処理の内容) をユーザーへ要約する。「完了」が後処理まで済んだことを表す状態であるため、記録は後処理の後に行う。

### マージ依頼テンプレート

```text
マージ準備が完了しました。

- PR: <PR URL>
- Issue: <Issue URL>
- 反映ブランチ: <head> -> <base>
- merge 方法: <Create a merge commit / Squash and merge / Rebase and merge>
- Issue 完了条件: すべて達成済み
- レビュー / checks / mergeable: 問題なし

GitHub Web で最終マージをお願いします。
```

### merge queue 投入依頼テンプレート

```text
merge queue への投入準備が完了しました。

- PR: <PR URL>
- Issue: <Issue URL>
- 反映ブランチ: <head> -> <base>
- Issue 完了条件: すべて達成済み
- レビュー / checks / mergeable: 問題なし

GitHub Web で `Add to merge queue` または `Merge when ready` をお願いします。
```

## この段階の完了条件

- [ ] 該当する ADR・Design Doc がある場合、ステータスが確定し push 済みである。
- [ ] 対象変更が default branch に取り込まれている。
- [ ] 進捗コメントで「完了」が記録されている。
- [ ] 作業用 worktree とブランチが削除されている。
- [ ] 制御用 worktree の default branch が同期されている。
