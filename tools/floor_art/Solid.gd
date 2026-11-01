extends RefCounted
## 입체 소품 부품(사용자 2026-11-01 "입체감이 안 느껴지는 것들 — 땅바닥에 붙은 것처럼 그린 것들 다시 그려", V27).
## 3/4 시점(위에서 비스듬히 — 화면 위쪽 = 먼 쪽, 빛은 왼쪽 위 앞)에서 덩어리마다 픽셀별 높이·법선을 계산해 칠한다:
## 밝은 윗면 · 어두운 아래·오른쪽 면 · 바닥에 닿는 곳의 접지 그늘 · 바닥 그림자 · 굵기가 바뀌는 잉크 윤곽.
## 평면 도형에 그늘 한 번 덧칠하던 옛 소품(동굴 요소·실내 상자·자루·더미)이 바닥에 붙은 무늬처럼 보였다 — 이 부품으로 다시 그린다.
## 좌표는 그림 px. foot = 바닥에 닿는 앞 가운데.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")

const LIGHT := Vector3(-0.5, -0.75, 0.45)  ## 왼쪽 위 앞(화면 y 위 = 먼 쪽이자 위)
const DARK := Color("#1a1412")
const LIT := Color("#fff0d0")


## 바닥 그림자(오른쪽 아래로 조금 밀린 흐린 타원).
static func shadow(p: Paint, foot: Vector2, rx: float, ry: float, a: float = 0.45) -> void:
	var r := Rect2(foot.x - rx * 1.2, foot.y - ry * 1.2, rx * 2.6, ry * 2.6)
	for y in range(maxi(0, int(r.position.y)), mini(p.h, int(r.end.y) + 1)):
		for x in range(maxi(0, int(r.position.x)), mini(p.w, int(r.end.x) + 1)):
			var d := Vector2((x - foot.x - rx * 0.15) / rx, (y - foot.y - ry * 0.1) / ry).length()
			if d < 1.0:
				p.blend(x, y, Color(0.03, 0.02, 0.03), a * (1.0 - d * d))


## 둥근 덩어리(돌·자루·고기·흙더미): 화면에서 가로 반지름 rx, 높이 h(밑동 foot에서 위로), 바닥 깊이 반지름 ry.
## 밑면은 납작하게 바닥에 앉고, 위는 둥글게 솟는다. rough = 표면 울퉁불퉁(0~1), lean = 꼭대기가 옆으로 쏠림(-1~1).
static func lump(p: Paint, foot: Vector2, rx: float, ry: float, h: float, col: Color, rough: float = 0.3, lean: float = 0.0, ink: float = 1.0) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = p.rng.randi()
	noise.frequency = 2.5 / maxf(4.0, rx)
	var l := LIGHT.normalized()  # 빛이 오는 쪽(왼쪽 위 앞)
	var mask := {}
	var steps := 28
	for y in range(maxi(0, int(foot.y - h - ry) - 3), mini(p.h, int(foot.y + ry) + 2)):
		for x in range(maxi(0, int(foot.x - rx * 1.3)), mini(p.w, int(foot.x + rx * 1.3) + 1)):
			# 가까운 쪽(z = +1)부터 먼 쪽으로: 그 깊이의 기둥(바닥 g ~ 표면 s)이 이 픽셀을 덮으면 그 표면이 보인다
			for k in steps + 1:
				var z := 1.0 - 2.0 * k / steps
				var sx := foot.x + lean * 0.3 * rx * (1.0 - absf(z))
				var nx := (x - sx) / rx
				var base := 1.0 - nx * nx - z * z
				if base <= 0.0:
					continue
				var bump := 1.0 + rough * 0.45 * noise.get_noise_2d(x * 0.7, z * ry * 2.0)
				var hh := sqrt(base) * h * bump
				var g := foot.y + z * ry
				if y > g or y < g - hh:
					continue
				# 반타원체 법선: (가로, 위 = −y, 앞 = +z)
				var n := Vector3(nx * h / rx, -sqrt(base), z * h / maxf(1.0, ry) * 0.6).normalized()
				n = (n + Vector3(noise.get_noise_2d(x * 2.1, y * 2.1), 0.0, noise.get_noise_2d(y * 2.1, x * 2.1)) * rough * 0.6).normalized()
				var lam := clampf(n.dot(l), 0.0, 1.0)  # 0 = 빛을 등진 면(오른쪽 아래)
				var c := col.darkened(0.62).lerp(col, smoothstep(0.05, 0.5, lam)).lerp(col.lightened(0.3), smoothstep(0.62, 0.92, lam))
				var up := clampf((g - y) / maxf(1.0, hh), 0.0, 1.0)  # 0 = 바닥에 닿은 곳
				c = c.lerp(DARK, (1.0 - smoothstep(0.0, 0.35, up)) * 0.45)  # 접지 그늘
				p.blend(x, y, c, 1.0)
				mask[Vector2i(x, y)] = true
				break
	_rim(p, mask, ink)


