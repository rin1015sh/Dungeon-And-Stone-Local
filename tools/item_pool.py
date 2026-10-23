"""아이템 풀 공식(제안 — 게임에 아직 적용 안 함). 실행하면 docs/balance/item_pool.md·item_pool.csv를 다시 만든다.
    python3 tools/item_pool.py

공식(사용자 요청 2026-10-23 "아이템 종류 × 소재 등급으로 스탯, 종류마다 특색, 높은 소재일수록 증가율만 커지게"):
  장비 = 종류(검·창·판금 갑옷 …) × 소재(강철·미스티움 …)
  공격력·증가 스탯 = round(종류 기본값 × 등급 배율 GROW[등급])        — 소재가 높을수록 커진다
  감소 스탯       = 종류 값 그대로(등급과 무관)                        — 소재 특성(가벼움·무거움)만 바꾼다
  소재 특성       = 소재마다 붙는 고정 효과(아래 MATERIALS의 trait)
  구입가          = 2,000 × 종류 가격 계수 × 소재 종류 계수 × 등급 가격 배율 PRICE[등급] × 소재 개별 계수
  판매가          = 구입가 × 0.5 (data/city.json 상점 sell_ratio)
가격 단위는 지금 게임 돈 단위(CT43 — 원작 시세 ÷ 25). ×25 하면 원작 시세 근처(아이릴제 장검 48만 × 25 = 1,200만).
"""
import csv
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

GROW = {1: 1.0, 2: 1.6, 3: 2.3, 4: 3.1, 5: 4.0, 6: 5.0}           # 증가 스탯·공격력 배율
PRICE = {1: 1, 2: 25, 3: 240, 4: 900, 5: 2500, 6: 15000}           # 등급 가격 배율(강철 장검 2,000 기준)
BASE_PRICE = 2000
SELL_RATIO = 0.5
KIND_PRICE = {"metal": 1.0, "leather": 0.8, "wood": 0.7, "cloth": 0.6, "bone": 0.5, "gem": 1.2}
KIND_KO = {"metal": "금속", "leather": "가죽", "wood": "목재", "cloth": "천", "bone": "뼈", "gem": "보석"}
WHERE = {1: "대장간·상점", 2: "대장간 주문(4층 탐험가급)", 3: "시중 거래", 4: "시중 거래", 5: "주문 제작(억 단위 — 원작)", 6: "시중에 거의 없음"}

STAT_KO = {"str": "근력", "agi": "민첩", "p_res": "물리내성", "m_res": "항마력", "int": "정신력", "sight": "시각",
           "natural_regen": "자연재생력", "soul_regen": "영혼 재생력", "accuracy": "명중률",
           "affinity_fire": "화염 감응도", "affinity_cold": "냉기 감응도", "resist_fire": "화염 내성", "resist_cold": "냉기 내성",
           "resist_poison": "독 내성", "resist_dark": "어둠 내성", "max:hp": "생명력", "max:soul": "영혼력",
           "dmg_dealt:slash": "주는 참격 피해", "dmg_dealt:pierce": "주는 관통 피해", "dmg_dealt:blunt": "주는 타격 피해", "dmg_taken:physical": "받는 물리 피해", "dmg_taken:magical": "받는 마법 피해"}
PCT = {"dmg_dealt:slash", "dmg_dealt:pierce", "dmg_dealt:blunt", "dmg_taken:physical", "dmg_taken:magical"}

