class_name TownProp
extends Node2D
## 도시 동네 지도의 소품 하나(CT82): 가로등 · 정산 천막 · 공시판 · 통 · 상자 · 자루 · 안마당 우물 · 광장 돌 단과 돌 고리(포탈 — 평소엔 꺼짐).
## 노드 위치 = 발(칸 아래 가운데) — 발 높이로 앞뒤를 정한다. 거리의 통·상자는 뒤질 수 없다(사용자 2026-11-02 — 테두리 없음).

var kind: String = "lamp"
var size: Vector2 = Vector2(32, 32)  ## 차지한 칸 크기(세계 px)
var render: Dictionary
var tile: float = 32.0
var look: int = 0


func setup(p_kind: String, rect: Rect2i, p_render: Dictionary, p_tile: float) -> void:
	kind = p_kind
	render = p_render
	tile = p_tile
	size = Vector2(rect.size) * tile
	position = Vector2((rect.position.x + rect.size.x * 0.5) * tile, rect.end.y * tile)
	look = absi(rect.position.x * 31 + rect.position.y * 17)
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


func _c(key: String, i: int = 0) -> Color:
	return TownBrush.col(render, key, i)


func _draw() -> void:
	var b := TownBrush.new()
	b.ellipse(Vector2(0, -3), Vector2(size.x * 0.42, 5), Color(0, 0, 0, 0.35))
	match kind:
		"lamp":
			b.ellipse(Vector2(0, -44), Vector2(26, 22), Color(_c("lamp"), 0.08))
			b.rect_v(Rect2(-2, -44, 4, 44), _c("iron"), TownBrush.shade(_c("iron"), 0.6))
			b.rect(Rect2(-5, -4, 10, 4), _c("iron"))
			b.rect(Rect2(-6, -54, 12, 3), _c("iron"))
			b.rect_v(Rect2(-4.5, -51, 9, 9), _c("lamp"), TownBrush.shade(_c("lamp"), 0.75))
			b.poly(PackedVector2Array([Vector2(-7, -53), Vector2(7, -53), Vector2(0, -59)]), _c("iron"))
		"tent":
			var w := size.x
			var c := _c("awning")
			b.poly_cols(PackedVector2Array([Vector2(-w * 0.5, -6), Vector2(0, -size.y - 34), Vector2(0, -16)]), PackedColorArray([TownBrush.shade(c, 1.05), TownBrush.shade(c, 1.2), TownBrush.shade(c, 0.9)]), "wood")
			b.poly_cols(PackedVector2Array([Vector2(0, -16), Vector2(0, -size.y - 34), Vector2(w * 0.5, -6)]), PackedColorArray([TownBrush.shade(c, 0.7), TownBrush.shade(c, 0.85), TownBrush.shade(c, 0.6)]), "wood")
			b.poly(PackedVector2Array([Vector2(-12, -6), Vector2(0, -40), Vector2(12, -6)]), Color(0.06, 0.05, 0.04))
			b.rect_v(Rect2(-w * 0.5 + 10, -22, 30, 16), _c("door"), TownBrush.shade(_c("door"), 0.6), "wood")  # 정산 탁자
			b.rect(Rect2(-w * 0.5 + 18, -30, 14, 6), _c("iron"))  # 저울
		"board":
			b.rect_v(Rect2(-size.x * 0.5 + 2, -40, size.x - 4, 26), _c("door"), TownBrush.shade(_c("door"), 0.7), "wood")
			for k in 4:
				b.rect(Rect2(-size.x * 0.5 + 8 + k * 13, -36 + (k % 2) * 4, 10, 12), _c("frame"))
			b.rect(Rect2(-size.x * 0.5 + 4, -16, 4, 16), _c("timber"))
			b.rect(Rect2(size.x * 0.5 - 8, -16, 4, 16), _c("timber"))
		"barrel":
			b.rect_v(Rect2(-10, -24, 20, 22), TownBrush.shade(_c("door"), 1.3), TownBrush.shade(_c("door"), 0.8), "wood")
			b.ellipse(Vector2(0, -24), Vector2(10, 4), TownBrush.shade(_c("door"), 1.5), "wood", 16)
			b.rect(Rect2(-10, -19, 20, 2), _c("iron"))
			b.rect(Rect2(-10, -9, 20, 2), _c("iron"))
		"crate":
			b.rect_v(Rect2(-11, -14, 22, 14), TownBrush.shade(_c("cloth"), 1.0), TownBrush.shade(_c("cloth"), 0.7), "wood")
			b.rect(Rect2(-11, -22, 22, 8), TownBrush.shade(_c("cloth"), 1.25), "wood")
			b.line(Vector2(-11, -14), Vector2(11, 0), 1.5, TownBrush.shade(_c("cloth"), 0.5))
		"sacks":
			for k in 3:
				var sx := -9.0 + k * 9.0
				b.ellipse(Vector2(sx, -8 - (k % 2) * 5), Vector2(7, 8), TownBrush.shade(_c("cloth"), 1.0 + 0.1 * k), "dirt", 12)
		"well":
			b.ellipse(Vector2(0, -12), Vector2(16, 10), TownBrush.shade(_c("stone"), 1.1), "ashlar", 20)
			b.ellipse(Vector2(0, -12), Vector2(11, 6), Color(0.05, 0.06, 0.07), "", 16)
			b.rect(Rect2(-14, -40, 3, 28), _c("timber"))
			b.rect(Rect2(11, -40, 3, 28), _c("timber"))
			b.poly(PackedVector2Array([Vector2(-20, -38), Vector2(0, -50), Vector2(20, -38)]), _c("roofs", 1), "clay")
		"dais":
			_dais(b)
	b.flush(self)


