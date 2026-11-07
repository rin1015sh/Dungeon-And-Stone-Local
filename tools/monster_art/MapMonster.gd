extends RefCounted
## 탐험 맵 몬스터 걷기 그림(앞·옆·뒤 × 걸음): 전투 그림과 같은 3D 덩어리 도구로 몸을 돌려 그린다(tools/paint_actors.gd가 줄여 시트로).
## 여기 설계가 있는 몬스터만 시트를 그리고, 없는 몬스터는 예전처럼 전투 그림을 줄인 한 장(MonsterView가 흔든다).
## dir: "down"(앞) · "left"(왼쪽을 본 옆 — 오른쪽은 뒤집는다) · "up"(뒤). phase: 걸음 +1 / 0(섬) / -1.
## 종류(kind): figure = 사람형(탐험가와 같은 3D 몸 Back·Party — 큰 머리 맵 비율) · beast = 네발짐승(Beast — 앞 방향 face)
##            crawler = 기는 것(Party._crawler — 돌림 turn) · mound = 흙더미(여기서 — 얼굴·뿌리 팔이 돌림을 따른다)

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Clay := preload("res://tools/monster_art/Clay.gd")
const Render := preload("res://tools/monster_art/Render.gd")
const Finish := preload("res://tools/monster_art/Finish.gd")
const Back := preload("res://tools/monster_art/Back.gd")
const Beast := preload("res://tools/monster_art/Beast.gd")
const Party := preload("res://tools/monster_art/Party.gd")
const Specs := preload("res://tools/monster_art/Specs.gd")
const Things := preload("res://tools/monster_art/Things.gd")

const PITCH := 0.3  ## 짐승·기는 것·흙더미를 위에서 내려다보는 정도
const SIDE_FACE := 0.25  ## 옆모습을 보는 사람 쪽으로 살짝 돌리는 정도(라디안 — 완전한 옆보다 3/4에 가깝게)


static func C(hex: String) -> Color:
	return Color(hex)


## 몬스터 맵 설계. kind · size(사람 키 대비 — 없으면 데이터 size) · spec(그리는 도구 설계) · map(figure: 탐험가 맵 값을 덮어쓴다).
## 사람형은 전투 설계(Figure 형식)를 3D 몸(Back) 설계로 옮겨(_from_figure) 쓰고, tweak로 고친다.
## 보스·중간보스(rank guardian·variant_guardian·midboss)는 걷지 않는다 — 기다리는 자세 한 장(BOSSES, idle_of). 계층군주는 전투 그림을 줄인 한 장.
static func spec_of(id: String) -> Dictionary:
	match id:
		"goblin":  # 전투 그림: 초록 살갗·굽은 등·긴 귀·노란 눈·허리 천·단검
			return {"kind": "figure", "size": 0.75, "spec": {"height": Party.REF_H, "build": "thin", "sh": 0.1, "skin": C("#7a9258"), "mottle": C("#4a5a30"),
				"hair": "none", "ears": "long", "eye_glow": C("#e8d060"),
				"kit": {"loin": C("#4a3a2a"), "belt": C("#3a2a1e"), "weapon": "dagger", "weapon_c": C("#7a7468")}},
				"map": {"hunch": 0.38, "knee": 0.16, "head": 2.3, "legs": 0.72, "wide": 1.0, "bulk": 1.05, "stance": 0.07}}
		"skull_rat":  # 데이터 크기(0.4)로는 맵에서 점처럼 작다
			return {"kind": "beast", "size": 0.9, "spec": Specs.More.spec_of(id)}
		"blade_wolf", "chimera_wolf", "frost_wolf", "sabertooth", "owlbear", "wall_mole", "mole_queen", "moon_rock_bear", "bulkar":
			return {"kind": "beast", "spec": Specs.More.spec_of(id)}
		"ghoul":
			return {"kind": "crawler", "size": 1.0, "spec": {"height": 420, "color": C("#8a947c"), "blood": 0.5, "eyes": C("#e0d8a0"), "elbow_h": 0.32, "elbow_w": 0.2, "reach": 0.3}}
		"ghoul_lord":
			return {"kind": "crawler", "spec": {"height": 420, "color": C("#5a6a48"), "bulk": 1.25, "blood": 1.0, "crown": C("#9a7a32"), "horns": C("#2a2820"), "eyes": C("#ff6030"), "elbow_h": 0.34, "elbow_w": 0.22, "reach": 0.3}}
		"gnome":
			return {"kind": "mound", "size": 0.8, "spec": Specs.More.spec_of("gnome")}
		"slime", "mineral_slime", "wormstone", "guardian_eye", "sandworm", "deathworm":
			return {"kind": "blob", "spec": Specs.More.spec_of(id)}
	if FIGURES.has(id):
		return _from_figure(id)
	return {}


