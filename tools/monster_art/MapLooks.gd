extends RefCounted
## 탐험 맵 탐험가 몸 그림의 옷차림 후보(2026-10-26 사용자 "거지 복장 같고 촌스럽다 · 머리가 크다 · 망토도 괜찮다 — 여러 개 그려 봐"):
## 걸음(Back.stride)은 그대로, 머리·다리 비율과 옷(Party kit + BackCloak 겉옷)만 바꾼다.
##   godot --headless --path . --script res://tools/paint_actors.gd -- --look=<id,id> --out=<폴더>  → <폴더>/<id>.webp(시트 하나씩)
## 항목: race · name · head · legs · spec(Party 설계에 덮어쓸 값 — kit은 통째로 바꾼다).

## 게임 그림의 옷차림(사용자 2026-10-26 "h4 b2로" → 2026-10-29 바바리안 "b8에 b7 합친 걸로" = b9 · 인간 "h6으로") — 탐험 맵 걷기 그림(paint_actors)과
## 전투 뒷모습(Party.spec_of → paint_monsters --only=party)·전투 동작(paint_motions)이 같이 쓴다.
const CHOSEN := {"human": "h6_ranger", "barbarian": "b9_iron_raider", "elf": "e4_ranger", "dwarf": "d4_axe", "beastkin": "k4_fox_rogue"}  ## 새 종족(사용자 2026-10-30 6차 시안 확정 — AM59)
## 게임 그림 말고도 남겨 두는 옷차림 → assets/actors/looks/<id>.webp(paint_actors가 같이 그린다):
##   n0_librarian(도서관 실내 방 사서 — CT62) · h3_coat(나중에 NPC 탐험가 — 사용자 "h3도 저장해 줘") · r0_raider(맵 약탈자 무리 — render.json view.raider_sprite, 사용자 2026-10-26 "전투 화면처럼 두건·망토로")
const KEEP := ["h3_coat", "r0_raider", "n0_librarian", "n1_guild_clerk", "n2_innkeeper", "n3_priest", "n4_merchant", "n5_smith", "n6_banker", "n7_trainer",
	"n8_acolyte", "n9_cook", "n10_apprentice", "n11_archer", "n12_maid", "n13_guard", "n14_scholar", "h0_traveler", "h1_cloak", "h7_hooded", "h11_wayfarer", "h4_gambeson"]  ## n8~ · h0·h1·h7·h11·h4 = 도시 실내 사람(CT69)


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
	## h6 망토 앞 트임 open 1.0 → 0.65 · open_top 0.18(사용자 2026-10-30 "앞으로 걸을 때 배가 너무 드러남 — 망토 로브로 살짝 가리게").
	## 머리 배율: h6·b9 = 게임 그림이라 2026-10-30 사용자 "인간·바바리안 탐험 화면 얼굴 조금 작게(엘프·수인만큼은 아니고)"로 1.75 → 1.62 · 2.1 → 1.92.
	## 순찰자 후보(사용자 2026-10-29 "인간 탐험가도 여러 개 — 반지의 제왕 아라고른 같은 느낌"): 몸에 맞춰 떨어지는 긴 망토(BackDrape)·가죽 웃옷·긴 장화·팔목 가죽.
	"h6_ranger": {"race": "human", "name": "순찰자", "head": 1.62, "legs": 0.82, "spec": {"arm_under": Color("#16120f"), "kit": {
		"pants": Color("#2e2c28"), "shirt": Color("#3e3a32"), "sleeves": "long", "vest": Color("#3a2a1e"), "belt": Color("#24180f"), "pouch": true,
		"boots": Color("#2a2018"), "boots_tall": true, "bracers": Color("#3a2a1c"), "elbow_guard": Color("#1c1714"),
		"cloak": {"c": Color("#33382e"), "len": 0.55, "flare": 1.2, "open": 0.65, "open_top": 0.18, "clasp": Color("#8a8070"), "collar": true}}}},
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
	## 도시 실내 방 NPC(2026-10-31, CT62): 도서관 사서 — 발목까지 오는 짙은 겉옷 · 끈 허리띠 · 센 머리와 수염.
	"n0_librarian": {"race": "human", "name": "도서관 사서", "head": 1.7, "legs": 0.82, "spec": {"hair": "short", "hair_c": Color("#9a958a"), "beard": Color("#a29c90"),
		"skin": Color("#b89a82"), "kit": {"pants": Color("#2c2a26"), "shirt": Color("#4a463c"), "sleeves": "long", "boots": Color("#221a14"),
		"coat": {"c": Color("#2e3a32"), "len": 0.95}, "outer_belt": Color("#6a5a3c")}}},
	## 도시 실내 방 NPC(2026-10-31, CT64): 길드 접수원 · 여관 주인 · 신관 · 상점 주인 · 대장장이 · 은행원 · 교관.
	"n1_guild_clerk": {"race": "human", "name": "길드 접수원", "head": 1.7, "legs": 0.82, "spec": {"hair": "long", "hair_c": Color("#3a2a1e"), "hair_len": 0.08,
		"kit": {"pants": Color("#2e2a24"), "shirt": Color("#8a7e64"), "sleeves": "long", "vest": Color("#3a4a3a"), "belt": Color("#2a1c14"), "boots": Color("#2a1e16"), "mantle": Color("#5a2a24")}}},
	"n2_innkeeper": {"race": "human", "name": "여관 주인", "head": 1.7, "legs": 0.8, "spec": {"hair": "short", "hair_c": Color("#5a3e2a"), "beard": Color("#5a3e2a"), "bulk": 1.15,
		"kit": {"pants": Color("#3a3228"), "shirt": Color("#9a8c6e"), "sleeves": "rolled", "apron": {"c": Color("#8a7e66")}, "belt": Color("#3a2818"), "boots": Color("#2e2218")}}},
	"n3_priest": {"race": "human", "name": "신관", "head": 1.7, "legs": 0.82, "spec": {"hair": "short", "hair_c": Color("#2a2420"),
		"kit": {"pants": Color("#3a3832"), "shirt": Color("#b8ae96"), "sleeves": "long", "boots": Color("#2a221a"),
		"coat": {"c": Color("#b4aa92"), "len": 0.95}, "sash": {"c": Color("#8a6a2a")}, "outer_belt": Color("#8a6a2a")}}},
	"n4_merchant": {"race": "human", "name": "상점 주인", "head": 1.7, "legs": 0.82, "spec": {"hair": "short", "hair_c": Color("#4a3a2a"),
		"kit": {"pants": Color("#3a3228"), "shirt": Color("#7a6a4e"), "sleeves": "long", "vest": Color("#5a3a26"), "belt": Color("#2a1c14"), "pouch": true, "boots": Color("#2e2218")}}},
	"n5_smith": {"race": "human", "name": "대장장이", "head": 1.7, "legs": 0.8, "spec": {"hair": "short", "hair_c": Color("#2a2420"), "beard": Color("#2a2420"), "bulk": 1.2,
		"kit": {"pants": Color("#2e2a24"), "shirt": Color("#5a4e3e"), "sleeves": "rolled", "apron": {"c": Color("#3e2a1c")}, "bracers": Color("#3a2a1c"), "boots": Color("#221a14")}}},
	"n6_banker": {"race": "human", "name": "은행원", "head": 1.7, "legs": 0.82, "spec": {"hair": "short", "hair_c": Color("#6a6458"),
		"kit": {"pants": Color("#24242a"), "shirt": Color("#a89e88"), "sleeves": "long", "boots": Color("#1a1814"),
		"coat": {"c": Color("#2a2a34"), "len": 0.55}, "outer_belt": Color("#1a1814")}}},
	"n7_trainer": {"race": "human", "name": "교관", "head": 1.7, "legs": 0.82, "spec": {"hair": "short", "hair_c": Color("#3a2e24"), "bulk": 1.1,
		"kit": {"pants": Color("#3e3830"), "boots": Color("#2e2218"), "bracers": Color("#3a2a1c"), "quilt": Color("#6a5e48"), "outer_belt": Color("#3a2818")}}},
	## 도시 실내 사람(2026-10-31, CT69): 수도사 · 요리사 · 견습생 · 궁수 · 여관 일꾼 · 경비병 · 학자.
	"n8_acolyte": {"race": "human", "name": "수도사", "head": 1.7, "legs": 0.82, "spec": {"hair": "short", "hair_c": Color("#4a3a2a"),
		"kit": {"pants": Color("#3a3228"), "shirt": Color("#6a5a44"), "sleeves": "long", "boots": Color("#2a221a"),
		"coat": {"c": Color("#5a4630"), "len": 0.95}, "outer_belt": Color("#a8946a")}}},
	"n9_cook": {"race": "human", "name": "요리사", "head": 1.7, "legs": 0.8, "spec": {"hair": "short", "hair_c": Color("#2e241c"), "bulk": 1.15,
		"kit": {"pants": Color("#3a342c"), "shirt": Color("#c8bea8"), "sleeves": "rolled", "apron": {"c": Color("#d8d0bc")}, "belt": Color("#3a2818"), "boots": Color("#2a2018")}}},
	"n10_apprentice": {"race": "human", "name": "대장간 견습생", "head": 1.75, "legs": 0.82, "spec": {"hair": "short", "hair_c": Color("#6a4a2e"),
		"kit": {"pants": Color("#34302a"), "shirt": Color("#7a6a52"), "sleeves": "rolled", "apron": {"c": Color("#4a3020")}, "boots": Color("#26201a")}}},
	"n11_archer": {"race": "human", "name": "궁수 수련생", "head": 1.75, "legs": 0.82, "spec": {"hair": "long", "hair_c": Color("#4a3424"), "hair_len": 0.06,
		"kit": {"pants": Color("#34322c"), "shirt": Color("#5a5444"), "sleeves": "long", "vest": Color("#3e4a34"), "belt": Color("#2a1c14"),
		"bracers": Color("#3a2a1c"), "boots": Color("#2a2018"), "boots_tall": true}}},
	"n12_maid": {"race": "human", "name": "여관 일꾼", "head": 1.7, "legs": 0.82, "spec": {"hair": "long", "hair_c": Color("#7a5434"), "hair_len": 0.1,
		"kit": {"pants": Color("#4a3a2e"), "shirt": Color("#8a7a62"), "sleeves": "rolled", "apron": {"c": Color("#c8bca4")}, "boots": Color("#2e2218")}}},
	"n13_guard": {"race": "human", "name": "은행 경비병", "head": 1.7, "legs": 0.82, "spec": {"hair": "short", "hair_c": Color("#2a2420"),
		"kit": {"pants": Color("#2e2c2a"), "shirt": Color("#3a3a3e"), "sleeves": "long", "boots": Color("#1e1a16"), "boots_tall": true,
		"chain": Color("#6a6e72"), "outer_belt": Color("#2a1c14"), "mantle": Color("#2a2a3a")}}},
	"n14_scholar": {"race": "human", "name": "학자", "head": 1.7, "legs": 0.82, "spec": {"hair": "long", "hair_c": Color("#8a8478"), "hair_len": 0.06, "beard": Color("#8a8478"),
		"kit": {"pants": Color("#2c2a26"), "shirt": Color("#5a4e3e"), "sleeves": "long", "boots": Color("#221a14"),
		"coat": {"c": Color("#5a2a2a"), "len": 0.8}, "outer_belt": Color("#2a1c14")}}},
	## b8 + b7(사용자 2026-10-29 "b8에 b7 합친 걸로 전부 교체"): 털 어깨·X자 멜빵·긴 띠 치마·맨다리 + 가시 쇠 어깨받이·쇠 팔목·쇠 위팔 띠.
	"b9_iron_raider": {"race": "barbarian", "name": "쇠 어깨 약탈자", "head": 1.92, "legs": 0.72, "spec": {"kit": {
		"pauldron": {"c": Color("#454a4e"), "side": "l", "kind": "iron", "size": 1.35}, "harness": {"c": Color("#2a1c12"), "x": true, "ring": Color("#6a6e72")},
		"pelt": Color("#5e5040"), "kilt": {"c": Color("#3e3024"), "len": 0.7, "slits": 8}, "leg_wraps": Color("#5a5040"),
		"boots": Color("#2e2218"), "boots_fur": Color("#5e5444"), "bracers": Color("#55595c"), "armband": Color("#55595c"), "paint": Color("#3a3a2a"),
		"elbow_guard": Color("#1c1714")}}},
	## 새 종족 후보(사용자 2026-10-30 "엘프·드워프·수인 — 엘프·수인은 여성 · 머리는 어두운 색 · 드워프는 수염 · 여러 복장 중 하나를 고른다"
	## → 2차 시안 12종 → 사용자가 준 참고 그림 세 장 "이 사진들 복장으로 다시"): 몸 = RaceParts.BODIES, 종족 소품 = RaceKit·RaceGear.
	## note = 비교 그림 부제(tools/looks_sheet.py). 그림 = paint_look_preview(시안) → 고르면 paint_actors·paint_motions --look.
	"e4_ranger": {"race": "elf", "name": "엘프 궁수", "note": "녹색 겉옷(엉덩이 아래까지) · 가죽 팔목 · 엉덩이 가죽 띠 둘 · 허리 칼집 · 은 메달 · 무릎 장화 · 등까지 오는 검은 머리", "head": 1.7, "legs": 0.88,
		"spec": {"arm_under": Color("#3a4430"), "hair": "long", "hair_c": Color("#141210"), "hair_len": 0.3, "hair_n": 12, "hair_w": 0.03, "hair_spread": 1.25, "kit": {
		"shirt": Color("#5a6040"), "sleeves": "long", "coat": {"c": Color("#4a5636"), "len": 0.16}, "outer_belt": Color("#3a2a1c"), "bracers": Color("#5a3e28"), "elbow_guard": Color("#3a2a1c"),
		"hip_belts": {"c": Color("#4a3020"), "n": 2}, "sheath": {"c": Color("#2a2420")}, "pendant": Color("#a8a49a"),
		"pants": Color("#5e5e52"), "boots": Color("#5a3e28"), "boots_tall": true}}},
	"d4_axe": {"race": "dwarf", "name": "드워프 전사", "note": "이마까지 덮는 뿔 투구 · 털 어깨 · 무릎 사슬 · 놋쇠 팔목 · 땋은 수염 넷", "head": 2.3, "legs": 0.62,
		"spec": {"arm_under": Color("#3a2e26"), "hair": "none", "hair_c": Color("#4a2a1c"), "beard": Color("#4a2a1c"), "beard_long": {"len": 0.22, "braids": 4, "c": Color("#4a2a1c")},
		"horns": Color("#8a7e66"), "horn_len": 0.6, "kit": {
		"helm": Color("#3a3e42"), "helm_brow": -0.12, "nasal": Color("#3a3e42"), "pelt": Color("#5a3a26"),
		"chain": Color("#3a3e42"), "kilt": {"c": Color("#3a3e42"), "len": 0.85, "slits": 2, "mat": "metal"}, "outer_belt": Color("#2a1c12"), "buckle": Color("#7a6a40"),
		"bracers": Color("#6a5a34"), "pants": Color("#3a3028"), "boots": Color("#2e2620")}}},
	"k4_fox_rogue": {"race": "beastkin", "name": "여우 수인 도적", "note": "두 번 감은 붉은 목도리 · 짙은 가죽 조끼 · 감은 팔목 · 허리 띠·주머니·단검 · 밧줄 · 긴 검은 장화 · 어깨 아래까지 오는 머리", "head": 1.8, "legs": 0.84,
		"spec": {"arm_under": Color("#24212a"), "hair": "long", "hair_c": Color("#2a1a12"), "hair_len": 0.2, "hair_n": 11, "hair_w": 0.028, "hair_spread": 1.2, "kit": {
		"shirt": Color("#2e2a30"), "sleeves": "long", "vest": Color("#3a2626"), "scarf": {"c": Color("#7a2a24")}, "bracers": Color("#4a3024"), "elbow_guard": Color("#2a1e18"),
		"belt": Color("#3a2418"), "pouch": true, "knife": true, "hip_belts": {"c": Color("#3a2418"), "n": 1}, "rope": Color("#8a7a5a"),
		"pants": Color("#24222a"), "boots": Color("#1a1614"), "boots_tall": true}}},
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
