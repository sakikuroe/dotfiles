---
name: unit-test
description: >-
  単体テスト（ユニットテスト）の作成・修正・レビュー時、TDDでの実装時、機能実装と合わせたテスト追加時には、必ずこのスキルに従う。テストの命名・構成・セットアップ関数・テストダブル（モック・スタブ・スパイ）・パラメタライズドテスト（テーブル駆動テスト）・フィクスチャに関する話題が出たときや、英語で unit test / write tests と依頼された場合も同様である。
---

# 単体テストテンプレート

仕様（何を検証するか）はドキュメントコメントに、実装（どう検証するか）はテストコードの本文に分けて記述する。これにより、コードを読まなくてもテストの意図を把握でき、コード自体も説明文に埋もれず読みやすくなる。この原則はプログラミング言語に依存しない。以下の例は Rust で記述しているが、他の言語を対象とする場合は、ドキュメントコメントの記法・テストのグループ化単位・テストフレームワークの流儀といった構文要素を、その言語の標準的な慣例に読み替えて同じ構造を実現すること。

本ルールの適用範囲は以下の通りである。新規にテストを追加する際は、この構造で記述する。一方、既存のテストを修正する際は、そのファイル独自の記述スタイルを尊重し、特に依頼がない限り、本構造への書き換えを目的としたリファクタリングは行わない。修正のたびに周囲と異なるスタイルを持ち込むと、かえってファイル全体の可読性を損なうためである。テストをレビューする際には、この構造を指摘の基準とする。

## ルール

テスト対象のインスタンスは、慣例に倣い `sut`（System Under Test の略記）という変数名にする。これにより、どれがテスト対象で、どれが準備のための値なのかを一目で区別できるようになる。テスト関数名は、検証する振る舞いを短い英文で表し（例: `sums_price_times_quantity`）、日本語での詳細な説明はドキュメントコメントに記述する。

各テスト関数のドキュメントコメント（例における `///`）は仕様書の役割を果たす。`Scenario:` に続けて振る舞いを1行で要約し、前提（Given）・操作（When）・期待する結果（Then）を箇条書きにする。テスト本文には `Given` `When` `Then` の区切りコメントのみを配置し、説明は繰り返さない。同じ説明を両方に記述すると二重管理となり、修正漏れの原因になるためである。

複数のテストで共有する前提条件（インスタンスの生成など）は、テストモジュール冒頭のセットアップ関数（ファクトリ関数）に集約する。この関数の目的は行数の節約ではない。第一に、各テストの Given から「そのテスト本来の関心事ではない準備の詳細」を隠蔽し、検証したい差分だけを際立たせることである。第二に、生成用の API が変更された際の影響をこの一箇所に留め、テスト群の変更に対する耐性を高めることである。逆に、単一のテストのみで使用する特殊な前提条件は、切り出さずにそのテストの Given に直接記述したほうが、視線移動が減り読みやすくなる。なお、セットアップ関数のドキュメントコメントには `Background:` を付け、生成される前提状態を1行で要約する。

前提状態を作る際、テスト対象のフィールドを直接書き換えてよいのは、そのフィールドが公開（public）されている場合に限る（テンプレートの `rejects_shipped_order` がこれに該当する）。フィールドが非公開の実コードでは、公開 API（例では `ship`）を呼び出して状態を遷移させるか、テスト用の生成関数を用意して前提条件を整えること。

テストは対象メソッドごとに、その言語における標準的なグループ化単位（例ではネストした `mod`）を用いてまとめ、グループの直前には何を検証するテスト群なのかをコメントで記述する。検証の観点は大きく分けて「戻り値そのもの」「呼び出し後のオブジェクトの状態変化」「依存先への呼び出し（通知や保存などの相互作用）」の3つである。相互作用の検証では、依存先を抽象インターフェース（例では trait）を実装したテストダブル（偽物）に差し替える。依存先の戻り値を固定して間接入力を与えたい場合はスタブを、依存先への呼び出しを記録して間接出力を確かめたい場合はスパイを使用する。テストダブルはテンプレートのように手書きしてもよいし、モックライブラリ（mockall、unittest.mock、jest.mock、Mockito など）を利用してもよい。プロジェクトにすでに特定の流儀があるならそれに従う。いずれの場合も、検証したい相互作用（呼び出し回数や引数など）は Then ブロックに明示的なアサーション（assert）として記述する。

