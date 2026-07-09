---
name: documentation
description: 機能コード以外の開発情報を「どこに書き、どこには書かないか」を定めるスキルである。Issue・PR・コミット・コードコメント・ADR・Design Doc・docs・CHANGELOG のいずれに何を書くか迷うとき、ドキュメントを書くとき、設計判断を ADR や Design Doc に残すとき、リリースに向けて CHANGELOG を更新するときに使用する。
---

## 本スキルが解決する問題

ソフトウェア開発では、機能のソースコード以外にも、課題の背景、期待する動作、検討した代替案、実際の変更内容、現在の仕様、設計上の判断、使い方、変更履歴など、多岐にわたる情報が生み出される。これらの情報を「どの成果物に書き、どこには書かないか」というルールが明確でないと、同じ内容が複数の場所に記載されて矛盾が生じたり、逆にどこにも記録されずに失われたりしてしまう。

本スキルは、こうした各種情報の置き場をそれぞれ1か所に定めることを目的とする。ルールの中心となるのは、各成果物に「書くべきこと」と「書くべきでないこと」を対照させた「置き場マップ」であり、その正本は [references/placement_map.md](./references/placement_map.md) に配置している。本ファイルでは、置き場を判断するための基本的な考え方のみを解説する。

## 情報を「変更系」と「恒常系」のどちらで扱うか

情報は、その性質によって「変更系」と「恒常系」の2つに大別され、それぞれ扱い方が異なる。

Issue、Pull Request（PR）、コミットメッセージ、Design Doc といった変更系の情報は、特定の変更に関して「いつ・なぜ・何を変えたか」を記録するスナップショットである。これらは変更が完了した時点で凍結し、以後は書き換えない。

一方、コードコメント、ADR、ドキュメント（docs）、README、CHANGELOG といった恒常系の情報は、「現在どうなっているか」を示すものである。これらは変更のたびに更新し、常に最新の状態を反映させる。

これらはどちらか一方だけでは不十分である。変更系だけでは過去の記録を時系列で読み解かなければ現在の仕様が把握できず、恒常系だけでは「なぜ今の形になったのか」という経緯を辿れない。したがって、両者をそれぞれの役割に特化させたうえで併用する必要がある。

## 同じ事実を 2 か所に書かず、1 事実に対して 1 正本とする

置き場を定めても、同じ内容をあちこちへ書き写していては意味がない。そこで、1 つの事実は 1 か所だけを正本として書き、別の場所から同じ事実に触れたいときは、内容を複製せず正本へリンクする。リンクの向きは「変更系 → 恒常系」を基本とする。これは、凍結された過去の記録から、常に更新され続ける最新の情報を参照するのが自然であるためである。

意思決定の経緯についても、この原則に沿って振り分けることにする。その変更のみで完結する理由は PR 本文に書けば十分だが、将来の実装に影響を与える重要な決定は ADR として独立 (昇格) させ、PR からはその ADR へリンクを張るようにする ([references/adr.md](./references/adr.md))。

## 置き場マップの引き方

機能コード以外のすべての情報は、必ずどこか 1 か所を正本とする。どこに書くか迷った場合は、まずその情報が「1 つの変更の記録 (変更系)」なのか「現在の状態 (恒常系)」なのかを判断し、[references/placement_map.md](./references/placement_map.md) にある置き場所の表から適切なものを選ぶ。

表を見ただけでは判断しきれない場合は、同ファイル内に記載されている各項目の詳述 (判断根拠と実例) を確認する。ドキュメントを作成・レビューする際は、着手前に必ずこのマップを参照すること。

## 参照文書

- [references/placement_map.md](./references/placement_map.md): 置き場マップの正本。変更系・恒常系それぞれの対照表と、各行の判断根拠・実例を収める。どこに書くか迷ったときの最終的な判断根拠となる。
- [references/adr.md](./references/adr.md): ADR の運用を定める。いつ書くか、Status の遷移、supersede、PR の判断理由からの昇格基準を扱う。
- [references/design_doc.md](./references/design_doc.md): Design Doc の運用を定める。いつ書くか、段階の遷移、確定後の凍結、ADR への切り出しを扱う。
- [references/diataxis.md](./references/diataxis.md): ドキュメントを Diátaxis の 4 分類 (reference / explanation / how-to / tutorial) に分ける指針である。
- [references/changelog.md](./references/changelog.md): CHANGELOG の運用を定める。Keep a Changelog の分類、Semantic Versioning、コミットとの関係を扱う。

## テンプレート

- [references/templates/adr.md](./references/templates/adr.md): ADR の本文テンプレート (Nygard 形式)
- [references/templates/design_doc.md](./references/templates/design_doc.md): Design Doc の本文テンプレート
- [references/templates/changelog.md](./references/templates/changelog.md): CHANGELOG の雛形