## 사람형 몬스터(전투 설계를 옮긴다)와 손볼 값(tweak — spec·map에 덮어쓴다).
const FIGURES := {
	"deadman": {}, "soldier_deadman": {}, "deadman_commander": {}, "skeleton_archer": {}, "skeleton_mage": {},
	"deathfiend": {"map": {"head": 1.9}}, "banshee": {}, "gargoyle_statue": {"map": {"head": 2.0}}, "bone_knight": {}, "skeleton": {}, "skeleton_warrior": {}, "dullahan": {}, "death_knight": {"map": {"head": 1.8}},
	"yeti": {"spec": {"hair": "ragged", "hair_c": Color("#d4dadf")}, "map": {"head": 1.8, "bulk": 1.25, "wide": 1.1}},
	"ice_golem": {"map": {"head": 1.6, "bulk": 1.3, "wide": 1.15}}, "ice_orc_shaman": {}, "ice_orc_warrior": {},
	"goblin_miner": {}, "hobgoblin_miner": {}, "hobgoblin": {}, "kobold": {}, "kobold_shield": {}, "kobold_slinger": {}, "stone_golem": {"map": {"head": 1.6, "bulk": 1.3, "wide": 1.15}}, "monolith_soldier": {}, "sandman": {}, "werewolf": {"spec": {"hair": "ragged", "hair_c": Color("#5a5450")}, "map": {"head": 1.8, "bulk": 1.15}}, "copper_golem": {"spec": {"skin": Color("#9a6634")}, "map": {"head": 1.6, "bulk": 1.3, "wide": 1.15}},
	"mummy": {}, "buried_one": {}, "iron_lizardman": {}, "iron_cavalry": {}, "riddle_gatekeeper": {"map": {"head": 1.8}},
}
## 보스·중간보스가 방 가운데서 기다리는 자세(BackPose rest — 플레이어가 방에 들어오면 바로 전투). 앞모습 한 장.
## 고른 까닭: 블라터(저주받은 기사) = 무릎 꿇고 칼을 짚은 채 · 캠보르미어(공작) = 왕좌 · 타룬바스(폭군 — 털 라이칸스로프) = 얼음몽둥이를 짚고 선 채
## 키르뒤(짐승) = 웅크림 · 킹 슬라임 = 퍼져 있음 · 일디움(철인) = 석상처럼 선 채 · 시체골렘 = 버려진 듯 주저앉음
## 카툼바(설원의 군주) = 바위에 걸터앉음(몽둥이 안 든 팔은 늘어뜨림 — 사용자 2026-10-18) · 고블린 폭탄병 = 책상다리로 폭탄 만지작.
const BOSSES := {
	"blater": {"spec": {"rest": "kneel"}, "map": {"head": 1.8}},
	"kambormir": {"size": 1.5, "spec": {"rest": "throne", "seat_c": Color("#3e3438")}, "map": {"head": 2.0}},
	"tarunbas": {"spec": {"rest": "stand", "plant": true, "hair": "ragged", "hair_c": Color("#c8c8c0")}, "map": {"head": 1.7, "bulk": 1.25, "wide": 1.1}},
	"kirdui": {"spec": {"rest": "squat"}, "map": {"head": 1.6, "bulk": 1.2}},
	"ildium": {"spec": {"rest": "stand"}, "map": {"head": 1.6, "bulk": 1.2}},
	"corpse_golem": {"spec": {"rest": "floor", "legs_out": true}, "map": {"head": 1.6, "bulk": 1.2}},
	"katumba": {"spec": {"rest": "seat", "free_hang": true, "seat_c": Color("#8a96a2"), "hair": "ragged", "hair_c": Color("#e0e6ea")}, "map": {"head": 1.7, "bulk": 1.25, "wide": 1.1}},
	"goblin_bomber": {"spec": {"rest": "floor"}, "map": {"head": 2.0}},
}
const BUILD := {"thin": "thin", "normal": "normal", "muscular": "muscular", "brute": "brute", "bones": "thin", "fat": "brute"}
const HAIR := {"ragged": "ragged", "long": "long", "short": "short", "topknot": "ragged"}


static func _combat(id: String) -> Dictionary:
	var f := Specs.spec_of(id)
	return f if not f.is_empty() else Specs.More.spec_of(id)


