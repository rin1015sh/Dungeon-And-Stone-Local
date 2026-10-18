# 인계 프롬프트 — 하단 대화창 · 시설 나가기 · 알림 나누기 · 사망 화면 없앰 (2026-10-18)

> 새 세션에 아래 "프롬프트" 부분을 그대로 붙여 넣는다.

---

## 프롬프트

CLAUDE.md와 docs/PROGRESS.md를 읽고 시작해. 최신 main 위에서 아래 UI 변경을 넣어 줘.

### 0. 먼저 해 볼 것 — 이미 만든 커밋 가져오기

다른 세션이 브랜치 `claude/sweet-archimedes-stxlag`에 이 작업을 이미 해 뒀다(main에는 아직 안 들어감). 커밋 두 개:
- `440b911` 하단 대화창(탐험 알림·전투 안내 Enter로 넘김) · 시설 나가기 버튼 · 시설 화면 재배치
- `b9b579c` 탐험 알림 세 갈래(안 보임·잠깐 띠·대화창) · 사망 시 결과 화면 없이 타이틀

`git fetch origin claude/sweet-archimedes-stxlag` 후 최신 main에서 만든 브랜치에 `git cherry-pick 440b911 b9b579c`를 해 본다.
충돌이 나면 아래 명세대로 main 쪽 변경을 살리면서 풀고, 너무 어긋나면 cherry-pick을 그만두고 아래 명세대로 새로 만든다.
(그 브랜치의 파일을 `git show b9b579c:<경로>`로 참고해도 된다.)
어느 쪽이든 끝에 `GODOT=<경로> bash tools/check.sh`가 "모든 검증 통과"여야 하고, 캡처로 화면을 직접 본다.

### 1. 사용자 요청 (원문 요지)

1. "도시 건물 안에 들어갔을 때 나갈 수 있는 버튼을 만들어 줘."
2. "지금 건물 안 UI가 마음에 안 들어. 다시 재배치해 줘."
3. "전투·탐험 알림창과 UI를 캐릭터 대사 넘기는 것처럼 하단 대화창으로, 엔터 누르면 넘어가게. 피어 앤 헝거 참고."
4. "횃불·포션·식사·단축키에 포션 없음·포탈 위에 섬은 그냥 표시하지 마(게임에서 없애). 아이템 획득·버리기는 엔터로 넘기게, 나머지 자잘한 건 잠깐 띄우고 사라지게."
5. "전투에서 패배하면 '당신은 패배했다...' 띄우고 바로 타이틀로. 죽었습니다 어쩌고 화면 없애."

### 2. 명세

**A. 공용 하단 대화창 `src/ui/widgets/DialogueBox.gd`(class_name DialogueBox, PanelContainer)**
- `say(text, kind)`로 줄을 쌓고 한 쪽에 `render.json ui.dialog.lines`(3)줄씩 보인다. 줄 색 = 팔레트 `log_<kind>`.
- 글자는 한 자씩 나온다(`chars_per_sec` 90). 나오는 중 Enter = 바로 다 보이기, 다 보였으면 Enter = 다음 쪽, 없으면 숨고 `drained` 시그널.
- 다 보이면 아래 가운데에 금빛 작은 삼각형이 깜박인다(글꼴 기호 대신 직접 그림 — 웹 글꼴 제한).
- 넘기는 키: `menu_confirm`·`interact`·`ui_accept`, 왼쪽 클릭. 줄이 남아 있는 동안 키 입력은 `_unhandled_input`에서 먼저 먹는다(`pause`·`debug_toggle`만 통과).
- `busy()`, `await wait()`(다 넘길 때까지), `clear()`, `advance()`, `shown_changed(on)` 시그널.
- `idle_text`/`idle_kind`: 넘길 줄이 없을 때 남겨 둘 글(시설 정보 줄). 비면 창 숨김.
- 이름판 `set_speaker(text)`: 창 위 왼쪽에 걸친 작은 판(시설 이름).
- `static var auto_skip`(테스트·캡처용 — 켜면 say가 아무것도 안 하고 기다리지 않음), 인스턴스 `instant`(전투 빨리 감기 디버그).
- 스타일 인자(`_init(style)`) — 시설은 `CityUi.card_box()`, 기본은 거의 검은 판 + `slot_border` 2px.
- render.json `ui.dialog`: `{"lines":3,"chars_per_sec":90,"font_size":18,"line_gap":6,"height":128,"width":960,"pad_x":22,"pad_y":14,"mark_size":7,"plate_x":18}`.

