extends RefCounted
## 탐험 맵 소품(tools/paint_floor.gd — 동굴 요소·포탈의 마름모 표식을 대신하는 그림): 시트 한 칸 = 소품 하나, 투명 RGBA.
## 칸 = 바닥 1.5칸 크기(tiles.json art.prop.size 1.5). 게임은 그림 아래 끝을 칸 아래쪽 근처에 둔다 —
## 바닥에 누운 것은 그림 높이 72% 근처(= 칸 가운데), 서 있는 것은 85% 근처에 밑동을 둔다.
## 상호작용 대상이라 둘레보다 조금 밝게(게임이 prop_highlight를 곱한다) + 가장자리에 빛 받은 테두리.
## 칠은 Cave(돌·점·수정·금)·Decals(얼룩·막대·뼈) 부품 + Ink.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")
const Decals := preload("res://tools/floor_art/Decals.gd")

## 시트 칸 순서(tiles.json art.prop.cell이 이 번호를 가리킨다).
const ORDER := ["corpse", "ghoul_feast", "stone_heap", "dead_campfire", "broken_gear", "offering", "spring", "drip",
	"stalagmites", "mushroom", "wolf_den", "gnome_trinkets", "gnome_stash", "goblin_camp", "torch_stubs", "old_skeleton",
	"cairn", "cache", "goblin_snare", "wet_slope", "portal", "rift_portal", "rift_gate"]

const SKIN := Color("#8a7a6a")
const CLOTH := Color("#4a4236")
const LEATHER := Color("#5a3e28")
const METAL := Color("#70787f")
const WOOD := Color("#4e3a28")
const BLOOD := Color("#4a0d0a")
const BONE := Color("#b8ae98")
const STONE := Color("#6a6470")


