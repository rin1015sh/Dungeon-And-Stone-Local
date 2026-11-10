extends RefCounted
## 탐험 맵 소품(tools/paint_floor.gd — 동굴 요소·포탈의 마름모 표식을 대신하는 그림): 시트 한 칸 = 소품 하나, 투명 RGBA.
## 칸 = 바닥 1.5칸 크기(tiles.json art.prop.size 1.5). 게임은 그림 아래 끝을 칸 아래쪽 근처에 둔다 —
## 바닥에 누운 것은 그림 높이 72% 근처(= 칸 가운데), 서 있는 것은 85% 근처에 밑동을 둔다.
## 상호작용 대상이라 둘레보다 조금 밝게(게임이 prop_highlight를 곱한다) + 가장자리에 빛 받은 테두리.
## 칠은 Cave(돌·점·수정·금)·Decals(얼룩·막대·뼈) 부품 + Ink.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")
const Decals := preload("res://tools/floor_art/Decals.gd")
const Solid := preload("res://tools/floor_art/Solid.gd")

## 시트 칸 순서(tiles.json art.prop.cell이 이 번호를 가리킨다).
const ORDER := ["corpse", "ghoul_feast", "stone_heap", "dead_campfire", "broken_gear", "offering", "spring", "drip",
	"stalagmites", "mushroom", "wolf_den", "gnome_trinkets", "gnome_stash", "goblin_camp", "torch_stubs", "old_skeleton",
	"cairn", "cache", "goblin_snare", "wet_slope", "portal", "rift_portal", "rift_gate",
	"wolf_kill", "gnome_marker", "goblin_lookout", "wolf_tracks",  # 레벨 디자인 LD2(2026-11-07)
	"bear_trap", "bear_trap_shut"]  # 곰덫(2026-11-10 — 덫을 바닥 타일 대신 소품 한 칸으로)

const SKIN := Color("#8a7a6a")
const CLOTH := Color("#4a4236")
const LEATHER := Color("#5a3e28")
const METAL := Color("#70787f")
const WOOD := Color("#4e3a28")
const BLOOD := Color("#4a0d0a")
const BONE := Color("#b8ae98")
const STONE := Color("#6a6470")


