"""게임 글 모음 ↔ md: 도서관 책 · 플레이버 텍스트(아이템·소재·몬스터·정수 … 설명) · 상황 문구(ko.json의 문장)를
docs/TEXTS.md 한 파일로 모으고(export, 기본), 사용자가 고친 md를 데이터에 되돌린다(apply).
    python3 tools/texts_md.py                 → docs/TEXTS.md 다시 쓰기
    python3 tools/texts_md.py --only=books_items → docs/TEXTS_BOOKS_ITEMS.md(도서관 책 + 아이템 플레이버만)
    python3 tools/texts_md.py --apply [--md=<고친 파일>] [--dry]  → 바뀐 글만 data/에 넣는다(--dry = 무엇이 바뀔지만)
      (어느 md든 경로로 찾으니 TEXTS.md · TEXTS_BOOKS_ITEMS.md 모두 같은 명령으로 적용된다)
항목 = "#### 이름 · `파일:경로`" 줄 + 그 아래 글(다음 # 줄 전까지). 경로: .키 · [번호] · {id}(목록에서 id가 그것인 항목).
적용은 이미 있는 글만 바꾼다(새 항목·지운 항목은 무시하고 알린다). ko.json 글의 {자리표시자}가 달라지면 건너뛴다.
파일 모양을 지키려고 JSON 글자열을 그 자리에서 바꾸고, 같은 글이 파일에 여럿이면 파일을 다시 쓴다.
적용 뒤: ko.json을 바꿨으면 strings_md.gd(→ STRINGS.md), 그리고 tools/check.sh(서적은 숫자·괄호·존댓말 금지 — CT52).
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MD = os.path.join(ROOT, "docs", "TEXTS.md")
# 일부만 뽑는 파일: 이름 → (md 경로, 큰 제목, 남길 (큰 제목, 작은 제목 목록 — None = 모두))
SUBSETS = {
    "books_items": (os.path.join(ROOT, "docs", "TEXTS_BOOKS_ITEMS.md"), "게임 글 모음 — 도서관 서적 · 아이템 플레이버",
                    [("도서관 책", None), ("플레이버 · 설명 글", ["아이템", "장비 소재", "장비 종류"])]),
}
HEAD = re.compile(r"^#### (.*?) · `([^`]+)`\s*$")
KO = "data/strings/ko.json"

# 플레이버·설명 글: (제목, 파일 glob, 모을 키)
FLAVOR = [
    ("아이템", "data/items/*.json", ["desc_ko"]),
    ("장비 소재", "data/materials.json", ["flavor_ko"]),
    ("장비 종류", "data/item_types.json", ["flavor_ko"]),
    ("요리", "data/meals.json", ["desc_ko", "flavor_ko"]),
    ("몬스터", "data/monsters/*.json", ["desc_ko"]),
    ("정수", "data/essences/*.json", ["desc_ko"]),
    ("스킬", "data/skills/*.json", ["desc_ko"]),
    ("상태이상", "data/statuses.json", ["desc_ko"]),
    ("전투 게이지", "data/meters.json", ["desc_ko"]),
    ("랜드마크", "data/landmarks.json", ["desc_ko"]),
    ("종족 · 직업", "data/races.json", ["desc_ko"]),
    ("종족 · 직업 ", "data/classes.json", ["desc_ko"]),
    ("균열(설명 · 챕터)", "data/rifts/*.json", ["desc_ko"]),
    ("수수께끼(문제 · 벽화)", "data/riddles/*.json", ["question_ko", "hints_ko"]),
]
# 상황 문구: ko.json에서 문장(끝이 . ! ? …)인 글만. UI 이름·버튼·개발 화면 묶음은 뺀다(그것들은 docs/STRINGS.md).
KO_SKIP = {"debug", "foundation", "collection", "error", "app", "num", "menu", "target_kind", "stat_group", "dir8"}
KO_NAMES = {
    "log": "기록 · 일반 알림", "create": "캐릭터 만들기", "explore": "탐험 알림", "effect": "아이템 · 스킬 효과", "end": "귀환",
    "pause": "일시정지", "cause": "사인", "combat": "전투", "reward": "보상 · 정수", "inventory": "소지품", "party": "아군",
    "character": "캐릭터", "codex": "도감", "bestiary": "도감(몬스터)", "essence": "정수 칸", "riddle": "수수께끼",
    "plaza": "차원광장 · 정산", "city": "도시", "field": "동굴 요소", "buff": "버프",
}
SUB_MIN = 5  # 하위 묶음이 이만큼 이상이면 따로 제목(아니면 위 묶음에 섞는다)
SENTENCE = re.compile(r"[.!?…][\"'」』”’)]*$")
HANGUL = re.compile(r"[가-힣]")
PLACEHOLDER = re.compile(r"\{[a-z_0-9]+\}")


def load(rel: str):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
        return json.load(f)


def files(pattern: str) -> list:
    return sorted(os.path.relpath(p, ROOT).replace(os.sep, "/") for p in glob.glob(os.path.join(ROOT, pattern))
                  if not os.path.basename(p).startswith("_"))


# ---- 경로 ----
def walk(o, path: str, label: str, keys: list, out: list) -> None:
    """keys에 든 키의 글(또는 글 목록)을 (경로, 이름, 글)로 모은다. 이름 = 가장 가까운 name_ko."""
    if isinstance(o, dict):
        label = o.get("name_ko", label) if isinstance(o.get("name_ko"), str) else label
        for k, v in o.items():
            if k.startswith("_"):
                continue
            p = path + "." + k
            if k in keys and isinstance(v, str) and v.strip():
                out.append((p, label, v))
            elif k in keys and isinstance(v, list):
                for i, s in enumerate(v):
                    if isinstance(s, str):
                        out.append(("%s[%d]" % (p, i), "%s %d" % (label, i + 1), s))
            else:
                walk(v, p, label, keys, out)
    elif isinstance(o, list):
        for i, v in enumerate(o):
            tag = "{%s}" % v["id"] if isinstance(v, dict) and isinstance(v.get("id"), str) else "[%d]" % i
            walk(v, path + tag, label, keys, out)


TOKEN = re.compile(r"\.([^.\[{]+)|\[(\d+)\]|\{([^}]+)\}")


def resolve(doc, path: str):
    """경로의 부모와 마지막 열쇠. 없으면 (None, None)."""
    toks = [(m.group(1), m.group(2), m.group(3)) for m in TOKEN.finditer(path)]
    node = doc
    for n, (key, idx, ident) in enumerate(toks):
        last = n == len(toks) - 1
        if key is not None:
            if not isinstance(node, dict) or key not in node:
                return None, None
            if last:
                return node, key
            node = node[key]
        elif idx is not None:
            i = int(idx)
            if not isinstance(node, list) or i >= len(node):
                return None, None
            if last:
                return node, i
            node = node[i]
        else:
            hit = [e for e in node if isinstance(e, dict) and e.get("id") == ident] if isinstance(node, list) else []
            if len(hit) != 1:
                return None, None
            node = hit[0]
    return None, None


# ---- 모으기 ----
def collect() -> list:
    """[(큰 제목, 작은 제목, [(키, 이름, 글)])]"""
    parts = []
    books = []
    fields = load("data/city.json")["library"]["fields"]
    for f in fields:
        rel = "data/city_info/%s.json" % f["id"]
        entries = []
        for e in load(rel):
            note = "%d등급 거주 · %d층" % (e.get("tier", 1), e.get("floor", 1))
            entries.append(("%s:{%s}.name_ko" % (rel, e["id"]), "제목 (%s)" % note, e["name_ko"]))
            entries.append(("%s:{%s}.text_ko" % (rel, e["id"]), e["name_ko"], e["text_ko"]))
        books.append((f["name_ko"], entries))
    parts.append(("도서관 책", books))
    flavor = []
    for title, pattern, keys in FLAVOR:
        entries = []
        for rel in files(pattern):
            found = []
            walk(load(rel), "", os.path.basename(rel)[:-5], keys, found)
            entries += [("%s:%s" % (rel, p), name, s) for p, name, s in found]
        if entries:
            flavor.append((title.strip(), entries))
    merged = []  # 같은 제목(종족 · 직업)을 하나로
    for title, entries in flavor:
        if merged and merged[-1][0] == title:
            merged[-1][1].extend(entries)
        else:
            merged.append((title, entries))
    parts.append(("플레이버 · 설명 글", merged))
    ko = load(KO)
    groups = {}
    order = []

    found = []

    def walk_ko(o, p):
        if isinstance(o, dict):
            for k, v in o.items():
                if not k.startswith("_"):
                    walk_ko(v, p + [k])
        elif isinstance(o, str) and p[0] not in KO_SKIP and HANGUL.search(o) and SENTENCE.search(o.strip()):
            found.append((p, o))
    walk_ko(ko, [])
    subs = {}
    for p, _ in found:
        if len(p) >= 3:
            subs[(p[0], p[1])] = subs.get((p[0], p[1]), 0) + 1
    for p, o in found:
        g = (p[0], p[1]) if len(p) >= 3 and subs[(p[0], p[1])] >= SUB_MIN else (p[0], "")
        if g not in groups:
            groups[g] = []
            order.append(g)
        groups[g].append(("%s:.%s" % (KO, ".".join(p)), ".".join(p[1:]) or p[0], o))
    situ = []
    for top, sub in order:
        situ.append((KO_NAMES.get(top, top) + (" · " + sub if sub else ""), groups[(top, sub)]))
    parts.append(("상황 문구", situ))
    return parts


# ---- 내보내기 ----
def export(only: str = "") -> None:
    parts = collect()
    md, title, extra = MD, "게임 글 모음 — 도서관 책 · 플레이버 · 상황 문구", []
    if only:
        md, title, keep = SUBSETS[only]
        picked = []
        for big, subs in keep:
            secs = [sec for b, ss in parts if b == big for sec in ss if subs is None or sec[0] in subs]
            picked.append((big, secs))
        parts = picked
        extra = [
            "> - **장비의 글**: 아이템 파일에 있는 장비(강철 검 등)는 \"아이템\"의 글이 그대로 보인다. "
            "무작위로 생기는 장비는 \"장비 종류\"(생김새) + 빈 줄 + \"장비 소재\"(내력)를 이어 붙여 보인다(ItemForge).",
            "> - 나머지 글(몬스터·정수·상태·상황 문구 …)은 `docs/TEXTS.md`. 적용 명령은 같다: `python3 tools/texts_md.py --apply --md=docs/TEXTS_BOOKS_ITEMS.md`.",
        ]
    total = sum(len(e) for _, secs in parts for _, e in secs)
    lines = [
        "# " + title,
        "",
        "> 게임에 나오는 읽을거리를 한 파일에 모았다(%d개). **고친 뒤 이 파일을 보내 주면 바뀐 글만 게임에 넣는다**(`python3 tools/texts_md.py --apply --md=%s`)." % (total, os.path.relpath(md, ROOT).replace(os.sep, "/")),
        "> - 항목 = `#### 이름 · \\`파일:경로\\`` 줄 + 그 아래 글. **`####` 줄(특히 \\` \\` 안 경로)은 바꾸지 말고, 아래 글만** 고친다. 글은 여러 줄이어도 된다(다음 `#` 줄 전까지가 한 글).",
        "> - `{이름}`은 자리표시자(게임이 값을 넣는다) — 그대로 둔다(바꾸면 그 줄은 적용하지 않는다). `\\n`이 필요한 자리는 그냥 줄을 바꿔 쓴다.",
        "> - 대화창은 **한 쪽에 한 문장**이다(UI44) — 문장을 끊으면 Enter 한 번씩 넘어간다.",
        "> - 도서관 책: 고서 문체, **숫자·%·괄호·존댓말 금지**(CT52). 거주 등급·층은 제목 줄에 적혀 있다(바꾸지 않는다).",
        "> - 항목을 지우거나 새로 써도 게임에는 들어가지 않는다(새 글은 따로 말해 주면 데이터에 더한다). 버튼·이름 같은 짧은 화면 글은 `docs/STRINGS.md`, 이름(`name_ko`)은 각 데이터 파일.",
    ] + extra + [
        "",
        "## 차례",
        "",
    ]
    for big, secs in parts:
        lines.append("- **%s** — " % big + " · ".join("%s(%d)" % (t, len(e)) for t, e in secs))
    for big, secs in parts:
        lines += ["", "## " + big]
        for title, entries in secs:
            lines += ["", "### " + title]
            for key, name, text in entries:
                lines += ["", "#### %s · `%s`" % (name.replace("\n", " "), key), text]
    with open(md, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print("%d개 → %s" % (total, os.path.relpath(md, ROOT)))


# ---- 적용 ----
def parse(md: str) -> dict:
    out = {}
    key = None
    buf = []

    def flush():
        if key is not None:
            out[key] = "\n".join(buf).strip("\n").strip()

    with open(md, encoding="utf-8") as f:
        for raw in f.read().splitlines():
            m = HEAD.match(raw)
            if m:
                flush()
                key, buf = m.group(2), []
            elif raw.startswith("#"):
                flush()
                key, buf = None, []
            elif key is not None:
                buf.append(raw.rstrip())
    flush()
    return out


def apply(md: str, dry: bool) -> None:
    edited = parse(md)
    current = {k: t for _, secs in collect() for _, e in secs for k, _, t in e}
    unknown = [k for k in edited if k not in current]
    changes = {k: v for k, v in edited.items() if k in current and v != current[k]}
    skipped = []
    by_file = {}
    for k, v in changes.items():
        rel, path = k.split(":", 1)
        if rel == KO and sorted(PLACEHOLDER.findall(v)) != sorted(PLACEHOLDER.findall(current[k])):
            skipped.append((k, "자리표시자가 달라졌다"))
            continue
        if not v:
            skipped.append((k, "빈 글"))
            continue
        by_file.setdefault(rel, []).append((path, current[k], v))
    for rel, items in sorted(by_file.items()):
        full = os.path.join(ROOT, rel)
        with open(full, encoding="utf-8") as f:
            text = f.read()
        doc = json.loads(text)
        rewrite = False
        for path, old, new in items:
            parent, last = resolve(doc, path)
            parent[last] = new
            o, n = json.dumps(old, ensure_ascii=False), json.dumps(new, ensure_ascii=False)
            if text.count(o) == 1:
                text = text.replace(o, n)
            else:
                rewrite = True
            print("  %s:%s" % (rel, path))
        if dry:
            continue
        if rewrite:
            text = json.dumps(doc, ensure_ascii=False, indent=2) + "\n"
            print("  ! %s — 같은 글이 여럿이라 파일을 다시 썼다(모양이 바뀌었을 수 있다)" % rel)
        else:
            assert json.loads(text) == doc, rel
        with open(full, "w", encoding="utf-8") as f:
            f.write(text)
    n = sum(len(v) for v in by_file.values())
    print("%s %d개 (파일 %d)" % ("바뀔 글" if dry else "바꾼 글", n, len(by_file)))
    for k, why in skipped:
        print("  건너뜀 %s — %s" % (k, why))
    if unknown:
        print("  모르는 항목 %d개(무시): %s" % (len(unknown), ", ".join(unknown[:8])))
    if not dry and n:
        print("다음: ko.json을 바꿨으면 strings_md.gd로 STRINGS.md를 다시 만들고, texts_md.py로 이 파일도 다시 만든 뒤 tools/check.sh")


def main() -> None:
    args = dict((a.lstrip("-").split("=", 1) + [""])[:2] for a in sys.argv[1:])
    md = args.get("md") or MD
    if "apply" in args:
        apply(md, "dry" in args)
    elif args.get("only"):
        export(args["only"])
    else:
        export()
        for name in SUBSETS:  # 일부만 뽑은 파일도 함께 새로 쓴다(어긋나지 않게)
            export(name)


if __name__ == "__main__":
    main()
