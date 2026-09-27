---
name: issue-planning
description: GitHub Issue を起票するためのスキル。ユーザーの要望をもとに Issue を作成する場面や、単独で Issue を起票する場面で使用する。
---

## 概要

ユーザーの要望をもとに GitHub Issue を作成する。Issue はその後のすべての工程の基準となるため、要望と完了条件を過不足なく記述すること。特に、ユーザーが明示していない要件やスコープを想像で補うのは厳禁である。草案を作成する前に、必ずユーザーと完了条件について合意すること。

## 手順

まず、ユーザーから「やりたいこと」または「発生している問題」を聞き取り、Issue の種別 (`機能追加・機能改善` / `バグ修正`) を判断する。入力内容から種別が明らかな場合は AI Agent が判断して構わないが、迷う場合はユーザーに確認すること。

草案を作成する前に、必要な情報をユーザーに確認する。完了条件はもちろん、背景・制約・スコープに不明点があれば併せて確認しておくこと。また、既存の Issue や PR と重複する可能性がある場合は検索して確認し、内容が 1 つの Issue に収まらない規模であれば分割案を提示すること。

確認が済んだら、ユーザーの回答をもとに草案を作り、タイトル案と本文案をあわせてユーザーに提示する。本文案は `/tmp` 配下にマークダウン形式で作成し、その中身をユーザーに提示すること。本文は種別ごとのテンプレートをベースに作成し、必要に応じて節を追加する。ただし、記述してよいのはユーザーから確認できた情報のみである。

提示した草案について、ユーザーの承認を得るまで修正と再提示を繰り返す。承認されたら、`bash .claude/skills/issue-planning/scripts/create_issue.sh` を実行して Issue を作成する。

コマンド例:

```bash
cat <<'EOF' > /tmp/issue_body.md
## 提案する機能の概要

...

## 何をもって完了とするか

- [ ]
EOF

bash .claude/skills/issue-planning/scripts/create_issue.sh "<タイトル>" /tmp/issue_body.md
```

作成後は、出力結果 (URL、番号、本文) が意図した通りになっているか確認する。なお、Issue 作成後に本文を更新する場合は、`bash .claude/skills/issue-planning/scripts/update_issue_body.sh <issue番号> <body_file>` を使用すること。

## 記述上のルール

Issue は、要望や完了条件を第三者が見ても理解できる内容にすること。そのため、タイトルおよび本文は日本語で記述し、本文の構成は `writing-rules` スキルの `prose_structure.md` に従うこと。また、関係者の合意なしに Issue のスコープを広げてはならない。判断に迷った場合は作業を中断し、ユーザーに相談すること。

## 何をもって完了とするか

- [ ] Issue が GitHub 上に作成されている。

## テンプレート

- [bug.md](./references/templates/bug.md): バグ修正 Issue の本文テンプレート
- [feature.md](./references/templates/feature.md): 機能追加・機能改善 Issue の本文テンプレート

## スクリプト

- [create_issue.sh](./scripts/create_issue.sh): `bash .claude/skills/issue-planning/scripts/create_issue.sh <タイトル> <body_file>` で Issue を作成する。
- [update_issue_body.sh](./scripts/update_issue_body.sh): `bash .claude/skills/issue-planning/scripts/update_issue_body.sh <issue番号> <body_file>` で Issue 本文を指定したファイルの内容で置き換える。完了条件や背景・動機など、description 内の節を書き換える際に使用する。