# 소재: id, 이름, 등급, 종류, 출처(원작/창작), 특성 {"mods": {대상: 값}, "agi_pen": 배율, "stat_mult": {대상: 배율}, "atk": 배율}, 가격 계수, 설명
M = [
    # ── 금속 ──
    ("steel", "강철", 1, "metal", "원작", {}, 1.0, "1단계 금속. 기준"),
    ("lightium", "라이티늄", 2, "metal", "원작", {"agi_pen": 0.5}, 1.0, "강철보다 2배 가볍고 단단한 흰 금속 — 민첩 감소 절반"),
    ("airilje", "아이릴제", 3, "metal", "원작", {"weapon_mods": {"dmg_dealt:weapon": 0.10}}, 1.0, "미스릴+강철 합금, 트롤 가죽도 벤다 — 무기면 그 무기 피해 유형으로 주는 피해 +10%"),
    ("idium", "아이디움", 3, "metal", "원작", {"armor_mods": {"dmg_taken:physical": -0.05}}, 0.9, "3단계 금속 — 방어구·방패면 받는 물리 피해 −5%"),
    ("moonstone", "월광석", 4, "metal", "원작", {"mods": {"resist_dark": 3}}, 1.0, "아크와 부딪혀도 몇 번은 버티는 내구 — 어둠 내성 +3(내구도 규칙이 생기면 내구 ×2)"),
    ("orichalcum", "오리하르콘", 4, "metal", "원작(등급 미상 → 4단계 가정)", {"mods": {"int": 2}}, 1.0, "마력이 잘 통한다 — 정신력 +2"),
    ("mithril", "미스릴", 5, "metal", "원작", {"agi_pen": 0.5, "mods": {"m_res": 2}}, 1.0, "5단계 금속, 가볍다 — 민첩 감소 절반·항마력 +2"),
    ("adamantium", "아다만티움", 5, "metal", "원작", {"agi_pen": 1.5, "armor_mods": {"dmg_taken:magical": -0.5}, "atk": 1.1}, 1.1,
     "무겁다(민첩 감소 ×1.5) — 방어구면 받는 마법(속성) 피해 −50%, 무기면 공격력 ×1.1"),
    ("mystium", "미스티움", 6, "metal", "원작", {"mods": {"str": 1, "agi": 1, "p_res": 1, "m_res": 1, "int": 1}}, 1.0, "왕가에 납품되는 6단계 금속 — 주 스탯 모두 +1"),
    ("ark", "아크", 6, "metal", "원작", {"mods": {"dmg_taken:magical": -0.3}}, 2.0, "청은색, 마법의 카운터 — 받는 마법 피해 −30%. 용인만 다룬다(살 수 없다)"),
    # ── 가죽 ──
    ("tanned", "무두질 가죽", 1, "leather", "창작", {}, 1.0, "1단계 가죽. 기준"),
    ("wyvern", "와이번 가죽", 2, "leather", "원작", {"mods": {"agi": 1}}, 1.0, "2단계 가죽 — 민첩 +1"),
    ("troll_hide", "트롤 가죽", 3, "leather", "창작(원작에 질긴 가죽으로 나옴)", {"mods": {"natural_regen": 2}}, 1.0, "자연재생력 +2"),
    ("drake", "드레이크 가죽", 4, "leather", "원작(등급 미상 → 4단계 가정)", {"stat_mult": {"p_res": 0.5, "m_res": 2.0}, "mods": {"m_res": 2}}, 1.0,
     "항마력 보정이 크고 물리에 약하다 — 물리내성 증가 ×0.5, 항마력 증가 ×2 +2"),
    ("ogre", "오우거 가죽", 5, "leather", "원작", {"mods": {"max:hp": 15}}, 1.0, "5단계 가죽 — 생명력 +15"),
    ("elder_dragon", "고룡 가죽", 6, "leather", "창작", {"mods": {"resist_fire": 5, "resist_cold": 5}}, 1.0, "화염·냉기 내성 +5"),
    # ── 목재 ──
    ("oak", "참나무", 1, "wood", "창작", {}, 1.0, "1단계 목재. 기준"),
    ("redwood", "레드우드", 2, "wood", "원작", {"mods": {"accuracy": 3}}, 1.0, "2단계 목재 — 명중률 +3"),
    ("ironwood", "흑철목", 3, "wood", "창작", {"atk": 1.1}, 1.0, "쇠처럼 무거운 검은 나무 — 공격력 ×1.1"),
    ("bortal", "보르탈 나무", 4, "wood", "원작", {"mods": {"soul_regen": 2}}, 1.0, "4단계 목재 — 영혼 재생력 +2"),
    ("artene", "아르테네목", 5, "wood", "원작(최상급 선박재 → 5단계 가정)", {"stat_mult": {"p_res": 1.2}}, 1.0, "엄청 단단하다 — 물리내성 증가 ×1.2"),
    ("world_tree", "세계수", 6, "wood", "원작", {"mods": {"natural_regen": 3, "soul_regen": 3}}, 1.0, "6단계 목재 — 자연·영혼 재생력 +3"),
    # ── 천 ──
    ("linen", "리넨", 1, "cloth", "창작", {}, 1.0, "1단계 천. 기준"),
    ("spider_silk", "거미 비단", 2, "cloth", "창작", {"mods": {"resist_poison": 2}}, 1.0, "독 내성 +2"),
    ("frost_wool", "서리 양모", 3, "cloth", "창작", {"mods": {"resist_cold": 3}}, 1.0, "냉기 내성 +3"),
    ("moon_silk", "월광 비단", 4, "cloth", "창작", {"mods": {"resist_dark": 3}}, 1.0, "월광석 가루를 먹인 비단 — 어둠 내성 +3"),
    ("spirit_silk", "정령 비단", 5, "cloth", "창작", {"mods": {"soul_regen": 2}}, 1.0, "영혼 재생력 +2"),
    ("world_fiber", "세계수 섬유", 6, "cloth", "창작", {"mods": {"natural_regen": 3}}, 1.0, "자연재생력 +3"),
    # ── 뼈 ──
    ("beast_bone", "짐승 뼈", 1, "bone", "창작", {}, 1.0, "1단계 뼈. 기준"),
    ("troll_bone", "트롤 뼈", 3, "bone", "원작", {"mods": {"natural_regen": 2}}, 1.0, "3단계 소재 — 자연재생력 +2"),
    ("drake_bone", "드레이크 뼈", 5, "bone", "창작", {"mods": {"m_res": 2}}, 1.0, "항마력 +2"),
    # ── 보석(장신구) ──
    ("quartz", "수정", 1, "gem", "창작", {}, 1.0, "1단계 보석. 기준"),
    ("amber", "호박", 2, "gem", "창작", {"mods": {"resist_fire": 2}}, 1.0, "화염 내성 +2"),
    ("jade", "비취", 3, "gem", "창작", {"mods": {"resist_poison": 3}}, 1.0, "독 내성 +3"),
    ("obsidian", "흑요석", 4, "gem", "창작", {"mods": {"resist_dark": 3}}, 1.0, "어둠 내성 +3"),
    ("bloodstone", "용혈석", 5, "gem", "창작", {"mods": {"affinity_fire": 3}}, 1.0, "화염 감응도 +3"),
    ("bluestone", "블루스톤", 6, "gem", "원작", {"mods": {"soul_regen": 3, "affinity_cold": 3}}, 1.0, "6층 대해의 최상급 소재 — 영혼 재생력·냉기 감응도 +3"),
]
MATERIALS = [dict(zip(["id", "name", "tier", "kind", "source", "trait", "price_mult", "note"], m)) for m in M]

