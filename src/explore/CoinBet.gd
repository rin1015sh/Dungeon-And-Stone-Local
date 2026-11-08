class_name CoinBet
extends RefCounted
## 앞뒤를 고르고 던지는 동전 한 판(사용자 2026-11-08 "스탯 판정 전부 동전 던지기로" — V29).
## 고르기(ExploreSession.guess — 화면 W/S 창) → CoinToss.flip(kind) → 연출(toss) → then(right: bool).
## can_back = Esc로 그만둘 수 있다(살피기 행동 — 그만두면 then을 부르지 않는다). 아귀 입은 false. 함정은 동전이 아니라 스탯 판정(RiftHazards — 사용자 되돌림).
## 받는 화면이 없으면(테스트 · 시뮬) 앞면을 고르고 곧바로 then을 부른다(같은 프레임).
## 숨은 은닉처 알아채기처럼 묻지 않는 판정은 quiet — 화면에 동전을 띄우면 숨은 것이 있다는 게 드러나서다.


static func bet(s: ExploreSession, kind: String, then: Callable, can_back: bool = true) -> void:
	s.guess(func(pick: int) -> void:
		if pick < 0:
			if can_back:
				return
			pick = 0
		var heads := CoinToss.flip(s.db, s.rng, kind)
		s.toss(heads, func() -> void: then.call((pick == 0) == heads)), can_back)


## 묻지도 보이지도 않는 동전(숨은 은닉처 알아채기): 앞면이면 true.
static func quiet(s: ExploreSession, kind: String) -> bool:
	return CoinToss.flip(s.db, s.rng, kind)
