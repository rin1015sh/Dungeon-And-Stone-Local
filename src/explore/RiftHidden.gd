class_name RiftHidden
extends RefCounted
## 균열 챕터의 살필 수 있는 물체(RiftRun이 챕터를 만들 때 place, ExploreInteract가 살피기로 take).
## 챕터 "hidden": [{"id", "item", "count", "tile", "message", "near_entry"}] — 방 안쪽에 물체(tile)를 두고 옆에서 살펴 아이템을 얻는다(히든 피스).
##   near_entry: true면 시작 자리 가까이(빙하굴 빙정 연못).
##   "mural": true — 벽화(강철의 묘): 아이템 대신 이 균열 수수께끼(RiftRiddle)의 힌트를 읽는다. 벽화는 남고 다시 읽을 수 있다.
## 찾는 법에 붙는 조건(히든 피스 기획 §6 — 2026-10-24, RF17. 화면에 규칙 설명은 없다 — 장면 문구로만):
##   "needs": {"hazards": "no_fail"(이 챕터 위험이 한 번도 발동하지 않았다) | "all_pass"(이 챕터 위험을 모두 지났고 발동 없음),
##             "riddle": "correct"(수수께끼를 맞혔다), "guardian": true(수호자를 쓰러뜨렸다), "item": id(+ "consume": true면 쓴다)}
##     못 갖췄으면 "locked" 문구만 보이고 물체는 남는다(조건을 갖추고 다시 살피면 얻는다).
##   "reveal": {"hazard": 위험 id, "how": ["bypass"|"disarm"|"pass"]} — 처음엔 놓지 않는다. 그 위험이 그렇게 끝나면 그제야
##     자리(설계도 hidden 표시)에 나타난다("reveal_message"). 다르게 끝나면 끝내 나타나지 않는다.
##   "check": {"stat", "dc"} — 한 번만 판정(광차 밀기). 성공하면 얻고, 실패하면 "fail_message" — 다시 못 한다.
##   "one_of": 묶음 이름 — 같은 묶음 중 하나만 진짜(입장 때 고른다). 가짜를 살피면 "decoy": {"status", "message"}(저주)를 받고 사라진다.
##     "look_if": "murals" — 이 균열 벽화를 다 읽었으면 첫 살피기는 들여다보기만("look_message" 진짜·"plain_message" 가짜), 다음에 가져간다.
## 위험 결과는 RiftHazards가 on_hazard로 알린다(챕터마다 센다).

var at: Dictionary = {}      ## 이 챕터의 물체 칸 -> 정의
var taken: Dictionary = {}   ## 끝난(얻은·놓친) 히든 피스 id -> true(균열 한 번 동안)
var under: Dictionary = {}   ## 물체 칸 -> 원래 타일(설계도 지도 — 가져간 뒤 되돌린다)
var _waiting: Dictionary = {}  ## 챕터 번호 -> [[정의, 자리]] — reveal 조건을 기다리는 물체
var _hz: Dictionary = {}       ## "fail:<챕터>" · "done:<챕터>" · "total:<챕터>" -> 수
var _real: Dictionary = {}     ## one_of 묶음 -> 진짜 id
var _looked: Dictionary = {}   ## 들여다본 id -> true


