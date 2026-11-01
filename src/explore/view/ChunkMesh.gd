class_name ChunkMesh
extends RefCounted
## 청크 그림의 바뀌지 않는 부분(칸 모양·UV·삼각형)을 그림마다 모아 두고, 다시 그릴 때는 꼭짓점 색만 새로 채운다(FloorChunk).
## 밝은 균열은 걸을 때마다 시야 그림자가 바뀌어 화면 청크 여러 개를 다시 그리는데, 칸마다 그림 변형·UV·삼각형을
## 다시 만들면 청크 하나에 1~2ms라 한 걸음마다 끊겼다. 모양은 그리는 칸(탐험·타일)이 바뀔 때만 다시 만든다.
##   m.clear() → m.add_tex(pts, uvs, tex, vx, vy, mean) / m.add_plain(pts, vx, vy, base) … (모양)
##   그릴 때마다: m.draw(ci, view) — 색을 채워 ci(의 _draw 안)에 그림마다 한 번씩
## 같은 그림 안에서는 넣은 순서대로, 그림끼리는 처음 넣은 그림 순서(QuadBatch와 같다).


class Bucket:
	var tex: Texture2D
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var cols := PackedColorArray()
	var ref := PackedInt32Array()    # 그림 칸: 꼭짓점마다 색 표(_table) 번호
	var vx := PackedInt32Array()     # 색칠 칸: 꼭짓점 좌표와 바탕색(FloorView.vertex_color)
	var vy := PackedInt32Array()
	var base := PackedColorArray()


var _buckets: Array[Bucket] = []
var _by_tex: Dictionary = {}       # 그림 instance id(그림 없음 = 0) -> Bucket
var _ref_of: Dictionary = {}       # Vector3i(꼭짓점 x, y, 바탕 번호) -> 색 표 번호
var _need_vx := PackedInt32Array() # 색 표 번호마다 꼭짓점·바탕(그림 평균 색 — FloorView.vertex_mul)
var _need_vy := PackedInt32Array()
var _need_mean := PackedColorArray()
var _table := PackedColorArray()


func clear() -> void:
	_buckets.clear()
	_by_tex.clear()
	_ref_of.clear()
	_need_vx.resize(0)
	_need_vy.resize(0)
	_need_mean.resize(0)


func is_empty() -> bool:
	return _buckets.is_empty()


## 그림 칸 하나(꼭짓점 넷 — 왼위·오위·오아래·왼아래, 칸 (x, y)). 색 = 꼭짓점 빛 배율(mean = 그림 평균 색, key = 그 바탕의 번호).
func add_tex(pts: PackedVector2Array, uvs: PackedVector2Array, tex: Texture2D, x: int, y: int, mean: Color, key: int) -> void:
	var b := _bucket(tex)
	_quad(b, pts)
	b.uvs.append_array(uvs)
	for k in 4:
		var c := Vector3i(x + (1 if k == 1 or k == 2 else 0), y + (1 if k >= 2 else 0), key)
		var r: int = _ref_of.get(c, -1)
		if r < 0:
			r = _need_vx.size()
			_ref_of[c] = r
			_need_vx.append(c.x)
			_need_vy.append(c.y)
			_need_mean.append(mean)
		b.ref.append(r)


## 색칠 칸 하나(그림 없음): 색 = FloorView.vertex_color(꼭짓점, base).
func add_plain(pts: PackedVector2Array, x: int, y: int, base: Color) -> void:
	var b := _bucket(null)
	_quad(b, pts)
	for k in 4:
		b.vx.append(x + (1 if k == 1 or k == 2 else 0))
		b.vy.append(y + (1 if k >= 2 else 0))
		b.base.append(base)


## 지금 빛·안개로 색을 채워 ci에 그린다(ci의 _draw 안에서).
func draw(ci: CanvasItem, view: FloorView) -> void:
	_table.resize(_need_vx.size())
	for j in _need_vx.size():
		_table[j] = view.vertex_mul(_need_vx[j], _need_vy[j], _need_mean[j])
	var rid := ci.get_canvas_item()
	for b in _buckets:
		if b.tex != null:
			for j in b.ref.size():
				b.cols[j] = _table[b.ref[j]]
		else:
			for j in b.vx.size():
				b.cols[j] = view.vertex_color(b.vx[j], b.vy[j], b.base[j])
		RenderingServer.canvas_item_add_triangle_array(rid, b.idx, b.pts, b.cols, b.uvs, PackedInt32Array(), PackedFloat32Array(),
			b.tex.get_rid() if b.tex != null else RID())


func _bucket(tex: Texture2D) -> Bucket:
	var key: int = tex.get_instance_id() if tex != null else 0
	var b: Bucket = _by_tex.get(key)
	if b == null:
		b = Bucket.new()
		b.tex = tex
		_by_tex[key] = b
		_buckets.append(b)
	return b


func _quad(b: Bucket, pts: PackedVector2Array) -> void:
	var base := b.pts.size()
	b.pts.append_array(pts)
	b.cols.resize(b.pts.size())
	b.idx.append_array([base, base + 1, base + 2, base, base + 2, base + 3])  # 부채꼴 삼각형 둘(QuadBatch와 같은 순서)
