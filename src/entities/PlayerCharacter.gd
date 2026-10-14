class_name PlayerCharacter
extends Actor
## 플레이어 캐릭터: 종족·시작 템플릿·이름 + 성장(Progression)·정보(Knowledge)·단축칸(hotbar).
## 시작 소지품은 템플릿의 start_items, 시작 장비는 start_equipment(장착된 채로), 시작 돈은 char_creation.start_stones.

const HOTBAR_SIZE := 10

var race_id: String = ""
var class_id: String = ""
var progression: Progression = Progression.new()
var knowledge: Knowledge = Knowledge.new()
var essences: EssenceSet = EssenceSet.new()
## 레벨 하락 때 잠글 정수 슬롯을 고르는 난수(테스트에서 시드를 고정할 수 있다).
var essence_rng: Rng = Rng.new()
## 단축칸 1~0: 아이템 id(빈 칸은 ""). 소지품이 없으면 흐리게 보이고 쓸 수 없다.
var hotbar: Array[String] = []
## 피로도(도시·미궁 공용, 핵심 스탯이 아닌 별도 수치). 규칙은 data/city.json fatigue.
var fatigue: Fatigue = Fatigue.new()
## 활동으로 오른 능력치 기록 [{stat, amount, activity, month, period}] — 도시 독서·훈련(CityEffect stat_chance).
var stat_history: Array[Dictionary] = []


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
	pc.fatigue.setup(JsonUtil.get_dict(p_db.singletons.get("city", {}), "fatigue"))
	grant_innate_skills(pc)
	pc.auto_fill_hotbar()
	return pc


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


## 단축칸 i(0~9)에 아이템을 놓는다(""이면 비운다). 같은 아이템이 다른 칸에 있으면 그 칸은 비운다.
func set_hotbar(i: int, item_id: String) -> void:
	_ensure_hotbar()
	if i < 0 or i >= HOTBAR_SIZE:
		return
	if not item_id.is_empty():
		var old := hotbar.find(item_id)
		if old >= 0:
			hotbar[old] = ""
	hotbar[i] = item_id


## 쓸 수 있는(use_effects가 있는) 소지품을 빈 단축칸에 차례로 놓는다.
func auto_fill_hotbar() -> void:
	_ensure_hotbar()
	for id in inventory.ids():
		if hotbar.has(id) or JsonUtil.get_array(db.get_entry("items", id), "use_effects").is_empty():
			continue
		var free := hotbar.find("")
		if free < 0:
			return
		hotbar[free] = id


func _ensure_hotbar() -> void:
	while hotbar.size() < HOTBAR_SIZE:
		hotbar.append("")


## 저장용(저장 시스템이 생기면 쓴다): 성장·정보·장비·가방·단축칸·정수·피로도·활동 능력치 기록.
func progress_to_dict() -> Dictionary:
	return {"progression": progression.to_dict(), "knowledge": knowledge.to_dict(),
		"equipment": equipment.to_dict(), "inventory": inventory.to_dict(), "hotbar": hotbar.duplicate(),
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
	stat_history.clear()
	for h: Variant in JsonUtil.get_array(d, "stat_history"):
		if h is Dictionary:
			stat_history.append(h)
	var bases := JsonUtil.get_dict(d, "base_stats")
	for k: String in bases:
		if stats.has_stat(k):
			stats.set_base(k, float(bases[k]))
	change_level(Progression.level_for(db, progression.exp_total))  # 레벨(자원 최대치)과 정수 슬롯 잠금을 경험치에 맞춘다
	hotbar.clear()
	for v: Variant in JsonUtil.get_array(d, "hotbar"):
		hotbar.append(str(v))
	_ensure_hotbar()


## 기본 스탯 전부(캐릭터 생성 때 굴린 값 + 영약으로 오른 값) — 저장용.
func _boosted_bases() -> Dictionary:
	var out := {}
	for k in stats.ids():
		out[k] = stats.get_base(k)
	return out