## 전투 설계(Figure 형식: pose·body·head·kit·extras) → 3D 몸 설계(Back·Party 형식) + 맵 값.
static func _from_figure(id: String) -> Dictionary:
	var f := _combat(id)
	var body: Dictionary = f.get("body", {})
	var head: Dictionary = f.get("head", {})
	var pose: Dictionary = f.get("pose", {})
	var kit: Dictionary = (f.get("kit", {}) as Dictionary).duplicate()
	var build := str(body.get("build", "normal"))
	var sp := {"height": Party.REF_H, "build": BUILD.get(build, "normal"), "bulk": {"bones": 0.72, "fat": 1.15}.get(build, float(body.get("bulk", 1.0))),
		"sh": float(pose.get("sh", 0.12)), "skin": f.get("skin", C("#a09080")), "hair": HAIR.get(str(f.get("hair", "none")), "none"),
		"eye_glow": f.get("eyes", C("#d8d0b0"))}
	for k: String in ["mottle", "mottle_amt", "shade", "skin_kind", "hair_c", "blood", "grime", "fade", "desat", "fur_len"]:
		if f.has(k):
			sp[k] = f[k]
	match str(head.get("type", "human")):
		"goblin", "orc":
			sp["ears"] = "long"
		"block":
			sp["block_head"] = true
			sp["hair"] = "none"
		"skull":
			sp["hair"] = "none"
	if head.has("crown"):
		sp["crown"] = head["crown"]
	if head.get("horns", false) and f.has("horn"):
		sp["horns"] = f["horn"]
		sp["horn_len"] = float(head.get("horn_len", 0.7))
	for k: String in ["helm", "cap"]:
		if head.has(k):
			kit["helm"] = head[k]
			sp["hair"] = "none"  # 머리카락이 투구를 덮었다
			if head.has("plume"):
				kit["plume"] = head["plume"]
	var ex: Dictionary = f.get("extras", {})
	for k: String in ["lumps", "crystals"]:
		if ex.has(k):
			sp[k] = ex[k]
	if ex.has("wings"):
		sp["wings"] = ex["wings"]
		sp["wing_span"] = float(ex.get("wing_span", 1.0))
	if ex.has("tail"):
		sp["tail"] = ex["tail"]
	if kit.has("robe"):
		sp["robe"] = kit["robe"]
		kit.erase("robe")
	if kit.has("fur"):
		kit["pelt"] = kit["fur"]
		kit.erase("fur")
	sp["kit"] = kit
	var big := ["brute", "muscular"].has(str(sp["build"]))
	var mp := {"hunch": clampf(float(pose.get("hunch", 0.0)) * 0.8, 0.0, 0.45), "knee": float(pose.get("knee", 0.1)) * 0.5,
		"head": 2.0 if big else 2.3, "legs": 0.74, "wide": 1.0, "bulk": 1.05, "stance": 0.07}
	var tw: Dictionary = FIGURES.get(id, BOSSES.get(id, {}))
	sp.merge(tw.get("spec", {}), true)
	mp.merge(tw.get("map", {}), true)
	return {"kind": "figure", "spec": sp, "map": mp}


## 보스가 기다리는 자세 설계(없으면 빈 것). king_slime은 덩어리(blob).
static func idle_of(id: String) -> Dictionary:
	if id == "king_slime":
		return {"kind": "blob", "spec": Specs.More.spec_of(id)}
	if not BOSSES.has(id):
		return {}
	var m := _from_figure(id)
	if BOSSES[id].has("size"):
		m["size"] = BOSSES[id]["size"]
	return m


static func has(id: String) -> bool:
	return not spec_of(id).is_empty()


## 짐승·기는 것·흙더미 한 장(크게 — 줄이는 것은 paint_actors). height = 그릴 크기(px). 돌려주는 그림의 아래 가운데 근처가 발.
static func paint(id: String, dir: String, phase: float, height: float, seed_value: int) -> Image:
	var m := spec_of(id)
	if m.is_empty():
		m = idle_of(id)
	var sp: Dictionary = (m["spec"] as Dictionary).duplicate(true)
	sp["height"] = height
	sp["pitch"] = PITCH
	sp["walk"] = phase
	match str(m["kind"]):
		"beast":
			sp["face"] = {"down": 0.0, "left": -PI * 0.5 + SIDE_FACE, "up": PI}[dir]
			sp["canvas_h"] = 1.1
			return Beast.paint(sp, seed_value).to_image()
		"crawler":
			sp["turn"] = {"down": PI, "left": -PI * 0.5 - SIDE_FACE, "up": 0.0}[dir]
			sp["canvas_h"] = 1.0
			return Party._crawler(sp, seed_value).to_image()
		"mound":
			return _mound(sp, {"down": PI, "left": -PI * 0.5 - SIDE_FACE, "up": 0.0}[dir], phase, seed_value).to_image()
		"blob":  # 방향이 없는 덩어리(슬라임·웜스톤·수호자의 눈): 같은 그림을 걸음마다 눌렀다 폈다
			sp.erase("pitch")
			sp.erase("walk")
			var img := Things.paint(str(sp["kind"]), sp, seed_value).to_image()
			if phase != 0.0:
				var w := img.get_width()
				var h := img.get_height()
				var sq := img.duplicate() as Image
				sq.resize(int(w * 1.06), int(h * 0.92), Image.INTERPOLATE_LANCZOS)
				img = Image.create_empty(sq.get_width(), h, false, Image.FORMAT_RGBA8)
				img.blit_rect(sq, Rect2i(Vector2i.ZERO, sq.get_size()), Vector2i(0, h - sq.get_height()))
			return img
	return Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)


