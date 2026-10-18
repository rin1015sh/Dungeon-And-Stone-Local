extends RefCounted
## 핏빛성채 바닥 재질(bf.gd가 부른다): 바탕(주기 잡음 · 돌 배치는 모든 변형이 같다 — 칸끼리 이어지게)과 변형마다 다른 잔손질.
## 판석·계단·창살처럼 짜인 무늬는 고정 배치(시드와 무관)로 그리고, 결·얼룩만 시드로 바꾼다.

const Paint := preload("res://tools/city_art/Paint.gd")
const Seam := preload("res://tools/floor_art/Seam.gd")
const K := preload("res://tools/floor_art/rift/bf_kit.gd")

## 판석 줄마다 자른 자리(칸 64px 기준 — 두 줄 엇갈림)
const ROWS := [0, 22, 42]
const CUTS := [[0, 30], [14, 46], [6, 38]]
const STEP_CUTS := [[0, 26], [12, 44], [6, 36], [20, 52]]

## 재질마다 변형 번호 → 잔손질 종류
const KINDS := {
	"cobble": ["plain", "crack", "chip", "stain", "split", "grime"],
	"mudroad": ["plain", "puddle", "rut", "prints", "stones", "puddle"],
	"ash": ["plain", "tuft", "stones", "tuft", "char", "prints"],
	"carpet": ["plain", "stain", "worn", "wax", "fray", "stain"],
	"rubble": ["heap", "chunks", "block", "heap", "chunks", "dust"],
	"bloodcrack": ["fissure", "pool", "plain", "fissure", "spatter", "pool"],
	"stairs": ["plain", "chip", "blood", "plain", "crack", "grime"],
	"bloodpool": ["plain", "ring", "clot", "bone", "ring", "plain"],
	"bones": ["skull", "ribs", "pile", "skull", "long", "pile"],
	"dirt": ["straw", "plain", "straw", "bone", "puddle", "chain"],
	"grate": ["plain", "rust", "debris", "slime", "plain", "rag"],
	"corpsepit": ["skull", "hand", "ribs", "plain", "arm", "skull"],
}


