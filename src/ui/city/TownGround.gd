class_name TownGround
extends Node2D
## 도시 동네 지도 바닥 청크(CT82): chunk×chunk 칸의 바닥(자갈·판석·광장·계단·흙·물)과 옹벽·성벽 앞면을 한 번 그린다(TownBrush — 재질 그림 × 색).
## 꼭짓점마다 둘레의 높은 칸(집·벽·옹벽)을 세어 구석 그늘을 넣는다. 지도 전체를 매 프레임 훑지 않는다 — 처음 한 번만 그린다(그 뒤는 Godot이 기억).
## 칸 높이(TownMap.height_at — 단 · 계단 · 수로, CT95)만큼 위로 올려 그리고, 남쪽 칸보다 높으면 그 차이만큼 앞면(옹벽 · 계단 단 · 둑)을 세운다.
## 청크는 북→남, 칸은 줄마다 북→남으로 그린다(낮은 남쪽 칸이 나중 — 북쪽이 높은 땅이라 겹치지 않는다).

const MAT := {"street": "cobble", "avenue": "slabs", "paving": "slabs", "plaza": "plaza", "stairs": "stairs", "bridge": "slabs",
	"yard": "dirt", "court": "dirt", "water": "water", "house": "cobble", "dais": "plaza"}
const TALL := ["house", "wall", "retain", "gate"]

var town: TownMap
var render: Dictionary
var rect: Rect2i
var tile: float = 32.0


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


func _draw() -> void:
	var b := TownBrush.new()
	var ao := TownBrush.num(render, "ground_ao", 0.13)
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var c := Vector2i(x, y)
			var k := town.ground_at(c)
			if k == "void":
				continue
			var h := town.height_at(c)
			var p := Vector2(x, y) * tile - Vector2(0, h * tile)
			var r := Rect2(p, Vector2(tile, tile))
			match k:
				"retain":  # 옹벽 윗면(갓돌)
					b.rect_v(r, TownBrush.shade(TownBrush.col(render, "retain"), 1.25), TownBrush.shade(TownBrush.col(render, "retain"), 1.05), "slabs")
				"wall":
					_face(b, c, k, r)
				"gate":
					b.rect_v(r, TownBrush.col(render, "gate"), TownBrush.shade(TownBrush.col(render, "gate"), 0.6))
				_:
					var base := TownBrush.col(render, k)
					var cols := PackedColorArray()
					for v: Vector2i in [c, c + Vector2i(1, 0), c + Vector2i(1, 1), c + Vector2i(0, 1)]:
						cols.append(TownBrush.shade(base, 1.0 - ao * _tall_around(v)))
					b.poly_cols(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
						cols, MAT.get(k, "cobble"))
			_drop(b, c, k, h, x, y)
	_litter(b)
	b.flush(self)


## 바닥에 흩어진 종이·부스러기(참고 그림처럼 — 칸마다 고정된 값으로 고른다, 무작위가 아니다).
func _litter(b: TownBrush) -> void:
	var chance := TownBrush.num(render, "litter", 0.035)
	var c := TownBrush.col(render, "litter")
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var k := town.ground_at(Vector2i(x, y))
			if not k in ["street", "avenue", "paving", "plaza", "yard"]:
				continue
			var h := absi(hash(Vector2i(x, y) * 7919)) % 10000
			if float(h) / 10000.0 >= chance:
				continue
			var p := (Vector2(x, y) + Vector2(float(h % 97) / 97.0, float(h % 89) / 89.0) * 0.8) * tile - Vector2(0, town.height_at(Vector2i(x, y)) * tile)
			var a := float(h % 360) * PI / 180.0
			var u := Vector2(cos(a), sin(a)) * (3.5 + h % 3)
			var v := Vector2(-u.y, u.x) * 0.7
			var cc := TownBrush.shade(c, 0.8 + float(h % 5) * 0.06)
			cc.a = 0.75
			b.poly(PackedVector2Array([p - u - v, p + u - v, p + u + v, p - u + v]), cc)


## 남쪽 칸보다 높으면 앞면(옹벽 · 계단 한 단 · 수로 둑): 마름돌, 위가 밝고 아래가 어둡다, 발치 그늘.
func _drop(b: TownBrush, c: Vector2i, k: String, h: float, x: int, y: int) -> void:
	var s := c + Vector2i.DOWN
	if town.ground_at(s) == "void":
		return
	var hs := town.height_at(s)
	if h - hs < 0.05:
		return
	var base := TownBrush.col(render, "retain")
	var stair := k == "stairs" and town.ground_at(s) == "stairs"
	var face := Rect2(Vector2(x, y + 1) * tile - Vector2(0, h * tile), Vector2(tile, (h - hs) * tile))
	if stair:
		b.rect_v(face, TownBrush.shade(TownBrush.col(render, "stairs"), 0.8), TownBrush.shade(TownBrush.col(render, "stairs"), 0.55))
		return
	b.rect_v(face, TownBrush.shade(base, 0.95), TownBrush.shade(base, 0.6), "ashlar")
	b.rect_v(Rect2(face.position, Vector2(tile, 4)), TownBrush.shade(base, 1.3), TownBrush.shade(base, 1.0))  # 갓돌 그림자 띠
	b.rect_v(Rect2(face.position + Vector2(0, face.size.y - 4), Vector2(tile, 4)), TownBrush.shade(base, 0.55), TownBrush.shade(base, 0.3))


## 옹벽·성벽: 아래 두 칸 안에 길이 있으면 앞면(마름돌 — 위가 밝고 아래가 어둡다), 아니면 위면(어두운 잡석).
func _face(b: TownBrush, c: Vector2i, k: String, r: Rect2) -> void:
	var base := TownBrush.col(render, k)
	var below := 0
	while below < 3 and town.ground_at(c + Vector2i(0, below + 1)) in [k, "gate"]:
		below += 1
	var run := 0
	while run < 4 and town.ground_at(c - Vector2i(0, run + 1)) == k:
		run += 1
	if k == "wall" and below >= 2:
		b.rect(r, TownBrush.col(render, "wall_top"), "rubble")
		return
	var top_k := 1.0 - 0.12 * run
	var bot_k := top_k - 0.12
	b.rect_v(r, TownBrush.shade(base, top_k), TownBrush.shade(base, bot_k), "ashlar")
	if town.ground_at(c - Vector2i(0, 1)) != k:  # 맨 윗줄 = 갓돌
		b.rect_v(Rect2(r.position, Vector2(r.size.x, 5)), TownBrush.shade(base, 1.25), TownBrush.shade(base, 1.05))
	if below == 0:  # 발치 그늘
		b.rect_v(Rect2(r.position + Vector2(0, r.size.y - 4), Vector2(r.size.x, 4)), TownBrush.shade(base, bot_k), TownBrush.shade(base, 0.35))


## 꼭짓점 v(칸 모서리)를 둘러싼 네 칸 중 높은 칸 수(0~4).
func _tall_around(v: Vector2i) -> int:
	var n := 0
	for d: Vector2i in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
		if town.kind_at(v + d) in TALL:
			n += 1
	return n
