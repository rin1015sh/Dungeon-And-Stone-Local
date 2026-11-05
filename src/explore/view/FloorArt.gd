class_name FloorArt
extends RefCounted
## 층의 그림 설정(층 JSON `art` — 균열 챕터는 균열 `look.art`) = render.json 기본값 위에 층 값을 덮는다.
##   palette  {unexplored(미탐험 = 순흑), near_black(보이는 곳의 가장 어두운 색), tone(CanvasModulate 색조),
##             memory_tint, memory_brightness(기억 칸), memory_desat(기억 칸 그림 탈색 0~1 — 없으면 render.json view.memory_desat, FL10),
##             keep_hue(true면 근흑색 아래를 올릴 때 밝기만 맞추고 타일 색조는 남긴다 — 어둠 · 기억 칸도 풀은 푸르게, FL10)}
##   post     {saturation, vignette_strength, vignette_radius, grain_strength} — 화면 후처리
##   pulse    {tiles[], period_sec, depth, radius_m, strength} — 빛나는 타일의 느린 맥동(셰이더, 청크 다시 그리기 없음)
##   particles [{id, amount, lifetime, color, alpha, scale[min,max], velocity[min,max], direction[x,y], spread, gravity[x,y]}]
##   ambience {loop} — data/audio.json ambience 키(파일이 없으면 조용함)
##   abyss {cliff, cliff_tiles, cliff_depth, jag, abyss_color, mist_color, rim_color, beam_color, rail} — 낭떠러지·구덩이(void 타일)를
##          세계 좌표의 절벽 면 + 깊은 어둠으로(Abyss·VoidChunk — 화면에 고정된 뒷배경 그림은 쓰지 않는다)
##   battleback {image "res://…webp", half_width m} — 전투 화면 뒤 그림과 그 통로 반 폭(적이 앞뒤 줄로 그 안에 선다 — BattleStage·FoeRows,
##            그림 도구 tools/paint_battlebacks.gd — 균열 챕터는 챕터 battleback이 덮는다)
## 품질 "low"면 그레인·입자·맥동·횃불 흔들림을 끈다(GraphicsSettings).

const POST_KEYS := ["saturation", "vignette_strength", "vignette_radius", "grain_strength"]

var unexplored: Color = Color.BLACK
var near_black: Color = Color(0.05, 0.045, 0.06)
var tone: Color = Color.WHITE
var memory_tint: Color = Color.GRAY
var memory_brightness: float = 0.3
var memory_desat: float = -1.0  ## < 0 = render.json 기본값
var keep_hue: bool = false
var post: Dictionary = {}
var pulse_tiles: PackedStringArray = PackedStringArray()
var pulse_period: float = 6.0
var pulse_depth: float = 0.0
var pulse_radius_m: float = 1.5
var pulse_strength: float = 0.0
var particles: Array[Dictionary] = []
var ambience: String = ""
var abyss: Dictionary = {}
var battleback: String = ""
var battleback_width: float = 0.0  ## 통로 반 폭(m) — 0이면 render.json 기본값
var low_quality: bool = false


static func resolve(render: Dictionary, floor_def: Dictionary, quality: String = "high") -> FloorArt:
	var a := FloorArt.new()
	var view := JsonUtil.get_dict(render, "view")
	var lighting := JsonUtil.get_dict(render, "lighting")
	var art := JsonUtil.get_dict(floor_def, "art")
	var pal := JsonUtil.get_dict(art, "palette")
	a.low_quality = quality == "low"
	a.unexplored = _color(pal, "unexplored", JsonUtil.get_str(view, "unexplored_color", "#000000"))
	a.near_black = _color(pal, "near_black", JsonUtil.get_str(view, "near_black", "#0c0b0e"))
	a.tone = _color(pal, "tone", JsonUtil.get_str(lighting, "canvas_modulate", "#ffffff"))
	a.memory_tint = _color(pal, "memory_tint", JsonUtil.get_str(view, "memory_tint", "#808080"))
	a.memory_brightness = JsonUtil.get_float(pal, "memory_brightness", JsonUtil.get_float(view, "memory_brightness", 0.3))
	a.memory_desat = JsonUtil.get_float(pal, "memory_desat", -1.0)
	a.keep_hue = JsonUtil.get_bool(pal, "keep_hue")
	var p := JsonUtil.get_dict(art, "post")
	for key: String in POST_KEYS:
		if p.has(key) or lighting.has(key):
			a.post[key] = JsonUtil.get_float(p, key, JsonUtil.get_float(lighting, key))
	if a.low_quality:
		a.post["grain_strength"] = 0.0
	var pu := JsonUtil.get_dict(art, "pulse")
	for t: Variant in JsonUtil.get_array(pu, "tiles"):
		a.pulse_tiles.append(str(t))
	a.pulse_period = maxf(0.1, JsonUtil.get_float(pu, "period_sec", 6.0))
	a.pulse_depth = 0.0 if a.low_quality else clampf(JsonUtil.get_float(pu, "depth", 0.0), 0.0, 1.0)
	a.pulse_radius_m = JsonUtil.get_float(pu, "radius_m", 1.5)
	a.pulse_strength = JsonUtil.get_float(pu, "strength", 0.0)
	if not a.low_quality:
		for e: Variant in JsonUtil.get_array(art, "particles"):
			if e is Dictionary:
				a.particles.append(e)
	a.ambience = JsonUtil.get_str(JsonUtil.get_dict(art, "ambience"), "loop")
	a.abyss = JsonUtil.get_dict(art, "abyss")
	var bb := JsonUtil.get_dict(art, "battleback")
	a.battleback = JsonUtil.get_str(bb, "image")
	a.battleback_width = JsonUtil.get_float(bb, "half_width")
	return a


func has_pulse() -> bool:
	return not pulse_tiles.is_empty() and pulse_strength > 0.0


static func _color(d: Dictionary, key: String, fallback: String) -> Color:
	return Color.from_string(JsonUtil.get_str(d, key, fallback), Color.from_string(fallback, Color.BLACK))
