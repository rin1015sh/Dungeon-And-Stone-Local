class_name EssenceRemovePanel
extends CityPanel
## 신전 정수 제거 패널: 흡수한 정수 목록 → 고르면 한 번 더 확인(되돌릴 수 없음) → 제거.
## 비용은 기존 정수 삭제 비용(EssenceSet.next_delete_cost).

var _confirm: int = -1


func build() -> void:
	var cost := pc.essences.next_delete_cost(state.db)
	add_child(UiTheme.label(Strings.t("city.essence_cost", {"cost": cost, "money": pc.inventory.money}), "body", "text_title"))
	var list := scroll_list(UiTheme.render_float("city.list_height", 92.0))
	if pc.essences.absorbed.is_empty():
		list.add_child(UiTheme.label(Strings.t("city.essence_none"), "small", "text_dim"))
	for i in pc.essences.absorbed.size():
		var inst: Dictionary = pc.essences.absorbed[i]
		var text := Strings.t("city.essence_line", {"name": DataNames.entry(state.db, "essences", JsonUtil.get_str(inst, "essence")),
			"color": DataNames.tag(state.db, "essence_colors", JsonUtil.get_str(inst, "color"))})
		if EssenceSet.is_locked(inst):
			text += Strings.t("city.essence_locked")
		var idx := i
		if _confirm == i:
			row(list, text, Strings.t("city.essence_confirm", {"cost": cost}), func() -> void:
				_confirm = -1
				done(CityTemple.remove_essence(state, pc, activity_id, idx)), pc.inventory.money >= cost)
		else:
			row(list, text, Strings.t("city.essence_remove"), func() -> void:
				_confirm = idx
				rebuild())
	var note := UiTheme.label(Strings.t("city.essence_note"), "small", "text_dim")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(note)