## 물체를 방 안쪽 칸(사방 8칸이 모두 바닥이고 조우·출구·시작 자리가 아닌 곳)에 둔다. 설계도 지도(map.anchors.hidden)면 그 자리에.
func place(cs: ExploreSession, ch: Dictionary, rng: Rng, chapter: int = 0) -> void:
	at.clear()
	under.clear()
	var spots: Array = cs.map.anchors.get("hidden", [])
	var list := JsonUtil.get_array(ch, "hidden")
	_pick_real(list, rng)
	var k := -1
	for h: Variant in list:
		var hd: Dictionary = h if h is Dictionary else {}
		k += 1
		if taken.has(JsonUtil.get_str(hd, "id")):
			continue
		if hd.has("reveal"):  # 위험이 그렇게 끝날 때까지 숨어 있다
			if k < spots.size():
				var wait: Array = _waiting.get(chapter, [])
				wait.append([hd, spots[k]])
				_waiting[chapter] = wait
			continue
		if k < spots.size():  # 설계도 지도: 정해진 자리(분수대·책장·벽화 자리 — 벽 칸이어도 옆에서 살핀다)
			_put(cs, spots[k], hd)
			continue
		var cells: Array[Vector2i] = []
		for i in cs.map.tiles.size():
			var p := cs.map.pos_of(i)
			if RiftHazards._interior(cs.map, p) and not cs.map.slots.has(p) and p != cs.map.entry and cs.map.portal_at(p).is_empty() \
					and not at.has(p) and Vector2(p - cs.map.entry).length() > 3.0:
				cells.append(p)
		var near := cells.filter(func(p: Vector2i) -> bool: return Vector2(p - cs.map.entry).length() <= float(cs.db.bal("rift.near_entry_m", 8)))
		if JsonUtil.get_bool(hd, "near_entry") and not near.is_empty():
			cells.assign(near)
		if cells.is_empty():
			continue
		var p: Vector2i = rng.pick(cells)
		cs.map.set_tile(p, JsonUtil.get_str(hd, "tile"))
		at[p] = hd


## 이 챕터의 위험 묶음 수(RiftRun이 위험을 깐 뒤).
func count_hazards(chapter: int, hazards: RiftHazards) -> void:
	var groups: Array = []
	for p: Vector2i in hazards.at:
		if not groups.has(hazards.at[p]):
			groups.append(hazards.at[p])
	_hz["total:%d" % chapter] = groups.size()


## 위험 묶음 하나의 판정이 끝났다(RiftHazards.on_step). how = bypass(부숨) · disarm(해제) · pass(피함·건넘) · fail(발동).
func on_hazard(cs: ExploreSession, chapter: int, hd: Dictionary, how: String) -> void:
	_hz["done:%d" % chapter] = int(_hz.get("done:%d" % chapter, 0)) + 1
	if how == "fail":
		_hz["fail:%d" % chapter] = int(_hz.get("fail:%d" % chapter, 0)) + 1
	var wait: Array = _waiting.get(chapter, [])
	for w: Array in wait.duplicate():
		var rv := JsonUtil.get_dict(w[0], "reveal")
		if JsonUtil.get_str(rv, "hazard") != JsonUtil.get_str(hd, "id"):
			continue
		wait.erase(w)
		if not JsonUtil.get_array(rv, "how").has(how):
			taken[JsonUtil.get_str(w[0], "id")] = true  # 다르게 끝났다 — 끝내 나타나지 않는다
			continue
		_put(cs, w[1], w[0])
		cs.tiles_changed.emit(Rect2i(w[1], Vector2i.ONE))
		cs.message.emit(JsonUtil.get_str(w[0], "reveal_message", "explore.hidden_revealed"), {}, "good")


