---
name: pr-creation
description: push と PR 作成を担うスキルである。作業ブランチを push し、PR を作成するときに使用する。単独で PR を作成する場面でも使用する。
---

## 概要

作業ブランチを origin へ push し、PR を作成する段階である。同じブランチに対して PR が乱立しないよう、既存の open PR がある場合は新規作成せず再利用する。新規に作成する場合、PR はまず draft として作り、内容に問題がないと判断できたらユーザーの確認を経て ready に切り替える。作成直後に一度立ち止まって見直す余地を確保し、未完成の PR にレビューが飛んでしまうことを防ぐためである。本文はテンプレートに基づいて作成し、作成スクリプトが署名を自動付加する。

この段階を通じて守るべき姿勢がひとつある。PR 先のブランチやレビュー依頼先など、GitHub の PR 作成において可変でありかつ文脈から明らかでない要素は、推測で決めずに必ずユーザーに確認する。判断に迷った場合も同様で、作業を中断してユーザーに報告・相談する。

## 手順

### 事前確認

まず、現在いるブランチから対応する Issue を特定する。特定できたら、その Issue、作業ブランチ、PR 先のブランチをユーザーに提示して認識が合っているかを確認する。PR 先のブランチは default branch であることが多いが、そうとは限らないため、ここで必ず確認しておく。

作業ツリーやコミット履歴に意図しない差分がある場合は、勝手に処理せず、コミット・破棄・退避のいずれをどのように行うかをユーザーに相談する。差分の扱いを誤ると作業内容を失いかねないためである。

### Push と既存 PR の確認

差分の整理が済んだら、作業ブランチを origin へ push する。PR はリモートのブランチに対して作られるため、push が済んでいなければ以降の手順に進めない。履歴を書き換えた後などで強制 push が必要な場合は、`--force` ではなく `--force-with-lease` を使う。リモートに自分の知らないコミットが積まれていたときに、それを気づかず上書きしてしまう事故を防ぐためである。

push が済んだら、`gh pr list --head "$HEAD_BRANCH" --state all` で当該ブランチの既存 PR を確認する。open な PR が見つかった場合はそれを再利用し、見つからなかった場合は新規作成に進む。

### 草案の作成と承認

草案を書き始める前に、本文に必要な情報をユーザーに確認する。とくに完了条件（動作を確認する手順の前提となる、この変更が満たすべき条件）は必ず確認し、そのほかにも不明な点があればあわせて聞いておく。本文に記述してよいのはユーザーから確認できた情報のみであり、推測で埋めてはならない。誤った内容がレビューの前提になってしまうためである。

確認が済んだら、回答をもとにタイトル案と本文案を作成する。本文は [pr.md](./references/templates/pr.md) の構成に従い、`/tmp` 配下にマークダウンファイルとして書き出したうえで、その中身をユーザーに見せる。ファイルとして書き出すのは、後述の作成スクリプトにそのまま渡せる形で、提示した内容と実際に登録される内容を一致させるためである。

```bash
cat <<'EOF' > /tmp/pr_body.md
## 本 PR に対応する Issue

Closes #<issue番号>

## 本 PR で行った変更の概要

...

## 動作を確認する手順

...
EOF
```

タイトル案と本文案を提示し、ユーザーの承認が得られるまで、指摘を反映して修正と再提示を繰り返す。

### PR の作成

承認を得たら、次のスクリプトで PR を作成する。このスクリプトは PR を必ず draft として作成する。

```bash
bash .claude/skills/pr-creation/scripts/create_pr.sh "<タイトル>" /tmp/pr_body.md <head_branch> [base_branch]
```

`base_branch` には事前確認でユーザーと合意した PR 先のブランチを渡す。省略した場合は origin の default branch が使われるが、確認した結果が default branch であっても、認識のずれを残さないよう明示的に渡すことを推奨する。

既存の open PR を再利用する場合は、新規作成ではなく、承認済みのタイトルと本文でその PR を更新する。このとき draft / ready の状態は勝手に変更しない。

### Ready への切り替え

PR を draft として作成したら、差分と本文を改めて見直す。CI の状況や記載漏れも含めて問題がないと判断できたら、「ready に切り替えてよいか」をユーザーに確認し、承認を得てから次のスクリプトで切り替える。

```bash
bash .claude/skills/pr-creation/scripts/set_ready.sh <PR番号>
```

自分の見直しで問題が見つかった場合や、ユーザーが draft のまま置くことを望んだ場合は、切り替えずに draft のまま次へ進む。

### レビュー依頼と進捗の記録

ready に切り替えた場合は、「レビューを依頼するユーザーがいれば GitHub ユーザー名を教えてください」とユーザーに尋ねる。指定があれば `bash .claude/skills/pr-creation/scripts/add_reviewer.sh <PR番号> <username>` でレビュアーを追加し、不要との回答であればこのステップはスキップする。

最後に、PR の URL と状態を進捗コメントとして対応 Issue に記録する。コメント本文をファイルに書き出し、`bash .claude/skills/pr-creation/scripts/add_progress_comment.sh <issue番号> <body_file>` で投稿する。状態は ready に切り替えた場合は「レビュー待ち」、draft のままの場合は「ドラフトレビュー中」とする。

## 原則

PR のタイトルおよび本文は日本語で書く。本文の文章は `writing-rules` スキルの `prose_structure.md` に従う。

## この段階の完了条件

- [ ] 作業ブランチが origin に push 済みである。
- [ ] PR が、ユーザーに確認した PR 先ブランチ向けに draft として作成または再利用されている。
- [ ] ready への切り替えについてユーザーに確認し、承認された場合は切り替えが済んでいる。
- [ ] PR の URL と状態が進捗コメントとして対応 Issue に記録されている。

## テンプレート

- [pr.md](./references/templates/pr.md): PR 本文のテンプレート

## スクリプト

- [create_pr.sh](./scripts/create_pr.sh): `bash .claude/skills/pr-creation/scripts/create_pr.sh <タイトル> <body_file> <head_branch> [base_branch]` で、本文末尾に署名を自動付加して PR を draft として作成する。`base_branch` を省略した場合は origin の default branch を使う。
- [set_ready.sh](./scripts/set_ready.sh): `bash .claude/skills/pr-creation/scripts/set_ready.sh <PR番号>` で draft PR を ready に切り替える。切り替え前に必ずユーザーの承認を得ること。
- [add_reviewer.sh](./scripts/add_reviewer.sh): `bash .claude/skills/pr-creation/scripts/add_reviewer.sh <PR番号> <username>` でレビュー依頼を追加する。
- [add_progress_comment.sh](./scripts/add_progress_comment.sh): `bash .claude/skills/pr-creation/scripts/add_progress_comment.sh <issue番号> <body_file>` で Issue に進捗コメントを投稿する。PR 作成時に PR URL と状態を記録するために使う。