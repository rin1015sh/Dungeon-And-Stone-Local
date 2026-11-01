class_name DoorArt
extends RefCounted
## 문 그림(WallDoors가 찾은 문 하나 — 사용자 2026-11-01 "다 똑같으면 부조화 — 네모 문, 아치, 큰 대문 등 진짜 있을 법한 통로 연결부", AM64).
## 문 모양 = 문설주 벽 타일 art.doors 목록에서 자리마다 하나(해시 — 같은 자리는 늘 같다). 같은 모양도 자리마다 높이·기울기가 조금씩 다르다.
##   square  네모 돌 문틀(평평한 인방 + 문설주 띠)          round   둥근 아치(띠 + 쐐기돌)
##   pointed 뾰족 아치(띠)                                   gate    큰 대문(넓은 둥근 아치 + 두 겹 띠 + 쐐기돌 + 올려 둔 쇠창살 이빨 — 3칸 이상만)
##   rough   자연 굴 입구(울퉁불퉁한 아치, 띠 없음)          cave    매끈한 굴 입구(둥근 아치, 띠 없음)
##   timber  갱도 버팀목(기둥 둘 + 나무 들보)
## 지은 문(square·round·pointed·gate)은 돌 문틀 띠 + 문설주 + 문지방, 자연 굴(rough·cave)은 벽 그림만.
## 그림: 인방(벽 앞면 그림을 이어서 — 위에 덮을 뿐, 그 아래로 뒤 통로가 보인다) → 장식 → 먹선 → 위 검은 벽 머리(윗변이 U자로 둥글다).
## 수치(앞면 높이 비율)는 render.json view.door.kinds.<모양> {spring, crown}이 덮어쓴다.

const STRIPS := 6     ## 칸마다 인방을 나누는 토막
const TRIM := 5.0     ## 돌 문틀 띠 폭(px)
const KINDS := ["square", "round", "pointed", "gate", "rough", "cave", "timber"]
const DEFAULTS := {
	"square": {"spring": 0.16, "crown": 0.16}, "round": {"spring": 0.42, "crown": 0.12}, "pointed": {"spring": 0.5, "crown": 0.06},
	"gate": {"spring": 0.36, "crown": 0.08}, "rough": {"spring": 0.4, "crown": 0.14}, "cave": {"spring": 0.5, "crown": 0.1},
	"timber": {"spring": 0.2, "crown": 0.2},
}
static var kinds: Dictionary = {}


static func configure(cfg: Dictionary) -> void:
	kinds = JsonUtil.get_dict(cfg, "kinds")


## 자리(서쪽 문 칸 x, 줄)마다 고르는 모양. gate는 3칸 이상만(좁으면 목록의 다음 모양).
static func pick(def: TileDef, x0: int, x1: int, row: int) -> String:
	var list := def.art_doors if not def.art_doors.is_empty() else PackedStringArray(["round"])
	var hsh := absi(hash(Vector2i(x0 * 7 + 3, row)))
	for k in list.size():
		var kind := list[(hsh + k) % list.size()]
		if kind != "gate" or x1 - x0 + 1 >= 3:
			return kind
	return "round"


