class_name TownBrush
extends RefCounted
## 도시 동네 지도 그리기 붓(CT82): 재질 그림(assets/town/mat/<id>.webp — tools/paint_town.gd)을 세계 좌표로 이어 붙인 다각형을
## 넣은 순서대로 모았다가 한 번에 그린다(같은 그림이 이어지면 한 묶음 — QuadBatch와 달리 그림이 달라도 순서를 지킨다: 벽 위 창 위 지붕).
## 색은 꼭짓점 색으로 곱한다(재질 그림은 무채색). 노드에는 texture_repeat를 켜야 한다(TownWorld가 켠다).
##   b.poly(pts, color, "plaster") · b.poly(pts, color) — 그다음 _draw 안에서 b.flush(self)

const DIR := "res://assets/town/mat"
## 재질 그림 1px = 세계 몇 px인가(재질 그림 128px = 칸 4개).
const SCALE := 1.0

static var _cache: Dictionary = {}
static var _colors: Dictionary = {}  # city.town.colors(처음 한 번 읽는다)

var _runs: Array[Array] = []  # [tex, pts, cols, uvs, idx]


static func tex(id: String) -> Texture2D:
	if id.is_empty():
		return null
	if not _cache.has(id):
		var path := DIR.path_join(id + ".webp")
		_cache[id] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _cache[id]


## 볼록 다각형 하나(한 색). mat가 비면 그림 없이 색만. uv_off = 재질 무늬를 옮긴다(집마다 무늬가 같은 자리에 오지 않게).
func poly(pts: PackedVector2Array, c: Color, mat: String = "", uv_off: Vector2 = Vector2.ZERO) -> void:
	var cols := PackedColorArray()
	cols.resize(pts.size())
	cols.fill(c)
	poly_cols(pts, cols, mat, uv_off)


## 볼록 다각형 하나(꼭짓점마다 색 — 그늘·빛 기울기).
func poly_cols(pts: PackedVector2Array, cols: PackedColorArray, mat: String = "", uv_off: Vector2 = Vector2.ZERO) -> void:
	if pts.size() < 3:
		return
	var t := tex(mat)
	var uvs := PackedVector2Array()
	if t != null:
		var size := Vector2(t.get_width(), t.get_height()) * SCALE
		for p in pts:
			uvs.append((p + uv_off) / size)
	_add(pts, cols, uvs, t)


func _add(pts: PackedVector2Array, cols: PackedColorArray, uvs: PackedVector2Array, t: Texture2D) -> void:
	var run: Array = _runs.back() if not _runs.is_empty() else []
	if run.is_empty() or run[0] != t:
		run = [t, PackedVector2Array(), PackedColorArray(), PackedVector2Array(), PackedInt32Array()]
		_runs.append(run)
	var vp: PackedVector2Array = run[1]
	var vc: PackedColorArray = run[2]
	var vu: PackedVector2Array = run[3]
	var vi: PackedInt32Array = run[4]
	var base := vp.size()
	vp.append_array(pts)
	vc.append_array(cols)
	if t != null:
		vu.append_array(uvs)
	for k in range(1, pts.size() - 1):
		vi.append_array([base, base + k, base + k + 1])
	run[1] = vp  # 꾸러미 배열은 값으로 복사된다 — 다시 넣는다
	run[2] = vc
	run[3] = vu
	run[4] = vi


## 볼록 다각형 하나 — 재질 좌표를 직접(세계 px 단위 — 면 위 좌표, TownSolid).
func poly_uv(pts: PackedVector2Array, c: Color, uvs_px: PackedVector2Array, mat: String) -> void:
	var t := tex(mat)
	if t == null:
		poly(pts, c)
		return
	var size := Vector2(t.get_width(), t.get_height()) * SCALE
	var uvs := PackedVector2Array()
	for u in uvs_px:
		uvs.append(u / size)
	var cols := PackedColorArray()
	cols.resize(pts.size())
	cols.fill(c)
	_add(pts, cols, uvs, t)


func rect(r: Rect2, c: Color, mat: String = "", uv_off: Vector2 = Vector2.ZERO) -> void:
	poly(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), c, mat, uv_off)


## 위아래 두 색 기울기 직사각형(벽 아래 그늘 · 처마 그늘).
func rect_v(r: Rect2, top: Color, bottom: Color, mat: String = "", uv_off: Vector2 = Vector2.ZERO) -> void:
	poly_cols(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([top, top, bottom, bottom]), mat, uv_off)


## 타원(원형 건물·광장 단·우물). 꼭짓점 n개 부채꼴.
func ellipse(center: Vector2, radii: Vector2, c: Color, mat: String = "", n: int = 32) -> void:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / n
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	poly(pts, c, mat)


func flush(ci: CanvasItem) -> void:
	var rid := ci.get_canvas_item()
	for run in _runs:
		var t: Texture2D = run[0]
		RenderingServer.canvas_item_add_triangle_array(rid, run[4], run[1], run[2], run[3] if t != null else PackedVector2Array(),
			PackedInt32Array(), PackedFloat32Array(), t.get_rid() if t != null else RID())
	_runs.clear()


## 색을 밝기 k배(1 = 그대로).
static func shade(c: Color, k: float) -> Color:
	return Color(c.r * k, c.g * k, c.b * k, c.a)


## 선 하나(두께 w — 잉크 윤곽·처마선·마루).
func line(a: Vector2, b: Vector2, w: float, c: Color) -> void:
	var n := (b - a).orthogonal().normalized() * w * 0.5
	poly(PackedVector2Array([a - n, b - n, b + n, a + n]), c)


## render.json city.town 값.
static func cfg(render: Dictionary) -> Dictionary:
	return GameDatabase.single(render, "city.town", {}) as Dictionary


static func num(render: Dictionary, key: String, fallback: float) -> float:
	return JsonUtil.get_float(cfg(render), key, fallback)


## city.town.colors의 색(목록이면 i번째 — 집마다 고른다).
static func col(render: Dictionary, key: String, i: int = 0) -> Color:
	if _colors.is_empty():
		_colors = JsonUtil.get_dict(cfg(render), "colors")
	var v: Variant = _colors.get(key, "#808080")
	if v is Array:
		var a: Array = v
		v = a[posmod(i, a.size())] if not a.is_empty() else "#808080"
	return Color.html(str(v)) if Color.html_is_valid(str(v)) else Color(0.5, 0.5, 0.5)
