extends Node
## 시스템 간 느슨한 결합용 전역 시그널 허브(오토로드).
## 업적·도감·퀘스트 같은 기능은 여기 시그널을 구독만 하면 붙는다.
## 오토로드는 class_name을 두지 않는다(오토로드 이름과 충돌).

@warning_ignore("unused_signal")
signal log_message(text: String, kind: String)            ## kind: info/system/good/warn/danger
@warning_ignore("unused_signal")
signal notice(key: String, args: Dictionary, kind: String)  ## 문구 키 알림(소지품 창 등) — 탐험 화면이 키로 보일지(대화창)·안 보일지를 나눈다(NoticeRoute)
@warning_ignore("unused_signal")
signal data_reloaded
@warning_ignore("unused_signal")
signal time_advanced(hours: float)                         ## M1 TimeSystem
@warning_ignore("unused_signal")
signal floor_closing(floor_id: String, hours_left: float)  ## M1/M4
@warning_ignore("unused_signal")
signal monster_killed(monster_id: String, killer_id: String)  ## M2/M3
@warning_ignore("unused_signal")
signal essence_absorbed(actor_id: String, essence_id: String) ## M3
@warning_ignore("unused_signal")
signal character_died(actor_id: String, cause: String)     ## M4 묘비 목록