static func draw(view: FloorView, cv: CanvasItem, row: int, door: Dictionary) -> void:
	var map := view.map
	var xa_cell := int(door["x0"])
	var xb_cell := int(door["x1"])
	if map.explored[row * map.width + xa_cell] == 0:
		return
	var def := map.defs[int(door["flank"])]
	var kind := pick(def, xa_cell, xb_cell, row)
	var t := float(view.tile)
	var h := float(view.wall_face_of(def))
	var xa := xa_cell * t
	var xb := (xb_cell + 1) * t
	var top := -h  # 줄 아래 가장자리(바닥 선) 기준
	var hsh := absi(hash(Vector2i(xa_cell, row * 13 + 5)))
	var jit := (float(hsh % 1000) / 1000.0 - 0.5)  # 자리마다 -0.5~0.5
	var cfg: Dictionary = DEFAULTS[kind].merged(JsonUtil.get_dict(kinds, kind), true)
	var spring_y := top + h * (float(cfg["spring"]) + jit * 0.08)
	var crown_y := top + h * clampf(float(cfg["crown"]) + jit * 0.04, 0.04, 0.4)
	var skew := jit * 0.35 if kind == "rough" else 0.0  # 자연 굴은 꼭대기가 한쪽으로
	var edge := func(x: float) -> float: return _edge(kind, (x - xa) / (xb - xa), spring_y, crown_y, skew, hsh, h)
	var lit := func(x: float) -> Color: return _light(view, def, x, row)  # 그림에 곱하는 빛 배율(인방)
	var face := def.color_face
	var tone := func(x: float) -> Color:  # 그림 없는 장식의 색 = 앞면 색 × 빛
		var m := _light(view, def, x, row)
		return Color(face.r * m.r, face.g * m.g, face.b * m.b, m.a)
	var batch := QuadBatch.new()
	_lintel(view, batch, def, row, xa_cell, xb_cell, top, edge, lit)
	match kind:
		"square", "round", "pointed", "gate":
			_trim(batch, xa, xb, edge, tone, 1.4, 0.0)
			if kind == "gate":
				_trim(batch, xa, xb, edge, tone, 0.9, TRIM)
			if kind in ["round", "gate"]:
				_keystone(batch, (xa + xb) * 0.5, top, crown_y, tone)
			_jambs(batch, xa, xb, edge, tone)
			_sill(batch, xa, xb, tone)
		"timber":
			_timber(view, batch, xa, xb, top, h, crown_y, lit)
	batch.flush(cv)
	if kind == "gate":
		_teeth(cv, xa, xb, edge, tone)
	var ink := PackedVector2Array()
	var steps := (xb_cell - xa_cell + 1) * STRIPS
	for k in steps + 1:
		var x := xa + (xb - xa) * float(k) / steps
		ink.append(Vector2(x, edge.call(x)))
	var l: Color = tone.call((xa + xb) * 0.5)
	if kind != "timber":
		cv.draw_polyline(ink, Color(l.r * 0.3, l.g * 0.3, l.b * 0.3, l.a), 1.2)
	_head(view, cv, xa, xb, top, t)


## 문 윗변 y(u = 0 서쪽 ~ 1 동쪽).
static func _edge(kind: String, u: float, spring_y: float, crown_y: float, skew: float, hsh: int, h: float) -> float:
	u = clampf(u, 0.0, 1.0)
	match kind:
		"square", "timber":
			return crown_y
		"pointed":
			return spring_y - (spring_y - crown_y) * sqrt(maxf(0.0, 1.0 - absf(u * 2.0 - 1.0)))
		"rough":
			var w := clampf(u + skew * sin(u * PI), 0.0, 1.0)
			var v := w * 2.0 - 1.0
			var base := spring_y - (spring_y - crown_y) * sqrt(maxf(0.0, 1.0 - v * v))
			var ph := float(hsh % 628) / 100.0
			return base + h * 0.05 * (sin(u * 17.0 + ph) + 0.6 * sin(u * 37.0 + ph * 2.0)) * sin(u * PI)
	var c := u * 2.0 - 1.0
	return spring_y - (spring_y - crown_y) * sqrt(maxf(0.0, 1.0 - c * c))


## 인방: 앞면 위 선부터 문 윗변까지 벽 앞면 그림(칸마다 그 변형, 앞면과 같은 빛).
static func _lintel(view: FloorView, batch: QuadBatch, def: TileDef, row: int, xa_cell: int, xb_cell: int, top: float, edge: Callable, lit: Callable) -> void:
	var t := float(view.tile)
	var tex := view.tile_tex[def.index]
	var n := maxi(1, def.art_variants)
	var split := clampf((float(tex.get_width()) / n) / tex.get_height(), 0.0, 1.0) if tex != null else 0.0
	var span := float(view.wall_face_of(def)) + float(view.wall_skirt)
	var pts := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	var cols := PackedColorArray([Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK])
	var uvs := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	for cell in range(xa_cell, xb_cell + 1):
		var col := float(FloorArtLayer.variant(cell, row, n, def.art_salt + 1))
		for k in STRIPS:
			var x0 := (cell + float(k) / STRIPS) * t
			var x1 := (cell + float(k + 1) / STRIPS) * t
			var y0: float = edge.call(x0)
			var y1: float = edge.call(x1)
			var l0: Color = lit.call(x0)
			var l1: Color = lit.call(x1)
			_quad(pts, Vector2(x0, top), Vector2(x1, top), Vector2(x1, y1), Vector2(x0, y0))
			cols[0] = l0
			cols[1] = l1
			cols[2] = l1
			cols[3] = l0
			if tex != null:
				var hx := 0.5 / tex.get_width()
				var u0 := clampf((col + float(k) / STRIPS) / n, col / n + hx, (col + 1.0) / n - hx)
				var u1 := clampf((col + float(k + 1) / STRIPS) / n, col / n + hx, (col + 1.0) / n - hx)
				uvs[0] = Vector2(u0, split)
				uvs[1] = Vector2(u1, split)
				uvs[2] = Vector2(u1, split + (y1 - top) / span * (1.0 - split))
				uvs[3] = Vector2(u0, split + (y0 - top) / span * (1.0 - split))
				batch.add(pts, cols, uvs, tex)
			else:
				batch.add(pts, cols)


