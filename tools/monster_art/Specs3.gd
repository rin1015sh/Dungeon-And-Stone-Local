extends RefCounted
## 몬스터 그림 설계 3부: 2층 새 몬스터 15종(docs/plans/floor2_monsters.md — 사용자 2026-11-08). 모습은 이름 · 데이터 색 · 크기에서 정했다(창작).


static func C(hex: String) -> Color:
	return Color(hex)


static func spec_of(id: String) -> Dictionary:
	match id:
		# ── 고블린 숲 ──
		"goblin_trapper":  # 덫 고리를 어깨에 감은 고블린 — 끈 · 등짐 · 짧은 창
			return {"height": 470, "skin": C("#6a8a50"), "mottle": C("#3e5228"), "eyes": C("#e8d060"),
				"pose": {"hunch": 0.45, "knee": 0.42, "arm_l": "hang", "arm_r": "rest", "sh": 0.105, "stance": 0.12, "head": 1.35, "legs": 0.88, "weight": 0.2},
				"body": {"build": "thin", "hands": "claw", "claws": 0.3}, "head": {"type": "goblin", "mouth": "grin", "ears": "long"},
				"kit": {"loin": C("#4a3a26"), "straps": C("#5a4630"), "belt": C("#2a1e14"), "weapon": "spear", "weapon_c": C("#6a5a40")}}
		"goblin_shaman":  # 뼈 장식 두건 · 긴 넝마 · 해골 지팡이
			return {"height": 480, "skin": C("#5a7a48"), "mottle": C("#344a26"), "eyes": C("#b0ff80"), "glow": 0.8,
				"pose": {"hunch": 0.5, "knee": 0.35, "arm_l": "staff", "arm_r": "claw", "sh": 0.1, "head": 1.35, "legs": 0.85, "weight": -0.2},
				"body": {"build": "thin", "hands": "claw", "claws": 0.5}, "head": {"type": "goblin", "mouth": "open", "ears": "long", "hood": C("#4a3a2e")},
				"kit": {"robe": C("#5a4a36"), "torn": 0.9, "collar": C("#d8ccb0"), "weapon": "staff", "glow": C("#a0e070"), "staff_c": C("#3a2a1e")}}
		"goblin_wolf_rider":  # 늑대 가죽을 뒤집어쓴 고블린 — 털 망토 · 긴 창(늑대 머리 두건)
			return {"height": 500, "skin": C("#7a8a50"), "mottle": C("#4a5228"), "eyes": C("#f0c040"),
				"pose": {"hunch": 0.35, "knee": 0.3, "arm_l": "hang", "arm_r": "rest", "sh": 0.115, "head": 1.3, "legs": 0.92, "weight": 0.4},
				"body": {"build": "normal", "hands": "claw"}, "head": {"type": "goblin", "mouth": "grin", "ears": "long", "hood": C("#7a7058")},
				"kit": {"fur": C("#7a7058"), "shirt": C("#4a3a28"), "belt": C("#2a1e14"), "boots": C("#3a2a1a"), "weapon": "lance", "weapon_c": C("#7a6a50")}}
		"goblin_hound":  # 고블린이 기르는 마른 사냥개 — 갈비 · 목줄
			return {"kind": "beast", "height": 460, "color": C("#5a5040"), "belly": C("#7a6a54"), "fur": 0.45, "tail": "thin", "bulk": 0.8, "legs": 1.05, "eyes": C("#e0a040")}
		"thorn_creeper":
			return {"kind": "vine", "height": 520, "color": C("#4a6a3a"), "bud": C("#7a2a3a"), "eyes": C("#f0c040"), "glow": 0.7}
		# ── 짐승의 소굴 ──
		"spine_boar":  # 등에 가시 털이 솟은 멧돼지 — 엄니 · 낮은 몸
			return {"kind": "beast", "height": 520, "color": C("#6a5040"), "belly": C("#8a7058"), "fur": 0.9, "blades": C("#3a2e24"), "tail": "stub", "bulk": 1.3, "legs": 0.7,
				"mouth": "shut", "tusks": C("#e0d4b8"), "eyes": C("#d05030")}
		"canyon_bat":
			return {"kind": "swarm", "height": 460, "color": C("#3a3036"), "count": 8, "eyes": C("#ff5040"), "glow": 0.6}
		"bone_hyena":  # 얼룩 하이에나 — 앞이 높고 뒤가 낮다
			return {"kind": "beast", "height": 500, "color": C("#8a7a5a"), "belly": C("#a8987a"), "fur": 0.55, "stripes": C("#3a3024"), "tail": "thin", "bulk": 0.95, "legs": 0.95, "eyes": C("#e0c040")}
		# ── 망자의 땅 ──
		"drowned":  # 물에 불은 시체 — 늘어진 살 · 진흙 · 수초
			return {"skin": C("#7a8a84"), "shade": C("#2a3a3a"), "mottle": C("#4a5a3a"), "mottle_amt": 0.6, "eyes": C("#d8e8d0"), "glow": 0.5,
				"pose": {"hunch": 0.35, "knee": 0.25, "arm_l": "claw", "arm_r": "claw", "sh": 0.12, "weight": 0.2, "tilt": 0.08},
				"body": {"build": "fat", "hands": "claw", "claws": 0.3}, "head": {"type": "gaunt", "mouth": "open"},
				"kit": {"shirt": C("#3a4038"), "torn": 1.0, "wraps": C("#4a5a3a"), "wraps_amt": 0.4}}
		"grave_keeper":  # 삽 대신 횃불 든 묘지기 — 두건 · 긴 앞치마
			return {"skin": C("#9a9078"), "shade": C("#3a3428"), "eyes": C("#f0c070"), "glow": 0.7,
				"pose": {"hunch": 0.4, "knee": 0.2, "arm_l": "hang", "arm_r": "rest", "sh": 0.12, "weight": -0.1},
				"body": {"build": "thin", "hands": "claw"}, "head": {"type": "gaunt", "mouth": "shut", "hood": C("#3a3428")},
				"kit": {"robe": C("#4a4234"), "torn": 0.5, "belt": C("#2a2218"), "weapon": "torch"}}
		"carrion_crow":
			return {"kind": "swarm", "height": 440, "color": C("#2a2628"), "count": 7, "beak": true, "eyes": C("#1a1410")}
		"wraith":  # 원한령 — 흐릿한 몸 · 찢긴 수의 · 빛나는 눈
			return {"skin": C("#9aa4bc"), "shade": C("#3a4460"), "eyes": C("#a0d0ff"), "glow": 1.0, "hair": "long", "hair_c": C("#5a6478"), "fade": 0.6, "desat": 0.4,
				"pose": {"hunch": 0.15, "arm_l": "claw", "arm_r": "wide", "sh": 0.1, "weight": -0.2, "tilt": -0.12},
				"body": {"build": "bones", "hands": "claw", "claws": 0.6}, "head": {"type": "skull", "mouth": "scream", "eye_style": "glow"},
				"kit": {"robe": C("#5a6480"), "torn": 1.0}}
		# ── 바위사막 ──
		"dune_scorpion":
			return {"kind": "scorpion", "height": 520, "color": C("#8a6a40"), "eyes": C("#f04020"), "glow": 0.5}
		"desert_vulture":
			return {"kind": "bird", "height": 560, "color": C("#5a4a3a"), "ruff": C("#c8b8a0"), "skin": C("#b07a6a"), "eyes": C("#e0c040")}
		"dried_pilgrim":  # 말라붙은 순례자 — 해진 순례복 · 붕대 · 지팡이
			return {"skin": C("#a08a68"), "shade": C("#4a3a28"), "eyes": C("#e8d8a0"), "glow": 0.6,
				"pose": {"hunch": 0.45, "knee": 0.2, "arm_l": "staff", "arm_r": "hang", "sh": 0.11, "weight": -0.3},
				"body": {"build": "bones", "hands": "claw"}, "head": {"type": "gaunt", "mouth": "open", "hood": C("#8a7656")},
				"kit": {"robe": C("#9a8460"), "torn": 0.7, "wraps": C("#c8b890"), "wraps_amt": 0.5, "weapon": "staff", "staff_c": C("#5a4630")}}
	return {}
