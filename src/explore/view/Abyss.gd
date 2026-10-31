class_name Abyss
extends RefCounted
## 낭떠러지·구덩이(void 타일) 그리기 설정(층 art.abyss — 균열 look.art.abyss) → 셰이더 재질(abyss.gdshader).
## 화면에 고정된 뒷배경 그림 대신 세계 좌표로: 땅 가장자리를 잡음으로 들쭉날쭉 깎고, 그 아래 절벽 면(cliff 그림 — 가로로 이어지는 띠,
## 아래로 갈수록 어둠)과 깊은 어둠(abyss_color + 흐르는 안개 mist_color)을 칠한다. 나무 발판(타일 art.void_edge "beam")은 깎지 않고
## 들보 면·난간(VoidChunk)을 그린다.
##   cliff        절벽 면 그림(tools/paint_floor.gd → assets/floor/<장소>/chasm.webp)
##   cliff_tiles  그림 한 장이 덮는 가로 칸 수 · cliff_depth 절벽 면 높이(칸)
##   jag          땅 가장자리를 깎는 깊이(칸 비율, 0~0.45)
##   abyss_color · mist_color · rim_color(절벽 위 턱의 부스러진 테두리) · beam_color(발판 들보)
##   rail         {post, rope, every, height} — 허공 위 나무 발판의 난간(색·기둥 간격 칸·높이 칸)
##   rise         {face, top, face_tiles, face_depth, top_tiles, fog, jag, dark} — 솟은 외곽(타일 "rise": true — 지도 바깥 둘레):
##                내려가는 대신 위로 솟은 벽·절벽 면(face — 위 = 꼭대기, 성가퀴 틈 투명)과 그 너머 꼭대기 풍경(top — 사방으로 이어 붙임)

const SHADER := "res://assets/shaders/abyss.gdshader"


## 셰이더 재질(설정이 없으면 null — 낭떠러지는 색칠한 칸).
static func material(art: FloorArt, map: FloorMap, tile: int) -> ShaderMaterial:
	if art.abyss.is_empty():
		return null
	var a := art.abyss
	var m := ShaderMaterial.new()
	m.shader = load(SHADER) as Shader
	m.set_shader_parameter("mask", mask_texture(map))
	m.set_shader_parameter("dist", dist_texture(map))
	m.set_shader_parameter("map_size", Vector2(map.width, map.height))
	m.set_shader_parameter("tile", float(tile))
	var path := JsonUtil.get_str(a, "cliff")
	if not path.is_empty() and ResourceLoader.exists(path):
		m.set_shader_parameter("cliff", load(path) as Texture2D)
	m.set_shader_parameter("cliff_w", JsonUtil.get_float(a, "cliff_tiles", 8.0) * tile)
	m.set_shader_parameter("cliff_h", JsonUtil.get_float(a, "cliff_depth", 2.0) * tile)
	m.set_shader_parameter("jag", clampf(JsonUtil.get_float(a, "jag", 0.32), 0.0, 0.45))
	m.set_shader_parameter("abyss_color", _c(a, "abyss_color", "#060608"))
	m.set_shader_parameter("mist_color", _c(a, "mist_color", "#141418"))
	m.set_shader_parameter("rim_color", _c(a, "rim_color", "#9a8e80"))
	m.set_shader_parameter("beam_color", _c(a, "beam_color", "#4a3824"))
	var r := JsonUtil.get_dict(a, "rise")
	if not r.is_empty():
		for key: String in ["face", "top"]:
			var rp := JsonUtil.get_str(r, key)
			if ResourceLoader.exists(rp):
				m.set_shader_parameter("rise_" + key, load(rp) as Texture2D)
		m.set_shader_parameter("rise_w", JsonUtil.get_float(r, "face_tiles", 8.0) * tile)
		m.set_shader_parameter("rise_h", JsonUtil.get_float(r, "face_depth", 3.0) * tile)
		m.set_shader_parameter("rise_top_w", JsonUtil.get_float(r, "top_tiles", 8.0) * tile)
		m.set_shader_parameter("rise_fog", JsonUtil.get_float(r, "fog", 6.0))
		m.set_shader_parameter("rise_jag", clampf(JsonUtil.get_float(r, "jag", 0.0), 0.0, 0.45))
		m.set_shader_parameter("rise_dark", _c(r, "dark", "#0c0a0a"))
	return m


