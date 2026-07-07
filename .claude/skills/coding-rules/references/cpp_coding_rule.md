# C++ コーディングルール

## このドキュメントの目的

本ドキュメントは、このリポジトリで C++ のコードを書く際の基本ルールをまとめたものである。新しくコードやモジュールを追加する場合も、既存のコードを修正する場合も、ここに示す方針に従うこと。

## 命名規則

命名には次の規則を適用する。ファイル名・ディレクトリー名、名前空間名、関数名・メソッド名、そしてローカル変数名・引数名・メンバー変数名には `snake_case` を用いる。型名 (`class`、`struct`、`enum class`、`union`、`concept` など)、`enum class` の列挙子、および `T` や `ValueType` といったテンプレート型パラメーター名には `UpperCamelCase` を用いる。`constexpr`、`constinit`、`static constexpr` など定数として扱う値と、マクロ名には `SCREAMING_SNAKE_CASE` を用いる。ただし、マクロの使用自体は最小限にとどめること。

## ファイル構成

ヘッダーファイルの先頭には `#pragma once` を記述し、多重インクルードを防止すること。`#include` は、まず対応するヘッダー (自身のヘッダー)、次に同一プロジェクトのヘッダー、続いて外部ライブラリーのヘッダー、最後に C/C++ 標準ライブラリーのヘッダー、という順序で並べる。その際、標準ライブラリーおよび外部ライブラリーのヘッダーには角括弧 `<...>` を、プロジェクト内のヘッダーには引用符 `"..."` を使用すること。なお、`#include "../..."` のように相対パスで上位ディレクトリーへ遡る指定は使用しないこと。

## 名前空間と `using`

`using namespace ...;` は、いかなるスコープでも禁止する。また、関数や型を `using` で直接導入するのではなく、名前空間エイリアスを経由して参照すること。

推奨:

```cpp
namespace hos = front_of_house::hosting;
hos::add_to_waitlist();
```

非推奨:

```cpp
using front_of_house::hosting::add_to_waitlist;
add_to_waitlist();
```

## コーディングスタイル

インデントには半角スペース 4 個を用い、タブは使用しないこと。各行の長さは原則として 100 文字以内を目安とするが、可読性のために必要であれば 100 文字を超えても構わない。

波括弧は K&R 形式とし、開き括弧は同一行に置く。`if`、`else`、`for`、`while`、`do`、`switch` の波括弧は省略せず、`else` は閉じ波括弧と同じ行 (`} else {`) に配置すること。二項演算子の前後には、`a + b` や `i += 1` のようにスペースを入れる。インクリメント・デクリメントには `i += 1`、`i -= 1` を使用し、`i++`、`++i`、`i--`、`--i` は使用しないこと。イテレーターを操作する際は、既存のイテレーターを進める場合には `std::advance(it, n)` を、新しいイテレーターを得る場合には `std::next(it, n)` や `std::prev(it, n)` を使用する。

初期化は原則としてリスト初期化 `{}` を用いること。ただし、`std::vector<T>(n)` のように意図的にコンストラクター呼び出しを選ぶ場合は、`()` を用いて構わない。

## 型と変数

すべての変数宣言には `auto` を用い、必ず初期化子を付けること。これは `const`、`constexpr`、`static` な変数やメンバーについても同様である。型は右辺で確定させるものとし、明示的なコンストラクター呼び出しやキャストによって意図を示すこと。初期化には原則として `{}` を用い、縮小変換 (narrowing) を防止する。

整数型については、配列の添字やサイズには `std::size_t` を、負数が意味を持つ差分には `std::ptrdiff_t` を用いる。また、`int` や `long` を安易に使わず、`std::uint32_t` や `std::int64_t` などの固定幅整数を優先すること。なお、CUDA の `dim3` コンストラクターに渡す引数には `std::uint32_t` を使用する。

ポインターの扱いについては、所有権を持つポインターには `std::unique_ptr` または `std::shared_ptr` を使用し、生ポインターで所有権を管理しないこと。`new` / `delete` の直接使用は禁止とし、動的確保が必要な場合は `std::make_unique` / `std::make_shared` を使用する。一方、所有権を持たない参照渡しであれば、生ポインターや参照を用いて構わない。ヌルポインターには `nullptr` を使用し、`NULL` や `0` をヌルポインターとして使わないこと。

キャストが必要な場合は `static_cast`、`const_cast`、`reinterpret_cast` を明示的に使用し、C 形式のキャストは使用しないこと。さらに、例外を送出しない関数には `noexcept` を付与する。単一引数のコンストラクターには `explicit` を付けて暗黙の型変換を防ぎ、仮想関数をオーバーライドする際には必ず `override` 指定子を付けること。

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

