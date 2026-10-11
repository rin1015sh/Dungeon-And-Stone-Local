class_name InventoryWindow
extends GothicWindow
## 소지품 창(스톤샤드식): 장비 인형 · [정렬] · 스톤 · 격자 가방.
## 오른쪽 클릭/두 번 클릭: 장비면 장착, 쓸 수 있으면 사용(use_requested — 탐험 규칙이 처리).
## 끌어놓기: 가방 ↔ 장비 칸, 가방 안 옮기기·쌓기, 단축칸에 끌어 등록(BottomBar).

signal use_requested(item_id: String)

var actor: Actor
var grid: InventoryGrid
var doll: PaperDoll

var _money: Label
var _stats: Label


func _init() -> void:
	super(Strings.t("inventory.title"))


func setup(p_actor: Actor) -> void:
	actor = p_actor
	custom_minimum_size.x = UiTheme.metric("inv_window_width", 432)
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
	var sort := UiTheme.button(Strings.t("inventory.sort"), _sort)
	sort.focus_mode = Control.FOCUS_NONE
	bar.add_child(sort)
	_stats = UiTheme.label("", "small", "text_dim")
	_stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	grid.activated.connect(_activate)
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
	grid.queue_redraw()


## 가방 자리 i: 장비면 장착, 아니면 사용 요청.
func _activate(i: int) -> void:
	var id := str(actor.inventory.stacks()[i]["id"])
	if not ItemInfo.equip(actor.db, id).is_empty():
		InventoryActions.equip_stack(actor, i)
	elif not JsonUtil.get_array(ItemInfo.def(actor.db, id), "use_effects").is_empty():
		use_requested.emit(id)
	refresh()


## 정렬: 큰 아이템부터 왼쪽 위로 다시 놓는다.
func _sort() -> void:
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