**B. 전투(`CombatScreen`)**
- 위 가운데 안내 띠(banner)를 없앤다. 대화창은 아래 창 `CommandMenu` 안 왼쪽에 넣는다(`CommandMenu.set_dialog(d)` — 맨 앞 자식, 최소 폭 `ui.combat_dialog_width` 360, 대화창이 보이는 동안 왼쪽 명령 칸을 숨김 → [대화창 | 파티 창]).
- `_say` = `EventBus.log_message` + `_dialog.say`. 화면이 열리기 전 `battle.history`도 대화창에.
- 차례 루프: `next_turn` 뒤 `_read()`(대화창이 비면 바로 통과, 아니면 다 넘길 때까지 대기), 행동 뒤 `_turn_gap()`은 안내가 있으면 그걸 다 넘길 때까지, 없을 때만 예전 쉼(0.7초). 행동 정하기(명령 창 열기)는 안내를 다 넘긴 뒤.
- 잘못된 행동 경고: 명령 창 닫기 → 경고를 대화창에 → 다 넘기면 다시 연다.
- 결과: 결과 칸·"계속" 버튼을 없앤다. 결과 한 줄("승리"/"당신은 패배했다..."/"도주", 색 good/danger/warn) → Enter → 드롭 묻기(CombatDrops) → 보상 안내를 대화창에 → 다 넘기면 `finished`. 보상 안내는 세션이 기록에 남기므로 여기선 `_dialog.say`만.
- `combat.result_defeat` = "당신은 패배했다...", 안 쓰게 된 `combat.continue` 문자열 삭제. `_dialog.instant = GameState.debug_fast_combat`.
- `dialog()` 접근자(테스트용).

**C. 탐험(`ExploreScreen`)**
- 왼쪽 아래 기록창(LogPanel)을 화면에서 뺀다(클래스는 기반 점검 화면이 쓰니 둔다).
- 대화창은 하단 바 자리(가운데, 폭 `ui.dialog.width`, 화면이 좁으면 여백만 남기고)에 겹치고, 떠 있는 동안 하단 바 숨김 + `session.realtime.set_paused("dialog", _dialog.busy())`(매 프레임).
- 전투가 열릴 때 `_dialog.clear()`.
- **알림 세 갈래**(`src/ui/widgets/NoticeRoute.gd`, render.json `ui.notice`): 문구 키로 나눈다.
  - silent(안 보임, 기록에만): `effect.light_on`, `effect.light_already`, `effect.restore`, `effect.restore_none`, `explore.no_item`, `explore.portal_here`, `explore.rift_portal_here`, `explore.rift_exit_here`
  - toast(위 가운데 띠, 2.6초 뒤 흐려지며 사라짐, 시간 안 멈춤, 최근 3줄 — `src/ui/widgets/NoticeToast.gd`): `explore.cannot_use`, `explore.no_category`, `explore.wait`, `explore.nothing_here`, `explore.status_on/off`, `explore.safe_enter/leave`, `explore.dark_enter`, `explore.light_out`, `field.done`, `field.done_today`, `field.missing`, `field.no_cost`, `inventory.no_room_swap`, `inventory.no_room_unequip`, `effect.fatigue_down/up/none`, `effect.status_on/off` + **동굴 요소 근처 문구**(data/events의 `near.line` 키를 읽어 저절로 toast). 번호 변형 키(`field.x.2`)는 앞 두 마디로 비교.
  - 그 밖 = 대화창(Enter): 아이템 획득(`field.got`·`field.got_n`·`field.no_room`·`reward.loot`), 버리기(`inventory.discarded`), 발견·경고·폐쇄·휴식 결과·입장 등. 처음 보는 키도 대화창.
- 라우팅: `session.message` → `_notify(key, args, kind)`({interact}는 지금 살피기 키로 채움) → 항상 `EventBus.log_message`(기록) → 전투 중·끝난 뒤가 아니면 갈래대로. `_notify`가 기록을 내는 동안 `_routing = true`로 `_on_log`(키 없는 log_message → 대화창)가 두 번 보이지 않게.
- 소지품 창·장비 인형 알림은 새 시그널 `EventBus.notice(key, args, kind)`로 보낸다(`InventoryWindow` 두 곳, `PaperDoll` 한 곳 — 예전엔 `log_message`에 완성된 글을 보냈다). ExploreScreen이 `notice`를 `_notify`에 연결.
- `dialog()`·`toast()` 접근자(테스트용).

**D. 사망 → 결과 화면 없이 바로 타이틀**
- `Main._on_run_ended`: `died`면 `GameState.on_death()` 후 바로 `_show_title()`(EndScreen 안 띄움). 층 폐쇄·포기는 EndScreen 그대로.
- `ExploreScreen._end("died")`: 전투 패배였으면(전투 finished 콜백에서 `_defeated = result == Battle.RESULT_DEFEAT`를 resolve 전에 기록) 대화창을 비우고 바로 `run_ended`. 탐험 중 사망(굶주림·함정)이면 남은 안내("숨이 멎었다.")를 다 넘긴 뒤 `run_ended`(지연 타이머 없음).