static func paint(kind: String, w: int, seed_value: int) -> Paint:
	var p := Paint.new(w, w, seed_value + kind.hash() % 1000)
	var u := w / 96.0
	var c := Vector2(w * 0.5, w * 0.72)  # 바닥에 누운 것의 가운데(칸 가운데)
	var foot := Vector2(w * 0.5, w * 0.84)  # 서 있는 것의 밑동
	match kind:
		"corpse":  # 탐험가 맵 몸 그림(걷는 탐험가와 같은 그림)을 눕힌 시체 — 사람 크기(tiles.json feat_corpse art.prop.size)
			Decals._blob(p, c + Vector2(4, 10) * u, 36 * u, BLOOD, 0.8, 0.35)  # 몸 밑에서 번진 피
			Decals._blob(p, c + Vector2(-26, 6) * u, 18 * u, BLOOD.darkened(0.2), 0.7, 0.4)
			Decals._blob(p, c + Vector2(22, 18) * u, 12 * u, BLOOD.darkened(0.1), 0.6, 0.45)
			_shadow(p, c, 40 * u, 14 * u)
			Decals._stick(p, c + Vector2(-34, 16) * u, c + Vector2(-8, 22) * u, 2.6 * u, METAL.darkened(0.2))  # 떨어뜨린 칼
			_lying_body(p, c, w * 0.86, -1.42, "res://assets/actors/human.webp", 0)
			Cave._stone(p, c + Vector2(30, 14) * u, 8 * u, 6 * u, LEATHER)  # 굴러 나온 등짐
			Ink.line(p, c + Vector2(24, 11) * u, c + Vector2(36, 11) * u, 1.0 * u, Ink.INK, 0.6, 0.4)
		"ghoul_feast":
			Decals._blob(p, c, 26 * u, Color("#3a3422"), 0.7, 0.25)
			Decals._blob(p, c + Vector2(-4, 2) * u, 14 * u, BLOOD, 0.8, 0.35)
			for k in 3:
				Decals._bones(p, c + Vector2(p.rng.randf_range(-10, 10), p.rng.randf_range(-6, 6)) * u, u * 1.3)
			for k in 6:
				Cave._stone(p, c + Vector2(p.rng.randf_range(-16, 16), p.rng.randf_range(-8, 8)) * u, 2.5 * u, 2.0 * u, Color("#6a2a22"))
		"stone_heap":
			_shadow(p, c, 24 * u, 10 * u)
			for k in 14:
				var q := c + Vector2(p.rng.randf_range(-16, 16), p.rng.randf_range(-6, 8) - k * 0.6) * u
				var r := p.rng.randf_range(4.0, 8.0) * u
				Cave._stone(p, q, r, r * 0.75, STONE.lightened(p.rng.randf_range(-0.1, 0.2)))
		"dead_campfire":
			Decals._blob(p, c, 18 * u, Color("#2a2826"), 0.85, 0.15)
			for k in 9:
				var a := TAU * k / 9.0
				Cave._stone(p, c + Vector2(cos(a) * 17, sin(a) * 11) * u, 4.0 * u, 3.0 * u, STONE)
			for k in 3:
				var d := Vector2.from_angle(p.rng.randf() * TAU) * 11 * u
				Decals._stick(p, c - d, c + d, 3.0 * u, Color("#1e1814"))
			for k in 8:
				Cave._dot(p, c + Vector2(p.rng.randf_range(-8, 8), p.rng.randf_range(-5, 5)) * u, 1.2 * u, Color("#8a8680"), 0.6)
		"broken_gear":
			_shadow(p, c, 26 * u, 10 * u)
			Cave._stone(p, c + Vector2(10, 0) * u, 13 * u, 10 * u, WOOD)  # 깨진 둥근 방패
			Ink.line(p, c + Vector2(4, -8) * u, c + Vector2(14, 8) * u, 1.6 * u, Ink.INK, 0.9, 0.6)
			Cave._dot(p, c + Vector2(10, 0) * u, 3.0 * u, METAL, 0.9)
			Decals._stick(p, c + Vector2(-26, 6) * u, c + Vector2(-2, -6) * u, 3.0 * u, METAL)  # 부러진 칼
			Decals._stick(p, c + Vector2(-6, -4) * u, c + Vector2(-2, -12) * u, 2.0 * u, METAL)
			Decals._stick(p, c + Vector2(-26, 6) * u, c + Vector2(-32, 9) * u, 3.4 * u, LEATHER)
			Cave._stone(p, c + Vector2(-8, 10) * u, 7 * u, 5.5 * u, METAL.darkened(0.15))  # 투구
		"offering":
			_shadow(p, c, 20 * u, 8 * u)
			var slab := PackedVector2Array([c + Vector2(-16, -6) * u, c + Vector2(16, -8) * u, c + Vector2(18, 6) * u, c + Vector2(-17, 8) * u])
			p.fill_poly(slab, func(x: int, y: int) -> Color: return p.vary(STONE.lightened(0.1), x, y, 0.08))
			Ink.path(p, slab, 1.2 * u, true, Ink.INK, 0.8, 0.6)
			for k in 7:
				Cave._dot(p, c + Vector2(p.rng.randf_range(-12, 12), p.rng.randf_range(-4, 4)) * u, 1.8 * u, Color("#c9a24a"), 0.95)
			for k in 2:
				var q := c + Vector2(-8 + k * 14, -4) * u
				Decals._stick(p, q, q + Vector2(0, -9) * u, 3.0 * u, Color("#d8d0b8"))
				Ink.glow(p, q.x, q.y - 11 * u, 7 * u, Color("#ffb46a"), 0.5, false)
				Cave._dot(p, q + Vector2(0, -11) * u, 1.5 * u, Color("#ffe0a0"), 1.0)
		"spring":
			for k in 10:
				var a := TAU * k / 10.0
				Cave._stone(p, c + Vector2(cos(a) * 20, sin(a) * 12) * u, 4.5 * u, 3.4 * u, STONE)
			Decals._blob(p, c, 15 * u, Color("#203a52"), 1.0, 0.1)
			Decals._blob(p, c + Vector2(-3, -2) * u, 9 * u, Color("#3a6a8a"), 0.6, 0.1)
			for k in 4:
				Decals._spot(p, c + Vector2(p.rng.randf_range(-9, 4), p.rng.randf_range(-6, 2)) * u, 1.2 * u, Color("#d8ecff"), 0.8)
		"drip":
			Decals._blob(p, c, 14 * u, Color("#1e2434"), 0.75, 0.2)
			for r: float in [5.0, 9.0, 13.0]:
				Ink.path(p, Cave._ellipse(c, r * u, r * 0.6 * u, 22), 0.9 * u, true, Color("#b8c8ff"), 0.4, 0.4)
			Cave._cluster(p, c + Vector2(10, 2) * u, 0.45 * u, false)
			Decals._spot(p, c, 2.0 * u, Color("#e0e8ff"), 0.9)
		"stalagmites":
			for k in 4:
				var b := foot + Vector2(p.rng.randf_range(-20, 20), p.rng.randf_range(-6, 2)) * u
				_spike(p, b, p.rng.randf_range(5, 9) * u, p.rng.randf_range(24, 44) * u, STONE.lightened(0.05))
		"mushroom":
			Ink.glow(p, c.x, c.y - 6 * u, 26 * u, Color("#3affd8"), 0.35, false)
			for k in 6:
				var b := c + Vector2(p.rng.randf_range(-16, 16), p.rng.randf_range(-6, 8)) * u
				var hgt := p.rng.randf_range(6, 14) * u
				Decals._stick(p, b, b + Vector2(0, -hgt), 2.2 * u, Color("#a8b8a8"))
				var cap := b + Vector2(0, -hgt)
				p.fill_poly(Cave._ellipse(cap, p.rng.randf_range(4, 7) * u, 2.8 * u, 16), func(x: int, y: int) -> Color:
					return Color("#6af0dc").lerp(Color("#1e6a64"), clampf((y - cap.y) / (3.0 * u) * 0.5 + 0.4, 0.0, 1.0)))
				Ink.path(p, Cave._ellipse(cap, 6 * u, 2.8 * u, 16), 0.8 * u, true, Color("#0a2422"), 0.6, 0.3)
		"wolf_den":
			Decals._blob(p, c, 26 * u, Color("#4a4034"), 0.9, 0.3)
			for k in 40:  # 털·마른 풀
				var q := c + Vector2(p.rng.randf_range(-22, 22), p.rng.randf_range(-13, 13)) * u
				var d := Vector2.from_angle(p.rng.randf() * TAU) * p.rng.randf_range(3, 7) * u
				Ink.line(p, q, q + d, 0.9 * u, Color("#8a7a62") if p.rng.randf() < 0.6 else Color("#2a2420"), 0.8, 0.4)
			Decals._bones(p, c + Vector2(8, 2) * u, u * 1.2)
		"gnome_trinkets":
			Decals._blob(p, c, 16 * u, Color("#4a3c2c"), 0.6, 0.3)
			for k in 10:
				var q := c + Vector2(p.rng.randf_range(-15, 15), p.rng.randf_range(-8, 8)) * u
				var col := [Color("#c9a24a"), Color("#8ab0c8"), Color("#a86a48"), Color("#d8d0c0")][k % 4] as Color
				Cave._stone(p, q, 2.4 * u, 2.0 * u, col)
				Decals._spot(p, q - Vector2(1, 1) * u, 0.8 * u, Color("#fff8e0"), 0.9)
		"gnome_stash":
			_shadow(p, c, 22 * u, 10 * u)
			Cave._stone(p, c, 20 * u, 13 * u, Color("#4a3c2c"))  # 진흙 둔덕
			Decals._blob(p, c + Vector2(2, 2) * u, 6 * u, Color("#0e0a08"), 0.95, 0.2)  # 구멍
			for k in 4:
				Decals._spot(p, c + Vector2(p.rng.randf_range(-3, 6), p.rng.randf_range(0, 5)) * u, 1.1 * u, Color("#ffe080"), 1.0)
		"goblin_camp":
			Ink.glow(p, c.x, c.y - 8 * u, 34 * u, Color("#ff9a40"), 0.45, false)
			Decals._blob(p, c, 14 * u, Color("#2a2420"), 0.9, 0.2)
			for k in 3:  # 삼각 꼬챙이
				var a := c + Vector2((k - 1) * 14, 6) * u
				Decals._stick(p, a, c + Vector2(0, -26) * u, 2.4 * u, WOOD)
			_flame(p, c + Vector2(0, -2) * u, 10 * u)
			var rag := PackedVector2Array([c + Vector2(16, 6) * u, c + Vector2(30, 2) * u, c + Vector2(32, 14) * u, c + Vector2(18, 16) * u])
			p.fill_poly(rag, func(x: int, y: int) -> Color: return p.vary(Color("#5a4a30"), x, y, 0.12))
			Ink.path(p, rag, 1.0 * u, true, Ink.INK, 0.6, 0.8)
		"torch_stubs":
			for k in 4:
				var b := c + Vector2(p.rng.randf_range(-18, 18), p.rng.randf_range(-6, 8)) * u
				var d := Vector2.from_angle(p.rng.randf() * TAU) * p.rng.randf_range(8, 13) * u
				Decals._stick(p, b - d, b + d, 3.2 * u, WOOD)
				Cave._dot(p, b + d, 3.0 * u, Color("#0e0a08"), 0.95)
		"old_skeleton":
			_shadow(p, c, 26 * u, 9 * u)
			_skeleton(p, c, u)
		"cairn":
			_shadow(p, foot, 16 * u, 6 * u)
			var y := foot.y
			for k in 6:
				var r := (13.0 - k * 1.7) * u
				Cave._stone(p, Vector2(foot.x + p.rng.randf_range(-2, 2) * u, y - r * 0.4), r, r * 0.6, STONE.lightened(k * 0.03))
				y -= r * 1.0
		"cache":
			_shadow(p, c, 20 * u, 8 * u)
			Cave._stone(p, c + Vector2(-6, -2) * u, 12 * u, 10 * u, CLOTH.lightened(0.05))  # 자루
			Ink.line(p, c + Vector2(-10, -11) * u, c + Vector2(-2, -11) * u, 1.6 * u, LEATHER, 0.9, 0.4)
			var box := PackedVector2Array([c + Vector2(4, -6) * u, c + Vector2(22, -6) * u, c + Vector2(22, 8) * u, c + Vector2(4, 8) * u])
			p.fill_poly(box, func(x: int, y: int) -> Color: return p.vary(WOOD, x, y, 0.1))
			Ink.path(p, box, 1.2 * u, true, Ink.INK, 0.85, 0.4)
			Ink.line(p, c + Vector2(4, 0) * u, c + Vector2(22, 0) * u, 1.6 * u, METAL, 0.8, 0.3)
		"goblin_snare":
			Decals._stick(p, c + Vector2(-14, 4) * u, c + Vector2(-12, -10) * u, 2.4 * u, WOOD)
			Ink.path(p, Cave._ellipse(c + Vector2(4, 2) * u, 12 * u, 6 * u, 18), 1.4 * u, true, Color("#8a7450"), 0.85, 1.0)
			Ink.line(p, c + Vector2(-12, -8) * u, c + Vector2(-8, 0) * u, 1.2 * u, Color("#8a7450"), 0.85, 0.8)
		"wet_slope":
			for k in 6:
				var a := c + Vector2(p.rng.randf_range(-24, 24), p.rng.randf_range(-14, 10)) * u
				Ink.line(p, a, a + Vector2(p.rng.randf_range(-4, 4), p.rng.randf_range(8, 14)) * u, 2.2 * u, Color("#a8c0d8"), 0.35, 0.6)
			Decals._blob(p, c, 24 * u, Color("#1a2232"), 0.4, 0.2)
		"portal", "rift_portal":
			var col := Color("#c8a0ff") if kind == "portal" else Color("#ff6a6a")
			Ink.glow(p, c.x, c.y, 34 * u, col, 0.5, false, 0.6)
			for r: float in [26.0, 20.0]:
				Ink.path(p, Cave._ellipse(c, r * u, r * 0.6 * u, 40), 1.8 * u, true, col.darkened(0.2), 0.85, 0.5)
			for k in 10:  # 고리 사이 문자
				var a := TAU * k / 10.0
				var q := c + Vector2(cos(a) * 23, sin(a) * 13.8) * u
				Ink.line(p, q - Vector2(1.5, 2) * u, q + Vector2(1.5, 2) * u, 1.2 * u, col.lightened(0.3), 0.9, 0.3)
				Ink.line(p, q + Vector2(-2, 0.5) * u, q + Vector2(1, 0.5) * u, 1.0 * u, col.lightened(0.3), 0.8, 0.3)
			Decals._blob(p, c, 12 * u, col.darkened(0.6), 0.5, 0.15)
		"rift_gate":  # 균열 탈출 포탈: 세로로 선 차원문 — 차원광장 포탈처럼 돌 고리 안에 보랏빛 소용돌이(사용자 2026-10-26)
			_gate(p, foot, u)
	return p


