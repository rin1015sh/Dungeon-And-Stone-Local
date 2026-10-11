class_name InventoryActions
extends RefCounted
## 가방(Inventory) ↔ 장비(Equipment) 사이 옮기기. 빠진 장비는 가방 빈 자리로 들어가고,
## 자리가 없으면 아무것도 바꾸지 않고 실패한다(아이템을 잃지 않는다).


## 가방 자리 i의 아이템을 장착한다. slot을 비우면 알맞은 칸. 성공하면 true.
static func equip_stack(a: Actor, i: int, slot: String = "") -> bool:
	var inv := a.inventory
	if i < 0 or i >= inv.stacks().size():
		return false
	var id := str(inv.stacks()[i]["id"])
	var target := a.equipment.pick_slot(id, slot)
	if target.is_empty():
		return false
	# 빠질 장비가 가방에 들어갈 자리가 있는지 미리 본다(장착할 아이템이 빠진 뒤의 가방 기준).
	var probe := Inventory.new(a.db, inv.width, inv.height)
	probe.load_dict(inv.to_dict())
	probe.remove(id, 1)
	for s in a.equipment.displaced_by(id, target):
		if probe.add(a.equipment.item_in(s), 1) != 1:
			return false
	if int(inv.stacks()[i]["count"]) > 1:
		inv.remove(id, 1)
	else:
		inv.take_stack(i)
	for old in a.equipment.equip(a.stats, id, target):
		inv.add(old, 1)
	return true


## 장비 칸 slot을 벗어 가방에 넣는다. pos가 있으면 그 자리에. 성공하면 true.
static func unequip_to_bag(a: Actor, slot: String, pos: Vector2i = Vector2i(-1, -1)) -> bool:
	var id := a.equipment.item_in(slot)
	if id.is_empty():
		return false
	if pos.x >= 0:
		if not a.inventory.can_place(id, pos):
			return false
		a.equipment.unequip(a.stats, slot)
		return a.inventory.place(id, 1, pos)
	if not a.inventory.fits(id, 1):
		return false
	a.equipment.unequip(a.stats, slot)
	a.inventory.add(id, 1)
	return true
