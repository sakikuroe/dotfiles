# Push と PR の作成

## 概要

作業用 worktree のブランチを origin へ push し, `main` 向けの PR を作成します.
初回 push 前には `origin/main` を基点に履歴を整形します.
既存の open PR がある場合は再利用します.

## 手順

- 作業用 worktree で対象 branch にいることを確認します.
    - 実行場所: push と履歴整形は作業用 worktree で行います.
    - コマンド例:
        ```bash
        # 実行場所: 作業用 worktree
        cd ~/.worktrees/<repo>-<branch>
        git fetch origin --prune
        git status   # 未コミット差分がないことを確認
        ```
- `origin/main` の存在を確認します.
- 未コミット差分がないことを確認します.
    - 意図しない差分がある場合は, コミット / 破棄 / 退避の方針を決めてから進みます.
- push 方法を決めます.
    - remote に branch が未公開の場合 → 公開前に履歴を整形してから push します.
        - `git rebase origin/main` → `git reset --soft origin/main` → 適切な粒度で commit を作り直します.
    - 公開済みの場合 → 通常 push します.
    - コマンド例:
        ```bash
        # 実行場所: 作業用 worktree
        git push -u origin <branch>           # 初回 (upstream を設定)
        # または
        git push                              # 2 回目以降
        git push --force-with-lease           # 履歴整形した場合
        ```
- PR を決定します.
    - `gh pr list --head "$HEAD_BRANCH" --state all` で既存 PR を確認し, open PR があれば再利用します.
    - Issue の完了条件がすべて満たされていれば ready PR, そうでなければ draft PR とします.
    - ready PR は `Closes #<issue番号>`, draft PR は `Refs #<issue番号>` を使います.
- PR の内容をユーザーへ提示し, 認証を得ます.
    - PR タイトル, 本文, draft / ready の別を提示します.
- ユーザーの認証後に PR を作成または更新します.
    - 実行場所: メインリポジトリ. `gh pr create` はカレントブランチから PR を作るため, worktree から実行すると別 Bash セッションで cwd がリセットされて main から作ろうとしてエラーになる事故が起きやすい. メインリポジトリから `--head <branch>` で明示するのが安全.
    - 本文はヒアドキュメントで一時ファイルに書き出してから `--body-file` で渡します. シェル内で本文に含まれるバッククォートをエスケープする事故を防ぐためです.
    - タイトルにバッククォートを含む場合, `--title "..."` とダブルクォートで渡すとシェルがコマンド置換として解釈し壊れる. 変数経由かシングルクォートで渡します.
    - コマンド例:
        ```bash
        # 実行場所: メインリポジトリ
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
- ready PR の場合, レビュー依頼先をユーザーに確認します.
    - 「レビューを依頼するユーザーがいれば GitHub ユーザー名を教えてください」と尋ねます.
    - ユーザーが指定した場合は `bash ${CLAUDE_SKILL_DIR}/scripts/add_reviewer.sh <PR番号> <username>` で依頼します.
        - 実行場所: メインリポジトリ (リポジトリ判定に `gh repo view` を使うため worktree 内でも可).
        - `gh pr edit` が `projectCards` の GraphQL エラーで失敗する場合は REST API を使う.
          例: `gh api repos/<owner>/<repo>/pulls/<number> --method PATCH --field title='...' --jq '.title'`
    - 不要と回答した場合はスキップします.
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

*This comment was posted by AI Agent.*
```

## 原則

- PR のタイトルおよび本文は日本語で書きます.
- `--force` は使わず, 必要時は `--force-with-lease` のみ使います.
- ユーザー認証なしに PR を作成しません.
- 判断に迷う場合は作業を中断し, ユーザーに報告, 相談します.

## この phase の完了条件

- [ ] 作業ブランチが origin に push 済みである.
- [ ] PR が `main` 向けに作成または再利用されている.
- [ ] Issue の `進捗` が PR 状態に一致している.
- [ ] Step 06 を開始できる状態になっている.