## 세로로 선 돌 고리(받침 돌 둘) + 안쪽 보랏빛 소용돌이(가운데 밝고 가장자리 진한 띠) + 테두리 빛·바닥 빛.
static func _gate(p: Paint, foot: Vector2, u: float) -> void:
	var violet := Color("#a070ff")
	var rx := 17.0 * u
	var ry := 27.0 * u
	var gc := foot - Vector2(0, ry + 7.0 * u)
	Ink.glow(p, foot.x, foot.y - 2 * u, 34 * u, violet, 0.45, false, 0.35)  # 바닥에 번진 빛
	_shadow(p, foot, 26 * u, 6 * u)
	var deep := Color("#170828")
	var mid := Color("#8a58e8")
	var core := Color("#efe2ff")
	p.fill_poly(Cave._ellipse(gc, rx, ry, 56), func(x: int, y: int) -> Color:
		var n := Vector2((x - gc.x) / rx, (y - gc.y) / ry)
		var d := minf(1.0, n.length())
		var band := pow(0.5 + 0.5 * sin(atan2(n.y, n.x) * 2.0 - d * 9.0 + p.nz("mid", x, y) * 1.2), 1.6)
		var c := deep.lerp(mid, band * (1.0 - d * 0.3))
		c = c.lerp(core, smoothstep(0.5, 0.0, d) * 0.9)
		c = c.lerp(Color("#c8a8ff"), smoothstep(0.82, 1.0, d) * 0.7)  # 안쪽 테가 밝다
		return c)
	for k in 18:  # 돌 고리(머릿돌이 위)
		var a := TAU * k / 18.0 - PI * 0.5
		var q := gc + Vector2(cos(a) * (rx + 4.5 * u), sin(a) * (ry + 4.5 * u))
		Cave._stone(p, q, 5.2 * u, 4.6 * u, STONE.darkened(0.25 if k != 0 else 0.1).lightened(p.rng.randf_range(-0.05, 0.05)))
	for s: float in [-1.0, 1.0]:  # 받침 돌
		Cave._stone(p, foot + Vector2(s * 13.0, -4.0) * u, 9.0 * u, 6.0 * u, STONE.darkened(0.35))
	Ink.path(p, Cave._ellipse(gc, rx, ry, 56), 1.6 * u, true, Color("#e0ccff"), 0.85, 0.3)
	Ink.glow(p, gc.x, gc.y, rx * 1.9, violet, 0.3, false, ry / rx)  # 고리 둘레로 번지는 빛


