extends SceneTree
## 게임 글 ↔ md: data/strings/ko.json(화면·대화창·기록에 나오는 글 전부)을 docs/STRINGS.md로 쓰고(--export, 기본), 고친 md를 ko.json에 되돌린다(--apply).
##   godot --headless --path . --script res://tools/strings_md.gd -- [--export | --apply] [--md=res://docs/STRINGS.md]
## md 한 줄 = "- `키` 글" — 키는 그대로 두고 글만 고친다. 적용은 ko.json에 이미 있는 키만 바꾼다(새 키·지운 줄은 무시하고 알린다 — 키는 코드가 부른다).
## 묶음 이름·설명(SECTIONS)과 JSON의 "_comment"는 읽기용이라 적용하지 않는다.

const KO := "res://data/strings/ko.json"
const LINE := "- `%s` %s"
## 맨 위 묶음 → [이름, 어디에 나오는가].
const SECTIONS := {
	"app": ["앱", "타이틀 화면 제목·부제"],
	"target_kind": ["대상 종류", "스킬 설명의 대상(적 하나·적 전체 …)"],
	"menu": ["메뉴", "타이틀 메뉴 · 공용 버튼(돌아가기·쪽수)"],
	"error": ["오류", "데이터 검증 실패 화면"],
	"foundation": ["기반 점검", "타이틀의 기반 점검 화면(개발용)"],
	"collection": ["데이터 묶음 이름", "기반 점검·검증에서 묶음 이름"],
	"stat_group": ["스탯 묶음", "스탯 묶음 제목(육체·정신 …)"],
	"log": ["기록", "기록 창 · 일반 알림(피해·영혼력 …)"],
	"create": ["캐릭터 만들기", "새 게임 — 종족·이름·능력치"],
	"explore": ["탐험", "미궁 화면 — HUD · 대화창 알림(경고·발견·못 하는 이유)"],
	"effect": ["효과", "아이템·스킬 효과 결과 알림"],
	"debug": ["디버그", "F1 디버그 패널"],
	"end": ["귀환·결과 화면", "미궁에서 돌아올 때"],
	"pause": ["일시정지", "Esc 정지 창"],
	"cause": ["사인", "결과 화면의 사망 원인"],
	"combat": ["전투", "전투 화면 — 명령 · 대화창 안내 · 보스 대사 · 전투 기록"],
	"knowledge": ["지식", "몬스터 약점·저항(전투에서 알게 될 때 · 도감)"],
	"reward": ["보상", "전투 드롭 · 획득할까? · 경험치"],
	"inventory": ["소지품", "Tab 메뉴 소지품 쪽"],
	"character": ["캐릭터", "Tab 메뉴 캐릭터 쪽"],
	"bestiary": ["도감", "Tab 메뉴 도감 쪽"],
	"bottom": ["아래 막대", "탐험 화면 아래 막대"],
	"essence": ["정수", "정수 칸·설명"],
	"riddle": ["수수께끼", "강철의 묘 수수께끼 창"],
	"plaza": ["차원광장", "도시 → 미궁 포탈 화면 버튼"],
	"city": ["도시", "도시 — 거리·시설·활동 결과(lines)·거리 사건(street)·세금"],
	"field": ["동굴 요소", "1층 동굴 요소를 살필 때(번호가 여럿이면 하나를 고른다)"],
}

var _args: Dictionary = {"md": "res://docs/STRINGS.md"}


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else "true"
	var ko := JSON.parse_string(FileAccess.get_file_as_string(KO)) as Dictionary
	if ko == null:
		print("ko.json을 읽지 못했다")
		quit(1)
		return
	quit(_apply(ko) if _args.has("apply") else _export(ko))


