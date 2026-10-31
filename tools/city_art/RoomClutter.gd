extends RefCounted
## 시설 실내 잡동사니 가구 — 칸마다 하나씩 세우는 작은 것(RoomFurniture2 전용, CT68 "조금 어지럽혀도 되니 실제 같은 느낌으로"):
## stool 둥근 걸상 · chest 쇠띠 궤 · basket 바구니(variant apples·bread·onions·wool·herbs) · bucket 양동이 · plant 화분 · broom 빗자루 ·
## crates 쌓은 궤짝 · candle 바닥 촛대(빛) · books 책 더미 · coat 옷걸이(망토) · logs 장작 묶음 · cask 누운 술통 · lantern 바닥 등(빛) ·
## jug 물동이 · cheese 치즈 바퀴 · bottles 빈 병 · stack 접시 더미 · spear 기대 세운 창 · mop 대걸레.
## 무리 칸마다 그 칸 아래쪽(발)에 세운다. 불꽃이 있으면 그 자리를 돌려준다.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Bits := preload("res://tools/city_art/InteriorBits.gd")
const Props := preload("res://tools/city_art/Props.gd")

## 칸 크기에 곱하는 그림 높이(RoomFurniture2 캔버스).
const HEIGHT := {"stool": 0.6, "chest": 0.7, "basket": 0.6, "bucket": 0.6, "plant": 1.2, "broom": 1.3, "crates": 1.3, "candle": 1.3,
	"books": 0.6, "coat": 1.6, "logs": 0.7, "cask": 0.8, "lantern": 0.8, "jug": 0.8, "cheese": 0.5, "bottles": 0.6, "stack": 0.5,
	"spear": 1.8, "mop": 1.3}
const BASKET := {"apples": "#9a2e22", "bread": "#b8864a", "onions": "#c8a868", "wool": "#d8d0c0", "herbs": "#4a6a34", "potatoes": "#8a6a44"}


static func shapes() -> Array:
	return HEIGHT.keys()


