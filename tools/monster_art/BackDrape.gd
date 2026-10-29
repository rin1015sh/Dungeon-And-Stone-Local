extends RefCounted
## 몸에 맞춰 떨어지는 망토(사용자 2026-10-29 "망토를 그대로 얹지 말고 살짝 코트 그린다는 느낌으로 — 몸 체형과 맞아떨어지게"):
## 따로 빚은 원뿔을 몸에 씌우지 않고, 외투처럼 몸 부위 기록(어깨·몸통·엉덩이·허벅지)을 부풀린 한 겹 + 등 뒤로 곧게 떨어지는 자락(견갑골 → 단,
## 엉덩이 골·다리 사이로 파고들지 않게)으로 빚는다. 앞은 목 아래에서 단으로 갈수록 벌어지게 트여(몸 둘레 각도로 — 어느 쪽에서 봐도 맞는 자리) 옷이 보인다.
##   cloak {c, len(0 = 엉덩이 ~ 1 = 발목), flare(단 폭), open(앞 트임 배율), clasp(목 여밈 쇠 색), collar(젖힌 두건), fur}
##   under = 안에 입은 겹 두께 · belt = 겉허리띠(BackCloak이 누빔·사슬·외투·겉허리띠를 보고 채운다)
## 옛 원뿔 망토는 cloak에 cone: true(BackCloak._cloak).

const Clay := preload("res://tools/monster_art/Clay.gd")
const Back := preload("res://tools/monster_art/Back.gd")
const BackKit := preload("res://tools/monster_art/BackKit.gd")

const GROW := 0.024        ## 몸 위로 부풀리는 두께(외투 0.02보다 조금 두껍게)
const OPEN_TOP := 0.32     ## 목 아래 앞 트임 반각(라디안 — 0 = 가운데 한 줄)
const OPEN_BOT := 0.95     ## 단의 앞 트임 반각(open 배율을 곱한다)


