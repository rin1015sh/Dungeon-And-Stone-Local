extends RefCounted
## 도시 실내 NPC 동작 시트(tools/paint_actors.gd --acts — CT69): 방 JSON 사람의 act마다 그 옷차림으로 동작 칸을 그려
## assets/actors/acts/<옷차림>__<동작>.webp(줄 = 아래·왼쪽·오른쪽·위 — 걷기 시트와 같은 줄, 칸 = 동작 칸) + index.json {이름: {cell, foot, frames, seq, fps}}.
## 동작 정의 = tools/monster_art/npc_acts.json(뒷모습 120px 칸 관절 — PartyMotion이 3D 뼈대로 옮긴다, 전투 동작 칸을 빌릴 수도 있다).

const ACTS := "res://tools/monster_art/npc_acts.json"
const MOTIONS := "res://tools/monster_art/party_motions.json"
const OUT := "res://assets/actors/acts"


## 동작 id → {frames: [칸(PartyMotion 형식)], kit, seq, fps}.
static func load_acts() -> Dictionary:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ACTS))
	var mo: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MOTIONS))
	var rest: Dictionary = ((mo["idle"]["frames"] as Array)[0] as Dictionary)["p"]
	var out := {}
	for id: String in data:
		if id.begins_with("_"):
			continue
		var a: Dictionary = data[id]
		var frames: Array = []
		var kit: Dictionary = (a.get("kit", {}) as Dictionary).duplicate()
		if a.has("from"):
			var m: Dictionary = mo[str(a["from"])]
			for k: Variant in a.get("pick", range((m["frames"] as Array).size())):
				frames.append(((m["frames"] as Array)[int(k)] as Dictionary).duplicate(true))
			if m.has("weapon"):
				kit["weapon"] = m["weapon"]
			kit.merge(m.get("kit", {}) as Dictionary, true)
		else:
			for f: Dictionary in (a["frames"] as Array):
				var fr := f.duplicate(true)
				var p := rest.duplicate(true)
				p.merge(fr.get("set", {}) as Dictionary, true)
				fr["p"] = p
				frames.append(fr)
		var seq: Array = a.get("seq", range(frames.size()))
		out[id] = {"frames": frames, "kit": kit, "seq": seq, "fps": float(a.get("fps", 3.0))}
	return out


## 방 JSON들에서 그릴 [옷차림 이름, 동작] 쌍(옷차림 이름 = look 파일 이름 — looks/<MapLooks id> 또는 종족 시트).
static func wanted(db: GameDatabase) -> Array:
	var seen := {}
	var out: Array = []
	for rid: String in db.get_collection("rooms"):
		for v: Variant in JsonUtil.get_array(db.get_entry("rooms", rid), "npcs"):
			var n: Dictionary = v
			var act := JsonUtil.get_str(n, "act")
			var look := JsonUtil.get_str(n, "look").get_file().get_basename()
			if act.is_empty() or look.is_empty() or seen.has(look + "__" + act):
				continue
			seen[look + "__" + act] = true
			out.append([look, act])
	return out


## 칸 그림들(발 = 아래 가운데) → 한 장. 칸 크기는 가장 큰 그림에 맞춘다. 돌려줌 {sheet, cell}.
static func pack(frames: Dictionary, cols: int) -> Dictionary:
	var cell := Vector2i(8, 8)
	for img: Image in frames.values():
		var u := img.get_used_rect()
		var half := maxi(img.get_width() / 2 - u.position.x, u.end.x - img.get_width() / 2)  # 발 가운데에서 좌우로 같은 폭
		cell.x = maxi(cell.x, half * 2 + 4)
		cell.y = maxi(cell.y, img.get_height() - u.position.y + 2)
	var sheet := Image.create_empty(cell.x * cols, cell.y * 4, false, Image.FORMAT_RGBA8)
	for at: Vector2i in frames:
		var img: Image = frames[at]
		var u := img.get_used_rect()
		var dst := Vector2i(at.x * cell.x + cell.x / 2 - img.get_width() / 2 + u.position.x, at.y * cell.y + cell.y - 2 - (img.get_height() - u.position.y))
		sheet.blit_rect(img, u, dst)
	return {"sheet": sheet, "cell": cell}


static func save_index(index: Dictionary) -> void:
	var path := OUT.path_join("index.json")
	var cur: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
	var all: Dictionary = cur if cur is Dictionary else {}
	all.merge(index, true)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(all, "\t", true))