# 종류: id, 이름, 칸, 분류, 소재 종류, 무기 {피해, 공격력, 양손, 원거리}, 증가(등급 배율), 감소(고정), 가격 계수, 크기, 특색
T = [
    # ── 무기(주무기) ──
    ("dagger", "단검", "main_hand", "weapon", ["metal", "bone"], {"type": "pierce", "atk": 6}, {"agi": 1, "accuracy": 5}, {}, 0.4, [1, 2], "가볍고 정확하다, 공격력 낮음"),
    ("sword", "장검", "main_hand", "weapon", ["metal"], {"type": "slash", "atk": 10}, {"accuracy": 3}, {}, 1.0, [1, 3], "기준 — 감소 없음"),
    ("greatsword", "대검", "main_hand", "weapon", ["metal"], {"type": "slash", "atk": 17, "two_handed": True}, {"str": 1}, {"agi": -2}, 1.8, [1, 4], "양손, 강하지만 느리다"),
    ("axe", "도끼", "main_hand", "weapon", ["metal"], {"type": "slash", "atk": 12}, {"str": 1}, {"accuracy": -5}, 0.9, [1, 3], "세지만 빗나간다"),
    ("mace", "철퇴", "main_hand", "weapon", ["metal", "bone"], {"type": "blunt", "atk": 11}, {"p_res": 1}, {"agi": -1}, 0.8, [1, 3], "타격(뼈·갑옷), 약간 느리다"),
    ("warhammer", "전투 망치", "main_hand", "weapon", ["metal"], {"type": "blunt", "atk": 19, "two_handed": True}, {"str": 2}, {"agi": -3, "accuracy": -5}, 1.6, [1, 4], "양손, 가장 무겁다"),
    ("spear", "창", "main_hand", "weapon", ["metal"], {"type": "pierce", "atk": 13}, {}, {"agi": -2}, 1.1, [1, 4], "공격력이 오르나 민첩이 준다(사용자 예)"),
    ("halberd", "미늘창", "main_hand", "weapon", ["metal"], {"type": "slash", "atk": 18, "two_handed": True}, {"p_res": 1}, {"agi": -3}, 1.7, [1, 4], "양손, 베기·막기"),
    ("club", "곤봉", "main_hand", "weapon", ["wood", "bone"], {"type": "blunt", "atk": 8}, {"str": 1}, {"accuracy": -3}, 0.3, [1, 3], "싸고 투박하다"),
    ("bow", "활", "main_hand", "weapon", ["wood"], {"type": "pierce", "atk": 9, "two_handed": True, "ranged": True}, {"accuracy": 5}, {}, 0.9, [1, 4], "원거리(후열), 공격력 낮음"),
    ("crossbow", "석궁", "main_hand", "weapon", ["wood", "metal"], {"type": "pierce", "atk": 15, "two_handed": True, "ranged": True}, {"accuracy": 3}, {"agi": -2}, 1.3, [2, 3], "원거리, 장전이 느리다"),
    ("staff", "지팡이", "main_hand", "weapon", ["wood"], {"type": "blunt", "atk": 4, "two_handed": True}, {"int": 2, "m_res": 1}, {"str": -1}, 1.0, [1, 4], "마법 쪽, 근접이 약하다"),
    # ── 보조 ──
    ("buckler", "소형 방패", "off_hand", "armor", ["metal", "wood"], None, {"p_res": 2}, {}, 0.5, [2, 2], "가볍다"),
    ("shield", "방패", "off_hand", "armor", ["metal", "wood", "bone"], None, {"p_res": 4}, {"agi": -1}, 0.9, [2, 2], "기준 방패"),
    ("tower_shield", "대형 방패", "off_hand", "armor", ["metal", "wood"], None, {"p_res": 7, "max:hp": 10}, {"agi": -3}, 1.6, [2, 3], "벽처럼 막는다, 느리다"),
    # ── 몸 ──
    ("padded", "누비 갑옷", "body", "armor", ["cloth"], None, {"p_res": 2, "max:hp": 5}, {}, 0.6, [2, 3], "가볍다"),
    ("robe", "로브", "body", "armor", ["cloth"], None, {"m_res": 3, "int": 1}, {"p_res": -1}, 0.8, [2, 3], "마법 쪽, 물리에 약하다"),
    ("leather_armor", "가죽 갑옷", "body", "armor", ["leather"], None, {"p_res": 3, "m_res": 1}, {}, 1.0, [2, 3], "기준 갑옷"),
    ("chainmail", "사슬 갑옷", "body", "armor", ["metal"], None, {"p_res": 6}, {"agi": -2}, 1.8, [2, 3], "무겁다"),
    ("plate", "판금 갑옷", "body", "armor", ["metal"], None, {"p_res": 10, "max:hp": 10}, {"agi": -4}, 3.0, [2, 3], "가장 단단하고 가장 무겁다"),
    # ── 머리 ──
    ("hood", "두건", "head", "armor", ["cloth", "leather"], None, {"p_res": 1}, {}, 0.2, [2, 2], "가볍다"),
    ("helm", "투구", "head", "armor", ["metal"], None, {"p_res": 3}, {"sight": -1}, 0.6, [2, 2], "시야가 좁다"),
    ("greathelm", "통투구", "head", "armor", ["metal"], None, {"p_res": 5, "max:hp": 5}, {"sight": -2, "agi": -1}, 1.0, [2, 2], "단단하지만 앞이 잘 안 보인다"),
    # ── 손·발·허리·망토 ──
    ("gloves", "장갑", "hands", "armor", ["leather"], None, {"str": 1, "accuracy": 2}, {}, 0.2, [2, 2], "손이 미끄러지지 않는다"),
    ("gauntlets", "건틀릿", "hands", "armor", ["metal"], None, {"p_res": 2, "str": 1}, {"agi": -1}, 0.5, [2, 2], "단단한 손"),
    ("boots", "장화", "feet", "armor", ["leather"], None, {"agi": 1}, {}, 0.25, [2, 2], "가볍다"),
    ("sabatons", "쇠 장화", "feet", "armor", ["metal"], None, {"p_res": 2}, {"agi": -1}, 0.5, [2, 2], "무겁다"),
    ("belt", "허리띠", "waist", "armor", ["leather"], None, {"p_res": 1, "max:hp": 5}, {}, 0.15, [2, 1], "기준"),
    ("cloak", "망토", "cloak", "armor", ["cloth", "leather"], None, {"resist_cold": 2, "m_res": 1}, {}, 0.3, [2, 2], "추위·마법을 조금 막는다"),
    # ── 장신구 ──
    ("ring", "반지", "ring", "armor", ["gem", "metal"], None, {"m_res": 1}, {}, 0.5, [1, 1], "소재 특성이 핵심"),
    ("amulet", "목걸이", "neck", "armor", ["gem", "bone"], None, {"max:soul": 3}, {}, 0.5, [1, 1], "영혼력"),
]
TYPES = [dict(zip(["id", "name", "slot", "category", "kinds", "weapon", "grow", "penalty", "price_mult", "size", "note"], t)) for t in T]

