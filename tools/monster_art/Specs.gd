extends RefCounted
## 몬스터 id → 그림 설계(52종). kind: figure(사람형 — Figure) · beast(네발짐승 — Beast) · crawler·worm·slime·mound·eye·maggot(Things)
## · lord(계층군주 드레드피어 전용 — Lord).
## 각 키의 뜻은 해당 파일 머리말(Figure·Rig·Anatomy·Face·Kit·Arms·Extras·Beast·Things). 원작 묘사가 없는 몬스터는
## 이름·데이터 색·크기에서 모습을 정했다(ASSUMPTIONS UI8). 바꾸려면 여기 한 항목을 고치고 --only=<id>로 다시 그린다.

const Figure := preload("res://tools/monster_art/Figure.gd")
const Beast := preload("res://tools/monster_art/Beast.gd")
const Things := preload("res://tools/monster_art/Things.gd")
const Lord := preload("res://tools/monster_art/Lord.gd")
const More := preload("res://tools/monster_art/Specs2.gd")


static func paint(id: String, _def: Dictionary, seed_value: int) -> Variant:
	var sp := spec_of(id)
	if sp.is_empty():
		sp = More.spec_of(id)
	if sp.is_empty():
		return null
	var kind := str(sp.get("kind", "figure"))
	match kind:
		"figure":
			return Figure.paint(sp, seed_value)
		"beast":
			return Beast.paint(sp, seed_value)
		"lord":
			return Lord.paint(sp, seed_value)
	return Things.paint(kind, sp, seed_value)


static func C(hex: String) -> Color:
	return Color(hex)


## 화면 키의 기준이 되는 "몸 높이"(px): 사람형 = 발~정수리(설계 키, 들어 올린 무기·뿔 제외).
## 나머지는 잘라낸 그림 높이 crop_h를 사람 키에 견준 비율로 나눈다(네발짐승 0.8 · 기는 것 0.7 · 덩어리 0.78 — 예전 도형과 같은 비율).
static func body_height(id: String, crop_h: float) -> float:
	var sp := spec_of(id)
	if sp.is_empty():
		sp = More.spec_of(id)
	match str(sp.get("kind", "figure")):
		"figure":
			return minf(crop_h, float(sp.get("height", 560)))
		"beast":
			return crop_h / 0.8
		"crawler":
			return crop_h / 0.7
		"worm":
			return crop_h
		"lord":  # 머리 위로 솟은 뿔·날개 끝은 키에서 뺀다 — 전투 무대에서 위 안내 줄 뒤로 넘쳐 화면을 꽉 채운다
			return crop_h * 0.8
	return crop_h / 0.78


