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
		out[id] = tween(frames, seq, float(a.get("fps", 3.0)), float(data.get("_tween_fps", 10.0)))
		out[id]["kit"] = kit
	return out


## 사이 칸 채우기(사용자 2026-11-01 "NPC 애니메이션이 너무 어색하다" — 2~3칸이 툭툭 바뀌었다): seq 한 걸음을 k+1 칸으로 나누고,
## 다른 자세로 넘어가는 걸음은 그 사이를 관절·손 자리 보간(부드럽게 — smoothstep)으로 채운다. 같은 자세가 이어지는 걸음은 그 칸을 k+1번.
## 걸음 길이(1/fps)는 그대로라 동작 빠르기는 같다. k = 화면 칸 빠르기(_tween_fps) ÷ fps − 1(1~3).
static func tween(keys: Array, seq: Array, fps: float, target_fps: float) -> Dictionary:
	var k := clampi(roundi(target_fps / maxf(0.1, fps)) - 1, 1, 3)
	var frames: Array = keys.duplicate()
	var out_seq: Array = []
	var made := {}
	for i in seq.size():
		var a := int(seq[i])
		var b := int(seq[(i + 1) % seq.size()])
		out_seq.append(a)
		for j in range(1, k + 1):
			if a == b:
				out_seq.append(a)
				continue
			var key := "%d>%d>%d" % [a, b, j]
			if not made.has(key):
				var t := float(j) / float(k + 1)
				made[key] = frames.size()
				frames.append(blend(keys[a], keys[b], t * t * (3.0 - 2.0 * t)))
			out_seq.append(made[key])
	return {"frames": frames, "seq": out_seq, "fps": fps * (k + 1)}


## 두 칸(PartyMotion 형식 — p 관절 · ik 손 자리 · turn …)을 t만큼 섞는다. 숫자는 보간, 글자(d 앞뒤)·한쪽에만 있는 값은 가까운 쪽.
static func blend(a: Variant, b: Variant, t: float) -> Variant:
	if (a is float or a is int) and (b is float or b is int):
		return lerpf(float(a), float(b), t)
	if a is Array and b is Array and (a as Array).size() == (b as Array).size():
		var arr: Array = []
		for i in (a as Array).size():
			arr.append(blend(a[i], b[i], t))
		return arr
	if a is Dictionary and b is Dictionary:
		var d := {}
		for key: Variant in a:
			d[key] = blend(a[key], b[key], t) if (b as Dictionary).has(key) else a[key]
		for key: Variant in b:
			if not d.has(key):
				d[key] = b[key]
		return d
	return a if t < 0.5 else b


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
