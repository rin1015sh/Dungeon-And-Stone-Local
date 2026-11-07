extends RefCounted
## 상태이상 아이콘(사용자 요청 2026-10-24 "상태이상은 글자가 아니라 머리 위 아이콘으로 — 피어 앤 헝거처럼, 직관적으로 새로 그려줘"):
## 상태 id → [기호, 색]. 받침 테 색은 종류(해로운 것 검붉은 · 이로운 것 탁한 금빛). 이름은 쓰지 않는다.
## 여관 요리(meal_*)는 모두 "meal" 한 장. 그 밖에 표에 없는 상태는 "debuff"·"buff"(화살표) 한 장으로(StatusIcons가 고른다).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Sh := preload("res://tools/status_art/Shapes.gd")
const G1 := preload("res://tools/status_art/Glyphs.gd")
const G2 := preload("res://tools/status_art/Glyphs2.gd")

const RIM_BAD := Color("#7a2a22")
const RIM_GOOD := Color("#8a7438")

## 기호 → [스크립트, 함수]
const GLYPHS := {
	"drop": [G1, "drop"], "bubbles": [G1, "bubbles"], "skull": [G1, "skull"], "flame": [G1, "flame"], "snowflake": [G1, "snowflake"],
	"ice_block": [G1, "ice_block"], "stars": [G1, "stars"], "spiral": [G1, "spiral"], "ghost": [G1, "ghost"], "eye": [G1, "eye"],
	"eye_cross": [G1, "eye_cross"], "lightning": [G1, "lightning"], "sweat": [G1, "sweat"], "stone": [G1, "stone"], "weight": [G1, "weight"],
	"broken_heart": [G1, "broken_heart"], "fang": [G1, "fang"], "maggot": [G1, "maggot"], "bone": [G1, "bone"], "bowl": [G1, "bowl"],
	"cloud": [G1, "cloud"], "puff": [G1, "puff"],
	"chain": [G2, "chain"], "lock": [G2, "lock"], "shield": [G2, "shield"], "broken_shield": [G2, "broken_shield"], "helmet": [G2, "helmet"],
	"sword": [G2, "sword"], "dagger": [G2, "dagger"], "dagger_drop": [G2, "dagger_drop"], "boot_wing": [G2, "boot_wing"],
	"arrow_up": [G2, "arrow"], "arrow_down": [G2, "arrow"], "crosshair": [G2, "crosshair"], "sigil": [G2, "sigil"],
	"exclamation": [G2, "exclamation"], "magnet": [G2, "magnet"], "hourglass": [G2, "hourglass"], "bear_trap": [G2, "bear_trap"],
	"mask": [G2, "mask"], "crossed_swords": [G2, "crossed_swords"], "fist": [G2, "fist"], "waves": [G2, "waves"], "burst": [G2, "burst"],
	"figure": [G2, "figure"], "veil": [G2, "veil"], "rune": [G2, "rune"], "coffin": [G2, "coffin"],
}

