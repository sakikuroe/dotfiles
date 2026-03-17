# Push と PR の作成

## 概要

作業用 worktree のブランチを origin へ push し, `main` 向けの PR を作成します.
初回 push 前には `origin/main` を基点に履歴を整形します.
既存の open PR がある場合は再利用します.

## 手順

- 作業用 worktree で対象 branch にいることを確認します.
- `git fetch origin --prune` でリモートを最新化し, `origin/main` の存在を確認します.
- 未コミット差分がないことを確認します.
    - 意図しない差分がある場合は, コミット / 破棄 / 退避の方針を決めてから進みます.
- push 方法を決めます.
    - remote に branch が未公開の場合 → 公開前に履歴を整形してから push します.
        - `git rebase origin/main` → `git reset --soft origin/main` → 適切な粒度で commit を作り直します.
    - 公開済みの場合 → 通常 push します.
- PR を決定します.
    - `gh pr list --head "$HEAD_BRANCH" --state all` で既存 PR を確認し, open PR があれば再利用します.
    - Issue の完了条件がすべて満たされていれば ready PR, そうでなければ draft PR とします.
    - ready PR は `Closes #<issue番号>`, draft PR は `Refs #<issue番号>` を使います.
- PR の内容をユーザーへ提示し, 認証を得ます.
    - PR タイトル, 本文, draft / ready の別を提示します.
- ユーザーの認証後に PR を作成または更新します.
- Issue の `進捗` を更新します.
    - ready PR → `レビュー待ち`, draft PR → `ドラフトレビュー中`.
    - `ブランチ`, `PR`, `次` を更新します.

## PR 本文テンプレート

```markdown
## 概要
- <何を / なぜ>

## 変更内容
- <変更点>

## 検証
- <実行コマンド・確認結果>

## 影響範囲 / リスク
- <影響・リスク・ロールバック>

## 関連 Issue
- Closes #<issue番号>

*This comment was posted by AI Agent (model: <モデル名>).*
```

## 原則

- `--force` は使わず, 必要時は `--force-with-lease` のみ使います.
- ユーザー認証なしに PR を作成しません.
- 判断に迷う場合は作業を中断し, ユーザーに報告, 相談します.

## この phase の完了条件

- [ ] 作業ブランチが origin に push 済みである.
- [ ] PR が `main` 向けに作成または再利用されている.
- [ ] Issue の `進捗` が PR 状態に一致している.
- [ ] Step 06 を開始できる状態になっている.
