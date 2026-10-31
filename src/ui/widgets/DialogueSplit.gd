class_name DialogueSplit
extends RefCounted
## 대화창 한 쪽 = 한 문장(사용자 결정 2026-10-31 "대화 로그는 한 번에 한 문장만 — 앞으로도 항상", UI44).
## 글을 문장으로 나눈다: 줄바꿈마다, 줄 안에서는 마침표·물음표·느낌표·말줄임표(닫는 따옴표·괄호까지) 뒤 빈칸에서.
## 책 제목처럼 『…』·「…」만 있는 줄은 다음 문장과 같은 쪽에 붙인다(제목만 홀로 한 쪽이 되지 않게).

const _END := "[.!?…。]+[\"'」』”’)\\]]*"

static var _re: RegEx = null


static func sentences(text: String) -> PackedStringArray:
	if _re == null:
		_re = RegEx.create_from_string(_END + "\\s+")
	var out := PackedStringArray()
	var head := ""
	for raw in text.split("\n"):
		var line := raw.strip_edges()
		if line.is_empty():
			continue
		if _is_title(line):
			head = line if head.is_empty() else head + "\n" + line
			continue
		var from := 0
		for m in _re.search_all(line):
			_push(out, line.substr(from, m.get_end() - from).strip_edges(), head)
			head = ""
			from = m.get_end()
		_push(out, line.substr(from).strip_edges(), head)
		head = ""
	if not head.is_empty():
		out.append(head)
	return out


static func _push(out: PackedStringArray, s: String, head: String) -> void:
	if s.is_empty():
		return
	out.append(s if head.is_empty() else head + "\n" + s)


static func _is_title(line: String) -> bool:
	return (line.begins_with("『") and line.ends_with("』")) or (line.begins_with("「") and line.ends_with("」"))
