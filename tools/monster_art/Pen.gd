extends RefCounted
## Render의 펜 작업: 바깥·가려진 경계 잉크(edges) · 골 잉크(creases) · 펜 빗금(hatch) · 형태를 따라 도는 붓결(brush).
## ink 배열(칸마다 잉크 진하기 0~1)에 모아 두면 Render가 마지막에 한 번에 얹는다.

const Clay := preload("res://tools/monster_art/Clay.gd")
const Paint := preload("res://tools/city_art/Paint.gd")
const Kinds := preload("res://tools/monster_art/Kinds.gd")


## 잉크 선: 덮인 칸의 이웃이 비었거나 훨씬 뒤면(가려진 경계) 그 자리에 굵기가 바뀌는 점을 찍는다.
static func edges(cl: Clay, p: Paint, ink: PackedFloat32Array, nx: PackedFloat32Array, ny: PackedFloat32Array, scale: float) -> void:
	var w := cl.w
	var h := cl.h
	var jump := maxf(3.0, scale * 0.012)
	var base := maxf(0.8, scale / 300.0)
	for y in h:
		for x in w:
			var i := y * w + x
			if cl.top_g[i] < 0:
				continue
			var hv := cl.top_h[i]
			var outer := false
			var inner := false
			for k in 4:
				var xx := x + (1 if k == 0 else (-1 if k == 1 else 0))
				var yy := y + (1 if k == 2 else (-1 if k == 3 else 0))
				if xx < 0 or yy < 0 or xx >= w or yy >= h:
					outer = true
					continue
				var j := yy * w + xx
				if cl.top_g[j] < 0:
					outer = true
				elif hv - cl.top_h[j] > jump:
					inner = true
			if not outer and not inner:
				continue
			var md: Dictionary = cl.mats[cl.top_m[i]]
			if str(md["kind"]) == "glow":
				continue
			var side := clampf(nx[i] * 0.55 + ny[i] * 0.85, 0.0, 1.0)  # 빛 반대쪽(오른쪽 아래)은 굵게
			var wob := 0.6 + p.nz("mid", x, y) * 0.8
			var rad := base * (1.25 if outer else 0.8) * (0.7 + side * 1.0) * wob * float(md.get("line", 1.0))
			if inner and not outer and p.nz("hi", x, y) < 0.12:
				continue  # 가끔 끊긴다
			_dot(ink, w, h, x + 0.5, y + 0.5, rad, 0.95)


## 골 잉크: 오목함이 큰 곳에 가늘게(근육 사이·갈비·주름).
static func creases(cl: Clay, p: Paint, ink: PackedFloat32Array, cav: PackedFloat32Array, scale: float) -> void:
	for i in cl.w * cl.h:
		var c := cav[i]
		if c < 0.22:
			continue
		var x := i % cl.w
		var y := i / cl.w
		var md: Dictionary = cl.mats[cl.top_m[i]]
		var a := clampf((c - 0.22) * 2.2, 0.0, 0.7) * (0.5 + p.nz("mid", x, y) * 0.6) * float(md.get("line", 1.0))
		ink[i] = maxf(ink[i], a)


## 그늘 빗금(펜 해칭): 한 방향 평행선(60°)을 어두운 곳에만 — 어두울수록 굵고, 가장 어두운 곳은 엇갈린 선을 한 번 더.
## 선마다 끝나는 어둠 기준이 달라 끝이 들쭉날쭉하고, 큰 잡음으로 살짝 휘며, 군데군데 끊긴다.
static func hatch(cl: Clay, p: Paint, ink: PackedFloat32Array, tone: PackedFloat32Array, scale: float) -> void:
	var sp := maxf(3.2, scale / 125.0)
	var hw0 := maxf(0.35, scale / 1400.0)
	for y in cl.h:
		for x in cl.w:
			var i := y * cl.w + x
			var m := cl.top_m[i]
			if m < 0:
				continue
			var md: Dictionary = cl.mats[m]
			var kd: Dictionary = Kinds.KINDS.get(str(md["kind"]), Kinds.KINDS["skin"])
			var hk := float(md.get("hatch", kd["hatch"]))
			if hk <= 0.0:
				continue
			var dark := smoothstep(0.26, 0.0, tone[i]) * hk * 0.7
			if dark <= 0.02:
				continue
			var wob := p.nz("lo", x, y) * 2.5
			var a := _lines(x, y, 0.866, -0.5, sp, wob, dark, hw0, 0.0)
			if dark > 0.55:
				a = maxf(a, _lines(x, y, 0.42, 0.91, sp * 1.1, wob, (dark - 0.55) * 2.2, hw0, 0.3))
			if a > ink[i]:
				ink[i] = a