グローバル変数の使用は、テスト専用の限定的な用途を除いて禁止する。マジックナンバーも禁止とし、意味のある名前付き定数に置き換えたうえで、必要に応じて単位や根拠をコメントに残すこと。時刻や期間を扱う際は、可能な限り `std::chrono` などの型安全な表現を用いる。また、列挙には `enum class` を用い、暗黙の整数変換を防止すること。

## コメントとドキュメント

### 通常コメント (`//`)

コメントはすべて日本語で記述し、リポジトリ内のすべてのコードに付与すること。その際、コードの逐語訳にならないよう注意し、意図や背景を説明する文章にすること。

配置と粒度については、変数の宣言・初期化、ループの開始、条件分岐、主要な計算ステップごとにコメントを付けるのが原則である。コードの塊単位ではなく「論理的な 1 ステップ」単位で記述し、コメントだけを読んでも処理の流れが理解できる粒度を目指すこと。

記述する内容としては、なぜその初期値なのか、なぜその条件なのか、なぜその計算式なのかといった、数学的根拠や最適化の意図を明示する。あわせて、守るべき不変条件や前提条件も明示すること。

### ドキュメントコメント (`///`、`//!`)

ドキュメントコメントには Doxygen 互換の `///` または `//!` を用い、日本語で記述すること。ライブラリーやモジュールの概要は、ファイル先頭に `//!` で記述する。また、`class`、`struct`、`enum`、関数、`namespace` などのすべてのアイテムには、公開・非公開を問わず、その直前に `///` を付与すること。

関数のドキュメントコメントには、まず概要を記載し、続いて次のセクションを設けること。`# Args` セクションには引数の説明を、`# Returns` セクションには戻り値の説明を記載する。`# Constraints` セクションには引数やテンプレート引数に関する制約を、`# Throws` セクションには例外を送出する条件を記載する。`# Complexity` セクションには時間計算量と空間計算量を Big O 記法で示し、`# Examples` セクションには完結した実行可能なサンプルコードを載せる。なお、`# Args` と `# Returns` では、型だけでなく、その値の意味と用途まで説明すること。

### エラーの書式

エラーメッセージは英語で記述すること。また、テストにおける等価性の検証は (期待値, 実際値) の順序とする。たとえば GoogleTest では、`EXPECT_EQ(expected, actual)` のように書く。

## コード例

以下に、ルールを満たしたコード例を示す。

```cpp
//! 素数列の生成機能を提供するモジュール。
//!
//! 指定された個数の素数を試し割り法で生成する。

#include "prime_generator.hpp"

#include <cstddef>
#include <cstdint>
#include <vector>

namespace prime_generator {

/// 最初の `n` 個の素数を生成する。
///
/// # Args
/// - `n`: 生成する素数の個数
///
/// # Returns
/// - 昇順に並んだ素数列
///
/// # Constraints
/// - 戻り値の要素数は `n` と一致する。
///
/// # Throws
/// - メモリー確保に失敗した場合、`std::bad_alloc` を送出する可能性がある。
///
/// # Complexity
/// - 時間計算量: 概ね `O(n * sqrt(p_n))`
/// - 空間計算量: `O(n)`
///
/// # Examples
/// ```cpp
/// auto primes = prime_generator::generate_primes(std::size_t{5});
/// // primes == {2, 3, 5, 7, 11}
/// ```
auto generate_primes(std::size_t n) -> std::vector<std::uint64_t> {
    // 生成個数が 0 の場合は空配列を返して処理を終了する。
    if (n == std::size_t{0}) {
        return {};
    }

    // 素数を格納する領域を確保し、再確保回数を抑制する。
    auto primes = std::vector<std::uint64_t>{};
    primes.reserve(n);

    // 最初の素数 2 を先に追加し、以降は奇数だけを候補にする。
    primes.push_back(std::uint64_t{2});

    // 偶数は素数になり得ないため、候補値は 3 から開始する。
    auto candidate = std::uint64_t{3};

    // 必要個数に達するまで候補値の素数判定を繰り返す。
    while (primes.size() < n) {
        // 現在候補が素数であると仮定して判定を開始する。
        auto is_prime = true;

        // 既知の素数で割り切れるかを確認し、合成数なら早期終了する。
        for (const auto& prime : primes) {
            // prime^2 > candidate なら、これ以上の試し割りは不要になる。
            if (prime > candidate / prime) {
                break;
            }

            // 割り切れた場合は合成数と確定する。
            if (candidate % prime == std::uint64_t{0}) {
                is_prime = false;
                break;
            }
        }

        // 素数と判定できた候補値のみ結果に追加する。
        if (is_prime) {
            primes.push_back(candidate);
        }

        // 次の奇数候補へ進める。
        candidate += std::uint64_t{2};
    }

    return primes;
}

}  // namespace prime_generator
```