## 칸 지도 그림(지도 칸 = 텍셀): r = 허공, g = 나무 발판(깎지 않는 가장자리), b = 솟은 외곽.
static func mask_texture(map: FloorMap) -> ImageTexture:
	var img := Image.create(map.width, map.height, false, Image.FORMAT_RGB8)
	for y in map.height:
		for x in map.width:
			var d := map.defs[map.tiles[y * map.width + x]]
			img.set_pixel(x, y, Color(1.0 if d.is_void else 0.0, 1.0 if d.void_edge == "beam" else 0.0, 1.0 if d.is_rise else 0.0))
	return ImageTexture.create_from_image(img)


## 칸 거리 그림(균열 렉 — CT73, 셰이더가 땅 찾기 걸음을 경계 칸 안에서만 하게): r = 반대쪽(허공 칸이면 땅, 땅 칸이면 허공)까지 체비쇼프 거리,
## g = 위(북쪽)로 가장 가까운 땅 칸까지(바로 위가 땅이면 1), b = 아래(남쪽)로, a = 같은 줄 옆으로 — 모두 칸 수 / FAR(FAR에서 멈춤).
## 균열 지도(작다)만 낭떠러지 셰이더를 쓴다 — r은 경계 칸에서만 퍼뜨린다.
const FAR := 15


static func dist_texture(map: FloorMap) -> ImageTexture:
	var w := map.width
	var h := map.height
	var vd := PackedByteArray()
	vd.resize(w * h)
	for i in w * h:
		vd[i] = 1 if map.defs[map.tiles[i]].is_void else 0
	var far := PackedByteArray()
	far.resize(w * h)
	far.fill(FAR)
	var front := PackedInt32Array()
	for y in h:
		for x in w:
			var i := y * w + x
			var edge := false
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var xx := x + dx
					var yy := y + dy
					if xx >= 0 and yy >= 0 and xx < w and yy < h and vd[yy * w + xx] != vd[i]:
						edge = true
			if edge:
				far[i] = 1
				front.append(i)
	var level := 1
	while not front.is_empty() and level < FAR - 1:
		var next := PackedInt32Array()
		for i in front:
			var x := i % w
			var y := i / w
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var xx := x + dx
					var yy := y + dy
					if xx < 0 or yy < 0 or xx >= w or yy >= h:
						continue
					var j := yy * w + xx
					if vd[j] == vd[i] and far[j] > level + 1:
						far[j] = level + 1
						next.append(j)
		front = next
		level += 1
	var up := PackedByteArray()
	up.resize(w * h)
	var down := PackedByteArray()
	down.resize(w * h)
	for x in w:
		var run := FAR
		for y in h:
			var i := y * w + x
			run = 0 if vd[i] == 0 else mini(FAR, run + 1)
			up[i] = run
		run = FAR
		for y in range(h - 1, -1, -1):
			var i := y * w + x
			run = 0 if vd[i] == 0 else mini(FAR, run + 1)
			down[i] = run
	var side := PackedByteArray()  # 같은 줄 왼쪽·오른쪽 중 가까운 땅까지
	side.resize(w * h)
	for y in h:
		var run := FAR
		for x in w:
			var i := y * w + x
			run = 0 if vd[i] == 0 else mini(FAR, run + 1)
			side[i] = run
		run = FAR
		for x in range(w - 1, -1, -1):
			var i := y * w + x
			run = 0 if vd[i] == 0 else mini(FAR, run + 1)
			side[i] = mini(side[i], run)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var i := y * w + x
			img.set_pixel(x, y, Color(far[i] / float(FAR), up[i] / float(FAR), down[i] / float(FAR), side[i] / float(FAR)))
	return ImageTexture.create_from_image(img)


static func rail(art: FloorArt) -> Dictionary:
	return JsonUtil.get_dict(art.abyss, "rail")


static func color(art: FloorArt, key: String, fallback: String) -> Color:
	return _c(art.abyss, key, fallback)


static func _c(d: Dictionary, key: String, fallback: String) -> Color:
	return Color.from_string(JsonUtil.get_str(d, key, fallback), Color.from_string(fallback, Color.BLACK))