static func one(p: Paint, shape: String, d: Dictionary, col: Color, cx: float, g: float, t: int) -> Vector2:
	match shape:
		"stool":
			for lx: float in [-0.18, 0.0, 0.18]:
				Ink.line(p, Vector2(cx + lx * t, g), Vector2(cx + lx * t * 0.6, g - t * 0.36), 3.0, col.darkened(0.35), 1.0, 0.1)
			var top := _ellipse(Vector2(cx, g - t * 0.4), t * 0.24, t * 0.1)
			p.fill_poly(top, p.flat(col, 0.12))
			Ink.path(p, top, 1.4)
		"chest":
			var body := Paint.rect_poly(cx - t * 0.38, g - t * 0.42, t * 0.76, t * 0.42)
			p.fill_poly(body, Mat.planks(p, col, 0, 0, false, 8))
			var lid := Paint.poly([Vector2(cx - t * 0.38, g - t * 0.42), Vector2(cx - t * 0.32, g - t * 0.62), Vector2(cx + t * 0.32, g - t * 0.62), Vector2(cx + t * 0.38, g - t * 0.42)])
			p.fill_poly(lid, p.flat(col.lightened(0.12), 0.12))
			for bx: float in [-0.24, 0.24]:
				Ink.line(p, Vector2(cx + bx * t, g - t * 0.62), Vector2(cx + bx * t, g), 3.0, Color("#3a3a3c"), 1.0, 0.1)
			p.fill_rect(cx - 3, g - t * 0.44, 6, 7, p.flat(Color("#c8a048"), 0.1))
			Ink.path(p, body, 1.5)
			Ink.path(p, lid, 1.5)
		"basket":
			var b := Paint.poly([Vector2(cx - t * 0.3, g - t * 0.36), Vector2(cx + t * 0.3, g - t * 0.36), Vector2(cx + t * 0.22, g), Vector2(cx - t * 0.22, g)])
			p.fill_poly(b, func(x: int, y: int) -> Color: return p.vary(Color("#8a6a3a").darkened(0.25 if posmod(x + y, 6) < 2 else 0.0), x, y, 0.1))
			var fill := Color(BASKET.get(JsonUtil.get_str(d, "variant"), "#9a2e22") as String)
			for k in 5:
				var c := Vector2(cx + (k - 2) * t * 0.1, g - t * 0.4 - (k % 2) * 4)
				p.fill_poly(_ellipse(c, t * 0.08, t * 0.07), p.flat(fill.lightened(p.rng.randf_range(-0.1, 0.12)), 0.1))
				Ink.path(p, _ellipse(c, t * 0.08, t * 0.07), 0.9, true, Ink.INK, 0.6)
			Ink.path(p, b, 1.4)
		"bucket":
			var b := Paint.poly([Vector2(cx - t * 0.2, g - t * 0.42), Vector2(cx + t * 0.2, g - t * 0.42), Vector2(cx + t * 0.16, g), Vector2(cx - t * 0.16, g)])
			p.fill_poly(b, Mat.planks(p, col, 0, 0, true, 6))
			for by: float in [0.12, 0.32]:
				Ink.line(p, Vector2(cx - t * 0.19, g - t * by), Vector2(cx + t * 0.19, g - t * by), 2.0, Color("#3a3a3c"), 1.0, 0.05)
			p.fill_poly(_ellipse(Vector2(cx, g - t * 0.42), t * 0.19, t * 0.06), p.flat(Color("#2a3a44"), 0.15))
			Ink.path(p, b, 1.4)
			Ink.path(p, _arc(Vector2(cx, g - t * 0.42), t * 0.2, PI, TAU), 1.4, false)
		"plant":
			var pot := Paint.poly([Vector2(cx - t * 0.2, g - t * 0.36), Vector2(cx + t * 0.2, g - t * 0.36), Vector2(cx + t * 0.14, g), Vector2(cx - t * 0.14, g)])
			for k in 9:
				var a := Vector2(cx, g - t * 0.36)
				var tip := a + Vector2.from_angle(-PI * (0.15 + 0.7 * k / 8.0)) * t * p.rng.randf_range(0.4, 0.7)
				Ink.line(p, a, tip, 5.0, Color("#3a5a2e").lightened(p.rng.randf_range(-0.1, 0.15)), 1.0, 0.4)
			p.fill_poly(pot, p.flat(Color("#9a5236"), 0.12))
			Ink.path(p, pot, 1.4)
		"broom":
			Ink.line(p, Vector2(cx + t * 0.18, g - t * 1.2), Vector2(cx - t * 0.02, g - t * 0.35), 3.0, Color("#7a5a3a"), 1.0, 0.1)
			var head := Paint.poly([Vector2(cx - t * 0.06, g - t * 0.38), Vector2(cx + t * 0.04, g - t * 0.38), Vector2(cx + t * 0.14, g), Vector2(cx - t * 0.2, g)])
			p.fill_poly(head, p.flat(Color("#b89a5a"), 0.15))
			Ink.path(p, head, 1.2)
		"crates":
			Props.crate(p, cx, g, t * 0.72)
			Props.crate(p, cx + t * 0.04, g - t * 0.68, t * 0.56)
		"candle":
			Ink.line(p, Vector2(cx - t * 0.12, g), Vector2(cx + t * 0.12, g), 4.0, Color("#3a3226"), 1.0, 0.1)
			Ink.line(p, Vector2(cx, g), Vector2(cx, g - t * 1.0), 3.0, Color("#6a5a3a"), 1.0, 0.1)
			Props.candle(p, cx, g - t * 1.0, 14.0)
			return Vector2(cx, g - t * 1.0 - 18)
		"books":
			Bits.book_pile(p, cx - t * 0.25, g, 3 + p.rng.randi() % 3)
		"coat":
			Ink.line(p, Vector2(cx - t * 0.18, g), Vector2(cx + t * 0.18, g), 4.0, Color("#3a281b"), 1.0, 0.1)
			Ink.line(p, Vector2(cx, g), Vector2(cx, g - t * 1.5), 4.0, Color("#4a3424"), 1.0, 0.1)
			var cloak := Paint.poly([Vector2(cx - t * 0.08, g - t * 1.4), Vector2(cx + t * 0.12, g - t * 1.4), Vector2(cx + t * 0.26, g - t * 0.5), Vector2(cx - t * 0.18, g - t * 0.55)])
			p.fill_poly(cloak, p.flat(col, 0.15))
			Ink.path(p, cloak, 1.4)
			p.fill_poly(_ellipse(Vector2(cx - t * 0.02, g - t * 1.52), t * 0.18, t * 0.07), p.flat(Color("#3a2e24"), 0.1))
		"logs":
			for k in 5:
				var c := Vector2(cx + ((k % 3) - 1) * t * 0.22 + (0.11 * t if k >= 3 else 0.0), g - t * 0.14 - (k / 3) * t * 0.2)
				p.fill_poly(_ellipse(c, t * 0.12, t * 0.11), p.flat(Color("#b89a6a"), 0.1))
				Ink.path(p, _ellipse(c, t * 0.12, t * 0.11), 1.2)
				p.fill_poly(_ellipse(c, t * 0.04, t * 0.04), p.flat(Color("#7a5a3a"), 0.1))
		"cask":
			var c := Vector2(cx, g - t * 0.3)
			for lx: float in [-0.26, 0.26]:
				Ink.line(p, Vector2(cx + lx * t, g), Vector2(cx + lx * t, g - t * 0.2), 4.0, Color("#3a281b"), 1.0, 0.1)
			var body := Paint.rect_poly(cx - t * 0.36, c.y - t * 0.22, t * 0.72, t * 0.44)
			p.fill_poly(body, Mat.planks(p, col, 0, 0, false, 7))
			Ink.path(p, body, 1.5)
			p.fill_poly(_ellipse(Vector2(cx + t * 0.36, c.y), t * 0.08, t * 0.22), p.flat(col.lightened(0.15), 0.1))
			for bx: float in [-0.2, 0.2]:
				Ink.line(p, Vector2(cx + bx * t, c.y - t * 0.22), Vector2(cx + bx * t, c.y + t * 0.22), 2.5, Color("#3a3a3c"), 1.0, 0.05)
		"lantern":
			var body := Paint.rect_poly(cx - t * 0.12, g - t * 0.42, t * 0.24, t * 0.36)
			p.fill_poly(body, p.flat(Color("#e8c070"), 0.1))
			Ink.path(p, body, 1.6)
			Ink.line(p, Vector2(cx, g - t * 0.42), Vector2(cx, g - t * 0.06), 1.5, Ink.INK, 0.7)
			p.fill_rect(cx - t * 0.15, g - t * 0.08, t * 0.3, t * 0.08, p.flat(Color("#2a2622"), 0.1))
			Ink.path(p, _arc(Vector2(cx, g - t * 0.44), t * 0.1, PI, TAU), 1.4, false)
			return Vector2(cx, g - t * 0.26)
		"jug":
			var u := Paint.poly([Vector2(cx - t * 0.08, g - t * 0.62), Vector2(cx + t * 0.08, g - t * 0.62), Vector2(cx + t * 0.24, g - t * 0.32), Vector2(cx + t * 0.14, g), Vector2(cx - t * 0.14, g), Vector2(cx - t * 0.24, g - t * 0.32)])
			p.fill_poly(u, func(x: int, y: int) -> Color: return p.vary(col.lightened(0.2 * clampf((cx - x) / (t * 0.24), -1.0, 1.0)), x, y, 0.1))
			Ink.path(p, u, 1.4)
			Ink.path(p, _arc(Vector2(cx + t * 0.2, g - t * 0.42), t * 0.1, -PI * 0.5, PI * 0.5), 1.6, false)
		"cheese":
			for k in 2:
				var c := Vector2(cx + (k - 0.5) * t * 0.3, g - t * 0.12 - k * t * 0.14)
				var w := Paint.rect_poly(c.x - t * 0.2, c.y - t * 0.08, t * 0.4, t * 0.16)
				p.fill_poly(w, p.flat(Color("#d8b860"), 0.1))
				p.fill_poly(_ellipse(Vector2(c.x, c.y - t * 0.08), t * 0.2, t * 0.06), p.flat(Color("#e8cc78"), 0.1))
				Ink.path(p, w, 1.2)
		"bottles":
			for k in 4:
				var bx := cx + (k - 1.5) * t * 0.14
				var bh := t * p.rng.randf_range(0.32, 0.46)
				var bc: Color = [Color("#2e4a2e"), Color("#4a2a1e"), Color("#6a7a6a")][k % 3]
				if k == 3:
					Ink.line(p, Vector2(bx - t * 0.2, g - 4), Vector2(bx + t * 0.1, g - 2), 6.0, bc, 1.0, 0.1)  # 쓰러진 병
					continue
				p.fill_rect(bx - 3, g - bh, 7, bh, p.flat(bc.lightened(0.1), 0.1))
				p.fill_rect(bx - 1.5, g - bh - 6, 4, 6, p.flat(bc, 0.1))
		"stack":
			for k in 4:
				var c := Vector2(cx, g - k * 4.0 - 4)
				p.fill_poly(_ellipse(c, t * 0.24, t * 0.08), p.flat(Color("#c8bca8").darkened(k * 0.04), 0.06))
				Ink.path(p, _ellipse(c, t * 0.24, t * 0.08), 1.0, true, Ink.INK, 0.6)
		"spear":
			Ink.line(p, Vector2(cx - t * 0.1, g), Vector2(cx + t * 0.08, g - t * 1.6), 3.0, Color("#6a4a2e"), 1.0, 0.1)
			p.fill_poly(Paint.poly([Vector2(cx + t * 0.04, g - t * 1.6), Vector2(cx + t * 0.14, g - t * 1.6), Vector2(cx + t * 0.12, g - t * 1.85)]), p.flat(Color("#9a9a98"), 0.06))
		"mop":
			Ink.line(p, Vector2(cx - t * 0.16, g - t * 1.2), Vector2(cx + t * 0.02, g - t * 0.25), 3.0, Color("#7a5a3a"), 1.0, 0.1)
			for k in 6:
				Ink.line(p, Vector2(cx, g - t * 0.25), Vector2(cx - t * 0.18 + k * t * 0.08, g), 2.0, Color("#a89c84"), 1.0, 0.3)
	return Vector2.ZERO


static func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 20:
		pts.append(c + Vector2.from_angle(TAU * i / 20.0) * Vector2(rx, ry))
	return pts


static func _arc(c: Vector2, r: float, a0: float, a1: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 11:
		pts.append(c + Vector2.from_angle(lerpf(a0, a1, i / 10.0)) * r)
	return pts