# 소재를 쓰지 않는 아이템(지금 게임 값 + 새로 넣을 것). 구입가는 상점 값, 판매가 = ×0.5. new = 아직 게임에 없음.
PLAIN = [
    # id, 이름, 분류, 구입가, 효과, 새것
    ("torch", "횃불", "빛", 10000, "빛 반경 4m, 72시간", False),
    ("torch_stub", "타다 남은 횃불", "빛", 500, "짧게 탄다", False),
    ("lantern", "랜턴", "빛", 25000, "빛 반경 5m, 기름 한 병 120시간(꺼도 남는다)", True),
    ("lamp_oil", "램프 기름", "빛", 1500, "랜턴 다시 채우기", True),
    ("ration", "휴대 식량", "음식", 300, "허기 회복", False),
    ("stone_bread", "돌빵", "음식", 20, "허기 조금", False),
    ("leftovers", "먹다 남은 음식", "음식", 10, "허기 조금", False),
    ("crystal_mushroom", "수정 버섯", "음식", 50, "허기 조금 + 상태", False),
    ("spring_water", "샘물", "음식", 5, "피로 회복", False),
    ("minor_potion", "하급 포션", "포션", 3000, "생명력 회복", False),
    ("medium_potion", "중급 포션", "포션", 8000, "생명력 회복(크게)", False),
    ("greater_potion", "상급 포션", "포션", 20000, "생명력 크게 회복 + 출혈 멈춤", True),
    ("soul_potion", "영혼 포션", "포션", 6000, "영혼력 회복", True),
    ("antidote", "해독제", "포션", 1500, "중독 풀기", True),
    ("bandage", "붕대", "도구", 400, "출혈 멈춤 + 생명력 조금", True),
    ("smoke_bomb", "연막탄", "도구", 4000, "전투에서 도주 확률 +30%p(한 번)", True),
    ("whetstone", "숫돌", "도구", 800, "다음 전투 동안 무기 공격력 +2", True),
    ("explorer_tag", "탐험가 신원패", "전리품", 1000, "길드에 반납", False),
    ("gnome_trinket", "노움 장신구", "전리품", 800, "팔 물건", False),
]


