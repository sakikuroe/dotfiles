# C++ コーディングルール

## このドキュメントの目的

- 本ドキュメントは, このリポジトリで C++ のコードを書くときの基本ルールをまとめます.
- 新しくコードやモジュールを追加する場合や, 既存コードを修正する場合は, ここに書かれた方針に従ってください.

## 命名規則

次の命名規則を適用します.

- `snake_case`:
    - ファイル名, ディレクトリー名.
    - 名前空間名.
    - 関数名, メソッド名.
    - ローカル変数名, 引数名, メンバー変数名.
- `UpperCamelCase`:
    - 型名 (`class`, `struct`, `enum class`, `union`, `concept` など).
    - `enum class` の列挙子.
    - テンプレート型パラメーター名 (`T`, `ValueType` など).
- `SCREAMING_SNAKE_CASE`:
    - 定数 (`constexpr`, `constinit`, `static constexpr` など, 定数として扱う値).
    - マクロ名 (ただしマクロの使用は最小限にする).

## ファイル構成

- ヘッダーファイルの先頭には `#pragma once` を記述し, 多重インクルードを防止します.
- `#include` の順序は次の通りとします.
    1. 対応するヘッダー (自身のヘッダー).
    2. 同一プロジェクトのヘッダー.
    3. 外部ライブラリーのヘッダー.
    4. C/C++ 標準ライブラリーのヘッダー.
- 標準ライブラリーおよび外部ライブラリーのヘッダーには角括弧 `<...>` を使用します. プロジェクト内のヘッダーには引用符 `"..."` を使用します.
- 相対パスで上位ディレクトリーへ遡る `#include "../..."` は使用しません.

## 名前空間と `using`

- `using namespace ...;` は, いかなるスコープでも禁止します.
- 関数や型を `using` で直接導入せず, 名前空間エイリアスを経由して参照します.
    - 推奨:

    ```cpp
    namespace hos = front_of_house::hosting;
    hos::add_to_waitlist();
    ```

    - 非推奨:

    ```cpp
    using front_of_house::hosting::add_to_waitlist;
    add_to_waitlist();
    ```

## コーディングスタイル

- インデントには半角スペース 4 個分を用います. タブは使用しません.
- 各コード行は原則として 100 文字以内を目安とします. 可読性のために必要な場合は, 100 文字を超えても構いません.
- 波括弧は K&R 形式を用い, 開き括弧は同一行に置きます.
- `if`, `else`, `for`, `while`, `do`, `switch` の波括弧は省略しません.
- `else` は閉じ波括弧と同じ行に配置します (`} else {`).
- 二項演算子の前後にはスペースを入れます (`a + b`, `i += 1`).
- インクリメント, デクリメントは `i += 1`, `i -= 1` を使用し, `i++`, `++i`, `i--`, `--i` は使用しません.
- イテレーターの操作には以下を使用します.
    - 既存イテレーターを進める: `std::advance(it, n)`.
    - 新しいイテレーターを得る: `std::next(it, n)`, `std::prev(it, n)`.
- 初期化は, 原則としてリスト初期化 `{}` を用います.
    - ただし, `std::vector<T>(n)` のように意図的にコンストラクター呼び出しを選ぶ場合は `()` を用いて構いません.

## 型と変数

- すべての変数宣言に `auto` を用い, 必ず初期化子を付けます.
- `const`, `constexpr`, `static` な変数やメンバーについても `auto` を用います.
- 型は右辺で確定させます. 明示的なコンストラクター呼び出しやキャストで意図を示します.
- 初期化は原則として `{}` を用い, 縮小変換 (`narrowing`) を防止します.
- 配列の添字やサイズには `std::size_t` を用います. 負数が意味を持つ差分には `std::ptrdiff_t` を用います.
- 整数型は `int` や `long` を安易に使わず, 固定幅整数 (`std::uint32_t`, `std::int64_t` など) を優先します.
- CUDA の `dim3` コンストラクターに渡す引数には `std::uint32_t` を使用します.
- 所有権を持つポインターには `std::unique_ptr` または `std::shared_ptr` を使用し, 生ポインターで所有権を管理することは禁止します.
- `new` / `delete` の直接使用は禁止します. 動的確保が必要な場合は `std::make_unique` / `std::make_shared` を使用します.
- 所有権を持たない参照渡しには生ポインターまたは参照を用いて構いません.
- ヌルポインターには `nullptr` を使用します. `NULL` や `0` をヌルポインターとして使用することは禁止します.
- キャストは `static_cast`, `const_cast`, `reinterpret_cast` を明示的に使用し, C 形式のキャストは使用しません.
- 例外を送出しない関数には `noexcept` を付与します.
- 単一引数のコンストラクターには `explicit` を付与し, 暗黙の型変換を防ぎます.
- オーバーライドする仮想関数には `override` 指定子を必ず付けます.

例:

```cpp
// ループカウンター
for (auto i = std::size_t{0}; i < 100; i += 1) {
    ...
}

// 整数・定数
auto value = std::uint64_t{42};
auto diff = std::ptrdiff_t{-1};
constexpr auto MAX_N = std::size_t{1'000'000};

// コンテナ（サイズ指定のため () を使用）
auto v = std::vector<std::uint64_t>(n);

// アトミック変数
static auto flag = std::atomic_bool{false};

// ヌルポインター
auto ptr = static_cast<std::uint64_t*>(nullptr);

// 所有権を持つポインター
auto owned = std::make_unique<std::uint64_t>(std::uint64_t{0});
auto shared = std::make_shared<std::uint64_t>(std::uint64_t{0});

// 所有権を持たない参照渡し（生ポインター）
auto* raw = owned.get();
```

## 定数・グローバル・列挙

- グローバル変数の使用は禁止します (テスト専用の限定的な用途を除く).
- マジックナンバーは禁止します. 意味のある名前付き定数に置き換え, 必要に応じて単位や根拠をコメントします.
- 時刻や期間は, 可能な限り `std::chrono` などの型安全な表現を用います.
- 列挙には `enum class` を用い, 暗黙の整数変換を防止します.

## コメントとドキュメント

### 通常コメント (`//`)

- コメントはすべて日本語で記述します.
- リポジトリ内のすべてのコードにコメントを付与します.
- コードの逐語訳ではなく, 意図や背景を説明する文章にします.
- 原則として, 変数の宣言・初期化, ループ開始, 条件分岐, 主要な計算ステップごとにコメントを付与します.
- コードの塊単位ではなく, 論理的な 1 ステップ単位で記述します.
- コメントだけを読んでも処理の流れが理解できる粒度を目指します.
- なぜその初期値か, なぜその条件か, なぜその計算式か (数学的根拠や最適化の意図) を明示します.
- 守るべき不変条件や前提条件を明示します.

### ドキュメントコメント (`///`, `//!`)

- Doxygen 互換の `///` または `//!` を用い, 日本語で記述します.
- ライブラリーやモジュールの概要は, ファイル先頭に `//!` で記述します.
- すべてのアイテム (`class`, `struct`, `enum`, 関数, `namespace` など) について, 公開・非公開を問わず直前に `///` を付与します.
- 関数ドキュメントには, 次のセクションを設けます.
    - 概要.
    - `# Args`: 引数の説明.
    - `# Returns`: 戻り値の説明.
    - `# Constraints`: 引数やテンプレート引数に関する制約.
    - `# Throws`: 例外を送出する条件.
    - `# Complexity`: 時間計算量, 空間計算量 (Big O 記法).
    - `# Examples`: 完結した実行可能なサンプルコード.
- `Args` と `Returns` では, 型だけでなく, 値の意味と用途を説明します.

### エラーの書式

- エラーメッセージは日本語で記述します.
- テストにおける等価性検証は `(期待値, 実際値)` の順序とします.
    - 例: GoogleTest の `EXPECT_EQ(expected, actual)`.

## コード例

以下に, ルールを満たしたコード例を示します.

```cpp
//! 素数列の生成機能を提供するモジュール.
//!
//! 指定された個数の素数を試し割り法で生成する.

#include "prime_generator.hpp"

#include <cstddef>
#include <cstdint>
#include <vector>

namespace prime_generator {

/// 最初の `n` 個の素数を生成する.
///
/// # Args
/// - `n`: 生成する素数の個数.
///
/// # Returns
/// - 昇順に並んだ素数列.
///
/// # Constraints
/// - 戻り値の要素数は `n` と一致する.
///
/// # Throws
/// - メモリー確保に失敗した場合, `std::bad_alloc` を送出する可能性がある.
///
/// # Complexity
/// - 時間計算量: 概ね `O(n * sqrt(p_n))`.
/// - 空間計算量: `O(n)`.
///
/// # Examples
/// ```cpp
/// auto primes = prime_generator::generate_primes(std::size_t{5});
/// // primes == {2, 3, 5, 7, 11}
/// ```
auto generate_primes(std::size_t n) -> std::vector<std::uint64_t> {
    // 生成個数が 0 の場合は空配列を返して処理を終了する.
    if (n == std::size_t{0}) {
        return {};
    }

    // 素数を格納する領域を確保し, 再確保回数を抑制する.
    auto primes = std::vector<std::uint64_t>{};
    primes.reserve(n);

    // 最初の素数 2 を先に追加し, 以降は奇数だけを候補にする.
    primes.push_back(std::uint64_t{2});

    // 偶数は素数になり得ないため, 候補値は 3 から開始する.
    auto candidate = std::uint64_t{3};

    // 必要個数に達するまで候補値の素数判定を繰り返す.
    while (primes.size() < n) {
        // 現在候補が素数であると仮定して判定を開始する.
        auto is_prime = true;

        // 既知の素数で割り切れるかを確認し, 合成数なら早期終了する.
        for (const auto& prime : primes) {
            // prime^2 > candidate なら, これ以上の試し割りは不要になる.
            if (prime > candidate / prime) {
                break;
            }

            // 割り切れた場合は合成数と確定する.
            if (candidate % prime == std::uint64_t{0}) {
                is_prime = false;
                break;
            }
        }

        // 素数と判定できた候補値のみ結果に追加する.
        if (is_prime) {
            primes.push_back(candidate);
        }

        // 次の奇数候補へ進める.
        candidate += std::uint64_t{2};
    }

    return primes;
}

}  // namespace prime_generator
```
