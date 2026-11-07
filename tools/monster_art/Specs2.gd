extends RefCounted
## 몬스터 그림 설계 2부: 악마·흡혈귀·유령·골렘·석상·기사 · 네발짐승 · 구울 · 벌레 · 슬라임 · 노움 · 눈 · 구더기.


static func C(hex: String) -> Color:
	return Color(hex)


static func spec_of(id: String) -> Dictionary:
	match id:
		# ── 2층 고블린 숲(floor2.md §5 — FL21): 홉고블린 = 광부 몸 바탕, 곡괭이 대신 큰 몽둥이 · 가죽 어깨 · 깃털 단 머리띠 ──
		"hobgoblin":
			return {"height": 620, "skin": C("#6a7a46"), "mottle": C("#3c4a28"), "eyes": C("#f0c040"), "grime": 0.5,
				"pose": {"hunch": 0.3, "knee": 0.28, "arm_l": "hang", "arm_r": "rest", "sh": 0.15, "head": 1.1, "weight": 0.4, "arms": 1.08},
				"body": {"build": "muscular", "hands": "claw"}, "head": {"type": "goblin", "mouth": "fangs", "ears": "pointed"},
				"kit": {"weapon": "club", "weapon_c": C("#5a4632"), "armor": C("#4a3a2a"), "plates": ["shoulders"], "belt": C("#2a1e14"), "loin": C("#4a3a28"), "straps": C("#3a2a1a")}}
		# ── 2층 망자의 땅(floor2.md §3 — 원작 묘사 없음: 이름 · 등급에서 모습을 정함) ──
		"skeleton":  # 맨손에 녹슨 칼 하나 든 해골(궁수 · 메이지와 같은 뼈, 무장은 가볍게)
			return {"skin": C("#d4cab0"), "eyes": C("#c8d8ff"), "glow": 0.5, "pose": {"arm_l": "hang", "arm_r": "rest", "sh": 0.11, "weight": 0.3, "tilt": 0.05},
				"body": {"build": "bones"}, "head": {"type": "skull", "mouth": "grin"},
				"kit": {"loin": C("#3a342a"), "belt": C("#2a2016"), "weapon": "sword", "weapon_c": C("#7a6e5e")}}
		"skeleton_warrior":  # 둥근 나무 방패와 투구를 쓴 해골(앞줄)
			return {"skin": C("#d0c6aa"), "eyes": C("#c8d8ff"), "glow": 0.5, "pose": {"arm_l": "hang", "arm_r": "rest", "sh": 0.115, "weight": -0.3},
				"body": {"build": "bones"}, "head": {"type": "skull", "mouth": "grin", "helm": C("#5a5448"), "visor": false},
				"kit": {"armor": C("#4e4a42"), "plates": ["shoulders"], "belt": C("#2a2016"), "loin": C("#3a342a"), "weapon": "sword", "weapon_c": C("#7a6e5e"), "shield": C("#5a4632")}}
		"dullahan":  # 목 없는 검은 판금 기사 — 목 자리에 푸른 불씨만(머리를 아주 작게)
			return {"height": 620, "skin": C("#2a2a30"), "eyes": C("#80c8ff"), "glow": 1.0,
				"pose": {"arm_l": "hang", "arm_r": "rest", "sh": 0.135, "weight": 0.4, "tilt": -0.04, "head": 0.25},
				"body": {"build": "normal", "bulk": 1.2, "hands": "fist"}, "head": {"type": "skull", "mouth": "shut", "size": 0.35},
				"kit": {"armor": C("#33333b"), "plates": ["chest", "shoulders", "legs"], "boots": C("#1e1e24"), "cape": C("#1a1a22"), "weapon": "greatsword", "weapon_c": C("#6a6a74"), "belt": C("#1a1a1e")}}
		"death_knight":  # 비석에서 일어난 기사 — 블라터와 같은 데스나이트, 빛바랜 회흑 갑주 · 푸른 넋빛
			return {"height": 680, "skin": C("#3a3438"), "eyes": C("#7ab8ff"), "glow": 1.0, "horn": C("#16141a"), "blood": 0.15,
				"pose": {"knee": 0.15, "arm_l": "hang", "arm_r": "rest", "sh": 0.145, "weight": 0.4},
				"body": {"build": "muscular", "hands": "fist"}, "head": {"type": "human", "helm": C("#2a262c"), "horns": true, "horn_len": 0.6},
				"kit": {"armor": C("#2e2a30"), "boots": C("#18161a"), "cape": C("#1c2230"), "weapon": "greatsword", "weapon_c": C("#5a5e68")}}
		"iron_lizardman":
			return {"skin": C("#6a7a64"), "shade": C("#2a3a2e"), "mottle": C("#3a4a36"), "eyes": C("#e0c040"), "nail": C("#2a2a24"),
				"pose": {"knee": 0.3, "hunch": 0.25, "arm_l": "hang", "arm_r": "rest", "sh": 0.125, "weight": 0.4},
				"body": {"build": "muscular", "hands": "claw", "claws": 0.5, "feet": "claw"}, "head": {"type": "lizard", "mouth": "fangs", "ears": "none", "eye_style": "beast"},
				"extras": {"tail": C("#5e6e5a")}, "kit": {"armor": C("#5e6266"), "plates": ["chest", "shoulders"], "weapon": "spear", "weapon_c": C("#7a7a78"), "loin": C("#3a3228")}}
		"deathfiend":
			return {"height": 620, "width": 1.15, "skin": C("#6a5462"), "shade": C("#2a1626"), "mottle": C("#3a2030"), "eyes": C("#ff4020"), "glow": 1.0, "horn": C("#2a2020"), "blood": 0.4,
				"pose": {"hunch": 0.35, "knee": 0.3, "arm_l": "claw", "arm_r": "wide", "sh": 0.14, "weight": -0.3},
				"body": {"build": "muscular", "hands": "claw", "claws": 0.8, "feet": "claw"}, "head": {"type": "demon", "mouth": "fangs", "horns": true, "horn_len": 0.8, "ears": "pointed"},
				"extras": {"wings": C("#3a2a30")}, "kit": {"loin": C("#2a1e1e")}}
		"kirdui":
			return {"height": 720, "width": 1.05, "skin": C("#3e3a44"), "shade": C("#140f18"), "mottle": C("#4a2040"), "mottle_amt": 0.5, "eyes": C("#ff3020"), "glow": 1.0, "horn": C("#1a1818"), "blood": 0.6,
				"pose": {"hunch": 0.65, "knee": 0.4, "arm_l": "rest", "arm_r": "rest", "sh": 0.16, "hip": 0.085, "neck": 0.5, "arms": 1.15, "weight": 0.4},
				"body": {"build": "brute", "bulk": 1.1, "hands": "claw", "claws": 0.9, "feet": "claw"}, "head": {"type": "demon", "mouth": "fangs", "horns": true, "horn_len": 1.0, "size": 1.05},
				"extras": {"spikes": C("#1e1a1c"), "lumps": 5}, "kit": {"loin": C("#1e1a1a")}}
		"dreadfear":  # 계층군주 — 사용자 2026-11-01 다시 그림(V27): 사람 꼴 + 온몸에 구더기가 붙어 꿈틀댄다, 삐딱한 자세(한쪽으로 기울고 고개 꺾임)·벌린 다리,
			# 숫양 뿔·노란 눈은 이어 쓰고 뼈 대검을 늘어뜨려 쥔다(스킬 뼈 대검 내려치기). 옛 거대 상반신·날개·털 목도리는 Lord.gd에 남김
			return {"height": 700, "width": 1.18, "skin": C("#b4a284"), "mottle": C("#6a4436"), "mottle_amt": 0.65, "shade": C("#3a1a26"), "blood": 0.55,
				"eyes": C("#f4d27a"), "glow": 1.0, "horn": C("#cdb892"),
				"pose": {"hunch": 0.3, "knee": 0.3, "arm_l": "hang", "arm_r": "hang", "tilt": -0.32, "lean": 0.45, "twist": 0.25, "sh": 0.13,
					"stance": 0.22, "weight": 0.8, "knees_out": 0.35, "splay": 0.35, "arms": 1.12},
				"body": {"build": "normal", "bulk": 1.08, "hands": "claw", "claws": 0.7, "feet": "bare"},
				"head": {"type": "gaunt", "mouth": "fangs", "horns": C("#cdb892"), "horn_len": 0.95, "size": 1.08},
				"kit": {"loin": C("#2a1e1e"), "weapon": "greatsword", "weapon_c": C("#cfc2a0")},
				"extras": {"maggots": 120, "maggot_c": C("#e2d6b0")}}
		"kambormir":
			return {"height": 600, "skin": C("#ddd0d4"), "shade": C("#6a4a5a"), "eyes": C("#ff2a2a"), "glow": 1.0, "hair": "slick", "hair_c": C("#141014"),
				"pose": {"arm_l": "rest", "arm_r": "hang", "sh": 0.115, "weight": 0.5, "tilt": -0.08},
				"body": {"build": "thin", "hands": "claw", "claws": 0.7}, "head": {"type": "human", "mouth": "fangs", "ears": "pointed", "angry": 0.9},
				"kit": {"shirt": C("#1e1a22"), "shirt_len": 1.0, "torn": 0.0, "cape": C("#3a0c16"), "boots": C("#141014"), "belt": C("#2a1a1e"), "collar": C("#8a7040")}}
		"banshee":
			return {"skin": C("#c4cedc"), "shade": C("#4a5a78"), "eyes": C("#e8f4ff"), "glow": 0.9, "hair": "long", "hair_c": C("#dde2ea"), "fade": 0.55, "desat": 0.35,
				"pose": {"hunch": 0.2, "arm_l": "wide", "arm_r": "claw", "sh": 0.1, "weight": 0.3, "tilt": 0.18},
				"body": {"build": "thin", "hands": "claw", "claws": 0.5}, "head": {"type": "gaunt", "mouth": "scream", "eye_style": "glow"},
				"kit": {"robe": C("#8a98b0"), "torn": 1.0}}
		"copper_golem":
			return {"height": 640, "width": 1.0, "skin": C("#b8783e"), "skin_kind": "metal", "shade": C("#4a2a14"), "mottle": C("#4a9a7a"), "mottle_amt": 0.6, "eyes": C("#60f0e0"), "glow": 1.0,
				"pose": {"knee": 0.2, "arm_l": "hang", "arm_r": "hang", "sh": 0.16, "hip": 0.085, "neck": 0.25, "arms": 1.1, "weight": 0.2},
				"body": {"build": "brute", "hands": "fist", "feet": "bare"}, "head": {"type": "block", "size": 1.2}, "extras": {"lumps": 8}}
		"ice_golem":
			return {"height": 640, "width": 1.0, "skin": C("#a8d0e8"), "skin_kind": "slime", "shade": C("#2a5a7a"), "eyes": C("#e8fcff"), "glow": 1.0,
				"pose": {"knee": 0.2, "arm_l": "hang", "arm_r": "hang", "sh": 0.16, "hip": 0.085, "neck": 0.25, "arms": 1.1, "weight": -0.2},
				"body": {"build": "brute", "hands": "fist"}, "head": {"type": "block", "size": 1.2}, "extras": {"lumps": 10, "crystals": C("#d8f4ff"), "frost": 0.8}}
		"gargoyle_statue":
			return {"skin": C("#8a8a90"), "skin_kind": "stone", "shade": C("#3a3a42"), "mottle": C("#5a6a4a"), "mottle_amt": 0.35, "eyes": C("#e0b040"), "glow": 0.8, "horn": C("#6a6a70"),
				"pose": {"hunch": 0.6, "knee": 0.6, "arm_l": "claw", "arm_r": "claw", "sh": 0.13, "weight": 0.0, "stance": 0.13},
				"body": {"build": "muscular", "hands": "claw", "claws": 0.6, "feet": "claw"}, "head": {"type": "demon", "mouth": "fangs", "horns": true, "horn_len": 0.6, "ears": "pointed"},
				"extras": {"wings": C("#7a7a80"), "wing_span": 0.85}}
		"riddle_gatekeeper":
			return {"height": 620, "skin": C("#9aa0a8"), "skin_kind": "stone", "shade": C("#3e4450"), "eyes": C("#f8f0d0"), "glow": 1.0,
				"pose": {"arm_l": "staff", "arm_r": "cross", "sh": 0.13, "weight": 0.0},
				"body": {"build": "normal", "hands": "open"}, "head": {"type": "block", "size": 0.9},
				"kit": {"robe": C("#7a8088"), "torn": 0.0, "weapon": "staff", "glow": C("#f8ecc0"), "staff_c": C("#7a7a80")}}
		"ildium":
			return {"height": 720, "width": 0.95, "skin": C("#7a8088"), "skin_kind": "metal", "eyes": C("#ffa040"), "glow": 1.0,
				"pose": {"knee": 0.15, "arm_l": "hang", "arm_r": "hang", "sh": 0.16, "hip": 0.085, "neck": 0.6, "weight": 0.3},
				"body": {"build": "brute", "hands": "fist"}, "head": {"type": "human", "helm": C("#6e747c"), "size": 1.0},
				"kit": {"armor": C("#6e747a"), "boots": C("#4a4e54"), "weapon": "greatsword", "weapon_c": C("#9aa0a8"), "belt": C("#3a3430")}}
		"iron_cavalry":
			return {"height": 600, "skin": C("#8a7a6a"), "eyes": C("#e0c080"), "glow": 0.6,
				"pose": {"arm_l": "hang", "arm_r": "hang", "sh": 0.13, "weight": 0.4},
				"body": {"build": "normal", "hands": "fist"}, "head": {"type": "human", "helm": C("#6a7078"), "plume": C("#6a1a18")},
				"kit": {"armor": C("#70787f"), "boots": C("#3a3430"), "cape": C("#3a2420"), "weapon": "lance", "weapon_c": C("#8a9098"), "shield": C("#5a6068"), "shield_kind": "kite", "shield_mat": "metal"}}
		"blater":
			return {"height": 660, "skin": C("#5a4448"), "eyes": C("#ff3020"), "glow": 1.0, "horn": C("#1e1a1c"), "blood": 0.4,
				"pose": {"knee": 0.2, "arm_l": "hang", "arm_r": "rest", "sh": 0.14, "weight": -0.4},
				"body": {"build": "muscular", "hands": "fist"}, "head": {"type": "human", "helm": C("#3a2c32"), "horns": true, "horn_len": 0.8},
				"kit": {"armor": C("#3e2e34"), "boots": C("#241a1e"), "cape": C("#4a1418"), "weapon": "greatsword", "weapon_c": C("#5e4c50")}}
		# ── 약탈자(사람 — 1층 탐험가를 노리는 무리, 이 프로젝트에서 새로 그린 모습) ──
		"raider_cutthroat":  # 두건을 깊이 눌러쓴 칼잡이 + 짧은 칼(2026-10-26 사용자 "뼈다귀 같다" → 마른 몸 thin을 보통 몸·굵기 1.35·넓은 어깨·긴 윗옷)
			return {"height": 560, "skin": C("#b8967a"), "shade": C("#4a3026"), "eyes": C("#d8c8a0"),
				"pose": {"hunch": 0.2, "knee": 0.25, "arm_l": "hang", "arm_r": "rest", "sh": 0.13, "weight": 0.5, "tilt": 0.04},
				"body": {"build": "normal", "bulk": 1.35, "hands": "fist"}, "head": {"type": "human", "mouth": "shut", "hood": C("#3a342c")},
				"kit": {"shirt": C("#4a4034"), "shirt_len": 1.0, "torn": 0.2, "belt": C("#2a1e16"), "straps": C("#3a2a1e"), "boots": C("#2e2620"), "weapon": "dagger", "weapon_c": C("#8a8478")}}
		"raider_archer":  # 누더기 망토의 궁수(칼잡이처럼 살을 붙임)
			return {"height": 560, "skin": C("#a88a70"), "shade": C("#40302a"), "eyes": C("#d0c0a0"),
				"pose": {"hunch": 0.15, "knee": 0.2, "arm_l": "bow", "arm_r": "hang", "sh": 0.125, "weight": -0.3},
				"body": {"build": "normal", "bulk": 1.3, "hands": "fist"}, "head": {"type": "human", "mouth": "shut", "hood": C("#2e3028")},
				"kit": {"shirt": C("#3e3a30"), "shirt_len": 1.0, "torn": 0.3, "cape": C("#2a2820"), "belt": C("#2a1e16"), "boots": C("#2a221c"), "weapon": "bow"}}
		# ── 네발짐승 ──
		"blade_wolf":
			return {"kind": "beast", "height": 560, "color": C("#a0a0a4"), "belly": C("#c8c4bc"), "fur": 0.85, "blades": C("#9aa4ae"), "eyes": C("#e0b040")}
		"blood_blade_wolf":
			return {"kind": "beast", "height": 560, "color": C("#8e5a52"), "belly": C("#b88a7a"), "fur": 0.85, "blades": C("#a04a40"), "eyes": C("#ff4030"), "glow": 0.8, "blood": 0.5}
		"giant_blade_wolf":
			return {"kind": "beast", "height": 640, "color": C("#8a8c92"), "belly": C("#b4b0a8"), "fur": 0.9, "blades": C("#a8b0b8"), "bulk": 1.25, "eyes": C("#f0c040")}
		"frost_wolf":
			return {"kind": "beast", "height": 560, "color": C("#d8e2ea"), "belly": C("#f0f4f6"), "fur": 0.95, "frost": 0.8, "eyes": C("#80d0ff"), "glow": 0.8}
		"chimera_wolf":
			return {"kind": "beast", "height": 600, "color": C("#8a6a54"), "belly": C("#b0947a"), "fur": 0.7, "tail": "snake", "tail_c": C("#4a6a3a"), "horns": C("#3a3028"), "eyes": C("#ff8030"), "glow": 0.6}
		"sabertooth":
			return {"kind": "beast", "height": 560, "color": C("#d8ccb4"), "belly": C("#ece4d4"), "head": "cat", "fur": 0.3, "stripes": C("#3a2a1e"), "tail": "thin", "bulk": 1.1, "eyes": C("#e0d040")}
		"owlbear":
			return {"kind": "beast", "height": 620, "color": C("#9a8a70"), "belly": C("#c8b898"), "head": "owl", "fur": 0.8, "bulk": 1.4, "tail": "stub", "legs": 0.85, "eyes": C("#e8b030")}
		# ── 2층 짐승의 소굴(floor2.md §2 — 창작, LD12) ──
		"wall_mole":  # 협곡 벽을 파고 사는 두더지 — 쥐 머리 · 짧은 다리 · 흙빛 털
			return {"kind": "beast", "height": 420, "color": C("#5a4a3c"), "belly": C("#7a6650"), "head": "rat", "fur": 0.75, "tail": "stub", "bulk": 0.95, "legs": 0.6, "eyes": C("#d07040"), "head_k": 1.2}
		"mole_queen":  # 몸집이 몇 배인 여왕 — 짙은 털 · 붉은 눈
			return {"kind": "beast", "height": 580, "color": C("#3e3028"), "belly": C("#6a5444"), "head": "rat", "fur": 0.85, "tail": "stub", "bulk": 1.25, "legs": 0.65, "eyes": C("#ff5030"), "glow": 0.6, "head_k": 1.7}
		"moon_rock_bear":  # 가슴에 흰 반달 무늬 · 바위처럼 거친 검은 털
			return {"kind": "beast", "height": 640, "color": C("#2e2a28"), "belly": C("#d8d0b8"), "fur": 0.9, "head_k": 1.15, "tail": "stub", "bulk": 1.55, "legs": 0.8, "eyes": C("#c09040")}
		"bulkar":  # 바위 그늘에 붙어 위장하는 털 짐승 — 바위색 털에 짙은 얼룩
			return {"kind": "beast", "height": 520, "color": C("#8a8278"), "belly": C("#a8a094"), "fur": 1.0, "stripes": C("#4a443e"), "tail": "thin", "bulk": 1.05, "legs": 0.85, "eyes": C("#e0e0a0")}
		"werewolf":  # 늑대 무리의 우두머리 — 잿빛 털의 라이칸스로프(타룬바스 몸 — 무기 없이 발톱)
			return {"height": 700, "width": 1.0, "skin": C("#6a6460"), "skin_kind": "fur", "shade": C("#2a2624"), "eyes": C("#ffb030"), "glow": 0.9, "fur_len": 1.4,
				"pose": {"hunch": 0.45, "knee": 0.42, "arm_l": "claw", "arm_r": "claw", "sh": 0.16, "hip": 0.085, "neck": 0.45, "arms": 1.2, "weight": -0.4, "tilt": 0.05},
				"body": {"build": "brute", "bulk": 1.15, "hands": "claw", "claws": 0.9, "feet": "claw"}, "head": {"type": "ape", "mouth": "fangs", "ears": "long", "size": 1.0},
				"kit": {"belt": C("#2a221c"), "loin": C("#3a3028")}}
		"skull_rat":
			return {"kind": "beast", "height": 440, "color": C("#6a5a50"), "head": "rat", "fur": 0.6, "tail": "thin", "bulk": 0.85, "legs": 0.7, "eyes": C("#ff6030"), "head_k": 1.4}
		# ── 기는 것·벌레 ──
		"ghoul":
			return {"kind": "crawler", "color": C("#8a947c"), "blood": 0.5, "eyes": C("#e0d8a0")}
		"elder_ghoul":
			return {"kind": "crawler", "height": 480, "color": C("#6e7a66"), "bulk": 1.15, "blood": 0.8, "hair": "ragged", "hair_c": C("#2a2a24"), "eyes": C("#e8e0a0"), "glow": 0.6}
		"ghoul_lord":
			return {"kind": "crawler", "height": 520, "color": C("#5a6a48"), "bulk": 1.25, "blood": 1.0, "crown": C("#9a7a32"), "horns": C("#2a2820"), "eyes": C("#ff6030"), "glow": 1.0}
		"wormstone":
			return {"kind": "worm", "height": 560, "color": C("#8a8a90")}
		# ── 덩어리 ──
		"slime":
			return {"kind": "slime", "height": 320, "color": C("#6ac46a"), "inside": 1}
		"king_slime":
			return {"kind": "slime", "height": 520, "color": C("#4ab44a"), "crown": C("#d0a840"), "inside": 4}
		"mineral_slime":
			return {"kind": "slime", "height": 340, "color": C("#7a8a6a"), "crystals": C("#a8d8c0"), "inside": 2}
		"gnome":
			return {"kind": "mound", "height": 340, "color": C("#7a6a52"), "moss": C("#5a6a30"), "glow": 1.0, "eyes": C("#ffcc60")}
		"corrupted_gnome":
			return {"kind": "mound", "height": 340, "color": C("#4e4a3a"), "veins": C("#7a2a4a"), "glow": 1.0, "eyes": C("#ff4040")}
		"guardian_eye":
			return {"kind": "eye", "height": 440, "color": C("#b89070"), "iris": C("#d0c060")}
		"dreadfear_maggot":
			return {"kind": "maggot", "height": 280, "color": C("#d9cfa8")}
	return {}
