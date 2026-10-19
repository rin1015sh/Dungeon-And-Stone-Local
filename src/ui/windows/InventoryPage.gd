class_name InventoryPage
extends MenuPage
## Tab 메뉴의 소지품 쪽(스톤샤드식): 장비 인형 · [정렬] · 공격·스톤 · 격자 가방. 키로만 다룬다(사용자 결정 2026-10-19).
##   W/A/S/D = 커서(장비 칸 · 정렬 · 가방 칸 — 아이템은 크기만큼 한 칸), 커서가 놓인 아이템의 설명은 쪽 옆에 뜬다(장착품과 비교).
##   Enter: 가방 아이템 → 장착/사용 · 옮기기 · 단축칸에 두기/빼기 · 버리기 / 장비 칸 → 벗기(비었으면 가방에서 낄 것 고르기) / 정렬.
##   옮기기: 커서가 놓을 자리(초록 = 놓을 수 있음) — Enter = 놓기(같은 아이템 위면 쌓기), Backspace = 그만두기.
## 장착·벗기가 가방 자리 때문에 안 되면 알림(EventBus.notice).

signal use_requested(item_id: String)

var actor: Actor
var grid: InventoryGrid
var doll: PaperDoll

var _money: Label
var _stats: Label
var _sort: PanelContainer
var _cursor: Dictionary = {"kind": "cell", "cell": Vector2i.ZERO}  # kind: slot(slot) / sort / cell(cell)
var _carry: Dictionary = {}  # 옮기는 중인 묶음(InventoryGrid 옮기기 데이터)
var _tip: Control = null
var _asking: bool = false  # 작은 선택 창이 떠 있다(GameMenu가 키를 넘기지 않는다)


func _init() -> void:
	super(Strings.t("inventory.title"))


func setup(p_actor: Actor) -> void:
	actor = p_actor
	custom_minimum_size.x = MenuPage.cfg("inventory_width", 420.0)
	var doll_box := PanelContainer.new()
	doll_box.add_theme_stylebox_override("panel", GothicStyle.inset_box())
	content.add_child(doll_box)
	var center := CenterContainer.new()
	doll_box.add_child(center)
	doll = PaperDoll.new()
	doll.setup(actor)
	center.add_child(doll)
	var bar := HBoxContainer.new()
	content.add_child(bar)
	_sort = PanelContainer.new()
	_sort.add_child(UiTheme.label(Strings.t("inventory.sort"), "small", "text"))
	bar.add_child(_sort)
	_stats = UiTheme.label("", "small", "text_dim")
	_stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stats.clip_text = true
	bar.add_child(_stats)
	_money = UiTheme.label("", "body", "gold")
	bar.add_child(_money)
	var grid_box := PanelContainer.new()
	grid_box.add_theme_stylebox_override("panel", GothicStyle.inset_box())
	content.add_child(grid_box)
	var gc := CenterContainer.new()
	grid_box.add_child(gc)
	grid = InventoryGrid.new()
	grid.setup(actor)
	gc.add_child(grid)
	actor.inventory.money_changed.connect(func(_m: int) -> void: refresh())
	actor.equipment.changed.connect(func(_s: String) -> void: refresh())
	refresh()


func refresh() -> void:
	_money.text = Strings.t("inventory.money", {"amount": actor.inventory.money})
	_stats.text = Strings.t("inventory.summary", {
		"attack": roundi(DamageCalc.attack_power(actor.db, actor, {"scaling": "phys"})),
		"type": DataNames.tag(actor.db, "damage_types", actor.attack_damage_type()),
		"p_res": roundi(actor.stats.get_value("p_res"))})
	_fix_cursor()
	_show_cursor()


func busy() -> bool:
	return _asking


func carrying() -> bool:
	return not _carry.is_empty()


func cursor() -> Dictionary:
	return _cursor


## 커서를 가방 칸 c로(테스트도 쓴다).
func cursor_to_cell(c: Vector2i) -> void:
	_cursor = {"kind": "cell", "cell": c}
	_show_cursor()