## 광장 가운데 세 단 돌 단과 그 위 선 돌 고리(포탈 — 열리는 것은 하순 끝 차원광장 화면, M3에서 이 자리로).
func _dais(b: TownBrush) -> void:
	var r := size.x * 0.5
	var stone := _c("stone")
	for k in 3:  # 세 단: 앞쪽 옆면(어둡다) 위에 윗면 · 가장자리 밝은 테
		var rr := r - k * tile * 0.8
		var cy := -r - k * 12.0
		b.ellipse(Vector2(0, cy + 12), Vector2(rr, rr), TownBrush.shade(_c("stone_dark"), 0.55), "ashlar", 40)
		b.ellipse(Vector2(0, cy), Vector2(rr, rr), TownBrush.shade(stone, 1.2), "", 40)
		b.ellipse(Vector2(0, cy), Vector2(rr - 3, rr - 3), TownBrush.shade(_c("stone_dark"), 1.0 + 0.08 * k), "rubble", 40)
	var foot := Vector2(0, -r - 28)
	var R := tile * 1.7
	var th := 14.0
	var ring := _c("ring")
	var ctr := foot - Vector2(0, R)
	b.ellipse(ctr, Vector2(R - th, R - th), Color(0.05, 0.05, 0.06, 0.55), "", 32)  # 고리 안(꺼진 포탈 — 어둑하다)
	for i in 32:  # 선 고리(두께 있는 원 — 조각마다 빛)
		var a0 := TAU * i / 32.0
		var a1 := TAU * (i + 1) / 32.0
		var o0 := ctr + Vector2(cos(a0), sin(a0)) * R
		var o1 := ctr + Vector2(cos(a1), sin(a1)) * R
		var i0 := ctr + Vector2(cos(a0), sin(a0)) * (R - th)
		var i1 := ctr + Vector2(cos(a1), sin(a1)) * (R - th)
		var k := 0.85 + 0.35 * -cos((a0 + a1) * 0.5 + 0.8)
		b.poly(PackedVector2Array([o0, o1, i1, i0]), TownBrush.shade(ring, k), "rubble")
	for i in 8:  # 새긴 홈
		var a := TAU * i / 8.0
		b.line(ctr + Vector2(cos(a), sin(a)) * (R - th), ctr + Vector2(cos(a), sin(a)) * R, 2.0, TownBrush.shade(ring, 0.5))
	b.rect_v(Rect2(-R * 0.8, foot.y - 6, R * 1.6, 10), TownBrush.shade(stone, 1.1), TownBrush.shade(stone, 0.7), "ashlar")
