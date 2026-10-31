extends RefCounted
## 시설 실내 소품 조각(RoomFurniture·RoomProps2 전용 — CT66): 판(윗면 + 앞면 띠 — 탐험 맵 벽 턱과 같은 눌린 시점) · 다리 · 책 더미 · 잉크병 · 초 · 기름 등.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Bits := preload("res://tools/city_art/InteriorBits.gd")
const RoomArt := preload("res://tools/city_art/RoomArt.gd")

const PAD := 10  ## 좌우 여백(px)


## 판(윗면) + 앞면 띠(두께 depth px). 윗면 = r(위에서 본 판).
static func _slab(p: Paint, r: Rect2, depth: float, top_sh: Callable, front_sh: Callable) -> void:
	var front := Paint.rect_poly(r.position.x, r.end.y, r.size.x, depth)
	p.fill_poly(front, front_sh)
	Ink.shade(p, front, Vector2(0, r.end.y), Vector2(0, r.end.y + depth), 0.1, 0.5)
	Ink.path(p, front, 2.0)
	var top := Paint.rect_poly(r.position.x, r.position.y, r.size.x, r.size.y)
	p.fill_poly(top, top_sh)
	Ink.shade(p, top, Vector2(0, r.position.y), Vector2(0, r.end.y), 0.0, 0.2)
	Ink.path(p, top, 2.0)


## 다리 넷(뒤 둘은 짧게 보인다) — 판 아래에서 바닥(판 앞면 아래 lift)까지.
static func _legs(p: Paint, r: Rect2, lift: float, c: Color, lw: float = 7.0) -> void:
	for lx: float in [r.position.x + 6, r.end.x - 6 - lw]:
		p.fill_rect(lx, r.position.y + 6, lw - 1, r.size.y - 6 + lift * 0.3, p.flat(c.darkened(0.3), 0.1))  # 뒷다리
		var leg := Paint.rect_poly(lx, r.end.y, lw, lift)
		p.fill_poly(leg, p.flat(c, 0.12))
		Ink.path(p, leg, 1.4)


static func _book_stack(p: Paint, base: Vector2, n: int) -> void:
	var y := base.y
	for i in n:
		var bw := p.rng.randf_range(20, 28)
		var b := Paint.rect_poly(base.x + p.rng.randf_range(-3, 3), y - 6, bw, 6)
		p.fill_poly(b, p.flat(Bits.BOOK_COLORS[p.rng.randi() % Bits.BOOK_COLORS.size()], 0.2))
		Ink.path(p, b, 1.1)
		y -= 6


static func _inkwell(p: Paint, c: Vector2) -> void:
	var pot := Paint.rect_poly(c.x - 4, c.y - 7, 8, 7)
	p.fill_poly(pot, p.flat(Color("#1a1a20"), 0.1))
	Ink.path(p, pot, 1.0)
	Ink.line(p, c + Vector2(1, -6), c + Vector2(12, -22), 1.6, Color("#d8d0b8"), 0.9, 0.2)  # 깃펜


static func _candle(p: Paint, base: Vector2, ch: float) -> void:
	var dish := Paint.rect_poly(base.x - 7, base.y - 3, 14, 4)
	p.fill_poly(dish, p.flat(Color("#4a4238"), 0.1))
	var body := Paint.rect_poly(base.x - 3, base.y - 3 - ch, 6, ch)
	p.fill_poly(body, p.flat(Color("#d8cfb4"), 0.1))
	Ink.path(p, body, 1.0)
	RoomArt._flame(p, Vector2(base.x, base.y - 4 - ch), 1.0)


static func _oil_lamp(p: Paint, base: Vector2) -> void:
	var bowl := Paint.poly([base + Vector2(-10, 0), base + Vector2(10, 0), base + Vector2(7, -8), base + Vector2(-7, -8)])
	p.fill_poly(bowl, p.flat(Color("#7a6238"), 0.12))
	Ink.path(p, bowl, 1.2)
	var chimney := Paint.rect_poly(base.x - 5, base.y - 26, 10, 18)
	p.fill_poly(chimney, p.flat(Color("#c8b890"), 0.1), 0.55)
	Ink.path(p, chimney, 1.0, true, Ink.INK, 0.6)
	RoomArt._flame(p, base + Vector2(0, -10), 0.9)
