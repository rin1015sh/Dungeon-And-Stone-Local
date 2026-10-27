class_name FoeRows
extends RefCounted
## 적 자리(원근 줄 — 전투 뒷그림의 통로 안에 앞뒤로 선다, UI29): 적 폭을 미터로 받아 앞줄부터 채우고,
## 벽(가운데에서 ±half_width m) 안에 못 들면 다음 줄(더 깊은 곳)로 보낸다. 벽이 소실점으로 모이므로 미터로 재면 모든 줄의 폭 한도가 같다.
## 줄 r의 깊이 배율 = 1 / (1 + r × step) — 화면에서 키·가운데에서 떨어진 거리·바닥까지 높이가 모두 이 배율로 줄어든다(BattleStage).
## 뒷줄은 앞줄 사이 틈에 선다. 계층군주·수호자(pinned)는 늘 앞줄 한가운데. 줄이 max_rows를 넘으면 모두 같은 비율로 줄인다(arrange_fit).


static func scale_of(row: int, step: float) -> float:
	return 1.0 / (1.0 + row * step)


## widths(m, 나온 순서) → {"pos": Array[Vector2](x m, 줄), "rows": 줄 수}. 한 줄에 하나는 늘 들어간다(벽보다 넓은 보스).
## pinned = 늘 앞줄 한가운데(x 0)에 설 적(계층군주·수호자 — 없으면 -1): 나머지는 그 양옆에 번갈아, 못 들면 뒷줄로.
static func arrange(widths: PackedFloat32Array, half_width: float, gap: float, pinned: int = -1) -> Dictionary:
	var pos: Array[Vector2] = []
	pos.resize(widths.size())
	var order := PackedInt32Array()
	for i in widths.size():
		if i != pinned:
			order.append(i)
	var prev: Array[Vector2] = []  # 앞줄 (가운데 x, 폭)
	var first_row := 0
	if pinned >= 0 and pinned < widths.size():
		pos[pinned] = Vector2(0.0, 0)
		prev.append(Vector2(0.0, widths[pinned]))
		var left := -widths[pinned] / 2.0
		var right := widths[pinned] / 2.0
		var rest := PackedInt32Array()
		for i in order:
			var w := widths[i]
			var fit_r := right + gap + w <= half_width + 0.01
			var fit_l := -left + gap + w <= half_width + 0.01
			if fit_r and (right <= -left or not fit_l):
				pos[i] = Vector2(right + gap + w / 2.0, 0)
				right += gap + w
			elif fit_l:
				pos[i] = Vector2(left - gap - w / 2.0, 0)
				left -= gap + w
			else:
				rest.append(i)
				continue
			prev.append(Vector2(pos[i].x, w))
		order = rest
		first_row = 1
	var rows: Array[PackedInt32Array] = []
	var used: Array[float] = []
	for i in order:
		var w := widths[i] + gap
		if rows.is_empty() or (not rows[-1].is_empty() and used[-1] + w > half_width * 2.0 + gap * 0.5):
			rows.append(PackedInt32Array())
			used.append(0.0)
		rows[-1].append(i)
		used[-1] += w
	for k in rows.size():
		var r := first_row + k
		var gaps := _gaps(prev, rows[k], widths, half_width, gap)
		if gaps.size() == rows[k].size():  # 앞줄 사이 틈에 — 가려지지 않게
			for j in rows[k].size():
				pos[rows[k][j]] = Vector2(gaps[j], r)
		else:
			var total := used[k] - gap
			var x := -total / 2.0
			var shift := 0.0
			if r % 2 == 1:  # 반 칸 어긋나기 — 벽 안에서만
				shift = clampf(used[k] / rows[k].size() / 2.0, 0.0, maxf(0.0, half_width - total / 2.0))
			for i in rows[k]:
				pos[i] = Vector2(x + widths[i] / 2.0 + shift, r)
				x += widths[i] + gap
		prev = []
		for i in rows[k]:
			prev.append(Vector2(pos[i].x, widths[i]))
	return {"pos": pos, "rows": first_row + rows.size()}


