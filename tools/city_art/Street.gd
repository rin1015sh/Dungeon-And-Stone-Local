extends RefCounted
## 라비기온 거리 배경(옆에서 본 긴 그림): 흐린 하늘 · 먼 성벽과 지붕 · 나무 줄 · 뒤쪽 풀밭 · 진흙 길(바퀴 자국·웅덩이)
## + 건물 사이 소품(사과나무·울타리·우물·등불·수레). 건물 자체는 Buildings가 따로 그린다. tools/paint_city.gd 전용.

const Px := preload("res://tools/city_art/Px.gd")
const Props := preload("res://tools/city_art/Props.gd")

const HEIGHT := 240


## spans = [[x0, x1] …] 건물이 차지하는 가로 구간(밑그림 좌표), baseline = 건물이 서는 y.
static func paint(width: int, baseline: int, spans: Array, seed_value: int) -> Px:
	var p := Px.new(width, HEIGHT, seed_value)
	_sky(p, baseline)
	_far_city(p, baseline)
	_tree_line(p, baseline)
	_ground(p, baseline)
	_gap_props(p, baseline, spans)
	return p


static func _sky(p: Px, baseline: int) -> void:
	p.gradient_v(0, 0, p.w, baseline, Color("#66737a"), Color("#c3bfac"), 0.008)
	for i in p.w / 90:  # 옅은 가로 구름 띠
		var cx := p.rng.randi_range(-40, p.w)
		var cy := p.rng.randi_range(8, 70)
		var span := p.rng.randi_range(60, 160)
		for k in span:
			var t := float(k) / span
			var thick := int(3 * sin(t * PI)) + 1
			for yy in thick:
				p.px(cx + k, cy + yy - thick / 2, Color(0.86, 0.85, 0.79, 0.16))
			if p.rng.randf() < 0.3:
				p.px(cx + k, cy + thick, Color(0.4, 0.44, 0.48, 0.08))


## 먼 도시: 뾰족한 지붕 실루엣(안개로 흐린 푸른 회색) + 드문 탑 + 성벽(총안).
static func _far_city(p: Px, baseline: int) -> void:
	var wall_top := baseline - 46
	for layer in 2:
		var far := Color("#8b9396") if layer == 0 else Color("#727c81")
		var x := -10
		while x < p.w:
			var bw := p.rng.randi_range(12, 26)
			var top := wall_top - p.rng.randi_range(14, 38) + layer * 10
			var roof := p.rng.randi_range(8, 16)
			for xx in bw:
				var peak := top - roof + absi(xx - bw / 2) * roof * 2 / maxi(1, bw)
				for yy in range(peak, wall_top + 2):
					p.px(x + xx, yy, far.darkened(0.06 if xx > bw / 2 else 0.0))
			if layer == 1 and p.rng.randf() < 0.3:
				p.px(x + bw / 3, top + 5, Color("#d8b070"))
				p.px(x + bw / 3, top + 6, Color("#a07a40"))
			if layer == 0 and p.rng.randf() < 0.06:  # 탑(원뿔 지붕)
				var tx := x + bw / 2
				var th := p.rng.randi_range(26, 40)
				for yy in range(top - th, top):
					for xx in range(-4, 5):
						p.px(tx + xx, yy, far.darkened(0.1 if xx > 0 else 0.04))
				for yy in 12:
					for xx in range(-(yy * 5 / 12) - 1, (yy * 5 / 12) + 2):
						p.px(tx + xx, top - th - 12 + yy, far.darkened(0.2))
			x += bw - p.rng.randi_range(2, 7)
	var wall := Color("#646d71")
	p.noisy_rect(0, wall_top, p.w, 20, wall, 0.025)
	for xx in range(0, p.w, 8):
		p.rect(xx, wall_top - 4, 5, 4, wall)
	p.rect(0, wall_top, p.w, 1, wall.lightened(0.15))
	p.shade_grad(0, wall_top + 8, p.w, 12, 0.0, -0.15)


