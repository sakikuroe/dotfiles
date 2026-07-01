---
name: documentation
description: 機能コード以外の開発情報を「どこに書き、どこには書かないか」を定めるスキルである。Issue・PR・コミット・コードコメント・ADR・docs・CHANGELOG のいずれに何を書くか迷うとき、ドキュメントを書くとき、設計判断を ADR に残すとき、リリースに向けて CHANGELOG を更新するときに使用する。
---

## 概要

ソフトウェア開発では、機能コードそのもの以外に多くの情報が生まれる。課題や背景、期待する動作、検討した代替案、実際の変更内容、現在の仕様、設計判断、使い方、変更履歴などである。これらを「どの成果物に書き、どこには書かないか」が定まっていないと、同じ事実が複数箇所に重複したり、どこにも書かれず失われたりする。

本スキルは、これらの情報の置き場を 1 か所に定める。中心となるのは、各成果物について「書くこと」と「書かないこと」を一覧した置き場マップである。各行の詳しい根拠と例は [references/placement_map.md](./references/placement_map.md) で詳述する。

## 2 つの軸

情報は性質によって 2 つの系に分かれ、扱い方が異なる。

- 変更系 (Issue / 実装計画 / PR / コミット / 進捗コメント): 1 つの変更の「いつ・なぜ・何を変えたか」を時点で記録する。マージ後は凍結し、書き換えない。
- 恒常系 (コードコメント / ADR / docs / README / CHANGELOG): 「いまどうなっているか」を表す。変更のたびに更新し、常に現在の状態を反映させる。

変更系だけでは「現在どうなっているか」を復元できず、恒常系だけでは「なぜそうなったか」を辿れない。両方を、それぞれの役割に絞って持つ。

## 重複を減らす原則

- 1 事実 1 正本: 1 つの事実は 1 か所だけに書く。
- コピーせずリンク: 別の場所から同じ事実に触れたいときは、内容を複製せず正本へリンクする。参照の方向は「変更系 → 恒常系」を基本とする。
- 意思決定の振り分け: その変更限りの理由は PR 本文に書く。将来の実装を縛る決定は ADR へ昇格させる ([references/adr.md](./references/adr.md))。

## 置き場マップ

機能コード以外のすべての情報は、次のいずれか 1 か所を正本とする。迷ったときは、その情報が「1 つの変更の記録」なのか「現在の状態」なのかをまず判断し、該当する系の表から置き場を選ぶ。

### 変更系 (1 変更ごとに作り、マージ後は凍結する)

| 置き場所 | ここに書く (正本) | ここには書かない (→ 正しい置き場) |
| --- | --- | --- |
| Issue 本文 | 課題・背景・動機、利用者視点の期待動作、受け入れ基準 (完了条件)、スコープ外 | 実装手段・API・設定・アーキ全体像 (→ docs)、進捗 (→ Issue コメント) |
| Issue コメント (実装計画) | 実装方針、変更対象、検討した代替案と却下理由、テスト方針 | 確定後の現在仕様 (→ reference)、将来を縛る決定 (→ ADR) |
| Issue コメント (進捗) | ブランチ名・PR・状態 | 設計・仕様・知見 (→ 各正本) |
| PR 本文 | 対応 Issue、変更概要、計画からの乖離点 (計画へリンク)、スコープ外、動作確認・テスト結果、恒常 docs 更新の確認 | Issue 背景の再掲、現在仕様の全体 (→ docs)、決定の正本 (→ ADR、PR はリンク) |
| コミットメッセージ | 1 関心事の変更内容とその理由 | 大きな設計判断の正本 (→ ADR) |

### 恒常系 (現在の状態を表し、変更のたびに更新する)

| 置き場所 | ここに書く (正本) | ここには書かない (→ 正しい置き場) |
| --- | --- | --- |
| コードコメント | 局所的な「なぜこの行・このやり方か」、前提・落とし穴 | 全体の仕様・設計判断 (→ docs / ADR) |
| ADR (`docs/adr`) | 将来を縛る設計判断と、その文脈・却下案・結果 | 使い方 (→ how-to)、変更手順 (→ PR)、受理後は不変 (supersede で更新) |
| docs / reference | 現在の仕様・API・設定の正確な事実 | なぜそうしたか (→ explanation / ADR)、手順 (→ how-to) |
| docs / explanation | 設計の背景・仕組み・なぜこうなっているか | 網羅的な仕様の逐一 (→ reference)、手順 (→ how-to) |
| docs / how-to | 特定の目的を達成する手順 | 概念の説明 (→ explanation)、網羅仕様 (→ reference) |
| docs / tutorial | 初学者向けの学習導線 | 網羅的なリファレンス (→ reference) |
| README | プロジェクト概要・導入・docs への入口 | 詳細な仕様 (→ docs) |
| CHANGELOG | バージョン間の利用者向け変更点 (Added/Changed/Fixed 等) | 内部実装の詳細 (→ PR / コミット) |

docs の 4 分類 (reference / explanation / how-to / tutorial) の使い分けは [references/diataxis.md](./references/diataxis.md) を、各行の詳しい根拠と例は [references/placement_map.md](./references/placement_map.md) を参照する。

## 参照文書

- [references/placement_map.md](./references/placement_map.md): 置き場マップの各行を詳述する。迷ったときの最終的な判断根拠
- [references/adr.md](./references/adr.md): ADR をいつ・どう書くか。Status の遷移、supersede、PR の判断理由からの昇格基準
- [references/diataxis.md](./references/diataxis.md): docs を Diátaxis の 4 分類に分ける指針
- [references/changelog.md](./references/changelog.md): CHANGELOG の運用（Keep a Changelog の分類、Semantic Versioning、コミットとの関係）

## テンプレート

- [references/templates/adr.md](./references/templates/adr.md): ADR の本文テンプレート (Nygard 形式)
- [references/templates/changelog.md](./references/templates/changelog.md): CHANGELOG の雛形 (Keep a Changelog)
