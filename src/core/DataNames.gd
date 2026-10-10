class_name DataNames
extends RefCounted
## 데이터 항목의 표시 이름(name_ko) 찾기. 없으면 id를 그대로 돌려준다.


## 컬렉션 항목의 이름. 예: DataNames.entry(db, "items", "torch") → "횃불"
static func entry(db: GameDatabase, col: String, id: String) -> String:
	return JsonUtil.get_str(db.get_entry(col, id), "name_ko", id)


## tags.json 목록 항목의 이름. 예: DataNames.tag(db, "directions", "east") → "동쪽"
static func tag(db: GameDatabase, list_name: String, id: String) -> String:
	for item: Variant in JsonUtil.get_array(db.tags, list_name):
		if item is Dictionary and JsonUtil.get_str(item, "id") == id:
			return JsonUtil.get_str(item, "name_ko", id)
	return id
