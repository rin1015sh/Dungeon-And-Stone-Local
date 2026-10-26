class_name EssenceRemovePanel
extends CityPanel
## 신전 정수 제거 패널: 흡수한 정수 목록 → 고르면 그 칸이 "정말 제거"로 바뀌고 한 번 더 고르면(되돌릴 수 없음) 제거.
## 비용은 기존 정수 삭제 비용(EssenceSet.next_delete_cost).

var _confirm: int = -1


func build() -> void:
	head(Strings.t("city.essence_cost", {"cost": pc.essences.next_delete_cost(state.db), "money": Strings.stones(pc.inventory.money)}))
	if pc.essences.absorbed.is_empty():
		add_child(UiTheme.label(Strings.t("city.essence_none"), "small", "text_dim"))
	choices()


func options() -> Array[Dictionary]:
	var cost := pc.essences.next_delete_cost(state.db)
	var opts: Array[Dictionary] = []
	for i in pc.essences.absorbed.size():
		var inst: Dictionary = pc.essences.absorbed[i]
		var text := Strings.t("city.essence_line", {"name": DataNames.entry(state.db, "essences", JsonUtil.get_str(inst, "essence")),
			"color": DataNames.tag(state.db, "essence_colors", JsonUtil.get_str(inst, "color"))})
		if EssenceSet.is_locked(inst):
			text += Strings.t("city.essence_locked")
		var idx := i
		if _confirm == i:
			opts.append({"text": text, "sub": Strings.t("city.essence_confirm", {"cost": Strings.stones(cost)}), "enabled": pc.inventory.money >= cost,
				"on_pick": func() -> void:
					_confirm = -1
					done(CityTemple.remove_essence(state, pc, activity_id, idx))})
		else:
			opts.append({"text": text, "sub": Strings.t("city.essence_remove"), "on_pick": func() -> void:
				_confirm = idx
				rebuild()})
	return opts