static func _tree_line(p: Px, baseline: int) -> void:
	for i in p.w / 6:
		p.blob(p.rng.randi_range(0, p.w), baseline - p.rng.randi_range(22, 34), p.rng.randi_range(7, 12), Color("#4a5a48"), PackedVector2Array(), 0.95)
	for i in p.w / 7:
		p.blob(p.rng.randi_range(0, p.w), baseline - p.rng.randi_range(12, 22), p.rng.randi_range(6, 10), Color("#3a4a35"), PackedVector2Array(), 0.95)


static func _ground(p: Px, baseline: int) -> void:
	p.noisy_rect(0, baseline - 14, p.w, 16, Color("#4d6a2c"), 0.08)  # 뒤쪽 풀밭
	Props.grass_tufts(p, 0, baseline - 12, p.w, p.w / 3)
	var road := Color("#6b5a44")
	for yy in range(baseline, HEIGHT):
		var t := float(yy - baseline) / float(HEIGHT - baseline)
		for xx in p.w:
			var c := road.darkened(0.12 - t * 0.12)
			if p.rng.randf() < 0.08:
				c = c.darkened(0.12)
			p.px(xx, yy, p.jit(c, 0.05))
	for k in 4:  # 바퀴 자국
		var ty := baseline + 12 + k * 7 + p.rng.randi_range(-1, 1)
		var y := float(ty)
		for xx in p.w:
			y += p.rng.randf_range(-0.25, 0.25)
			y = clampf(y, ty - 2, ty + 2)
			p.px(xx, int(y), road.darkened(0.3))
			if p.rng.randf() < 0.5:
				p.px(xx, int(y) + 1, road.lightened(0.06))
	for i in p.w / 30:  # 진흙 얼룩
		p.blob(p.rng.randi_range(0, p.w), p.rng.randi_range(baseline + 6, HEIGHT - 4), p.rng.randi_range(4, 9), road.darkened(0.18), PackedVector2Array(), 0.5)
	for i in p.w / 110:  # 웅덩이(납작하게)
		var cx := p.rng.randi_range(0, p.w)
		var cy := p.rng.randi_range(baseline + 14, HEIGHT - 8)
		var rw := p.rng.randi_range(5, 11)
		for xx in range(-rw, rw + 1):
			var hh := 2 if absi(xx) < rw - 2 else 1
			for yy in hh:
				p.px(cx + xx, cy + yy, Color("#5c6a70") if yy > 0 else Color("#8a989c"))
	for i in p.w / 8:  # 돌멩이·나무 조각
		var sx := p.rng.randi_range(0, p.w)
		var sy := p.rng.randi_range(baseline + 2, HEIGHT - 2)
		if p.rng.randf() < 0.6:
			p.px(sx, sy, Color("#8a8074"))
			p.px(sx + 1, sy, Color("#4d463d"))
		else:
			p.line(Vector2i(sx, sy), Vector2i(sx + p.rng.randi_range(3, 6), sy + p.rng.randi_range(-1, 1)), Color("#5a4630"))
	p.shade_grad(0, baseline, p.w, 6, -0.25, 0.0)


## 건물 사이 빈 곳에 소품. 순서대로 나무·우물·수레·등불을 돌려 쓴다.
static func _gap_props(p: Px, baseline: int, spans: Array) -> void:
	var gaps: Array = []
	var prev := 0
	for s: Array in spans:
		gaps.append([prev, int(s[0])])
		prev = int(s[1])
	gaps.append([prev, p.w])
	for i in gaps.size():
		var a: int = gaps[i][0]
		var b: int = gaps[i][1]
		var mid := (a + b) / 2
		var room := b - a
		if room < 16:
			continue
		match i % 4:
			0:
				Props.tree(p, mid, baseline + 2, clampf(room / 30.0, 1.3, 1.9))
				Props.bush(p, mid + 14, baseline + 3, 12)
			1:
				Props.tree(p, mid, baseline, 1.5)
				Props.fence(p, a + 4, b - 6, baseline + 2)
			2:
				Props.well(p, mid, baseline + 6)
				Props.lamp_post(p, a + 6, baseline + 3)
			3:
				Props.tree(p, mid - 6, baseline + 1, 1.4)
				Props.cart(p, mid + 4, baseline + 10)
		Props.grass_tufts(p, a, baseline + 1, room, room / 4)
