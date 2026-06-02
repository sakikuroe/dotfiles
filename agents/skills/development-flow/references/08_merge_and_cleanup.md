# `main` へのマージと後処理

## 概要

マージ可能条件を確認し, ユーザーへ最終マージを依頼する.
マージ前に `origin/main` への追従を行い, マージ後は Issue, worktree, branch の後処理を行って次の作業に入れる状態に戻す.
PR がすでに merge 済みの場合は後処理だけを実行する.

## 手順

- 制御用 worktree で実行していることを確認する.
    - `main` branch にいること, 無関係な未コミット差分がないこと.
- Issue のコメント履歴から branch 名と PR を確認する.
    - branch 名と PR が見つからない場合は中断すること.
    - worktree path は Step 01 の配置規則に従う.
- PR の状態を確認し, 分岐する.
    - `MERGED` の場合 → 後処理へ進む.
    - `CLOSED` かつ未 merge の場合 → 中断し, 継続 / abandon をユーザーに確認すること.
    - `OPEN` の場合 → 以降の手順へ進む.
- 作業用 worktree で `origin/main` に追従する.
    - worktree が存在しない場合は Step 03 に戻ること.
    - `origin/main` に rebase する.
    - rebase で HEAD が変わった場合は `push --force-with-lease` し, Step 06 に戻って checks / review を再確認すること.
- マージ可否を判定する.
    - Issue の `完了条件` がすべて達成済みであること.
    - PR が open, draft でない, レビュー承認済み, checks 通過, 競合なし.
    - 条件を満たさない場合は Step 06 または Step 07 に戻ること.
- マージ方法を決める.
    - merge queue を使わない場合:
        - 進捗コメントで状態を `マージ待ち` に記録する.
        - ユーザーへマージを依頼する (テンプレートは下記参照).
        - ユーザーが GitHub Web でマージする. AI Agent が代行する場合は認証後に `gh pr merge` を実行する.
    - merge queue を使う場合:
        - 進捗コメントで状態を `merge queue 待ち` に記録する.
        - ユーザーへ queue 投入を依頼する. AI Agent が代行する場合は認証後に `gh pr merge --auto` を実行する.
        - Step 06 へ戻り, `MERGED` になるまで待つ.
- マージ後の確認と後処理を行う.
    - PR が `MERGED` であることを確認する.
    - Issue のクローズ状態を確認する (`Closes` による自動クローズ, または手動).
    - 進捗コメントで状態を `完了` に記録する. `bash ${CLAUDE_SKILL_DIR}/scripts/add_progress_comment.sh <issue番号> <body_file>` を使う.
    - `bash ${CLAUDE_SKILL_DIR}/scripts/cleanup.sh <PR番号> [--yes]` で remote branch 削除 → worktree 削除 → local branch 削除 → main 同期を一括して行う.
        - 実行場所: メインリポジトリー. 削除対象の worktree 内から実行すると, 削除後にカレントディレクトリが消えてシェルが追従できなくなるため.
        - `--yes` を付けると remote branch 削除の確認プロンプトをスキップする. 非対話環境 (Claude Code など) ではこれを付けること.
        - コマンド例:
            ```bash
            # 実行場所: メインリポジトリー
            cd /path/to/main/repo
            bash ${CLAUDE_SKILL_DIR}/scripts/cleanup.sh 123 --yes
            ```
- 最終結果をユーザーへ要約する.

### 後処理の順序

後処理は以下の順で行うこと. worktree を先に削除しないと local branch の削除が失敗する.

1. remote branch の削除.
2. worktree の削除.
3. local branch の削除.
4. `main` の同期.

### local branch 削除の注意

`Squash and merge` や `Rebase and merge` を使うと, local の作業 branch が `main` の祖先にならず `git branch -d` が失敗することがある.
PR が `MERGED` で変更が取り込まれていれば問題ないので, 必要なら `git branch -D` を使うこと.

### マージ依頼テンプレート

```text
マージ準備が完了しました.

- PR: <PR URL>
- Issue: <Issue URL>
- 反映ブランチ: <head> -> <base>
- merge 方法: <Create a merge commit / Squash and merge / Rebase and merge>
- Issue 完了条件: すべて達成済み
- レビュー / checks / mergeable: 問題なし

GitHub Web で最終マージをお願いします.
```

### merge queue 投入依頼テンプレート

```text
merge queue への投入準備が完了しました.

- PR: <PR URL>
- Issue: <Issue URL>
- 反映ブランチ: <head> -> <base>
- Issue 完了条件: すべて達成済み
- レビュー / checks / mergeable: 問題なし

GitHub Web で `Add to merge queue` または `Merge when ready` をお願いします.
```

## 原則

- 後処理 (worktree 削除, branch 削除) は merge 確定後にのみ行うこと.
- `--force` は使わず, 必要時は `--force-with-lease` のみ使うこと.
- 判断に迷う場合は作業を中断し, ユーザーに報告・相談すること.

## この phase の完了条件

- [ ] 対象変更が `main` に取り込まれている.
- [ ] 進捗コメントで `完了` が記録されている.
- [ ] 作業用 worktree と branch が削除されている.
- [ ] 制御用 worktree の `main` が同期されている.
