"""balance_sheet.py가 만든 표(Table 묶음)를 파일로 쓴다 — all_stats.md · .xlsx · .html.
    직접 돌리지 않는다: python3 tools/balance_sheet.py
"""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_MD = os.path.join(ROOT, "docs", "balance", "all_stats.md")
OUT_XLSX = os.path.join(ROOT, "docs", "balance", "all_stats.xlsx")
OUT_HTML = os.path.join(ROOT, "docs", "balance", "all_stats.html")
VIEW = os.path.join(ROOT, "tools", "balance_sheet_view.html")
CHECK_NOTE = "몬스터: 생명력 곡선比 60~140% · 주스탯 70~130% 밖(성격 ±30%는 의도라 그 밖만) / 정수: 기준 합·생명력 75~125% 밖. 기준 = 수치를 매길 때 쓴 곡선 목표(restat_monsters)."
# 화면 탭: (id, 이름, 개수 글, [시트 이름…]) — 시트 이름은 balance_sheet.py의 Table.sheet. 첫 시트가 처음 보이는 표가 아니면 MAIN_SHEET
TABS = [
    ("monsters", "몬스터", "{몬스터}종", ["몬스터", "등급별 평균", "등급별 잡몹", "몬스터 스킬", "몬스터 패시브"]),
    ("bosses", "보스", "{보스}종", ["보스", "보스 스킬"]),
    ("essences", "정수", "{정수}종", ["정수", "정수 등급별", "정수 스킬"]),
    ("statuses", "상태이상", "{상태이상}종", ["상태이상"]),
    ("gear", "장비", "{장비 전체}개", ["무기 단계", "방어구 단계", "장비 전체", "공식 밖 장비", "장비 배율"]),
    ("items", "아이템", "{쓰는 아이템}+{그 밖의 아이템}개", ["쓰는 아이템", "그 밖의 아이템"]),
    ("player", "플레이어", "종족·레벨", ["기준 탐험가", "레벨", "종족", "직업"]),
    ("rules", "공식·점검", "점검 {점검}건", []),
]
LABEL = {"몬스터": "전체 목록", "등급별 평균": "등급 × 구분 평균", "등급별 잡몹": "등급별 잡몹 평균", "몬스터 스킬": "스킬", "몬스터 패시브": "패시브",
         "보스": "보스·정예 스탯", "보스 스킬": "스킬", "정수": "전체 목록", "정수 등급별": "등급별 평균", "정수 스킬": "스킬", "상태이상": "전체 목록",
         "무기 단계": "무기 × 단계", "방어구 단계": "방어구 × 단계", "장비 전체": "전체 목록", "공식 밖 장비": "공식 밖 장비", "장비 배율": "단계 배율",
         "쓰는 아이템": "포션·음식·도구", "그 밖의 아이템": "재료·마석·잡동사니", "기준 탐험가": "층별 기준 탐험가", "레벨": "레벨", "종족": "종족", "직업": "직업"}


def merged_sheets(sections: list) -> dict:
    """시트 이름 → {headers, rows, note} (같은 시트 이름의 표는 줄을 잇는다 — 지역별 몬스터 표 등)."""
    out = {}
    for _head, tables in sections:
        for t in tables:
            name = t.sheet or t.title
            if name in out:
                out[name]["rows"] += t.rows
            else:
                out[name] = {"headers": list(t.headers), "rows": list(t.rows), "note": t.note}
    return out


# 내려받아 바로 여는 파일은 완전한 문서여야 한다(charset이 없으면 한글이 깨지고, doctype이 없으면 쿼크 모드).
# 화면 틀(VIEW)은 Artifact 게시용 조각이라 껍데기를 여기서 씌운다 — 게시 서버가 씌우는 것과 같은 기본값.
DOC_HEAD = ('<!doctype html>\n<html lang="ko">\n<head>\n<meta charset="utf-8">\n'
            '<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">\n'
            "<style>*,*::before,*::after{box-sizing:border-box}body{margin:0;font-size:14px}img{max-width:100%}[hidden]{display:none!important}</style>\n")


