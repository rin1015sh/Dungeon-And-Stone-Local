extends SceneTree
## 도시 동네 지도 재질 그림(CT82 — M0): 128×128 이음매 없는 재질 → assets/town/mat/<id>.webp.
##   godot --headless --path . --script res://tools/paint_town.gd [-- --only=<id,id>]
## 색은 거의 무채색(밝기 평균 약 0.8) — 게임이 꼭짓점 색(render.json city.town.colors)을 곱해 벽색·지붕색을 낸다(TownBrush).
## 무늬는 모두 128px 주기로 감싸 이어 붙여도 이음매가 없다(자갈 = 감싼 보로노이, 판석·마름돌·기와 = 줄마다 엇갈린 칸, 잡음 = 감싼 값 잡음).

const S := 128
const OUT := "res://assets/town/mat"
const IDS := ["cobble", "slabs", "plaza", "dirt", "water", "ashlar", "rubble", "plaster", "clay", "slate", "wood", "stairs", "lead"]


func _init() -> void:
	var only := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for id: String in IDS:
		if not only.is_empty() and not only.has(id):
			continue
		var img := Image.create(S, S, false, Image.FORMAT_RGB8)
		call("_" + id, img)
		img.save_webp(ProjectSettings.globalize_path(OUT.path_join(id + ".webp")), true, 0.9)
		print("그림: 재질 ", id)
	quit(0)


## 감싼 값 잡음(주기 S) — 0~1.
func _noise(x: float, y: float, cell: int, s: int) -> float:
	var n := S / cell
	var gx := x / float(cell)
	var gy := y / float(cell)
	var x0 := int(floor(gx))
	var y0 := int(floor(gy))
	var fx := gx - x0
	var fy := gy - y0
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	var a := _h(posmod(x0, n), posmod(y0, n), s)
	var b := _h(posmod(x0 + 1, n), posmod(y0, n), s)
	var c := _h(posmod(x0, n), posmod(y0 + 1, n), s)
	var d := _h(posmod(x0 + 1, n), posmod(y0 + 1, n), s)
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fy)


func _fbm(x: float, y: float, s: int) -> float:
	return _noise(x, y, 32, s) * 0.5 + _noise(x, y, 16, s + 1) * 0.3 + _noise(x, y, 8, s + 2) * 0.2


static func _h(a: int, b: int, s: int) -> float:
	var v := (a * 73856093) ^ (b * 19349663) ^ (s * 83492791)
	v = (v ^ (v >> 13)) * 1274126177
	return float(absi(v ^ (v >> 16)) % 10007) / 10007.0


func _put(img: Image, x: int, y: int, v: float, tint: Color = Color(1, 1, 1)) -> void:
	img.set_pixel(posmod(x, S), posmod(y, S), Color(clampf(v * tint.r, 0, 1), clampf(v * tint.g, 0, 1), clampf(v * tint.b, 0, 1)))


## 자갈: 감싼 보로노이 — 돌마다 둥근 볼록(왼쪽 위가 밝다), 틈은 어둡다.
func _cobble(img: Image, cells: int = 16, seed_v: int = 11, gap: float = 1.1) -> void:
	var pts: Array[Vector2] = []
	var tones: Array[float] = []
	var step := float(S) / cells
	for j in cells:
		for i in cells:
			pts.append(Vector2((i + 0.15 + _h(i, j, seed_v) * 0.7) * step, (j + 0.15 + _h(i, j, seed_v + 5) * 0.7) * step))
			tones.append(0.74 + _h(i, j, seed_v + 9) * 0.16)
	for y in S:
		for x in S:
			var p := Vector2(x, y)
			var d1 := 1e9
			var d2 := 1e9
			var best := 0
			var bv := Vector2.ZERO
			for k in pts.size():
				var dv := pts[k] - p
				dv.x -= roundf(dv.x / S) * S
				dv.y -= roundf(dv.y / S) * S
				var d := dv.length()
				if d < d1:
					d2 = d1
					d1 = d
					best = k
					bv = dv
				elif d < d2:
					d2 = d
			var edge := (d2 - d1) * 0.5
			var shade := 1.0 + clampf((bv.x + bv.y) / (step * 1.4), -0.5, 0.5) * 0.35  # 가운데보다 아래오른쪽이 어둡다
			var v := tones[best] * shade * (0.92 + _fbm(x, y, seed_v) * 0.16)
			if edge < gap:
				v = 0.42 + edge * 0.1
			_put(img, x, y, v)


