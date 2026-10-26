class_name FoeRows
extends RefCounted
## 적 자리(원근 줄 — 전투 뒷그림의 통로 안에 앞뒤로 선다, UI29): 적 폭을 미터로 받아 앞줄부터 채우고,
## 벽(가운데에서 ±half_width m) 안에 못 들면 다음 줄(더 깊은 곳)로 보낸다. 벽이 소실점으로 모이므로 미터로 재면 모든 줄의 폭 한도가 같다.
## 줄 r의 깊이 배율 = 1 / (1 + r × step) — 화면에서 키·가운데에서 떨어진 거리·바닥까지 높이가 모두 이 배율로 줄어든다(BattleStage).
## 뒷줄은 반 칸 어긋나 앞줄 사이 틈에 선다. 줄이 max_rows를 넘으면 모두 같은 비율로 줄인다(arrange_fit).


static func scale_of(row: int, step: float) -> float:
	return 1.0 / (1.0 + row * step)


## widths(m, 나온 순서) → {"pos": Array[Vector2](x m, 줄), "rows": 줄 수}. 한 줄에 하나는 늘 들어간다(벽보다 넓은 보스).
static func arrange(widths: PackedFloat32Array, half_width: float, gap: float) -> Dictionary:
	var rows: Array[PackedInt32Array] = [PackedInt32Array()]
	var used: Array[float] = [0.0]
	for i in widths.size():
		var w := widths[i] + gap
		if not rows[-1].is_empty() and used[-1] + w > half_width * 2.0 + gap * 0.5:
			rows.append(PackedInt32Array())
			used.append(0.0)
		rows[-1].append(i)
		used[-1] += w
	var pos: Array[Vector2] = []
	pos.resize(widths.size())
	var prev := PackedFloat32Array()  # 앞줄 가운데들(m)
	for r in rows.size():
		var gaps := _gaps(prev, rows[r], widths, half_width)
		if gaps.size() == rows[r].size():  # 앞줄 사이 틈에 — 가려지지 않게
			for j in rows[r].size():
				pos[rows[r][j]] = Vector2(gaps[j], r)
		else:
			var total := used[r] - gap
			var x := -total / 2.0
			var shift := 0.0
			if r % 2 == 1:  # 반 칸 어긋나기 — 벽 안에서만
				shift = clampf(used[r] / rows[r].size() / 2.0, 0.0, maxf(0.0, half_width - total / 2.0))
			for i in rows[r]:
				pos[i] = Vector2(x + widths[i] / 2.0 + shift, r)
				x += widths[i] + gap
		prev = PackedFloat32Array()
		for i in rows[r]:
			prev.append(pos[i].x)
	return {"pos": pos, "rows": rows.size()}


## 앞줄(prev) 사이 틈과 양 끝 바깥 자리 중 가운데에 가까운 것부터 이 줄 수만큼(왼쪽부터 차례로). 벽 밖이면 못 쓴다 — 모자라면 빈 배열.
static func _gaps(prev: PackedFloat32Array, row: PackedInt32Array, widths: PackedFloat32Array, half_width: float) -> PackedFloat32Array:
	if prev.size() < 1 or row.is_empty():
		return PackedFloat32Array()
	var xs := prev.duplicate()
	xs.sort()
	var spacing := (xs[-1] - xs[0]) / maxf(1.0, xs.size() - 1) if xs.size() > 1 else widths[row[0]] * 1.2
	var cands: Array[float] = [xs[0] - spacing / 2.0, xs[-1] + spacing / 2.0]
	for i in xs.size() - 1:
		cands.append((xs[i] + xs[i + 1]) / 2.0)
	var wmax := 0.0
	for i in row:
		wmax = maxf(wmax, widths[i])
	cands = cands.filter(func(c: float) -> bool: return absf(c) + wmax / 2.0 <= half_width + 0.01)
	if cands.size() < row.size():
		return PackedFloat32Array()
	cands.sort_custom(func(a: float, b: float) -> bool: return absf(a) < absf(b))
	var out := PackedFloat32Array(cands.slice(0, row.size()))
	out.sort()
	return out


## 줄이 max_rows를 넘지 않을 때까지 모두 줄인다 → {"pos", "rows", "k"(줄인 배율)}.
static func arrange_fit(widths: PackedFloat32Array, half_width: float, gap: float, max_rows: int) -> Dictionary:
	var k := 1.0
	var out := arrange(widths, half_width, gap)
	while int(out["rows"]) > max_rows and k > 0.3:
		k *= 0.92
		var ws := PackedFloat32Array()
		for w in widths:
			ws.append(w * k)
		out = arrange(ws, half_width, gap * k)
	out["k"] = k
	return out


## 나중에 나온 적(소환·증원·분열)의 빈자리: 앞줄부터, 가운데에 가까운 곳 — 뒷줄은 앞줄 사이 틈을 먼저(가려지지 않게).
## taken = [Vector3(x m, 줄, 폭 m)]. 못 찾으면 Vector2(INF, -1)(다시 정렬).
static func fit_new(taken: Array[Vector3], w: float, half_width: float, gap: float, max_rows: int) -> Vector2:
	for r in max_rows:
		var spans: Array[Vector2] = []
		var front := PackedFloat32Array()
		for t in taken:
			if int(t.y) == r:
				spans.append(Vector2(t.x - t.z / 2.0 - gap, t.x + t.z / 2.0 + gap))
			elif int(t.y) == r - 1:
				front.append(t.x)
		var gaps := _gaps(front, PackedInt32Array([0]), PackedFloat32Array([w]), half_width) if not front.is_empty() else PackedFloat32Array()
		var preferred: Array[float] = []
		if not front.is_empty():  # 앞줄의 틈 전부(가운데에 가까운 것부터)
			var xs := front.duplicate()
			xs.sort()
			for i in xs.size() - 1:
				preferred.append((xs[i] + xs[i + 1]) / 2.0)
			var sp := (xs[-1] - xs[0]) / maxf(1.0, xs.size() - 1) if xs.size() > 1 else w * 1.2
			preferred.append(xs[0] - sp / 2.0)
			preferred.append(xs[-1] + sp / 2.0)
		preferred.append_array(Array(gaps))
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
				if absf(c) < absf(best):
					best = c
			if best != INF:
				return Vector2(best, r)
	return Vector2(INF, -1)