def grow_mult(tier: int) -> float:
    return GROW[tier]


def nice(v: float) -> int:
    """두 자리 유효숫자로 반올림(가격표처럼)."""
    if v < 100:
        return int(round(v / 5.0) * 5) or 5
    digits = len(str(int(v))) - 2
    return int(round(v / 10 ** digits) * 10 ** digits)


def build(t: dict, m: dict) -> dict:
    tier = m["tier"]
    trait = m["trait"]
    g = grow_mult(tier)
    stats: dict = {}
    smult = trait.get("stat_mult", {})
    for k, v in t["grow"].items():
        stats[k] = stats.get(k, 0) + max(1, round(v * g * smult.get(k, 1.0)))
    for k, v in t["penalty"].items():
        pen = v
        if k == "agi" and "agi_pen" in trait:
            pen = -int(abs(v) * trait["agi_pen"] + (0.5 if trait["agi_pen"] > 1 else 0))  # 가벼움 = 내림, 무거움 = 올림
        if pen != 0:
            stats[k] = stats.get(k, 0) + pen
    extra = dict(trait.get("mods", {}))
    if t["category"] == "weapon":
        for k, v in trait.get("weapon_mods", {}).items():
            extra[k.replace(":weapon", ":" + t["weapon"]["type"])] = v
    else:
        extra.update(trait.get("armor_mods", {}))
    for k, v in extra.items():
        stats[k] = stats.get(k, 0) + v
    out = {"type": t, "mat": m, "stats": stats}
    if t["weapon"]:
        out["atk"] = round(t["weapon"]["atk"] * g * trait.get("atk", 1.0))
    price = BASE_PRICE * t["price_mult"] * KIND_PRICE[m["kind"]] * PRICE[tier] * m["price_mult"]
    out["buy"] = nice(price)
    out["sell"] = nice(out["buy"] * SELL_RATIO)
    return out


