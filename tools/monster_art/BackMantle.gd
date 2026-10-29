extends RefCounted
## 망토 위에 얹는 어깨 장식(사용자 2026-10-29 "등 뒤가 허전 — 어깨 털 목도리·가죽 어깨덮개 여러 개로 보여 줘", AM50 — 후보만, 게임 그림은 그대로):
##   capelet {c, kind: fur|leather, len(0 = 어깨 바로 아래 ~ 1 = 가슴 아래), flare(단 폭 배율)} 어깨를 덮고 등 위쪽까지 오는 짧은 겉 망토
##   ruff {c} 목둘레를 감은 두툼한 털 목도리(어깨 위로 넘친다)
##   pads {c, kind: leather|iron, size, sides: "both"|"l"|"r"} 겹 판 어깨받이(BackSavage 어깨받이를 망토 위로 — 크게)
## 등 자락(BackDrape)보다 조금 더 바깥에 빚는다 — 몸 겹 위에 씌우면 망토 등판 안에 묻혀 보이지 않았다.
## kit 키가 없으면 아무것도 하지 않는다.

const Clay := preload("res://tools/monster_art/Clay.gd")
const Back := preload("res://tools/monster_art/Back.gd")
const BackKit := preload("res://tools/monster_art/BackKit.gd")
const BackDrape := preload("res://tools/monster_art/BackDrape.gd")
const BackSavage := preload("res://tools/monster_art/BackSavage.gd")


static func wear(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, kit: Dictionary, rng: RandomNumberGenerator) -> void:
	var under := float((kit.get("cloak", {}) as Dictionary).get("under", 0.0)) if kit.get("cloak") is Dictionary else 0.0
	if kit.has("capelet"):
		_capelet(cl, pr, j, bd, kit["capelet"], under, rng)
	if kit.has("pads"):
		var d: Dictionary = (kit["pads"] as Dictionary).duplicate()
		var sides := str(d.get("sides", "both"))
		for t: String in ["l", "r"]:
			if sides == "both" or sides == t:
				d["side"] = t
				BackSavage._pauldron(cl, pr, j, bd, d, rng)
	if kit.has("ruff"):
		_ruff(cl, pr, j, bd, kit["ruff"], under, rng)


## 짧은 겉 망토: 몸틀(BackDrape._frame)을 따라 어깨 → 단까지 망토 등판보다 조금 바깥에 한 겹, 단은 몸 둘레로 휘고(가운데가 조금 길게)
## 털이면 들쭉날쭉, 가죽이면 매끈한 단 + 단 따라 바늘땀 골.
static func _capelet(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, d: Dictionary, under: float, rng: RandomNumberGenerator) -> void:
	var col: Color = d["c"]
	var fur := str(d.get("kind", "fur")) == "fur"
	var m := cl.mat(col, "fur" if fur else "leather", {"mottle": col.darkened(0.35), "mottle_amt": 0.45 if fur else 0.25})
	var g := cl.group()
	var f := BackDrape._frame(pr, j)
	var rv: Vector3 = f["rv"]
	var bv: Vector3 = f["bv"]
	var ch: Vector3 = j["chest"]
	var nk: Vector3 = j["neck"]
	var bw: float = bd["back_w"] - ch.z
	var shw: float = f["shw"]
	var sy: float = (f["top"] as Vector3).y
	var hem := lerpf(sy + 0.05, ch.y + 0.11, float(d.get("len", 0.5)))
	var flare := float(d.get("flare", 1.0))
	var jag: Array = []
	for i in 40:
		jag.append(rng.randf_range(-0.024, 0.02) if fur else rng.randf_range(-0.003, 0.003))
	var hem_at := func(phi: float) -> float: return hem + 0.02 * sin(phi) - 0.03 * pow(absf(cos(phi)), 1.5) + float(jag[int(absf(phi) * 9.0) % 40])
	var piece := BackKit.hem_poly(f["pr2"], nk.y - 0.2, shw * 1.45 * flare + 0.12, bw + 0.2, hem_at)  # 위는 넉넉히 — 윗선은 캡슐 둥근 끝이 어깨를 따라 정한다(일자로 자르면 네모난 판처럼 보였다)
	var t := 0.022 if fur else 0.012  # 망토 등판(BackDrape ws)보다 바깥
	var z0 := bw * 0.4
	var d0 := bw * 0.68 + 0.03 + under + t
	var spine: Array = [BackDrape._w(f, j, 0, sy + 0.01, z0), BackDrape._w(f, j, 0, (sy + hem) * 0.5, z0), BackDrape._w(f, j, 0, hem + 0.03, z0 + 0.006)]
	var us: Array = [shw * 0.78, shw * 1.02 * flare + 0.035, shw * 1.1 * flare + 0.045]
	var ws: Array = [d0 - 0.01, d0, d0 + 0.006]
	cl.set_clip(piece)
	BackDrape.echain(cl, pr, g, spine, us, ws, m, 0.05, f["pr2"])
	cl.set_clip(PackedVector2Array())
	BackKit.shell(cl, pr, ["shoulder_l", "shoulder_r", "torso", "neck"], 0.024 + under + 0.008, m, g, piece, 0.04, 0.0)  # 어깨 덮개(얇게 — 두꺼우면 어깨가 공처럼 부풀었다)
	var n_lines := 12 if fur else 7
	for k in n_lines:  # 털 결 · 가죽 주름: 어깨에서 단으로 퍼지며
		var phi := PI * (k + rng.randf_range(0.2, 0.8)) / n_lines  # 0 ~ π = 오른쪽 → 등 → 왼쪽
		var n := rv * cos(phi) + bv * sin(phi)
		var p0 := BackDrape._w(f, j, cos(phi) * (shw * 0.7), sy + rng.randf_range(0.0, 0.03), sin(phi) * (d0 + z0) * 0.98)
		var p1 := BackDrape._w(f, j, cos(phi) * (shw * 1.06 * flare + 0.04), float(hem_at.call(phi)) - 0.012, z0 + sin(phi) * (d0 + 0.006))
		Back.groove(cl, pr, g, [p0, p0.lerp(p1, 0.5) + n * 0.004, p1], n, 0.006 if fur else 0.004, 0.01 if fur else 0.006)
	if not fur:  # 단을 따라 박은 바늘땀(가는 골 한 줄)
		var stitch: Array = []
		for i in 13:
			var phi := PI * i / 12.0
			stitch.append(BackDrape._w(f, j, cos(phi) * (shw * 1.05 * flare + 0.04), float(hem_at.call(phi)) - 0.02, z0 + sin(phi) * (d0 + 0.004)))
		Back.groove(cl, pr, g, stitch, bv, 0.003, 0.004)


