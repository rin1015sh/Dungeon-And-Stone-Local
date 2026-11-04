class_name PlayerCharacter
extends Actor
## 플레이어 캐릭터: 종족·시작 템플릿·이름 + 성장(Progression)·정보(Knowledge). 소지품은 Tab 메뉴에서만 쓴다(단축칸 없음 — 2026-10-19).
## 시작 소지품은 템플릿의 start_items, 시작 장비는 start_equipment(장착된 채로), 시작 돈은 char_creation.start_stones.

var race_id: String = ""
var class_id: String = ""
var progression: Progression = Progression.new()
var knowledge: Knowledge = Knowledge.new()
var essences: EssenceSet = EssenceSet.new()
## 레벨 하락 때 잠글 정수 슬롯을 고르는 난수(테스트에서 시드를 고정할 수 있다).
var essence_rng: Rng = Rng.new()
## 피로도(도시·미궁 공용, 핵심 스탯이 아닌 별도 수치). 규칙은 data/city.json fatigue.
var fatigue: Fatigue = Fatigue.new()
const FATIGUE_SOURCE := "fatigue"
var _fatigue_tier_level: float = 0.0  # 마지막으로 알린 피로 단계(at_least)
## 활동으로 오른 능력치 기록 [{stat, amount, activity, month, period}] — 도시 독서·훈련(CityEffect stat_chance).
var stat_history: Array[Dictionary] = []
## 전투 줄(사용자 2026-10-25): "front"(전위 — 적 어그로를 더 받는다) · "back"(후위). 비면 템플릿 역할로(default_row).
var row: String = ""
const BACK_ROLES := ["ranged", "caster", "healer"]  ## 궁수·마법사·신관 = 후위, 탱커·근접 딜러 = 전위


## 지금 전투 줄.
func get_row() -> String:
	return row if row in ["front", "back"] else default_row(db, class_id)


## 템플릿 역할(classes role)로 정한 기본 줄.
static func default_row(p_db: GameDatabase, p_class: String) -> String:
	return "back" if JsonUtil.get_str(p_db.get_entry("classes", p_class), "role") in BACK_ROLES else "front"


## 종족·템플릿 범위에서 굴린 기본 스탯(bases)으로 캐릭터를 만든다.
static func create(p_db: GameDatabase, p_race: String, p_class: String, p_name: String,
		bases: Dictionary) -> PlayerCharacter:
	var level := int(p_db.bal("char_creation.start_level", 1))
	var pc := PlayerCharacter.new(p_db, bases, level)
	pc.progression.exp_total = Progression.exp_for_level(p_db, level)  # 시작 레벨만큼의 경험치(첫 경험치에 레벨이 내려가지 않게)
	pc.id = "player"
	pc.race_id = p_race
	pc.class_id = p_class
	pc.display_name = p_name
	var cls := p_db.get_entry("classes", p_class)
	for item: Variant in JsonUtil.get_array(cls, "start_equipment"):
		var id := str(item)
		var slot := pc.equipment.pick_slot(id)
		if not slot.is_empty():
			pc.equipment.equip(pc.stats, id, slot)
	for item: Variant in JsonUtil.get_array(cls, "start_items"):
		if item is Dictionary:
			pc.inventory.add(JsonUtil.get_str(item, "id"), JsonUtil.get_int(item, "count", 1))
	pc.inventory.add_money(int(p_db.bal("char_creation.start_stones", 0)))
	pc.pool.fill_all()  # 장비 수정자로 최대치가 바뀌었을 수 있다
	pc.fatigue.changed.connect(pc._on_fatigue_changed)
	pc.fatigue.setup(JsonUtil.get_dict(p_db.singletons.get("city", {}), "fatigue"))
	grant_innate_skills(pc)
	return pc


## 피로도 단계 효과(수정자 출처 "fatigue")를 지금 값에 맞춰 다시 붙인다.
func _on_fatigue_changed(_value: float, _delta: float, _source: String) -> void:
	var worse := fatigue.tier_level() > _fatigue_tier_level
	_fatigue_tier_level = fatigue.tier_level()
	if worse and not fatigue.tier_id().is_empty():
		condition_notice.emit(fatigue.tier_id())  # 피로 단계가 올랐다(내려갈 땐 알리지 않는다)
	stats.remove_source(FATIGUE_SOURCE)
	var mods := fatigue.effects()
	if not mods.is_empty():
		stats.add_modifiers_from_data(FATIGUE_SOURCE, mods)


## 레벨을 바꾸면 정수 슬롯 잠금도 맞춘다(레벨 하락 = 무작위 잠금, 상승 = 해제).
func set_level(level: int) -> void:
	change_level(level, essence_rng)


func change_level(level: int, rng: Rng = null) -> void:
	super.set_level(level)
	if essences != null:
		essences.sync_slots(self, rng if rng != null else essence_rng)


## 모든 아군(플레이어·동료)이 시작부터 가진 기본 스킬(balance party.innate_skills: 대화·조사)을 준다.
## 이미 있으면 건너뛰므로 불러오기(M4 저장) 뒤에 다시 불러도 안전하다. 동료 생성(M4)도 이 함수를 부른다.
static func grant_innate_skills(a: Actor) -> void:
	for id: Variant in a.db.bal("party.innate_skills", []):
		if a.db.has_entry("skills", str(id)):
			a.learn_skill(str(id))


func race_name() -> String:
	return JsonUtil.get_str(db.get_entry("races", race_id), "name_ko", race_id)


func template_name() -> String:
	return JsonUtil.get_str(db.get_entry("classes", class_id), "name_ko", class_id)


func base_attack_type() -> String:
	return JsonUtil.get_str(db.get_entry("classes", class_id), "attack_type", "blunt")


## 저장용(저장 시스템이 생기면 쓴다): 성장·정보·장비·가방·정수·피로도·활동 능력치 기록.
func progress_to_dict() -> Dictionary:
	return {"progression": progression.to_dict(), "knowledge": knowledge.to_dict(),
		"equipment": equipment.to_dict(), "inventory": inventory.to_dict(),
		"essences": essences.to_dict(), "boons": boons.duplicate(), "base_stats": _boosted_bases(),
		"fatigue": fatigue.to_dict(), "stat_history": stat_history.duplicate(true)}


func progress_load_dict(d: Dictionary) -> void:
	progression.load_dict(JsonUtil.get_dict(d, "progression"))
	knowledge.load_dict(JsonUtil.get_dict(d, "knowledge"))
	equipment.load_dict(stats, JsonUtil.get_dict(d, "equipment"))
	inventory.load_dict(JsonUtil.get_dict(d, "inventory"))
	essences.load_dict(self, JsonUtil.get_dict(d, "essences"))
	boons = JsonUtil.get_dict(d, "boons").duplicate()
	fatigue.load_dict(JsonUtil.get_dict(d, "fatigue"))
	_on_fatigue_changed(fatigue.value, 0.0, "load")
	stat_history.clear()
	for h: Variant in JsonUtil.get_array(d, "stat_history"):
		if h is Dictionary:
			stat_history.append(h)
	var bases := JsonUtil.get_dict(d, "base_stats")
	for k: String in bases:
		if stats.has_stat(k):
			stats.set_base(k, float(bases[k]))
	change_level(Progression.level_for(db, progression.exp_total))  # 레벨(자원 최대치)과 정수 슬롯 잠금을 경험치에 맞춘다


## 기본 스탯 전부(캐릭터 생성 때 굴린 값 + 영약으로 오른 값) — 저장용.
func _boosted_bases() -> Dictionary:
	var out := {}
	for k in stats.ids():
		out[k] = stats.get_base(k)
	return out
