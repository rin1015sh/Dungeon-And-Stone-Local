# "글 대신 화면으로" 점검(2026-11-08)

> 사용자 2026-11-08: "로그나 텍스트는 가급적 쓰지 않고 화면으로 보여준다 — 여기에 맞지 않는 것을 찾아봐. 특히 애니메이션이 필요한 것들". 원칙 = CLAUDE.md UI19(간접 체험) · UI20(소리를 글로 쓰지 않음) · UI44(대화창 한 문장).
> 방법: 코드와 데이터에서 내보내는 문구 키를 모두 모아(`render.json ui.notice.silent`에 없는 것 = 대화창에 떠서 Enter로 넘겨야 한다), 화면에 이미 보이는지 · 그림이나 움직임이 없어 글이 대신하고 있는지 나눴다. 진행(2026-11-08): §1 · §2 · §3 · §5의 2~5 = UI58. §0(몬스터 전투 움직임 — §5의 1)은 사용자가 보류.

## 0. 가장 큰 구멍: 전투에서 몬스터가 움직이지 않는다

- 탐험가 그림에는 동작 시트가 있다(휘두르기 · 피격 · 자세 · 쓰러짐 — PartySprite). **몬스터 그림은 한 장으로 서 있기만 한다**(`BattlerView`는 대상 흰빛 · 떠오르는 숫자 · 죽을 때 먼지만). 공격 · 피격 · 큰 몸짓 · 기절이 그림으로 보이지 않아 대화창 문구가 그 몫을 한다.
- 필요한 움직임(몬스터 공통 — 그림 한 장을 움직여도 된다 · 시트를 새로 그릴 필요 없음):
  | 움직임 | 지금 대신하는 글 |
  |---|---|
  | 공격: 앞으로 짧게 튀어나왔다 돌아옴 | 스킬 이름 알림창만 |
  | 피격: 하얗게 번쩍 + 좌우 흔들림 | 떠오르는 숫자만 |
  | 큰 몸짓 예고: 뒤로 젖혀 웅크림 · 붉은 기운 · 숨쉬듯 커졌다 줄었다 | `combat.*_warn` 18종(창끝을 낮추고 · 꼬리를 높이 든다 · 앞발로 땅을 긁는다 …) |
  | 큰 몸짓 터짐: 크게 돌진 | `combat.*_fire` 18종 |
  | 큰 몸짓 끊김: 기운이 깨져 흩어짐 · 비틀 | `combat.windup_broken` · `delayed_dropped` |
  | 기절 · 마비로 차례를 거름: 머리 위 별 · 휘청 | `combat.skip` |
  | 밀려남: 뒤로 미끄러짐 | `combat.pushed_back` |
  | 달아남 성공 · 실패: 화면 밖으로 뛰어감 / 넘어졌다 일어남 | `combat.flee_ok` · `flee_fail` |
  | 자폭: 폭발 번쩍 · 파편 | `combat.death_blast` |
  | 대신 맞기: 지키는 쪽이 앞으로 미끄러져 막음 | `combat.cover` · `covered_hit` |
  | 반격 · 칼날털 되돌림: 맞은 쪽이 바로 받아침 | `combat.counter` · `reflect`(숫자는 이미 뜬다) |
  | 물건 빼앗기: 물건 그림이 몬스터 쪽으로 날아감 | `combat.item_stolen` |
  | 오인 공격: 다른 대상으로 꺾임 | `combat.misdirect` |

## 1. 화면에 이미 보이는데 대화창에 뜨는 것 → silent로

| 키 | 화면에 보이는 것 |
|---|---|
| `combat.guard` | 탐험가 방어 자세 · 방어 상태 아이콘 |
| `combat.down_party` | 탐험가가 쓰러지는 동작 |
| `combat.barrier_absorb` · `rider_hit` · `endure` | 떠오르는 숫자 · "막음" |
| `combat.aura_tick` · `marked` · `meter_full` · `sealed` | 상태 아이콘 |
| `combat.extra_action` · `extra_hit` | 왼쪽 위 행동 순서 |
| `effect.status_resisted` · `status_immune` · `combat.no_effect` · `telegraph_guarded` | → 떠오르는 짧은 글("저항" · "면역" · "막음")로 바꾸면 된다(회피 · 면역과 같은 방식) |