1つのテスト内にアサーション（assert）が複数あっても、同じ操作の結果を確かめるものであれば問題ない。特にエラー系のテストでは、エラーが返ることに加え、「状態が変わっていないこと」や「通知などの副作用が起きていないこと」まで含めて検証する。これにより、処理の失敗時に中途半端な変更が残ってしまうというバグを検出できるためである。

Given/When/Then の構造が同一で、入力と期待値の組み合わせのみが異なるケースが複数存在する場合は、ケースごとにテスト関数を手動で複製せず、パラメタライズドテスト機能を用いてまとめてよい。対象言語やテストフレームワークが提供するパラメタライズドテストの仕組み（例では rstest クレート。他に pytest の parametrize、JUnit の @ParameterizedTest、Jest の test.each、Go のテーブル駆動テストなど）を活用し、各ケースが独立したテストとして実行および報告されるようにする。その際、ケース名には検証内容が分かる説明を付けること。プロジェクトにこの仕組みが導入されていない場合、無断で開発用依存ライブラリを追加してはならない。追加の可否を確認するか、言語の標準機能だけで記述できる形（ループや個別のテスト関数など）で実装する。逆に、ケースごとに前提条件や検証内容そのものが異なる場合は、無理にまとめず個別のテスト関数に分けたほうが可読性が高い。なお、後述のテンプレートでは書き方の比較として単発テストとパラメタライズド版を併記しているが、実際のコードでは同じ振る舞いを二重に検証することは避け、適した方を一つ選択すること。

## テンプレート（Rust による例）

本テンプレートでは開発用依存関係として rstest を使用するため、事前に `Cargo.toml` の `[dev-dependencies]` へ `rstest` を追加してから使用すること。