static func _shadow(p: Paint, c: Vector2, rx: float, ry: float) -> void:
	p.fill_poly(Cave._ellipse(c + Vector2(2, 3), rx, ry, 24), func(_x: int, _y: int) -> Color: return Color(0.04, 0.03, 0.04, 0.4))


## 쓰러진 탐험가: 탐험 맵 몸 그림 시트(paint_actors.gd — 옆모습 줄의 걸음 칸 col, 다리를 벌린 자세)를 각도 angle(라디안)로 눕혀
## 길이 length(px)로 c에 놓는다. 핏기 없게 어둡고 탁하게. 시트가 없으면 아무것도 그리지 않는다(맵 몸 그림을 먼저 그린다).
static func _lying_body(p: Paint, c: Vector2, length: float, angle: float, sheet_path: String, col: int) -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(sheet_path))
	if img == null or img.is_empty():
		return
	img.convert(Image.FORMAT_RGBA8)
	var cw := img.get_width() / 5
	var ch := img.get_height() / 4
	var src := img.get_region(Rect2i(col * cw, 2 * ch, cw, ch))  # 줄 2 = 오른쪽을 본 옆모습
	var used := src.get_used_rect()
	if used.size.y <= 0:
		return
	var k := length / float(used.size.y)  # 키 → 누운 길이
	var mid := Vector2(used.position) + Vector2(used.size) * 0.5
	var rot := Transform2D(angle, Vector2.ZERO)
	var inv := rot.affine_inverse()
	var reach := length * 0.6
	for y in range(int(c.y - reach), int(c.y + reach) + 1):
		for x in range(int(c.x - reach), int(c.x + reach) + 1):
			var s: Vector2 = inv * (Vector2(x, y) - c) / k + mid
			var sx := int(s.x)
			var sy := int(s.y)
			if sx < 0 or sy < 0 or sx >= cw or sy >= ch:
				continue
			var px := src.get_pixel(sx, sy)
			if px.a < 0.05:
				continue
			var g := px.r * 0.3 + px.g * 0.59 + px.b * 0.11
			var dead := Color(lerpf(px.r, g, 0.45), lerpf(px.g, g, 0.5), lerpf(px.b, g, 0.4)) * 0.62  # 핏기 없이 탁하게
			p.blend(x, y, Color(dead.r, dead.g, dead.b), px.a)