static func drape(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, d: Dictionary, rng: RandomNumberGenerator) -> void:
	var col: Color = d["c"]
	var m := cl.mat(col, "fur" if d.get("fur", false) else "cloth", {"mottle": col.darkened(0.3), "mottle_amt": 0.35})
	var g := cl.group()
	var B := Vector3(0, 0, 1)
	var nk: Vector3 = j["neck"]
	var pv: Vector3 = j["pelvis"]
	var ch: Vector3 = j["chest"]
	var bw: float = bd["back_w"]
	var shw := absf(j["shoulder_r"].x)
	var sy: float = j["shoulder_r"].y
	var H: float = pr["H"]
	var hem := lerpf(pv.y, -0.04, float(d.get("len", 0.6)))
	var flare := float(d.get("flare", 1.15))
	var band := BackKit.band(cl, pr, nk.y - 0.2, hem, rng, 0.01, 16)
	var pieces: Array = [band]
	var open := float(d.get("open", 1.0))
	if open > 0.0:
		var hole := _opening(cl, pr, j, bd, nk.y + 0.012, hem + 0.06, open)
		if hole.size() >= 3:
			pieces = Geometry2D.clip_polygons(band, hole)
	var tags := ["torso", "pelvis", "thigh_l", "thigh_r"]
	if not j.get("map_face", false):  # 맵 몸: 큰 머리 밑 목까지 덮으면 앞모습에서 턱수염처럼 보인다
		tags.append("neck")
	var under := float(d.get("under", 0.0))  # 안에 입은 두꺼운 겹(누빔·사슬·외투)만큼 더 띄운다
	var belt := 0.025 if d.get("belt", false) else 0.0  # 겉허리띠: 등 자락만 더 띄워 덮는다(몸 겹까지 띄우면 윗몸이 부풀었다)
	# 등 뒤 자락: 견갑골에서 단까지 곧게(폭은 어깨 바깥 → 단에서 flare만큼), 몸 뒤쪽에 중심을 두어 앞으로는 몸통 겹 안에 숨는다
	var z0 := bw * 0.4
	var spine: Array = [Vector3(0, sy + 0.01, z0), Vector3(0, ch.y, z0), Vector3(0, pv.y, z0), Vector3(0, hem, z0)]
	var us: Array = [shw + 0.015, shw + 0.035, shw * flare + 0.04, shw * flare + 0.07]
	var ws: Array = [bw * 0.75 + under, bw * 0.62 + 0.02 + under, bw * 0.62 + 0.05 + under + belt, bw * 0.62 + 0.055 + under + belt]  # 엉덩이·허리띠 위로 곧게
	for piece: PackedVector2Array in pieces:
		if Geometry2D.is_polygon_clockwise(piece) != Geometry2D.is_polygon_clockwise(band):
			continue  # 구멍 다각형은 빚을 자리가 아니다
		BackKit.shell(cl, pr, tags, GROW + under, m, g, piece, 0.05, 0.0)
		BackKit.shell(cl, pr, ["shoulder_l", "shoulder_r"], GROW * 0.45 + under, m, g, piece, 0.05, 0.0)  # 어깨는 얇게(두꺼우면 어깨가 공처럼 부풀었다)
		cl.set_clip(piece)
		echain(cl, pr, g, spine, us, ws, m, 0.05)
		cl.set_clip(PackedVector2Array())
	for k in 9:  # 등 세로 주름: 견갑골 아래에서 단으로 조금씩 퍼진다
		var u := lerpf(-0.8, 0.8, (k + rng.randf_range(0.25, 0.75)) / 9.0)
		var p0 := Vector3(u * shw * 0.8, ch.y - 0.02 + rng.randf_range(0.0, 0.05), bw + GROW + under)
		var p1 := Vector3(u * (shw * flare + 0.06), hem - 0.01, z0 + float(ws[3]))
		Back.groove(cl, pr, g, [p0, p0.lerp(p1, 0.5) + Vector3(0, 0, 0.004), p1], B, 0.005, 0.008)
	for s: float in [-1.0, 1.0]:  # 옆구리로 흘러내리는 주름(옆에서 보인다)
		for k in 3:
			var p0 := Vector3(s * (shw + 0.02), sy + 0.04 + k * 0.03, 0.02 - k * 0.025)
			var p1 := Vector3(s * (shw * flare + 0.06), hem - 0.01, 0.04 - k * 0.03)
			Back.groove(cl, pr, g, [p0, p0.lerp(p1, 0.5), p1], Vector3(s, 0, 0.2), 0.006, 0.01)
	for k in 5:  # 해진 단
		var a := rng.randf_range(-PI, 0.0)
		cl.erase(g, Back.P2(pr, Vector3(cos(a) * (shw * flare + 0.06), hem - rng.randf_range(0.0, 0.015), z0 - sin(a) * float(ws[3]))), rng.randf_range(0.005, 0.012) * H, rng.randf_range(0.01, 0.022) * H, 0.5)
	var front := ch.z - 0.066 * float(bd["dep"]) - GROW
	if d.has("clasp"):  # 트임 양쪽 위 끝을 잇는 여밈 쇠 둘 + 사슬
		var metal := cl.mat(d["clasp"], "metal")
		for s: float in [-1.0, 1.0]:
			Back.bump(cl, pr, g, Vector3(s * shw * 0.32, nk.y + 0.035, front + 0.012), Vector3(0, 0, -1), 0.014, 0.014, 0.008, metal)
		Back.ridge(cl, pr, g, [Vector3(-shw * 0.3, nk.y + 0.04, front + 0.01), Vector3(0, nk.y + 0.05, front + 0.004), Vector3(shw * 0.3, nk.y + 0.04, front + 0.01)], Vector3(0, 0, -1), 0.003, 0.003, metal)
	if d.get("collar", false):  # 목 뒤로 젖힌 두건: 목둘레를 감는 두툼한 천(등에 붙인 뾰족한 자락은 문장(▽)처럼 보여 뺐다)
		var hg := cl.group()
		Back.ell(cl, pr, hg, Vector3(0, nk.y + 0.02, bw * 0.7 + under), shw * 0.72, 0.045, 0.06, m, 0.02)