## 상태 id → [기호, 색]
const MAP := {
	"peckish": ["bowl", "#b8905a"], "hungry": ["bowl", "#a07a48"], "famished": ["bowl", "#84603a"], "starving": ["bowl", "#6a4a2a"], "starvation": ["skull", "#c8b890"],
	"soul_exhaustion": ["lock", "#5a6ab8"], "bleeding": ["drop", "#b01818"], "poison": ["bubbles", "#6aa832"],
	"stun": ["stars", "#e8d060"], "fear": ["ghost", "#a8b0c8"], "hyperalgesia": ["lightning", "#e05030"],
	"hypothermia": ["snowflake", "#a8d0f0"], "burn": ["flame", "#e86a20"], "stamina_depleted": ["hourglass", "#b09060"],
	"stressed": ["sweat", "#8ab0d8"], "guarding": ["shield", "#b0a080"], "blind": ["eye_cross", "#8a6a40"],
	"trap_set": ["bear_trap", "#8a8a88"], "iron_wall": ["shield", "#8a9aa8"], "rally": ["arrow_up", "#d05a30"],
	"lurk": ["dagger", "#6a6a80"], "paralysis": ["lightning", "#e8e060"], "snare": ["chain", "#8a8070"],
	"hidden": ["mask", "#6a6488"], "rot": ["maggot", "#a0a070"], "counter_stance": ["crossed_swords", "#c8c8c8"],
	"intimidated": ["arrow_down", "#b06040"], "curse": ["sigil", "#9a48b0"], "lethargy": ["hourglass", "#5a6ab8"],
	"exhaustion": ["sweat", "#c0a080"], "isolated": ["figure", "#8a8a8a"], "dread_proliferating": ["ghost", "#b83a3a"],
	"dread_seeping": ["ghost", "#7a4a7a"], "dread_veil": ["veil", "#5a4a6a"], "dread_groggy": ["stone", "#8a7a60"],
	"dread_rage": ["burst", "#d02020"], "dread_hatred_burst": ["burst", "#8a2060"], "dread_human_form": ["figure", "#c8a888"],
	"dread_buff_bone_memory": ["bone", "#d8ccb0"], "dread_buff_wax_armor": ["shield", "#e0c890"],
	"dread_buff_staring_eye": ["eye", "#c84040"], "dread_buff_maggot_nest": ["maggot", "#e0d8b0"],
	"dread_buff_echo": ["waves", "#9a80c0"], "petrify": ["stone", "#9a9890"], "suppress": ["weight", "#7a7068"],
	"frost": ["snowflake", "#e0f4ff"], "frozen": ["ice_block", "#8ac8f0"], "confusion": ["spiral", "#c080d0"],
	"grudge_mark": ["sigil", "#a0c8d0"], "sacrifice_mark": ["sigil", "#c82828"], "seal": ["lock", "#c0a050"],
	"heal_block": ["broken_heart", "#9a2a3a"], "telegraphed": ["exclamation", "#e8c040"], "march_order": ["sword", "#d8a040"],
	"daze": ["spiral", "#a0a0c0"], "shield_arm": ["shield", "#a08060"], "vitality_drain": ["fang", "#c02040"],
	"golem_burned": ["flame", "#a04020"], "golem_skeleton": ["bone", "#b8b0a0"], "blater_grudge": ["broken_heart", "#5a2a6a"],
	"blater_grudge_weak": ["broken_heart", "#8a6a8a"], "guardian_frenzy": ["burst", "#e06020"], "vamp_blood_feast": ["fang", "#8a1010"],
	"vamp_blood_veil": ["shield", "#8a1a2a"], "regen_stopped": ["broken_heart", "#7a7a7a"], "tear_sealed": ["lock", "#a8d8f0"],
	"haste": ["boot_wing", "#d0e0b0"], "mired": ["weight", "#6a5638"], "heat": ["flame", "#e8a040"], "refreshed": ["drop", "#8ab8e0"], "soaked": ["waves", "#6a9ac0"], "high_ground": ["arrow_up", "#c8c0a0"], "ambush_hunter": ["dagger", "#d8d8d8"], "ambush_hunter_weak": ["dagger", "#9a9a9a"],
	"steel_ice_wall": ["shield", "#a8d8f8"], "troll_frenzy": ["fist", "#6a8a4a"], "miner_helmet": ["helmet", "#c8a040"],
	"miner_helmet_weak": ["helmet", "#907e50"], "venom_weapon": ["dagger_drop", "#6aa832"], "overheat": ["flame", "#f08030"],
	"acid_corrosion": ["broken_shield", "#a0c030"], "shield_wall": ["shield", "#8a7a60"], "ildium_overheat": ["flame", "#d05020"],
	"magnetized": ["magnet", "#c03030"], "riddle_weakened": ["rune", "#7a7a8a"], "riddle_empowered": ["rune", "#e8a840"],
	"vulnerable": ["broken_shield", "#c05050"], "marked": ["crosshair", "#e04040"], "taunt": ["fist", "#c08040"],
	"covered": ["shield", "#9ab0c8"], "smoke_cover": ["cloud", "#a8a8a8"], "whetted": ["sword", "#e8e8e8"],
	"tomb_curse": ["coffin", "#8a7a50"], "blast_scorched": ["puff", "#5a4a40"],
	"meal": ["bowl_steam", "#c88a40"], "buff": ["arrow_up", "#c8a050"], "debuff": ["arrow_down", "#b04a3a"],
}


## 아이콘 한 장(96×96, 투명 바탕). good = 이로운 상태(받침 테 색).
static func paint(key: String, good: bool, seed_value: int) -> Paint:
	var p := Paint.new(Sh.S, Sh.S, seed_value)
	Sh.plate(p, RIM_GOOD if good else RIM_BAD)
	var m: Array = MAP.get(key, MAP["buff" if good else "debuff"])
	var col := Color(str(m[1]))
	match str(m[0]):
		"bowl_steam":
			G1.bowl(p, col, true)
		"arrow_up":
			G2.arrow(p, col, true)
		"arrow_down":
			G2.arrow(p, col, false)
		_:
			var g: Array = GLYPHS[str(m[0])]
			(g[0] as Script).call(str(g[1]), p, col)
	Ink.grade(p, 0.06, 1.08, Color("#120a08"), Color("#ffe8c8"), 0.08)
	return p
