extends RefCounted
## 탐험 맵 탐험가 몸 그림의 옷차림 후보(2026-10-26 사용자 "거지 복장 같고 촌스럽다 · 머리가 크다 · 망토도 괜찮다 — 여러 개 그려 봐"):
## 걸음(Back.stride)은 그대로, 머리·다리 비율과 옷(Party kit + BackCloak 겉옷)만 바꾼다.
##   godot --headless --path . --script res://tools/paint_actors.gd -- --look=<id,id> --out=<폴더>  → <폴더>/<id>.webp(시트 하나씩)
## 항목: race · name · head · legs · spec(Party 설계에 덮어쓸 값 — kit은 통째로 바꾼다).

## 게임 그림의 옷차림(사용자 2026-10-26 "h4 b2로" → 2026-10-29 바바리안 "b8에 b7 합친 걸로" = b9 · 인간 "h6으로") — 탐험 맵 걷기 그림(paint_actors)과
## 전투 뒷모습(Party.spec_of → paint_monsters --only=party)·전투 동작(paint_motions)이 같이 쓴다.
const CHOSEN := {"human": "h6_ranger", "barbarian": "b9_iron_raider"}
## 게임 그림 말고도 남겨 두는 옷차림 → assets/actors/looks/<id>.webp(paint_actors가 같이 그린다):
##   h3_coat(나중에 NPC 탐험가 — 사용자 "h3도 저장해 줘") · r0_raider(맵 약탈자 무리 — render.json view.raider_sprite, 사용자 2026-10-26 "전투 화면처럼 두건·망토로")
const KEEP := ["h3_coat", "r0_raider"]