## 판석(대로·앞뜰): 줄마다 엇갈린 큰 직사각형.
func _slabs(img: Image, bw: int = 32, bh: int = 32, seed_v: int = 21) -> void:
	for y in S:
		for x in S:
			var row := y / bh
			var off := (bw / 2) * (row % 2)
			var col := int(floor(float(x + off) / bw))
			var lx := posmod(x + off, bw)
			var ly := posmod(y, bh)
			var v := 0.74 + _h(posmod(col, S / bw), posmod(row, maxi(1, S / bh)), seed_v) * 0.18
			v *= 0.9 + _fbm(x, y, seed_v) * 0.2
			if lx == 0 or ly == 0:
				v = 0.34
			elif lx == 1 or ly == 1:
				v *= 1.12
			elif lx == bw - 1 or ly == bh - 1:
				v *= 0.8
			_put(img, x, y, v)


func _plaza(img: Image) -> void:
	_slabs(img, 64, 32, 31)


func _dirt(img: Image) -> void:
	for y in S:
		for x in S:
			var v := 0.62 + _fbm(x, y, 41) * 0.3
			if _h(x, y, 43) > 0.985:
				v *= 1.25  # 잔돌
			_put(img, x, y, v)


func _water(img: Image) -> void:
	for y in S:
		for x in S:
			var w := _noise(x * 2.0, y, 32, 51) * 0.6 + _noise(x, y * 2.0, 16, 52) * 0.4
			var v := 0.55 + w * 0.3
			if absf(w - 0.55) < 0.02:
				v += 0.1  # 잔물결 빛
			_put(img, x, y, v)


## 마름돌(시설 벽·옹벽·성벽).
func _ashlar(img: Image) -> void:
	_slabs(img, 32, 16, 61)


func _rubble(img: Image) -> void:
	_cobble(img, 7, 71, 1.4)


## 회벽: 부드러운 얼룩 + 아래로 흐른 때.
func _plaster(img: Image) -> void:
	for y in S:
		for x in S:
			var v := 0.84 + (_fbm(x, y, 81) - 0.5) * 0.14 - _noise(x, y, 64, 82) * 0.06
			_put(img, x, y, v)


## 흙기와: 줄(8px)마다 반원 비늘, 줄 아래가 그늘.
func _clay(img: Image) -> void:
	var th := 16
	var tw := 16
	for y in S:
		for x in S:
			var row := y / th
			var off := (tw / 2) * (row % 2)
			var lx := posmod(x + off, tw)
			var ly := y % th
			var u := (lx - tw * 0.5 + 0.5) / (tw * 0.5)
			var curve := 1.0 - u * u
			var v := 0.62 + float(ly) / th * 0.32 * curve + _h(posmod((x + off) / tw, S / tw), row, 91) * 0.1
			if ly == th - 1 or lx == 0:
				v = 0.36
			_put(img, x, y, v * (0.94 + _fbm(x, y, 92) * 0.12))


## 슬레이트: 엇갈린 납작한 직사각형.
func _slate(img: Image) -> void:
	var th := 7
	var tw := 16
	for y in S:
		for x in S:
			var row := int(floor(float(y) / th))
			var off := (tw / 2) * (row % 2)
			var lx := posmod(x + off, tw)
			var ly := posmod(y, th)
			var v := 0.7 + _h(posmod((x + off) / tw, S / tw), posmod(row, 18), 101) * 0.16
			if ly >= th - 1 or lx == 0:
				v = 0.34
			_put(img, x, y, v * (0.95 + _fbm(x, y, 102) * 0.1))


func _wood(img: Image) -> void:
	for y in S:
		for x in S:
			var plank := x / 16
			var v := 0.62 + _h(plank, 0, 111) * 0.18 + (_noise(x * 0.5, y * 4.0, 16, 112) - 0.5) * 0.12
			if x % 16 == 0:
				v = 0.3
			_put(img, x, y, v)


## 계단: 16px마다 디딤면(밝다) + 챌면(어둡다).
func _stairs(img: Image) -> void:
	for y in S:
		for x in S:
			var ly := y % 16
			var v := 0.82 if ly < 10 else 0.5
			if ly == 0:
				v = 0.95
			v *= 0.92 + _fbm(x, y, 121) * 0.16
			if posmod(x + (y / 16) * 13, 37) == 0:
				v *= 0.7  # 돌 이음
			_put(img, x, y, v)


## 납 지붕(돔·첨탑).
func _lead(img: Image) -> void:
	for y in S:
		for x in S:
			var v := 0.68 + (_fbm(x, y, 131) - 0.5) * 0.18
			if x % 16 == 0:
				v = 0.42  # 이음 띠
			_put(img, x, y, v)