## 돌 문틀 띠: 문 윗변 위쪽 TRIM px(off만큼 더 위) — 밝기 k배.
static func _trim(batch: QuadBatch, xa: float, xb: float, edge: Callable, lit: Callable, k: float, off: float) -> void:
	var pts := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	var cols := PackedColorArray([Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK])
	var steps := maxi(4, int((xb - xa) / 4.0))
	for i in steps:
		var x0 := xa + (xb - xa) * float(i) / steps
		var x1 := xa + (xb - xa) * float(i + 1) / steps
		var y0: float = edge.call(x0) - off
		var y1: float = edge.call(x1) - off
		_quad(pts, Vector2(x0, y0 - TRIM), Vector2(x1, y1 - TRIM), Vector2(x1, y1), Vector2(x0, y0))
		var c0: Color = lit.call(x0)
		var c1: Color = lit.call(x1)
		cols[0] = Color(c0.r * k, c0.g * k, c0.b * k, c0.a)
		cols[1] = Color(c1.r * k, c1.g * k, c1.b * k, c1.a)
		cols[2] = Color(c1.r * k * 0.7, c1.g * k * 0.7, c1.b * k * 0.7, c1.a)
		cols[3] = Color(c0.r * k * 0.7, c0.g * k * 0.7, c0.b * k * 0.7, c0.a)
		batch.add(pts, cols)


## 문설주 띠: 문 양옆 안쪽에 윗변부터 바닥 선까지(빛 받는 서쪽 밝게 · 안쪽 먹선).
static func _jambs(batch: QuadBatch, xa: float, xb: float, edge: Callable, tone: Callable) -> void:
	var pts := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	var cols := PackedColorArray([Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK])
	for side: int in [0, 1]:
		var x := xa if side == 0 else xb - TRIM
		var y: float = edge.call(xa + TRIM * 0.5 if side == 0 else xb - TRIM * 0.5)
		var c: Color = tone.call(x)
		var hi := Color(c.r * 1.35, c.g * 1.35, c.b * 1.35, c.a)
		var lo := Color(c.r * 0.75, c.g * 0.75, c.b * 0.75, c.a)
		_quad(pts, Vector2(x, y), Vector2(x + TRIM, y), Vector2(x + TRIM, 0.0), Vector2(x, 0.0))
		cols[0] = hi if side == 0 else lo
		cols[1] = lo if side == 0 else hi
		cols[2] = cols[1]
		cols[3] = cols[0]
		batch.add(pts, cols)
		var ix := x + TRIM if side == 0 else x  # 안쪽 먹선
		_quad(pts, Vector2(ix - 0.6, y), Vector2(ix + 0.6, y), Vector2(ix + 0.6, 0.0), Vector2(ix - 0.6, 0.0))
		var ink := Color(c.r * 0.3, c.g * 0.3, c.b * 0.3, c.a)
		for k in 4:
			cols[k] = ink
		batch.add(pts, cols)


## 문지방: 문 아래 바닥 선에 걸친 얕은 돌 턱(위 밝게).
static func _sill(batch: QuadBatch, xa: float, xb: float, tone: Callable) -> void:
	var c: Color = tone.call((xa + xb) * 0.5)
	var pts := PackedVector2Array([Vector2(xa, -3.0), Vector2(xb, -3.0), Vector2(xb, 1.5), Vector2(xa, 1.5)])
	var hi := Color(c.r * 1.3, c.g * 1.3, c.b * 1.3, c.a)
	var lo := Color(c.r * 0.6, c.g * 0.6, c.b * 0.6, c.a)
	batch.add(pts, PackedColorArray([hi, hi, lo, lo]))


## 쐐기돌: 아치 꼭대기에 인방을 꿰뚫는 사다리꼴(밝게).
static func _keystone(batch: QuadBatch, cx: float, top: float, crown_y: float, lit: Callable) -> void:
	var c: Color = lit.call(cx)
	var pts := PackedVector2Array([Vector2(cx - 4.5, top + 1.0), Vector2(cx + 4.5, top + 1.0), Vector2(cx + 3.0, crown_y), Vector2(cx - 3.0, crown_y)])
	var hi := Color(c.r * 1.45, c.g * 1.45, c.b * 1.45, c.a)
	batch.add(pts, PackedColorArray([hi, hi, Color(c.r * 1.1, c.g * 1.1, c.b * 1.1, c.a), Color(c.r * 1.1, c.g * 1.1, c.b * 1.1, c.a)]))