**E. 시설(`FacilityView`, `CityHud`) — 나가기 버튼 + 재배치**
- 오른쪽 큰 패널을 없애고 그림을 가리지 않게:
  - 아래 = 대화창(전체 폭 − 여백, 높이 `ui.dialog.height`, `CityUi.card_box()` 스타일), 이름판 = 시설 이름. 평소 글(idle) = 시설 정보 줄(신전 공적치·은행 잔액 등 facilities `shows`), 없으면 " "(창이 사라지지 않게).
  - 대화창 바로 위 오른쪽 = 선택 창(`CityUi.card()` + `ChoiceGrid`(1열, compact, 칸 높이 `city.interior_slot_height` 40), 폭 `city.interior_menu_width` 300): 활동(데이터 순서, 칸 오른쪽 아래 sub = 이용료 "50 스톤" 또는 못 하는 이유) + 맨 끝 **나가기**(`city.leave` "나가기"). W/S·Enter, Backspace = 나가기.
  - 탐험가 카드는 시설 안에서 달력 카드 아래로 올린다(`CityHud.set_facility_mode` — `_calendar`·`_vitals` 참조 저장, 나오면 원래 왼쪽 아래).
- 나가기는 **언제나** 된다(예전 CT3 "활동 전엔 못 나감·나가기 버튼 없음"을 바꿈). 들어올 때 쓴 행동력은 돌려주지 않는다. Esc·Backspace·빈 곳 오른쪽 클릭도 나가기. `city.leave_locked` 문자열 삭제.
- 일반 활동: 결과(`city.did` + 문구)를 대화창에 → 다 넘기면 저절로 거리로(`leave_requested.emit.call_deferred()`). 결과 넘기는 동안 선택 창 숨김·`grid.active = false`. 거리 위 알림(summary)은 "할 게 없어 바로 나올 때"만.
- 창구(상점·은행·정수 제거): 선택 창 자리에 패널 + 그 아래 나가기 버튼(카드 폭 `city.interior_panel_width` 440). 거래 결과는 넘기지 않는 글(idle_text/idle_kind)로 대화창에 남긴다(거래마다 Enter를 누르지 않게).
- 선택 창 자리는 `_menu.minimum_size_changed`·`resized`에 맞춰 다시 잡는다.
- 안 쓰게 된 render.json 키 정리: `combat_reward_height`, `explore_log_width/height`, `city.result_lines`, `city.result_min_height`.

**F. 테스트·도구**
- `tests/smoke_ui.gd`: `_ready`에서 `DialogueBox.auto_skip = true`. "계속" 버튼을 누르던 곳(실시간 전투·수수께끼)은 지우고 `_take_drops`는 전투 화면이 사라지면 끝나게. 새 검사:
  - 탐험: auto_skip을 끄고 알림 → 대화창 보임·하단 바 숨김·시간 정지 → Enter로 닫힘·시간 흐름 / `effect.light_on`·`explore.portal_here` → 아무것도 안 보임 / `explore.wait` → 띠 1줄·시간 흐름 / `field.got` → 대화창.
  - 전투: auto_skip을 끈 채 몬스터 소환 → 시작 안내가 대화창에·행동창 아직 → Enter를 눌러 행동창이 열림.
  - 시설: "들어오면 못 나간다" 검사 → "시설 안에 나가기 버튼", 은행 창구는 나가기 버튼으로 나오기.
  - 아사 흐름: EndScreen 없이 바로 TitleScreen.
- `tools/screenshot.gd`: `DialogueBox.auto_skip = not _args.has("dialog")` — `--dialog`면 대화창을 띄운 채 찍는다(맨 위 사용법 주석에도).

**G. 문서**
- ASSUMPTIONS: UI15(대화창·시설 나가기·재배치 — CT3에 "바뀜 → UI15" 표시), UI16(알림 세 갈래·사망 화면 없앰).
- CLAUDE.md 구조 목록(widgets에 DialogueBox·NoticeToast·NoticeRoute, LogPanel = 기반 점검 기록창), 빠른 참조 "하단 대화창" 줄, 도시 줄의 "나가기 버튼 없음" 고치기.
- CANON·DESIGN의 "나가기 버튼 없음" 문장, PROGRESS 현재 상태, README 체크리스트(두 표: 하단 대화창·시설 / 알림 나누기·사망 화면).

### 3. 확인

- check.sh 통과.
- 캡처(xvfb): `--screen=city --facility=inn --dialog`, `--facility=shop --activity=shop_trade --dialog`, `--facility=inn --activity=inn_rest --dialog`, `--screen=explore --seed=1 --dialog`, `--screen=explore --seed=1 --combat --dialog --mate=barbarian`(파티 창이 넘치지 않는지), `--screen=explore --seed=1 --interact`(띠).
- 그전 세션에서 이미 본 것: UI 스모크의 "1 RID CanvasItem / 2 ObjectDB leaked" 경고는 이 작업 전부터 있던 것이다(check.sh는 통과).
