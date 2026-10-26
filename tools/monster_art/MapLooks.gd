extends RefCounted
## 탐험 맵 탐험가 몸 그림의 옷차림 후보(2026-10-26 사용자 "거지 복장 같고 촌스럽다 · 머리가 크다 · 망토도 괜찮다 — 여러 개 그려 봐"):
## 걸음(Back.stride)은 그대로, 머리·다리 비율과 옷(Party kit + BackCloak 겉옷)만 바꾼다.
##   godot --headless --path . --script res://tools/paint_actors.gd -- --look=<id,id> --out=<폴더>  → <폴더>/<id>.webp(시트 하나씩)
## 항목: race · name · head · legs · spec(Party 설계에 덮어쓸 값 — kit은 통째로 바꾼다).

## 게임 그림의 옷차림(사용자 2026-10-26 "h4 b2로") — 탐험 맵 걷기 그림(paint_actors)과 전투 뒷모습(Party.spec_of → paint_monsters --only=party)이 같이 쓴다.
const CHOSEN := {"human": "h4_gambeson", "barbarian": "b2_leather"}
## 게임 그림 말고도 남겨 두는 옷차림(나중에 NPC 탐험가 — 사용자 "h3도 저장해 줘") → assets/actors/looks/<id>.webp(paint_actors가 같이 그린다)
const KEEP := ["h3_coat"]


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
	"b0_barbarian": {"race": "barbarian", "name": "바바리안(머리만 작게)", "head": 2.1, "legs": 0.72, "spec": {}},
	"b1_fur_cloak": {"race": "barbarian", "name": "털 망토", "head": 2.1, "legs": 0.72, "spec": {"kit": {
		"pants": Color("#4a3a2a"), "leg_wraps": Color("#6a5e4a"), "vest": Color("#5a4030"), "belt": Color("#3a2818"), "pouch": true,
		"boots": Color("#3e2e20"), "boots_fur": Color("#7a6a54"), "bracers": Color("#3e2c1c"), "armband": Color("#6a5a3a"),
		"cloak": {"c": Color("#5e5040"), "len": 0.4, "flare": 1.25, "open": 1.3, "fur": true}}}},
	"b2_leather": {"race": "barbarian", "name": "가죽 갑옷", "head": 2.1, "legs": 0.72, "spec": {"kit": {
		"pants": Color("#34302a"), "leg_wraps": Color("#6a5e4a"), "boots": Color("#3e2e20"), "boots_fur": Color("#7a6a54"), "bracers": Color("#3e2c1c"),
		"coat": {"c": Color("#4a3020"), "len": 0.08}, "outer_belt": Color("#2a1c12"), "pelt": Color("#6e5e4a")}}},
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