## 시체·해골·고블린·오크·설원 — 사람형 1부(나머지는 Specs2).
static func spec_of(id: String) -> Dictionary:
	match id:
		"deadman":
			return {"skin": C("#bdb59a"), "mottle": C("#6a4a44"), "mottle_amt": 0.55, "blood": 0.9, "eyes": C("#e0dcc0"), "hair": "ragged", "hair_c": C("#241c16"),
				"pose": {"hunch": 0.35, "knee": 0.25, "arm_l": "hang", "arm_r": "wide", "tilt": 0.15, "sh": 0.11, "stance": 0.12, "weight": 0.6, "knees_out": -0.3},
				"body": {"build": "thin", "hands": "claw", "claws": 0.6}, "head": {"type": "gaunt", "mouth": "scream"}, "kit": {"loin": C("#4e4234")}}
		"soldier_deadman":
			return {"skin": C("#a8a88c"), "mottle": C("#4e5040"), "mottle_amt": 0.5, "blood": 0.5, "eyes": C("#d8dcc0"), "hair": "ragged", "hair_c": C("#2a241c"),
				"pose": {"hunch": 0.25, "knee": 0.2, "arm_l": "hang", "arm_r": "claw", "tilt": -0.1, "sh": 0.115, "weight": -0.4},
				"body": {"build": "thin", "hands": "claw", "claws": 0.3, "feet": "bare"}, "head": {"type": "gaunt", "mouth": "open", "helm": C("#5a5446"), "visor": false},
				"kit": {"shirt": C("#4a4a3a"), "torn": 0.7, "belt": C("#2a2016"), "boots": C("#2e261e"), "weapon": "spear", "weapon_c": C("#6a5a48"), "shield": C("#5a4c3a")}}
		"deadman_commander":
			return {"height": 600, "skin": C("#a09c84"), "mottle": C("#4a4a3a"), "mottle_amt": 0.5, "blood": 0.35, "eyes": C("#b8e8c8"), "glow": 0.7, "hair": "ragged", "hair_c": C("#1e1a16"),
				"pose": {"hunch": 0.15, "arm_l": "hang", "arm_r": "hang", "sh": 0.12, "weight": 0.5, "tilt": 0.08},
				"body": {"build": "thin", "hands": "claw", "claws": 0.3}, "head": {"type": "gaunt", "mouth": "shut", "angry": 0.9},
				"kit": {"armor": C("#4e4c46"), "plates": ["chest", "shoulders", "legs"], "cape": C("#3a1c1a"), "boots": C("#2a221c"), "weapon": "sword", "weapon_c": C("#7a766a"), "belt": C("#2a1e16")}}
		"buried_one":
			return {"skin": C("#8a7c62"), "mottle": C("#4a3c28"), "mottle_amt": 0.75, "blood": 0.15, "eyes": C("#d8c890"), "hair": "ragged", "hair_c": C("#3a3024"), "grime": 0.7,
				"pose": {"hunch": 0.6, "knee": 0.45, "arm_l": "claw", "arm_r": "wide", "tilt": 0.25, "sh": 0.11, "stance": 0.12, "weight": -0.3},
				"body": {"build": "thin", "hands": "claw", "claws": 0.7}, "head": {"type": "gaunt", "mouth": "open"},
				"kit": {"wraps": C("#5a4c38"), "wraps_amt": 0.35, "loin": C("#3a3024")}}
		"mummy":
			return {"skin": C("#6a5a44"), "eyes": C("#ffb040"), "glow": 0.9, "pose": {"hunch": 0.2, "arm_l": "claw", "arm_r": "claw", "sh": 0.11, "weight": 0.3},
				"body": {"build": "thin", "hands": "claw"}, "head": {"type": "gaunt", "mouth": "shut", "eye_style": "black"},
				"kit": {"wraps": C("#c8b890"), "wraps_amt": 0.92, "wraps_head": true, "loin": C("#8a7a5a")}}
		"corpse_golem":
			return {"height": 640, "width": 1.0, "skin": C("#b08a78"), "shade": C("#5a2e30"), "mottle": C("#6a3a50"), "mottle_amt": 0.7, "blood": 1.1, "eyes": C("#e0d0a0"),
				"pose": {"hunch": 0.55, "knee": 0.35, "arm_l": "hang", "arm_r": "hang", "sh": 0.16, "hip": 0.085, "neck": 0.6, "head": 0.8, "weight": -0.4, "arms": 1.08},
				"body": {"build": "fat", "bulk": 1.15, "hands": "claw"}, "head": {"type": "gaunt", "mouth": "open"}, "hair": "ragged", "hair_c": C("#2a201a"),
				"extras": {"stitches": true, "lumps": 6}, "kit": {"weapon": "cleaver", "weapon_c": C("#8a8278"), "loin": C("#3a2a22"), "belt": C("#2a1e16")}}
		"skeleton_archer":
			return {"skin": C("#d8ceb4"), "eyes": C("#c8e0ff"), "glow": 0.6, "pose": {"arm_l": "bow", "arm_r": "hang", "sh": 0.11, "weight": 0.4},
				"body": {"build": "bones"}, "head": {"type": "skull", "mouth": "grin"},
				"kit": {"weapon": "bow", "weapon_hand": "l", "loin": C("#3e382e"), "belt": C("#2a2016")}}
		"skeleton_mage":
			return {"skin": C("#d0c8b8"), "eyes": C("#c0a0ff"), "glow": 1.0, "pose": {"arm_l": "staff", "arm_r": "cross", "sh": 0.11, "weight": -0.3},
				"body": {"build": "bones"}, "head": {"type": "skull", "mouth": "grin", "hood": C("#3a3448"), "face_lit": true},
				"kit": {"robe": C("#3e3850"), "torn": 0.8, "weapon": "staff", "glow": C("#b090ff"), "staff_c": C("#3a2a22")}}
		"bone_knight":
			return {"height": 600, "skin": C("#d0c8ac"), "eyes": C("#80b8ff"), "glow": 1.0, "horn": C("#4a4038"),
				"pose": {"arm_l": "hang", "arm_r": "hang", "sh": 0.13, "weight": 0.4, "tilt": -0.06},
				"body": {"build": "bones"}, "head": {"type": "skull", "mouth": "grin", "horns": true, "horn_len": 0.7},
				"kit": {"armor": C("#585652"), "plates": ["shoulders", "legs"], "belt": C("#3a3430"), "cape": C("#2a2226"), "weapon": "greatsword", "weapon_c": C("#8a8680"), "shield": C("#4a4440"), "shield_kind": "kite", "shield_mat": "metal"}}
		"tarunbas":
			return {"height": 680, "skin": C("#d8d4c8"), "eyes": C("#ff5030"), "glow": 1.0,
				"pose": {"arm_l": "hang", "arm_r": "rest", "sh": 0.14, "weight": -0.4, "tilt": 0.08},
				"body": {"build": "bones", "bulk": 1.2}, "head": {"type": "skull", "mouth": "grin", "size": 1.15, "crown": C("#9a7a32")},
				"kit": {"armor": C("#5a5040"), "plates": ["shoulders"], "belt": C("#4a3a20"), "loin": C("#3a1a30"), "cape": C("#3a1a30"), "weapon": "greatsword", "weapon_c": C("#6e6a64")}}
		"goblin":
			return {"height": 480, "skin": C("#7a9258"), "mottle": C("#4a5a30"), "eyes": C("#e8d060"),
				"pose": {"hunch": 0.45, "knee": 0.4, "arm_l": "hang", "arm_r": "claw", "sh": 0.105, "stance": 0.11, "head": 1.35, "legs": 0.9, "weight": 0.4},
				"body": {"build": "thin", "hands": "claw", "claws": 0.4}, "head": {"type": "goblin", "mouth": "grin", "ears": "long"},
				"kit": {"loin": C("#4a3a2a"), "weapon": "dagger", "weapon_c": C("#7a7468")}}
		"goblin_archer":
			return {"height": 480, "skin": C("#6a8250"), "mottle": C("#3e4e2a"), "eyes": C("#e8d060"),
				"pose": {"hunch": 0.35, "knee": 0.3, "arm_l": "bow", "arm_r": "hang", "sh": 0.105, "head": 1.35, "legs": 0.9, "weight": -0.3},
				"body": {"build": "thin", "hands": "claw"}, "head": {"type": "goblin", "mouth": "shut", "ears": "long"},
				"kit": {"shirt": C("#4a3e2c"), "shirt_len": 0.9, "torn": 0.5, "weapon": "bow", "loin": C("#3a2e20")}}
		"goblin_swordsman":
			return {"height": 500, "skin": C("#7a8a4e"), "mottle": C("#4a5228"), "eyes": C("#e8c850"),
				"pose": {"hunch": 0.3, "knee": 0.3, "arm_l": "hang", "arm_r": "hang", "sh": 0.115, "head": 1.3, "legs": 0.92, "weight": 0.5},
				"body": {"build": "normal", "hands": "claw"}, "head": {"type": "goblin", "mouth": "grin", "ears": "long"},
				"kit": {"shirt": C("#5a4630"), "torn": 0.1, "belt": C("#2a1e14"), "weapon": "sword", "weapon_c": C("#7e7a70"), "shield": C("#5a4a34"), "loin": C("#3a2e20")}}
		"goblin_miner":
			return {"height": 500, "skin": C("#8e9a58"), "mottle": C("#5a5a30"), "eyes": C("#e8d060"), "grime": 0.6,
				"pose": {"hunch": 0.35, "knee": 0.3, "arm_l": "rest", "arm_r": "hang", "sh": 0.115, "head": 1.3, "legs": 0.92, "weight": -0.4},
				"body": {"build": "normal", "hands": "claw"}, "head": {"type": "goblin", "mouth": "grin", "ears": "long", "cap": C("#6a5a3a")},
				"kit": {"shirt": C("#5a4a36"), "torn": 0.15, "weapon": "pick", "weapon_c": C("#6a6660"), "loin": C("#3e3226")}}
		"goblin_bomber":
			return {"height": 600, "width": 1.0, "skin": C("#a87a52"), "mottle": C("#6a4028"), "eyes": C("#ffa040"), "glow": 0.5,
				"pose": {"hunch": 0.3, "knee": 0.3, "arm_l": "rest", "arm_r": "hang", "sh": 0.15, "hip": 0.085, "head": 1.15, "legs": 0.85, "weight": 0.4},
				"body": {"build": "fat", "hands": "claw"}, "head": {"type": "goblin", "mouth": "grin", "ears": "long"},
				"extras": {"bombs": 4}, "kit": {"weapon": "bomb", "belt": C("#2a1e14"), "loin": C("#4a3220"), "straps": C("#3a2a1a")}}
		"hobgoblin_miner":
			return {"height": 600, "skin": C("#72844a"), "mottle": C("#40502a"), "eyes": C("#f0c040"), "grime": 0.6,
				"pose": {"hunch": 0.35, "knee": 0.3, "arm_l": "hang", "arm_r": "hang", "sh": 0.145, "head": 1.1, "weight": 0.5, "arms": 1.05},
				"body": {"build": "muscular", "hands": "claw"}, "head": {"type": "goblin", "mouth": "fangs", "ears": "pointed", "cap": C("#5a4a30")},
				"kit": {"weapon": "pick", "weapon_c": C("#6a6660"), "belt": C("#2a1e14"), "loin": C("#4a3a28"), "straps": C("#3a2a1a")}}
		"ice_orc_warrior":
			return {"height": 600, "skin": C("#9ab4c0"), "shade": C("#3a4a62"), "mottle": C("#4a5a6a"), "eyes": C("#e8f4ff"), "hair": "topknot", "hair_c": C("#e4e8ec"),
				"pose": {"knee": 0.25, "arm_l": "hang", "arm_r": "hang", "sh": 0.14, "weight": -0.5, "hunch": 0.15},
				"body": {"build": "muscular", "hands": "claw"}, "head": {"type": "orc", "mouth": "fangs", "ears": "pointed"},
				"kit": {"fur": C("#d0ccc4"), "weapon": "axe", "weapon_c": C("#6a8090"), "loin": C("#4a4a50"), "belt": C("#2a2420"), "boots": C("#3a3430")}}
		"ice_orc_shaman":
			return {"height": 580, "skin": C("#88a4c8"), "shade": C("#36446a"), "mottle": C("#4a5a7a"), "eyes": C("#a8e8ff"), "glow": 0.8, "hair": "long", "hair_c": C("#dce0e4"),
				"pose": {"hunch": 0.25, "arm_l": "staff", "arm_r": "claw", "sh": 0.12, "weight": 0.3},
				"body": {"build": "normal", "hands": "claw"}, "head": {"type": "orc", "mouth": "fangs", "ears": "pointed"},
				"kit": {"robe": C("#3e4a5e"), "fur": C("#d4d4cc"), "weapon": "staff", "glow": C("#90e0ff"), "staff_c": C("#c8d0d8")}}
		"yeti":
			return {"height": 620, "width": 1.0, "skin": C("#e4e8ea"), "skin_kind": "fur", "shade": C("#7a8898"), "eyes": C("#a0c8f0"), "fur_len": 1.3,
				"pose": {"hunch": 0.5, "knee": 0.35, "arm_l": "wide", "arm_r": "rest", "sh": 0.15, "hip": 0.08, "neck": 0.5, "arms": 1.12, "weight": 0.3},
				"body": {"build": "brute", "hands": "claw", "claws": 0.5, "feet": "claw"}, "head": {"type": "ape", "mouth": "scream", "size": 0.95}}
		"katumba":
			return {"height": 700, "width": 1.0, "skin": C("#f2f4f6"), "skin_kind": "fur", "shade": C("#6a8098"), "eyes": C("#70c8ff"), "glow": 1.0, "fur_len": 1.4,
				"pose": {"hunch": 0.45, "knee": 0.35, "arm_l": "hang", "arm_r": "rest", "sh": 0.16, "hip": 0.085, "neck": 0.5, "arms": 1.12, "weight": -0.4},
				"body": {"build": "brute", "bulk": 1.1, "hands": "claw", "claws": 0.6, "feet": "claw"}, "head": {"type": "ape", "mouth": "scream", "size": 0.95},
				"extras": {"crystals": C("#b8e4f8"), "frost": 0.6}, "kit": {"weapon": "club", "wood": C("#6a7a88")}}
	return {}
