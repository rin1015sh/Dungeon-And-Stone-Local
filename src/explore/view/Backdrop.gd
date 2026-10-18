class_name Backdrop
extends RefCounted
## 낭떠러지(void 타일) 너머 뒷배경 설정(층 art.backdrop — 균열 look.art.backdrop): 그림·시차·절벽 면 색.
##   image  뒷배경 그림(tools/paint_floor.gd → assets/floor/<장소>/backdrop.webp)
##   drift  카메라가 움직일 때 뒷배경이 따라 움직이는 비율(0 = 화면에 고정 — 아주 먼 하늘, 클수록 가깝다)
##   scale  [x, y] 화면 하나에 그림 몇 장(1 = 그림 한 장이 화면 하나)
##   cliff_color · cliff_depth  낭떠러지 가장자리에서 아래로 떨어지는 절벽 면(색, 칸 비율) — VoidChunk

const SHADER := "res://assets/shaders/backdrop.gdshader"


## 뒷배경 셰이더 재질(그림이 없으면 null — 낭떠러지는 색칠한 칸).
static func material(art: FloorArt) -> ShaderMaterial:
	var path := JsonUtil.get_str(art.backdrop, "image")
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var m := ShaderMaterial.new()
	m.shader = load(SHADER) as Shader
	m.set_shader_parameter("backdrop", load(path) as Texture2D)
	m.set_shader_parameter("drift", JsonUtil.get_float(art.backdrop, "drift", 0.12))
	var sc := JsonUtil.get_array(art.backdrop, "scale")
	m.set_shader_parameter("scale", Vector2(float(sc[0]), float(sc[1])) if sc.size() == 2 else Vector2.ONE)
	return m


static func cliff_color(art: FloorArt) -> Color:
	return Color.from_string(JsonUtil.get_str(art.backdrop, "cliff_color", "#2a2224"), Color(0.16, 0.13, 0.14))


static func cliff_depth(art: FloorArt) -> float:
	return JsonUtil.get_float(art.backdrop, "cliff_depth", 0.9)
