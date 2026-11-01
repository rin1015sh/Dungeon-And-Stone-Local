class_name VertexDiff
extends RefCounted
## 시야를 다시 계산하기 전후의 꼭짓점 값(빛·안개·앎)을 비교해, 실제로 바뀐 꼭짓점을 덮는 칸 사각형들만 돌려준다(FloorView.refresh).
## 밝은 곳(균열 — 시야 = 지도 전체)에서는 한 칸 걸어도 바뀌는 꼭짓점이 적은데 시야 사각형 전체를 다시 그리면
## 걸음마다 청크 수십 개를 그려 0.1~0.5초씩 멈췄다. 줄마다 통째로 같으면 건너뛴다(대부분의 줄).

var _rect: Rect2i     ## 비교할 꼭짓점 사각형(끝 포함 — 칸 사각형보다 한 줄·한 칸 크다)
var _w: int = 0       ## 꼭짓점 격자 너비(map.width + 1)
var _light: Array[PackedColorArray] = []
var _fog: Array[PackedByteArray] = []
var _known: Array[PackedByteArray] = []


## 칸 사각형 cells를 둘러싼 꼭짓점 값을 기억한다.
func take(cells: Rect2i, w: int, h: int, light: PackedColorArray, fog: PackedByteArray, known: PackedByteArray) -> void:
	_w = w
	_rect = Rect2i(cells.position, cells.size + Vector2i.ONE).intersection(Rect2i(0, 0, w, h))
	_light.clear()
	_fog.clear()
	_known.clear()
	for vy in range(_rect.position.y, _rect.end.y):
		var a := vy * w + _rect.position.x
		var b := a + _rect.size.x
		_light.append(light.slice(a, b))
		_fog.append(fog.slice(a, b))
		_known.append(known.slice(a, b))


## 기억한 뒤로 값이 바뀐 꼭짓점을 덮는 칸 사각형들 — 줄마다 바뀐 구간(gap칸보다 멀리 떨어진 구간은 따로).
## 하나로 묶으면 화면 양쪽 끝의 그림자만 바뀌어도 그 사이 청크까지 모두 다시 그려 걸음마다 끊겼다.
func changed_rects(light: PackedColorArray, fog: PackedByteArray, known: PackedByteArray, gap: int) -> Array[Rect2i]:
	var out: Array[Rect2i] = []
	for k in _light.size():
		var vy := _rect.position.y + k
		var a := vy * _w + _rect.position.x
		var b := a + _rect.size.x
		var l := light.slice(a, b)
		var f := fog.slice(a, b)
		var n := known.slice(a, b)
		if l == _light[k] and f == _fog[k] and n == _known[k]:
			continue
		var pl := _light[k]
		var pf := _fog[k]
		var pn := _known[k]
		var lo := -1
		var hi := -1
		for i in _rect.size.x:
			if l[i] != pl[i] or f[i] != pf[i] or n[i] != pn[i]:
				if lo >= 0 and i - hi > gap:
					out.append(_span(lo, hi, vy))
					lo = -1
				if lo < 0:
					lo = i
				hi = i
		if lo >= 0:
			out.append(_span(lo, hi, vy))
	return out


## 꼭짓점 줄 vy의 구간 [lo, hi](_rect 안 번호)을 덮는 칸 — 꼭짓점 (vx, vy)는 칸 (vx-1..vx, vy-1..vy)의 모서리다.
func _span(lo: int, hi: int, vy: int) -> Rect2i:
	return Rect2i(_rect.position.x + lo - 1, vy - 1, hi - lo + 2, 2)