static func _skeleton(p: Paint, c: Vector2, u: float) -> void:
	Decals._stick(p, c + Vector2(-16, 0) * u, c + Vector2(10, 0) * u, 2.6 * u, BONE)  # 척추
	for k in 4:
		var x := -6.0 + k * 4.5
		for sgn: float in [-1.0, 1.0]:
			Ink.line(p, c + Vector2(x, 0) * u, c + Vector2(x + 2, sgn * 7) * u, 1.6 * u, BONE.darkened(0.08), 0.95, 0.3)
	Cave._stone(p, c + Vector2(17, 0) * u, 6 * u, 5.5 * u, BONE)  # 두개골
	Cave._dot(p, c + Vector2(17, -1.6) * u, 1.4 * u, Color("#1a1412"), 0.95)
	Cave._dot(p, c + Vector2(17, 1.8) * u, 1.4 * u, Color("#1a1412"), 0.95)
	for sgn: float in [-1.0, 1.0]:
		Decals._stick(p, c + Vector2(-16, sgn * 2) * u, c + Vector2(-32, sgn * 8) * u, 2.2 * u, BONE)  # 다리
		Decals._stick(p, c + Vector2(4, sgn * 5) * u, c + Vector2(-2, sgn * 18) * u, 1.8 * u, BONE)  # 팔


