"""동네 배치를 게임 동네 지도 데이터로 내보낸다 — 지금은 블록 도시 v4(tools/town_v4.py, CT100), 옛 v3 안 A 1/4 판(town_v3_small.py, CT95)은 --plan=v3.
  python3 tools/town_v3_export.py [--plan=v3]   → data/town/district7.json
구상 좌표(x −40~40 · z −75~35, 칸)를 지도 칸(x 0~80 · y 0~110)으로 옮긴다. 집 크기 · 각도는 구상 그대로(1칸 = 집 키트 1칸 = 사람 한 칸).
TownMap이 읽는 꼴: bands(단 높이 · 경계선) · areas(poly · line+width · circle · rect) · houses(뒤틀린 집 목록) · buildings(시설 7) · props · places(퀘스트 자리) · sewer.
지도를 바꿨으면 집 그림을 다시 굽는다(tools/paint_town_houses.gd — CLAUDE.md).
"""
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import town_v3 as tv  # noqa: E402
import town_v3_small as small  # noqa: E402
import town_v4 as v4  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "data", "town", "district7.json")
OX, OZ = 40.0, 75.0

PLACE_IDS = {
	1: "plaza", 2: "guild", 3: "settle_tent", 4: "inn", 5: "bank", 6: "temple", 7: "library", 8: "shop", 9: "smithy",
	10: "notice_board", 11: "tavern", 12: "stalls", 13: "herbalist", 14: "well", 15: "laundry", 16: "guard_post",
	17: "graveyard", 18: "poorhouse", 19: "pawnshop", 20: "abandoned_house", 21: "warehouse", 22: "gate",
	23: "sewer_entrance", 24: "black_market", 25: "under_bridge",
}
STYLE = {"temple": ("gothic", 4), "library": ("stone", 3), "guild": ("hall", 3), "bank": ("stone", 3), "inn": ("inn", 3),
		"shop": ("arcade", 2), "smithy": ("workshop", 2)}


def P(x, z):
	return [round(x + OX, 2), round(z + OZ, 2)]


def pts(line):
	return [P(x, z) for x, z in line]


def floors_of(top: float) -> int:
	return max(1, min(4, int(round((top - tv.top_of(0)) / 1.15))))


