extends RefCounted
## 털 덧그리기(칠한 뒤): 털 재질(kind "fur") 자리마다 끝이 가는 털 뭉치(휘어진 쐐기)를 아래·바깥으로 늘어뜨린다.
## 아래 줄부터 그려 위 뭉치가 아래 뭉치 뿌리를 덮는다. 가장자리 뭉치는 윤곽 밖으로 삐져나와 덥수룩한 실루엣이 된다.
## 색은 그 자리 칠한 색에서 — 뿌리 쪽 어둡게, 끝은 밝게(빛 받는 쪽) + 한쪽에 가는 잉크.

const Clay := preload("res://tools/monster_art/Clay.gd")
const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")


## scale = 몸 높이 px. length = 뭉치 길이 배율. flow = 기본 흐름 방향(아래). only_g = 이 그룹만(-1이면 전부).
static func comb(cl: Clay, p: Paint, scale: float, length: float = 1.0, flow: Vector2 = Vector2(0, 1), only_g: int = -1) -> void:
	var sp := maxf(3.0, scale / 85.0)
	var seeds: Array = []
	var y := 0.0
	while y < cl.h:
		var x := 0.0
		while x < cl.w:
			var jx := int(x + Paint.hash01(int(x), int(y), 41) * sp)
			var jy := int(y + Paint.hash01(int(x), int(y), 42) * sp)
			x += sp
			if jx >= cl.w or jy >= cl.h:
				continue
			var i := jy * cl.w + jx
			var m := cl.top_m[i]
			if m < 0 or str(cl.mats[m]["kind"]) != "fur":
				continue
			if only_g >= 0 and cl.top_g[i] != only_g:
				continue
			seeds.append(Vector2i(jx, jy))
		y += sp
	seeds.reverse()  # 아래부터
	var cx := cl.w * 0.5
	for sd: Vector2i in seeds:
		var base := p.get_c(sd.x, sd.y)
		if base.a <= 0.0:
			continue
		var h1 := Paint.hash01(sd.x, sd.y, 43)
		var h2 := Paint.hash01(sd.x, sd.y, 44)
		if Paint.hash01(sd.x, sd.y, 45) < 0.3:
			continue
		var out := Vector2((sd.x - cx) / cl.w * 1.6, 0.0)
		var dir := (flow + out + Vector2(h1 - 0.5, 0) * 0.9).normalized()
		var ln := sp * (1.1 + h2 * 1.4) * length
		var wd := sp * (0.5 + h1 * 0.35)
		var lum := base.get_luminance()
		var root := base.darkened(0.04)
		var tip := base.lightened(0.06 + lum * 0.14) if h2 > 0.35 else base.darkened(0.07)
		_lock(p, Vector2(sd.x, sd.y), dir, ln, wd, root, tip, h1 - 0.5)


## 털 뭉치 하나: 뿌리 굵고 끝이 가는 휜 붓 획(가장자리 부드럽게, 뿌리→끝 색이 바뀜). bend = 휘는 정도(-0.5~0.5).
static func _lock(p: Paint, root: Vector2, dir: Vector2, ln: float, wd: float, c0: Color, c1: Color, bend: float) -> void:
	var nrm := Vector2(-dir.y, dir.x)
	var steps := int(ln * 1.2) + 2
	for k in steps + 1:
		var t := float(k) / steps
		var q := root + dir * ln * t + nrm * bend * ln * 0.35 * t * t
		var r := wd * 0.5 * (1.0 - t * 0.85)
		var col := c0.lerp(c1, t)
		for yy in range(int(q.y - r - 1), int(q.y + r + 1) + 1):
			for xx in range(int(q.x - r - 1), int(q.x + r + 1) + 1):
				var cov := clampf(r - Vector2(xx + 0.5 - q.x, yy + 0.5 - q.y).length() + 0.5, 0.0, 1.0)
				if cov > 0.0:
					p.blend(xx, yy, col, cov * 0.32)
	if p.rng.randf() < 0.25:  # 가끔 그늘 쪽에 가는 잉크
		var a := root - nrm * wd * 0.3
		Ink.line(p, a, a + dir * ln * 0.85 + nrm * bend * ln * 0.25, maxf(0.6, wd * 0.12), Ink.INK, 0.28, 0.3)
