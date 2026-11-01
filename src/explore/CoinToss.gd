class_name CoinToss
extends RefCounted
## 동전 던지기 판정(사용자 2026-11-01 "피어 앤 헝거처럼 동전 던지기로 획득 — 보스 전투 등 중요한 전투에서도", V25). 순수 로직 — 연출은 CoinFlip(UI).
## 앞면 = 성공. 확률 = balance coin.<kind>.heads(없으면 coin.heads, 기본 0.5).
##   chest  상자 열기(RiftChest) — 앞면이면 꺼내고, 뒷면이면 자물쇠 함정
##   battle 중요한 전투(구성·연전에 coin.battle.ranks 등급 몬스터 — 수호자·중간보스·계층군주) 시작 — 앞면이면 아군 선공, 뒷면이면 적 선공


static func heads_chance(db: GameDatabase, kind: String) -> float:
	return clampf(float(db.bal("coin.%s.heads" % kind, db.bal("coin.heads", 0.5))), 0.0, 1.0)


static func flip(db: GameDatabase, rng: Rng, kind: String) -> bool:
	return rng.chance(heads_chance(db, kind))


## 동전을 던지는 중요한 전투인가(몬스터 id 목록 — 연전 구성까지 넘긴다).
static func important(db: GameDatabase, monster_ids: Array) -> bool:
	var ranks: Array = db.bal("coin.battle.ranks", [])
	for id: Variant in monster_ids:
		if ranks.has(JsonUtil.get_str(db.get_entry("monsters", str(id)), "rank")):
			return true
	return false
