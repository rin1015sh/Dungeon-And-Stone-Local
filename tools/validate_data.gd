extends SceneTree
## 데이터 검증 CLI(스키마·참조 무결성).
##   godot --headless --path . --script res://tools/validate_data.gd
## 오류가 있으면 종료 코드 1.


func _initialize() -> void:
	var db := GameDatabase.new()
	db.load_all("res://data")
	var registries := ContentRegistries.new()
	var v := registries.make_validator()
	v.validate(db)
	v.errors.append_array(Strings.load_locale())
	print("데이터 검증 — %s" % db.root_path)
	for col: String in db.collections:
		print("  %-11s %d" % [col, db.get_collection(col).size()])
	print("  효과 타입: %s" % ", ".join(registries.effects.types()))
	print("  층 생성기: %s" % ", ".join(registries.generators.ids()))
	for w: String in v.warnings:
		print("  경고: " + w)
	for e: String in v.errors:
		print("  오류: " + e)
	print("결과: %s (오류 %d, 경고 %d)" % ["통과" if v.errors.is_empty() else "실패", v.errors.size(), v.warnings.size()])
	quit(0 if v.errors.is_empty() else 1)
