---
name: development-flow
description: GitHub Issue を起点とする AI 主導の開発フローを定めるスキルである。開発タスクに着手するとき、Issue を作成するとき、または Issue から PR・マージまでの手順を進めるときは必ずこのフローに従う。ユーザーが「実装して」「直して」「ブランチを作って」「PRを出して」のように Issue に明示的に言及せず開発を依頼した場合も、必ずこのフローに従う。
---

## 概要

GitHub Issue を要求の起点とし、AI Agent が実装、検証、git/gh 操作を担う開発フローである。元の clone を制御用 worktree (default branch 固定) とし、実装はそのリポジトリ直下の `.worktrees/` 配下の作業用 worktree で行う。対象範囲は 1 Issue の着手準備から merge 完了までである。

本スキルは全体の順序を統括し、ワークスペースの準備 (default branch の同期、作業ブランチ・worktree の作成) とマージ・後処理を直接担う。途中の各段階 (Issue 起票、実装、PR 作成、レビュー対応) は独立したスキルとして定義されており、それぞれ単独でも利用できるが、1 Issue を着手から merge まで通す場合は、本スキルが定める順序と引き継ぎの規則に従って呼び出す。

このフローが目指すのは、本スキルを起点に各スキルを順に呼び出すだけで Issue 駆動開発が一巡し、ユーザーの判断が必要な箇所でのみ停止する状態である。したがって AI Agent は、後述の承認ポイントと、各スキルが定める内容の合意・相談の場面を除き、ユーザーへ都度確認せずに次の段階へ進む。

## 前提

対象は default branch (既定では `main`) を持つ GitHub リポジトリーであり、default branch へは直接 push せず、必ず作業ブランチと PR を経由する。初回着手時には `gh auth status` で認証を確認し、あわせてリポジトリーの保護ルール (必須承認数、status checks、merge queue の有無) を把握しておく。単独開発で他者の承認が必須となる保護ルールがある場合は、フローを最後まで進めてもマージできないため、別アカウントの用意かルールの調整を先に行う必要がある。

## 手順

フローは「準備」「設計 (該当する場合)」「実装から PR」「マージと後処理」の 4 つのまとまりで進める。各段階の詳細な手順は参照先のスキルと文書に委ね、ここでは全体の順序だけを定める。

まず準備として、default branch を origin と同期し ([references/sync_main.md](./references/sync_main.md))、ユーザーの要求から Issue を起票して実装方針の承認を得る ([issue-planning](../issue-planning/SKILL.md))。

### 設計が必要な場合の流れ

実装方針の検討で、作り方が複数あって間違えたときの手戻りが大きい、他のメンバーやシステムに影響する、といった条件に複数当てはまる場合は、実装より先に Design Doc を書く。Design Doc が必要かどうかの判断基準は documentation スキルの [design_doc.md](../documentation/references/design_doc.md) に従う。

Design Doc を書く場合の流れは次のとおりである。まず Issue に紐付く作業ブランチと worktree を作成し ([references/create_branch.md](./references/create_branch.md))、作業用 worktree で Design Doc を書いてドラフト PR として提出する。PR 上で設計のレビューを受け、合意が得られたらステータスを Approved に変更して push する。この時点で、将来を縛る決定を ADR として切り出し、Design Doc とADR を相互にリンクする。そのまま同じブランチで実装に進む。

Design Doc が不要な場合は、方針の承認が得られた後、Issue に紐付く作業ブランチと worktree を作成する ([references/create_branch.md](./references/create_branch.md))。ブランチの作成を方針承認の後に置くのは、方針が変わると変更の種別や内容、すなわちブランチ名も変わりうるためである。

### 実装から PR

作業用 worktree で実装、検証、コミットを行う ([implementation](../implementation/SKILL.md))。実装の過程で将来を縛る決定をした場合 (技術選定、データモデルの構造、全員が従う規約など) は、ADR を Proposed で書き、同じブランチに含める。

利用者から見える挙動が変わる場合は、同じ PR の中で恒常系ドキュメントも更新する。具体的には、docs (reference / how-to 等) への反映と CHANGELOG の Unreleased セクションへの追記を、実装と同じ PR に含める。ドキュメント更新を別の PR に分離すると高い確率で忘れられるため、同一 PR にまとめることを完了条件とする。

実装が済んだら、Design Doc がある場合はドラフトを解除し (Design Doc で既にドラフト PR を作成済みのため)、ない場合は新たに PR を作成する ([pr-creation](../pr-creation/SKILL.md))。実装、ADR、ドキュメントの変更をまとめてレビューに出す。

PR を作成した後は、レビューと CI の結果に応じて、指摘対応と再レビューの依頼を繰り返す ([review-response](../review-response/SKILL.md))。

### マージと後処理

Approve されたら、ADR のステータスを Accepted に、Design Doc のステータスを Implemented に、それぞれ変更して push する (書いたものだけ)。マージ可能条件が揃ったことを確認してユーザーへ最終マージを依頼し、マージ後には worktree とブランチの後処理を行って、次の作業に入れる状態へ戻す ([references/merge_and_cleanup.md](./references/merge_and_cleanup.md))。

## 段階間の引き継ぎ

