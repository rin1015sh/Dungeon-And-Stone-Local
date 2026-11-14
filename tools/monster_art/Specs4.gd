extends RefCounted
## 몬스터 그림 설계 4부: 3층 순례자의 길 새 몬스터(사용자 2026-11-14). 원작 묘사(docs/LORE.md 한 줄)가 있으면 따르고,
## 없으면 이름 · 데이터 색 · 크기에서 모습을 정했다(창작 — 다이로우터 · 돌연변이 하급 정령 · 아이안트로 · 오크 히어로 · 오크 로드).


static func C(hex: String) -> Color:
	return Color(hex)


static func spec_of(id: String) -> Dictionary:
	match id:
		# ── 강철바위 언덕 ──
		"iron_falcon":  # 쇳빛 깃털의 매 — 접은 날개 · 굽은 부리
			return {"kind": "bird", "height": 500, "color": C("#6e727c"), "ruff": C("#a8aeb8"), "skin": C("#7a7e88"), "eyes": C("#f0c040")}
		"steel_hill_guard":  # 쇠로 짠 병사 — 판금 몸 · 미늘창 · 연 방패
			return {"height": 640, "skin": C("#6a6e74"), "skin_kind": "metal", "shade": C("#2a2e34"), "eyes": C("#80d0ff"), "glow": 0.8,
				"pose": {"knee": 0.1, "arm_l": "hang", "arm_r": "rest", "sh": 0.15, "weight": 0.1},
				"body": {"build": "muscular", "hands": "fist"}, "head": {"type": "block", "size": 0.95, "helm": C("#4e5258"), "visor": true},
				"kit": {"armor": C("#5a5e64"), "plates": ["chest", "shoulders", "legs"], "weapon": "lance", "weapon_c": C("#8a8e94"),
					"shield": C("#5a5e64"), "shield_kind": "kite", "shield_mat": "metal", "belt": C("#2a2a2e")}}
		"iantro":  # 무거운 등딱지를 진 땅딸막한 짐승 사람 — 낮은 무게중심(균형추) · 긴 팔
			return {"height": 560, "width": 1.15, "skin": C("#5a5248"), "skin_kind": "stone", "shade": C("#24201c"), "mottle": C("#7a6a50"), "mottle_amt": 0.45,
				"eyes": C("#e0b050"), "glow": 0.6,
				"pose": {"hunch": 0.55, "knee": 0.45, "arm_l": "hang", "arm_r": "hang", "sh": 0.17, "hip": 0.09, "neck": 0.3, "arms": 1.15, "stance": 0.15, "weight": 0.0},
				"body": {"build": "brute", "bulk": 1.15, "hands": "fist", "feet": "claw"}, "head": {"type": "ape", "mouth": "shut", "size": 0.75},
				"extras": {"lumps": 9, "spikes": C("#3a342c")}}
		# ── 오크 군락지 ──
		"orc_shaman":  # 초록 오크 주술사 — 뼈 목걸이 · 털 어깨 · 불씨 지팡이
			return {"height": 580, "skin": C("#6a8a4a"), "shade": C("#2a3a1e"), "mottle": C("#4a5a30"), "eyes": C("#f0c060"), "glow": 0.8, "hair": "long", "hair_c": C("#2a2018"),
				"pose": {"hunch": 0.25, "arm_l": "staff", "arm_r": "claw", "sh": 0.12, "weight": 0.3},
				"body": {"build": "normal", "hands": "claw"}, "head": {"type": "orc", "mouth": "fangs", "ears": "pointed"},
				"kit": {"robe": C("#4a3a2a"), "torn": 0.5, "fur": C("#6a5a40"), "collar": C("#d8ccb0"), "weapon": "staff", "glow": C("#ffb050"), "staff_c": C("#3a2a1e")}}
		"orc_warrior":
			return {"height": 600, "skin": C("#6a8048"), "shade": C("#2a3a1e"), "mottle": C("#4a5a2e"), "eyes": C("#f0d060"), "hair": "topknot", "hair_c": C("#1e1a14"),
				"pose": {"knee": 0.25, "arm_l": "hang", "arm_r": "hang", "sh": 0.14, "weight": -0.5, "hunch": 0.15},
				"body": {"build": "muscular", "hands": "claw"}, "head": {"type": "orc", "mouth": "fangs", "ears": "pointed"},
				"kit": {"fur": C("#5a4a36"), "weapon": "axe", "weapon_c": C("#7a746a"), "loin": C("#4a3a28"), "belt": C("#2a2016"), "boots": C("#3a2e22")}}
		"orc_archer":
			return {"height": 590, "skin": C("#647a44"), "shade": C("#28361c"), "mottle": C("#44522a"), "eyes": C("#f0d060"), "hair": "ragged", "hair_c": C("#1e1a14"),
				"pose": {"hunch": 0.2, "arm_l": "bow", "arm_r": "hang", "sh": 0.13, "weight": -0.3},
				"body": {"build": "normal", "hands": "claw"}, "head": {"type": "orc", "mouth": "fangs", "ears": "pointed"},
				"kit": {"shirt": C("#4a3e2c"), "shirt_len": 0.9, "torn": 0.4, "straps": C("#3a2a1a"), "weapon": "bow", "weapon_hand": "l", "loin": C("#3a2e20"), "boots": C("#3a2e22")}}
		"orc_great_warrior":  # 어깨 갑옷 · 큰 칼 · 붉은 띠
			return {"height": 680, "width": 1.1, "skin": C("#5a7040"), "shade": C("#24321a"), "mottle": C("#3e4e28"), "eyes": C("#ff9040"), "glow": 0.4, "hair": "topknot", "hair_c": C("#16120e"),
				"pose": {"knee": 0.25, "arm_l": "hang", "arm_r": "rest", "sh": 0.155, "hip": 0.08, "weight": 0.4, "arms": 1.08},
				"body": {"build": "muscular", "bulk": 1.15, "hands": "fist"}, "head": {"type": "orc", "mouth": "fangs", "ears": "pointed", "angry": 0.8},
				"kit": {"armor": C("#4a4440"), "plates": ["shoulders", "chest"], "weapon": "greatsword", "weapon_c": C("#8a8478"), "belt": C("#6a2a20"), "loin": C("#4a3a28"), "boots": C("#2e261e")}}
		"orc_hero":  # 이름 가진 오크 — 뿔 투구 · 판금 · 붉은 망토 · 큰 도끼
			return {"height": 700, "width": 1.12, "skin": C("#4e6438"), "shade": C("#1e2a14"), "mottle": C("#36442a"), "eyes": C("#ffc040"), "glow": 0.7, "horn": C("#d8ccb0"),
				"pose": {"knee": 0.2, "arm_l": "hang", "arm_r": "rest", "sh": 0.16, "hip": 0.085, "weight": 0.4, "arms": 1.08},
				"body": {"build": "muscular", "bulk": 1.2, "hands": "fist"}, "head": {"type": "orc", "mouth": "fangs", "ears": "pointed", "helm": C("#4a4440"), "horns": true, "horn_len": 0.6, "angry": 0.9},
				"kit": {"armor": C("#5a5248"), "plates": ["chest", "shoulders", "legs"], "cape": C("#6a1e18"), "weapon": "axe", "weapon_c": C("#9a948a"), "belt": C("#2a2016"), "boots": C("#241e18")}}
		"orc_lord":  # 오크 로드 — 산 같은 몸 · 왕관 · 털 망토 · 큰 몽둥이
			return {"height": 760, "width": 1.15, "skin": C("#46583a"), "shade": C("#1a2412"), "mottle": C("#2e3a22"), "eyes": C("#ff5030"), "glow": 0.9, "hair": "long", "hair_c": C("#16120e"),
				"pose": {"hunch": 0.2, "knee": 0.25, "arm_l": "hang", "arm_r": "rest", "sh": 0.17, "hip": 0.09, "neck": 0.5, "weight": 0.3, "arms": 1.12},
				"body": {"build": "brute", "bulk": 1.2, "hands": "fist"}, "head": {"type": "orc", "mouth": "fangs", "ears": "pointed", "crown": C("#b08a3a"), "angry": 1.0},
				"kit": {"fur": C("#4a3e30"), "armor": C("#4a4440"), "plates": ["shoulders"], "weapon": "club", "wood": C("#4a3a28"), "belt": C("#2a1e14"), "loin": C("#3a2e22"), "collar": C("#d8ccb0")}}
		# ── 칠흑의 강어귀 · 녹빛꼬리 습지 ──
		"frogman":  # 작은 녹색 개구리 인간 — 번들한 살갗 · 작살
			return {"height": 470, "skin": C("#4e7a3e"), "skin_kind": "slime", "shade": C("#1e3418"), "mottle": C("#2e4a24"), "mottle_amt": 0.6, "eyes": C("#f0e040"),
				"pose": {"hunch": 0.4, "knee": 0.5, "arm_l": "hang", "arm_r": "rest", "sh": 0.11, "stance": 0.15, "head": 1.25, "legs": 0.9, "weight": 0.3},
				"body": {"build": "thin", "hands": "claw", "feet": "claw"}, "head": {"type": "lizard", "mouth": "shut", "ears": "none", "eye_style": "beast", "size": 1.1},
				"kit": {"loin": C("#3a3424"), "belt": C("#2a2418"), "weapon": "spear", "weapon_c": C("#8a8070")}}
		"lizardman":  # 녹갈색 비늘 · 맨몸 · 뼈촉 창 · 꼬리
			return {"skin": C("#5e6e42"), "shade": C("#24301a"), "mottle": C("#3a4a2a"), "eyes": C("#e0c040"), "nail": C("#2a2a24"),
				"pose": {"knee": 0.3, "hunch": 0.25, "arm_l": "hang", "arm_r": "rest", "sh": 0.125, "weight": 0.4},
				"body": {"build": "muscular", "hands": "claw", "claws": 0.5, "feet": "claw"}, "head": {"type": "lizard", "mouth": "fangs", "ears": "none", "eye_style": "beast"},
				"extras": {"tail": C("#56663c")}, "kit": {"weapon": "spear", "weapon_c": C("#c8bca0"), "loin": C("#4a3a28"), "straps": C("#3a2e20")}}
		# ── 조각 사원 ──
		"nameless_statue":  # 얼굴 없는 작은 기도상 — 돌 옷자락 · 모은 손 · 빈 눈빛
			return {"height": 480, "skin": C("#a8a294"), "skin_kind": "stone", "shade": C("#4a463e"), "mottle": C("#6a6a52"), "mottle_amt": 0.3, "eyes": C("#c0e0ff"), "glow": 0.7,
				"pose": {"hunch": 0.2, "knee": 0.2, "arm_l": "cross", "arm_r": "cross", "sh": 0.11, "weight": 0.0},
				"body": {"build": "thin", "hands": "fist", "feet": "bare"}, "head": {"type": "human", "mouth": "shut", "hood": C("#9a9688")},
				"kit": {"robe": C("#9a9688"), "torn": 0.0}, "extras": {"lumps": 4}}
		# ── 마녀의 숲 ──
		"fairy":  # 손바닥만 한 날개 인형 떼 — 보랏빛 날개 가루
			return {"kind": "swarm", "height": 400, "color": C("#c8a8e0"), "count": 5, "insect": true, "eyes": C("#f8f0ff"), "glow": 0.9}
		"witch_wraith":  # 레이스 — 보랏빛 수의 · 초록 불꽃 눈 · 흩어지는 아랫몸
			return {"skin": C("#9a88b0"), "shade": C("#2e2040"), "eyes": C("#a0ff80"), "glow": 1.0, "hair": "long", "hair_c": C("#3a2a48"), "fade": 0.65, "desat": 0.3,
				"pose": {"hunch": 0.25, "arm_l": "wide", "arm_r": "claw", "sh": 0.1, "weight": 0.2, "tilt": 0.1},
				"body": {"build": "bones", "hands": "claw", "claws": 0.6}, "head": {"type": "skull", "mouth": "scream", "eye_style": "glow"},
				"kit": {"robe": C("#4a3a5a"), "torn": 1.0}}
		"witch_lamp":  # 도깨비불 — 흔들리는 불덩이
			return {"kind": "slime", "height": 300, "color": C("#e8a040"), "inside": 0, "eyes": C("#fff4b0"), "glow": 1.0, "fade": 0.5, "desat": 0.0}
		"woodman":  # 걷는 나무 인형 — 나뭇결 몸 · 이끼 · 가지 손
			return {"height": 580, "skin": C("#7a5a3a"), "skin_kind": "wood", "shade": C("#2e2014"), "mottle": C("#5a6a30"), "mottle_amt": 0.4, "eyes": C("#c8ff60"), "glow": 0.6,
				"pose": {"hunch": 0.2, "knee": 0.15, "arm_l": "hang", "arm_r": "claw", "sh": 0.13, "weight": 0.2, "arms": 1.1},
				"body": {"build": "thin", "hands": "claw", "claws": 0.8, "feet": "bare"}, "head": {"type": "block", "size": 0.9}, "extras": {"lumps": 6}}
		"snetree":  # 뿌리내린 채 걷는 나무 — 촉수 같은 가지
			return {"kind": "vine", "height": 640, "color": C("#5a4a32"), "bud": C("#3a6a2a"), "eyes": C("#e0ff60"), "glow": 0.8}
		"dirouter":  # 길을 비트는 그림자 — 두건 같은 머리 · 길게 늘어진 손
			return {"skin": C("#6a6080"), "shade": C("#16101e"), "eyes": C("#d080ff"), "glow": 1.0, "fade": 0.7, "desat": 0.3,
				"pose": {"hunch": 0.35, "arm_l": "wide", "arm_r": "claw", "sh": 0.1, "weight": -0.2, "tilt": -0.1, "arms": 1.2},
				"body": {"build": "thin", "hands": "claw", "claws": 0.9}, "head": {"type": "gaunt", "mouth": "shut", "hood": C("#1e1828"), "eye_style": "glow"},
				"kit": {"robe": C("#2a2438"), "torn": 1.0}}
		"mutant_spirit":  # 뒤틀린 마력 덩어리 — 촉수 달린 눈
			return {"kind": "eye", "height": 420, "color": C("#7a5a9a"), "iris": C("#80ffd0"), "fade": 0.35, "desat": 0.1}
		"homunculus":  # 사람을 흉내 낸 몸 — 핏기 없는 살 · 꿰맨 자국 · 민머리
			return {"height": 520, "skin": C("#d0b4a4"), "shade": C("#6a4a48"), "mottle": C("#a07070"), "mottle_amt": 0.3, "eyes": C("#e8e8d8"),
				"pose": {"hunch": 0.3, "knee": 0.2, "arm_l": "hang", "arm_r": "claw", "sh": 0.11, "weight": -0.2, "tilt": 0.08},
				"body": {"build": "thin", "hands": "claw"}, "head": {"type": "human", "mouth": "shut", "ears": "none"},
				"extras": {"stitches": true}, "kit": {"loin": C("#6a5a4a")}}
		"dryad":  # 나무 정령 — 나무껍질 살결 · 잎 머리 · 흐린 아랫몸
			return {"skin": C("#8aa06a"), "skin_kind": "wood", "shade": C("#2a3a1a"), "eyes": C("#e0ff90"), "glow": 0.7, "hair": "long", "hair_c": C("#4a6a2a"), "fade": 0.35,
				"pose": {"hunch": 0.05, "arm_l": "wide", "arm_r": "hang", "sh": 0.1, "weight": 0.4, "tilt": 0.12},
				"body": {"build": "thin", "hands": "open"}, "head": {"type": "human", "mouth": "shut", "ears": "pointed"},
				"kit": {"robe": C("#5a7a3a"), "torn": 0.7}}
		"half_troll":  # 2.5m 회갈색 거구 — 굽은 등 · 긴 팔 · 몽둥이
			return {"height": 720, "width": 1.05, "skin": C("#9a9488"), "shade": C("#4a4840"), "mottle": C("#6a6a58"), "mottle_amt": 0.4, "eyes": C("#ffb040"), "glow": 0.4,
				"hair": "ragged", "hair_c": C("#3a342c"),
				"pose": {"hunch": 0.5, "knee": 0.35, "arm_l": "hang", "arm_r": "rest", "sh": 0.16, "hip": 0.085, "neck": 0.5, "arms": 1.15, "weight": -0.3},
				"body": {"build": "brute", "bulk": 1.15, "hands": "fist", "feet": "bare"}, "head": {"type": "ape", "mouth": "fangs", "ears": "long", "size": 0.9},
				"kit": {"weapon": "club", "wood": C("#5a4630"), "loin": C("#4a3a28"), "belt": C("#2a2016")}}
		"canavaro":  # 언데드 사냥꾼 — 두건 · 긴 외투 · 석궁(활) · 붉은 눈
			return {"skin": C("#8a8070"), "shade": C("#2e2820"), "mottle": C("#5a5040"), "mottle_amt": 0.5, "eyes": C("#ff6040"), "glow": 0.9,
				"pose": {"hunch": 0.15, "arm_l": "bow", "arm_r": "hang", "sh": 0.12, "weight": -0.3},
				"body": {"build": "thin", "hands": "claw"}, "head": {"type": "gaunt", "mouth": "shut", "hood": C("#2a2420")},
				"kit": {"shirt": C("#3a3028"), "shirt_len": 1.0, "torn": 0.4, "cape": C("#241e1a"), "belt": C("#1e1812"), "straps": C("#3a2a1a"),
					"boots": C("#241e18"), "weapon": "bow", "weapon_hand": "l"}}
		"canavaro_hound":  # 카나바로의 들개 — 마른 언데드 개 · 붉은 눈
			return {"kind": "beast", "height": 440, "color": C("#4a4440"), "belly": C("#6a5a50"), "fur": 0.4, "tail": "thin", "bulk": 0.8, "legs": 1.05,
				"eyes": C("#ff5030"), "glow": 0.8, "mouth": "snarl"}
	return {}
