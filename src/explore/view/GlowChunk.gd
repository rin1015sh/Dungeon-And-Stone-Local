class_name GlowChunk
extends Node2D
## 청크 하나의 맥동 빛(층 JSON art.pulse.tiles): 지금 보이는 빛나는 타일마다 둥근 빛 번짐을 더한다(가산 혼합).
## 맥동은 셰이더(crystal_pulse)가 TIME으로 움직이니 시야가 바뀔 때만 다시 그린다. 벽이면 앞면 가운데, 바닥이면 칸 가운데.

const SHADER := "res://assets/shaders/crystal_pulse.gdshader"
const TEXTURE_SIZE := 64

var view: FloorView
var cells: Rect2i
var _pulse: PackedByteArray  # map.defs 번호 -> 맥동 타일이면 1


func setup(p_view: FloorView, p_cells: Rect2i) -> void:
	view = p_view
	cells = p_cells
	_pulse = PackedByteArray()
	_pulse.resize(view.map.defs.size())
	for i in view.map.defs.size():
		_pulse[i] = 1 if view.art.pulse_tiles.has(view.map.defs[i].id) and view.map.defs[i].emits_light() else 0
	material = view.glow_material


func _draw() -> void:
	var map := view.map
	var t := float(view.tile)
	var r := view.art.pulse_radius_m * t
	var k := view.art.pulse_strength
	var tex := view.glow_texture
	for y in range(cells.position.y, cells.end.y):
		for x in range(cells.position.x, cells.end.x):
			var i := y * map.width + x
			if _pulse[map.tiles[i]] == 0 or map.visible_now[i] == 0:
				continue
			var def := map.defs[map.tiles[i]]
			var c := Vector2((x + 0.5) * t, (y + 0.5) * t)
			if def.is_wall():
				c.y = (y + 1) * t - view.wall_face_of(def) * 0.5
			var phase := float(absi(hash(Vector2i(x, y))) % 1000) / 1000.0
			var col := def.light_color * k
			col.a = phase
			draw_texture_rect(tex, Rect2(c - Vector2(r, r), Vector2(r * 2.0, r * 2.0)), false, col)


## 둥근 빛 번짐 그림(가운데 1 → 가장자리 0). FloorView가 한 번 만들어 청크들이 같이 쓴다.
static func make_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.45, Color(1, 1, 1, 0.35))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = TEXTURE_SIZE
	tex.height = TEXTURE_SIZE
	return tex


static func make_material(period: float, depth: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(SHADER) as Shader
	m.set_shader_parameter("period", period)
	m.set_shader_parameter("depth", depth)
	return m
