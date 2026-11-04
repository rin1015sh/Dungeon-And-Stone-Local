extends SceneTree
## 동네 일반 집의 문 자리 뽑기(CT110 — 집 실내를 돌려 쓰고, 지금은 잠겨 있다):
##   godot --headless --path . --script res://tools/town_doors.gd
## 집마다 손그림 집 키트(HouseFit — 게임 그림과 같은 바리에이션 · 크기 · 각도)를 그림 없이(Kit.dry) 세워 문 앞 디딤돌 자리를 지도 칸으로 바꾼다
## → assets/town/houses/doors.json {집 id: {door: [x, y](집 칸 — 그 아래 칸이 문 앞 길), design(바리에이션 함수)}}. TownMap이 읽는다.
## 동네 지도 · 집 그림(paint_town_hand)을 다시 만들었으면 이것도 다시 돌린다.

const HouseFit := preload("res://tools/town_kit/HouseFit.gd")
const Kit := preload("res://tools/town_kit/Kit.gd")
const OUT := "res://assets/town/houses/doors.json"


func _init() -> void:
	Kit.dry = true
	var db := GameDatabase.new()
	db.load_all("res://data")
	var town := TownMap.load_for(db)
	var out := {}
	var miss := 0
	for i in town.houses.size():
		var h: Dictionary = town.houses[i]
		if not str(h.get("facility", "")).is_empty():
			continue
		var node := HouseFit.make(h, i)
		var design := str(node.get_meta("design", ""))
		var best := Vector2i(-1, -1)
		for q: Vector3 in node.get_meta("doors", PackedVector3Array()):
			if q.y > 0.3:
				continue  # 땅 위 문만(돌출 계단 · 높은 단 문은 빼고)
			var c := Vector2i(floori(q.x), floori(q.z - 0.3))
			for d: Vector2i in [Vector2i.ZERO, Vector2i(0, -1), Vector2i.LEFT, Vector2i.RIGHT]:
				var cell := c + d
				if not town.is_walkable(cell) and town.is_walkable(cell + Vector2i.DOWN):
					best = cell
					break
			if best.x >= 0:
				break
		node.free()
		if best.x < 0:
			miss += 1
			continue
		out[str(h["id"])] = {"door": [best.x, best.y], "design": design}
	HouseFit.clear()
	quit(_save(out, miss, town))


func _save(out: Dictionary, miss: int, town: TownMap) -> int:
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify({"_comment": "tools/town_doors.gd가 만든다(손으로 고치지 않는다). 일반 집 문 자리(집 칸 — 아래 칸이 문 앞) · 바리에이션(실내 고르기 — city.json interior.house_kinds, CT110).", "houses": out}, "\t"))
	f.close()
	print("집 문: %d채 · 문 못 찾음 %d채(전체 %d)" % [out.size(), miss, town.houses.size()])
	return 0