## 흙더미(노움): 이끼 덮인 흙·돌 둔덕 + 앞쪽의 눈구멍 둘(빛) + 양옆 뿌리 팔. 걸으면 좌우로 기우뚱하며 뿌리 팔을 번갈아 내딛는다.
static func _mound(sp: Dictionary, turn: float, walk: float, seed_value: int) -> Paint:
	var H := float(sp["height"])
	var w := int(H * 1.1)
	var h := int(H * 0.9)
	var p := Paint.new(w, h, seed_value)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cl := Clay.new(w, h)
	var pr := Back.proj(Vector2(w * 0.5, h - H * 0.06), H, turn, PITCH)
	var col: Color = sp.get("color", C("#7a6a52"))
	var earth := cl.mat(col, "stone", {"mottle": col.darkened(0.3), "mottle_amt": 0.5})
	var g := cl.group()
	cl.tag = "mound"
	var bob := absf(walk) * 0.012
	var c := Vector3(walk * 0.015, -0.2 - bob, 0.0)
	Back.ell(cl, pr, g, c, 0.3, 0.22, 0.27, earth, 0.04)
	for k in 16:  # 돌·흙 덩이(위·옆을 덮는다)
		var a := rng.randf_range(0.0, TAU)
		var la := rng.randf_range(0.15, 1.2)
		var q := c + Vector3(cos(a) * cos(la) * 0.27, -sin(la) * 0.2, sin(a) * cos(la) * 0.24)
		Back.ell(cl, pr, g, q, rng.randf_range(0.03, 0.06), rng.randf_range(0.025, 0.05), rng.randf_range(0.03, 0.05), earth, 0.01)
	if sp.has("moss"):  # 이끼(위쪽 반)
		var mm := cl.mat(sp["moss"], "fur")
		for k in 22:
			var a := rng.randf_range(0.0, TAU)
			var la := rng.randf_range(0.55, 1.4)
			var q := c + Vector3(cos(a) * cos(la) * 0.28, -sin(la) * 0.21 - 0.01, sin(a) * cos(la) * 0.25)
			Back.ell(cl, pr, g, q, 0.05, 0.025, 0.05, mm, 0.01)
	var F := Vector3(0, 0, -1)  # 노움의 앞(몸 좌표 — 돌림 π면 보는 사람 쪽)
	var eyes: Array = []
	for s: float in [-1.0, 1.0]:  # 눈구멍
		var e := c + Vector3(s * 0.065, 0.0, -0.24)
		if Back.facing(pr, Vector3(s * 0.4, 0, -1)) > 0.15:
			var q := Back.P2(pr, e)
			cl.carve(g, q, 0.026 * H, 0.02 * H, 0.03 * H)
			eyes.append(q)
	for s: float in [-1.0, 1.0]:  # 뿌리 팔(몸 옆에서 땅으로) — 걸음마다 번갈아 앞으로
		var ga := cl.group()
		var k := walk * s
		var a := c + Vector3(s * 0.22, 0.1, -0.06)  # 몸 아래쪽 옆에서 짧게 — 땅을 짚는 굵은 뿌리
		var tip := a + Vector3(s * 0.07, 0.09 - maxf(0.0, k) * 0.03, -0.04 - k * 0.06)
		Back.chain(cl, pr, ga, [a, a.lerp(tip, 0.5) + Vector3(s * 0.02, 0.0, 0.0), tip], [0.045, 0.035, 0.02], earth, 0.01)
		for f in 3:
			Back.cap(cl, pr, ga, tip, tip + Vector3(s * (f - 1) * 0.025, 0.04, -0.02 + (f - 1) * 0.015), 0.008, 0.002, earth, 0.004)
	Render.render(cl, p, H)
	var ec: Color = sp.get("eyes", C("#ffcc60"))
	for e: Vector2 in eyes:
		Ink.glow(p, e.x, e.y, H * 0.06, ec, float(sp.get("glow", 1.0)) * 0.7, false)
		for yy in range(int(e.y - H * 0.008), int(e.y + H * 0.008) + 1):
			for xx in range(int(e.x - H * 0.01), int(e.x + H * 0.01) + 1):
				p.blend(xx, yy, ec.lightened(0.35), 0.95)
	Finish.done(p, sp, {"chest": Back.P(pr, c), "waist": Back.P(pr, c)}, H)
	return p