## 앞 트임 화면 다각형: 몸 둘레(타원)에서 앞 가운데 ±반각(위 → 아래로 벌어짐)의 보는 사람 쪽 부분만 높이마다 왼쪽·오른쪽 끝을 찍는다.
## 위·아래로는 화면 끝까지 늘려(band에서 구멍이 아니라 왼쪽·오른쪽 두 조각이 남게) 돌려준다. 보이는 앞면이 없으면(뒷모습) 빈 배열.
static func _opening(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, v0: float, v1: float, open: float) -> PackedVector2Array:
	var c: float = pr["c"]
	var s: float = pr["s"]
	var shw := absf(j["shoulder_r"].x)
	var bw: float = bd["back_w"]
	var pv: Vector3 = j["pelvis"]
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var rows := 18
	for r in rows + 1:
		var t := r / float(rows)
		var v := lerpf(v0, v1, t)
		var a := lerpf(OPEN_TOP, OPEN_BOT * open, pow(t, 0.8))
		var hip := clampf((v - (pv.y - 0.15)) / 0.15, 0.0, 1.0)  # 가슴 → 엉덩이 둘레
		var ru := lerpf(shw + 0.06, 0.15, hip)
		var rw := lerpf(bw + 0.05, 0.12, hip)
		var xs := PackedFloat32Array()
		var ys := 0.0
		for i in 15:
			var phi := -PI * 0.5 + lerpf(-a, a, i / 14.0)
			if cos(phi) * s + sin(phi) * c < 0.05:  # 보는 사람 쪽 면만(c·s는 Back.proj — 앞 = w 음수)
				continue
			var q := Back.P2(pr, Vector3(cos(phi) * ru, v, sin(phi) * rw))
			xs.append(q.x)
			ys = q.y
		if xs.size() < 2:
			continue
		var lo := xs[0]
		var hi := xs[0]
		for x in xs:
			lo = minf(lo, x)
			hi = maxf(hi, x)
		left.append(Vector2(lo, ys))
		right.append(Vector2(hi, ys))
	if left.size() < 2:
		return PackedVector2Array()
	var out := PackedVector2Array([Vector2(left[0].x, -10.0)])
	out.append_array(left)
	out.append(Vector2(left[left.size() - 1].x, cl.h + 10.0))
	out.append(Vector2(right[right.size() - 1].x, cl.h + 10.0))
	right.reverse()
	out.append_array(right)
	out.append(Vector2(right[right.size() - 1].x, -10.0))
	return Back.roll_poly(pr, out)


## 단면이 타원인 캡슐 줄(몸 좌표 폭 us · 깊이 ws — 돌린 각도에 따라 화면 폭과 앞뒤 솟음을 섞는다, Back.ell과 같은 근사).
static func echain(cl: Clay, pr: Dictionary, g: int, pts: Array, us: Array, ws: Array, m: int, k: float) -> void:
	var c: float = pr["c"]
	var s: float = pr["s"]
	var H: float = pr["H"]
	for i in pts.size() - 1:
		var rx := PackedFloat32Array()
		var flat := 0.0
		for jj in [i, i + 1]:
			var u := float(us[jj])
			var w := float(ws[jj])
			var x := sqrt(pow(u * c, 2.0) + pow(w * s, 2.0))
			rx.append(x)
			flat += sqrt(pow(u * s, 2.0) + pow(w * c, 2.0)) / x * 0.5
		cl.cap(g, Back.P(pr, pts[i]), Back.P(pr, pts[i + 1]), rx[0] * H, rx[1] * H, m, k * H, flat)