```rust
/// 出荷完了を顧客に知らせるための手段。テスト時には記録用のテストダブル（スパイ）に差し替える。
pub trait Notifier {
    fn send(&self, message: &str);
}

/// 注文の状態。
#[derive(Debug, PartialEq)]
pub enum Status {
    Accepted,
    Shipped,
}

/// 1件の注文。顧客名・明細・状態を保持する。
pub struct Order {
    pub customer: String,
    /// 明細（品名, 単価, 数量）
    pub items: Vec<(String, i64, u32)>,
    pub status: Status,
}

impl Order {
    /// 明細が空の注文を受付状態で作成する。
    pub fn new(customer: &str) -> Self {
        Self { customer: customer.to_string(), items: vec![], status: Status::Accepted }
    }

    /// 明細を追加する。出荷済みの注文は変更できない。
    pub fn add_item(&mut self, name: &str, price: i64, qty: u32) -> Result<(), String> {
        if self.status == Status::Shipped {
            return Err("出荷済みの注文は変更できません".into());
        }
        self.items.push((name.to_string(), price, qty));
        Ok(())
    }

    /// 合計金額（単価×数量の総和）を返す。
    pub fn total(&self) -> i64 {
        self.items.iter().map(|(_, price, qty)| price * i64::from(*qty)).sum()
    }

    /// 状態を出荷済みに更新し、顧客へ通知を送る。明細が空、またはすでに出荷済みの場合はエラーとする。
    pub fn ship(&mut self, notifier: &impl Notifier) -> Result<(), String> {
        if self.items.is_empty() {
            return Err("明細のない注文は出荷できません".into());
        }
        if self.status == Status::Shipped {
            return Err("すでに出荷済みです".into());
        }
        self.status = Status::Shipped;
        notifier.send(&format!("{}様の注文を出荷しました", self.customer));
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::cell::RefCell;

    /// Background: 明細2件（合計1300円）を持つ受付状態の注文
    /// 生成手順をここに集約し、各テストには検証したい差分のみを記述する。
    fn create_order() -> Order {
        let mut order = Order::new("田中太郎");
        order.add_item("紅茶", 500, 2).unwrap();
        order.add_item("砂糖", 300, 1).unwrap();
        order
    }

    /// Notifier のスパイ。送信内容を記録し、後から検証できるようにする。
    struct SpyNotifier {
        messages: RefCell<Vec<String>>,
    }
    impl SpyNotifier {
        fn new() -> Self { Self { messages: RefCell::new(vec![]) } }
        fn sent_count(&self) -> usize { self.messages.borrow().len() }
        fn last_message(&self) -> String { self.messages.borrow().last().cloned().unwrap_or_default() }
    }
    impl Notifier for SpyNotifier {
        fn send(&self, message: &str) { self.messages.borrow_mut().push(message.into()); }
    }

    // total のテスト: 戻り値を検証する
    mod total {
        use super::*;
        use rstest::rstest;

        /// Scenario: 合計金額は明細の単価×数量の総和になる
        /// - Given: 紅茶500円×2と砂糖300円×1を持つ注文がある
        /// - When: 合計金額を求める
        /// - Then: 1300円になる
        #[test]
        fn sums_price_times_quantity() {
            // Given
            let sut = create_order();
            // When
            let result = sut.total();
            // Then
            assert_eq!(result, 1300);
        }

        /// Scenario: 明細の組み合わせによらず、合計金額は単価×数量の総和になる
        /// - Given: 明細の件数や内容が異なる複数の注文がある
        /// - When: 合計金額を求める
        /// - Then: 各ケースにおいて期待通りの金額になる
        #[rstest]
        #[case::no_items(vec![], 0)]
        #[case::single_item(vec![("紅茶", 500, 2)], 1000)]
        #[case::multiple_items(vec![("紅茶", 500, 2), ("砂糖", 300, 1)], 1300)]
        fn sums_price_times_quantity_for_various_item_sets(
            #[case] items: Vec<(&str, i64, u32)>,
            #[case] expected: i64,
        ) {
            // Given
            let mut sut = Order::new("田中太郎");
            for (name, price, qty) in items {
                sut.add_item(name, price, qty).unwrap();
            }
            // When
            let result = sut.total();
            // Then
            assert_eq!(result, expected);
        }
    }

    // add_item のテスト: 状態変化を検証する
    mod add_item {
        use super::*;

        /// Scenario: 受付状態の注文には明細を追加できる
        /// - Given: 明細2件の注文がある
        /// - When: 明細を1件追加する
        /// - Then: 成功し、明細が3件になる
        #[test]
        fn appends_to_items() {
            // Given
            let mut sut = create_order();
            // When
            let result = sut.add_item("ミルク", 200, 1);
            // Then
            assert!(result.is_ok());
            assert_eq!(sut.items.len(), 3);
        }

        /// Scenario: 出荷済みの注文への追加はエラーになり、明細は変わらない
        /// - Given: 出荷済みの注文がある
        /// - When: 明細を追加しようとする
        /// - Then: エラーが返り、明細は2件のまま
        #[test]
        fn rejects_shipped_order() {
            // Given
            let mut sut = create_order();
            sut.status = Status::Shipped;
            // When
            let result = sut.add_item("ミルク", 200, 1);
            // Then
            assert!(result.is_err());
            assert_eq!(sut.items.len(), 2);
        }
    }

    // ship のテスト: 依存（Notifier）との相互作用を検証する
    mod ship {
        use super::*;

        /// Scenario: 出荷処理を行うと状態が更新され、顧客へ通知が1回送られる
        /// - Given: 受付状態の注文と通知用のスパイオブジェクトがある
        /// - When: 出荷する
        /// - Then: 状態が出荷済みになり、通知が1回送信される
        #[test]
        fn updates_status_and_notifies() {
            // Given
            let mut sut = create_order();
            let spy = SpyNotifier::new();
            // When
            let result = sut.ship(&spy);
            // Then
            assert!(result.is_ok());
            assert_eq!(sut.status, Status::Shipped);
            assert_eq!(spy.sent_count(), 1);
            assert!(spy.last_message().contains("田中太郎"));
        }

        /// Scenario: 明細のない注文を出荷しようとするとエラーになり、通知も送られない
        /// - Given: 明細が空の注文と通知用のスパイオブジェクトがある
        /// - When: 出荷しようとする
        /// - Then: エラーが返り、状態は受付のままで通知も送信されない
        #[test]
        fn rejects_empty_order_without_notifying() {
            // Given
            let mut sut = Order::new("田中太郎");
            let spy = SpyNotifier::new();
            // When
            let result = sut.ship(&spy);
            // Then
            assert!(result.is_err());
            assert_eq!(sut.status, Status::Accepted);
            assert_eq!(spy.sent_count(), 0);
        }
    }
}
```