static func paint(kind: String, w: int, seed_value: int) -> Paint:
	var p := Paint.new(w, w, seed_value + kind.hash() % 1000)
	var u := w / 96.0
	var c := Vector2(w * 0.5, w * 0.72)  # 바닥에 누운 것의 가운데(칸 가운데)
	var foot := Vector2(w * 0.5, w * 0.84)  # 서 있는 것의 밑동
	match kind:
		"corpse":  # 탐험가 맵 몸 그림(걷는 탐험가와 같은 그림)을 눕힌 시체 — 사람 크기(tiles.json feat_corpse art.prop.size)
			Decals._blob(p, c + Vector2(4, 10) * u, 36 * u, BLOOD, 0.8, 0.35)  # 몸 밑에서 번진 피
			Decals._blob(p, c + Vector2(-26, 6) * u, 18 * u, BLOOD.darkened(0.2), 0.7, 0.4)
			Decals._blob(p, c + Vector2(22, 18) * u, 12 * u, BLOOD.darkened(0.1), 0.6, 0.45)
			_shadow(p, c, 40 * u, 14 * u)
			Decals._stick(p, c + Vector2(-34, 16) * u, c + Vector2(-8, 22) * u, 2.6 * u, METAL.darkened(0.2))  # 떨어뜨린 칼
			_lying_body(p, c, w * 0.86, -1.42, "res://assets/actors/human.webp", 0)
			Cave._stone(p, c + Vector2(30, 14) * u, 8 * u, 6 * u, LEATHER)  # 굴러 나온 등짐
			Ink.line(p, c + Vector2(24, 11) * u, c + Vector2(36, 11) * u, 1.0 * u, Ink.INK, 0.6, 0.4)
		"ghoul_feast":  # 뜯긴 고깃덩이와 뼈 더미(입체 — V27)
			Decals._blob(p, c + Vector2(0, 6) * u, 28 * u, BLOOD.darkened(0.2), 0.8, 0.3)
			Solid.shadow(p, c + Vector2(0, 6) * u, 24 * u, 8 * u)
			for k in 5:
				var q := c + Vector2(p.rng.randf_range(-16, 16), p.rng.randf_range(-2, 8) + k * 0.8) * u
				Solid.lump(p, q, p.rng.randf_range(6, 10) * u, 4 * u, p.rng.randf_range(5, 9) * u, Color("#6a2a22").lightened(p.rng.randf_range(-0.1, 0.15)), 0.5, 0.0, u)
			for k in 3:
				Decals._bones(p, c + Vector2(p.rng.randf_range(-12, 12), p.rng.randf_range(-2, 4)) * u, u * 1.4)
			Solid.lump(p, c + Vector2(10, 8) * u, 6 * u, 4 * u, 7 * u, BONE, 0.2, 0.0, u)  # 해골
			Cave._dot(p, c + Vector2(8, 2) * u, 1.4 * u, Ink.INK, 0.9)
			Cave._dot(p, c + Vector2(12, 2) * u, 1.4 * u, Ink.INK, 0.9)
		"stone_heap":  # 쌓인 돌무더기(뒤에서 앞으로 — V27)
			Solid.shadow(p, c + Vector2(0, 6) * u, 28 * u, 10 * u)
			for row in 3:
				for k in 4 - row:
					var q := c + Vector2((k - (3 - row) * 0.5) * 12 + p.rng.randf_range(-3, 3), 8 - row * 7 + (2 - row) * 0.0) * u
					var r := p.rng.randf_range(7.0, 10.0) * u
					Solid.lump(p, q + Vector2(0, -row * 2) * u, r, r * 0.45, r * 0.9, STONE.lightened(p.rng.randf_range(-0.08, 0.15)), 0.45, 0.0, u)
		"dead_campfire":  # 돌로 두른 꺼진 모닥불 — 재 둔덕 + 숯이 된 장작(입체 — V27)
			Solid.shadow(p, c + Vector2(0, 4) * u, 24 * u, 10 * u)
			var ring: Array = []
			for k in 9:
				var a := TAU * k / 9.0
				ring.append([sin(a), c + Vector2(cos(a) * 18, sin(a) * 10 + 4) * u])
			ring.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
			for e: Array in ring.slice(0, 4):
				Solid.lump(p, e[1], 5 * u, 3 * u, 5 * u, STONE, 0.5, 0.0, u)
			Solid.lump(p, c + Vector2(0, 5) * u, 12 * u, 6 * u, 4 * u, Color("#3a3634"), 0.6, 0.0, u)  # 재
			Solid.log(p, c + Vector2(-12, 2) * u, c + Vector2(8, 8) * u, 3.2 * u, Color("#1e1814"), Color("#3a2a20"), u)
			Solid.log(p, c + Vector2(10, 0) * u, c + Vector2(-6, 9) * u, 3.0 * u, Color("#241c16"), Color("#4a3426"), u)
			for e: Array in ring.slice(4):
				Solid.lump(p, e[1], 5 * u, 3 * u, 5 * u, STONE.lightened(0.05), 0.5, 0.0, u)
		"broken_gear":  # 기대어 선 깨진 둥근 방패 · 굴러 있는 투구 · 부러진 칼(입체 — V27)
			Solid.shadow(p, c + Vector2(0, 6) * u, 28 * u, 9 * u)
			var sh := c + Vector2(10, 2) * u
			var disc := Cave._ellipse(sh + Vector2(0, -10) * u, 12 * u, 14 * u, 28)  # 세워 기댄 방패(앞면)
			p.fill_poly(Cave._ellipse(sh + Vector2(3, -9) * u, 12 * u, 14 * u, 28), p.flat(WOOD.darkened(0.5), 0.05))  # 두께
			p.fill_poly(disc, func(x: int, y: int) -> Color:
				var t := clampf(((x - sh.x) + (y - sh.y + 10 * u)) / (24.0 * u) + 0.5, 0.0, 1.0)
				return p.vary(WOOD.lightened(0.18).lerp(WOOD.darkened(0.3), t), x, y, 0.1))
			Ink.path(p, disc, 1.4 * u, true, Ink.INK, 0.9, 0.4)
			Ink.line(p, sh + Vector2(-4, -22) * u, sh + Vector2(3, 0) * u, 1.5 * u, Ink.INK, 0.9, 0.7)  # 금
			Solid.lump(p, sh + Vector2(0, -8) * u, 3.4 * u, 2 * u, 3 * u, METAL, 0.1, 0.0, u)  # 방패 장식
			Decals._stick(p, c + Vector2(-28, 8) * u, c + Vector2(-6, 0) * u, 3.0 * u, METAL)
			Decals._stick(p, c + Vector2(-28, 8) * u, c + Vector2(-34, 11) * u, 3.4 * u, LEATHER)
			Solid.lump(p, c + Vector2(-10, 12) * u, 8 * u, 5 * u, 8 * u, METAL.darkened(0.1), 0.15, 0.0, u)  # 투구
			Ink.line(p, c + Vector2(-16, 9) * u, c + Vector2(-4, 9) * u, 1.0 * u, Ink.INK, 0.8, 0.3)
		"offering":  # 낮은 돌 제단 — 위에 초 둘과 바친 금화(입체 — V27)
			var slab := c + Vector2(0, 8) * u
			Solid.shadow(p, slab, 22 * u, 8 * u)
			Solid.block(p, slab, 34 * u, 12 * u, 9 * u, func(x: int, y: int) -> Color: return p.vary(STONE.darkened(0.12), x, y, 0.08),
				func(x: int, y: int) -> Color: return p.vary(STONE.lightened(0.18), x, y, 0.08), func(x: int, y: int) -> Color: return p.vary(STONE.darkened(0.4), x, y, 0.08), u)
			var top := slab + Vector2(2, -13) * u
			for k in 7:
				Cave._dot(p, top + Vector2(p.rng.randf_range(-12, 12), p.rng.randf_range(-3, 3)) * u, 1.8 * u, Color("#c9a24a"), 0.95)
			for k in 2:
				var q := top + Vector2(-8 + k * 14, 0) * u
				Solid.drum(p, q, 1.8 * u, 9 * u, Color("#d8d0b8"), Color("#efe6cc"), u * 0.6)
				Ink.glow(p, q.x, q.y - 12 * u, 7 * u, Color("#ffb46a"), 0.5, false)
				Cave._dot(p, q + Vector2(0, -12) * u, 1.5 * u, Color("#ffe0a0"), 1.0)
		"spring":  # 돌을 둘러 쌓은 샘 — 뒤쪽 돌 · 물 · 앞쪽 돌(입체 — V27)
			var ring: Array = []
			for k in 11:
				var a := TAU * k / 11.0
				ring.append([sin(a), c + Vector2(cos(a) * 21, sin(a) * 12 + 4) * u])
			ring.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
			for e: Array in ring.slice(0, 5):
				Solid.lump(p, e[1], 5.5 * u, 3 * u, 6 * u, STONE, 0.5, 0.0, u)
			Decals._blob(p, c + Vector2(0, 4) * u, 15 * u, Color("#162a3c"), 1.0, 0.1)
			Decals._blob(p, c + Vector2(-3, 2) * u, 9 * u, Color("#2f5a78"), 0.6, 0.1)
			for k in 4:
				Decals._spot(p, c + Vector2(p.rng.randf_range(-9, 4), p.rng.randf_range(-2, 6)) * u, 1.2 * u, Color("#d8ecff"), 0.8)
			for e: Array in ring.slice(5):
				Solid.lump(p, e[1], 5.5 * u, 3 * u, 6 * u, STONE.lightened(0.06), 0.5, 0.0, u)
		"drip":
			Decals._blob(p, c, 14 * u, Color("#1e2434"), 0.75, 0.2)
			for r: float in [5.0, 9.0, 13.0]:
				Ink.path(p, Cave._ellipse(c, r * u, r * 0.6 * u, 22), 0.9 * u, true, Color("#b8c8ff"), 0.4, 0.4)
			Cave._cluster(p, c + Vector2(10, 2) * u, 0.45 * u, false)
			Decals._spot(p, c, 2.0 * u, Color("#e0e8ff"), 0.9)
		"stalagmites":
			for k in 4:
				var b := foot + Vector2(p.rng.randf_range(-20, 20), p.rng.randf_range(-6, 2)) * u
				_spike(p, b, p.rng.randf_range(5, 9) * u, p.rng.randf_range(24, 44) * u, STONE.lightened(0.05))
		"mushroom":
			Ink.glow(p, c.x, c.y - 6 * u, 26 * u, Color("#3affd8"), 0.35, false)
			for k in 6:
				var b := c + Vector2(p.rng.randf_range(-16, 16), p.rng.randf_range(-6, 8)) * u
				var hgt := p.rng.randf_range(6, 14) * u
				Decals._stick(p, b, b + Vector2(0, -hgt), 2.2 * u, Color("#a8b8a8"))
				var cap := b + Vector2(0, -hgt)
				p.fill_poly(Cave._ellipse(cap, p.rng.randf_range(4, 7) * u, 2.8 * u, 16), func(x: int, y: int) -> Color:
					return Color("#6af0dc").lerp(Color("#1e6a64"), clampf((y - cap.y) / (3.0 * u) * 0.5 + 0.4, 0.0, 1.0)))
				Ink.path(p, Cave._ellipse(cap, 6 * u, 2.8 * u, 16), 0.8 * u, true, Color("#0a2422"), 0.6, 0.3)
		"wolf_den":  # 털과 마른 풀을 깔아 다진 둔덕 + 갉아 먹은 뼈(입체 — V27)
			Solid.shadow(p, c + Vector2(0, 6) * u, 28 * u, 10 * u)
			Solid.lump(p, c + Vector2(0, 6) * u, 26 * u, 10 * u, 7 * u, Color("#4a4034"), 0.7, 0.0, u)
			for k in 50:  # 털·마른 풀
				var q := c + Vector2(p.rng.randf_range(-22, 22), p.rng.randf_range(-8, 12)) * u
				var d := Vector2.from_angle(p.rng.randf() * TAU) * p.rng.randf_range(3, 7) * u
				Ink.line(p, q, q + d, 0.9 * u, Color("#8a7a62") if p.rng.randf() < 0.6 else Color("#2a2420"), 0.8, 0.4)
			Decals._bones(p, c + Vector2(8, 0) * u, u * 1.3)
			Solid.lump(p, c + Vector2(-10, 6) * u, 4 * u, 2.5 * u, 4 * u, BONE, 0.2, 0.0, u)
		"gnome_trinkets":  # 진흙 위에 늘어놓은 반짝이는 잡동사니(입체 — V27)
			Solid.shadow(p, c + Vector2(0, 6) * u, 20 * u, 7 * u)
			for k in 9:
				var q := c + Vector2(p.rng.randf_range(-15, 15), p.rng.randf_range(-2, 10)) * u
				var col := [Color("#c9a24a"), Color("#8ab0c8"), Color("#a86a48"), Color("#d8d0c0")][k % 4] as Color
				Solid.lump(p, q, 3.0 * u, 2.0 * u, 3.0 * u, col, 0.2, 0.0, u * 0.7)
				Decals._spot(p, q - Vector2(1, 3) * u, 0.8 * u, Color("#fff8e0"), 0.9)
		"gnome_stash":  # 진흙 둔덕에 판 구멍 — 안에 반짝이는 것(입체 — V27)
			Solid.shadow(p, c + Vector2(0, 8) * u, 24 * u, 9 * u)
			Solid.lump(p, c + Vector2(0, 8) * u, 21 * u, 9 * u, 11 * u, Color("#4a3c2c"), 0.5, 0.0, u)
			Decals._blob(p, c + Vector2(2, 0) * u, 6 * u, Color("#0e0a08"), 0.95, 0.2)
			for k in 4:
				Decals._spot(p, c + Vector2(p.rng.randf_range(-3, 6), p.rng.randf_range(-2, 3)) * u, 1.1 * u, Color("#ffe080"), 1.0)
		"goblin_camp":
			Ink.glow(p, c.x, c.y - 8 * u, 34 * u, Color("#ff9a40"), 0.45, false)
			Decals._blob(p, c, 14 * u, Color("#2a2420"), 0.9, 0.2)
			for k in 3:  # 삼각 꼬챙이
				var a := c + Vector2((k - 1) * 14, 6) * u
				Decals._stick(p, a, c + Vector2(0, -26) * u, 2.4 * u, WOOD)
			_flame(p, c + Vector2(0, -2) * u, 10 * u)
			var rag := PackedVector2Array([c + Vector2(16, 6) * u, c + Vector2(30, 2) * u, c + Vector2(32, 14) * u, c + Vector2(18, 16) * u])
			p.fill_poly(rag, func(x: int, y: int) -> Color: return p.vary(Color("#5a4a30"), x, y, 0.12))
			Ink.path(p, rag, 1.0 * u, true, Ink.INK, 0.6, 0.8)
		"torch_stubs":  # 다 타고 버려진 횃불 토막(누운 막대 — 입체, V27)
			Solid.shadow(p, c + Vector2(0, 6) * u, 22 * u, 7 * u)
			for k in 4:
				var b := c + Vector2(p.rng.randf_range(-16, 16), p.rng.randf_range(-2, 10)) * u
				var d := Vector2.from_angle(p.rng.randf_range(-0.6, 0.6)) * p.rng.randf_range(8, 12) * u
				Solid.log(p, b - d, b + d, 2.4 * u, WOOD, Color("#1a1210"), u * 0.8)
		"old_skeleton":
			_shadow(p, c, 26 * u, 9 * u)
			_skeleton(p, c, u)
		"cairn":  # 쌓아 올린 돌탑(입체 — V27)
			Solid.shadow(p, foot, 18 * u, 6 * u)
			var y := foot.y
			for k in 6:
				var r := (13.0 - k * 1.7) * u
				Solid.lump(p, Vector2(foot.x + p.rng.randf_range(-2, 2) * u, y), r, r * 0.45, r * 0.85, STONE.lightened(k * 0.03), 0.35, 0.0, u)
				y -= r * 0.8
		"cache":  # 숨겨 둔 자루와 작은 나무 궤짝(입체 — V27)
			Solid.shadow(p, c + Vector2(0, 8) * u, 24 * u, 8 * u)
			Solid.block(p, c + Vector2(12, 10) * u, 18 * u, 10 * u, 11 * u, func(x: int, y: int) -> Color: return p.vary(WOOD.darkened(0.1), x, y, 0.1),
				func(x: int, y: int) -> Color: return p.vary(WOOD.lightened(0.2), x, y, 0.1), func(x: int, y: int) -> Color: return p.vary(WOOD.darkened(0.45), x, y, 0.1), u)
			Ink.line(p, c + Vector2(3, 5) * u, c + Vector2(21, 5) * u, 1.4 * u, METAL, 0.8, 0.3)
			Solid.lump(p, c + Vector2(-6, 10) * u, 11 * u, 6 * u, 15 * u, CLOTH.lightened(0.08), 0.25, -0.3, u)  # 자루
			Ink.line(p, c + Vector2(-10, -3) * u, c + Vector2(-3, -3) * u, 1.6 * u, LEATHER, 0.9, 0.4)
		"bear_trap", "bear_trap_shut":  # 곰덫 — 쇠 고리 받침 · 톱니 턱 둘(벌림 = 납작하게 누운 반원 둘, 닫힘 = 맞물려 선 턱) · 말뚝에 맨 사슬
			var shut := kind == "bear_trap_shut"
			var iron := Color("#5c5a56")
			var rust := Color("#7a4a2c")
			Solid.shadow(p, c + Vector2(0, 4) * u, 22 * u, 8 * u)
			for k in 7:  # 사슬: 받침에서 말뚝까지
				var q := c + Vector2(14 + k * 2.6, 2 - k * 1.2) * u
				Ink.path(p, Cave._ellipse(q, 1.7 * u, 1.1 * u, 10), 1.0 * u, true, iron.darkened(0.2), 0.9, 0.3)
			Solid.drum(p, c + Vector2(33, -6) * u, 2.0 * u, 7 * u, WOOD, WOOD.lightened(0.25), u * 0.6)  # 말뚝
			Ink.path(p, Cave._ellipse(c + Vector2(0, 2) * u, 9 * u, 4 * u, 22), 3.0 * u, true, Ink.INK, 0.9, 0.3)
			Ink.path(p, Cave._ellipse(c + Vector2(0, 2) * u, 9 * u, 4 * u, 22), 1.8 * u, true, iron.lightened(0.15), 0.95, 0.4)  # 받침 고리
			Solid.lump(p, c + Vector2(0, 2) * u, 4 * u, 2 * u, 2 * u, iron.lightened(0.1), 0.2, 0.0, u)  # 밟는 판
			if not shut:
				for side in [-1.0, 1.0]:  # 바닥에 벌려 눕힌 턱(타원 반쪽) + 안쪽을 보는 이빨
					var arc := PackedVector2Array()
					for k in 13:
						var a := PI * k / 12.0
						arc.append(c + Vector2(side * (6 + sin(a) * 13), -cos(a) * 9 + 2) * u)
					for k in range(1, 12, 2):  # 이빨(턱 안쪽 — 턱보다 먼저 칠해 밑동이 턱에 묻힌다)
						var a := PI * k / 12.0
						var b := c + Vector2(side * (6 + sin(a) * 13), -cos(a) * 9 + 2) * u
						var tip := b + Vector2(-side * sin(a) * 5.5, cos(a) * 3.8) * u
						var tri := PackedVector2Array([b + Vector2(0, -2.0) * u, b + Vector2(0, 2.0) * u, tip])
						p.fill_poly(tri, p.flat(Color("#d8d4ca"), 0.05))
						Ink.path(p, tri, 0.8 * u, true, Ink.INK, 0.8, 0.2)
					Ink.path(p, arc, 4.2 * u, false, Ink.INK, 0.95, 0.3)
					Ink.path(p, arc, 2.6 * u, false, iron.lightened(0.3), 1.0, 0.3)
					Ink.path(p, arc, 1.0 * u, false, rust, 0.6, 0.6)
			else:
				for side in [-1.0, 1.0]:  # 맞물려 선 턱(앞 · 뒤 반원이 위로 서서 닫힘)
					var arc := PackedVector2Array()
					for k in 13:
						var a := PI * k / 12.0
						arc.append(c + Vector2(-cos(a) * 13, side * 1.4 - sin(a) * 11 + 2) * u)
					Ink.path(p, arc, 4.2 * u, false, Ink.INK, 0.95, 0.3)
					Ink.path(p, arc, 2.6 * u, false, iron.lightened(0.3 if side > 0 else 0.05), 1.0, 0.3)
				for k in range(1, 12, 2):  # 맞물린 이빨
					var a := PI * k / 12.0
					var b := c + Vector2(-cos(a) * 13, -sin(a) * 11 + 2) * u
					Ink.line(p, b + Vector2(0, -2.6) * u, b + Vector2(0, 2.6) * u, 1.6 * u, Color("#d8d4ca"), 1.0, 0.2)
				Decals._blob(p, c + Vector2(-4, 6) * u, 5 * u, BLOOD, 0.5, 0.35)
		"goblin_snare":  # 박아 세운 말뚝 + 바닥에 깐 올가미 고리(입체 말뚝 — V27)
			Ink.path(p, Cave._ellipse(c + Vector2(4, 4) * u, 12 * u, 6 * u, 18), 1.6 * u, true, Color("#8a7450"), 0.9, 1.0)
			Solid.shadow(p, c + Vector2(-13, 6) * u, 5 * u, 2 * u)
			Solid.drum(p, c + Vector2(-13, 6) * u, 2.4 * u, 16 * u, WOOD, WOOD.lightened(0.25), u * 0.7)
			Ink.line(p, c + Vector2(-12, -8) * u, c + Vector2(-6, 2) * u, 1.3 * u, Color("#8a7450"), 0.9, 0.8)
		"wolf_kill":  # 반쯤 뜯긴 짐승 — 드러난 갈비뼈 · 털가죽 · 핏자국 · 뜯긴 다리(LD2)
			Solid.shadow(p, c + Vector2(0, 6) * u, 30 * u, 10 * u)
			Decals._blob(p, c + Vector2(-4, 6) * u, 20 * u, BLOOD, 0.55, 0.35)
			Solid.lump(p, c + Vector2(-8, 6) * u, 16 * u, 8 * u, 8 * u, Color("#5a4a3a"), 0.6, 0.0, u)  # 털가죽 몸통
			for k in 30:
				var q := c + Vector2(p.rng.randf_range(-22, 6), p.rng.randf_range(-2, 12)) * u
				Ink.line(p, q, q + Vector2.from_angle(p.rng.randf() * TAU) * 4 * u, 0.8 * u, Color("#7a6a52"), 0.7, 0.4)
			for k in 6:  # 갈비뼈 — 몸통 위로 휘어 솟는다
				var x := -2.0 + k * 3.2
				var b := c + Vector2(x, 6) * u
				Ink.path(p, PackedVector2Array([b, b + Vector2(1.5, -7) * u, b + Vector2(4, -10) * u]), 1.6 * u, false, BONE, 0.95, 0.3)
			Decals._blob(p, c + Vector2(8, 2) * u, 6 * u, Color("#6a1a14"), 0.85, 0.3)  # 뜯긴 살
			Decals._stick(p, c + Vector2(14, 10) * u, c + Vector2(28, 4) * u, 2.2 * u, BONE)  # 뜯겨 나온 다리뼈
			Solid.lump(p, c + Vector2(29, 4) * u, 3 * u, 2 * u, 3 * u, BONE, 0.2, 0.0, u * 0.7)
		"gnome_marker":  # 손바닥만 한 돌 셋을 포갠 길표지 — 맨 위 돌이 한쪽으로 길쭉, 둘레에 작은 손자국(LD2)
			Solid.shadow(p, foot, 12 * u, 4 * u)
			Solid.lump(p, foot, 9 * u, 4 * u, 5 * u, STONE.darkened(0.1), 0.35, 0.0, u)
			Solid.lump(p, foot - Vector2(0, 5) * u, 7 * u, 3.2 * u, 4.5 * u, STONE, 0.35, 0.0, u)
			var top := PackedVector2Array([foot + Vector2(-5, -10) * u, foot + Vector2(12, -12) * u, foot + Vector2(13, -9) * u, foot + Vector2(-4, -7) * u])
			p.fill_poly(top, func(x: int, y: int) -> Color: return p.vary(STONE.lightened(0.12), x, y, 0.08))
			Ink.path(p, top, 1.0 * u, true, Ink.INK, 0.8, 0.5)
			for k in 3:  # 작은 손자국(진흙)
				var h := foot + Vector2(-16 + k * 7, 4 + (k % 2) * 3) * u
				Decals._blob(p, h, 2.2 * u, Color("#3a2e22"), 0.8, 0.2)
				for f in 4:
					Decals._spot(p, h + Vector2(-2.2 + f * 1.5, -2.6) * u, 0.6 * u, Color("#3a2e22"), 0.85)
			Decals._spot(p, foot + Vector2(10, -11) * u, 0.9 * u, Color("#ffe8a0"), 0.9)  # 끝에 박은 반짝이(노움 표시)
		"goblin_lookout":  # 말뚝 넷 위 발판 + 봉화 바구니 — 서 있는 망루(멀리서 불빛이 보인다, LD2)
			Ink.glow(p, foot.x, foot.y - 58 * u, 38 * u, Color("#ff9a40"), 0.45, false)
			Solid.shadow(p, foot, 22 * u, 7 * u)
			for s: float in [-1.0, 1.0]:
				Decals._stick(p, foot + Vector2(s * 14, 0) * u, foot + Vector2(s * 9, -44) * u, 3.0 * u, WOOD)
				Decals._stick(p, foot + Vector2(s * 8, -4) * u, foot + Vector2(s * 6, -44) * u, 2.4 * u, WOOD.darkened(0.25))
			Ink.line(p, foot + Vector2(-13, -12) * u, foot + Vector2(11, -26) * u, 1.6 * u, WOOD.lightened(0.1), 0.9, 0.4)  # 엇댄 버팀목
			Ink.line(p, foot + Vector2(13, -12) * u, foot + Vector2(-11, -26) * u, 1.6 * u, WOOD.lightened(0.1), 0.9, 0.4)
			Solid.block(p, foot + Vector2(0, -42) * u, 26 * u, 10 * u, 4 * u, func(x: int, y: int) -> Color: return p.vary(WOOD, x, y, 0.12),
				func(x: int, y: int) -> Color: return p.vary(WOOD.lightened(0.18), x, y, 0.12), func(x: int, y: int) -> Color: return p.vary(WOOD.darkened(0.4), x, y, 0.1), u)
			Solid.drum(p, foot + Vector2(5, -50) * u, 4.5 * u, 5 * u, METAL.darkened(0.3), Color("#2a2018"), u * 0.7)  # 봉화 바구니
			_flame(p, foot + Vector2(5, -55) * u, 9 * u)
			var rag := PackedVector2Array([foot + Vector2(-11, -52) * u, foot + Vector2(-11, -66) * u, foot + Vector2(-2, -62) * u])
			Decals._stick(p, foot + Vector2(-11, -46) * u, foot + Vector2(-11, -68) * u, 1.4 * u, WOOD)
			p.fill_poly(rag, func(x: int, y: int) -> Color: return p.vary(Color("#6a2a1e"), x, y, 0.15))  # 찢긴 깃발
		"wolf_tracks":  # 젖은 바닥에 줄지어 찍힌 발자국(발바닥 + 발가락 넷 + 발톱 점, LD2)
			Decals._blob(p, c + Vector2(0, 2) * u, 26 * u, Color("#2e2620"), 0.35, 0.4)
			for k in 6:
				var q := c + Vector2(-24 + k * 9.5, (4 if k % 2 == 0 else -4)) * u
				Decals._blob(p, q, 2.4 * u, Color("#1e1814"), 0.85, 0.2)
				for f in 4:
					var toe := q + Vector2(3.6 - absf(f - 1.5) * 0.5, 0).rotated((f - 1.5) * 0.55) * u  # 가는 쪽(+x) 앞에 발가락
					Decals._spot(p, toe, 1.0 * u, Color("#1e1814"), 0.9)
					Decals._spot(p, toe + (toe - q).normalized() * 1.6 * u, 0.45 * u, Color("#0e0a08"), 0.9)
		"wet_slope":
			for k in 6:
				var a := c + Vector2(p.rng.randf_range(-24, 24), p.rng.randf_range(-14, 10)) * u
				Ink.line(p, a, a + Vector2(p.rng.randf_range(-4, 4), p.rng.randf_range(8, 14)) * u, 2.2 * u, Color("#a8c0d8"), 0.35, 0.6)
			Decals._blob(p, c, 24 * u, Color("#1a2232"), 0.4, 0.2)
		"portal", "rift_portal":
			var col := Color("#c8a0ff") if kind == "portal" else Color("#ff6a6a")
			Ink.glow(p, c.x, c.y, 34 * u, col, 0.5, false, 0.6)
			for r: float in [26.0, 20.0]:
				Ink.path(p, Cave._ellipse(c, r * u, r * 0.6 * u, 40), 1.8 * u, true, col.darkened(0.2), 0.85, 0.5)
			for k in 10:  # 고리 사이 문자
				var a := TAU * k / 10.0
				var q := c + Vector2(cos(a) * 23, sin(a) * 13.8) * u
				Ink.line(p, q - Vector2(1.5, 2) * u, q + Vector2(1.5, 2) * u, 1.2 * u, col.lightened(0.3), 0.9, 0.3)
				Ink.line(p, q + Vector2(-2, 0.5) * u, q + Vector2(1, 0.5) * u, 1.0 * u, col.lightened(0.3), 0.8, 0.3)
			Decals._blob(p, c, 12 * u, col.darkened(0.6), 0.5, 0.15)
		"rift_gate":  # 균열 탈출 포탈: 세로로 선 차원문 — 차원광장 포탈처럼 돌 고리 안에 보랏빛 소용돌이(사용자 2026-10-26)
			_gate(p, foot, u)
	return p