def fmt_stats(st: dict) -> str:
    parts = []
    for k, v in st.items():
        if k in PCT:
            parts.append("%s %+d%%" % (STAT_KO[k], round(v * 100)))
        elif v != 0:
            parts.append("%s %+d" % (STAT_KO.get(k, k), v))
    return " · ".join(parts)


def won(v: int) -> str:
    return "{:,}".format(v)


def main() -> None:
    rows = []
    for t in TYPES:
        for m in MATERIALS:
            if m["kind"] in t["kinds"]:
                rows.append(build(t, m))
    md = []
    md.append("# 아이템 풀 — 종류 × 소재 공식 (2026-10-23 제안, 게임에 아직 적용 안 함)\n")
    md.append("> 생성: `python3 tools/item_pool.py`(공식·표는 이 스크립트가 정본 — 이 파일은 손으로 고치지 않는다). 같은 내용 CSV: `docs/balance/item_pool.csv`.")
    md.append("> 사용자 요청: \"아이템 종류(검·철퇴·창)와 소재 등급(강철·미스티움 …)으로 스탯이 오르게, 종류마다 특색(창 = 공격력↑ 민첩↓), 높은 소재일수록 증가율만 커지게, 감소는 알아서\".\n")
    md.append("## 1. 공식\n")
    md.append("| 값 | 공식 |\n|---|---|")
    md.append("| 공격력·**증가** 스탯 | 종류 기본값 × 등급 배율(아래) — 반올림, 최소 1 |")
    md.append("| **감소** 스탯 | 종류 값 그대로(등급과 무관) — 소재 특성 '가벼움'(라이티늄·미스릴 ×0.5)·'무거움'(아다만티움 ×1.5)만 바꾼다 |")
    md.append("| 소재 특성 | 소재마다 고정 효과(등급 배율을 받지 않는다) |")
    md.append("| 구입가 | %s × 종류 가격 계수 × 소재 종류 계수 × 등급 가격 배율 × 소재 개별 계수 → 유효숫자 두 자리 |" % won(BASE_PRICE))
    md.append("| 판매가 | 구입가 × %.1f(상점 `sell_ratio`) |\n" % SELL_RATIO)
    md.append("| 등급 | 1 | 2 | 3 | 4 | 5 | 6 |\n|---|---|---|---|---|---|---|")
    md.append("| 증가 배율 | " + " | ".join("×%.1f" % GROW[i] for i in range(1, 7)) + " |")
    md.append("| 가격 배율 | " + " | ".join("×%s" % won(PRICE[i]) for i in range(1, 7)) + " |")
    md.append("| 구하는 곳 | " + " | ".join(WHERE[i] for i in range(1, 7)) + " |\n")
    md.append("소재 종류 가격 계수: " + " · ".join("%s ×%.1f" % (KIND_KO[k], v) for k, v in KIND_PRICE.items()) + ".\n")
    md.append("**돈 단위**: 지금 게임 돈(CT43 — 원작 시세 ÷ 25). 기준점: 강철 장검 2,000(지금 값 그대로) · 아이릴제(3단계) 장검 480,000(원작 1,200만 ÷ 25) · "
              "5단계 장검 5,000,000(원작 1억 2,500만 — '억 단위로 시작') · 6단계는 그 6배. 원작 시세로 쓰려면 모든 가격 ×25.\n")
    md.append("**규모 감각**: 1층 원정 한 번 벌이 약 36,000(`tools/sim_income.gd`). 2단계 장검(50,000)은 원정 한두 번, 3단계는 1층에서는 사실상 못 산다 — 원작처럼 '4층 탐험가쯤 돼야 2단계'에 가깝다.\n")
    md.append("## 2. 소재 (원작 = 사용자가 준 설정, 창작 = 빈 등급을 채운 것)\n")
    md.append("| 등급 | 소재 | 종류 | 출처 | 특성 |\n|---|---|---|---|---|")
    for m in sorted(MATERIALS, key=lambda x: (x["tier"], list(KIND_KO).index(x["kind"]))):
        md.append("| %d | %s | %s | %s | %s |" % (m["tier"], m["name"], KIND_KO[m["kind"]], m["source"], m["note"]))
    md.append("\n## 3. 종류 (1단계 기준 값 — 증가는 등급 배율을 받고, 감소는 고정)\n")
    md.append("| 종류 | 칸 | 쓰는 소재 | 피해·공격력 | 증가 | 감소 | 가격 계수 | 특색 |\n|---|---|---|---|---|---|---|---|")
    for t in TYPES:
        w = t["weapon"]
        wtxt = ""
        if w:
            wtxt = "%s %d%s%s" % ({"slash": "참격", "pierce": "관통", "blunt": "타격"}[w["type"]], w["atk"], " 양손" if w.get("two_handed") else "",
                                  " 원거리" if w.get("ranged") else "")
        md.append("| %s | %s | %s | %s | %s | %s | ×%.2f | %s |" % (t["name"], t["slot"], "·".join(KIND_KO[k] for k in t["kinds"]), wtxt,
                                                                  fmt_stats(t["grow"]), fmt_stats(t["penalty"]) or "없음", t["price_mult"], t["note"]))
    md.append("\n## 4. 전체 목록 (종류 × 소재)\n")
    md.append("이름 = 소재 + 종류(예: 라이티늄 창). 같은 등급에 금속이 둘이면 둘 다 있다.\n")
    for t in TYPES:
        md.append("### %s\n" % t["name"])
        md.append("| 등급 | 이름 | %s스탯 | 구입가 | 판매가 |\n|---|---|%s---|---:|---:|" % (("공격력 | ", "---:|") if t["weapon"] else ("", "")))
        for r in [x for x in rows if x["type"] is t]:
            m = r["mat"]
            atk = ("%d | " % r["atk"]) if t["weapon"] else ""
            buy = won(r["buy"]) + ("(살 수 없음)" if m["id"] == "ark" else "")
            md.append("| %d | %s %s | %s%s | %s | %s |" % (m["tier"], m["name"], t["name"], atk, fmt_stats(r["stats"]), buy, won(r["sell"])))
        md.append("")
    md.append("## 5. 소재를 쓰지 않는 아이템\n")
    md.append("| 이름 | 분류 | 효과 | 구입가 | 판매가 | |\n|---|---|---|---:|---:|---|")
    for p in PLAIN:
        md.append("| %s | %s | %s | %s | %s | %s |" % (p[1], p[2], p[4], won(p[3]), won(nice(p[3] * SELL_RATIO)), "새로" if p[5] else "지금 있음"))
    md.append("\n그 밖에 값이 정해진 것(이 공식 밖): 마석(화폐처럼 제값 — 9등급 80 … 5등급 4,000), 균열 히든 피스·넘버스(초록 보석 120,000·네크로노미콘 160,000 — 팔 물건, "
              "여신의 눈물·폭약·뿔피리 — 균열 밖 반출 불가, 팔지 못함), 계층보구(뼈 대검 — 팔지 못함). 넘버스·계층보구는 공식보다 강하다(소재 6단계 위).\n")
    md.append("## 6. 지금 장비와 비교 (적용하면 바뀌는 것)\n")
    md.append("| 지금 아이템 | 지금 | 공식(1단계) |\n|---|---|---|")
    now = [("강철 검", "참격 10", "sword", "steel"), ("강철 창", "관통 12", "spear", "steel"), ("철퇴", "타격 10", "mace", "steel"),
           ("사냥 단검", "관통 7 · 민첩 +1", "dagger", "steel"), ("사냥 활", "관통 9 원거리 · 민첩 +1", "bow", "oak"),
           ("가죽 갑옷", "물리내성 +2", "leather_armor", "tanned"), ("누비 갑옷", "물리내성 +3 · 민첩 −1", "padded", "linen"),
           ("철 투구", "물리내성 +2", "helm", "steel"), ("나무 방패", "물리내성 +3", "shield", "oak"), ("가죽 장갑", "근력 +1", "gloves", "tanned"),
           ("가죽 장화", "민첩 +1", "boots", "tanned"), ("가죽 허리띠", "물리내성 +1", "belt", "tanned"), ("여행 망토", "물리내성 +1", "cloak", "linen"),
           ("가죽 두건", "물리내성 +1", "hood", "tanned")]
    by = {(r["type"]["id"], r["mat"]["id"]): r for r in rows}
    for name, cur, tid, mid in now:
        r = by[(tid, mid)]
        atk = ("%s %d · " % ({"slash": "참격", "pierce": "관통", "blunt": "타격"}[r["type"]["weapon"]["type"]], r["atk"])) if r["type"]["weapon"] else ""
        md.append("| %s | %s | %s%s (%s스톤) |" % (name, cur, atk, fmt_stats(r["stats"]), won(r["buy"])))
    md.append("\n## 7. 게임에 넣는다면\n")
    md.append("- 데이터: `data/materials.json`(소재 — 등급·종류·특성·가격 계수) + `data/item_types.json`(종류 — 칸·무기·증가·감소·가격 계수) + `balance.json items.grow/price`(등급 배율). "
              "아이템 JSON은 `{\"type\": \"spear\", \"material\": \"lightium\"}`만 두고 `ItemForge`(새 파일)가 장비 수치·가격을 계산한다 — 공식을 바꾸면 모든 장비가 따라 바뀐다.")
    md.append("- 지금 장비 14개는 같은 id로 1단계 소재를 붙여 바꾼다(저장 호환). 넘버스·계층보구·히든 피스는 공식 밖(손으로 쓴 수치)으로 둔다.")
    md.append("- 대장간 진열: 1단계 전부 + 2단계 몇 개(주문 — 비쌈). 3단계 이상은 지금 1층만 있어 진열하지 않는다(2층 이후·균열 보상 후보).")
    md.append("- 새 효과가 필요한 것: 주는/받는 피해 % 수정자(이미 있음 — `dmg_dealt:`·`dmg_taken:`), 랜턴 기름·숫돌·연막탄(새 효과 3개), 내구도(원작 월광석 — 규칙 없음, 보류).")
    with open(os.path.join(ROOT, "docs", "balance", "item_pool.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(md) + "\n")
    with open(os.path.join(ROOT, "docs", "balance", "item_pool.csv"), "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["종류", "소재", "등급", "칸", "피해 유형", "공격력", "스탯", "구입가", "판매가"])
        for r in rows:
            t = r["type"]
            w.writerow([t["name"], r["mat"]["name"], r["mat"]["tier"], t["slot"], t["weapon"]["type"] if t["weapon"] else "", r.get("atk", ""),
                        fmt_stats(r["stats"]), r["buy"], r["sell"]])
        for p in PLAIN:
            w.writerow([p[1], "", "", p[2], "", "", p[4], p[3], nice(p[3] * SELL_RATIO)])
    print("종류 %d × 소재 → 장비 %d개 + 일반 %d개" % (len(TYPES), len(rows), len(PLAIN)))


if __name__ == "__main__":
    main()
