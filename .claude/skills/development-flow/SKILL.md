---
name: development-flow
description: GitHub Issue を起点とする AI 主導の開発フローを定義するスキルである。開発タスクに着手するとき、Issue を作成するとき、または Issue から PR およびマージまでの手続きを進めるときには、必ずこのフローに従う。ユーザーが「実装して」「直して」「ブランチを作って」「PRを出して」のように、Issue に明示的に言及することなく開発を依頼した場合も、例外なくこのフローに従う。
---

## 概要

GitHub Issue を要求の起点とし、AI Agent が実装、検証、git や gh コマンドの操作を担う開発フローである。最初にクローンしたディレクトリを制御用 worktree (default branch に固定) とし、実際の作業はリポジトリ直下の `.worktrees/` ディレクトリ内に作成した作業用 worktree で行う。このフローの対象範囲は、1 つの Issue に対する着手の準備からマージの完了までである。

本スキルは開発全体のフローを統括し、ワークスペースの準備 (default branch の同期や作業ブランチ・worktree の作成) と、マージおよびその後処理を直接担う。途中の各プロセス (Issue の起票、実装、PR の作成、レビュー対応など) はそれぞれ独立したスキルとして定義されており、単独での利用も可能である。しかし、1 つの Issue を着手からマージまで一貫して進める場合は、本スキルが規定する順序と引き継ぎルールに従って各スキルを呼び出す。

本フローの目的は、本スキルを起点として各スキルを順番に呼び出すだけで Issue 駆動開発を一巡させ、ユーザーの判断が不可欠な箇所でのみ処理を一時停止させることである。そのため AI Agent は、後述する「承認ポイント」や各スキルで定められた合意・相談の場面を除き、都度ユーザーに確認を行うことなく次の段階へと進む。

## 前提

デフォルトブランチ (通常は `main`) を持つ GitHub リポジトリを対象とする。作業にあたっては default branch に直接 push せず、必ず作業ブランチと PR を経由するものとする。初回着手時には `gh auth status` で認証状態を確認するとともに、リポジトリの保護ルール (必須承認数、status checks、merge queue の有無など) を把握しておく。単独での開発において他者の承認が必須となる保護ルールが設定されている場合、フローを最後まで進めてもマージできない。そのため、あらかじめ別のアカウントを用意するか、保護ルールの調整を行っておく必要がある。

## 手順

フローは「準備」「設計 (該当する場合)」「実装から PR 作成」「マージと後処理」の 4 つのフェーズに分けて進める。各段階の詳細な手順は参照先のスキルや文書に委ね、ここでは全体の進行順序のみを規定する。

最初に準備として、default branch を origin と同期する ([references/sync_main.md](./references/sync_main.md))。続いて、ユーザーの要望をもとに Issue を起票し、実装方針についての承認を得る ([issue-planning](../issue-planning/SKILL.md))。

### 設計が必要な場合の流れ

実装方針を検討する際、「複数の実装方法があり、判断を誤った際の手戻りが大きい」「他のメンバーやシステムへ影響を及ぼす」といった条件に複数あてはまる場合は、実装に着手する前に Design Doc を作成する。Design Doc が必要かどうかの判断基準は、documentation スキルの [design_doc.md](../documentation/references/design_doc.md) に従う。

Design Doc を作成する場合の流れは以下の通りである。まず Issue に紐付く作業ブランチと worktree を作成し ([references/create_branch.md](./references/create_branch.md))、作業用 worktree 上で Design Doc を執筆してドラフト PR として提出する。PR 上で設計に対するレビューを受け、合意が得られたらステータスを Approved に変更して push する。この時点で、将来的な制約となる決定事項を ADR として切り出し、Design Doc と ADR を相互にリンクさせる。その後、同じブランチのまま実装へと進む。

Design Doc が不要な場合は、方針の承認を得たあとに、Issue に紐付く作業ブランチと worktree を作成する ([references/create_branch.md](./references/create_branch.md))。ブランチを作成するタイミングを方針承認の後にしているのは、方針が変わることで変更の種別や内容が変わり、結果としてブランチ名も変わる可能性があるためである。