func cursor_to_slot(slot: String) -> void:
	_cursor = {"kind": "slot", "slot": slot}
	_show_cursor()


func on_active(on: bool) -> void:
	if grid != null:
		_show_cursor()
	if not on:
		_set_tip(null)


func enter(from_left: bool) -> void:
	_cursor = {"kind": "cell", "cell": Vector2i(0 if from_left else actor.inventory.width - 1, 0)}
	_fix_cursor()
	_show_cursor()


func nav(d: Vector2i) -> bool:
	var targets := _targets()
	var rects: Array[Rect2] = []
	for t: Dictionary in targets:
		rects.append(t["rect"])
	var i := MenuPage.nearest(rects, _rect_of(_cursor), d)
	if i < 0:
		return d.x == 0 or carrying()  # 위아래는 끝에서 멈추고, 좌우 끝이면 옆 쪽으로(옮기는 중엔 멈춤)
	_cursor = targets[i]["at"]
	_show_cursor()
	return true


func confirm() -> void:
	if carrying():
		_place()
		return
	match str(_cursor["kind"]):
		"sort":
			sort()
		"slot":
			_slot_menu(str(_cursor["slot"]))
		"cell":
			var i := actor.inventory.stack_at(_cursor["cell"])
			if i >= 0:
				_item_menu(i)


func back() -> bool:
	if not carrying():
		return false
	_carry = {}
	grid.set_preview({}, Vector2i.ZERO)
	_show_cursor()
	return true


## 정렬: 큰 아이템부터 왼쪽 위로 다시 놓는다.
func sort() -> void:
	var items: Array[Dictionary] = []
	for s in actor.inventory.stacks():
		items.append({"id": s["id"], "count": s["count"]})
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var sa := ItemInfo.size(actor.db, a["id"])
		var sb := ItemInfo.size(actor.db, b["id"])
		return sa.x * sa.y > sb.x * sb.y if sa.x * sa.y != sb.x * sb.y else str(a["id"]) < str(b["id"]))
	var saved := actor.inventory.to_dict()
	actor.inventory.load_dict({"w": actor.inventory.width, "h": actor.inventory.height, "money": actor.inventory.money})
	for it in items:
		if actor.inventory.add(str(it["id"]), int(it["count"])) < int(it["count"]):
			actor.inventory.load_dict(saved)  # 다시 놓을 수 없으면 원래대로
			break
	refresh()


## 가방 자리 i: 장비면 장착, 아니면 사용 요청(테스트도 쓴다).
func activate(i: int) -> void:
	var id := str(actor.inventory.stacks()[i]["id"])
	if not ItemInfo.equip(actor.db, id).is_empty():
		if not InventoryActions.equip_stack(actor, i):
			EventBus.notice.emit("inventory.no_room_swap", {"item": DataNames.entry(actor.db, "items", id)}, "warn")
	elif _usable(id):
		use_requested.emit(id)
	refresh()


## 가방 자리 i의 묶음을 통째로 버린다(테스트도 쓴다). 버렸으면 true.
func discard(i: int) -> bool:
	if i < 0 or i >= actor.inventory.stacks().size():
		return false
	var st := actor.inventory.take_stack(i)
	EventBus.notice.emit("inventory.discarded", {"item": DataNames.entry(actor.db, "items", str(st.get("id", ""))),
		"count": int(st.get("count", 1))}, "warn")
	refresh()
	return true


## 가방 자리 i를 옮기기 시작한다(커서가 놓을 자리가 된다).
func carry(i: int) -> void:
	var s: Dictionary = actor.inventory.stacks()[i]
	_carry = {"type": "item", "from": "grid", "index": i, "id": str(s["id"])}
	_cursor = {"kind": "cell", "cell": Vector2i(s["pos"])}
	_show_cursor()


func _place() -> void:
	if grid.drop(_carry, _cursor["cell"]):
		_carry = {}
		refresh()


func _usable(id: String) -> bool:
	return not JsonUtil.get_array(ItemInfo.def(actor.db, id), "use_effects").is_empty()