const LOOKS := {
	"h0_traveler": {"race": "human", "name": "깔끔한 여행복", "head": 1.75, "legs": 0.82, "spec": {"kit": {
		"pants": Color("#3a3630"), "shirt": Color("#6a5e4e"), "sleeves": "long", "vest": Color("#3e2c20"), "mantle": Color("#4a2a24"),
		"belt": Color("#2a1c14"), "pouch": true, "knife": true, "boots": Color("#2e2218")}}},
	"h1_cloak": {"race": "human", "name": "방랑 망토", "head": 1.75, "legs": 0.82, "spec": {"kit": {
		"pants": Color("#3a3630"), "shirt": Color("#5a5244"), "sleeves": "long", "belt": Color("#2a1c14"), "boots": Color("#2e2218"),
		"cloak": {"c": Color("#3a3230"), "len": 0.42, "flare": 1.3, "open": 1.0, "clasp": Color("#8a7a58"), "collar": true}}}},
	"h2_hood": {"race": "human", "name": "두건 쓴 망토", "head": 1.75, "legs": 0.82, "spec": {"hair": "none", "kit": {
		"pants": Color("#33302c"), "shirt": Color("#4e4a40"), "sleeves": "long", "belt": Color("#2a1c14"), "boots": Color("#2a201a"),
		"hood_up": Color("#353130"), "cloak": {"c": Color("#353130"), "len": 0.45, "flare": 1.3, "open": 0.8, "clasp": Color("#7a6a4a")}}}},
	"h3_coat": {"race": "human", "name": "탐험가 외투", "head": 1.75, "legs": 0.82, "spec": {"kit": {
		"pants": Color("#34302a"), "shirt": Color("#7a6e5a"), "sleeves": "long", "boots": Color("#2a1e16"),
		"coat": {"c": Color("#4a3424"), "len": 0.55}, "outer_belt": Color("#24180f")}}},
	"h4_gambeson": {"race": "human", "name": "누빔 갑옷", "head": 1.75, "legs": 0.82, "spec": {"kit": {
		"pants": Color("#3e3830"), "boots": Color("#2e2218"), "bracers": Color("#3a2a1c"),
		"quilt": Color("#6a5e48"), "outer_belt": Color("#3a2818"), "mantle": Color("#5a2a24")}}},
	"h5_chain": {"race": "human", "name": "사슬 갑옷", "head": 1.75, "legs": 0.82, "spec": {"kit": {
		"pants": Color("#34322e"), "shirt": Color("#4a4236"), "sleeves": "long", "boots": Color("#2a221c"),
		"chain": Color("#6a6e72"), "outer_belt": Color("#2a1c14"), "cloak": {"c": Color("#4a2220"), "len": 0.38, "flare": 1.25, "open": 1.1, "clasp": Color("#8a7a58")}}}},
	"r0_raider": {"race": "human", "name": "약탈자(두건·망토)", "head": 1.75, "legs": 0.82, "spec": {"hair": "none", "skin": Color("#8a6a56"), "mottle": Color("#4a3026"), "kit": {
		"pants": Color("#2e2a26"), "shirt": Color("#4a4034"), "sleeves": "long", "belt": Color("#2a1e16"), "boots": Color("#2a221c"), "bracers": Color("#3a2a1e"),
		"hood_up": Color("#3a342c"), "cloak": {"c": Color("#2c2a22"), "len": 0.3, "flare": 1.05, "open": 0.9, "fit": true, "cone": true}}}},
	"b0_barbarian": {"race": "barbarian", "name": "바바리안(머리만 작게)", "head": 2.1, "legs": 0.72, "spec": {}},
	"b1_fur_cloak": {"race": "barbarian", "name": "털 망토", "head": 2.1, "legs": 0.72, "spec": {"kit": {
		"pants": Color("#4a3a2a"), "leg_wraps": Color("#6a5e4a"), "vest": Color("#5a4030"), "belt": Color("#3a2818"), "pouch": true,
		"boots": Color("#3e2e20"), "boots_fur": Color("#7a6a54"), "bracers": Color("#3e2c1c"), "armband": Color("#6a5a3a"),
		"cloak": {"c": Color("#5e5040"), "len": 0.4, "flare": 1.25, "open": 1.3, "fur": true}}}},
	"b2_leather": {"race": "barbarian", "name": "가죽 갑옷", "head": 2.1, "legs": 0.72, "spec": {"kit": {
		"pants": Color("#34302a"), "leg_wraps": Color("#6a5e4a"), "boots": Color("#3e2e20"), "boots_fur": Color("#7a6a54"), "bracers": Color("#3e2c1c"),
		"coat": {"c": Color("#4a3020"), "len": 0.08}, "outer_belt": Color("#2a1c12"), "pelt": Color("#6e5e4a")}}},
	## 야만전사 후보(사용자 2026-10-29 "바바리안 복장을 야만전사 느낌으로 여러 개 — 기획만"): 맨몸·가죽끈·띠 치마·뼈 장식(BackSavage).
	"b3_berserker": {"race": "barbarian", "name": "광전사", "head": 2.1, "legs": 0.72, "spec": {"kit": {
		"harness": {"c": Color("#2e2016"), "x": true, "ring": Color("#7a7064")}, "kilt": {"c": Color("#5a4030"), "len": 0.55, "slits": 7},
		"paint": Color("#7a2a1e"), "leg_wraps": Color("#6a5e4a"), "boots": Color("#3e2e20"), "boots_fur": Color("#7a6a54"),
		"bracers": Color("#3e2c1c"), "armband": Color("#6a5a3a")}}},
	"b4_wolf_pelt": {"race": "barbarian", "name": "늑대 털가죽", "head": 2.1, "legs": 0.72, "spec": {"kit": {
		"pelt": Color("#6a6050"), "kilt": {"c": Color("#5e5444"), "len": 0.5, "fur": true, "slits": 0}, "necklace": {"c": Color("#cbbb98"), "n": 7},
		"paint": Color("#2e2a30"), "pants": Color("#3a3028"), "boots": Color("#3e2e20"), "boots_fur": Color("#6e6250"),
		"bracers": Color("#3e2c1c"), "armband": Color("#6a5a3a")}}},
	"b5_skull_hunter": {"race": "barbarian", "name": "해골 사냥꾼", "head": 2.1, "legs": 0.72, "spec": {"kit": {
		"pauldron": {"c": Color("#a89a7c"), "side": "r", "kind": "skull"}, "harness": {"c": Color("#2a1c12"), "x": false, "ring": Color("#8a7a58")},
		"necklace": {"c": Color("#cbbb98"), "n": 9}, "pants": Color("#2e2a24"), "loin": Color("#5a4a36"), "leg_wraps": Color("#6a5e4a"),
		"boots": Color("#3a2a1e"), "bracers": Color("#3a2a1c")}}},
	"b6_chieftain": {"race": "barbarian", "name": "족장 털갑옷", "head": 2.1, "legs": 0.72, "spec": {"kit": {
		"vest": Color("#4a3020"), "pelt": Color("#7a6a52"), "kilt": {"c": Color("#6e5e4a"), "len": 0.6, "fur": true, "slits": 0},
		"pants": Color("#34302a"), "outer_belt": Color("#2a1c12"), "boots": Color("#3e2e20"), "boots_fur": Color("#7a6a54"),
		"bracers": Color("#3e2c1c"), "armband": Color("#8a7a58"), "necklace": {"c": Color("#cbbb98"), "n": 5}}}},
	"b7_scrap_iron": {"race": "barbarian", "name": "고철 반갑옷", "head": 2.1, "legs": 0.72, "spec": {"kit": {
		"pauldron": {"c": Color("#5e6266"), "side": "l", "kind": "iron"}, "harness": {"c": Color("#2e2016"), "x": false, "ring": Color("#6a6e72")},
		"kilt": {"c": Color("#4a3a2a"), "len": 0.5, "slits": 5}, "pants": Color("#2e2a24"), "leg_wraps": Color("#5e5444"),
		"boots": Color("#3a2a1e"), "bracers": Color("#55595c"), "armband": Color("#55595c"), "paint": Color("#2a2a34")}}},
	"b8_hide_raider": {"race": "barbarian", "name": "가죽 누더기 약탈자", "head": 2.1, "legs": 0.72, "spec": {"kit": {
		"pauldron": {"c": Color("#4a3424"), "side": "l", "kind": "leather"}, "harness": {"c": Color("#2a1c12"), "x": true, "ring": Color("#7a7064")},
		"pelt": Color("#5e5040"), "kilt": {"c": Color("#3e3024"), "len": 0.7, "slits": 8}, "leg_wraps": Color("#5a5040"),
		"boots": Color("#2e2218"), "boots_fur": Color("#5e5444"), "bracers": Color("#3a2a1c"), "paint": Color("#3a3a2a")}}},
	## 순찰자 후보(사용자 2026-10-29 "인간 탐험가도 여러 개 — 반지의 제왕 아라고른 같은 느낌"): 몸에 맞춰 떨어지는 긴 망토(BackDrape)·가죽 웃옷·긴 장화·팔목 가죽.
	"h6_ranger": {"race": "human", "name": "순찰자", "head": 1.75, "legs": 0.82, "spec": {"arm_under": Color("#16120f"), "kit": {
		"pants": Color("#2e2c28"), "shirt": Color("#3e3a32"), "sleeves": "long", "vest": Color("#3a2a1e"), "belt": Color("#24180f"), "pouch": true,
		"boots": Color("#2a2018"), "boots_tall": true, "bracers": Color("#3a2a1c"), "elbow_guard": Color("#1c1714"),
		"cloak": {"c": Color("#33382e"), "len": 0.55, "flare": 1.2, "open": 1.0, "clasp": Color("#8a8070"), "collar": true}}}},
	"h7_hooded": {"race": "human", "name": "두건 쓴 순찰자", "head": 1.75, "legs": 0.82, "spec": {"hair": "none", "kit": {
		"pants": Color("#2a2824"), "shirt": Color("#38342c"), "sleeves": "long", "vest": Color("#33261a"), "belt": Color("#24180f"), "knife": true,
		"boots": Color("#26201a"), "boots_tall": true, "bracers": Color("#33261a"), "hood_up": Color("#2e3029"),
		"cloak": {"c": Color("#2e3029"), "len": 0.8, "flare": 1.25, "open": 0.85}}}},
	"h8_strider": {"race": "human", "name": "떠돌이 검사(긴 가죽 외투)", "head": 1.75, "legs": 0.82, "spec": {"kit": {
		"pants": Color("#2c2a26"), "boots": Color("#2a2018"), "boots_tall": true, "bracers": Color("#2e2218"),
		"coat": {"c": Color("#3a2a1e"), "len": 0.42}, "outer_belt": Color("#1e140c"),
		"cloak": {"c": Color("#2c2c2a"), "len": 0.62, "flare": 1.15, "open": 1.2, "clasp": Color("#7a7060")}}}},
	"h9_north_guard": {"race": "human", "name": "북방 경비대", "head": 1.75, "legs": 0.82, "spec": {"kit": {
		"pants": Color("#34302a"), "boots": Color("#2e2218"), "boots_tall": true, "bracers": Color("#3a2a1c"),
		"quilt": Color("#4a4438"), "outer_belt": Color("#2a1c12"),
		"cloak": {"c": Color("#3a2e26"), "len": 0.45, "flare": 1.1, "open": 1.1, "clasp": Color("#8a7a58"), "collar": true}}}},
	"h10_mail_ranger": {"race": "human", "name": "사슬 순찰자", "head": 1.75, "legs": 0.82, "spec": {"kit": {
		"pants": Color("#2e2c28"), "shirt": Color("#3a362e"), "sleeves": "long", "boots": Color("#2a2018"), "boots_tall": true, "bracers": Color("#3a2a1c"),
		"chain": Color("#4e5256"), "outer_belt": Color("#24180f"),
		"cloak": {"c": Color("#30342c"), "len": 0.68, "flare": 1.2, "open": 1.0, "clasp": Color("#8a8070")}}}},
	"h11_wayfarer": {"race": "human", "name": "길손(짧은 망토)", "head": 1.75, "legs": 0.82, "spec": {"kit": {
		"pants": Color("#3a3630"), "shirt": Color("#5a5244"), "sleeves": "long", "vest": Color("#3e2c20"), "belt": Color("#2a1c14"), "pouch": true,
		"boots": Color("#2e2218"), "bracers": Color("#3a2a1c"),
		"cloak": {"c": Color("#4a3a2c"), "len": 0.3, "flare": 1.1, "open": 1.3, "collar": true}}}},
	## b8 + b7(사용자 2026-10-29 "b8에 b7 합친 걸로 전부 교체"): 털 어깨·X자 멜빵·긴 띠 치마·맨다리 + 가시 쇠 어깨받이·쇠 팔목·쇠 위팔 띠.
	"b9_iron_raider": {"race": "barbarian", "name": "쇠 어깨 약탈자", "head": 2.1, "legs": 0.72, "spec": {"kit": {
		"pauldron": {"c": Color("#454a4e"), "side": "l", "kind": "iron", "size": 1.35}, "harness": {"c": Color("#2a1c12"), "x": true, "ring": Color("#6a6e72")},
		"pelt": Color("#5e5040"), "kilt": {"c": Color("#3e3024"), "len": 0.7, "slits": 8}, "leg_wraps": Color("#5a5040"),
		"boots": Color("#2e2218"), "boots_fur": Color("#5e5444"), "bracers": Color("#55595c"), "armband": Color("#55595c"), "paint": Color("#3a3a2a"),
		"elbow_guard": Color("#1c1714")}}},
	## 새 종족 후보(사용자 2026-10-30 "엘프·드워프·수인 — 엘프·수인은 여성 · 머리는 어두운 색 · 드워프는 수염 · 여러 복장 중 하나를 고른다"
	## → 첫 시안 "종족 느낌도 안 나고 밋밋 — 휘황찬란 말고 바바리안·인간처럼 은은한 개성"): 몸 = RaceParts.BODIES, 종족 소품 = RaceKit.
	## note = 비교 그림 부제(tools/looks_sheet.py). 그림 = paint_look_preview(시안) → 고르면 paint_actors·paint_motions --look.
	"e0_bow": {"race": "elf", "name": "숲의 궁수", "note": "이끼색 웃옷 · 짧은 어깨 망토 · 등 화살통 · 은 머리띠", "head": 1.7, "legs": 0.88, "spec": {"kit": {
		"shirt": Color("#5e6a52"), "sleeves": "long", "vest": Color("#3a4630"), "belt": Color("#3a2a1c"), "pants": Color("#2e302a"), "mantle": Color("#4a5a40"),
		"boots": Color("#2e2418"), "boots_tall": true, "bracers": Color("#4a3a2a"), "quiver": {"c": Color("#4a3624")}, "circlet": {"c": Color("#c8c4b8")}}}},
	"e1_blade": {"race": "elf", "name": "은빛 검객", "note": "가는 사슬 위 사선 천 띠 · 한쪽 가죽 어깨받이 · 묶은 머리", "head": 1.7, "legs": 0.88,
		"spec": {"ponytail": {"len": 0.2}, "hair_len": 0.06, "kit": {
		"shirt": Color("#3e4a48"), "sleeves": "long", "chain": Color("#3e4448"), "sash": {"c": Color("#2e5254")}, "pauldron": {"c": Color("#4a3a2a"), "side": "l", "kind": "leather", "size": 0.8},
		"pants": Color("#2a2c2a"), "belt": Color("#24180f"), "boots": Color("#2a2018"), "boots_tall": true, "bracers": Color("#5a5e62")}}},
	"e2_sage": {"race": "elf", "name": "숲의 현자", "note": "남회색 긴 망토(은 여밈) · 은 머리띠 · 땋은 두 갈래", "head": 1.7, "legs": 0.88,
		"spec": {"hair_c": Color("#1e1610"), "braids": 2, "kit": {
		"pants": Color("#2a2c28"), "boots": Color("#26201a"), "boots_tall": true, "shirt": Color("#6a6a62"), "sleeves": "long", "vest": Color("#3a4252"), "belt": Color("#3a2c1e"),
		"cloak": {"c": Color("#3a4252"), "len": 0.75, "flare": 1.2, "open": 0.55, "clasp": Color("#c8c4b8"), "collar": true}, "circlet": {"c": Color("#c8c4b8"), "gem": Color("#4a6a7a")}}}},
	"e3_scout": {"race": "elf", "name": "숲길 정찰병", "note": "청록 목도리 · 가죽 조끼 · 단검 · 긴 장화", "head": 1.7, "legs": 0.88, "spec": {"kit": {
		"shirt": Color("#6e6a5a"), "sleeves": "long", "vest": Color("#4a3624"), "scarf": {"c": Color("#3e5e5e")}, "belt": Color("#2a1c12"), "knife": true, "pouch": true,
		"pants": Color("#2e302a"), "boots": Color("#2e2418"), "boots_tall": true, "bracers": Color("#4a3a2a")}}},
	"d0_ironside": {"race": "dwarf", "name": "강철 전사", "note": "양어깨 쇠받이 · 사슬 · 큰 청동 버클 · 코 가리개 투구", "head": 2.3, "legs": 0.62,
		"spec": {"hair": "none", "kit": {
		"shirt": Color("#4a3a30"), "sleeves": "long", "chain": Color("#3a3e42"), "pauldron": {"c": Color("#3e4246"), "side": "both", "kind": "iron", "size": 1.05},
		"belt": Color("#2a1c12"), "buckle": Color("#8a6a3a"), "helm": Color("#44484c"), "nasal": Color("#44484c"),
		"pants": Color("#3a342c"), "boots": Color("#2e2218"), "bracers": Color("#3e4246")}}},
	"d1_smith": {"race": "dwarf", "name": "대장장이", "note": "가죽 앞치마 · 걷은 소매 · 쇠 팔목 · 한 갈래 땋은 수염", "head": 2.3, "legs": 0.62,
		"spec": {"beard_long": {"len": 0.2, "braids": 1}, "kit": {
		"shirt": Color("#7a6a50"), "sleeves": "rolled", "apron": {"c": Color("#4a3020"), "len": 0.85}, "belt": Color("#2a1c12"), "buckle": Color("#8a6a3a"),
		"pants": Color("#3e3428"), "boots": Color("#3a2a1e"), "bracers": Color("#3e4246"), "armband": Color("#4a4e52")}}},
	"d2_guardian": {"race": "dwarf", "name": "산문 수호병", "note": "판금 · 진홍 짧은 망토 · 뿔 투구", "head": 2.3, "legs": 0.62,
		"spec": {"hair": "none", "horns": Color("#8a8070"), "horn_len": 0.45, "kit": {
		"pants": Color("#34302a"), "armor": Color("#42474c"), "boots": Color("#34302a"), "helm": Color("#42474c"), "nasal": Color("#42474c"), "buckle": Color("#8a6a3a"),
		"cloak": {"c": Color("#5a2622"), "len": 0.3, "flare": 1.1, "open": 1.2, "clasp": Color("#8a6a3a")}}}},
	"d3_wander": {"race": "dwarf", "name": "떠돌이 광부", "note": "누빔 · 등짐(담요 · 곡괭이) · 털 단 장화", "head": 2.3, "legs": 0.62, "spec": {"kit": {
		"quilt": Color("#6a5a44"), "outer_belt": Color("#3a2818"), "pack": {"c": Color("#5a4430"), "roll": Color("#4a5060"), "pick": true},
		"pants": Color("#3a3228"), "boots": Color("#2e2218"), "boots_fur": Color("#5e5444"), "bracers": Color("#3a2a1c")}}},
	"k0_fox_drifter": {"race": "beastkin", "name": "여우 떠돌이", "note": "녹슨 붉은 목도리 · 짧은 조끼 · 짧은 띠 치마 · 감은 종아리", "head": 1.8, "legs": 0.84, "spec": {"kit": {
		"shirt": Color("#7a7462"), "sleeves": "long", "vest": Color("#4a3424"), "scarf": {"c": Color("#7a3a26")}, "kilt": {"c": Color("#4a3a2a"), "len": 0.3, "slits": 4},
		"pants": Color("#3a3228"), "leg_wraps": Color("#8a7e68"), "belt": Color("#2a1c12"), "boots": Color("#2e2218"), "bracers": Color("#4a3424")}}},
	"k1_wolf_hunter": {"race": "beastkin", "name": "늑대 사냥꾼", "note": "털 어깨 · 한쪽 가죽 어깨받이 · 사선 멜빵 · 송곳니 목걸이 · 감은 천", "head": 1.8, "legs": 0.84,
		"spec": {"ears": "wolf", "hair_c": Color("#1c1816"), "hair": "long", "hair_len": 0.14, "fluff_tail": {"kind": "wolf", "c": Color("#2a2622")}, "kit": {
		"shirt": Color("#4a4034"), "sleeves": "long", "pelt": Color("#4a4238"), "pauldron": {"c": Color("#4a3424"), "side": "r", "kind": "leather", "size": 0.9},
		"harness": {"c": Color("#2a1c12"), "x": false, "ring": Color("#6a6e72")}, "necklace": {"c": Color("#c8b898"), "n": 5},
		"pants": Color("#2e2a26"), "leg_wraps": Color("#6a6050"), "boots": Color("#2e2218"), "bracers": Color("#6a6050")}}},
	"k2_cat_thief": {"race": "beastkin", "name": "고양이 도적", "note": "몸에 붙는 검은 옷 · 자줏빛 사선 천 띠 · 짧은 어깨 망토 · 긴 장화", "head": 1.8, "legs": 0.84,
		"spec": {"ears": "cat", "hair_c": Color("#141110"), "fluff_tail": {"kind": "cat", "c": Color("#1c1816")}, "kit": {
		"shirt": Color("#2a2826"), "sleeves": "long", "pants": Color("#24221f"), "sash": {"c": Color("#4a2e40"), "w": 0.04}, "mantle": Color("#2e2a2a"),
		"belt": Color("#1e140c"), "knife": true, "boots": Color("#1e1814"), "boots_tall": true, "bracers": Color("#2e2218"), "elbow_guard": Color("#1c1714")}}},
	"k3_fox_warrior": {"race": "beastkin", "name": "여우 검사", "note": "짙은 웃옷 · 황토빛 허리띠 · 털 치마 · 쇠 팔목 · 묶은 머리", "head": 1.8, "legs": 0.84,
		"spec": {"hair": "long", "hair_len": 0.05, "ponytail": {"len": 0.16, "high": 0.45}, "kit": {
		"shirt": Color("#3a3830"), "sleeves": "long", "coat": {"c": Color("#2e3430"), "len": 0.08}, "outer_belt": Color("#7a5a2e"), "kilt": {"c": Color("#5e5040"), "len": 0.7, "fur": true, "slits": 3},
		"pants": Color("#2e2a26"), "boots": Color("#2e2218"), "boots_fur": Color("#5e5444"), "bracers": Color("#3e4246")}}},
}


static func has(id: String) -> bool:
	return LOOKS.has(id)


static func race_of(id: String) -> String:
	return str((LOOKS.get(id, {}) as Dictionary).get("race", "human"))


## 종족 설계(Party.spec_of(<종족>_back))에 이 옷차림을 덮는다.
static func apply(base: Dictionary, id: String) -> Dictionary:
	var sp := base.duplicate(true)
	var lk: Dictionary = LOOKS.get(id, {})
	for key: String in (lk.get("spec", {}) as Dictionary):
		sp[key] = (lk["spec"] as Dictionary)[key]
	return sp


## 머리·다리 배율(없으면 -1 — paint_actors의 종족 값을 쓴다).
static func body(id: String) -> Dictionary:
	var lk: Dictionary = LOOKS.get(id, {})
	return {"head": float(lk.get("head", -1.0)), "legs": float(lk.get("legs", -1.0))}
