# Push と PR の作成

## 概要

作業用 worktree のブランチを origin へ push し, `main` 向けの PR を作成する.
初回 push 前には `origin/main` を基点に履歴を整形する.
既存の open PR がある場合は再利用する.

## 手順

- 作業用 worktree で対象 branch にいることを確認する.
    - 実行場所: push と履歴整形は作業用 worktree で行うこと.
    - コマンド例:
        ```bash
        # 実行場所: 作業用 worktree
        cd ~/.worktrees/<repo>-<branch>
        git fetch origin --prune
        git status   # 未コミット差分がないことを確認
        ```
- `origin/main` の存在を確認する.
- 未コミット差分がないことを確認する.
    - 意図しない差分がある場合は, コミット / 破棄 / 退避の方針を決めてから進むこと.
- push 方法を決める.
    - remote に branch が未公開の場合 → 公開前に履歴を整形してから push する.
        - `git rebase origin/main` → `git reset --soft origin/main` → 適切な粒度で commit を作り直す.
    - 公開済みの場合 → 通常 push する.
    - コマンド例:
        ```bash
        # 実行場所: 作業用 worktree
        git push -u origin <branch>           # 初回 (upstream を設定)
        # または
        git push                              # 2 回目以降
        git push --force-with-lease           # 履歴整形した場合
        ```
- PR を決定する.
    - `gh pr list --head "$HEAD_BRANCH" --state all` で既存 PR を確認し, open PR があれば再利用する.
    - Issue の完了条件がすべて満たされていれば ready PR, そうでなければ draft PR とする.
    - ready PR は `Closes #<issue番号>`, draft PR は `Refs #<issue番号>` を使う.
- PR の内容をユーザーへ提示し, 認証を得る.
    - PR タイトル, 本文, draft / ready の別を提示する.
- ユーザーの認証後に PR を作成または更新する.
    - 実行場所: メインリポジトリー. `gh pr create` はカレントブランチから PR を作るため, worktree から実行すると別 Bash セッションで cwd がリセットされて main から作ろうとしてエラーになる事故が起きやすい. メインリポジトリーから `--head <branch>` で明示するのが安全.
    - 本文はヒアドキュメントで一時ファイルに書き出してから `--body-file` で渡すこと. シェル内で本文に含まれるバッククォートをエスケープする事故を防ぐため.
    - タイトルにバッククォートを含む場合, `--title "..."` とダブルクォートで渡すとシェルがコマンド置換として解釈し壊れる. 変数経由かシングルクォートで渡すこと.
    - コマンド例:
        ```bash
        # 実行場所: メインリポジトリー
        cat <<'EOF' > /tmp/pr_body.md
        ## 概要

        - ...

        ## 変更内容

        - ...

        ## 検証

        - ...

        ## 影響範囲 / リスク

        - ...

        ## 関連 Issue

        - Closes #<issue番号>

        *This comment was posted by AI Agent.*
        EOF

        gh pr create \
          --title "<タイトル>" \
          --body-file /tmp/pr_body.md \
          --head <branch> \
          --base main
        ```
- ready PR の場合, レビュー依頼先をユーザーに確認する.
    - 「レビューを依頼するユーザーがいれば GitHub ユーザー名を教えてください」と尋ねる.
    - ユーザーが指定した場合は `bash ${CLAUDE_SKILL_DIR}/scripts/add_reviewer.sh <PR番号> <username>` で依頼する.
        - 実行場所: メインリポジトリー (リポジトリー判定に `gh repo view` を使うため worktree 内でも可).
        - `gh pr edit` が `projectCards` の GraphQL エラーで失敗する場合は REST API を使う.
          例: `gh api repos/<owner>/<repo>/pulls/<number> --method PATCH --field title='...' --jq '.title'`
    - 不要と回答した場合はスキップする.
- Issue の `進捗` を更新する.
    - ready PR → `レビュー待ち`, draft PR → `ドラフトレビュー中`.
    - `ブランチ`, `PR`, `次` を更新する.

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

*This comment was posted by AI Agent.*
```

## 原則

- PR のタイトルおよび本文は日本語で書くこと.
- `--force` は使わず, 必要時は `--force-with-lease` のみ使うこと.
- ユーザーの認証を得ずに PR を作成しないこと.
- 判断に迷う場合は作業を中断し, ユーザーに報告・相談すること.

## この phase の完了条件

- [ ] 作業ブランチが origin に push 済みである.
- [ ] PR が `main` 向けに作成または再利用されている.
- [ ] Issue の `進捗` が PR 状態に一致している.
- [ ] Step 06 を開始できる状態になっている.
