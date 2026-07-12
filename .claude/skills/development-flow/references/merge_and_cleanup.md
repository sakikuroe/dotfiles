# default branch へのマージと後処理

## 概要

マージ可能な条件を満たしているか確認し、ユーザーに最終的なマージを依頼する。マージ前には origin の default branch への追従と、この作業で作成した ADR や Design Doc がある場合はそのステータスの確定を行う。マージ後には Issue や worktree、ブランチの後処理を行い、次の作業に取り掛かれる状態に戻す。すでに PR がマージされている場合は、後処理のみを実行する。

## 手順

### 事前確認

この段階の作業は、制御用 worktree (メインリポジトリー) で実行する。まず、カレントブランチが default branch であることと、作業とは無関係な未コミットの差分がないことを確認する。次に、Issue のコメント履歴から対応するブランチ名と PR を特定する。特定できない場合は処理を中断し、ユーザーに確認する。作業用 worktree のパスは、ブランチ名を元に [sync_main.md](./sync_main.md) の配置規則に従って導出する。

続いて PR のステータスを確認し、その後の手順を分岐させる。ステータスが `MERGED` の場合は「マージ後の確認と後処理」へ進む。`CLOSED` かつ未マージの場合は処理を中断し、作業を再開するか破棄 (abandon) するかをユーザーに確認する。`OPEN` の場合は、以降の手順へ進む。

### default branch への追従

マージする前に、作業用 worktree にて origin の default branch を rebase し、最新の状態に追従させる。worktree が存在しない場合は [create_branch.md](./create_branch.md) に戻って再度準備する。rebase によって HEAD が変わった場合は `push --force-with-lease` で変更を反映したうえで、review-response スキルに戻って checks やレビューの状態を再確認する。これは、コミット履歴が変化することで、既存のレビュー承認や CI の結果が最新のコードに対するものではなくなってしまうためである。なお、強制的な push には `--force` を使わず、必ず `--force-with-lease` を使用すること。これは、リモートに自分の知らないコミットが積まれていた場合に、誤って上書きしてしまう事故を防ぐためである。

### ADR・Design Doc のステータス確定

この時点で、PR のレビューが Approve 済みであることを確認する。まだ Approve されていない場合は review-response スキルに戻り、指摘への対応と再レビューの依頼を継続する。

Approve 済みであれば、マージを依頼する前に、該当の PR で ADR や Design Doc を作成していないか確認する。ADR のステータスが Proposed であれば Accepted に、Design Doc が Approved のまま実装を進めていた場合は Implemented に変更する (詳細は documentation スキルの [adr.md](../../documentation/references/adr.md) や [design_doc.md](../../documentation/references/design_doc.md) を参照)。ステータスの変更は git-committer サブエージェントに委譲してコミットし、push する。

この際の push はステータス行の変更のみであり、設計や実装の内容自体は変わらないため、通常は再レビューを依頼する必要はない。ただし、push 時にレビュー承認が自動で失効する設定 (dismiss stale reviews) が有効なリポジトリでは承認が取り消されることがあるため、失効していないかを必ず確認し、失効していた場合は review-response スキルに戻って再度レビューを依頼する。また、push によって checks が再実行されることもあるため、続く「マージ可否の判定」の手順で改めて通過を確認する。

なお、この PR に ADR も Design Doc も紐付いていない場合、本手順は省略してよい。

### マージ可否の判定

Issue の完了条件がすべて達成されていること、また、PR が open かつ draft ではなく、レビューが承認済みで checks を通過し、コンフリクト (競合) が起きていないことを確認する。さらに、ADR や Design Doc を作成している場合は、そのステータスが確定済みであることもあわせて確認する。これらの条件をひとつでも満たしていない場合、原因がレビューでの指摘事項であれば review-response スキルに、ステータスの確定が済んでいないことであれば前節の手順に戻って対応する。

### マージの依頼

マージの進め方は、merge queue を使用するかどうかで分かれる。どちらの場合でも、進捗コメントの投稿には `bash .claude/skills/development-flow/scripts/add_progress_comment.sh <issue番号> <body_file>` を使用する。

merge queue を使用しない場合は、進捗コメントとして現在の状態を「マージ待ち」と記録したうえで、後述の「マージ依頼テンプレート」を用いてユーザーにマージを依頼する。マージ作業はユーザー自身が GitHub の Web 画面上で行うことを基本とするが、AI Agent が代行する場合はユーザーの承認を得てから `gh pr merge` を実行する。

merge queue を使用する場合は、進捗コメントとして状態を「merge queue 待ち」と記録し、後述の「merge queue 投入依頼テンプレート」を用いてキューへの投入を依頼する。AI Agent が代行する場合は、承認を得てから `gh pr merge --auto` を実行する。キューへの投入後は PR のステータスが `MERGED` になるまで待機し、checks の失敗などでキューから外れてしまった場合は review-response スキルに戻って対応する。

### マージ後の確認と後処理

PR が `MERGED` になったことを確認したら、Issue がクローズされているか (`Closes` キーワードによる自動クローズ、もしくは手動クローズ) を確認する。なお、worktree やブランチの削除といった後処理を、マージが確定する前に行ってはならない。マージ前に削除してしまうと、追加の指摘対応などで作業を再開する手段が失われてしまうためである。

後処理は以下のスクリプトを用いて一括で行う。リモートブランチの削除という取り消しが困難な操作を含むため、実行前には必ずユーザーからの承認を得ること。

```bash
# 実行場所: メインリポジトリー
cd /path/to/repo
bash .claude/skills/development-flow/scripts/cleanup.sh 123 --yes
```

スクリプトの実行場所は、必ずメインリポジトリーとする。削除対象である作業用の worktree 内から実行してしまうと、削除後にカレントディレクトリーが消失し、シェルが正常に動作しなくなるためである。また、`--yes` はリモートブランチ削除時の確認プロンプトをスキップするオプションである。Claude Code のような非対話環境では、対話プロンプトではなく事前のやり取りで承認を得ているため、このオプションを付けて実行する。

本スクリプトは、remote branch の削除、worktree の削除、local branch の削除、default branch の同期をこの順で実行する。worktree を先に削除しておかないと local branch の削除に失敗するため、この実行順序を変更してはならない。なお、`Squash and merge` や `Rebase and merge` を用いてマージした場合、ローカルの作業ブランチが default branch の直接の祖先にならず、`git branch -d` コマンドが失敗することがある。しかし、PR が `MERGED` となり変更が確実に取り込まれていれば問題はなく、スクリプトは自動で `git branch -D` にフォールバックして削除を完了させる。

後処理まで完了したら、進捗コメントとして状態を「完了」と記録し、最終的な結果 (マージされた PR、Issue のクローズ状態、実行した後処理の内容) を要約してユーザーに報告する。「完了」という状態は後処理まで無事に済んだことを意味するため、この記録は必ず後処理の後に行うこと。

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

- [ ] 該当する ADR や Design Doc がある場合、ステータスが確定され push 済みであること。
- [ ] 対象の変更が default branch に取り込まれていること。
- [ ] 進捗コメントに「完了」と記録されていること。
- [ ] 作業用の worktree とブランチが削除されていること。
- [ ] 制御用 worktree の default branch が同期されていること。