## 앞줄(prev = (x, 폭)) 사이 틈과 양 끝 바깥 자리 중 가운데에 가까운 것부터 이 줄 수만큼(왼쪽부터 차례로). 벽 밖이면 못 쓴다 — 모자라면 빈 배열.
static func _gaps(prev: Array[Vector2], row: PackedInt32Array, widths: PackedFloat32Array, half_width: float, gap: float) -> PackedFloat32Array:
	if prev.is_empty() or row.is_empty():
		return PackedFloat32Array()
	var wmax := 0.0
	for i in row:
		wmax = maxf(wmax, widths[i])
	var cands := _gap_points(prev, wmax, gap)
	cands = cands.filter(func(c: float) -> bool: return absf(c) + wmax / 2.0 <= half_width + 0.01)
	if cands.size() < row.size():
		return PackedFloat32Array()
	cands.sort_custom(func(a: float, b: float) -> bool: return absf(a) < absf(b))
	var out := PackedFloat32Array(cands.slice(0, row.size()))
	out.sort()
	return out


## 앞줄 몸과 몸 사이 틈의 가운데들(가장자리 기준 — 넓은 보스 옆에서도 몸 뒤가 아닌 틈에) + 양 끝 바깥(맨 끝 몸 바로 옆).
static func _gap_points(prev: Array[Vector2], w: float, gap: float) -> Array[float]:
	var xs := prev.duplicate()
	xs.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var out: Array[float] = [xs[0].x - xs[0].y / 2.0 - gap - w / 2.0, xs[-1].x + xs[-1].y / 2.0 + gap + w / 2.0]
	for i in xs.size() - 1:
		out.append((xs[i].x + xs[i].y / 2.0 + xs[i + 1].x - xs[i + 1].y / 2.0) / 2.0)
	return out


## 줄이 max_rows를 넘지 않을 때까지 모두 줄인다 → {"pos", "rows", "k"(줄인 배율)}.
static func arrange_fit(widths: PackedFloat32Array, half_width: float, gap: float, max_rows: int, pinned: int = -1) -> Dictionary:
	var k := 1.0
	var out := arrange(widths, half_width, gap, pinned)
	while int(out["rows"]) > max_rows and k > 0.3:
		k *= 0.92
		var ws := PackedFloat32Array()
		for w in widths:
			ws.append(w * k)
		out = arrange(ws, half_width, gap * k, pinned)
	out["k"] = k
	return out


## 나중에 나온 적(소환·증원·분열)의 빈자리: 앞줄부터, 가운데에 가까운 곳 — 뒷줄은 앞줄 사이 틈을 먼저(가려지지 않게).
## taken = [Vector3(x m, 줄, 폭 m)]. 못 찾으면 Vector2(INF, -1)(다시 정렬).
## hide: 뒷줄 자리가 앞줄 몸과 이 비율 넘게 겹치면 쓰지 않는다(1 = 조금도 겹치지 않게).
static func fit_new(taken: Array[Vector3], w: float, half_width: float, gap: float, max_rows: int, hide: float = 0.45) -> Vector2:
	for r in max_rows:
		var spans: Array[Vector2] = []
		var front: Array[Vector2] = []
		for t in taken:
			if int(t.y) == r:
				spans.append(Vector2(t.x - t.z / 2.0 - gap, t.x + t.z / 2.0 + gap))
			elif int(t.y) == r - 1:
				front.append(Vector2(t.x, t.z))
		var preferred: Array[float] = []
		if not front.is_empty():  # 앞줄 틈 먼저
			preferred = _gap_points(front, w, gap)
		var others: Array[float] = [0.0]
		for s in spans:
			others.append(s.x - w / 2.0)
			others.append(s.y + w / 2.0)
		for cands: Array[float] in [preferred, others]:
			var best := INF
			for c in cands:
				if c - w / 2.0 < -half_width - 0.01 or c + w / 2.0 > half_width + 0.01:
					if not (spans.is_empty() and front.is_empty() and c == 0.0):  # 빈 앞줄 가운데는 벽보다 넓어도 된다
						continue
				if spans.any(func(s: Vector2) -> bool: return c + w / 2.0 > s.x + 0.01 and c - w / 2.0 < s.y - 0.01):
					continue
				if front.any(func(f: Vector2) -> bool: return absf(c - f.x) < (f.y + w) * 0.5 * hide):
					continue  # 앞줄 몸 바로 뒤 — 가려진다(드레드피어 뒤에 구더기가 숨던 것)
				if absf(c) < absf(best):
					best = c
			if best != INF:
				return Vector2(best, r)
	return Vector2(INF, -1)
