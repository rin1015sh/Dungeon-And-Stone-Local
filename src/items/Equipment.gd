class_name Equipment
extends RefCounted
## 장비 칸(스톤샤드식 장비 인형): 주무기·보조·머리·몸·망토·장갑·허리·신발·반지 2·목걸이.
## 아이템 equip.slot이 칸을 정한다("ring"은 왼쪽/오른쪽 반지 중 빈 곳). 양손 무기는 보조 칸도 막는다.
## 장착하면 equip.modifiers를 "equip:<칸>" 출처로 스탯에 붙이고, 벗으면 뗀다.
## 개체(Actor)를 필드로 들지 않는다(Actor가 이 객체를 가지므로 순환 참조 방지) — 스탯을 인자로 받는다.

signal changed(slot: String)

const SLOTS: Array[String] = ["main_hand", "off_hand", "head", "body", "cloak", "hands", "waist", "feet",
	"ring_l", "ring_r", "neck"]

var _db: GameDatabase
var _slots: Dictionary = {}  # 칸 -> 아이템 id


func _init(db: GameDatabase = null) -> void:
	_db = db


func item_in(slot: String) -> String:
	return str(_slots.get(slot, ""))


func is_empty(slot: String) -> bool:
	return item_in(slot).is_empty()


## 보조 칸이 양손 무기로 막혀 있는가.
func off_hand_blocked() -> bool:
	return not is_empty("main_hand") and ItemInfo.two_handed(_db, item_in("main_hand"))


## 아이템이 들어갈 수 있는 칸 목록(데이터 slot 기준).
func slots_for(item_id: String) -> Array[String]:
	var s := ItemInfo.slot(_db, item_id)
	var out: Array[String] = []
	if s == "ring":
		out.assign(["ring_l", "ring_r"])
	elif SLOTS.has(s):
		out.append(s)
	return out


## 장착할 칸: slot을 지정하지 않으면 빈 칸을 먼저, 없으면 첫 칸.
func pick_slot(item_id: String, slot: String = "") -> String:
	var cands := slots_for(item_id)
	if not slot.is_empty():
		return slot if cands.has(slot) else ""
	for c in cands:
		if is_empty(c):
			return c
	return cands[0] if not cands.is_empty() else ""


## 장착하면 빠져야 하는 아이템 칸들(같은 칸 + 양손 규칙).
func displaced_by(item_id: String, slot: String) -> Array[String]:
	var out: Array[String] = []
	if not is_empty(slot):
		out.append(slot)
	if slot == "main_hand" and ItemInfo.two_handed(_db, item_id) and not is_empty("off_hand"):
		out.append("off_hand")
	if slot == "off_hand" and off_hand_blocked():
		out.append("main_hand")
	return out


## 장착한다. 빠진 아이템 id 목록을 돌려준다(가방에 넣는 것은 호출하는 쪽 몫). 칸이 맞지 않으면 null 대신 빈 목록 + false는 can_equip으로 먼저 확인.
func equip(stats: StatBlock, item_id: String, slot: String) -> Array[String]:
	var removed: Array[String] = []
	for s in displaced_by(item_id, slot):
		removed.append(unequip(stats, s))
	_slots[slot] = item_id
	stats.add_modifiers_from_data("equip:" + slot, JsonUtil.get_array(ItemInfo.equip(_db, item_id), "modifiers"))
	changed.emit(slot)
	return removed


func can_equip(item_id: String, slot: String) -> bool:
	return slots_for(item_id).has(slot)


## 벗는다. 벗은 아이템 id(없으면 "").
func unequip(stats: StatBlock, slot: String) -> String:
	var id := item_in(slot)
	if id.is_empty():
		return ""
	_slots.erase(slot)
	stats.remove_source("equip:" + slot)
	changed.emit(slot)
	return id


## 주무기 정보 {damage_type, attack}. 맨손이면 {}.
func weapon() -> Dictionary:
	return ItemInfo.weapon(_db, item_in("main_hand"))


func equipped_ids() -> Array[String]:
	var out: Array[String] = []
	for s in SLOTS:
		if not is_empty(s):
			out.append(item_in(s))
	return out


func to_dict() -> Dictionary:
	return _slots.duplicate()


## 저장된 장비를 다시 입힌다(수정자도 다시 붙인다).
func load_dict(stats: StatBlock, d: Dictionary) -> void:
	for s: String in _slots.keys():
		unequip(stats, s)
	for s: String in d:
		if SLOTS.has(s) and _db != null and _db.has_entry("items", str(d[s])):
			equip(stats, str(d[s]), s)