static func _lines(x: int, y: int, ax: float, ay: float, sp: float, wob: float, dark: float, hw0: float, seed_off: float) -> float:
	var u := (x * ax + y * ay) / sp + wob + seed_off
	var li := int(floor(u))
	var th := Paint.hash01(li, 3, int(seed_off * 10.0))
	if dark < 0.15 + th * 0.55:  # 이 선은 여기서 끝난다
		return 0.0
	var v := (-x * ay + y * ax) / (sp * 7.0) + Paint.hash01(li, 5, 1) * 3.0
	if fposmod(v, 1.0) < 0.1:  # 끊김
		return 0.0
	var dist := absf(fposmod(u, 1.0) - 0.5) * sp
	var hw := hw0 * (0.8 + dark * 1.2)
	return clampf(hw - dist + 0.5, 0.0, 1.0) * clampf(0.35 + dark * 0.6, 0.0, 0.85)


static func _dot(ink: PackedFloat32Array, w: int, h: int, cx: float, cy: float, rad: float, a: float) -> void:
	for yy in range(maxi(0, int(cy - rad - 1)), mini(h - 1, int(cy + rad + 1)) + 1):
		for xx in range(maxi(0, int(cx - rad - 1)), mini(w - 1, int(cx + rad + 1)) + 1):
			var dx := xx + 0.5 - cx
			var dy := yy + 0.5 - cy
			var cov := clampf(rad - sqrt(dx * dx + dy * dy) + 0.5, 0.0, 1.0) * a
			var i := yy * w + xx
			if cov > ink[i]:
				ink[i] = cov


## 붓결: 형태를 따라 도는 짧고 굵은 반투명 덧칠(밑색을 조금 밝거나 어둡게) — 매끈한 찰흙 느낌을 지운다.
static func brush(cl: Clay, p: Paint, nx: PackedFloat32Array, ny: PackedFloat32Array, scale: float) -> void:
	var sp := maxf(3.0, scale / 90.0)
	var ln := sp * 3.0
	var y := 0.0
	while y < cl.h:
		var x := 0.0
		while x < cl.w:
			var jx := int(x + Paint.hash01(int(x), int(y), 21) * sp)
			var jy := int(y + Paint.hash01(int(x), int(y), 22) * sp)
			x += sp
			if jx >= cl.w or jy >= cl.h:
				continue
			var i := jy * cl.w + jx
			var g := cl.top_g[i]
			if g < 0 or str(cl.mats[cl.top_m[i]]["kind"]) in ["glow", "eye"]:
				continue
			var base := p.get_c(jx, jy)
			var d := (Paint.hash01(jx, jy, 23) - 0.5) * 0.22
			var c := base.lightened(d) if d > 0.0 else base.darkened(-d)
			var tan := Vector2(-ny[i], nx[i])
			var dir := Vector2(0.3, -0.95) if tan.length() < 0.15 else tan.normalized()
			var wd := sp * (0.35 + Paint.hash01(jx, jy, 24) * 0.3)
			var steps := int(ln) + 1
			for s in steps + 1:
				var t := float(s) / steps
				var q := Vector2(jx, jy) + dir * (t - 0.5) * ln
				var r := wd * (0.5 + 0.5 * sin(t * PI))
				for yy in range(int(q.y - r), int(q.y + r) + 1):
					for xx in range(int(q.x - r), int(q.x + r) + 1):
						if xx < 0 or yy < 0 or xx >= cl.w or yy >= cl.h:
							continue
						var k := yy * cl.w + xx
						if cl.top_g[k] != g:
							continue
						var f := clampf(r - Vector2(xx + 0.5 - q.x, yy + 0.5 - q.y).length(), 0.0, 1.0)
						p.tint(xx, yy, c, f * 0.18)
		y += sp
