class_name ExploreInteract
extends RefCounted
## 살피기(E)와 포탈 안내(ExploreSession이 부른다 — 세션 파일을 짧게 유지).
##   층 포탈: 아래층은 아직 잠김(M6) · 균열 포탈: 들어간다(RiftWatch.enter → 세션 transfer)
##   균열 출구: 다음 챕터 / 탈출(RiftRun.use_exit) · 대현자 기념비: 마석이 있으면 바쳐 균열을 연다(RiftWatch.try_offer)


static func run(s: ExploreSession) -> void:
	var portal := s.map.portal_at(s.pos)
	if not portal.is_empty():
		match str(portal.get("kind", "floor")):
			"rift":
				var first := s.rifts.enter(s, portal)
				if first != null:
					s.transfer.emit(first)
			"rift_exit":
				if s.rift_run != null:
					var next := s.rift_run.use_exit(s)
					if next != null:
						s.transfer.emit(next)
			_:
				s.message.emit("explore.portal_locked", {"floor": int(portal["to_floor"])}, "system")
		return
	for d in FloorMap.DIRS4:
		var def := s.map.def_at(s.pos + d)
		if def != null and def.interact == "monument":
			if not s.rifts.try_offer(s, s.pos + d):
				s.message.emit("explore.monument", {}, "system")
			return
	s.message.emit("explore.nothing_here", {}, "info")


static func portal_found(s: ExploreSession, portal: Dictionary) -> void:
	match str(portal.get("kind", "floor")):
		"rift":
			s.message.emit("explore.rift_portal_found", {}, "danger")
		"rift_exit":
			s.message.emit("explore.rift_exit_found", {}, "good")
		_:
			s.message.emit("explore.portal_found", {"dir": DataNames.tag(s.db, "directions", str(portal["dir"]))}, "good")


static func portal_here(s: ExploreSession, portal: Dictionary) -> void:
	match str(portal.get("kind", "floor")):
		"rift":
			s.message.emit("explore.rift_portal_here", {}, "system")
		"rift_exit":
			s.message.emit("explore.rift_exit_here", {}, "system")
		_:
			s.message.emit("explore.portal_here", {}, "system")