def write_html(sections: list, formulas: list, chk: list, fragment_path: str = "") -> None:
    sheets = merged_sheets(sections)
    counts = {k: len(v["rows"]) for k, v in sheets.items()}
    counts["점검"] = len(chk)
    tabs = []
    for tid, name, count, names in TABS:
        tabs.append({"id": tid, "name": name, "count": re.sub(r"\{([^}]+)\}", lambda m: str(counts.get(m.group(1), 0)), count),
                     "sheets": [{"name": n, "label": LABEL.get(n, n), "headers": sheets[n]["headers"], "rows": sheets[n]["rows"], "note": sheets[n]["note"]}
                                for n in names if n in sheets]})
    missing = set(sheets) - {n for t in TABS for n in t[3]}
    if missing:
        print("화면 탭에 없는 시트(balance_sheet_out.TABS에 더한다): %s" % ", ".join(sorted(missing)))
    data = {"tabs": tabs, "formulas": formulas, "checks": chk, "check_note": CHECK_NOTE}
    blob = json.dumps(data, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
    with open(VIEW, encoding="utf-8") as f:
        page = f.read()
    assert "/*DATA*/null" in page
    page = page.replace("/*DATA*/null", blob)
    if fragment_path:  # Artifact 게시용(껍데기 없는 조각)
        with open(fragment_path, "w", encoding="utf-8") as f:
            f.write(page)
    head, sep, body = page.partition('<div class="wrap">')
    assert sep, "화면 틀에 <div class=\"wrap\">가 있어야 한다"
    with open(OUT_HTML, "w", encoding="utf-8") as f:
        f.write(DOC_HEAD + head.rstrip() + "\n</head>\n<body>\n" + sep + body.rstrip() + "\n</body>\n</html>\n")


def md_cell(v) -> str:
    if isinstance(v, float):
        v = "%g" % v
    elif isinstance(v, int) and abs(v) >= 10000:
        v = "{:,}".format(v)
    return str(v).replace("|", "\\|").replace("\n", " ")


def write_md(sections: list, formulas: list, chk: list) -> None:
    w = ["# 밸런스 총정리 — 몬스터 · 보스 · 정수 · 상태이상 · 아이템 · 플레이어", "",
         "> `python3 tools/balance_sheet.py`가 `data/*.json`에서 만든다 — **손으로 고치지 않는다**(데이터를 바꿨으면 다시 돌린다).",
         "> 같은 표를 시트별로 정렬·필터해 보려면 `docs/balance/all_stats.xlsx`. 곡선(기준값) = `docs/balance/curve.md`, 공식 설명 = `docs/balance/stats.md`.",
         "> 수치 대부분이 임시값(`source: placeholder`). '곡선比'는 계획한 기준값 대비 — 100%면 계획대로, 크면 강하다.", "",
         "## 목차", "", "0. 공식 · 6. 자동 점검(맨 위로 올림) · 1. 플레이어 기준 · 2. 몬스터(등급별 평균 → 보스 → 전체 → 스킬·패시브) · 3. 정수 · 4. 상태이상 · 5. 아이템", "",
         "## 0. 공식(지금 데이터 값)", ""] + ["- " + x for x in formulas] + ["", "## 6. 자동 점검 — 곡선에서 많이 벗어난 것", "",
         "> 몬스터: 생명력 곡선比 60~140% · 주스탯 70~130% 밖(성격 ±30%는 의도라 그 밖만) / 정수: 기준 합·생명력 75~125% 밖. 기준 = 수치를 매길 때 쓴 곡선 목표(restat_monsters).", ""]
    w += ["- " + x for x in chk] + [""]
    for head, tables in sections:
        w += ["## " + head, ""]
        for t in tables:
            w += ["### " + t.title, ""]
            if t.note:
                w += ["> " + t.note, ""]
            w.append("| " + " | ".join(t.headers) + " |")
            w.append("|" + "---|" * len(t.headers))
            w += ["| " + " | ".join(md_cell(c) for c in row) + " |" for row in t.rows]
            w.append("")
    with open(OUT_MD, "w", encoding="utf-8") as f:
        f.write("\n".join(w))


def xl_row(row: list) -> list:
    """'104%' 같은 글자는 숫자(1.04)로 — 엑셀에서 정렬·필터가 되게(표시는 % 서식)."""
    out = []
    for v in row:
        if isinstance(v, str) and re.fullmatch(r"-?\d+(\.\d+)?%", v):
            out.append(float(v[:-1]) / 100.0)
        else:
            out.append(v)
    return out


def write_xlsx(sections: list, formulas: list, chk: list) -> bool:
    try:
        from openpyxl import Workbook
        from openpyxl.styles import Alignment, Font, PatternFill
        from openpyxl.utils import get_column_letter
    except ImportError:
        print("openpyxl 없음 — xlsx는 건너뜀(pip install openpyxl)")
        return False
    wb = Workbook()
    ws = wb.active
    ws.title = "공식·점검"
    ws.append(["밸런스 총정리 — tools/balance_sheet.py가 data/*.json에서 만든다(손으로 고치지 않는다)"])
    ws.append([])
    ws.append(["공식"])
    for x in formulas:
        ws.append([x])
    ws.append([])
    ws.append(["자동 점검"])
    for x in chk:
        ws.append([x.replace("**", "")])
    ws.column_dimensions["A"].width = 160
    head_fill = PatternFill("solid", fgColor="DDD6C8")
    sheets = {}
    for _head, tables in sections:
        for t in tables:
            name = (t.sheet or t.title)[:31]
            if name in sheets:
                sh = sheets[name]
                for row in t.rows:
                    sh.append(xl_row(row))
                continue
            sh = wb.create_sheet(name)
            sheets[name] = sh
            sh.append(t.headers)
            for c in sh[1]:
                c.font = Font(bold=True)
                c.fill = head_fill
                c.alignment = Alignment(wrap_text=True, vertical="top")
            for row in t.rows:
                sh.append(xl_row(row))
            sh.freeze_panes = "C2" if len(t.headers) > 6 else "A2"
            sh.auto_filter.ref = "A1:%s1" % get_column_letter(len(t.headers))
    for sh in sheets.values():
        for row in sh.iter_rows(min_row=2):
            for c in row:
                if isinstance(c.value, float) and c.column_letter and isinstance(sh.cell(1, c.column).value, str) and ("比" in sh.cell(1, c.column).value or "→" in sh.cell(1, c.column).value):
                    c.number_format = "0%"
        for i, col in enumerate(sh.iter_cols(min_row=1, max_row=min(sh.max_row, 200)), start=1):
            width = max(len(str(c.value)) if c.value is not None else 0 for c in col)
            sh.column_dimensions[get_column_letter(i)].width = max(6, min(60, width * 1.6 + 2))
    wb.save(OUT_XLSX)
    return True


