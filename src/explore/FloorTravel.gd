class_name FloorTravel
extends RefCounted
## 층 사이 이동(M6-0 A·B — docs/plans/floor2.md §1-4·§1-5).
## 오르기: 층 포탈 portal {"to_floor", "dest"} → 층 정의 중 "arrival"이 dest와 같은 층의 새 세션(없으면 null — 아직 잠김).
##   위층 세션은 아래층 세션을 below로 붙잡는다(아래층은 위층을 모른다 — 순환 참조 없음). 아래층 세션은 떼어 둔다(detach).
## 내리기: 위층 도착 비석(포탈 kind "floor_down")에서 살피면 아래층 세션을 다시 붙여 올라갔던 포탈 자리에 세운다.
##   위층은 버린다 — 다시 오르면 새 지도(원작: 2층은 달마다 새로, 6층 전까지 층 상태를 남기지 않는다 — floors_2_10 §2 D).
## 시계·플레이어·동료·가방·난수·효과 레지스트리는 같은 것을 넘긴다 — 원정 시계는 층과 무관하게 하나(사용자 2026-11-04 "총 10일").
## 오토로드를 쓰지 않는다(도서관 서적 floor는 Main이 세션을 띄울 때 센다).


## 포탈 dest에 도착하는 층 id(층 JSON "arrival"). 없으면 "".
static func floor_for(db: GameDatabase, dest: String) -> String:
	if dest.is_empty():
		return ""
	for fid: String in db.get_collection("floors"):
		if JsonUtil.get_str(db.get_entry("floors", fid), "arrival") == dest:
			return fid
	return ""


## 층 포탈로 오른다. 갈 층이 없으면 null(호출하는 쪽이 "잠겨 있다"를 알린다).
static func up(s: ExploreSession, portal: Dictionary) -> ExploreSession:
	var fid := floor_for(s.db, str(portal.get("dest", "")))
	if fid.is_empty():
		return null
	var fdef := s.db.get_entry("floors", fid)
	var gen := ContentRegistries.new().generator(JsonUtil.get_str(fdef, "generator"))
	if gen == null:
		return null
	var map := gen.generate(s.db, fdef, Rng.new(s.rng.randi_range(1, 1 << 30)))
	var next := ExploreSession.new(s.db, fdef, map, s.player, s.clock, s.rng, s.effects)
	next.companions = s.companions
	next.monsters_enabled = s.monsters_enabled
	next.below = s
	next.below_at = portal["pos"]
	s.detach()
	next.fade_in = true
	next.pending_messages.append_array(s.take_pending())
	return next


## 도착 비석에서 아래층으로 내려간다. 아래층이 없으면 null.
static func down(s: ExploreSession) -> ExploreSession:
	var low := s.below
	if low == null:
		return null
	s.detach()
	s.below = null
	low.reattach()
	low.place_at(s.below_at, Vector2i.DOWN)
	low.fade_in = true
	low.refresh_view()
	return low