def main():
	blocks = "--plan=v3" not in sys.argv
	tv.set_extent(*small.EXTENT, 8)
	t, _notes = v4.plan_v4() if blocks else small.plan_a_small()
	catalog = v4.CATALOG if blocks else small.CATALOG_S
	p = t.p
	# v4: 블록 사이 땅은 모두 돌길, 안뜰만 흙(막힌 안뜰은 TownMap이 정원으로) · v3: 길 밖 땅 = 흙 뒷마당(CT98)
	areas = [{"kind": "street" if blocks else "yard", "poly": pts(p.outline)}]
	for line, w, lv in p.channels:
		areas.append({"kind": "water", "line": pts(line), "width": w, "h": lv})
	main_roads = [t.st["main"][0], t.st["main_s"][0]]
	for line, w in getattr(t, "mains", []):  # 큰길(바닥 굽기가 반듯한 돌로 — CT103)
		areas.append({"kind": "street", "line": pts(line), "width": w, "main": True})
	for line, w in p.streets:
		areas.append({"kind": "avenue" if line in main_roads else "street", "line": pts(line), "width": w})
	areas.append({"kind": "street", "poly": pts([(-40, 28.5), (40, 28.5), (40, 35), (-40, 35)])})  # 수로 남쪽 둑길
	plaza_sq = [(-13, -31.5), (13, -31.5), (13, -11), (-13, -11)]
	market = [(-9, -6.6), (9, -6.6), (9, 4.5), (-9, 4.5)]
	for poly in p.pavings:
		if len(poly) <= 6:
			e = {"kind": "paving", "poly": pts(poly)}
			if blocks and poly in (plaza_sq, market):
				e["pattern"] = "diag"  # 광장 · 시장 = 비스듬한 격자 판석(길과 다른 포장, CT103)
			areas.append(e)
	if blocks:
		for poly in getattr(t, "pockets", []):  # 모퉁이 쉼터(판석)
			areas.append({"kind": "paving", "poly": pts(poly)})
	for poly in p.yards:
		areas.append({"kind": "yard", "poly": pts(poly)})
	for line, w, _h in p.bridges:
		areas.append({"kind": "bridge", "line": pts(line), "width": w})
	if blocks:
		for poly in t.piers:  # 강변 나무 부두(걷는다 · 높이는 아랫단 그대로 — 물 높이로 가라앉지 않게)
			areas.append({"kind": "bridge", "poly": pts(poly), "wood": True, "h": v4.LOWH})
	cx, cz = t.plaza_at
	areas.append({"kind": "plaza", "circle": P(cx, cz) + [8.0]})
	areas.append({"kind": "dais", "circle": P(cx, cz) + [3.4]})
	for h in p.houses:  # 시설 문 앞 돌 마당(2칸)
		if h.get("facility"):
			(ax, az), (bx, bz) = h["front"]
			areas.append({"kind": "paving", "poly": pts([(ax, az), (bx, bz), (bx, bz + 2.0), (ax, az + 2.0)])})
	for x0, z0, x1, z1, _hi, _lo in p.stairs:
		a, b = P(x0, z0), P(x1, z1)
		areas.append({"kind": "stairs", "rect": [math.floor(a[0]), math.floor(a[1]), math.ceil(b[0]), math.ceil(b[1])]})
	for gid, rc in (t.gates if blocks else [("north", (7, -75, 13, -72)), ("west", (-40, -12, -38, -7))]):
		a, b = P(rc[0], rc[1]), P(rc[2], rc[3])
		areas.append({"kind": "gate", "rect": [int(a[0]), int(a[1]), int(b[0]), int(b[1])], "id": gid, "travel": True})

	houses, buildings, props = [], [], []
	for h in p.houses:
		kind = h["kind"]
		poly = h["poly"]
		mx, mz = sum(q[0] for q in poly) / 4, sum(q[1] for q in poly) / 4
		if kind == "post":  # 묘비
			props.append({"kind": "grave", "at": [[int(mx + OX), int(mz + OZ)]]})
			continue
		if kind == "shed":  # 노점
			props.append({"kind": "crate", "at": [[int(mx + OX), int(mz + OZ)]]})
			continue
		num = h.get("num", 0)
		fid = h.get("facility", "")
		if fid:
			xs = [q[0] + OX for q in poly]
			zs = [q[1] + OZ for q in poly]
			r = [math.floor(min(xs)), math.floor(min(zs)), math.ceil(max(xs)), math.ceil(max(zs))]
			style, fl = STYLE[fid]
			buildings.append({"facility": fid, "rect": r, "style": style, "floors": fl, "door": [int((r[0] + r[2]) / 2), r[3] - 1]})
			continue
		if num == 3:
			props.append({"kind": "tent", "rect": [int(mx + OX) - 2, int(mz + OZ) - 1, int(mx + OX) + 2, int(mz + OZ) + 1]})
			continue
		if num == 10:
			props.append({"kind": "board", "rect": [int(mx + OX) - 1, int(mz + OZ), int(mx + OX) + 1, int(mz + OZ) + 1]})
			continue
		w, d = h.get("wd", (4, 4))
		e = {"center": P(mx, mz), "size": [round(w, 2), round(d, 2)], "angle": round(-float(h.get("yaw", 0.0)), 2), "floors": floors_of(h["top"])}
		if num:
			e["place"] = PLACE_IDS[num]
		if h.get("zone"):
			e["zone"] = h["zone"]
		houses.append(e)
	for x, z, r, _top, name in p.rounds:
		if name == "도서관":
			c = P(x, z)
			buildings.append({"facility": "library", "circle": [c[0], c[1], r], "style": "rotunda", "floors": 3,
							"door": [int(c[0]), int(math.floor(c[1] + r - 0.5))]})
	for x, z, _r, _h, _c in p.discs:
		if (x, z) != t.plaza_at:
			props.append({"kind": "well", "at": [[int(x + OX), int(z + OZ)]]})
	props.append({"kind": "lamp", "ring": P(cx, cz) + [7.2, 6]})
	for kind, x, z, w, d in t.props:  # 쓰임새 자리의 거리 소품(town_v3_small.dress — CT98)
		gx, gz = x + OX, z + OZ
		x0, z0 = int(math.floor(gx - w / 2 + 0.5)), int(math.floor(gz - d / 2 + 0.5))
		props.append({"kind": kind, "rect": [x0, z0, max(x0 + 1, int(math.floor(gx + w / 2 + 0.5))), max(z0 + 1, int(math.floor(gz + d / 2 + 0.5)))]})
	places = []
	for num, spots in sorted(t.places.items()):
		cat = next(c for c in catalog if c[0] == num)
		places.append({"id": PLACE_IDS[num], "name_ko": cat[1], "at": [P(x, z) for x, z in spots], "hook_ko": cat[4]})
	bands = [{"h": h, "line": pts(line)} for line, h in p.bands[:-1]] + [{"h": p.bands[-1][1]}]
	out = {
		"_comment": "도시 동네 지도 — 라비기온 7구역 v4 블록 도시(CT100 — 2026-11-03 사용자 \"흩뿌려진 거 말고 맨 처음 기획한 것처럼 딱딱 맞아떨어지게, 각도 비튼 버전이 들어가게, 실제 도시처럼\" · docs/plans/city_town_v3.md §13). "
		"tools/town_v3_export.py가 tools/town_v4.py에서 만든다 — 손으로 고치지 말고 배치 파일을 고쳐 다시 내보낸다. 좌표 = 칸(x 동, y 남). "
		"bands = 단(위에서부터 · line = 그 단의 남쪽 경계, 마지막은 경계 없음 · h = 높이(칸) — 3/4 화면에서 위로 올려 그린다, 경계 칸은 옹벽, 길이 넘는 곳은 계단). "
		"areas는 순서대로 칠한다(poly = 다각형 · line + width = 길 · circle · rect, h = 그 칸 높이를 따로). houses = 블록 둘레 줄집(가운데 · 폭 · 깊이 · 각도(도, + = 시계 방향) · 층, place = 퀘스트 자리). "
		"buildings = 시설(문 = 앞면 맨 아래 줄). places = 퀘스트 · 거리 사건 자리(지금은 자리만). sewer = 하수도 굴 · 입구(땅 밑 — 지금은 자리만).",
		"id": "district7",
		"name_ko": "라비기온 7구역",
		"size": [80, 110],
		"start": [int(v) for v in P(*t.start)] if blocks else [40, 58],
		"seed": 7,
		"bands": bands,
		"areas": areas,
		"houses": houses,
		"buildings": buildings,
		"props": props,
		"places": places,
		"sewer": {"tunnels": [pts(s) for s in p.sewers], "entrances": next(pl["at"] for pl in places if pl["id"] == "sewer_entrance")},
		"source": "original",
	}
	with open(OUT, "w", encoding="utf-8") as f:
		json.dump(out, f, ensure_ascii=False, indent="\t")
		f.write("\n")
	print("wrote", OUT, "houses", len(houses), "buildings", len(buildings), "props", len(props), "areas", len(areas))


if __name__ == "__main__":
	main()