## 2. 지도 위 — 글이 장면을 대신하는 것

| 지금 글 | 필요한 그림 · 움직임 |
|---|---|
| `field.ambush*` 11종(덤불이 흔들리더니 고블린이 · 진창 속에서 손이 · 벽이 터지듯 …) | 땅 · 벽 · 덤불에서 솟아오르는 움직임(흙먼지 · 흔들림) + 무리 머리 위 "!" |
| 경보 6종 `watch_alarm` · `lookout_alarm` · `rampart_alarm` · `rider_alarm` · `crow_alarm` · `drum_alarm` | 경보를 낸 몬스터의 몸짓(손가락질 · 깃발 · 북 · 까마귀 맴돌기) + 몰려오는 무리마다 "!" 표시 |
| `field.boar_wall`(멧돼지가 바위에 머리를 처박고 비틀거린다) | 벽 앞에서 튕겨 나며 머리 위 별 |
| 덫 결과 `forest_snare_fail` · `forest_pit_fail` · `forest_spike_fail` · `snare_fail` · `explore.trap_*_fail` · `hazard_*_fail` | 덫이 튀는 움직임(올가미가 당겨짐 · 말뚝이 솟음 · 구덩이로 꺼짐) — 지금은 화면이 그대로이고 글로만 |
| `explore.ground_gives` · `maw_caught` · `maw_swallowed` | 발밑이 꺼지는 · 입이 다무는 움직임 |
| `field.sandworm` · `deathworm_rise` · `deathworm_sink` | 모래가 솟구치는 움직임(진동 SandTremor는 있다 — 솟는 순간은 없다) |
| `field.grave_wakes` · `sealed_tomb_guard` · `sarcophagus_wake` · `dig_grave_wake` · `bell_risers` | 무덤 흙이 갈라지며 일어남 |
| `field.sand_tremor` | 이미 진동 그림이 있다 → 글은 빼도 된다 |

## 3. 소리를 글로 쓴 것(UI20 위반) → 소리 키로, 글은 장면만

| 키 | 문제 |
|---|---|
| `field.gate_open` | "쇠사슬 풀리는 소리가 길게 이어진다" — 소리 자체가 글 |
| `field.bell_ring.1 · .2` · `bell_risers` · `bell_day` | "울림이 늪 너머까지 번진다" · "아무 울림이 없다" |
| `field.ambush_goblin.2` · `ambush_wolf.1` · `wolf_kill_back` | "낄낄거리는 소리" · "그르렁거림" |
| `field.sealed_tomb_open` | "자물쇠가 비명처럼 돌아갔다" |
| `combat.bomber_intro` · `talk_no_reply_beast` · `talk_no_reply_humanoid` | "낄낄댄다" · "으르렁거린다" · "끽끽대며" |

## 4. 글로 남겨도 되는 것(화면으로 알 수 없는 정보)

- 얻은 물건(`item.got`), 못 하는 이유(가방 자리 · 열쇠 없음 · 아직 닫힌 포탈), 층 폐쇄 경고 · 남은 시간, 조사 결과(`combat.info_*`), 영혼 베기 결과(레벨 · 정수를 잃음), 보스 등장 대사, 비문 · 벽화 · 비석 문구(읽는 것이 내용).
- 동굴 요소를 살폈을 때의 장면 한 줄(시체 · 궤짝 · 샘 …)은 "살핀 결과"라 둔다.

## 5. 고치는 순서(제안)

1. **몬스터 전투 움직임**(§0 — 튀어나옴 · 피격 번쩍 · 큰 몸짓 자세 · 끊김 · 기절 별 · 밀려남 · 달아남) + `combat.*_warn/_fire` · `skip` · `pushed_back` · `windup_broken` 등을 silent로. 가장 자주 보는 화면이라 효과가 가장 크다.
2. §1 silent 정리 + 짧은 떠오르는 글("저항" · "면역" · "막음").
3. §3 소리 문구 고치기(장면만 남기고 소리는 소리 키로).
4. 지도 "!" 표시 + 매복 솟아오름 + 경보 몸짓(§2 위 두 줄) → 해당 문구 silent.
5. 덫 · 꺼지는 땅 · 모래 솟구침 · 무덤 깨어남 움직임(§2 나머지).