## 석순: 밑동이 넓고 끝이 뾰족한 원뿔(왼쪽 위 빛 — 왼쪽 면 밝게).
static func _spike(p: Paint, base: Vector2, r: float, hgt: float, col: Color) -> void:
	var tip := base + Vector2(r * 0.15, -hgt)
	var left := PackedVector2Array([base + Vector2(-r, 0), tip, base + Vector2(0, r * 0.35)])
	var right := PackedVector2Array([base + Vector2(0, r * 0.35), tip, base + Vector2(r, 0)])
	_shadow(p, base, r * 1.3, r * 0.45)
	p.fill_poly(left, func(x: int, y: int) -> Color: return p.vary(col.lightened(0.15), x, y, 0.08))
	p.fill_poly(right, func(x: int, y: int) -> Color: return p.vary(col.darkened(0.3), x, y, 0.08))
	Ink.path(p, PackedVector2Array([base + Vector2(-r, 0), tip, base + Vector2(r, 0)]), 1.2, false, Ink.INK, 0.8, 0.5)


static func _flame(p: Paint, c: Vector2, size: float) -> void:
	for k in 3:
		var s := size * (1.0 - k * 0.3)
		var col := [Color("#c83a12"), Color("#ff8a2a"), Color("#ffe0a0")][k] as Color
		var poly := PackedVector2Array([c + Vector2(-s * 0.6, 0), c + Vector2(-s * 0.2, -s * 0.9), c + Vector2(0, -s * 1.5),
			c + Vector2(s * 0.3, -s * 0.8), c + Vector2(s * 0.6, 0), c + Vector2(0, s * 0.25)])
		p.fill_poly(poly, func(_x: int, _y: int) -> Color: return col)
