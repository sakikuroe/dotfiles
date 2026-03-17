# `main` へのマージと後処理

## 概要

マージ可能条件を確認し, ユーザーへ最終マージを依頼します.
マージ前に `origin/main` への追従を行い, マージ後は Issue, worktree, branch の後処理を行って次の作業に入れる状態に戻します.
PR がすでに merge 済みの場合は後処理だけを実行します.

## 手順

- 制御用 worktree で実行していることを確認します.
    - `main` branch にいること, 無関係な未コミット差分がないこと.
- Issue の `進捗` から branch 名と PR を確認します.
    - `ブランチ` と `PR` が空の場合は中断します.
    - worktree path は Step 01 の配置規則に従います.
- PR の状態を確認し, 分岐します.
    - `MERGED` の場合 → 後処理へ進みます.
    - `CLOSED` かつ未 merge の場合 → 中断し, 継続 / abandon をユーザーに確認します.
    - `OPEN` の場合 → 以降の手順へ進みます.
- 作業用 worktree で `origin/main` に追従します.
    - worktree が存在しない場合は Step 03 に戻ります.
    - `origin/main` に rebase します.
    - rebase で HEAD が変わった場合は `push --force-with-lease` し, Step 06 に戻って checks / review を再確認します.
- マージ可否を判定します.
    - Issue の `完了条件` がすべて達成済みであること.
    - PR が open, draft でない, レビュー承認済み, checks 通過, 競合なし.
    - 条件を満たさない場合は Step 06 または Step 07 に戻ります.
- マージ方法を決めます.
    - merge queue を使わない場合:
        - Issue の `進捗` を `マージ待ち` に更新します.
        - ユーザーへマージを依頼します (テンプレートは下記参照).
        - ユーザーが GitHub Web でマージします. AI Agent が代行する場合は認証後に `gh pr merge` を実行します.
    - merge queue を使う場合:
        - Issue の `進捗` を `merge queue 待ち` に更新します.
        - ユーザーへ queue 投入を依頼します. AI Agent が代行する場合は認証後に `gh pr merge --auto` を実行します.
        - Step 06 へ戻り, `MERGED` になるまで待ちます.
- マージ後の確認と後処理を行います.
    - PR が `MERGED` であることを確認します.
    - Issue のクローズ状態を確認します (`Closes` による自動クローズ, または手動).
    - Issue の `進捗` を `完了` に更新します.
    - remote branch を削除します (GitHub Web の `Delete branch` で削除済みなら不要).
    - 作業用 worktree を削除します (未コミット差分がないことを確認してから).
    - local branch を削除します.
    - 制御用 worktree の `main` を `origin/main` に同期します.
- 最終結果をユーザーへ要約します.

### 後処理の順序

後処理は以下の順で行います. worktree を先に削除しないと local branch の削除が失敗します.

1. remote branch の削除.
2. worktree の削除.
3. local branch の削除.
4. `main` の同期.

### local branch 削除の注意

`Squash and merge` や `Rebase and merge` を使うと, local の作業 branch が `main` の祖先にならず `git branch -d` が失敗することがあります.
PR が `MERGED` で変更が取り込まれていれば問題ないので, 必要なら `git branch -D` を使います.

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

- 後処理 (worktree 削除, branch 削除) は merge 確定後にのみ行います.
- `--force` は使わず, 必要時は `--force-with-lease` のみ使います.
- 判断に迷う場合は作業を中断し, ユーザーに報告, 相談します.

## この phase の完了条件

- [ ] 対象変更が `main` に取り込まれている.
- [ ] Issue の `進捗` が `完了` に更新されている.
- [ ] 作業用 worktree と branch が削除されている.
- [ ] 制御用 worktree の `main` が同期されている.
