class_name MonsterSnares
extends RefCounted
## 몬스터도 덫에 걸린다(레벨 디자인 LD — 고블린 숲 덫 골짜기 · 1층 북쪽 고블린 덫). 순수 로직(오토로드 비의존).
## 덫 정의(data/events의 hazard)에 "snares_monsters": {"hours": 걸려 있는 시간, "sound": 소리 키}가 있으면,
## 플레이어를 쫓는 무리(STATE_CHASE — 앞을 보지 않고 달려든다)가 아직 판정하지 않은 그 덫 묶음 칸에 들어서면 덫이 터진다:
## 묶음은 드러난 채 끝나고(플레이어가 밟아도 더 판정하지 않는다) 무리는 hours 동안 그 자리에 묶인다(FieldMonsters.Group.held_until).
## 쫓기지 않는 무리(순찰 — 제 덫 자리를 안다)는 걸리지 않는다. 덫 밭으로 꾀어 떼어 놓는 길을 연다.


## 시간이 흐른 뒤(ExploreSession.pass_time) 한 번. 걸린 무리 수.
static func update(s: ExploreSession) -> int:
	var hz := s.features.hazards
	if hz.at.is_empty():
		return 0
	var n := 0
	for g: FieldMonsters.Group in s.monsters.groups:
		if g.state != FieldMonsters.STATE_CHASE or g.held_until > s.clock.total_hours or not g.party.is_empty() or g.boss != "":
			continue
		if not hz.at.has(g.pos):
			continue
		var hd: Dictionary = hz.at[g.pos]
		var sn := JsonUtil.get_dict(hd, "snares_monsters")
		if sn.is_empty():
			continue
		spring(s, hd)
		g.held_until = s.clock.total_hours + JsonUtil.get_float(sn, "hours", 0.3)
		if sn.has("sound"):
			s.sound.emit(JsonUtil.get_str(sn, "sound"), g.pos)
		n += 1
	if n > 0:
		s.refresh_view()
	return n


## 덫 묶음 hd를 터진 것으로(판정 목록에서 빼고 그림은 드러낸 채 남긴다 — RiftHazards와 같다).
static func spring(s: ExploreSession, hd: Dictionary) -> void:
	var hz := s.features.hazards
	for q: Variant in hd["cells"]:
		hz.at.erase(q)
	hz.show_group(s, hd)