## 세로로 선 돌 고리(받침 돌 둘) + 안쪽 보랏빛 소용돌이(가운데 밝고 가장자리 진한 띠) + 테두리 빛·바닥 빛.
static func _gate(p: Paint, foot: Vector2, u: float) -> void:
	var violet := Color("#a070ff")
	var rx := 17.0 * u
	var ry := 27.0 * u
	var gc := foot - Vector2(0, ry + 7.0 * u)
	Ink.glow(p, foot.x, foot.y - 2 * u, 34 * u, violet, 0.45, false, 0.35)  # 바닥에 번진 빛
	_shadow(p, foot, 26 * u, 6 * u)
	var deep := Color("#170828")
	var mid := Color("#8a58e8")
	var core := Color("#efe2ff")
	p.fill_poly(Cave._ellipse(gc, rx, ry, 56), func(x: int, y: int) -> Color:
		var n := Vector2((x - gc.x) / rx, (y - gc.y) / ry)
		var d := minf(1.0, n.length())
		var band := pow(0.5 + 0.5 * sin(atan2(n.y, n.x) * 2.0 - d * 9.0 + p.nz("mid", x, y) * 1.2), 1.6)
		var c := deep.lerp(mid, band * (1.0 - d * 0.3))
		c = c.lerp(core, smoothstep(0.5, 0.0, d) * 0.9)
		c = c.lerp(Color("#c8a8ff"), smoothstep(0.82, 1.0, d) * 0.7)  # 안쪽 테가 밝다
		return c)
	for k in 18:  # 돌 고리(머릿돌이 위)
		var a := TAU * k / 18.0 - PI * 0.5
		var q := gc + Vector2(cos(a) * (rx + 4.5 * u), sin(a) * (ry + 4.5 * u))
		Cave._stone(p, q, 5.2 * u, 4.6 * u, STONE.darkened(0.25 if k != 0 else 0.1).lightened(p.rng.randf_range(-0.05, 0.05)))
	for s: float in [-1.0, 1.0]:  # 받침 돌
		Cave._stone(p, foot + Vector2(s * 13.0, -4.0) * u, 9.0 * u, 6.0 * u, STONE.darkened(0.35))
	Ink.path(p, Cave._ellipse(gc, rx, ry, 56), 1.6 * u, true, Color("#e0ccff"), 0.85, 0.3)
	Ink.glow(p, gc.x, gc.y, rx * 1.9, violet, 0.3, false, ry / rx)  # 고리 둘레로 번지는 빛


