class_name StatusTips
extends RefCounted
## 상태이상 설명 한 줄("[이름] 설명") — 하단 바·전투 카드의 마우스 설명에 쓴다(statuses.json desc_ko).


static func line(db: GameDatabase, status_id: String) -> String:
	var d := db.get_entry("statuses", status_id)
	var desc := JsonUtil.get_str(d, "desc_ko")
	var name := "[%s]" % DataNames.entry(db, "statuses", status_id)
	return name if desc.is_empty() else "%s %s" % [name, desc]


static func lines(db: GameDatabase, ids: Array[String]) -> String:
	var out := PackedStringArray()
	for id in ids:
		out.append(line(db, id))
	return "\n".join(out)
