extends RefCounted
## 3D 몸(Back)이 손에 드는 일 도구(도시 실내 NPC 동작 — tools/paint_actors.gd --acts, CT69):
## hammer 망치 · tongs 집게(kit hot = 달군 쇠, steam = 김) · book 펼친 책(두 손 사이) · broom 빗자루(두 손을 지나 땅까지) · mug 맥주잔 ·
## ladle 국자 · rag 걸레 · quill 깃펜 · coin 동전 · scroll 두루마리.
## kit.weapon = 오른손(weapon_hand) 도구, kit.off_tool = 다른 손 도구. 작은 맵 그림에서도 읽히게 크고 뭉툭하게.

const Clay := preload("res://tools/monster_art/Clay.gd")
const Back := preload("res://tools/monster_art/Back.gd")

const KINDS := ["hammer", "tongs", "book", "broom", "mug", "ladle", "rag", "quill", "coin", "scroll"]


static func draw(cl: Clay, pr: Dictionary, j: Dictionary, kit: Dictionary, sp: Dictionary) -> void:
	var main := str(kit.get("weapon_hand", "r"))
	var off := "l" if main == "r" else "r"
	for slot: Array in [["weapon", main], ["off_tool", off]]:
		var kind := str(kit.get(slot[0], ""))
		if KINDS.has(kind):
			_one(cl, pr, j, kind, str(slot[1]), kit, sp)


static func _one(cl: Clay, pr: Dictionary, j: Dictionary, kind: String, t: String, kit: Dictionary, sp: Dictionary) -> void:
	var hd: Vector3 = j["hand_" + t]
	var el: Vector3 = j["elbow_" + t]
	var fore := (hd - el).normalized()
	var perp := fore.cross(Vector3(0, 0, 1))
	perp = perp.normalized() if perp.length() > 0.2 else Vector3(1, 0, 0)
	var g := cl.group()
	var wood := cl.mat(Color("#6a4a2e"), "wood")
	var metal := cl.mat(Color("#7a7e84"), "metal")
	var skin := cl.mat(sp.get("skin", Color("#c49a78")), str(sp.get("skin_kind", "skin")))
	match kind:
		"hammer":
			var end := hd + fore * 0.12
			Back.cap(cl, pr, g, hd - fore * 0.03, end, 0.011, 0.011, wood, 0.002)
			Back.cap(cl, pr, g, end - perp * 0.045, end + perp * 0.035, 0.026, 0.024, metal, 0.003)
		"tongs":
			var tip := hd + fore * 0.2
			for s: float in [-1.0, 1.0]:
				Back.cap(cl, pr, g, hd, tip + perp * 0.012 * s, 0.006, 0.005, cl.mat(Color("#3a3a3c"), "metal"), 0.0)
			if kit.get("hot", false):
				Back.cap(cl, pr, g, tip, tip + fore * 0.08, 0.012, 0.01, cl.mat(Color("#ff8a3a"), "glow"), 0.002)
			if kit.get("steam", false):
				var pale := cl.mat(Color("#e8ecec"), "cloth")
				for k in 3:
					Back.ell(cl, pr, g, tip + Vector3(-0.03 + k * 0.03, -0.06 - k * 0.04, 0.0), 0.03, 0.025, 0.02, pale, 0.01)
		"book":
			var c := ((j["hand_l"] as Vector3) + (j["hand_r"] as Vector3)) * 0.5 + Vector3(0, -0.01, -0.01)
			var cover := cl.mat(kit.get("book_c", Color("#5a2a24")), "leather")
			var page := cl.mat(Color("#e0d6bc"), "cloth")
			var tilt := Vector3(0, 0.04, -0.03)  # 아래쪽이 앞으로 — 읽는 얼굴 쪽으로 기운 펼친 책
			Back.cap(cl, pr, g, c - tilt, c + tilt, 0.05, 0.05, cover, 0.004)
			Back.cap(cl, pr, g, c - tilt * 0.8 + Vector3(0, -0.012, 0.016), c + tilt * 0.8 + Vector3(0, -0.012, 0.016), 0.044, 0.044, page, 0.003)
			Back.cap(cl, pr, g, c - tilt * 0.8 + Vector3(0, -0.014, 0.024), c + tilt * 0.8 + Vector3(0, -0.014, 0.024), 0.004, 0.004, cover, 0.0)  # 가운데 접힌 줄
		"broom":
			var a: Vector3 = j["hand_l"]
			var b: Vector3 = j["hand_r"]
			if a.y > b.y:  # 위 손 → 아래 손 방향으로 땅까지
				var tmp := a
				a = b
				b = tmp
			var foot := Vector3(b.x + (b.x - a.x) * 0.6, -0.02, b.z - 0.12)  # 아래 손 앞쪽 땅
			var dir := (foot - a).normalized()
			Back.cap(cl, pr, g, a - dir * 0.08, foot, 0.009, 0.009, wood, 0.002)
			Back.ell(cl, pr, g, foot + Vector3(0, -0.015, 0), 0.07, 0.03, 0.035, cl.mat(Color("#b89a5a"), "hair"), 0.006)
		"mug":
			var base := hd + Vector3(0, 0.01, -0.01)
			Back.cap(cl, pr, g, base, base + Vector3(0, -0.06, 0), 0.026, 0.028, wood, 0.003)
			Back.ell(cl, pr, g, base + Vector3(0, -0.062, 0), 0.026, 0.01, 0.026, cl.mat(Color("#e8dcc0"), "cloth"), 0.002)
		"ladle":
			var end := hd + fore * 0.2
			Back.cap(cl, pr, g, hd - fore * 0.02, end, 0.007, 0.007, wood, 0.002)
			Back.ell(cl, pr, g, end, 0.03, 0.02, 0.03, metal, 0.003)
		"rag":
			Back.ell(cl, pr, g, hd + Vector3(0, 0.02, 0), 0.045, 0.012, 0.035, cl.mat(Color("#b8ac90"), "cloth"), 0.006)
		"quill":
			Back.cap(cl, pr, g, hd + Vector3(0, 0.01, 0), hd + Vector3(0.02, -0.07, 0.01), 0.004, 0.012, cl.mat(Color("#e8e4dc"), "cloth"), 0.002)
		"coin":
			Back.ell(cl, pr, g, hd + Vector3(0, 0.008, -0.01), 0.018, 0.006, 0.018, cl.mat(Color("#c8a048"), "metal"), 0.002)
		"scroll":
			Back.cap(cl, pr, g, hd - perp * 0.05, hd + perp * 0.05, 0.016, 0.016, cl.mat(Color("#d8ccaa"), "cloth"), 0.003)
	Back.ell(cl, pr, g, hd + Vector3(0, 0, 0.005), 0.022, 0.028, 0.02, skin, 0.003)  # 쥔 손(도구 위)