## 상자(나무 궤짝·돌 받침): 앞면 + 윗면 + 오른쪽 옆면 — 면마다 shader(x, y) -> Color. dd = 깊이가 화면에 눌린 높이.
static func block(p: Paint, foot: Vector2, w: float, dd: float, h: float, front: Callable, top: Callable, side: Callable, ink: float = 1.0) -> Dictionary:
	var fl := foot + Vector2(-w * 0.5, 0)
	var fr := foot + Vector2(w * 0.5, 0)
	var off := Vector2(dd * 0.35, -dd)
	var f := PackedVector2Array([fl + Vector2(0, -h), fr + Vector2(0, -h), fr, fl])
	var t := PackedVector2Array([fl + Vector2(0, -h), fr + Vector2(0, -h), fr + Vector2(0, -h) + off, fl + Vector2(0, -h) + off])
	var s := PackedVector2Array([fr + Vector2(0, -h), fr + Vector2(0, -h) + off, fr + off, fr])
	p.fill_poly(s, side)
	p.fill_poly(f, front)
	p.fill_poly(t, top)
	Ink.path(p, PackedVector2Array([fl, fl + Vector2(0, -h), fl + Vector2(0, -h) + off, fr + Vector2(0, -h) + off, fr + off, fr, fl]), 1.6 * ink, true, Ink.INK, 0.9, 0.35)
	Ink.line(p, fl + Vector2(0, -h), fr + Vector2(0, -h), 1.0 * ink, LIT, 0.35, 0.25)
	Ink.line(p, fr + Vector2(0, -h), fr, 1.1 * ink, Ink.INK, 0.7, 0.25)
	_ground(p, fl, fr, off)
	return {"front": f, "top": t, "side": s}


## 세운 원통(통·그루터기·의자 다리 묶음): 반지름 r, 높이 h. 둥근 윗면(밝게) + 왼쪽이 밝은 몸통.
static func drum(p: Paint, foot: Vector2, r: float, h: float, body: Color, cap: Color, ink: float = 1.0) -> Dictionary:
	var ry := r * 0.42
	var bodyp := PackedVector2Array()
	for i in 13:
		var a := PI * float(i) / 12.0
		bodyp.append(foot + Vector2(cos(a) * r, sin(a) * ry))
	for i in 13:
		var a := PI - PI * float(i) / 12.0
		bodyp.append(foot + Vector2(cos(a) * r, sin(a) * ry - h))
	p.fill_poly(bodyp, func(x: int, _y: int) -> Color:
		var u := clampf((x - (foot.x - r)) / (2.0 * r), 0.0, 1.0)
		var lam := 1.0 - absf(u - 0.3) * 1.4
		return body.darkened(0.5).lerp(body.lightened(0.15), clampf(lam, 0.0, 1.0)))
	var capp := _ellipse(foot + Vector2(0, -h), r, ry)
	p.fill_poly(capp, func(x: int, y: int) -> Color:
		var d := Vector2((x - foot.x + r * 0.3) / r, (y - foot.y + h + ry * 0.3) / ry).length()
		return cap.lightened(0.2 * (1.0 - clampf(d, 0.0, 1.0))))
	Ink.path(p, bodyp, 1.5 * ink, true, Ink.INK, 0.85, 0.3)
	Ink.path(p, capp, 1.1 * ink, true, Ink.INK, 0.7, 0.3)
	return {"cap": capp, "body": bodyp}


## 누운 통나무·막대(a → b, 반지름 r): 몸통은 원통 명암, 앞쪽 끝은 나이테 단면.
static func log(p: Paint, a: Vector2, b: Vector2, r: float, bark: Color, cut: Color, ink: float = 1.0) -> void:
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x)
	if n.y > 0.0:
		n = -n  # n = 위쪽(빛 받는 쪽)
	var poly := PackedVector2Array([a + n * r, b + n * r, b - n * r, a - n * r])
	p.fill_poly(poly, func(x: int, y: int) -> Color:
		var t := clampf((Vector2(x, y) - a).dot(n) / r, -1.0, 1.0)  # +1 = 위
		var c := bark.darkened(0.45).lerp(bark.lightened(0.18), (t + 1.0) * 0.5)
		return p.vary(c, x, y, 0.08))
	Ink.path(p, poly, 1.3 * ink, true, Ink.INK, 0.85, 0.3)
	var endp := b if b.y >= a.y else a  # 가까운(아래) 끝 단면
	var ring := _ellipse(endp, r * 0.55, r)
	p.fill_poly(ring, p.flat(cut, 0.08))
	Ink.path(p, ring, 1.0 * ink, true, Ink.INK, 0.8, 0.2)
	Ink.path(p, _ellipse(endp, r * 0.25, r * 0.45), 0.7 * ink, true, cut.darkened(0.45), 0.7, 0.2)


## 바닥에 닿는 앞 모서리를 따라 짧은 접지 그늘(물건이 바닥 위에 서 있게).
static func _ground(p: Paint, fl: Vector2, fr: Vector2, off: Vector2) -> void:
	for x in range(int(fl.x) - 2, int(fr.x + off.x) + 3):
		for k in 4:
			p.blend(x, int(fl.y) + 1 + k, Color(0.02, 0.02, 0.02), 0.35 * (1.0 - k / 4.0))


static func _rim(p: Paint, mask: Dictionary, ink: float) -> void:
	for c: Vector2i in mask:
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if not mask.has(c + d):
				p.blend(c.x, c.y, Ink.INK, 0.75 * minf(1.0, ink))
				break


static func _ellipse(c: Vector2, rx: float, ry: float, n: int = 24) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / n
		out.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return out