### 実装から PR

作業用 worktree 上で実装、検証、コミットを行う ([implementation](../implementation/SKILL.md))。実装の過程で、将来的な制約となるような決定 (技術選定、データモデルの構造、全員が従うべきルールなど) を行った場合は、ステータスを Proposed に設定した ADR を作成し、同じブランチに含める。

ユーザーから見える挙動に変更がある場合は、同じ PR の中で恒常系のドキュメントもあわせて更新する。具体的には、docs (reference や how-to など) への反映と、CHANGELOG の Unreleased セクションへの追記を実装と同じ PR に含める。ドキュメントの更新を別の PR に分けると忘れられやすいため、同一の PR にまとめることを作業の完了条件とする。

実装が完了したら、Design Doc がある場合は PR のドラフト状態を解除する (すでに Design Doc 作成時にドラフト PR が作られているため)。Design Doc がない場合は、新たに PR を作成する ([pr-creation](../pr-creation/SKILL.md))。その後、実装、ADR、ドキュメントの変更をすべてまとめてレビューに出す。

PR を作成したあとは、レビューや CI の結果に応じて、指摘事項への対応と再レビューの依頼を繰り返す ([review-response](../review-response/SKILL.md))。

### マージと後処理

PR が Approve されたら、ADR のステータスを Accepted に、Design Doc のステータスを Implemented にそれぞれ変更して push する (作成したもののみを対象とする)。マージ可能な条件がすべて揃ったことを確認したうえでユーザーに最終マージを依頼し、マージ後には worktree とブランチの後処理を行って、すぐに次の作業に取りかかれる状態に戻す ([references/merge_and_cleanup.md](./references/merge_and_cleanup.md))。

## 段階間の引き継ぎ

各スキルはそれぞれ単独でも利用できるように、対象の Issue や作業ブランチ、実装計画の有無、検証方法などをユーザーに確認する手順が組み込まれている。しかし、本フローの中で各スキルを呼び出す際、前の段階ですでに確定している情報を再度ユーザーに質問してしまうと、フローが不必要に停止してしまう。そのため、本フロー内では確定済みの情報をユーザーに聞き直すことはせず、そのまま次のスキルへ引き継ぐものとする。たとえば、implementation が用いる実装計画には issue-planning で承認済みの計画を利用し、review-response が用いる対応 Issue には本フローで扱っている Issue をそのまま引き継ぐ。検証方法のように、本フロー内でまだ確定していない情報が必要になった場合にのみ、その場でユーザーに確認をとる。

段階をまたいで引き継がれるステータスは、すべて Issue の進捗コメントとして集約される。各スキルは状態に変化があるたびに進捗コメント (ブランチ名・PR・状態など) を投稿する。そのため、中断した作業を再開する際には、Issue のコメント履歴と `git worktree list` や `gh pr view` による現在の状況からいまどのフェーズにいるかを判断し、適切な段階から作業を再開する。

## 承認ポイント

GitHub 上で外部から見える成果物を作成する操作や、取り消しが難しい操作については、必ずユーザーの承認を得てから実行する。具体的には以下の操作が該当し (括弧内は担当するスキル)、各段階のスキルにおいてもこのルールに従う。

- `gh issue create` による Issue の作成 (issue-planning)
- `gh pr create` による PR の作成 (pr-creation)
- PR の draft から ready への切り替え (pr-creation)
- レビュー依頼の追加・再設定 (pr-creation)
- `gh pr merge` によるマージ、および merge queue への投入 (development-flow)
- リモートブランチの削除を含むマージ後の後処理 (development-flow)

上記以外の操作 (コミット、push、Issue への進捗コメント、PR やレビューへの返信など) は、ユーザーの承認を待たずに進めてよい。なお、ここで規定した「操作に対する承認」とは別に、各スキルの中では実装方針の合意、PR 本文の草案の承認、レビューでの指摘事項をどう扱うかといった「内容についての合意」を行う手順が定められているため、それらについては各スキルの手順に従う。また、承認を求めるポイントを最小限に絞ってはいるものの、判断に迷う場合や想定外の事態に遭遇した場合は、どの段階であっても速やかに作業を中断し、ユーザーへ報告・相談を行う。

