class_name AmbientParticles
extends Node2D
## 층 분위기 입자(층 JSON art.particles — 먼지·물방울·재·눈 등). 플레이어를 따라다니며 시야 반경 안에서만 생기고,
## 생긴 입자는 월드에 남아(local_coords 끔) 걸어도 함께 끌려가지 않는다. 웹 호환을 위해 CPUParticles2D.
## 항목 = {id, amount, lifetime, color, alpha, scale[min,max](px), velocity[min,max](px/s), direction[x,y], spread(도), gravity[x,y]}

const TEXTURE_SIZE := 16

var _emitters: Array[CPUParticles2D] = []


func setup(list: Array[Dictionary]) -> void:
	var tex := _dot_texture()
	for e: Dictionary in list:
		var p := CPUParticles2D.new()
		p.name = JsonUtil.get_str(e, "id", "particles")
		p.texture = tex
		p.amount = maxi(1, JsonUtil.get_int(e, "amount", 20))
		p.lifetime = maxf(0.1, JsonUtil.get_float(e, "lifetime", 6.0))
		p.preprocess = p.lifetime
		p.local_coords = false
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 96.0
		var col := Color.from_string(JsonUtil.get_str(e, "color", "#ffffff"), Color.WHITE)
		col.a = JsonUtil.get_float(e, "alpha", 0.3)
		var ramp := Gradient.new()  # 생기고 사라질 때 서서히
		ramp.set_color(0, Color(col, 0.0))
		ramp.set_color(1, Color(col, 0.0))
		ramp.add_point(0.2, col)
		ramp.add_point(0.8, col)
		p.color_ramp = ramp
		var sc := _pair(e, "scale", Vector2(1.0, 2.0))
		p.scale_amount_min = sc.x / TEXTURE_SIZE
		p.scale_amount_max = sc.y / TEXTURE_SIZE
		var vel := _pair(e, "velocity", Vector2(2.0, 6.0))
		p.initial_velocity_min = vel.x
		p.initial_velocity_max = vel.y
		p.direction = _pair(e, "direction", Vector2(0.0, -1.0))
		p.spread = JsonUtil.get_float(e, "spread", 180.0)
		p.gravity = _pair(e, "gravity", Vector2.ZERO)
		add_child(p)
		_emitters.append(p)


## 입자가 생기는 반경(px) = 지금 시야.
func set_radius(px: float) -> void:
	for p in _emitters:
		p.emission_sphere_radius = maxf(8.0, px)


static func _pair(e: Dictionary, key: String, fallback: Vector2) -> Vector2:
	var a := JsonUtil.get_array(e, key)
	return Vector2(float(a[0]), float(a[1])) if a.size() == 2 else fallback


static func _dot_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = TEXTURE_SIZE
	tex.height = TEXTURE_SIZE
	return tex