## 가방 아이템에 할 일 고르기.
func _item_menu(i: int) -> void:
	var id := str(actor.inventory.stacks()[i]["id"])
	var acts: Array[String] = []
	if not ItemInfo.equip(actor.db, id).is_empty():
		acts.append("equip")
	elif _usable(id):
		acts.append("use")
	acts.append("move")
	if _usable(id):
		acts.append("hotbar")
	if (actor as PlayerCharacter) != null and id in (actor as PlayerCharacter).hotbar:
		acts.append("hotbar_remove")
	acts.append("discard")
	var opts: Array[Dictionary] = []
	for a in acts:
		opts.append({"text": Strings.t("inventory.act_" + a)})
	var k := await _ask(DataNames.entry(actor.db, "items", id), opts)
	if k < 0:
		return
	match acts[k]:
		"equip", "use":
			activate(i)
		"move":
			carry(i)
		"hotbar":
			_hotbar_menu(id)
		"hotbar_remove":
			var pc := actor as PlayerCharacter
			for h in pc.hotbar.size():
				if pc.hotbar[h] == id:
					pc.set_hotbar(h, "")
		"discard":
			discard(i)


## 단축칸 고르기(1~0 — 칸마다 지금 든 것).
func _hotbar_menu(id: String) -> void:
	var pc := actor as PlayerCharacter
	if pc == null:
		return
	var opts: Array[Dictionary] = []
	for h in PlayerCharacter.HOTBAR_SIZE:
		var cur: String = pc.hotbar[h] if h < pc.hotbar.size() else ""
		opts.append({"text": InputSetup.key_label("hotbar_%d" % ((h + 1) % 10)),
			"sub": DataNames.entry(actor.db, "items", cur) if not cur.is_empty() else ""})
	var k := await _ask(Strings.t("inventory.act_hotbar"), opts, true)
	if k >= 0:
		pc.set_hotbar(k, id)


## 장비 칸: 끼고 있으면 벗기, 비었으면 가방에서 이 칸에 낄 것 고르기.
func _slot_menu(slot: String) -> void:
	var worn := actor.equipment.item_in(slot)
	if not worn.is_empty():
		var k := await _ask(DataNames.entry(actor.db, "items", worn), [{"text": Strings.t("inventory.act_unequip")}])
		if k == 0:
			if not InventoryActions.unequip_to_bag(actor, slot):
				EventBus.notice.emit("inventory.no_room_unequip", {"item": DataNames.entry(actor.db, "items", worn)}, "warn")
			refresh()
		return
	var fits: Array[int] = []
	var opts: Array[Dictionary] = []
	for i in actor.inventory.stacks().size():
		var id := str(actor.inventory.stacks()[i]["id"])
		if actor.equipment.can_equip(id, slot):
			fits.append(i)
			opts.append({"text": DataNames.entry(actor.db, "items", id)})
	if fits.is_empty():
		return
	var k := await _ask(DataNames.tag(actor.db, "equip_slots", slot), opts)
	if k >= 0:
		if not InventoryActions.equip_stack(actor, fits[k], slot):
			EventBus.notice.emit("inventory.no_room_swap", {"item": opts[k]["text"]}, "warn")
		refresh()


func _ask(title: String, opts: Array[Dictionary], can_back: bool = true) -> int:
	_asking = true
	_set_tip(null)
	var host := popup_host if popup_host != null else self
	var k := await ChoicePopup.ask(host, title, opts, can_back, _cursor_global() - host.global_position)
	_asking = false
	if is_inside_tree():
		_show_cursor()
	return k