static func _shadow(p: Paint, c: Vector2, rx: float, ry: float) -> void:
	p.fill_poly(Cave._ellipse(c + Vector2(2, 3), rx, ry, 24), func(_x: int, _y: int) -> Color: return Color(0.04, 0.03, 0.04, 0.4))


## 쓰러진 탐험가: 탐험 맵 몸 그림 시트(paint_actors.gd — 옆모습 줄의 걸음 칸 col, 다리를 벌린 자세)를 각도 angle(라디안)로 눕혀
## 길이 length(px)로 c에 놓는다. 핏기 없게 어둡고 탁하게. 시트가 없으면 아무것도 그리지 않는다(맵 몸 그림을 먼저 그린다).
static func _lying_body(p: Paint, c: Vector2, length: float, angle: float, sheet_path: String, col: int) -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(sheet_path))
	if img == null or img.is_empty():
		return
	img.convert(Image.FORMAT_RGBA8)
	var cw := img.get_width() / 5
	var ch := img.get_height() / 4
	var src := img.get_region(Rect2i(col * cw, 2 * ch, cw, ch))  # 줄 2 = 오른쪽을 본 옆모습
	var used := src.get_used_rect()
	if used.size.y <= 0:
		return
	var k := length / float(used.size.y)  # 키 → 누운 길이
	var mid := Vector2(used.position) + Vector2(used.size) * 0.5
	var rot := Transform2D(angle, Vector2.ZERO)
	var inv := rot.affine_inverse()
	var reach := length * 0.6
	for y in range(int(c.y - reach), int(c.y + reach) + 1):
		for x in range(int(c.x - reach), int(c.x + reach) + 1):
			var s: Vector2 = inv * (Vector2(x, y) - c) / k + mid
			var sx := int(s.x)
			var sy := int(s.y)
			if sx < 0 or sy < 0 or sx >= cw or sy >= ch:
				continue
			var px := src.get_pixel(sx, sy)
			if px.a < 0.05:
				continue
			var g := px.r * 0.3 + px.g * 0.59 + px.b * 0.11
			var dead := Color(lerpf(px.r, g, 0.45), lerpf(px.g, g, 0.5), lerpf(px.b, g, 0.4)) * 0.62  # 핏기 없이 탁하게
			p.blend(x, y, Color(dead.r, dead.g, dead.b), px.a)