## 물체를 살핀다(옆 칸 p). 무언가 했으면 true.
func take(cs: ExploreSession, p: Vector2i, floor_tile: String, riddle: RiftRiddle) -> bool:
	var hd: Dictionary = at.get(p, {})
	if hd.is_empty():
		return false
	var id := JsonUtil.get_str(hd, "id")
	if JsonUtil.get_bool(hd, "mural"):
		if riddle == null:
			return false
		var hint := riddle.read_mural(cs.player, p)
		cs.message.emit(JsonUtil.get_str(hd, "message", "explore.mural_read"), {"hint": hint}, "system")
		return true
	if not _needs_ok(cs, hd, riddle):
		cs.message.emit(JsonUtil.get_str(hd, "locked", "explore.hidden_locked"), {}, "info")
		return true
	var group := JsonUtil.get_str(hd, "one_of")
	var real := group.is_empty() or str(_real.get(group, "")) == id
	if JsonUtil.get_str(hd, "look_if") == "murals" and riddle != null and riddle.is_ready() and not _looked.has(id) \
			and riddle.known(cs.player) >= riddle.hints().size():
		_looked[id] = true  # 벽화를 다 읽었다: 먼저 들여다본다
		cs.message.emit(JsonUtil.get_str(hd, "look_message" if real else "plain_message"), {}, "system")
		return true
	if not real:
		_spent(cs, p, floor_tile, hd)
		var decoy := JsonUtil.get_dict(hd, "decoy")
		var st := JsonUtil.get_str(decoy, "status")
		if not st.is_empty():
			cs.player.statuses.apply(st)
		cs.message.emit(JsonUtil.get_str(decoy, "message", "explore.hidden_decoy"), {}, "danger")
		cs.refresh_view()
		return true
	var check := JsonUtil.get_dict(hd, "check")
	if not check.is_empty() and not cs.rng.chance(RiftHazards.success_chance(cs.db, cs.player, check)):
		taken[id] = true  # 한 번뿐 — 물체는 그 자리에 남지만 다시 살펴도 아무것도 없다
		at.erase(p)
		cs.message.emit(JsonUtil.get_str(hd, "fail_message", "explore.hidden_failed"), {}, "warn")
		return true
	var item := JsonUtil.get_str(hd, "item")
	var count := JsonUtil.get_int(hd, "count", 1)
	if not cs.player.inventory.fits(item, count):  # 가방이 찼으면 그 자리에 둔다(탈출에 필요한 물건을 잃지 않게)
		cs.message.emit("explore.hidden_no_room", {"item": DataNames.entry(cs.db, "items", item)}, "warn")
		return true
	var need := JsonUtil.get_dict(hd, "needs")
	if JsonUtil.get_bool(need, "consume"):
		cs.player.inventory.remove(JsonUtil.get_str(need, "item"), 1)
	_spent(cs, p, floor_tile, hd)
	cs.player.inventory.add(item, count)
	cs.message.emit(JsonUtil.get_str(hd, "message", "explore.hidden_found"), {"item": DataNames.entry(cs.db, "items", item)}, "good")
	cs.refresh_view()
	return true


func _needs_ok(cs: ExploreSession, hd: Dictionary, riddle: RiftRiddle) -> bool:
	var need := JsonUtil.get_dict(hd, "needs")
	var ch := cs.rift_run.chapter if cs.rift_run != null else 0
	match JsonUtil.get_str(need, "hazards"):
		"no_fail":
			if int(_hz.get("fail:%d" % ch, 0)) > 0:
				return false
		"all_pass":
			if int(_hz.get("fail:%d" % ch, 0)) > 0 or int(_hz.get("done:%d" % ch, 0)) < int(_hz.get("total:%d" % ch, 0)):
				return false
	if JsonUtil.get_str(need, "riddle") == "correct" and (riddle == null or not riddle.answered_right()):
		return false
	if JsonUtil.get_bool(need, "guardian") and (cs.rift_run == null or not cs.rift_run.guardian_down):
		return false
	var item := JsonUtil.get_str(need, "item")
	return item.is_empty() or cs.player.inventory.count(item) > 0


## 물체를 놓는다(설계도 자리).
func _put(cs: ExploreSession, sp: Vector2i, hd: Dictionary) -> void:
	under[sp] = cs.map.tile_id_at(sp)
	cs.map.set_tile(sp, JsonUtil.get_str(hd, "tile"))
	at[sp] = hd


## 끝난 물체: 원래 타일로 되돌린다.
func _spent(cs: ExploreSession, p: Vector2i, floor_tile: String, hd: Dictionary) -> void:
	at.erase(p)
	taken[JsonUtil.get_str(hd, "id")] = true
	cs.map.set_tile(p, str(under.get(p, floor_tile)))
	cs.tiles_changed.emit(Rect2i(p, Vector2i.ONE))


## one_of 묶음마다 진짜 하나(처음 놓을 때 한 번 — 되돌아와도 같다).
func _pick_real(list: Array, rng: Rng) -> void:
	var groups: Dictionary = {}
	for h: Variant in list:
		var g := JsonUtil.get_str(h if h is Dictionary else {}, "one_of")
		if not g.is_empty() and not _real.has(g):
			var ids: Array = groups.get(g, [])
			ids.append(JsonUtil.get_str(h, "id"))
			groups[g] = ids
	for g: String in groups:
		_real[g] = rng.pick(groups[g])