func _export(ko: Dictionary) -> int:
	var out := PackedStringArray([
		"# 게임 글 (`data/strings/ko.json`)",
		"",
		"> 게임 화면·대화창·기록에 나오는 글 전부(%d줄). **이 파일을 고친 뒤 적용하면 게임에 들어간다.**" % _count(ko),
		"> - 한 줄 = ``- `키` 글``. **키(`` ` `` 안)는 바꾸지 말고 뒤의 글만** 고친다. 줄을 지우거나 새 키를 쓰면 무시된다(키는 코드가 부른다).",
		"> - `{이름}`은 자리표시자(게임이 값으로 바꿔 넣는다 — 그대로 둔다). 번호 키(`.1` `.2` …)가 여럿이면 차례로 모두 나오거나(장면) 하나를 고른다(묶음 설명 참고).",
		"> - 적용: `godot --headless --path . --script res://tools/strings_md.gd -- --apply` → `data/strings/ko.json`이 바뀐다(그 뒤 `tools/check.sh`).",
		"> - 다시 만들기(ko.json → 이 파일): `godot --headless --path . --script res://tools/strings_md.gd`. 코드가 글을 바꾸면 이 파일은 낡는다 — 고치기 전에 다시 만든다.",
		"> - 이 파일 밖의 글: 데이터 이름(`name_ko` — 각 `data/*.json`), 수수께끼 문제(`data/riddles`), 소문·정보(`data/city_info`).",
		"",
		"## 차례",
		"",
	])
	for k: String in ko:
		if not k.begins_with("_"):
			out.append("- [%s `%s`](#%s) — %s" % [_title(k), k, k, _where(k)])
	for k: String in ko:
		if k.begins_with("_"):
			continue
		out.append("")
		out.append("<a id=\"%s\"></a>" % k)
		out.append("## %s `%s`" % [_title(k), k])
		out.append("")
		out.append("> " + _where(k))
		_section(ko[k], k, 3, out)
	var f := FileAccess.open(str(_args["md"]), FileAccess.WRITE)
	if f == null:
		print("쓰기 실패: " + str(_args["md"]))
		return 1
	f.store_string("\n".join(out) + "\n")
	print("%s에 %d줄" % [_args["md"], _count(ko)])
	return 0


## 묶음 하나: 바로 아래 글 줄 먼저, 하위 묶음은 제목(### …)으로. 아주 깊은 묶음은 제목 없이 이어 쓴다.
func _section(node: Variant, path: String, depth: int, out: PackedStringArray) -> void:
	if not node is Dictionary:
		out.append(LINE % [path, str(node)])
		return
	var d: Dictionary = node
	if d.has("_comment"):
		out.append("")
		out.append("> " + str(d["_comment"]))
	var leaves := false
	for k: String in d:
		if not k.begins_with("_") and not d[k] is Dictionary:
			if not leaves:
				out.append("")
				leaves = true
			out.append(LINE % [path + "." + k, str(d[k])])
	for k: String in d:
		if k.begins_with("_") or not d[k] is Dictionary:
			continue
		if depth <= 4:
			out.append("")
			out.append("%s `%s`" % ["#".repeat(depth), path + "." + k])
		_section(d[k], path + "." + k, depth + 1, out)


func _apply(ko: Dictionary) -> int:
	var md := FileAccess.get_file_as_string(str(_args["md"]))
	if md.is_empty():
		print("md를 읽지 못했다: " + str(_args["md"]))
		return 1
	var re := RegEx.create_from_string("^- `([^`]+)` ?(.*)$")
	var changed := 0
	var seen := {}
	var unknown := PackedStringArray()
	for line in md.split("\n"):
		var m := re.search(line.trim_suffix("\r"))
		if m == null:
			continue
		var key := m.get_string(1)
		var text := m.get_string(2)
		seen[key] = true
		var parts := key.split(".")
		var node: Variant = ko
		for i in parts.size() - 1:
			node = (node as Dictionary).get(parts[i]) if node is Dictionary else null
		if not node is Dictionary or not (node as Dictionary).has(parts[-1]) or (node as Dictionary)[parts[-1]] is Dictionary:
			unknown.append(key)
			continue
		if str(node[parts[-1]]) != text:
			node[parts[-1]] = text
			changed += 1
	var missing := _count(ko) - _known(ko, "", seen)
	if not unknown.is_empty():
		print("ko.json에 없는 키(무시): " + ", ".join(unknown))
	if missing > 0:
		print("md에 없는 키 %d개는 그대로 둔다(md가 낡았으면 다시 만든다)" % missing)
	if changed == 0:
		print("바뀐 글 없음")
		return 0
	var f := FileAccess.open(KO, FileAccess.WRITE)
	if f == null:
		print("쓰기 실패: " + KO)
		return 1
	f.store_string(JSON.stringify(ko, "  ", false) + "\n")
	print("글 %d줄을 ko.json에 적용했다" % changed)
	return 0


func _count(node: Variant) -> int:
	if not node is Dictionary:
		return 1
	var n := 0
	for k: String in node:
		if not k.begins_with("_"):
			n += _count(node[k])
	return n


func _known(node: Variant, path: String, seen: Dictionary) -> int:
	if not node is Dictionary:
		return 1 if seen.has(path) else 0
	var n := 0
	for k: String in node:
		if not k.begins_with("_"):
			n += _known(node[k], k if path.is_empty() else path + "." + k, seen)
	return n


func _title(k: String) -> String:
	return str((SECTIONS.get(k, [k, ""]) as Array)[0])


func _where(k: String) -> String:
	return str((SECTIONS.get(k, ["", "—"]) as Array)[1])