## 갱도 버팀목: 문 양옆 나무 기둥 + 그 위 들보(인방 아래쪽에 걸친다).
static func _timber(view: FloorView, batch: QuadBatch, xa: float, xb: float, top: float, h: float, beam_y: float, lit: Callable) -> void:
	var wood := Abyss.color(view.art, "beam_color", "#4a3824")
	var pts := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	var cols := PackedColorArray([Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK])
	var post := 5.0
	for side: int in [0, 1]:
		var x := xa if side == 0 else xb - post
		var c: Color = lit.call(x)
		_quad(pts, Vector2(x, beam_y), Vector2(x + post, beam_y), Vector2(x + post, 0.0), Vector2(x, 0.0))
		cols[0] = Color(wood.r * c.r * 1.5, wood.g * c.g * 1.5, wood.b * c.b * 1.5, c.a)
		cols[1] = Color(wood.r * c.r * 0.8, wood.g * c.g * 0.8, wood.b * c.b * 0.8, c.a)
		cols[2] = cols[1]
		cols[3] = cols[0]
		batch.add(pts, cols)
	var c: Color = lit.call((xa + xb) * 0.5)
	var bh := h * 0.09
	_quad(pts, Vector2(xa - 3.0, beam_y - bh), Vector2(xb + 3.0, beam_y - bh), Vector2(xb + 3.0, beam_y), Vector2(xa - 3.0, beam_y))
	cols[0] = Color(wood.r * c.r * 1.6, wood.g * c.g * 1.6, wood.b * c.b * 1.6, c.a)
	cols[1] = cols[0]
	cols[2] = Color(wood.r * c.r * 0.7, wood.g * c.g * 0.7, wood.b * c.b * 0.7, c.a)
	cols[3] = cols[2]
	batch.add(pts, cols)


## 큰 대문의 올려 둔 쇠창살: 아치 윗변에서 내려온 짧은 뾰족 이빨.
static func _teeth(cv: CanvasItem, xa: float, xb: float, edge: Callable, lit: Callable) -> void:
	var c: Color = lit.call((xa + xb) * 0.5)
	var iron := Color(c.r * 0.35, c.g * 0.35, c.b * 0.38, c.a)
	var x := xa + 6.0
	while x < xb - 5.0:
		var y: float = edge.call(x)
		cv.draw_colored_polygon(PackedVector2Array([Vector2(x - 1.2, y - 1.0), Vector2(x + 1.2, y - 1.0), Vector2(x + 1.2, y + 5.0), Vector2(x, y + 8.0), Vector2(x - 1.2, y + 5.0)]), iron)
		x += 6.0
	var bar := PackedVector2Array()
	for k in 13:
		var bx := xa + 6.0 + (xb - xa - 12.0) * k / 12.0
		bar.append(Vector2(bx, edge.call(bx) + 3.0))
	cv.draw_polyline(bar, iron, 1.5)


## 문 위 검은 벽 머리(문 칸 윗면 자리): 아래 = 앞면 위 선, 윗변 = 가운데가 낮은 U자(뒤 통로 바닥이 둥글게 이어진다).
static func _head(view: FloorView, cv: CanvasItem, xa: float, xb: float, top: float, t: float) -> void:
	var w := xb - xa
	var r := minf(t * 0.6, w * 0.35)
	var poly := PackedVector2Array([Vector2(xa, top), Vector2(xb, top)])
	var steps := 16
	for k in steps + 1:
		var u := 1.0 - float(k) / steps
		var v := u * 2.0 - 1.0
		poly.append(Vector2(xa + w * u, top - t - r * (1.0 - sqrt(maxf(0.0, 1.0 - v * v)))))
	cv.draw_colored_polygon(poly, view.art.unexplored)


## 바닥 선 위 x(월드 px)에 가장 가까운 꼭짓점의 빛 × 면 그늘(WallRow 앞면과 같은 빛).
static func _light(view: FloorView, def: TileDef, x: float, row: int) -> Color:
	var vx := clampi(roundi(x / view.tile), 0, view.map.width)
	var c := view.vertex_mul(vx, row + 1, def.color_face)
	var k := view.face_shade
	return Color(c.r * k, c.g * k, c.b * k, c.a)


static func _quad(pts: PackedVector2Array, a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> void:
	pts[0] = a
	pts[1] = b
	pts[2] = c
	pts[3] = d
