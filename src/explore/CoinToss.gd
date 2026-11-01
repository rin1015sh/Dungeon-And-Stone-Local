class_name CoinToss
extends RefCounted
## 동전 던지기 판정(사용자 2026-11-01 "피어 앤 헝거처럼 동전 던지기로 획득", V25). 순수 로직 — 연출은 CoinFlip(UI).
## 앞면 확률 = balance coin.<kind>.heads(없으면 coin.heads, 기본 0.5).
##   chest  상자(RiftChest) — 플레이어가 고른 면과 같으면 담긴 물건, 다르면 잡템
## 보스의 아주 강한 패턴을 덜 아프게 맞는 데 쓸 생각(사용자 2026-11-01 — 보류). 전투 선공 동전은 없앴다.


static func heads_chance(db: GameDatabase, kind: String) -> float:
	return clampf(float(db.bal("coin.%s.heads" % kind, db.bal("coin.heads", 0.5))), 0.0, 1.0)


static func flip(db: GameDatabase, rng: Rng, kind: String) -> bool:
	return rng.chance(heads_chance(db, kind))
