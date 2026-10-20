class_name VertexDiff
extends RefCounted
## 시야를 다시 계산하기 전후의 꼭짓점 값(빛·안개·앎)을 비교해, 실제로 바뀐 꼭짓점을 덮는 칸 사각형만 돌려준다(FloorView.refresh).
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


## 기억한 뒤로 값이 바뀐 꼭짓점을 덮는 칸 사각형(바뀐 게 없으면 빈 사각형).
func changed_cells(light: PackedColorArray, fog: PackedByteArray, known: PackedByteArray) -> Rect2i:
	var lo := Vector2i(1 << 30, 1 << 30)
	var hi := Vector2i(-1, -1)
	for k in _light.size():
		var vy := _rect.position.y + k
		var a := vy * _w + _rect.position.x
		var b := a + _rect.size.x
		var l := light.slice(a, b)
		var f := fog.slice(a, b)
		var n := known.slice(a, b)
		if l == _light[k] and f == _fog[k] and n == _known[k]:
			continue
		for i in _rect.size.x:
			if l[i] != _light[k][i] or f[i] != _fog[k][i] or n[i] != _known[k][i]:
				var vx := _rect.position.x + i
				lo = Vector2i(mini(lo.x, vx), mini(lo.y, vy))
				hi = Vector2i(maxi(hi.x, vx), maxi(hi.y, vy))
	if hi.x < 0:
		return Rect2i()
	# 꼭짓점 (vx, vy)는 칸 (vx-1..vx, vy-1..vy)의 모서리다.
	return Rect2i(lo - Vector2i.ONE, hi - lo + Vector2i(2, 2))