static func _skeleton(p: Paint, c: Vector2, u: float) -> void:
	Decals._stick(p, c + Vector2(-16, 0) * u, c + Vector2(10, 0) * u, 2.6 * u, BONE)  # 척추
	for k in 4:
		var x := -6.0 + k * 4.5
		for sgn: float in [-1.0, 1.0]:
			Ink.line(p, c + Vector2(x, 0) * u, c + Vector2(x + 2, sgn * 7) * u, 1.6 * u, BONE.darkened(0.08), 0.95, 0.3)
	Cave._stone(p, c + Vector2(17, 0) * u, 6 * u, 5.5 * u, BONE)  # 두개골
	Cave._dot(p, c + Vector2(17, -1.6) * u, 1.4 * u, Color("#1a1412"), 0.95)
	Cave._dot(p, c + Vector2(17, 1.8) * u, 1.4 * u, Color("#1a1412"), 0.95)
	for sgn: float in [-1.0, 1.0]:
		Decals._stick(p, c + Vector2(-16, sgn * 2) * u, c + Vector2(-32, sgn * 8) * u, 2.2 * u, BONE)  # 다리
		Decals._stick(p, c + Vector2(4, sgn * 5) * u, c + Vector2(-2, sgn * 18) * u, 1.8 * u, BONE)  # 팔


