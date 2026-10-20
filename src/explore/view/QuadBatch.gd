class_name QuadBatch
extends RefCounted
## 칸 다각형들을 그림(텍스처)마다 삼각형 배열 하나로 모아 한 번에 그린다.
## draw_polygon은 부를 때마다 다각형을 삼각분할하고 그리기 명령을 하나씩 만들어, 칸이 수백 개인 청크를 다시 그리면 수십 ms가 걸렸다.
## 같은 그림 안에서는 넣은 순서대로 그려진다(겹치는 것도 순서 유지). 그림이 다른 묶음끼리는 처음 넣은 그림 순서 —
## 그림이 다른 것끼리 겹치는 순서가 중요하면 쓰지 않는다.
##   b.add(pts, cols, uvs, tex) · b.add(pts, cols) — 그다음 _draw 안에서 b.flush(self)


class Bucket:
	var tex: Texture2D
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()

	func add(p: PackedVector2Array, c: PackedColorArray, u: PackedVector2Array) -> void:
		var base := pts.size()
		pts.append_array(p)
		cols.append_array(c)
		if tex != null:
			uvs.append_array(u)
		for k in range(1, p.size() - 1):  # 볼록 다각형 → 부채꼴 삼각형
			idx.append(base)
			idx.append(base + k)
			idx.append(base + k + 1)


var _buckets: Array[Bucket] = []
var _by_tex: Dictionary = {}  # 그림 instance id(그림 없음 = 0) -> Bucket


## 볼록 다각형 하나(꼭짓점 3개 이상, cols는 꼭짓점마다). uvs는 그림이 있을 때만 쓴다.
func add(pts: PackedVector2Array, cols: PackedColorArray, uvs: PackedVector2Array = PackedVector2Array(), tex: Texture2D = null) -> void:
	var key: int = tex.get_instance_id() if tex != null else 0
	var b: Bucket = _by_tex.get(key)
	if b == null:
		b = Bucket.new()
		b.tex = tex
		_by_tex[key] = b
		_buckets.append(b)
	b.add(pts, cols, uvs)


## 모은 것을 ci에 그리고 비운다(ci의 _draw 안에서 부른다).
func flush(ci: CanvasItem) -> void:
	var rid := ci.get_canvas_item()
	for b in _buckets:
		RenderingServer.canvas_item_add_triangle_array(rid, b.idx, b.pts, b.cols, b.uvs, PackedInt32Array(), PackedFloat32Array(),
			b.tex.get_rid() if b.tex != null else RID())
	_buckets.clear()
	_by_tex.clear()
