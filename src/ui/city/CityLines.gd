class_name CityLines
extends RefCounted
## 활동 결과 문구: 메시지 키(city.fx.<결과>, city.spent_stones …)의 마지막 토막을 결과 이름으로 보고,
## 활동별 서술 문구 city.lines.<활동 id>.<결과>.<번호>(1부터)가 있으면 그것을, 없으면 원래 키를 쓴다.
## 활동 데이터 "lines"가 있으면 그 활동 id의 문구를 같이 쓴다(도서관 분야 읽기 = library_read).
## 번호가 여럿이면 날짜·행동력·결과로 정해지는 하나를 고른다(난수를 쓰지 않는다 — 판정 난수 순서를 흐트리지 않게).


## 활동 데이터 "quiet": [결과 이름 …]에 든 결과는 보이지 않는다(도서관 읽기의 정신력·피로 결과 — 사용자 2026-11-01 "정신력 오르는 거랑 눈이 뻑뻑하고 같은 이런 문구 없애").
static func quiet(state: CityState, activity_id: String, msg: Dictionary) -> bool:
	var key := str(msg["key"])
	return JsonUtil.get_array(state.activity(activity_id), "quiet").has(key.get_slice(".", key.get_slice_count(".") - 1))


static func text(state: CityState, activity_id: String, msg: Dictionary) -> String:
	var key := str(msg["key"])
	var outcome := key.get_slice(".", key.get_slice_count(".") - 1)
	var base := "city.lines.%s.%s" % [JsonUtil.get_str(state.activity(activity_id), "lines", activity_id), outcome]
	var n := 0
	while Strings.has("%s.%d" % [base, n + 1]):
		n += 1
	if n == 0:
		return Strings.t(key, msg["args"])
	var pick := absi(hash([activity_id, outcome, state.month, state.period, state.ap, state.known_info.size()])) % n
	return Strings.t("%s.%d" % [base, pick + 1], msg["args"])
