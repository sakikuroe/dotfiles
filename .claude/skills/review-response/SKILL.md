---
name: review-response
description: レビュー対応を担うスキルである。PR の状態を確認し、レビュー指摘や CI 不具合に対応するときに使用する。単独で PR のレビュー対応を行う場面でも使用する。
---

# レビュー指摘への対応

## 概要

レビュー指摘や PR コメントについて、ユーザーと採否を合意したうえで 1 件ずつ修正する。push と返答を繰り返すことで、PR を再レビュー可能な状態に戻す。

## 手順

まず、対応する Issue をユーザーに尋ね、その Issue のコメント履歴から branch 名と PR を確認して、対象 branch を特定する。特定できたら、`bash .claude/skills/review-response/scripts/add_progress_comment.sh <issue番号> <body_file>` で進捗コメントを投稿し、状態を「指摘対応中」に記録する。

ここからは、未対応の指摘がなくなるまで、指摘 1 件ずつ「修正 → コミット → push → 返答」のサイクルを繰り返す。

### 指摘の取得と対象コードの特定

サイクルの各回では、まず未対応の指摘を取得し、対象コードを特定する。GitHub 上の指摘は `bash .claude/skills/review-response/scripts/fetch_reviews.sh <PR番号>` で全体レビュー・インラインコメント・通常の PR コメントを一括取得でき、CI の結果は出力中の `checks` で確認できる。対象コードは `path`、`original_commit_id`、`original_line`、`original_start_line` から特定すること。`diff_hunk` や現在の行番号から推測してはならない。修正に入る前に `git show <original_commit_id>:<path> | nl -ba` でコメント時点のコードを確認し、コメント本文、パス、commit、行番号、対象コードの抜粋をセットで整理しておく。

### 採否の確定と修正・コミット

続いて、修正方針をユーザーへ提示し、採否を確定する。選択肢は、採用、非採用、別 Issue へ送る、要件変更として issue-planning スキルに戻す、の 4 つである。

採用となった場合は、修正して検証したうえで、コミットして push する。コミットは `git-committer` サブエージェントに委譲し、その指摘への修正だけを 1 コミットにまとめるよう伝えること。返ってきたコミットハッシュは、後段のインライン返答で使用する。

### 指摘への返答

修正を push したら、該当する review thread または PR コメントへ返答する。採用した場合は、何をどう直したかを返答する。非採用・別 Issue・要件変更の場合は、採用しなかったことやその理由を伝え、必要に応じて今後の方針を尋ねたり、疑問点を質問したりする。

レビュー全体への返答には `bash .claude/skills/review-response/scripts/reply_review.sh <PR番号> <review_node_id> <body_file> <commit_hash|->` を使う。インラインの返答には `bash .claude/skills/review-response/scripts/reply_inline.sh <PR番号> <comment_id> <body_file> <commit_hash|->` を使う。通常の PR コメントへの返答には `bash .claude/skills/review-response/scripts/reply_comment.sh <PR番号> <comment_id> <body_file> <commit_hash|->` を使う。いずれも `<commit_hash>` には必ずその指摘に対応したコミットを指定すること。コミット URL が不要な場合は `-` を渡す。

返答まで終えたら次の未対応の指摘に移り、同じサイクルを繰り返す。

### 指摘・コミット・返答の 1 対 1 対応

このサイクルでは、指摘 1 件ごとに修正・コミット・返答を完結させること。複数の指摘をまとめて 1 コミットにすること、コミットだけを連続して行い返答を後からまとめて行うこと、1 つの指摘に対して複数のコミットを作ることは、いずれも禁止する。これらのルールは、レビュアーが指摘事項と修正差分を対応づけられるようにするためのものである。

やむを得ず 1 つのコミットで複数の指摘をまとめて修正した場合は、2 件目以降の返答では `reply_inline.sh` にコミットハッシュを渡さず (`-` を指定し)、先の返答で示したコミットで修正済みであることを本文で伝えること。たとえば、次のように書く。

```md
本指摘は、コメント (https://github.com/.../pull/123#discussion_r456) への返答で示したコミット `abc1234` にて、あわせて修正しています。
```

### 進捗の記録と再レビュー待ち

すべての指摘への対応が済んだら、`bash .claude/skills/review-response/scripts/add_progress_comment.sh <issue番号> <body_file>` で進捗コメントを投稿し、状態を記録する。状態は、ready な PR の再レビューを待つ場合は「再レビュー待ち」、draft のまま継続する場合は「ドラフトレビュー中」とする。

その後は再レビューを待ち、新たな指摘が届いたら、手順の最初に戻って同じサイクルを繰り返す。

## 全般ルール


スクリプトの実行やコマンド操作が失敗したときは、勝手に次の手順へ進んだり、原因を推測して試行錯誤を重ねたりしてはならない。失敗した事実とその内容をユーザーに報告し、方針を尋ねること。失敗時に限らず、採否や対応方法の判断に迷う場合も同様に、作業を中断してユーザーに報告・相談すること。

レビューへの返答の文章は、`writing-rules` スキルの `prose_structure.md` に従って記述すること。また、review thread の resolve はレビュアーが行うものであり、返答や修正を終えた場合であっても、AI Agent が resolve を行ってはならない。

## 何をもって完了とするか

- [ ] 指摘への修正が完了している。
- [ ] 未対応の指摘への返答が残っていない。

## スクリプト

- [fetch_reviews.sh](./scripts/fetch_reviews.sh): `bash .claude/skills/review-response/scripts/fetch_reviews.sh <PR番号>` で、PR 状態 / 全体レビュー / インライン review comment / 通常の PR コメントを 1 回で取得し JSON で返す。
- [reply_review.sh](./scripts/reply_review.sh): `bash .claude/skills/review-response/scripts/reply_review.sh <PR番号> <review_node_id> <body_file> <commit_hash|->` で、レビュー全体へ引用付きで返答する。
- [reply_inline.sh](./scripts/reply_inline.sh): `bash .claude/skills/review-response/scripts/reply_inline.sh <PR番号> <comment_id> <body_file> <commit_hash|->` で、インライン review comment に返答する。
- [reply_comment.sh](./scripts/reply_comment.sh): `bash .claude/skills/review-response/scripts/reply_comment.sh <PR番号> <comment_id> <body_file> <commit_hash|->` で、通常の PR コメントへ引用付きで返答する。
- [add_progress_comment.sh](./scripts/add_progress_comment.sh): `bash .claude/skills/review-response/scripts/add_progress_comment.sh <issue番号> <body_file>` で Issue に進捗コメントを投稿する。状態変化のたびに使う。

## 連携サブエージェント

- git-committer: コミットを担う。作業ディレクトリとコミットの単位・意図を伝えて委譲する。