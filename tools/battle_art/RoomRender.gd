extends RefCounted
## 전투 뒷그림 칠하기(Room.render): 픽셀마다 Room.trace로 면·세계 점·법선을 얻고 재질을 받아 두었다가,
## 이웃 픽셀의 결 높이 차로 법선을 흔들어 빛(Room.shade)·잉크·안개(Room.fog)로 칠한다. 하늘·낭떠러지(flat)는 그대로.
## 끝나면 깊이(zbuf)·면(kind_buf)을 Room에 남긴다(소품이 벽 뒤로 숨는다). tools/paint_battlebacks.gd 전용.

const Paint := preload("res://tools/city_art/Paint.gd")


static func run(room: RefCounted, p: Paint) -> void:
	var w: int = room.w
	var h: int = room.h
	var n := w * h
	var zbuf := PackedFloat32Array()
	zbuf.resize(n)
	var kind_buf := PackedByteArray()
	kind_buf.resize(n)
	var pos := PackedVector3Array()
	pos.resize(n)
	var nor := PackedVector3Array()
	nor.resize(n)
	var hgt := PackedFloat32Array()
	hgt.resize(n)
	var alb := PackedColorArray()
	alb.resize(n)
	var emi := PackedColorArray()
	emi.resize(n)
	var ink := PackedFloat32Array()
	ink.resize(n)
	var spc := PackedFloat32Array()
	spc.resize(n)
	var flat := PackedByteArray()
	flat.resize(n)
	for y in h:
		for x in w:
			var tr: Array = room.trace(x, y)
			var t: float = tr[0]
			var kind: int = tr[1]
			var P: Vector3 = tr[2]
			var N: Vector3 = tr[3]
			var m: Dictionary = room.material.call(kind, P, N)
			var i := y * w + x
			zbuf[i] = t
			kind_buf[i] = kind
			pos[i] = P
			nor[i] = N
			hgt[i] = float(m.get("h", 0.0))
			alb[i] = m.get("c", Color.GRAY)
			emi[i] = m.get("emit", Color.BLACK)
			ink[i] = float(m.get("ink", 0.0))
			spc[i] = float(m.get("spec", 0.0))
			flat[i] = 1 if m.get("flat", false) else 0
	for y in h:
		for x in w:
			var i := y * w + x
			if flat[i] == 1:
				var fc := alb[i]
				var fk := i * 4
				p.buf[fk] = clampf(fc.r, 0.0, 1.0)
				p.buf[fk + 1] = clampf(fc.g, 0.0, 1.0)
				p.buf[fk + 2] = clampf(fc.b, 0.0, 1.0)
				p.buf[fk + 3] = 1.0
				continue
			var N := nor[i]
			var xi := i + 1 if x + 1 < w else i - 1
			var yi := i + w if y + 1 < h else i - w
			if kind_buf[xi] == kind_buf[i] and kind_buf[yi] == kind_buf[i]:
				var tx := pos[xi] - pos[i]
				var ty := pos[yi] - pos[i]
				var lx := tx.length()
				var ly := ty.length()
				if lx > 1e-5 and ly > 1e-5 and lx < 0.5 and ly < 0.5:
					var gx := (hgt[xi] - hgt[i]) / lx * (1.0 if xi > i else -1.0)
					var gy := (hgt[yi] - hgt[i]) / ly * (1.0 if yi > i else -1.0)
					N = (N - (tx / lx) * gx * room.bump - (ty / ly) * gy * room.bump).normalized()
			var c: Color = room.shade(pos[i], N, alb[i], spc[i]) + emi[i]
			c = c.lerp(Color("#120d0a"), clampf(ink[i], 0.0, 1.0))
			c = room.fog(c, zbuf[i])
			var k := i * 4
			p.buf[k] = clampf(c.r, 0.0, 1.0)
			p.buf[k + 1] = clampf(c.g, 0.0, 1.0)
			p.buf[k + 2] = clampf(c.b, 0.0, 1.0)
			p.buf[k + 3] = 1.0
	room.zbuf = zbuf
	room.kind_buf = kind_buf
