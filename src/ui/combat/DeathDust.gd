class_name DeathDust
extends Node2D
## 몬스터가 쓰러질 때(원문: 몸이 잘게 쪼개져 빛나는 먼지로 흩어지고 옷·무기도 함께 빛이 되어 사라진다 — docs/PROMPT_ART_MAP.md §3.4):
## 무대에서 치우는 그 몬스터 그림을 block px 조각으로 나눠, 조각마다 빛 색으로 물들며 위로 떠올라 흐려진다.
## 아래쪽 조각부터 먼저 흩어진다(발부터 사라지는 느낌). 끝나면 스스로 사라진다. 값은 render.json ui.combat_death_dust.

const LIT := 0.3  ## 처음부터 빛 색이 섞이는 정도(어두운 그림이 어둠에 묻히지 않게)

var _parts: Array[Dictionary] = []  # {p: 시작 자리, c: 색, d: 늦춤(초), v: 속도}
var _t: float = 0.0
var _sec: float = 1.4
var _glow: Color = Color("#ffe8b0")
var _block: float = 6.0


## art를 rect(무대 좌표) 크기로 그린 것을 조각낸다. flip = 좌우 반전으로 그려져 있었는지.
func setup(art: Texture2D, rect: Rect2, flip: bool, cfg: Dictionary, rng: RandomNumberGenerator) -> void:
	position = rect.position
	_sec = JsonUtil.get_float(cfg, "sec", 1.4)
	_glow = Color.from_string(JsonUtil.get_str(cfg, "color", "#ffe8b0"), _glow)
	_block = maxf(2.0, JsonUtil.get_float(cfg, "block", 6.0))
	var rise := JsonUtil.get_float(cfg, "rise", 70.0)
	var img := art.get_image()
	if img == null:
		return
	if img.is_compressed():
		img.decompress()
	var cols := maxi(1, int(rect.size.x / _block))
	var rows := maxi(1, int(rect.size.y / _block))
	var small := img.duplicate() as Image  # 조각 = 그 자리 그림의 평균 색(한 점만 찍으면 잉크 선이 많이 걸려 어둡다)
	small.convert(Image.FORMAT_RGBA8)
	if flip:
		small.flip_x()
	small.resize(cols, rows, Image.INTERPOLATE_TRILINEAR)
	for ry in rows:
		for rx in cols:
			var c := small.get_pixel(rx, ry)
			if c.a < 0.5:
				continue
			c.a = 1.0
			var low := float(ry) / rows  # 0 = 위, 1 = 아래
			_parts.append({"p": Vector2(rx, ry) * _block, "c": c, "d": (1.0 - low) * _sec * 0.35 + rng.randf() * _sec * 0.15,
				"v": Vector2(rng.randf_range(-0.35, 0.35), -rng.randf_range(0.6, 1.0)) * rise})


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t > _sec * 1.6:
		queue_free()


func _draw() -> void:
	for e in _parts:
		var k := clampf((_t - float(e["d"])) / _sec, 0.0, 1.0)  # 0 = 아직 몸, 1 = 다 흩어짐
		if k >= 1.0:
			continue
		var c: Color = (e["c"] as Color).lerp(_glow, minf(1.0, LIT + k * 2.5))  # 쓰러지는 순간부터 빛이 돈다
		c.a = 1.0 - k * k
		var s := _block * (1.0 - k * 0.6)
		var p: Vector2 = e["p"] + (e["v"] as Vector2) * k + Vector2(sin(_t * 6.0 + float(e["d"]) * 20.0) * 2.0 * k, 0)
		draw_rect(Rect2(p + Vector2(_block - s, _block - s) * 0.5, Vector2(s, s)), c)
