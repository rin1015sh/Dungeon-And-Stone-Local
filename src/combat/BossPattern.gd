class_name BossPattern
extends RefCounted
## 보스 패턴 하나(기반 클래스). src/combat/patterns/<id>.gd 파일 하나 = 패턴 하나, 몬스터 데이터 "pattern": "<id>".
## 수치는 몬스터 데이터 "pattern_params"에 둔다(코드에 매직 넘버 금지). BossHooks가 부른다.
## 페이즈 진입 처리(phases 데이터: 메시지·상태이상·패시브·대상 규칙·라운드 효과)는 BossHooks가 공통으로 하고,
## 패턴은 그 보스만의 규칙(주기 소환·순환·버프 등)만 맡는다.
## 라운드 = 보스 자신의 차례 하나(추가 행동은 같은 라운드). 기절 등으로 차례를 건너뛰어도 라운드는 끝난다.


## 전투 시작(첫 페이즈 진입 전 — memo 초기화).
func on_start(_b: Battle, _c: Combatant) -> void:
	pass


## 페이즈에 들어섰다(BossHooks가 공통 처리를 마친 뒤).
func on_phase(_b: Battle, _c: Combatant, _phase: Dictionary) -> void:
	pass


## 이번 차례 뒤에 한 번 더 행동하는가(라운드당 2회 행동).
func wants_extra_action(_b: Battle, _c: Combatant) -> bool:
	return false


## 라운드 종료(보스 차례가 끝났다). c.memo["round"]는 이미 1 늘어 있다.
func on_round_end(_b: Battle, _c: Combatant) -> void:
	pass


## 데이터 검사(검증기가 부른다).
func validate(_def: Dictionary, _db: GameDatabase) -> PackedStringArray:
	return PackedStringArray()
