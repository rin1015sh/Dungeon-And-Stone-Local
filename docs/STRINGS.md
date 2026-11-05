# 게임 글 (`data/strings/ko.json`)

> 게임 화면·대화창·기록에 나오는 글 전부(996줄). **이 파일을 고친 뒤 적용하면 게임에 들어간다.**
> - 한 줄 = ``- `키` 글``. **키(`` ` `` 안)는 바꾸지 말고 뒤의 글만** 고친다. 줄을 지우거나 새 키를 쓰면 무시된다(키는 코드가 부른다).
> - `{이름}`은 자리표시자(게임이 값으로 바꿔 넣는다 — 그대로 둔다). 번호 키(`.1` `.2` …)가 여럿이면 차례로 모두 나오거나(장면) 하나를 고른다(묶음 설명 참고).
> - 적용: `godot --headless --path . --script res://tools/strings_md.gd -- --apply` → `data/strings/ko.json`이 바뀐다(그 뒤 `tools/check.sh`).
> - 다시 만들기(ko.json → 이 파일): `godot --headless --path . --script res://tools/strings_md.gd`. 코드가 글을 바꾸면 이 파일은 낡는다 — 고치기 전에 다시 만든다.
> - 이 파일 밖의 글: 데이터 이름(`name_ko` — 각 `data/*.json`), 수수께끼 문제(`data/riddles`), 소문·정보(`data/city_info`).

## 차례

- [앱 `app`](#app) — 타이틀 화면 제목·부제
- [num `num`](#num) — —
- [대상 종류 `target_kind`](#target_kind) — 스킬 설명의 대상(적 하나·적 전체 …)
- [메뉴 `menu`](#menu) — 타이틀 메뉴 · 공용 버튼(돌아가기·쪽수)
- [오류 `error`](#error) — 데이터 검증 실패 화면
- [기반 점검 `foundation`](#foundation) — 타이틀의 기반 점검 화면(개발용)
- [데이터 묶음 이름 `collection`](#collection) — 기반 점검·검증에서 묶음 이름
- [스탯 묶음 `stat_group`](#stat_group) — 스탯 묶음 제목(육체·정신 …)
- [기록 `log`](#log) — 기록 창 · 일반 알림(피해·영혼력 …)
- [캐릭터 만들기 `create`](#create) — 새 게임 — 종족·이름·능력치
- [탐험 `explore`](#explore) — 미궁 화면 — HUD · 대화창 알림(경고·발견·못 하는 이유)
- [효과 `effect`](#effect) — 아이템·스킬 효과 결과 알림
- [디버그 `debug`](#debug) — F1 디버그 패널
- [일시정지 `pause`](#pause) — Esc 정지 창
- [전투 `combat`](#combat) — 전투 화면 — 명령 · 대화창 안내 · 보스 대사 · 전투 기록
- [condition `condition`](#condition) — —
- [지식 `knowledge`](#knowledge) — 몬스터 약점·저항(전투에서 알게 될 때 · 도감)
- [보상 `reward`](#reward) — 전투 드롭 · 획득할까? · 경험치
- [소지품 `inventory`](#inventory) — Tab 메뉴 소지품 쪽
- [party `party`](#party) — —
- [캐릭터 `character`](#character) — Tab 메뉴 캐릭터 쪽
- [codex `codex`](#codex) — —
- [도감 `bestiary`](#bestiary) — Tab 메뉴 도감 쪽
- [정수 `essence`](#essence) — 정수 칸·설명
- [수수께끼 `riddle`](#riddle) — 강철의 묘 수수께끼 창
- [차원광장 `plaza`](#plaza) — 도시 → 미궁 포탈 화면 버튼
- [도시 `city`](#city) — 도시 — 거리·시설·활동 결과(lines)·거리 사건(street)·세금
- [동굴 요소 `field`](#field) — 1층 동굴 요소를 살필 때(번호가 여럿이면 하나를 고른다)
- [dir8 `dir8`](#dir8) — —
- [buff `buff`](#buff) — —
- [item `item`](#item) — —

<a id="app"></a>
## 앱 `app`

> 타이틀 화면 제목·부제

- `app.title` 던전 앤 스톤
- `app.subtitle` 라프도니아 차원광장 — 탐험가 기록
- `app.build` 비상업 팬 프로젝트

<a id="num"></a>
## num `num`

> —

> 스톤 금액 표시(Strings.stones): 만의 자리부터 넷째 자리마다 units 순서로 단위를 붙인다. 문구에서 stone_unit 바로 앞의 수 인자는 자동으로 이렇게 쓴다.

- `num.stone_unit` 스톤
- `num.units` 만,억,조,경

<a id="target_kind"></a>
## 대상 종류 `target_kind`

> 스킬 설명의 대상(적 하나·적 전체 …)

- `target_kind.enemy_single` 적 하나
- `target_kind.enemy_row` 적 한 줄
- `target_kind.enemy_all` 적 전체
- `target_kind.ally_single` 아군 하나
- `target_kind.ally_all` 아군 전체
- `target_kind.any_single` 아무나 하나
- `target_kind.self` 자신

<a id="menu"></a>
## 메뉴 `menu`

> 타이틀 메뉴 · 공용 버튼(돌아가기·쪽수)

- `menu.new_game` 새 탐험가
- `menu.continue` 이어하기
- `menu.foundation` 기반 점검
- `menu.quit` 종료
- `menu.back` 돌아가기
- `menu.page` {page}/{pages}
- `menu.page_prev` ◀
- `menu.page_next` ▶
- `menu.cursor` ▶
- `menu.empty_slot` —

<a id="error"></a>
## 오류 `error`

> 데이터 검증 실패 화면

- `error.data_title` 데이터 검증 실패
- `error.data_hint` data/ 폴더의 JSON을 고친 뒤 다시 실행하라. (tools/validate_data.gd로 같은 결과를 볼 수 있다)
- `error.count` 오류 {errors}건 · 경고 {warnings}건

<a id="foundation"></a>
## 기반 점검 `foundation`

> 타이틀의 기반 점검 화면(개발용)

- `foundation.title` 기반 점검 — 스탯 · 자원 · 데이터
- `foundation.character` 탐험가
- `foundation.race` 종족
- `foundation.template` 시작 템플릿
- `foundation.reroll` 다시 굴리기 (남은 {left}회)
- `foundation.info` 레벨 {level} · 시드 {seed}
- `foundation.level_up` 레벨 +1
- `foundation.level_down` 레벨 -1
- `foundation.stats_header` 핵심 스탯
- `foundation.col_stat` 스탯
- `foundation.col_base` 기본
- `foundation.col_value` 최종
- `foundation.sub_stats` 세부 스탯 {count}종 등록 · 투명 {hidden}종 · 효과 연결 {wired}종
- `foundation.resources_header` 자원
- `foundation.in_dungeon` 미궁 안에 있다
- `foundation.actions_header` 조작
- `foundation.act_damage` 피해 {amount}
- `foundation.act_spend_soul` 영혼력 {amount} 소모
- `foundation.act_turn` 1턴 경과
- `foundation.act_hour` 1시간 경과
- `foundation.act_eat` 식사 (+{amount})
- `foundation.act_buff_on` 근력의 비약 (+{amount}, {hours}시간)
- `foundation.act_buff_off` 비약 효과 지우기 (남은 {left}시간)
- `foundation.act_restore` 완전 회복
- `foundation.data_header` 불러온 데이터
- `foundation.data_line` {name} {count}
- `foundation.data_ok` 검증 통과
- `foundation.data_warn` 경고 {count}건 (콘솔 참고)

<a id="collection"></a>
## 데이터 묶음 이름 `collection`

> 기반 점검·검증에서 묶음 이름

- `collection.stats` 스탯
- `collection.resources` 자원
- `collection.statuses` 상태이상
- `collection.meters` 전투 게이지
- `collection.injuries` 부상
- `collection.races` 종족
- `collection.classes` 템플릿
- `collection.monsters` 몬스터
- `collection.essences` 정수
- `collection.skills` 스킬
- `collection.items` 아이템
- `collection.floors` 층
- `collection.rifts` 균열
- `collection.riddles` 수수께끼
- `collection.materials` 소재
- `collection.item_types` 아이템 종류
- `collection.events` 이벤트
- `collection.facilities` 시설
- `collection.town` 도시 지도
- `collection.tiles` 타일
- `collection.landmarks` 랜드마크
- `collection.activities` 도시 활동
- `collection.city_info` 소문·정보
- `collection.city_events` 오늘의 거리
- `collection.street_events` 거리 사건
- `collection.meals` 여관 요리
- `collection.scavenge` 균열 잡템 표
- `collection.interiors` 시설 실내

<a id="stat_group"></a>
## 스탯 묶음 `stat_group`

> 스탯 묶음 제목(육체·정신 …)

- `stat_group.body` 육체
- `stat_group.mind` 정신
- `stat_group.ability` 이능
- `stat_group.special` 특수

<a id="log"></a>
## 기록 `log`

> 기록 창 · 일반 알림(피해·영혼력 …)

- `log.header` 기록
- `log.welcome` 차원광장의 돌바닥은 차갑다. 기록을 시작한다.
- `log.rolled` {race} {template}. 타고난 몸을 확인했다.
- `log.damage` {amount}의 피해를 입었다.
- `log.spend_ok` 영혼력 {amount}을 태웠다.
- `log.spend_fail` 영혼력이 모자란다. 아무 일도 일어나지 않았다.
- `log.turn` 한 턴이 지났다.
- `log.hour` 한 시간이 지났다.
- `log.hour_city` 한 시간이 지났다. 도시에서는 배가 고파지지 않는다.
- `log.eat` 마른 식량을 씹어 삼켰다.
- `log.buff_on` 근력의 비약을 들이켰다. 근력 +{amount}.
- `log.buff_off` 비약 기운을 털어냈다.
- `log.buff_expired` 근력의 비약 기운이 빠져나갔다.
- `log.status_on` [{status}] 상태가 되었다.
- `log.status_off` [{status}] 상태에서 벗어났다.
- `log.depleted` {resource}이(가) 바닥났다.
- `log.depleted_hp` 생명력이 다했다. 이 몸은 여기서 끝이다. (기반 점검: 기록만 남긴다)
- `log.recovered` {resource}이(가) 다시 차오른다.
- `log.level` 레벨 {level}. 영혼의 그릇이 달라졌다.
- `log.restore` 숨을 고르고 몸을 추슬렀다.

<a id="create"></a>
## 캐릭터 만들기 `create`

> 새 게임 — 종족·이름·능력치

- `create.title` 새 탐험가
- `create.who` 누구인가
- `create.name` 이름
- `create.default_name` 이름 없는 탐험가
- `create.race` 종족
- `create.template` 시작 템플릿
- `create.reroll` 다시 굴리기 (남은 {left}회)
- `create.body_header` 타고난 몸
- `create.resources_header` 자원
- `create.items_header` 가진 것
- `create.items_none` 빈손이다.
- `create.enter_header` 라비기온 13구역
- `create.enter` 도시로 간다
- `create.equipped_item` {item} (착용)

<a id="explore"></a>
## 탐험 `explore`

> 미궁 화면 — HUD · 대화창 알림(경고·발견·못 하는 이유)

- `explore.rift_exit_needs` 길이 막혀 있다. [{item}]이(가) 있어야 할 것 같다.
- `explore.rift_exit_used` [{item}]을(를) 썼다.
- `explore.rift_key_held` 가방에 자리가 없어 손에 쥐었다.
- `explore.fortress_tear` 조각상을 깨뜨리자 작은 상자가 나왔다.
- `explore.fortress_necronomicon` 썩은 책장 사이에 피로 쓴 책 한 권이 끼어 있다.
- `explore.hidden_no_room` {item}을(를) 찾았지만 가방에 자리가 없다.
- `explore.scavenge_empty` {tile}에는 건질 것이 없다.
- `explore.scavenge_no_room` {item}을(를) 찾았지만 가방에 자리가 없다.
- `explore.chest` 상자
- `explore.chest_nothing` 상자 안은 비어 있었다.
- `explore.coin_heads` 앞면
- `explore.coin_tails` 뒷면
- `explore.rift_item_lost` [{item}]이(가) 균열을 나서는 순간 빛을 잃고 흩어졌다.
- `explore.rift_opened` 동굴 곳곳에 균열 포탈 {count}개가 열렸다!
- `explore.rift_forced` 기념비가 마석을 삼키고, 옆에 {name}(으)로 통하는 균열 포탈이 열렸다.
- `explore.rift_offer` 대현자 기념비에 {item}을(를) 바쳤다.
- `explore.rift_offer_failed` 마석이 잠시 빛나다 꺼졌다. 균열이 열릴 자리를 찾지 못했다 — 마석은 그대로다.
- `explore.rift_portal_found` 붉게 일렁이는 균열 포탈이 보인다.
- `explore.rift_portal_here` 균열 포탈 앞이다.
- `explore.rift_enter` 균열 속으로 발을 들였다 — {name}.
- `explore.rift_chapter` [{rift} {n}/{total}] {chapter} — {desc}
- `explore.rift_variant` 공기가 무겁다. 이곳의 수호자는 평소와 다르다…
- `explore.rift_next_wave` 숨 돌릴 틈도 없이 다음 무리가 덮친다! (남은 무리 {left})
- `explore.rift_exit_found` 앞쪽에 출구가 보인다.
- `explore.rift_exit_here` 출구 앞이다.
- `explore.rift_left` {name}에서 빠져나왔다. 수정동굴의 공기가 반갑다.
- `explore.lord_summoned` 수정의 광채가 핏빛으로 바뀐다. 무언가가 깨어났다 — {name}!
- `explore.lord_bond` 동료들과의 결속이 끊어진 듯 서로의 기척이 멀어진다. 눈앞이 어둑해진다.
- `explore.lord_defeated` {name}이(가) 무너져 구더기 더미가 된다. 수정의 빛이 제 색을 되찾는다.
- `explore.lord_vanished` 핏빛 광채가 걷히고, 그것은 소리 없이 사라졌다.
- `explore.enter` {floor}. 발밑이 차갑다. 포탈은 등 뒤에서 닫혔다.
- `explore.wait` 숨을 죽이고 {hours}시간을 기다렸다.
- `explore.rest_safe` 안전한 자리에서 {hours}시간을 잤다. 몸이 조금 풀렸다.
- `explore.rest_unsafe` 벽에 기대 {hours}시간을 졸았다. 쉰 것 같지 않다.
- `explore.no_item` {item}이(가) 없다.
- `explore.no_category` 가진 {category}이(가) 없다.
- `explore.grave_wakes` 늪 어딘가의 비석 아래에서 무언가가 일어났다.
- `explore.portal_locked` {floor}층으로 가는 포탈이다. 소용돌이가 아직 닫혀 있어 그 너머로 갈 수 없다.
- `explore.monument` 대현자 기념비. 이 근처에는 아무것도 다가오지 않는다.
- `explore.monument_opt_offer` {item} {n}개를 바친다
- `explore.monument_opt_stone` {item}을(를) 바친다
- `explore.monument_opt_lord` {name}을(를) 부른다
- `explore.monument_why_kills` 받지 않는다
- `explore.monument_why_lord` 기척이 남아 있다
- `explore.monument_lord_call` 비석에 손을 얹자 발밑 깊은 곳에서 무언가가 대답한다.
- `explore.nothing_here` 살펴볼 만한 것이 없다.
- `explore.closing_soon` 공기가 무거워진다. 층이 닫히기까지 {hours}시간.
- `explore.closed` 층이 닫힌다. 보이지 않는 힘이 몸을 끌어당긴다.
- `explore.landmark_found` {name}을(를) 발견했다. {desc}
- `explore.portal_found` {dir}에서 포탈의 빛을 보았다.
- `explore.portal_here` 포탈 위에 섰다.
- `explore.safe_enter` 고요함이 감싼다. 안전지대다 — 여기서는 쉴 수 있다.
- `explore.safe_leave` 안전지대를 벗어났다.
- `explore.dark_enter` 수정 빛이 닿지 않는 곳이다. 한 치 앞도 보이지 않는다.
- `explore.status_on` [{status}] 상태가 되었다.
- `explore.status_off` [{status}] 상태에서 벗어났다.
- `explore.light_out` {item}이(가) 꺼졌다. 어둠이 다가온다.
- `explore.died` 숨이 멎었다.
- `explore.hud_time` 미궁 {day}일차 {time} · 폐쇄까지 {left}시간
- `explore.light_torch` 횃불 (남은 {hours}시간) · 시야 {vision}m
- `explore.light_ambient` 주변 빛 · 시야 {vision}m
- `explore.light_dark` 암흑 · 시야 {vision}m
- `explore.hud_safe` 안전지대
- `explore.hud_found` 발견: 랜드마크 {landmarks}/{landmarks_total} · 포탈 {portals}/{portals_total}
- `explore.hud_name` {name} · {race} {template} · 레벨 {level}
- `explore.hud_status` 상태: {list}
- `explore.hud_status_none` 상태: 이상 없음
- `explore.hud_items` 소지품: {list}
- `explore.hud_items_none` 소지품: 없음
- `explore.cannot_use` {item}은(는) 여기서 쓸 수 있는 물건이 아니다.
- `explore.paused` 일시정지
- `explore.ambush` 잠결에 무언가가 다가왔다!
- `explore.glacier_crystal` 연못 바닥에서 붉은 빛이 일렁인다.
- `explore.glacier_shard` 금 간 기둥을 부수자 얼음 조각이 굴러 나왔다.
- `explore.hazard_pass` 위험한 길을 무사히 지났다.
- `explore.hazard_fail` 발을 헛디뎠다!
- `explore.hazard_slick_pass` 미끄러운 얼음 위를 조심조심 건넜다.
- `explore.hazard_slick_fail` 얼음에 미끄러져 크게 넘어졌다!
- `explore.hazard_slope_pass` 얼음 급경사를 버티며 내려갔다.
- `explore.hazard_slope_fail` 급경사에서 미끄러져 바닥까지 굴렀다!
- `explore.hazard_rope_pass` 언 로프를 붙잡고 끝까지 건넜다.
- `explore.hazard_rope_fail` 언 로프를 놓쳐 아래로 떨어졌다!
- `explore.mine_gem` 철로가 끊긴 벽을 부수자 좁은 샛길이 나왔다. 안쪽에서 무언가 초록빛으로 반짝인다.
- `explore.mine_quartz` 광맥을 깨뜨리자 탁한 초록 수정이 떨어졌다.
- `explore.mine_explosive` 낡은 상자 속에 광부들이 숨겨 둔 것이 있다.
- `explore.mine_blast` 무너진 갱도가 뚫렸다.
- `explore.mine_smash` 무너진 바위를 맨손으로 밀어 치웠다.
- `explore.rift_exit_forced` 힘으로 길을 열었다.
- `explore.hazard_bridge_pass` 무너진 다리의 남은 들보를 딛고 건넜다.
- `explore.hazard_bridge_fail` 들보가 부러져 아래로 떨어졌다!
- `explore.hazard_stairs_pass` 절벽의 원형 계단을 조심조심 내려갔다.
- `explore.hazard_stairs_fail` 계단이 무너져 몇 단을 굴러떨어졌다!
- `explore.trap_detected` 바닥 문양이 미묘하게 어긋나 있다 — 함정이다!
- `explore.trap_disarmed` 함정의 장치를 조심스럽게 풀었다.
- `explore.trap_crushed` 함정을 밟아 그대로 짓뭉갰다. 이 정도로는 흠집도 안 난다.
- `explore.trap_plate_fail` 압력판이 꺼지며 벽에서 쇠말뚝이 튀어나왔다!
- `explore.trap_arrow_fail` 벽 틈에서 화살이 쏟아졌다!
- `explore.trap_blades_fail` 회전 칼날에 베였다!
- `explore.groove_blade_cut` 홈을 따라 미끄러져 온 칼날이 몸을 긋고 지나갔다.
- `explore.groove_blade_break` 홈에서 달려든 칼날이 몸에 부딪혀 그대로 부러졌다.
- `explore.mural_read` 벽화를 들여다본다. {hint}
- `explore.riddle_pass` 문지기가 창을 거두고 옆으로 비켜선다.
- `explore.riddle_weaken` 문지기를 묶던 봉인이 풀린다 — 약해진 문지기가 창을 겨눈다.
- `explore.riddle_wrong` 틀렸다. 문지기의 문양이 붉게 타오른다!
- `explore.hud_fatigue` 피로도 {value}
- `explore.hidden_revealed` 무언가 드러났다.
- `explore.hidden_locked` 지금은 아무것도 할 수 없다.
- `explore.hidden_failed` 손에 넣지 못했다.
- `explore.hidden_decoy` 손대자마자 무너져 내렸다.

### `explore.boss_notice`

> 방에서 기다리는 보스·중간 보스가 플레이어를 보고 전투에 들어가기 직전 대화창 한 줄(사용자 2026-10-28, V17 — 몬스터 id별, 없으면 any). 전투 안 첫 대사(combat.<보스>_intro)와 이어지게 쓴다

- `explore.boss_notice.death_knight` 무너진 비석 곁에 검은 갑주의 기사가 서 있다. 투구 틈의 붉은 빛이 이쪽을 향한다.
- `explore.boss_notice.any` {name}이(가) 당신을 응시한다.
- `explore.boss_notice.blater` 녹슨 갑옷의 기사가 천천히 고개를 든다. 투구 틈의 붉은 눈이 당신을 응시한다.
- `explore.boss_notice.kambormir` 창백한 사내가 천천히 고개를 돌린다. 핏기 없는 입가에 웃음이 번진다.
- `explore.boss_notice.corpse_golem` 엉겨 붙은 시체 더미가 몸을 돌린다. 수십 개의 흐린 눈이 한꺼번에 당신을 향한다.
- `explore.boss_notice.katumba` 눈보라 속 흰 거체가 움직임을 멈춘다. 무언가 당신을 내려다보고 있다.
- `explore.boss_notice.tarunbas` 얼음 가루 너머에서 회백색 짐승이 몸을 일으킨다. 핏발 선 두 눈이 당신을 노려본다.
- `explore.boss_notice.kirdui` 웅크린 검은 거체는 꼼짝하지 않는다. 눈만이 당신을 따라 움직인다.
- `explore.boss_notice.goblin_bomber` 폭약 주머니를 주렁주렁 단 고블린이 당신을 발견하고 누런 이를 드러낸다.
- `explore.boss_notice.king_slime` 공동 한가운데의 거대한 점액 덩어리가 출렁임을 멈춘다. 당신 쪽으로 몸을 기울인다.
- `explore.boss_notice.ildium` 강철 거인이 투구를 들어 올린다. 텅 빈 눈구멍이 당신을 응시한다.

### `explore.party`

- `explore.party.no_stones` 마석이 모자라다
- `explore.party.no_item` 가진 것이 없다
- `explore.party.rumor_portal` {dir} 끝에 위층으로 오르는 포탈이 있다고 한다.
- `explore.party.rumor_rift` {dir}에서 균열을 봤다고 한다.

#### `explore.party.title`

- `explore.party.title.rookie` 탐험가 {n}명
- `explore.party.title.wounded` 다친 탐험가
- `explore.party.title.fighting` 싸우는 탐험가 {n}명
- `explore.party.title.raider` 약탈자 {n}명

#### `explore.party.opt`

- `explore.party.opt.trade` {item} {n}개 ↔ 9등급 마석 {price}개
- `explore.party.opt.rumor` 소문을 묻는다
- `explore.party.opt.follow` 함께 다닌다
- `explore.party.opt.leave` 지나간다
- `explore.party.opt.give_potion` 포션을 건넨다
- `explore.party.opt.give_food` 식량을 건넨다
- `explore.party.opt.help` 돕는다
- `explore.party.opt.pay` 마석 절반을 내놓는다
- `explore.party.opt.fight` 싸운다

### `explore.hidden`

- `explore.hidden.tomb_oil` 벽감 깊숙이 봉해진 기름 단지가 그대로 있다. 묘지기들이 관절에 바르던 것이다.
- `explore.hidden.tomb_oil_locked` 벽감 안의 기름 단지가 깨져 있다. 함정이 울린 진동에 쓰러진 모양이다.
- `explore.hidden.steel_relic_reveal` 칼날이 부서지며 홈 바닥이 갈라졌다. 틈에서 작은 함 하나가 굴러 나왔다.
- `explore.hidden.steel_relic` 작은 함 속에 쇳빛 구슬이 들어 있다.
- `explore.hidden.coffin_locked` 관 뚜껑에 봉인이 걸려 있다. 문지기의 물음에 답한 자만 열 수 있을 것 같다.
- `explore.hidden.death_mask` 봉인이 풀린 관 안, 이름 모를 왕의 얼굴에 가면이 씌워져 있다.
- `explore.hidden.treasure_mark` 금화 사이에 벽화와 같은 문양이 새겨진 상자가 묻혀 있다.
- `explore.hidden.treasure_plain` 금화가 수북하다. 아무 문양도 없다.
- `explore.hidden.treasure_cursed` 금화가 손안에서 잿가루로 부서졌다. 차가운 기운이 등줄기를 타고 오른다.
- `explore.hidden.tomb_gold` 금화 더미 속을 헤집었다.
- `explore.hidden.fortress_key` 고문대 손잡이에 녹슨 열쇠꾸러미가 걸려 있다.
- `explore.hidden.wagon_locked` 수레 짐칸에 자물쇠가 채워져 있다.
- `explore.hidden.silver_chest` 열쇠가 맞았다. 짐칸 깊숙한 곳에 무언가 실려 있다.
- `explore.hidden.falls_locked` 물보라가 거세다. 젖은 몸으로는 폭포 뒤로 들어갈 엄두가 나지 않는다.
- `explore.hidden.snow_lotus` 폭포 뒤 바위틈에 얼음꽃 한 송이가 피어 있다.
- `explore.hidden.ice_core_locked` 얼음 가루가 쉴 새 없이 쏟아져 고드름 속이 보이지 않는다.
- `explore.hidden.eternal_ice` 가루가 그친 공동, 고드름 속에 푸른 결정이 갇혀 있다.
- `explore.hidden.cart_fail` 광차를 힘껏 밀었지만 바퀴가 철로에서 빠지며 옆으로 넘어졌다.
- `explore.hidden.mine_heart` 광차가 무너진 벽을 들이받자 숨은 갱도가 열렸다. 안쪽에서 무언가 빛난다.
- `explore.hidden.vein_reveal` 다리를 건너뛰는 순간, 아래 벼랑에 녹색 광맥이 드러난 것이 보였다.
- `explore.hidden.green_vein` 벼랑에 붙은 광맥이 드러나 있다.

<a id="effect"></a>
## 효과 `effect`

> 아이템·스킬 효과 결과 알림

- `effect.smite_heal` 여신의 눈물이 {name}의 상처를 감싼다.
- `effect.status_resisted` {name}은(는) [{status}]을(를) 버텨 냈다.
- `effect.status_broken` {name}의 [{status}]이(가) 풀렸다.
- `effect.restore` {resource}이(가) {amount}만큼 변했다.
- `effect.restore_none` {resource}은(는) 이미 가득하다.
- `effect.light_on` 횃불에 불을 붙였다. {hours}시간쯤 탈 것이다.
- `effect.light_already` 이미 횃불이 타고 있다. (남은 {hours}시간)
- `effect.status_on` [{status}] 상태가 되었다.
- `effect.status_on_named` {name}은(는) [{status}] 상태가 되었다.
- `effect.status_off` [{status}] 상태가 풀렸다.
- `effect.status_immune` {name}에게는 [{status}]이(가) 듣지 않는다.
- `effect.barrier_on` {name} 앞에 보호막이 선다({amount}).
- `effect.boon` {stat}이(가) 영구히 {amount} 올랐다. ({n}/{max})
- `effect.boon_limit` {name}은(는) 이미 이 효과를 {max}번 받았다. 더는 듣지 않는다.
- `effect.fatigue_down` 피로가 {amount}만큼 풀렸다.
- `effect.fatigue_up` 피로가 {amount}만큼 쌓였다.
- `effect.fatigue_none` 지친 데가 없다.
- `effect.battle_only` 싸울 때 쓰는 물건이다.

<a id="debug"></a>
## 디버그 `debug`

> F1 디버그 패널

- `debug.rift_force_open` 균열 강제 개방
- `debug.rift_clear_chapter` 이 챕터 조우 치우기
- `debug.give_rift_stones` 기념비 준비(마석 넷·네 종 처치)
- `debug.lord_ready` 수호자 넷 처치로 표시
- `debug.summon_lord` 계층군주 소환(드레드피어)
- `debug.add_companion` 동료 들이기(무작위 탐험가)
- `debug.title` 디버그 (F1)
- `debug.skip` +{hours}시간
- `debug.close_soon` 폐쇄 1시간 전
- `debug.reveal` 안개 걷기
- `debug.to_monument` 기념비로
- `debug.to_portal` 가까운 포탈로
- `debug.level_up` 레벨 +1
- `debug.level_down` 레벨 -1
- `debug.stat_up` {stat} +{amount}
- `debug.hunger_zero` 허기 100
- `debug.restore` 모두 회복
- `debug.invulnerable` 무적 (생명력 1 아래로 안 떨어짐)
- `debug.seed_placeholder` 시드 (현재 {seed})
- `debug.regenerate` 다시 생성
- `debug.portal_open_locked` 포탈 즉시 개방 (M4)
- `debug.later` 다음 마일스톤에서: {list}
- `debug.spawn_monster` 몬스터 소환(바로 전투)
- `debug.give_essence` 정수 흡수(무작위)

<a id="pause"></a>
## 일시정지 `pause`

> Esc 정지 창

- `pause.resume` 계속
- `pause.abandon` 탐험 포기
- `pause.abandon_confirm` 정말 포기한다 (한 번 더)
- `pause.graphics` 그래픽 {quality}
- `pause.quality_high` 높음
- `pause.quality_low` 낮음

<a id="combat"></a>
## 전투 `combat`

> 전투 화면 — 명령 · 대화창 안내 · 보스 대사 · 전투 기록

- `combat.start` {enemies}와(과) 맞닥뜨렸다.
- `combat.group` {name} 무리
- `combat.start_ambushed` {enemies}이(가) 덮쳐 왔다!
- `combat.party` 탐험가
- `combat.menu_root` {name}의 차례
- `combat.menu_skill` 스킬
- `combat.menu_item` 아이템
- `combat.cmd_attack` 공격
- `combat.cmd_skill` 스킬
- `combat.cmd_guard` 방어
- `combat.cmd_item` 아이템
- `combat.cmd_flee` 도주
- `combat.sub_count` {n}개
- `combat.sub_chance` 성공 {chance}%
- `combat.sub_stack` ×{n}
- `combat.no_usable_item` 전투 중에 쓸 수 있는 소지품이 없다.
- `combat.brief_damage` {type} 피해 {power}%
- `combat.brief_hits` {text} ×{n}
- `combat.extra_turn` 추가 턴
- `combat.brief_status` [{status}]
- `combat.brief_status_chance` [{status}] {chance}%
- `combat.brief_barrier` 보호막
- `combat.brief_restore` {res} 회복
- `combat.brief_summon` 소환
- `combat.brief_delayed` 예고 공격
- `combat.brief_cleanse` 상태 해제
- `combat.brief_cooldown` 재사용 {n}차례
- `combat.target_line` {name} (생명력 {hp}%)
- `combat.miss` {source}의 공격이 빗나갔다.
- `combat.immune` {source}의 공격이 {target}에게 통하지 않는다.
- `combat.hit` {source} → {target}, {amount}의 피해.
- `combat.crit` {source}의 일격이 {target}의 급소를 스쳤다! {amount}의 피해.
- `combat.effective` 잘 먹힌다.
- `combat.lethal` {target}이(가) 치명상을 입고 무너진다.
- `combat.use_skill` {name}: [{skill}]
- `combat.use_item` {name}이(가) {item}을(를) 썼다.
- `combat.no_item` 쓸 아이템이 없다.
- `combat.guard` {name}이(가) 몸을 웅크려 방어한다.
- `combat.skip` {name}은(는) 움직이지 못한다.
- `combat.flee_ok` {name}이(가) 도망쳤다.
- `combat.flee_fail` {name}은(는) 도망치지 못했다.
- `combat.down_monster` {name}이(가) 빛 먼지로 흩어졌다.
- `combat.down_party` {name}이(가) 쓰러졌다.
- `combat.end_victory` 적이 모두 사라졌다.
- `combat.end_defeat` 숨이 끊어진다.
- `combat.end_fled` 가까스로 빠져나왔다.
- `combat.reason_sealed` 지금은 이능을 쓸 수 없는 상태다.
- `combat.reason_cooldown` 아직 다시 쓸 수 없다.
- `combat.skill_wait` {n}차례 대기
- `combat.skill_used_up` 다 씀
- `combat.skill_no_cost` 대가 부족
- `combat.skill_sealed` 봉인
- `combat.skill_unusable` 사용 불가
- `combat.no_effect` {name}의 [{skill}]은(는) 아무 효과도 내지 못했다.
- `combat.reason_cost` 대가를 치를 수 없다.
- `combat.reason_unknown` 그 기술은 모른다.
- `combat.reason_no_target` 대상이 더는 그 자리에 없다.
- `combat.talk_no_reply` {source}이(가) 말을 건넸지만 {target}은(는) 알아듣는 기색이 없다.
- `combat.talk_no_reply_beast` {source}의 목소리에 {target}이(가) 이빨을 드러내며 낮게 으르렁거린다.
- `combat.talk_no_reply_undead` {target}의 텅 빈 눈은 {source}을(를) 먹잇감으로만 본다.
- `combat.talk_no_reply_construct` {target}은(는) 돌처럼 아무 대답이 없다.
- `combat.talk_no_reply_humanoid` {target}이(가) 알 수 없는 소리로 끽끽대며 단검을 고쳐 쥔다.
- `combat.talk_waver` {source}의 말에 {target}이(가) 머뭇거린다.
- `combat.talk_ignore` {target}은(는) {source}의 말을 흘려듣는다.
- `combat.talk_provoke` {source}의 말이 {target}을(를) 자극했다. 서둘러 덤벼든다!
- `combat.talk_withdraw` {target}이(가) {source}의 말에 무기를 내리고 뒷걸음질 친다.
- `combat.withdraw` {name}이(가) 싸움에서 물러났다.
- `combat.info_monster` [조사] {name} — {grade}등급 {family}. 근력 {str} · 민첩 {agi} · 물리내성 {p_res} · 항마력 {m_res}. {desc}
- `combat.info_ally` [조사] {name} — 생명력 {hp}%.
- `combat.float_immune` 면역
- `combat.float_blocked` 막힘
- `combat.float_miss` 회피
- `combat.horde_left` +{n}
- `combat.float_heal` +{n}
- `combat.float_loss` -{n}
- `combat.drop_ask` {what} — 획득할까?
- `combat.drop_take` 획득한다
- `combat.drop_leave` 두고 간다
- `combat.drop_essence` {color} {name}
- `combat.drop_item` {item} ×{count}
- `combat.drop_cannot` 받을 수 없다.
- `combat.drop_who` 누가 받을까?
- `combat.result_victory` 승리
- `combat.result_defeat` 당신은 패배했다...
- `combat.result_fled` 도주
- `combat.reflect` {source}의 칼날털이 {target}에게 {amount}만큼 되돌려 베었다.
- `combat.counter` {source}이(가) 막아 내고 {target}을(를) 찔렀다 — {amount}.
- `combat.cover` {protector}이(가) {name} 앞을 막아선다.
- `combat.covered_hit` {protector}이(가) {name} 대신 공격을 받아 낸다.
- `combat.drain` {source}이(가) 피를 핥아 {amount} 회복했다.
- `combat.summon` {name}의 울부짖음에 {monster}이(가) 달려왔다!
- `combat.summon_ally` {name}이(가) {monster}을(를) 불러냈다.
- `combat.down_summon` {name}이(가) 흩어졌다.
- `combat.dot` {name}이(가) [{list}]으로 생명력 {amount}을(를) 잃었다.
- `combat.card_stacks` ×{n}
- `combat.card_barrier` ({n})
- `combat.dot_plain` {name}이(가) 생명력 {amount}을(를) 잃었다.
- `combat.summon_fail` {name}이(가) 울부짖었지만 아무도 오지 않았다.
- `combat.reason_hidden` 그 상대는 모습을 감추고 있다.
- `combat.reason_no_flee` 도망칠 길이 없다.
- `combat.reason_leader_only` 일행을 이끄는 사람만 할 수 있다.
- `combat.reason_veiled` 장막 너머의 동료를 알아볼 수 없다.
- `combat.reason_item_no_effect` 듣지 않는다
- `combat.tag_blocked` {name} · {why}
- `combat.sealed` {name}의 [{skill}]이(가) 봉인되었다.
- `combat.survive_round` 버텨라! ({round}/{total})
- `combat.pushed_back` {name}이(가) 밀려나 다음 차례가 늦어진다.
- `combat.telegraph_guarded` {name}이(가) 예고된 일격을 막아 냈다!
- `combat.marked` {source}의 원한이 {name}에게 새겨졌다 — [{status}]!
- `combat.regen` {name}의 상처가 아문다. (+{amount})
- `combat.extra_hit` {name}이(가) 한 번 더 문다!
- `combat.monster_type` {name} — 기운이 느껴진다.
- `combat.bone_knight_hatred` 경고: {name}은(는) 영혼을 베는 기사다. 레벨이 내려갈 수 있다!
- `combat.soul_slash_miss` {name}의 영혼이 서늘해졌지만 버텨 냈다.
- `combat.soul_slash_level` {name}의 영혼이 베였다 — 레벨 {level}(으)로 떨어졌다!
- `combat.soul_slash_essence` {name}의 영혼에서 [{essence}]이(가) 떨어져 나가 사라졌다!
- `combat.soul_slash_soul` {name}의 영혼력이 {amount} 흩어졌다.
- `combat.smite` 여신의 눈물이 {target}을(를) 태운다! ({amount})
- `combat.golem_skeleton` {name}의 살점이 무너져 내리고 뼈대가 드러난다!
- `combat.golem_mumble_1` {name}: "…춥다… 춥다… 누가 문을…"
- `combat.golem_mumble_2` {name}: "내 손… 내 손은 어디… 여기, 여기 있다…"
- `combat.golem_mumble_3` {name}: "배고파, 배고파, 같이 있자, 같이…"
- `combat.golem_mumble_4` {name}의 입 수십 개가 동시에 웃는다.
- `combat.guardian_frenzy` {name}이(가) 궁지에 몰려 광분한다 — 연달아 움직인다!
- `combat.blater_intro` {name}이(가) 녹슨 대검을 바닥에 끌며 일어선다. 원한이 공기를 무겁게 누른다.
- `combat.kambormir_intro` {name}: "손님이 오셨군. 피가 따뜻할 때 인사해 두지."
- `combat.survived` {rounds}라운드를 버텨 냈다!
- `combat.reinforce` {monster}이(가) 기어오른다!
- `combat.meter_full` {name}의 {meter}이(가) 가득 찼다 — {status}!
- `combat.meter_damage_none` {target}의 마음에는 비출 공포가 없다.
- `combat.delayed_warn` {name}의 주위로 죽은 자들의 기억이 모여든다…
- `combat.delayed_fire` {name}이(가) 불러 모은 기억이 쏟아진다!
- `combat.delayed_dropped` {name}이(가) 준비하던 공격이 흩어졌다.
- `combat.tarun_collapse_warn` {name}이(가) 얼음몽둥이를 높이 쳐든다 — 천장과 바닥에 금이 쩍쩍 간다!
- `combat.tarun_collapse_fire` {name}의 몽둥이가 지면을 내리찍는다 — 발밑이 무너진다!
- `combat.blater_sentence_warn` {name}이(가) 대검으로 한 사람을 가리킨다 — 사형 선고.
- `combat.blater_sentence_fire` {name}의 선고가 집행된다!
- `combat.misdirect` {name}의 공격이 빗나가 {target}에게 향한다!
- `combat.rows_shuffled` 대열이 뒤엉켰다!
- `combat.extra_action` {name}이(가) 한 번 더 움직인다!
- `combat.enrage` {name}의 숨이 거칠어진다. 휘두르는 손길에 망설임이 사라졌다.
- `combat.dread_p1` 수정의 빛이 핏빛으로 물든다. {name}이(가) 구더기를 흩뿌리며 다가온다.
- `combat.dread_p2` {name}의 공포가 스며든다. 손끝이 떨리고, 원망이 쌓이기 시작한다.
- `combat.dread_p3` {name}을(를) 둘러싼 증오가 짙어진다. 동료의 얼굴이 낯설게 보인다.
- `combat.dread_p4` 구더기가 흩어지고 {name}의 사람 형체가 드러난다!
- `combat.dread_proliferate` {name}의 공포가 불어난다({stacks}중첩).
- `combat.dread_veil` 배신의 장막이 내려앉는다 — 누가 동료인지 알 수 없다.
- `combat.dread_groggy` {name}이(가) 껍질 속으로 숨어 웅크린다. 지금이 기회다!
- `combat.dread_buff` {name}이(가) 껍질을 벗고 새 모습을 얻었다: {buff}.
- `combat.dread_flag_old_memory` {name}에게서 아주 오래된 기억이 스친다.
- `combat.dread_flag_twisted_memory` 마비독의 냄새에 {name}의 기억이 뒤틀린다.
- `combat.barrier_absorb` {name}의 보호막이 피해 {amount}을(를) 받아 냈다.
- `combat.rider_hit` {target}에게 {type} 피해 {amount}.
- `combat.aura_tick` {name}의 기운이 퍼진다 — [{status}].
- `combat.katumba_intro` 토템이 부서지며 거대한 흰 그림자가 내려선다. {name}이(가) 눈보라를 몰고 온다.
- `combat.tarunbas_intro` 얼음 가루가 쏟아지는 천장에서 {name}이(가) 뛰어내린다. 얼음몽둥이가 바닥을 울린다.
- `combat.tarunbas_roar` {name}이(가) 울부짖는다 — 몸이 부풀어 오르고 연달아 움직인다!
- `combat.kirdui_intro` 검은 거체가 몸을 일으킨다. {name}의 송곳니 사이로 김이 새어 나온다.
- `combat.split` {name}이(가) 둘로 갈라진다 — {monster}!
- `combat.absorb` {name}이(가) {target}을(를) 집어삼켰다.
- `combat.absorb_none` {name}이(가) 삼킬 것을 찾지 못했다.
- `combat.summon_expired` {name}이(가) 사라졌다.
- `combat.death_blast` {name}이(가) 쓰러지며 폭발한다!
- `combat.self_blast` {name}이(가) 제 몸의 폭발에 휘말렸다({amount}).
- `combat.bomber_cookoff` 불길이 폭약 주머니에 옮겨붙었다 — {name}의 허리춤이 터진다({amount})!
- `combat.bomber_fuse_warn` {name}이(가) 심지에 불을 붙인 폭탄을 굴린다!
- `combat.bomber_fuse_fire` {name}의 지연 폭탄이 터진다!
- `combat.king_jump_warn` {name}이(가) 몸을 잔뜩 웅크린다 — 천장까지 뛰어오를 기세다!
- `combat.king_jump_fire` {name}이(가) 떨어져 내리며 모두를 짓누른다!
- `combat.bomber_intro` {name}이(가) 폭약 주머니를 흔들며 낄낄댄다.
- `combat.king_slime_intro` 공동 한가운데에서 {name}이(가) 출렁인다.
- `combat.king_slime_split` {name}의 몸이 찢어지며 슬라임들이 떨어져 나온다!
- `combat.revive` {name}이(가) 다시 일어난다!
- `combat.buried_rise` 관 뚜껑이 열리듯 {name}이(가) 흙을 털며 다시 일어난다!
- `combat.endure` {name}이(가) 쓰러질 일격을 버텨 냈다!
- `combat.ildium_intro` 분묘 한가운데에서 {name}이(가) 삐걱거리며 몸을 일으킨다.
- `combat.ildium_overheat` {name}의 강철 몸이 벌겋게 달아오른다 — 힘이 세지고 몸이 물러진다!
- `combat.ildium_trap_warn` {name}이(가) 바닥을 내리친다!
- `combat.ildium_trap_fire` 분묘의 함정이 일제히 튀어 오른다!
- `combat.banner_skill` {skill}
- `combat.banner_item` {item}
- `combat.start_first` {enemies}을(를) 먼저 발견했다. 싸운다.
- `combat.split_blocked` {name}이(가) 그을린 몸을 비틀지만 갈라지지 못한다.

<a id="condition"></a>
## condition `condition`

> —

- `condition.peckish` {who}은(는) 배고픔을 느낀다.
- `condition.hungry` {who}은(는) 허기가 져 몸이 무겁다.
- `condition.famished` {who}은(는) 굶주려 있다.
- `condition.starving` {who}은(는) 굶주림에 쓰러질 것 같다.
- `condition.starvation` {who}의 몸이 스스로를 갉아먹는다.
- `condition.tired` {who}은(는) 피곤함을 느낀다.
- `condition.weary` {who}은(는) 지쳐 있다.
- `condition.spent` {who}은(는) 녹초가 되었다.
- `condition.collapse` {who}은(는) 쓰러질 것 같다.

<a id="knowledge"></a>
## 지식 `knowledge`

> 몬스터 약점·저항(전투에서 알게 될 때 · 도감)

- `knowledge.unknown` ???
- `knowledge.aff_weak` {type} 약점 ×{mult}
- `knowledge.aff_resist` {type} 저항 ×{mult}
- `knowledge.aff_immune` {type} 면역

<a id="reward"></a>
## 보상 `reward`

> 전투 드롭 · 획득할까? · 경험치

- `reward.first_kill` 처음 쓰러뜨린 {name} — 공적 {exp}.
- `reward.loot_left` {what}을(를) 두고 간다.
- `reward.essence_absorbed` {who}의 몸속으로 {what}이(가) 스며들었다.
- `reward.essence_refused` {what}이(가) {who}에게 스며들지 못했다. {reason}
- `reward.essence_left` {what}이(가) 빛 먼지가 되어 흩어졌다.
- `reward.essence_nobody` {what}이(가) 떨어졌지만 받아들일 수 있는 이가 없어 빛 먼지로 흩어졌다. {reason}
- `reward.bag_full` 가방에 자리가 없어 {item} ×{count}을(를) 두고 간다.
- `reward.level_up` 영혼이 한 겹 더 단단해졌다. 레벨 {level} (정수 슬롯 {slots}).
- `reward.guardian_bonus` 수호자 {name}을(를) 쓰러뜨렸다 — 공적 {exp}.
- `reward.lord_bonus` 계층군주 {name}을(를) 처음으로 쓰러뜨렸다 — 공적 {exp}.
- `reward.level_down` 영혼이 깎여 나갔다. 레벨 {level} — 정수 {locked}개가 잠들었다.

<a id="inventory"></a>
## 소지품 `inventory`

> Tab 메뉴 소지품 쪽

- `inventory.discarded` {item} ×{count}을(를) 버렸다.
- `inventory.no_room_swap` 가방에 자리가 없어 {item}을(를) 바꿔 낄 수 없다.
- `inventory.no_room_unequip` 가방에 자리가 없어 {item}을(를) 벗을 수 없다.
- `inventory.title` 소지품
- `inventory.equipped` 장착 중
- `inventory.weapon_line` 공격력 {attack} · {type}
- `inventory.magic_power` 마력
- `inventory.two_handed` 양손
- `inventory.size` 크기
- `inventory.price` ◆ {price} 스톤
- `inventory.max_of` {res} 최대치
- `inventory.regen_of` {res} 재생
- `inventory.eff_restore` {res} +{amount}
- `inventory.eff_lower` {res} -{amount}
- `inventory.eff_restore_either` {res} +{amount} 또는 +{pct}%
- `inventory.eff_restore_pct` {res} +{pct}%
- `inventory.eff_lower_pct` {res} -{pct}%
- `inventory.eff_light` 빛 {m}m · {hours}시간
- `inventory.eff_status` {status} ({chance}%)
- `inventory.sort` 정렬
- `inventory.money` ◆ {amount}
- `inventory.summary` 공격 {attack} ({type}) · 물리내성 {p_res}
- `inventory.act_equip` 장착한다
- `inventory.act_use` 사용한다
- `inventory.act_move` 옮긴다
- `inventory.act_discard` 버린다
- `inventory.act_unequip` 벗는다

<a id="party"></a>
## party `party`

> —

- `party.title` 아군
- `party.fatigue` 피로
- `party.nameless` 이름 없는 탐험가
- `party.front` 전위
- `party.back` 후위
- `party.release` 파티에서 내보낸다
- `party.release_ask` {name}을(를) 파티에서 내보낼까?
- `party.release_yes` 내보낸다
- `party.release_no` 그만둔다
- `party.no_release_self` 자신은 내보낼 수 없다
- `party.mate_name` {race} {class}
- `party.mate_died` {name}이(가) 숨을 거두었다.
- `party.full` 파티가 가득 찼다

<a id="character"></a>
## 캐릭터 `character`

> Tab 메뉴 캐릭터 쪽

- `character.title` 캐릭터
- `character.level_line` {race} · 레벨 {level} · 공적 {exp} / {next}
- `character.max` 최대
- `character.attack` 공격력
- `character.crit` 치명타율
- `character.attack_type` 기본 공격: {type}
- `character.essence_slots` 정수 슬롯 {n}칸
- `character.sub_stats` 세부 능력치
- `character.boons` 영구 강화
- `character.boon_line` {item} → {stat} ({n}회)
- `character.passives` 패시브
- `character.passive_line` · {name} — {desc}
- `character.statuses` 걸린 상태
- `character.none` 없음
- `character.inert_mark` *

<a id="codex"></a>
## codex `codex`

> —

- `codex.monsters` 몬스터
- `codex.section` {name}  {n}
- `codex.entry` 『{name}』
- `codex.lore_empty` 아직 읽은 대목이 없다.
- `codex.lore_text` 『{name}』

{text}

<a id="bestiary"></a>
## 도감 `bestiary`

> Tab 메뉴 도감 쪽

- `bestiary.title` 도감
- `bestiary.entry` {name} ({kills})
- `bestiary.empty` 아직 마주친 몬스터가 없다.
- `bestiary.head` {name} — {grade}등급 · {family}
- `bestiary.kills` 처치 {kills} · 첫 처치 공적 {exp}
- `bestiary.stats` 생명력 {hp} · 근력 {str} · 민첩 {agi} · 물리내성 {p_res} · 항마력 {m_res}
- `bestiary.stats_unknown` 생명력·스탯: ???
- `bestiary.affinity` 상성: {aff}
- `bestiary.variant_of` {name}의 변이종.
- `bestiary.shared` [{skill}] 이능을 함께 지닌 종: {list}

<a id="essence"></a>
## 정수 `essence`

> 정수 칸·설명

- `essence.slots` 정수 {used} / {n}칸
- `essence.title` {color} {name}
- `essence.grade` {n}등급
- `essence.stat_inert` (아직 효과 없음)
- `essence.tip_passive` 패시브 · {name}: {desc}
- `essence.row_passive` 패시브
- `essence.row_skill` 이능
- `essence.row_stats` 능력치
- `essence.tip_skills` 이능 · {list}
- `essence.tip_stats` 능력치 · {list}
- `essence.not_implemented` (이 패시브의 효과는 아직 일부만 들어가 있다)
- `essence.reason_unknown` 알 수 없는 정수다.
- `essence.reason_no_slot` 빈 정수 슬롯이 없다.
- `essence.reason_duplicate` 이미 같은 이능이 영혼에 새겨져 있어 받아들일 수 없다.
- `essence.locked_suffix`  (잠김)

<a id="riddle"></a>
## 수수께끼 `riddle`

> 강철의 묘 수수께끼 창

- `riddle.title` 수수께끼 문지기
- `riddle.correct` "맞았다." 문지기가 묻는다 — 그냥 지나가겠는가, 봉인이 풀린 나와 겨루겠는가?
- `riddle.choose_pass` 그냥 지나간다
- `riddle.choose_weaken` 약해진 문지기와 싸운다

<a id="plaza"></a>
## 차원광장 `plaza`

> 도시 → 미궁 포탈 화면 버튼

- `plaza.save` 기록을 남긴다
- `plaza.saved` 기록을 남겼다
- `plaza.save_failed` 기록을 남기지 못했다
- `plaza.enter` 포탈로 들어간다
- `plaza.clerk` 탐험가 길드 직원
- `plaza.settle_tag` 길드 직원이 신원패를 받아 든다. "{name} 님, {grade}등급 탐험가. 무사히 돌아오셨군요."
- `plaza.settle_lot` {grade}등급 마석 {n}개
- `plaza.settle_count` "{list}. 확인했습니다."
- `plaza.settle_total` "정산하면 {n} 스톤입니다." 직원이 스톤 꾸러미를 내민다.
- `plaza.settle_none` "가져오신 마석은 없군요. 다음엔 빈손으로 오지 마세요."

<a id="city"></a>
## 도시 `city`

> 도시 — 거리·시설·활동 결과(lines)·거리 사건(street)·세금

- `city.place` {city} · {district}
- `city.date` {month}번째 달 {period}
- `city.date_year` {year}년째 {month}번째 달 {period}
- `city.fatigue_label` 피로도
- `city.fatigue_value_max` {value} / {max}
- `city.hud_fatigue_tier`  · {tier}
- `city.money_label` 소지금
- `city.ap_label` 행동력
- `city.ap_value` {ap} / {max}
- `city.btn_title` 타이틀로
- `city.leave` 나가기
- `city.choice` {name}  ({cost})
- `city.cost_stones` {n} 스톤
- `city.did` — {name} —
- `city.spent_stones` {n} 스톤을 치렀다.
- `city.info_merit` 신전 공적치 {merit}
- `city.info_balance` 은행 잔액 {balance} 스톤
- `city.info_lore` 읽은 대목 {n}
- `city.info_survey` 의뢰 {name} 조사 {n}/{cap} · 한 마리 {stones} 스톤
- `city.reason_unknown` 알 수 없는 시설·활동이다.
- `city.reason_inside` 이미 시설 안에 있다.
- `city.reason_no_ap` 행동력이 모자란다.
- `city.reason_no_money` 돈이 모자란다.
- `city.reason_not_here` 이 시설에서 할 수 없는 활동이다.
- `city.reason_panel` 이 활동은 창구에서 한다.
- `city.reason_not_sold` 팔지 않는 물건이다.
- `city.reason_bag_full` 가방에 자리가 없다.
- `city.reason_cannot_sell` 팔 수 없는 물건이다.
- `city.reason_bad_amount` 금액을 1 스톤 이상 넣어야 한다.
- `city.reason_no_balance` 맡긴 돈이 그만큼 없다.
- `city.reason_no_essence` 그 정수는 없다.
- `city.shop_bought` {item} {n}개를 {price} 스톤에 샀다.
- `city.shop_sold` {item} {n}개를 {price} 스톤에 넘겼다.
- `city.bank_status` 잔액 {balance} 스톤 · 소지금 {money} 스톤
- `city.bank_amount` 금액
- `city.bank_all_money` 소지금 전부
- `city.bank_all_balance` 잔액 전부
- `city.bank_deposit` 맡기기
- `city.bank_withdraw` 찾기
- `city.bank_deposited` {amount} 스톤을 맡겼다.
- `city.bank_withdrew` {amount} 스톤을 찾았다.
- `city.essence_cost` 제거 비용 {cost} 스톤 (소지금 {money})
- `city.essence_line` {name} ({color})
- `city.essence_locked`  [잠김]
- `city.essence_none` 흡수한 정수가 없다.
- `city.essence_remove` 제거
- `city.essence_confirm` 정말 제거 ({cost})
- `city.essence_removed` {name} 정수가 몸에서 빠져나갔다. {cost} 스톤을 치렀다.
- `city.debug_title` 도시 디버그 (F1)
- `city.debug_set_date` 날짜 바꾸기
- `city.debug_next_period` 다음 순
- `city.debug_ap` 행동력
- `city.debug_fatigue` 피로도
- `city.debug_apply` 적용
- `city.debug_undecided` 도시 규칙 값 임시로 바꾸기(JSON, 빈 칸 = 데이터 값)
- `city.debug_apply_overrides` 임시값 적용
- `city.debug_clear_overrides` 임시값 모두 지우기
- `city.debug_applied` 임시값 {n}개 적용.
- `city.debug_bad` 읽을 수 없는 값: {list}
- `city.debug_cleared` 임시값을 모두 지웠다.
- `city.expedition_auto` {date}이 저물었다. 미궁으로 향한다.
- `city.debug_dungeon` 미궁으로
- `city.date_weather` {date} · {weather}
- `city.bank_withdrew_fee` {amount} 스톤을 찾았다. 수수료로 {fee} 스톤이 빠졌다.
- `city.cannot_use_here` 여기서는 쓸 수 없다.
- `city.key_menu` 메뉴 {key}
- `city.key_pause` 정지 {key}
- `city.shop_money` 소지금 {money} 스톤
- `city.shop_sub_buy` 사기 {price} 스톤
- `city.shop_sub_sell` 팔기 {price} 스톤
- `city.shop_sell_name` {item} ×{n}
- `city.hud_tax` 세금 {n} 스톤 · {month}번째 달까지
- `city.reason_tax_none` 낼 세금이 없다
- `city.travel_title` 어디로 갈까
- `city.travel_cancel` 그만둔다
- `city.reason_no_books` 이 분야는 다 읽었다
- `city.debug_reroll` 사건 다시
- `city.debug_tax_due` 세금 기한으로
- `city.debug_life` 사건 {events} · 거리 {street} · 세금 {tax}(냄 {paid})
- `city.shop_tab_buy` 구매
- `city.shop_tab_sell` 판매
- `city.reason_closed` 문이 닫혀 있다
- `city.debug_street` 거리 사건
- `city.reason_no_item` 필요한 물건이 없다.
- `city.reason_read_this_visit` 오늘은 이 분야를 이미 읽었다

### `city.town`

> 도시 동네 지도(TownView, CT82) — 화면으로 알 수 없는 것만.

- `city.town.portal_closed` 돌 고리는 잠잠하다.

### `city.fx`

- `city.fx.fatigue_same` 몸 상태는 그대로다.
- `city.fx.fatigue_undecided` 피로도 변화량이 정해지지 않았다(미정) — 피로도 그대로
- `city.fx.stat_up` {stat}이 늘었다.
- `city.fx.stat_fail` 별다른 소득은 없었다.
- `city.fx.stat_no_amount` 능력치 상승량이 정해지지 않았다(미정) — 오르지 않음
- `city.fx.stat_undecided` 능력치 상승 대상·확률이 정해지지 않았다(미정) — 오르지 않음
- `city.fx.book_new` 『{name}』
{text}
- `city.fx.book_none` 서가를 다 뒤졌지만 처음 보는 대목은 없었다.
- `city.fx.book_undecided` 책을 읽는 규칙이 정해지지 않았다(미정) — 얻은 것 없음
- `city.fx.merit` 신전 일을 거들었다. 신관이 고개를 끄덕인다.
- `city.fx.merit_undecided` 봉사활동 공적치가 정해지지 않았다(미정) — 공적치 그대로
- `city.fx.fatigue_up` 몸이 무겁다.
- `city.fx.fatigue_down` 몸이 한결 가볍다.
- `city.fx.restore` 상처가 아물고 머리가 맑아졌다.
- `city.fx.restore_full` 다친 데도 없이 개운하게 일어났다.
- `city.fx.restore_undecided` 몸 상태는 그대로다. (미정)
- `city.fx.item_no_room` {name}을(를) 넣을 자리가 없다.
- `city.fx.item_undecided` 받을 것이 정해지지 않았다. (미정)
- `city.fx.tax_paid` 세금 {n} 스톤을 냈다. 납부 증서에 붉은 인장이 찍힌다.
- `city.fx.money_lost` {n} 스톤을 잃었다.
- `city.fx.money_got` {n} 스톤을 받았다.
- `city.fx.closed` {name}이(가) 문을 닫았다.
- `city.fx.no_tags` 신원패가 없다.
- `city.fx.tags_returned` 신원패 {n}장을 넘기고 {stones} 스톤을 받았다.
- `city.fx.no_records` 넘길 기록이 없다.
- `city.fx.records_sold` 기록 {n}건을 넘기고 {stones} 스톤을 받았다.
- `city.fx.no_survey` 의뢰받은 조사가 없다.
- `city.fx.survey_paid` {name} 조사 {n}건을 넘기고 {stones} 스톤을 받았다.
- `city.fx.meal_none` 오늘은 내올 요리가 없다고 한다.
- `city.fx.item_boon` {stat}이(가) 단단해졌다.
- `city.fx.item_boon_none` 해독할 책이 없다.
- `city.fx.item_boon_known` 이미 읽어 낸 책이다.

### `city.lines`

> 활동별 결과 문구(city.fx.<결과>·city.spent_stones 대신). 번호가 여럿이면 그중 하나(CityLines). 게임 용어·수치 나열 대신 장면을 쓴다.

#### `city.lines.inn_rest`

- `city.lines.inn_rest.spent_stones.1` 숙박비로 {n} 스톤을 냈다.

- `city.lines.inn_rest.fatigue_down.1` 삐걱거리는 침대였지만 오랜만에 깊이 잠들었다.
- `city.lines.inn_rest.fatigue_down.2` 푹 자고 일어나니 몸이 한결 가볍다.
- `city.lines.inn_rest.fatigue_down.3` 옆방 코골이에도 아랑곳없이 곯아떨어졌다.

- `city.lines.inn_rest.fatigue_same.1` 피곤하지도 않은데 괜히 침대에서 뒹굴었다.

- `city.lines.inn_rest.restore.1` 눅눅한 이불이었지만 상처가 꾸덕하게 아물었다.
- `city.lines.inn_rest.restore.2` 깊이 자고 나니 쑤시던 곳이 잠잠하다.

- `city.lines.inn_rest.restore_full.1` 멀쩡한 몸으로 하룻밤을 늘어지게 잤다.

#### `city.lines.inn_snack`

- `city.lines.inn_snack.spent_stones.1` {n} 스톤을 내고 구석 자리에 앉았다.

- `city.lines.inn_snack.fatigue_down.1` 허기를 달래고 나니 다리에 힘이 조금 돌아왔다.
- `city.lines.inn_snack.fatigue_down.2` 멀건 죽이라도 속이 데워지니 살 만하다.

- `city.lines.inn_snack.fatigue_same.1` 그릇을 비웠지만 피곤은 그대로다.

#### `city.lines.inn_hearty`

- `city.lines.inn_hearty.spent_stones.1` 넉넉히 {n} 스톤을 치렀다.

- `city.lines.inn_hearty.fatigue_down.1` 배가 터지도록 먹고 나니 몸이 다시 내 것 같다.
- `city.lines.inn_hearty.fatigue_down.2` 기름진 한 상을 비우자 눈이 맑아졌다.

- `city.lines.inn_hearty.fatigue_same.1` 든든하게 먹었다.

#### `city.lines.inn_meal`

- `city.lines.inn_meal.spent_stones.1` 밥값으로 {n} 스톤을 냈다.

- `city.lines.inn_meal.fatigue_down.1` 배가 든든해지니 굳은 어깨가 풀렸다.
- `city.lines.inn_meal.fatigue_down.2` 뜨끈한 것이 들어가니 그제야 살 것 같다.
- `city.lines.inn_meal.fatigue_down.3` 시끄러운 홀 구석에서 배불리 먹었다.

- `city.lines.inn_meal.fatigue_same.1` 느긋하게 그릇을 비웠다.

#### `city.lines.temple_service`

- `city.lines.temple_service.merit.1` 신전 바닥을 닦고 촛농을 긁어냈다. 신관이 고개를 끄덕인다.
- `city.lines.temple_service.merit.2` 구호소에서 죽을 나눠 주었다. 손등이 데었다.
- `city.lines.temple_service.merit.3` 제단의 향로를 닦았다. 손에 밴 향이 좀처럼 빠지지 않는다.

#### `city.lines.inn_feast`

- `city.lines.inn_feast.spent_stones.1` 특식 값으로 {n} 스톤을 냈다.

- `city.lines.inn_feast.fatigue_down.1` 접시를 다 비우고 나니 온몸에 기운이 돈다.
- `city.lines.inn_feast.fatigue_down.2` 오랜만에 사람 사는 맛을 봤다.

- `city.lines.inn_feast.fatigue_same.1` 접시를 깨끗이 비웠다.

#### `city.lines.library_decode`

- `city.lines.library_decode.item_boon.1` 밤새 검은 책장을 넘겼다. 마지막 장을 덮자 책은 재가 되어 흩어졌고, 어둠을 견디는 법만 머리에 남았다.
- `city.lines.library_decode.item_boon.2` 사서가 등불을 몇 번이나 갈아 주었다. 해독을 마친 책은 손안에서 바스러졌다.

### `city.tax_execution`

> 세금 기한(그해 tax.due_month 하순 끝)을 넘겼을 때 — 종족과 상관없이 교수형(원작, 사용자 2026-10-21). 이 장면 뒤 사망과 같다(CityTax).

- `city.tax_execution.1` 포탈 광장으로 가는 길목에서 경비대가 앞을 막는다. 대장이 장부를 펼친다.
- `city.tax_execution.2` "올해 세금 납부 기록이 없군." 대답을 기다리는 사람은 아무도 없다.
- `city.tax_execution.3` 광장 끝 교수대에 밧줄이 하나 더 걸린다.

### `city.street`

> 거리 사건(CityAmbient, data/street_events) — intro.<n> 장면(차례로 모두), <결과>.<n> 결과 장면(결과 = result 또는 선택지 id, 판정이 있으면 _ok·_fail), choice.<선택지 id> 선택지 이름. 결과 장면에는 효과 인자({n} 스톤, {name} 시설)를 쓸 수 있다.

#### `city.street.hanging`

- `city.street.hanging.intro.1` 광장 끝 교수대 앞에 사람들이 모여 있다. 지난해 세금을 내지 못한 자들이다.
- `city.street.hanging.intro.2` 인간도, 수인도, 드워프도 같은 줄에 서 있다. 밧줄은 종족을 묻지 않는다.
- `city.street.hanging.intro.3` 발판이 빠지는 소리가 몇 번 나고, 구경꾼들은 곧 제 갈 길로 흩어진다.

#### `city.street.tax_notice`

- `city.street.tax_notice.intro.1` 광장에 관리가 올라서서 두루마리를 편다.
- `city.street.tax_notice.intro.2` "올해 세금은 이번 달 하순이 끝나기 전까지 은행에 납부하라. 기한을 넘긴 자는 교수대에 오른다."

#### `city.street.pickpocket`

- `city.street.pickpocket.intro.1` 붐비는 골목에서 누군가 어깨를 세게 스치고 지나간다.

- `city.street.pickpocket.result_ok.1` 허리춤으로 뻗어 온 손목을 붙잡았다. 소년이 몸을 비틀어 빠져나가 인파 속으로 사라진다.

- `city.street.pickpocket.result_fail.1` 몇 걸음 뒤에야 허리춤이 가볍다는 것을 알았다. {n} 스톤어치 동전이 사라졌다.

#### `city.street.checkpoint`

- `city.street.checkpoint.intro.1` 경비대가 거리를 가로막고 지나가는 사람들의 얼굴을 하나하나 살핀다.

- `city.street.checkpoint.result.1` 수배자를 찾는다며 {name} 앞 골목을 통째로 막아 버렸다.

#### `city.street.wanted`

- `city.street.wanted.intro.1` 게시판에 새 현상수배 전단이 붙었다. 미궁 안에서 동료를 베고 혼자 돌아온 탐험가라고 한다.
- `city.street.wanted.intro.2` 전단 아래 적힌 현상금 액수를 두고 사람들이 수군거린다.

#### `city.street.stone_glut`

- `city.street.stone_glut.intro.1` 큰 원정대가 한꺼번에 돌아왔다. 짐수레마다 마석 자루가 실려 있다.
- `city.street.stone_glut.intro.2` 상점 주인들은 마석 값을 깎을 핑계가 생겼다며 웃는다.

#### `city.street.stone_demand`

- `city.street.stone_demand.intro.1` 마도 공방 사람들이 거리마다 다니며 마석을 사들인다.
- `city.street.stone_demand.intro.2` 상점 앞에 마석 값을 올려 받는다는 쪽지가 붙었다.

#### `city.street.potion_shortage`

- `city.street.potion_shortage.intro.1` 신전에서 내려오는 포션 물량이 끊겼다는 소문이 돈다.
- `city.street.potion_shortage.intro.2` 상점 진열대의 포션 앞에 새 가격표가 붙어 있다.

#### `city.street.dubious_peddler`

- `city.street.dubious_peddler.intro.1` 골목 그늘에서 사내가 손짓한다. 품속에서 붉은 물약 병을 꺼내 보인다.
- `city.street.dubious_peddler.intro.2` "신전 것과 똑같은 물건이오. 값은 반의반이고."

- `city.street.dubious_peddler.choice.buy` 산다
- `city.street.dubious_peddler.choice.pass` 지나친다

- `city.street.dubious_peddler.buy_ok.1` 병을 따 냄새를 맡아 보니 진짜 포션이다. 사내는 이미 자리를 떴다.

- `city.street.dubious_peddler.buy_fail.1` 병 속에는 붉게 물들인 물뿐이었다. 사내가 있던 자리는 비어 있다.

- `city.street.dubious_peddler.pass.1` 사내는 혀를 차고 다음 사람을 부른다.

#### `city.street.beggar`

- `city.street.beggar.intro.1` 한쪽 팔이 없는 사내가 담벼락에 기대 앉아 있다. 옆에 찌그러진 투구가 엎어져 있다.

- `city.street.beggar.choice.give` 동전을 넣는다
- `city.street.beggar.choice.pass` 지나친다

- `city.street.beggar.give.1` 투구에 동전이 떨어지는 소리에 사내가 고개를 든다. "미궁에서 살아 돌아오길."

- `city.street.beggar.pass.1` 사내는 고개를 숙인 채 움직이지 않는다.

#### `city.street.drunk`

- `city.street.drunk.intro.1` 술 냄새를 풍기는 덩치가 길을 막아선다. "어이, 거기. 어깨를 쳤으면 사과를 해야지."

- `city.street.drunk.choice.fight` 맞붙는다
- `city.street.drunk.choice.avoid` 돌아간다

- `city.street.drunk.fight_ok.1` 덩치가 진흙탕에 나뒹굴자 구경꾼들이 환호하며 동전을 던진다. {n} 스톤이 모였다.

- `city.street.drunk.fight_fail.1` 주먹다짐 끝에 둘 다 진흙탕에 나뒹굴었다. 온몸이 쑤신다.

- `city.street.drunk.avoid.1` 뒤에서 비웃음이 들리지만 돌아보지 않았다.

#### `city.street.errand`

- `city.street.errand.intro.1` 짐수레를 끌던 노인이 바퀴가 빠졌다며 도움을 청한다.

- `city.street.errand.choice.accept` 돕는다
- `city.street.errand.choice.decline` 거절한다

- `city.street.errand.accept.1` 짐을 다 옮기고 나니 해가 기울었다. 노인이 {n} 스톤을 손에 쥐여 준다.

- `city.street.errand.decline.1` 노인은 다른 사람을 부르러 간다.

#### `city.street.fire`

- `city.street.fire.intro.1` 밤사이 불이 났다. 매캐한 연기가 아직 골목에 남아 있다.

- `city.street.fire.result.1` {name} 쪽이 그을음투성이다. 오늘은 문을 열지 못할 것 같다.

#### `city.street.plague`

- `city.street.plague.intro.1` 기침하는 사람이 부쩍 늘었다. 역병이 돈다는 소문에 신전 앞에 줄이 길다.
- `city.street.plague.intro.2` 여관들도 식사와 잠자리 값을 슬그머니 올렸다.

### `city.meal`

> 여관 요리 한 장면(요리 id = data/meals.json, 효과는 상태 meal_<id>)

- `city.meal.squid_ink_fry` 새까만 튀김옷 속에서 오징어 다리가 꿈틀대듯 말려 있다. 짭조름한 먹물 맛에 발끝까지 가벼워진다.
- `city.meal.boar_rib_grill` 숯불 연기가 밴 멧돼지 갈비를 뼈째 뜯었다. 팔뚝에 힘이 들어간다.
- `city.meal.honey_quail` 꿀을 발라 구운 메추리 두 마리가 나왔다. 손가락까지 핥고 나니 몸이 날렵해진 기분이다.
- `city.meal.goat_cheese_soup` 산양젖 치즈가 실처럼 늘어나는 수프. 뱃속부터 단단히 데워진다.
- `city.meal.black_mushroom_risotto` 검은 버섯 향이 코끝을 찌르는 리소토. 머리가 맑게 개었다.
- `city.meal.mugwort_dumpling` 쌉쌀한 쑥 경단을 콩고물에 굴려 먹었다. 마음이 차분히 가라앉는다.
- `city.meal.smoked_eel_rice` 윤기 흐르는 훈제 장어를 밥 위에 얹어 먹었다. 몸 깊은 곳에서 기운이 차오른다.
- `city.meal.ginger_rye` 생강꿀차 한 잔에 호밀빵을 적셔 먹었다. 눈이 또렷해진다.
- `city.meal.grilled_sweetfish` 소금을 뿌려 숯불에 구운 은어. 몸놀림이 물고기처럼 미끄러워진 것 같다.
- `city.meal.salted_herring` 레몬 즙을 짜 넣은 소금 청어구이. 시큼한 맛에 정신이 번쩍 든다.
- `city.meal.blood_sausage` 김이 오르는 선지 소시지를 썰어 먹었다. 피가 피를 부르는 맛이다.
- `city.meal.bitter_herb_gukbap` 쓴나물을 듬뿍 넣은 국밥. 혀가 얼얼하지만 속이 깨끗해진다.
- `city.meal.garlic_lamb_skewer` 통마늘을 끼워 구운 양꼬치. 입에서 나는 마늘 냄새에 어둠도 물러설 것 같다.
- `city.meal.chili_oil_noodle` 붉은 고추기름이 둥둥 뜬 국수. 이마에 땀이 맺히고 손발까지 후끈하다.
- `city.meal.mint_sherbet` 박하 향이 도는 얼음과자를 사각사각 깨물었다. 몸속이 서늘하게 식는다.
- `city.meal.roast_carrot_stew` 달큰하게 구운 당근을 듬뿍 넣은 스튜. 어둑한 홀 구석까지 잘 보인다.
- `city.meal.barley_porridge` 보리와 귀리를 푹 끓인 죽. 한 그릇이면 한참은 배가 꺼지지 않을 것 같다.
- `city.meal.bean_porridge` 따끈한 콩죽을 천천히 떠먹었다. 빈속이 겨우 달래진다.
- `city.meal.drake_tail_steak` 주인장이 아껴 둔 드레이크 꼬리를 두툼하게 잘라 구웠다. 씹을 때마다 피가 끓는다.
- `city.meal.butter_salmon` 버터에 졸인 감자를 곁들인 연어 통구이. 온몸이 가뿐하다.
- `city.meal.moonberry_tart` 달빛 아래서만 익는다는 산딸기를 얹은 타르트. 머릿속이 은은하게 빛난다.
- `city.meal.whole_pig_roast` 홀 한가운데서 통째로 돌려 구운 돼지를 나눠 받았다. 몸이 한층 두꺼워진 것 같다.
- `city.meal.royal_herb_hotpot` 이름 모를 약초가 가득한 전골. 냄비 바닥까지 긁어 먹고 나니 몸이 독기를 밀어낸다.
- `city.meal.cave_truffle_soup` 미궁 동굴에서 캐 왔다는 송로를 갈아 넣은 수프. 눈이 밝아지고 속이 든든하다.

### `city.interior`

- `city.interior.locked` 잠겨 있다.

<a id="field"></a>
## 동굴 요소 `field`

> 1층 동굴 요소를 살필 때(번호가 여럿이면 하나를 고른다)

> 1층 동굴 요소(data/events) 문구 — 번호(.1 .2 …)가 여럿이면 하나를 고른다. corpse는 구역별(center/east/west/south/north).

- `field.done` 이미 손을 댄 자리다.
- `field.done_today` 오늘은 이만하면 됐다.
- `field.missing` {status} 상태가 아니다.
- `field.no_cost` {item}이(가) 없다.
- `field.no_room` 가방이 가득 차 {item}을(를) 두고 간다.
- `field.learned` {monster}의 습성을 짐작할 수 있게 됐다.
- `field.found_hidden` 발밑에 무언가 있다.
- `field.rest_campfire` 꺼진 모닥불 곁에 자리를 잡는다. 남은 온기가 굳은 몸을 풀어 준다.
- `field.corpse_done` 이미 뒤진 시체다. 더는 아무것도 없다.
- `field.campfire_done` 식은 재만 남았다.
- `field.gear_done` 쓸 만한 것은 이미 다 골라냈다.
- `field.cache_found` 돌무더기가 어딘가 일부러 쌓은 듯 반듯하다.
- `field.cache` 돌을 들어내자 기름 먹인 천 꾸러미가 나온다. 누군가 돌아올 생각이었나 보다.
- `field.cache_done` 빈 구덩이만 남았다.
- `field.offering_offer` 기념비 앞에 마석 하나를 내려놓는다. 앞서 간 이들의 공물 곁에.
- `field.offering_no_stone` 바칠 마석이 없다.
- `field.offering_offered` 이미 공물을 바쳤다.
- `field.offering_take` 공물 더미에서 마석을 집어 든다. 등 뒤가 서늘하다.
- `field.offering_taken` 남은 공물에는 손이 가지 않는다.
- `field.spring_full` 배가 출렁일 만큼 마셨다.
- `field.spring_wash` 상처를 물에 담그자 굳은 피가 풀려 흘러간다.
- `field.spring_no_wound` 씻어 낼 상처가 없다.
- `field.spring_fill` 병에 샘물을 가득 담는다.
- `field.spring_filled` 오늘은 이미 물을 담았다.
- `field.drip` 종유석 끝에서 떨어지는 물방울을 혀로 받는다. 차가운 수정 맛에 머리가 맑아진다.
- `field.drip_done` 물방울은 너무 느리게 떨어진다.
- `field.mushroom` 벽 틈에 핀 버섯이 희미하게 빛난다. 몇 송이를 딴다.
- `field.wolf_den` 뼈와 털이 수북하다. 칼날늑대의 잠자리다. 물어다 나른 먹이의 흔적으로 무리의 크기와 습성을 가늠한다.
- `field.wolf_den_done` 늑대 냄새가 진하게 배어 있다.
- `field.gnome_stash_done` 털린 은닉처는 텅 비었다.
- `field.ghoul_feast` 뜯어 먹힌 시체가 겹겹이 쌓여 있다. 썩은 살 사이로 손을 밀어 넣는다.
- `field.ghoul_feast_done` 더 뒤질 엄두가 나지 않는다.
- `field.rot_smell` 썩은 고기 냄새가 바람을 타고 온다. 가까운 곳에 구울이 있다.
- `field.goblin_camp` 고블린들의 모닥불이다. 꼬치에 꿴 고기와 훔쳐 온 물건이 널려 있다.
- `field.goblin_camp_done` 어지럽게 흩어진 뼈다귀만 남았다.
- `field.snare_detected` 발밑에 엉성하게 덮은 올가미가 보인다.
- `field.snare_disarmed` 올가미를 조심스레 풀어 치운다.
- `field.snare_pass` 발이 올가미를 스쳤지만 걸리지 않았다.
- `field.snare_fail` 올가미가 발목을 낚아챈다. 숨겨 둔 날붙이가 살을 파고든다.
- `field.slope_pass` 젖은 비탈을 조심스레 내려간다.
- `field.slope_fail` 물기에 발이 미끄러져 바위에 몸을 부딪는다.
- `field.portal_footprints` 포탈 쪽으로 수많은 발자국이 이어진다. 돌아 나온 발자국은 드물다.
- `field.torch_stubs` 암흑 경계에 횃불 꽁무니들이 꽂혀 있다. 아직 탈 만한 것을 하나 뽑는다.
- `field.crystal_glow` 벽마다 수정이 촘촘해 동굴이 낮처럼 밝다.
- `field.mud_tracks` 진흙 바닥에 무리가 지나간 발자국이 깊게 패어 있다. 아직 축축하다.
- `field.breeze` 바위 틈에서 서늘한 바람이 새어 나온다. 어딘가 큰 공간이 있다.
- `field.cairn` 누군가 납작한 돌을 쌓아 탑을 세웠다. 맨 위의 돌에는 아직 먼지가 앉지 않았다.
- `field.grave_stone` 진창 위에 갓 깎은 듯한 비석이 서 있다. 새겨진 이름은 없고, 손을 대면 돌이 차갑게 떨린다.
- `field.grave_stone_break` 비석을 걷어차 쓰러뜨렸다. 진창에 처박힌 돌 아래에서 차가운 기운이 빠져나가 흩어졌다.
- `field.grave_stone_break_fail` 한참을 내리쳐도 비석은 꿈쩍하지 않는다.
- `field.blood_well_pour` 손바닥을 그어 우물에 피를 흘려 넣었다. 바닥에서 검붉은 잔이 떠오른다.
- `field.blood_well_done` 우물은 더 이상 피를 받지 않는다.
- `field.blood_well_look` 우물 바닥에서 비릿한 냄새가 올라온다. 무언가가 목마른 것 같다.
- `field.dark_crystal_found` 어둠 속에서 무언가 희미하게 빛난다. 불빛 아래서는 그냥 돌이었을 것이다.
- `field.dark_crystal_touch` 손끝이 닿자 수정의 빛이 눈 속으로 스며들었다. 어둠의 결이 조금 더 또렷하다.
- `field.offering_mushroom` 수정 버섯 세 송이를 공물 더미 위에 가지런히 올려 두었다.
- `field.offering_no_mushroom` 바칠 것이 모자라다.
- `field.offering_mushroom_done` 버섯은 이미 올려 두었다.
- `field.offering_nothing` 돌과 마석 부스러기뿐이다.
- `field.offering_wait` 올려 둔 버섯이 그대로다.
- `field.offering_answer` 버섯은 사라지고, 그 자리에 서늘한 기운이 고여 있다. 들이마시자 넋이 맑아진다.
- `field.offering_answered` 공물 더미는 조용하다.
- `field.dig_grave_wake` 흙 속에서 손이 먼저 올라왔다.
- `field.sealed_tomb` 쇠창살 문에 사슬이 몇 겹으로 감겨 있다. 자물쇠 구멍만 새것처럼 반들거린다.
- `field.sealed_tomb_locked` 사슬이 단단히 잠겨 있다. 맞는 열쇠가 있어야 한다.
- `field.sealed_tomb_open` 자물쇠가 비명처럼 돌아갔다. 안쪽 관대 위에 부장품이 그대로 놓여 있다.
- `field.sealed_tomb_guard` 관대 둘레의 뼈들이 하나씩 일어섰다.
- `field.sacristy` 무너진 제단 뒤 작은 함 안에 녹슨 열쇠 하나와 타다 남은 초가 들어 있다.
- `field.journal_1` 쥔 손 안에 일지 한 장이 구겨져 있다. 「나루터에서 넷이 출발. 진창길이 빠르다고 했지만 구울이 너무 많다. 둑으로 돌아간다.」
- `field.journal_2` 품속에 젖은 일지 한 장. 「묘역의 새 비석. 손을 대면 떨린다. 대장은 내버려 두자고 했다. 이레째에 무언가 깬다는 걸 우리는 몰랐다.」
- `field.journal_3` 마지막 장이다. 「영묘 열쇠는 예배당 제단 뒤에 있다. 문을 연 건 실수였다. 남은 건 나 혼자다.」
- `field.watch_post` 무너진 계단을 딛고 망루 위에 섰다. 안개 너머로 길과 불빛이 내려다보인다.

### `field.corpse`

#### `field.corpse.center`

- `field.corpse.center.1` 엎드린 채 굳은 탐험가다. 상처가 여러 갈래라 무엇에 당했는지 알 수 없다. 주머니를 뒤진다.
- `field.corpse.center.2` 벽에 기대앉은 시체. 숨이 끊어질 때까지 누군가를 기다린 모양이다. 짐을 풀어 본다.
- `field.corpse.center.3` 가죽 갑옷이 찢긴 채 쓰러진 탐험가. 손에 쥔 것을 하나씩 떼어 낸다.

#### `field.corpse.east`

- `field.corpse.east.1` 목덜미에 반듯하게 베인 자국이 여럿이다. 짐승 이빨이라기엔 지나치게 날카롭다. 짐을 뒤진다.
- `field.corpse.east.2` 갑옷째 그어진 할퀸 자국. 무리에게 둘러싸였던 것 같다. 남은 것을 챙긴다.
- `field.corpse.east.3` 말라붙은 핏자국 위로 짐승 발자국이 어지럽다. 시체의 주머니를 뒤진다.

#### `field.corpse.west`

- `field.corpse.west.1` 머리에 둔기 자국이 있다. 작은 손이 휘두른 망치 같다. 짐을 뒤진다.
- `field.corpse.west.2` 주머니가 뒤집혀 있다. 누군가 반짝이는 것만 골라 가고 나머지를 버렸다.
- `field.corpse.west.3` 온몸에 자잘한 돌멩이 상처가 남아 있다. 시체의 짐을 풀어 본다.

#### `field.corpse.south`

- `field.corpse.south.1` 살점이 뜯겨 나간 자리가 검게 썩어 있다. 숨을 참고 짐을 뒤진다.
- `field.corpse.south.2` 반쯤 먹힌 시체다. 이빨 자국이 사람의 것과 닮았다. 남은 것을 챙긴다.
- `field.corpse.south.3` 썩은 냄새가 코를 찌른다. 고개를 돌린 채 주머니를 더듬는다.

#### `field.corpse.north`

- `field.corpse.north.1` 등에 조잡한 화살촉이 박혀 있다. 짐을 뒤진다.
- `field.corpse.north.2` 독에 부은 얼굴로 쓰러져 있다. 몸이 굳어 도망치지 못한 듯하다. 짐을 풀어 본다.
- `field.corpse.north.3` 목에 올가미 자국이 남아 있다. 시체의 주머니를 뒤진다.

### `field.stones`

- `field.stones.1` 누군가 쏟아 놓고 간 마석이 한 줌 흩어져 있다. 가방이 넘쳤던 모양이다.
- `field.stones.2` 돌 틈에 마석이 소복이 쌓여 있다. 더 값진 것을 담으려 버리고 간 것 같다.

### `field.campfire`

- `field.campfire.1` 재가 식은 지 오래다. 장작 끝에 타다 만 횃불이 걸려 있다.
- `field.campfire.2` 둥글게 쌓은 돌 안에 재만 남았다. 누군가 여기서 밤을 보냈다.

### `field.gear`

- `field.gear.1` 부러진 창대와 찢긴 가죽이 뒤엉켜 있다. 쓸 만한 것을 골라낸다.
- `field.gear.2` 녹슨 쇳조각을 하나씩 들춰 본다.

### `field.spring_drink`

- `field.spring_drink.1` 차고 맑은 물이 목을 타고 내려간다. 다리에 힘이 돈다.
- `field.spring_drink.2` 손을 모아 물을 떠 마신다. 수정 빛이 물결에 흔들린다.

### `field.stalagmites`

- `field.stalagmites.1` 석순이 숲처럼 솟아 있다. 사이로 몸을 숨길 만하다.
- `field.stalagmites.2` 천장의 종유석과 바닥의 석순이 거의 맞닿아 있다. 오랜 세월이다.

### `field.gnome_trinkets`

- `field.gnome_trinkets.1` 작은 망치와 깎다 만 돌 인형이 놓여 있다. 노움의 솜씨다.
- `field.gnome_trinkets.2` 손바닥만 한 돌 조각상들이 줄지어 서 있다. 하나같이 이쪽을 보고 있다.

### `field.old_skeleton`

- `field.old_skeleton.1` 아주 오래된 해골이 반쯤 바닥에 묻혀 있다. 곁의 장비는 처음 보는 모양이다.
- `field.old_skeleton.2` 흙빛으로 바랜 뼈 사이로 수정이 자라 들어가 있다.

### `field.dig_grave`

- `field.dig_grave.1` 흙이 아직 검다. 누군가 얼마 전에 덮은 무덤이다.
- `field.dig_grave.2` 십자가가 기울어 있다. 흙을 다진 발자국이 둘레를 돌다 끊겼다.

### `field.dig_grave_dig`

- `field.dig_grave_dig.1` 한참을 파 내려가자 썩은 천 사이로 무언가 손에 걸렸다.
- `field.dig_grave_dig.2` 관 뚜껑이 쪼개져 있다. 안에 남은 것을 더듬어 꺼냈다.
- `field.dig_grave_dig.3` 흙만 한가득이다. 누가 먼저 다녀간 모양이다.

### `field.epitaph`

- `field.epitaph.1` 「여기 잠든 이는 늪을 건너지 못했다. 다리는 북쪽에 있었다.」
- `field.epitaph.2` 「열쇠는 기도하는 자의 등 뒤에 두었다. 우리는 다시 열지 않으리라.」
- `field.epitaph.3` 「물이 빠지는 날에만 종탑이 보인다.」 아래 글줄은 깎여 나갔다.
- `field.epitaph.4` 이름이 셋 새겨져 있고, 그중 둘은 누군가 칼로 긁어 지웠다.
- `field.epitaph.5` 「검은 기사는 이레째 아침에 일어난다. 그 전에 돌을 깨뜨려라.」
- `field.epitaph.6` 「망루에 오른 자만이 길을 안다.」 돌 귀퉁이에 화살표가 새겨져 있다.
- `field.epitaph.7` 비문 대신 손톱자국이 빼곡하다.
- `field.epitaph.8` 「구덩이에 내려가지 마라. 내려간 자는 올라오는 법을 잊는다.」

<a id="dir8"></a>
## dir8 `dir8`

> —

- `dir8.0` 북쪽
- `dir8.1` 북동쪽
- `dir8.2` 동쪽
- `dir8.3` 남동쪽
- `dir8.4` 남쪽
- `dir8.5` 남서쪽
- `dir8.6` 서쪽
- `dir8.7` 북서쪽
- `dir8.here` 바로 곁

<a id="buff"></a>
## buff `buff`

> —

> 상태 효과 수치 줄(BuffText — 여관 식사)

- `buff.line` {name} ({parts})
- `buff.flee_bonus` 도주 확률 {v}
- `buff.crit_bonus` 치명타율 {v}
- `buff.hit_taken` 적 명중률 {v}
- `buff.lifesteal` 흡혈 {v}
- `buff.heal_mult` 받는 치유 {v}
- `buff.dmg_taken` 받는 {type} 피해
- `buff.dmg_taken_all` 받는 피해
- `buff.dmg_dealt` 주는 {type} 피해
- `buff.dmg_dealt_all` 주는 피해
- `buff.cat_physical` 물리
- `buff.cat_magical` 마법
- `buff.left_battle` 전투 {n}번
- `buff.left_hour` {n}시간

<a id="item"></a>
## item `item`

> —

> 아이템을 얻었다는 문구는 이것 하나(사용자 2026-11-01 "아이템 획득 문구 전부 통일" — ItemInfo.got_key)

- `item.got` {item}을(를) 얻었다.
- `item.got_n` {item} {n}개를 얻었다.
- `item.got_by` {who}이(가) {item}을(를) 얻었다.
- `item.got_by_n` {who}이(가) {item} {n}개를 얻었다.
- `item.got_list` {items}를 얻었다.
- `item.count_of` {item} {n}개
- `item.list_sep` , 
