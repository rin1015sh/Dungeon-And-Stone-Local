class_name DataSummary
extends Label
## 불러온 데이터 현황 한 덩어리: 컬렉션별 항목 수 + 검증 결과. (기반 점검·디버그 패널용)


func _init() -> void:
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_theme_font_size_override("font_size", UiTheme.metric("small_font_size", 14))
	add_theme_color_override("font_color", UiTheme.color("text_dim"))


func show_data(db: GameDatabase, validator: DataValidator) -> void:
	var parts := PackedStringArray()
	for col: String in db.collections:
		parts.append(Strings.t("foundation.data_line", {"name": Strings.t("collection." + col), "count": db.get_collection(col).size()}))
	var verdict := Strings.t("foundation.data_ok")
	if not validator.warnings.is_empty():
		verdict += " · " + Strings.t("foundation.data_warn", {"count": validator.warnings.size()})
	text = " · ".join(parts) + "\n" + verdict