## 役割

AI Agent は、Issue の草案作成、実装と検証、git や gh コマンドの操作、およびレビューでの指摘に対する返答を担当する。ユーザーは、各種承認ポイントでの確認と許可、GitHub の認証、GitHub Web 上でのレビュー、そして最終的なマージ可否の判断を担当する。

## 状態値

作業が進行中である場合は「〜中」、外部からの応答を待っている状態は「〜待ち」として表す。各状態は、括弧内に記載されたスキルが進捗コメントとして記録する。

- `方針レビュー待ち` — 実装方針のコメントを投稿し、ユーザーからの承認を待っている (issue-planning)。
- `設計レビュー待ち` — Design Doc のドラフト PR を提出し、設計に関するレビューを待っている (development-flow)。
- `実装中` — 実装および検証を進めている (implementation)。
- `ドラフトレビュー中` — draft PR を用いて相談や途中段階でのレビューを受けている (pr-creation / review-response)。
- `レビュー待ち` — ready PR として正式なレビューを待っている (pr-creation / review-response)。
- `指摘対応中` — レビューでの指摘事項や CI の不具合に対応している (review-response)。
- `再レビュー待ち` — 指摘された修正を反映し、再レビューを待っている (review-response)。
- `マージ待ち` — ユーザーへ最終確認とマージを依頼済みである (development-flow)。
- `merge queue 待ち` — merge queue に投入済みである (development-flow)。
- `完了` — マージと後処理の完了が確認できている (development-flow)。

## ドキュメントとの連携

フローの各段階で生成される情報 (Issue の本文、実装計画、進捗状況、PR の本文、コミットメッセージなど) の記載場所については、documentation スキルの置き場マップ ([placement_map.md](../documentation/references/placement_map.md)) に従う。

大規模な設計においては、前述の「設計が必要な場合の流れ」に従い、実装に着手する前に Design Doc のレビューを済ませる。さらに、Design Doc から将来的な制約事項となる決定を ADR として切り出し、実装・ADR・docs・CHANGELOG に対する変更をすべて 1 つの PR にまとめてレビューに出す。

docs の 4 つの分類 (tutorial / how-to / reference / explanation) からは、ADR・Design Doc・Issue・PR へリンクを貼らないこと。これは、docs が外部へと公開される可能性があるためである。本制約の詳細については、documentation スキルの [diataxis.md](../documentation/references/diataxis.md) を参照すること。

また、Issue、PR、各コメントの文章は、すべて writing-rules スキルに従って執筆する。

## 参照文書

development-flow が直接担当する手順は、以下の文書に規定する。

- [references/sync_main.md](./references/sync_main.md): default branch を origin と同期し、worktree の配置ルールを定める。
- [references/create_branch.md](./references/create_branch.md): 作業ブランチと worktree を作成する。
- [references/merge_and_cleanup.md](./references/merge_and_cleanup.md): マージの依頼と後処理 (remote branch / worktree / local branch の削除と default branch の同期) を行う。

## スクリプト

- [scripts/create_worktree.sh](./scripts/create_worktree.sh): `bash .claude/skills/development-flow/scripts/create_worktree.sh <branch-name>` を実行し、作業ブランチと worktree を命名規則に従って作成するか、あるいは再利用する。
- [scripts/cleanup.sh](./scripts/cleanup.sh): `bash .claude/skills/development-flow/scripts/cleanup.sh <PR番号> [--yes]` を実行し、マージ後の後処理 (remote branch 削除 → worktree 削除 → local branch 削除 → default branch 同期) を順次進める。
- [scripts/add_progress_comment.sh](./scripts/add_progress_comment.sh): `bash .claude/skills/development-flow/scripts/add_progress_comment.sh <issue番号> <body_file>` を実行し、Issue に進捗コメントを投稿する。状態の変化があるたびに呼び出す。```