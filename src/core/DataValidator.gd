class_name DataValidator
extends ValidatorBase
## data/ 스키마·참조 무결성 검사기. errors가 비어 있어야 통과.
## tools/validate_data.gd, tests/, DataRegistry가 같은 검사기를 쓴다(ContentRegistries.make_validator()).
## 규칙은 그룹별 파일: CoreRules(스탯·자원·상태이상·부상·종족·템플릿), ContentRules(몬스터·스킬·정수·아이템),
## WorldRules(타일·랜드마크·층·입력).

const REQUIRED_SINGLETONS := ["balance", "render", "tags", "input"]


func validate(p_db: GameDatabase) -> bool:
	db = p_db
	errors.clear()
	warnings.clear()
	_skipped_effect_types = false
	errors.append_array(db.load_errors)
	for s: String in REQUIRED_SINGLETONS:
		if (db.singletons.get(s, {}) as Dictionary).is_empty():
			err("singletons", "필수 파일 '%s'이(가) 비었거나 없다" % s)
	CoreRules.run(self)
	ContentRules.run(self)
	BossRules.run(self)
	WorldRules.run(self)
	_check_common_fields()
	if _skipped_effect_types:
		warnings.append("일부 효과 타입(전투용)의 핸들러가 아직 없어 검사를 건너뛰었다 — M2에서 연결")
	return errors.is_empty()


## 모든 컬렉션 공통: name_ko 권장, sprite 경로 형식. 스프라이트 파일이 없으면 경고 한 줄로 모은다.
func _check_common_fields() -> void:
	var missing_sprites := 0
	for col: String in db.collections:
		var list: Dictionary = db.collections[col]
		for id: String in list:
			var e: Dictionary = list[id]
			if not e.has("name_ko"):
				warn(col + "/" + id, "name_ko 없음")
			if e.has("sprite"):
				var sp := JsonUtil.get_str(e, "sprite")
				if not sp.begins_with("res://"):
					err(col + "/" + id, "sprite는 res:// 경로여야 한다")
				elif not ResourceLoader.exists(sp):
					missing_sprites += 1
	if missing_sprites > 0:
		warnings.append("스프라이트 파일 없음 %d개 — 임시 그래픽으로 표시된다" % missing_sprites)