各スキルは単独でも使えるように、対応 Issue、作業ブランチ、実装計画の有無、検証方法をユーザーに確認する手順を持っている。しかし本フローの中で呼び出すときに、前の段階までに確定した情報を同じ質問で聞き直すと、フローが不要に停止してしまう。そのため、フロー内では確定済みの情報を再度ユーザーに尋ねず、そのまま各スキルへ引き継ぐ。たとえば implementation が確認する実装計画には issue-planning で承認済みの計画を、review-response が確認する対応 Issue には本フローで扱っている Issue を、それぞれ用いる。検証方法のようにフロー上でまだ確定していない情報だけを、その場でユーザーに確認する。

段階をまたいで持ち越す状態は、Issue の進捗コメントに集約する。各スキルは状態が変わるたびに進捗コメント (ブランチ名・PR・状態) を投稿するため、中断した作業を再開するときは、Issue のコメント履歴と `git worktree list` / `gh pr view` の現在状態から、いまどの段階にいるかを判断して該当段階から進める。

## 承認ポイント

GitHub 上に外から見える成果物を作る操作と、取り消しの難しい操作だけは、ユーザーの承認を得てから実行する。具体的には次の操作が対象であり (括弧内は担当するスキル)、各段階のスキルもこれに従う。

- `gh issue create` による Issue の作成 (issue-planning)
- `gh pr create` による PR の作成 (pr-creation)
- PR の draft から ready への切り替え (pr-creation)
- レビュー依頼の追加・再設定 (pr-creation)
- `gh pr merge` によるマージ、および merge queue への投入 (development-flow)
- リモートブランチの削除を含むマージ後の後処理 (development-flow)

上記以外の操作 (コミット、push、Issue への進捗コメント、PR やレビューへの返答) は、承認を待たずに進めてよい。なお、この承認とは別に、実装方針や PR 本文の草案の承認、レビュー指摘の採否の合意といった「内容の合意」を各スキルが定めており、それらは各スキルの手順に従う。また、承認ポイントを最小限に絞る一方で、判断に迷う場合や想定外の状態に遭遇した場合は、どの段階でも作業を中断してユーザーに報告・相談する。

## 役割

AI Agent は、Issue 草案の作成、実装と検証、git/gh 操作、レビュー指摘への返答を担う。ユーザーは、承認ポイントでの承認、GitHub の認証、GitHub Web でのレビュー、最終的なマージの判断を担う。

## 状態値

AI Agent が作業中の状態は「〜中」、外部の応答を待つ状態は「〜待ち」で表す。各状態は括弧内のスキルが進捗コメントとして記録する。

- `方針レビュー待ち` — 実装方針コメントを投稿し、ユーザーの承認を待っている (issue-planning)。
- `設計レビュー待ち` — Design Doc のドラフト PR を提出し、設計レビューを待っている (development-flow)。
- `実装中` — 実装、検証を進めている (implementation)。
- `ドラフトレビュー中` — draft PR で相談や途中レビューを受けている (pr-creation / review-response)。
- `レビュー待ち` — ready PR で正式レビューを待っている (pr-creation / review-response)。
- `指摘対応中` — レビュー指摘や CI 不具合に対応している (review-response)。
- `再レビュー待ち` — 指摘対応を反映し、再レビューを待っている (review-response)。
- `マージ待ち` — ユーザーへ最終マージを依頼済みである (development-flow)。
- `merge queue 待ち` — merge queue に投入済みである (development-flow)。
- `完了` — merge と後処理を確認済みである (development-flow)。

## ドキュメントとの連携

フローの各段階で生み出す情報 (Issue 本文、実装計画、進捗、PR 本文、コミットメッセージ) をどこに書くかは、documentation スキルの置き場マップ ([placement_map.md](../documentation/references/placement_map.md)) に従う。

大きな設計については、前述の「設計が必要な場合の流れ」に従い、Design Doc のレビューを実装より先に行う。Design Doc から将来を縛る決定を ADR に切り出し、実装・ADR・docs・CHANGELOG の変更を 1 つの PR にまとめてレビューに出す。

docs の 4 分類 (tutorial / how-to / reference / explanation) から ADR・Design Doc・Issue・PR へのリンクは張らない。docs は外部に公開する場合があるためである。この制約の詳細は documentation スキルの [diataxis.md](../documentation/references/diataxis.md) を参照する。

あわせて、Issue、PR、コメントの文章は writing-rules スキルに従って書く。

## 参照文書

development-flow が直接担う段階の手順は、次の文書に定める。

- [references/sync_main.md](./references/sync_main.md): default branch を origin と同期し、worktree の配置規則を定める。
- [references/create_branch.md](./references/create_branch.md): 作業ブランチと worktree を作成する。
- [references/merge_and_cleanup.md](./references/merge_and_cleanup.md): マージの依頼と後処理 (remote branch / worktree / local branch の削除と default branch の同期) を行う。

## スクリプト

- [scripts/create_worktree.sh](./scripts/create_worktree.sh): `bash .claude/skills/development-flow/scripts/create_worktree.sh <branch-name>` で、作業ブランチと worktree を命名規則どおりに作成・再利用する。
- [scripts/cleanup.sh](./scripts/cleanup.sh): `bash .claude/skills/development-flow/scripts/cleanup.sh <PR番号> [--yes]` で、マージ後の後処理 (remote branch 削除 → worktree 削除 → local branch 削除 → default branch 同期) を順に実行する。
- [scripts/add_progress_comment.sh](./scripts/add_progress_comment.sh): `bash .claude/skills/development-flow/scripts/add_progress_comment.sh <issue番号> <body_file>` で、Issue に進捗コメントを投稿する。状態が変化するたびに呼ぶ。