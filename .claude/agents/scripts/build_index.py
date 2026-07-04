#!/usr/bin/env python3
"""research/index.md を全ノートの frontmatter から再生成する。

- index.md は常にこのスクリプトの出力で置き換えられる派生物であり、手で編集しない。
- 冪等: ノートの追加・削除・移動後に再実行すれば必ず正しい状態に収束する。
- 依存: Python 3 標準ライブラリのみ。
- 実行: python3 .claude/agents/scripts/build_index.py
"""
import datetime
import os
import re
import sys

# このスクリプトは .claude/agents/scripts/ に置かれる前提。
# リポジトリー直下の research/ を ROOT とする。
ROOT = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))),
    "research",
)
INDEX = os.path.join(ROOT, "index.md")
SKIP_DIRS = {".raw", ".scripts"}

SCALAR_KEYS = ("title", "url", "topic", "fetched_at", "summary")


def parse_frontmatter(text):
    """先頭の --- ... --- ブロックから必要なキーだけを素朴に抜き出す。

    ノートの frontmatter は各エージェントの規約に従う（値は1行、tags は
    フロースタイルの配列）前提で、汎用 YAML パーサは使わない。
    """
    m = re.match(r"\A---\s*\n(.*?)\n---\s*\n", text, re.S)
    if not m:
        return None
    fm = m.group(1)
    d = {}
    for key in SCALAR_KEYS:
        km = re.search(rf"^{key}:\s*(.+?)\s*$", fm, re.M)
        if km:
            v = km.group(1).strip()
            v = re.sub(r"\s+#.*$", "", v)  # 行末コメントを除去
            d[key] = v.strip().strip('"').strip("'")
    tm = re.search(r"^tags:\s*\[(.*?)\]\s*$", fm, re.M)
    if tm:
        d["tags"] = [t.strip().strip('"').strip("'")
                     for t in tm.group(1).split(",") if t.strip()]
    return d


def first_sentence(s):
    if not s:
        return ""
    for sep in ("。", ". "):
        i = s.find(sep)
        if i != -1:
            return s[: i + len(sep)].strip()
    return s.strip()


def sanitize(s):
    """index の1行1ノート形式を壊す文字を無害化する。"""
    return (s or "").replace("|", "／").replace("\n", " ").strip()


def collect():
    entries = []
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = sorted(
            d for d in dirnames if d not in SKIP_DIRS and not d.startswith(".")
        )
        for fn in sorted(filenames):
            if not fn.endswith(".md") or os.path.join(dirpath, fn) == INDEX:
                continue
            path = os.path.join(dirpath, fn)
            rel = os.path.relpath(path, ROOT)
            try:
                with open(path, encoding="utf-8") as f:
                    fm = parse_frontmatter(f.read())
            except OSError as e:
                print(f"skip {rel}: {e}", file=sys.stderr)
                continue
            if fm is None:
                print(f"skip {rel}: frontmatter がない", file=sys.stderr)
                continue
            group = rel.split(os.sep)[0] if os.sep in rel else "(root)"
            entries.append((group, rel, fm))
    return entries


def render(entries):
    today = datetime.date.today().isoformat()
    lines = [
        "# research index",
        "",
        "<!-- scripts/build_index.py による自動生成。直接編集しないこと。 -->",
        f"生成: {today} / ノート数: {len(entries)}",
        "",
    ]
    groups = {}
    for group, rel, fm in entries:
        groups.setdefault(group, []).append((rel, fm))
    for group in sorted(groups):
        lines.append(f"## {group}")
        lines.append("")
        # グループ内は fetched_at の新しい順、同日ならパス順
        for rel, fm in sorted(
            groups[group], key=lambda e: (e[1].get("fetched_at", ""), e[0]),
            reverse=True,
        ):
            title = sanitize(fm.get("title")) or rel
            fetched = sanitize(fm.get("fetched_at")) or "????-??-??"
            if fm.get("url"):
                origin = sanitize(fm["url"])
            elif fm.get("topic"):
                origin = "topic: " + sanitize(fm["topic"])
            else:
                origin = "-"
            summary = sanitize(first_sentence(fm.get("summary", "")))
            tags = "tags: " + ", ".join(fm.get("tags", [])) if fm.get("tags") else "tags: -"
            lines.append(
                f"- [{title}]({rel.replace(os.sep, '/')}) | {fetched} | {origin} | {summary} | {tags}"
            )
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def main():
    entries = collect()
    content = render(entries)
    tmp = INDEX + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(content)
    os.replace(tmp, INDEX)  # アトミックに置換
    print(f"index.md を再生成した（ノート数: {len(entries)}）")


if __name__ == "__main__":
    main()