## 석순: 밑동이 넓고 끝이 뾰족한 원뿔(왼쪽 위 빛 — 왼쪽 면 밝게).
static func _spike(p: Paint, base: Vector2, r: float, hgt: float, col: Color) -> void:
	var tip := base + Vector2(r * 0.15, -hgt)
	var left := PackedVector2Array([base + Vector2(-r, 0), tip, base + Vector2(0, r * 0.35)])
	var right := PackedVector2Array([base + Vector2(0, r * 0.35), tip, base + Vector2(r, 0)])
	_shadow(p, base, r * 1.3, r * 0.45)
	p.fill_poly(left, func(x: int, y: int) -> Color: return p.vary(col.lightened(0.15), x, y, 0.08))
	p.fill_poly(right, func(x: int, y: int) -> Color: return p.vary(col.darkened(0.3), x, y, 0.08))
	Ink.path(p, PackedVector2Array([base + Vector2(-r, 0), tip, base + Vector2(r, 0)]), 1.2, false, Ink.INK, 0.8, 0.5)


static func _flame(p: Paint, c: Vector2, size: float) -> void:
	for k in 3:
		var s := size * (1.0 - k * 0.3)
		var col := [Color("#c83a12"), Color("#ff8a2a"), Color("#ffe0a0")][k] as Color
		var poly := PackedVector2Array([c + Vector2(-s * 0.6, 0), c + Vector2(-s * 0.2, -s * 0.9), c + Vector2(0, -s * 1.5),
			c + Vector2(s * 0.3, -s * 0.8), c + Vector2(s * 0.6, 0), c + Vector2(0, s * 0.25)])
		p.fill_poly(poly, func(_x: int, _y: int) -> Color: return col)