static func base(p: Paint, style: String, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	match style:
		"cobble", "rubble":
			var jx := Seam.field(w, h, 77, 0.09, 2)  # 줄눈 흔들림(고정 — 모든 변형이 같은 돌 배치)
			var jy := Seam.field(w, h, 78, 0.09, 2)
			var hf := Seam.field(w, h, s, 0.09, 3)
			var st := Seam.field(w, h, s + 1, 0.035, 2)
			var fine := Seam.field(w, h, s + 2, 0.35, 1)
			var dusty := style == "rubble"
			for y in h:
				for x in w:
					var i := y * w + x
					var q := K.slab(x + (jx[i] - 0.5) * 7.0, y + (jy[i] - 0.5) * 7.0, w, ROWS, CUTS, 5.0)
					var tone := Paint.hash01(int(q.y), s % 991, 3)
					var t := 0.5 + (tone - 0.5) * 0.4 + Seam.relief(hf, w, h, x, y, 5.0) * 0.45 + (hf[i] - 0.5) * 0.2 + q.z * 0.25 + (fine[i] - 0.5) * 0.1
					var c := col.darkened(0.55).lerp(col.lightened(0.25), clampf(t, 0.0, 1.0))
					if st[i] > 0.58:  # 스민 얼룩
						c = c.lerp(Color("#20100e"), (st[i] - 0.58) * 1.3)
					if dusty:  # 돌가루가 덮인 바닥
						c = c.lerp(col.lightened(0.12), clampf(0.2 + (st[i] - 0.4) * 0.8, 0.0, 0.5))
					var jd := q.x
					if jd < 1.5:
						c = c.lerp(Color("#160c0a"), 0.85 if not dusty else 0.5)
					elif jd < 3.0:
						c = c.lerp(Color("#24160f"), (0.5 if not dusty else 0.25) * (3.0 - jd) / 1.5)
					p.blend(x, y, c, 1.0)
		"mudroad":
			var hf := Seam.field(w, h, s, 0.06, 3)
			var wet := Seam.field(w, h, s + 1, 0.04, 2)
			var clod := Seam.field(w, h, s + 3, 0.18, 2)
			for y in h:
				for x in w:
					var i := y * w + x
					var r := Seam.relief(hf, w, h, x, y, 3.5) + Seam.relief(clod, w, h, x, y, 1.8) * 0.5
					var t := 0.45 + r * 0.6 + (hf[i] - 0.5) * 0.25
					var c := col.darkened(0.45).lerp(col.lightened(0.08), clampf(t, 0.0, 1.0))
					var wt := smoothstep(0.45, 0.7, wet[i])
					c = c.lerp(Color("#2a1e18"), wt * 0.4)  # 젖어 검은 진흙
					if wt > 0.3 and r > 0.1:  # 번들거림
						c = c.lerp(Color("#9a8a80"), (r - 0.1) * 0.9 * wt)
					p.blend(x, y, c, 1.0)
		"ash", "dirt":
			var hf := Seam.field(w, h, s, 0.06, 3)
			var lo := Seam.field(w, h, s + 1, 0.03, 2)
			var fine := Seam.field(w, h, s + 2, 0.4, 1)
			var rip := Seam.field(w, h, 151, 0.05, 2)
			for y in h:
				for x in w:
					var i := y * w + x
					var t := 0.48 + Seam.relief(hf, w, h, x, y, 4.0) * 0.45 + (lo[i] - 0.5) * 0.45 + (fine[i] - 0.5) * 0.25
					if style == "ash":  # 바람 결
						t += sin((x * 0.25 + y * 0.9) + rip[i] * 9.0) * 0.06
					var c := col.darkened(0.45).lerp(col.lightened(0.22), clampf(t, 0.0, 1.0))
					if style == "ash" and fine[i] > 0.76:  # 흰 재 알갱이
						c = c.lerp(Color("#b8b0a8"), (fine[i] - 0.76) * 1.8)
					if style == "ash" and lo[i] < 0.3:  # 그을음
						c = c.lerp(Color("#1a1616"), (0.3 - lo[i]) * 1.4)
					if style == "dirt" and lo[i] < 0.32:  # 축축하게 검은 흙
						c = c.darkened((0.32 - lo[i]) * 1.3)
					p.blend(x, y, c, 1.0)
			if style == "dirt":
				_straw(p, col, 26, 501)
		"carpet":
			_carpet(p, col, s)
		"bloodcrack":
			_bloodcrack(p, col, s)
		"stairs":
			_stairs(p, col, s)
		"bloodpool":
			var hf := Seam.field(w, h, 161, 0.03, 3)  # 깊이는 고정(넓은 무늬가 칸 격자로 보이지 않게), 물결은 시드
			var rp := Seam.field(w, h, s, 0.07, 2)
			var sh := Seam.field(w, h, s + 1, 0.05, 2)
			for y in h:
				for x in w:
					var i := y * w + x
					var r := Seam.relief(rp, w, h, x, y, 4.0)
					var c := K.BLOOD_DARK.lerp(col.lightened(0.1), clampf(0.45 + hf[i] * 0.35, 0.0, 1.0))
					var gloss := pow(clampf(r * 2.6, 0.0, 1.0), 2.0) * smoothstep(0.35, 0.75, sh[i])
					c = c.lerp(Color("#e0968c"), gloss * 0.45)  # 끈적한 번들거림(넓게)
					c = c.lerp(Color("#0c0204"), pow(clampf(-r * 2.2, 0.0, 1.0), 2.0) * 0.35)
					p.blend(x, y, c, 1.0)
		"bones":
			var hf := Seam.field(w, h, s, 0.07, 3)
			var fine := Seam.field(w, h, s + 2, 0.45, 1)
			for y in h:
				for x in w:
					var i := y * w + x
					var t := 0.4 + Seam.relief(hf, w, h, x, y, 3.0) * 0.4 + (hf[i] - 0.5) * 0.3
					var c := col.darkened(0.55).lerp(col.lightened(0.05), clampf(t, 0.0, 1.0))
					if fine[i] > 0.7:  # 뼛조각 부스러기
						c = c.lerp(K.BONE.darkened(0.15), (fine[i] - 0.7) * 2.2)
					p.blend(x, y, c, 1.0)
			_litter(p, 611)
		"grate":
			_grate(p, col, s)
		"corpsepit":
			_pit(p, col, s)
		_:
			for y in h:
				for x in w:
					p.blend(x, y, col, 1.0)


# ── 짜인 무늬 바탕 ───────────────────────────────────

## 해진 붉은 양탄자: 촘촘한 올 + 빛바랜 금실 마름모(32px 주기) + 검붉은 속 마름모 + 닳은 자리·주름 그늘.
static func _carpet(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var pile := Seam.field(w, h, s, 0.3, 2)
	var wear := Seam.field(w, h, s + 1, 0.05, 3)
	var fold := Seam.field(w, h, s + 2, 0.03, 2)
	for y in h:
		for x in w:
			var i := y * w + x
			var weave := 0.5 + 0.25 * sin(x * PI) * sin(y * PI * 0.5) + 0.25 * sin(y * PI)
			var t := 0.55 + (pile[i] - 0.5) * 0.45 + (weave - 0.5) * 0.2 - (fold[i] - 0.5) * 0.5
			var c := col.darkened(0.55).lerp(col.lightened(0.1), clampf(t, 0.0, 1.0))
			var dx := absf(fposmod(x + y, 32) - 16.0)
			var dy := absf(fposmod(x - y, 32) - 16.0)
			var m := minf(dx, dy)
			var fade := clampf(1.0 - wear[i] * 0.9, 0.2, 1.0)
			if m < 1.6:  # 금실 마름모(빛바램)
				c = c.lerp(K.GOLD.darkened(0.15), 0.55 * (1.6 - m) / 1.6 * fade)
			elif m > 4.0 and m < 5.6:  # 검붉은 속 테
				c = c.lerp(Color("#3a080c"), 0.45 * fade)
			var cx := absf(fposmod(x, 32) - 16.0) + absf(fposmod(y, 32) - 16.0)
			if cx < 3.0:  # 마름모 가운데 꽃점
				c = c.lerp(K.GOLD.darkened(0.1), 0.5 * fade * (1.0 - cx / 3.0))
			if wear[i] > 0.6:  # 닳아 올이 드러난 곳(밝고 탁하게)
				c = c.lerp(Color("#6a4038"), (wear[i] - 0.6) * 1.5)
			p.blend(x, y, c, 1.0)


## 피가 고인 금 간 검은 돌: 고정 세포 무늬(판) + 시드마다 다른 피 흐름(어느 금이 차고 빛나는지).
static func _bloodcrack(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var cl := Seam.field(w, h, 91, 0.055, 1, true)
	var cl2 := Seam.field(w, h, 93, 0.13, 1, true)
	var hf := Seam.field(w, h, s, 0.1, 3)
	var flow := Seam.field(w, h, s + 1, 0.03, 2)
	var stone := Color("#1c1416")
	for y in h:
		for x in w:
			var i := y * w + x
			var fl := smoothstep(0.38, 0.72, flow[i])
			var e := cl[i]
			var thr := 0.022 + fl * 0.06
			var t := 0.42 + Seam.relief(hf, w, h, x, y, 6.0) * 0.55 + (hf[i] - 0.5) * 0.2
			var c := stone.darkened(0.3).lerp(Color("#4c3c44"), clampf(t, 0.0, 1.0))
			c = c.lerp(Color("#5a1418"), clampf(Seam.relief(hf, w, h, x, y, 6.0) * 2.0, 0.0, 1.0) * 0.3)  # 젖은 돌에 비친 붉은 빛
			if cl2[i] < 0.04:  # 판 안의 가는 잔금
				c = c.lerp(K.INK, 0.65 * (1.0 - cl2[i] / 0.04))
			var rim := clampf(1.0 - (e - thr) / 0.12, 0.0, 1.0)
			c = c.lerp(Color("#7a1414"), rim * rim * fl * 0.7)  # 빛나는 금 둘레로 번진 붉은 빛
			if e < thr + 0.012 and e >= thr:
				c = c.lerp(K.INK, 0.85)  # 금 가장자리 잉크
			elif e < thr:
				var k := 1.0 - e / thr  # 금 가운데일수록 1
				if fl < 0.08:
					c = K.INK.lerp(Color("#2a0606"), k * 0.5)  # 마른 금
				else:
					var b := K.BLOOD.lerp(K.BLOOD_LIT, clampf(k * 1.4, 0.0, 1.0) * (0.35 + fl * 0.65))
					c = b.lerp(K.BLOOD_HOT, clampf(k - 0.5, 0.0, 1.0) * fl * 1.3)
			p.blend(x, y, c, 1.0)


## 돌계단: 64px에 네 단(디딤면 + 빛 받은 앞 모서리 + 그늘진 챌면), 단마다 엇갈린 돌 이음.
static func _stairs(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var hf := Seam.field(w, h, s, 0.1, 3)
	var st := Seam.field(w, h, s + 1, 0.04, 2)
	var step := h / 4.0
	for y in h:
		for x in w:
			var i := y * w + x
			var fy := fposmod(float(y), step)
			var k := int(y / step)
			var row_cuts: Array = STEP_CUTS[k % 4]
			var dj := 1e9
			var seg := 0
			for n in row_cuts.size():
				var c0 := float(row_cuts[n])
				dj = minf(dj, minf(fposmod(x - c0, w), fposmod(c0 - x, w)))
				if x >= c0:
					seg = n
			var tone := Paint.hash01(k, seg, s % 991)
			var t := 0.5 + Seam.relief(hf, w, h, x, y, 4.0) * 0.35 + (hf[i] - 0.5) * 0.2 + (tone - 0.5) * 0.25
			var tread := step * 0.66
			if fy < tread:  # 디딤면: 뒤(위)쪽은 위 단 챌면 그늘
				t += 0.05 - clampf(1.0 - fy / 3.5, 0.0, 1.0) * 0.4
			elif fy < tread + 1.8:  # 앞 모서리(빛)
				t += 0.4
			else:  # 챌면(남쪽을 향해 그늘)
				t -= 0.45 + (fy - tread) / (step - tread) * 0.15
			var c := col.darkened(0.6).lerp(col.lightened(0.2), clampf(t, 0.0, 1.0))
			if fy >= tread + 1.8 and fy < tread + 2.8:
				c = c.lerp(K.INK, 0.4)
			if fy > step - 1.2:
				c = c.lerp(K.INK, 0.75)
			if dj < 1.0 and fy < step - 1.0:
				c = c.lerp(K.INK, 0.7)
			if st[i] > 0.6:
				c = c.lerp(Color("#2a1410"), (st[i] - 0.6) * 1.2)
			p.blend(x, y, c, 1.0)


## 녹슨 쇠 창살(세로 64/6 px · 가로 32px) 아래 검은 하수.
static func _grate(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var wf := Seam.field(w, h, s, 0.05, 2)
	var rf := Seam.field(w, h, s + 1, 0.15, 2)
	var rust := Seam.field(w, h, s + 2, 0.08, 2)
	var pw := 64.0 / 6.0
	for y in h:
		for x in w:
			var i := y * w + x
			var c := Color("#0a0c0a").lerp(Color("#202620"), wf[i] * 0.9)
			var r := Seam.relief(rf, w, h, x, y, 4.0)
			c = c.lerp(Color("#7a8478"), pow(clampf(r * 2.0, 0.0, 1.0), 3.0) * 0.3)  # 물 반짝임
			var fx := fposmod(float(x), pw)  # 세로 살: 0~4.5
			var fy := fposmod(float(y) - 2.0, 32.0)  # 가로 받침: 0~6
			if fposmod(fx - 2.5, pw) < 4.5 or fposmod(fy - 2.5, 32.0) < 6.0:  # 살 그림자(오른쪽 아래)
				c = c.darkened(0.55)
			var iron := col.darkened(0.1).lerp(Color("#7a4426"), clampf(rust[i] * 1.6 - 0.3, 0.2, 0.9))
			if fy < 6.0:
				var lit := 1.0 - fy / 6.0
				c = iron.darkened(0.45).lerp(iron.lightened(0.35), lit)
				if fy > 5.0:
					c = c.lerp(K.INK, 0.7)
			elif fx < 4.5:
				var u := fx / 4.5
				c = iron.darkened(0.45).lerp(iron.lightened(0.3), clampf(1.0 - u * 1.4, 0.0, 1.0))
				if u > 0.85:
					c = c.lerp(K.INK, 0.6)
			p.blend(x, y, c, 1.0)


## 시체 구덩이: 굽은 둥근 덩어리(팔다리·몸통)가 엉킨 높이장 — 깊은 골은 거의 검게, 솟은 곳만 창백하게.
static func _pit(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var a := Seam.field(w, h, s, 0.04, 2)
	var b := Seam.field(w, h, s + 1, 0.035, 2)
	var lump := Seam.field(w, h, s + 3, 0.07, 1, true)
	var dark := Seam.field(w, h, s + 2, 0.03, 2)
	var hgt := PackedFloat32Array()
	hgt.resize(w * h)
	for i in w * h:
		var ra := 1.0 - absf(a[i] * 2.0 - 1.0)  # 능선 = 굽은 팔다리
		var rb := 1.0 - absf(b[i] * 2.0 - 1.0)
		hgt[i] = maxf(maxf(pow(ra, 2.2), pow(rb, 2.2) * 0.9), smoothstep(0.15, 0.7, lump[i]) * 0.75)
	for y in h:
		for x in w:
			var i := y * w + x
			var r := Seam.relief(hgt, w, h, x, y, 9.0)
			var flesh := K.SKIN.darkened(0.45).lerp(Color("#b0a290"), clampf(0.35 + r * 1.0, 0.0, 1.0))
			flesh = flesh.lerp(Color("#5a6050"), clampf(dark[i] - 0.55, 0.0, 0.3))  # 썩어 푸르죽죽한 살
			var t := smoothstep(0.4, 0.8, hgt[i])
			var c := Color("#0a0505").lerp(flesh, t * (0.3 + dark[i] * 0.6))
			if hgt[i] > 0.36 and hgt[i] < 0.46:  # 몸 사이 그늘 윤곽
				c = c.lerp(K.INK, 0.55)
			if dark[i] < 0.35:  # 썩은 피·흙이 고인 곳
				c = c.lerp(Color("#2a0806"), (0.35 - dark[i]) * 1.8)
			p.blend(x, y, c, 1.0)


## 짚(감옥 흙바닥): 고정 배치로 감아 도는 가는 짚 줄기.
static func _straw(p: Paint, col: Color, n: int, sd: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = sd
	for k in n:
		var q := Vector2(r.randf() * p.w, r.randf() * p.h)
		var d := Vector2.from_angle(r.randf() * TAU) * r.randf_range(6.0, 13.0)
		K.wline(p, q + Vector2(0.6, 0.8), q + d + Vector2(0.6, 0.8), 1.4, K.INK, 0.35, 0.4)
		K.wline(p, q, q + d, 1.1, Color("#a88e58").lerp(col, 0.2), 0.75, 0.4)


## 뼛조각 부스러기(고정 배치, 감아 돈다).
static func _litter(p: Paint, sd: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = sd
	for k in 22:
		var q := Vector2(r.randf() * p.w, r.randf() * p.h)
		var d := Vector2.from_angle(r.randf() * TAU) * r.randf_range(3.0, 9.0)
		K.wline(p, q + Vector2(0.8, 1.0), q + d + Vector2(0.8, 1.0), 2.4, K.INK, 0.4, 0.2)
		K.wline(p, q, q + d, 2.0, K.INK, 0.6, 0.2)
		K.wline(p, q, q + d, 1.3, K.BONE.darkened(r.randf_range(0.15, 0.45)), 0.9, 0.2)