## 고를 수 있는 자리: 장비 칸 · 정렬 · 가방(옮기는 중이면 모든 칸, 아니면 아이템 하나 = 한 자리).
func _targets() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not carrying():
		for slot: String in doll.slots:
			out.append({"at": {"kind": "slot", "slot": slot}, "rect": _rect_of({"kind": "slot", "slot": slot})})
		out.append({"at": {"kind": "sort"}, "rect": _rect_of({"kind": "sort"})})
	var seen := {}
	for y in actor.inventory.height:
		for x in actor.inventory.width:
			var c := Vector2i(x, y)
			var r := Rect2i(c, Vector2i.ONE) if carrying() else grid.target_at(c)
			if seen.has(r):
				continue
			seen[r] = true
			out.append({"at": {"kind": "cell", "cell": r.position}, "rect": _cells_rect(r)})
	return out


## 커서 자리의 사각형(이 쪽 기준 좌표).
func _rect_of(at: Dictionary) -> Rect2:
	match str(at.get("kind")):
		"slot":
			var es: Control = doll.slots[str(at["slot"])]
			return Rect2(es.global_position - global_position, es.size)
		"sort":
			return Rect2(_sort.global_position - global_position, _sort.size)
	var c: Vector2i = at.get("cell", Vector2i.ZERO)
	return _cells_rect(Rect2i(c, Vector2i.ONE) if carrying() else grid.target_at(c))


func _cells_rect(r: Rect2i) -> Rect2:
	return Rect2(grid.global_position - global_position + Vector2(r.position * grid.cell), Vector2(r.size * grid.cell))


func _cursor_global() -> Vector2:
	var r := _rect_of(_cursor)
	return global_position + Vector2(r.get_center().x, r.position.y)


## 가방이 바뀌어 커서 칸이 아이템 가운데가 됐으면 그 아이템의 왼쪽 위로.
func _fix_cursor() -> void:
	if str(_cursor["kind"]) == "cell" and not carrying():
		_cursor["cell"] = grid.target_at(_cursor["cell"]).position


func _show_cursor() -> void:
	var on := active and not _asking
	var kind := str(_cursor["kind"])
	doll.set_cursor(str(_cursor["slot"]) if on and kind == "slot" else "")
	_sort.add_theme_stylebox_override("panel", GothicStyle.slot_box("hover" if on and kind == "sort" else ""))
	if carrying():
		var c: Vector2i = _cursor["cell"]
		grid.set_cursor(Rect2i(c, Vector2i.ONE) if on else Rect2i())
		grid.set_preview(_carry, c)
	else:
		grid.set_cursor(grid.target_at(_cursor["cell"]) if on and kind == "cell" else Rect2i())
	_set_tip(_tip_for() if on else null)


## 커서가 놓인 아이템의 설명(가방 아이템은 같은 칸 장착품과 비교).
func _tip_for() -> Control:
	match str(_cursor["kind"]):
		"slot":
			var worn := actor.equipment.item_in(str(_cursor["slot"]))
			return ItemTooltip.panel(actor.db, worn, true) if not worn.is_empty() else null
		"cell":
			var i := actor.inventory.stack_at(_cursor["cell"])
			if carrying():
				return ItemTooltip.panel(actor.db, str(_carry["id"]), false)
			if i >= 0:
				var s: Dictionary = actor.inventory.stacks()[i]
				return ItemTooltip.build(actor.db, str(s["id"]), actor, int(s["count"]))
	return null


## 설명은 쪽 왼쪽 바깥(캐릭터 쪽 위)에 커서 높이로 띄운다. 자리가 없으면 오른쪽.
func _set_tip(tip: Control) -> void:
	if _tip != null:
		_tip.queue_free()
		_tip = null
	if tip == null:
		return
	_tip = tip
	_tip.top_level = true
	_tip.z_index = 10
	add_child(_tip)
	_place_tip.call_deferred()


func _place_tip() -> void:
	if _tip == null or not is_inside_tree():
		return
	var sz := _tip.get_combined_minimum_size()
	_tip.size = sz
	var gap := float(UiTheme.metric("spacing", 8))
	var view := get_viewport_rect().size
	var x := global_position.x - sz.x - gap
	if x < gap:
		x = global_position.x + size.x + gap
	var y := clampf(_cursor_global().y, gap, maxf(gap, view.y - sz.y - gap))
	_tip.global_position = Vector2(x, y)