## 털 목도리: 목을 반 바퀴 넘게 감고 어깨 위로 넘치는 두툼한 털 말이(몸틀 사슬 — 몸을 돌려도 목에 붙는다) + 털 결.
static func _ruff(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, d: Dictionary, under: float, rng: RandomNumberGenerator) -> void:
	var col: Color = d["c"]
	var m := cl.mat(col, "fur", {"mottle": col.darkened(0.4), "mottle_amt": 0.55})
	var g := cl.group()
	var f := BackDrape._frame(pr, j)
	var rv: Vector3 = f["rv"]
	var bv: Vector3 = f["bv"]
	var nk: Vector3 = j["neck"]
	var ch: Vector3 = j["chest"]
	var bw: float = bd["back_w"] - ch.z
	var shw: float = f["shw"]
	var sy: float = (f["top"] as Vector3).y
	var pts: Array = []
	var rr: Array = []
	for i in 13:
		var a := lerpf(-PI * 0.72, PI * 0.72, i / 12.0)  # 0 = 목 뒤 가운데
		var yy := lerpf(nk.y + 0.035, sy - 0.006, pow(absf(sin(a)), 1.5))  # 목 뒤 → 옆으로 갈수록 어깨 위로 내려앉는다
		pts.append(Vector3(nk.x, yy, nk.z) + rv * (sin(a) * shw * 0.9) + bv * (cos(a) * (bw * 1.08 + under + 0.04)))  # 망토 등판(BackDrape) 바깥
		rr.append(0.05 * (1.0 - 0.25 * absf(sin(a))) + rng.randf_range(-0.004, 0.004))
	Back.chain(cl, pr, g, pts, rr, m, 0.03)
	for k in 18:  # 털 결(목에서 바깥으로 처진 골)
		var a := rng.randf_range(-PI * 0.65, PI * 0.65)
		var c := Vector3(nk.x, lerpf(nk.y + 0.035, sy - 0.006, pow(absf(sin(a)), 1.5)), nk.z) + rv * (sin(a) * shw * 0.9) + bv * (cos(a) * (bw * 1.08 + under + 0.085))
		var out := (rv * sin(a) + bv * cos(a)).normalized()
		Back.groove(cl, pr, g, [c - Vector3(0, 0.02, 0), c + out * 0.01 + Vector3(0, 0.02, 0)], out, 0.006, 0.009)
