# 새 게임 씨앗 — 저장소 설계 · 에셋 가져오기 · 이름 (2026-11-21)

던전 앤 스톤을 멈추고 새로 만들 게임의 출발 설계. 새 저장소가 생기면 이 문서를 그쪽 `docs/DESIGN.md`로 옮긴다.

## 1. 이름

| 후보 | 영문 · 저장소 | 느낌 |
|---|---|---|
| **등불성채 랜턴홀드** (추천) | Lanternhold · `lanternhold` | 등불 하나 들고 파티가 내려가는 던전. 던전 앤 스톤의 빛 · 시야 장치를 그대로 살린다 |
| 굴꾼의 맹세 | Delvers' Oath · `delvers-oath` | 파티가 맹세로 묶인 원정대 |
| 잿빛 회랑 | Ashen Halls · `ashen-halls` | 무너진 지하 왕국, 어두운 분위기 |
| 스무 면 | Twentyfold · `twentyfold` | d20 굴림이 중심인 게임이라는 말장난 |
| 깊은 문 | Deepgate · `deepgate` | 땅속 문을 하나씩 여는 구조 |

정하기 전에 같은 이름의 게임 · 상표가 있는지 스팀 · itch.io에서 한 번 찾아본다.

## 2. 한 줄 · 핵심 재미

**D&D 5판 SRD 규칙의 2D 3/4 쿼터뷰 격자 턴제 파티 던전 크롤러.** 탐험 화면에서 그대로 전투가 벌어진다(따로 전투 화면 없음 — 발더스게이트식).

던전 앤 스톤에서 재미없던 셋을 거꾸로 세운 것이 기둥이다.
1. **적마다 개성** — 몬스터마다 고유 능력 하나 이상(고블린: 공격 뒤 숨기 · 트롤: 재생, 불 · 산으로만 멈춤 · 구울: 마비 할퀴기). 색만 바꾼 변종 금지.
2. **판단이 있는 전투** — 이동 · 엄폐 · 높낮이 · 기회 공격 · 행동/추가 행동/반응 · 이점/불리 · d20 굴림이 화면에 보인다.
3. **자주 오는 보상** — 상자 · 시체 · 숨은 방에서 금화 · 소모품 · 마법 아이템. 쓰러뜨리면 뭔가 나온다.

## 3. 1단계 범위 (2주 안 — 해 보고 재미있을 때만 넓힌다)

- 던전 하나, 방 3~4개(입구 · 함정 방 · 무리 방 · 보스 방).
- 파티 4인 3레벨: 파이터 · 클레릭 · 로그 · 위저드(SRD 클래스, 하위 직업 하나씩).
- 적 5종: 고블린 · 스켈레톤 · 구울 · 늑대 · 보스(오우거 또는 트롤 — 그림은 `half_troll`).
- 규칙: 능력치 6 · 숙련 보너스 · AC · 명중 d20 · 피해 주사위 · 내성 · 이점/불리 · 이동 30피트(6칸) · 기회 공격 · 엄폐 · 주문 슬롯 · 짧은/긴 휴식 · 쓰러짐과 죽음 내성.
- 보상: 상자 · 시체 뒤지기, 금화 · 치유 물약 · +1 무기 · 주문 두루마리.
- **안 넣는 것**: 대화 선택지 · 마을 · 레벨 4 이상 · 제작 · 저장 여러 칸.

## 4. 규칙 출처 · 라이선스

- **SRD 5.1**(2014판 규칙, CC-BY-4.0). 2024판 규칙을 원하면 SRD 5.2(역시 CC-BY-4.0)로 바꿔도 된다 — 시작 전에 하나만 정한다.
- 저장소 `LICENSE-SRD.md`와 게임 크레딧에 다음 문구를 넣는다: *This work includes material taken from the System Reference Document 5.1 ("SRD 5.1") by Wizards of the Coast LLC, available at https://dnd.wizards.com/resources/systems-reference-document. The SRD 5.1 is licensed under the Creative Commons Attribution 4.0 International License.*
- 쓰지 않는 것: 포가튼 렐름 등 공식 세계 · 발더스게이트의 이름 · 인물 · 그림, SRD 밖 몬스터(비홀더 · 마인드 플레이어 등), "D&D" 상표를 게임 이름에 넣기.

## 5. 저장소 구조 (던전 앤 스톤에서 잘 됐던 규칙을 그대로)

```
project.godot   Godot 4.7, GL Compatibility, 오토로드 최소(EventBus · DataRegistry · GameState · AudioBus)
CLAUDE.md       세션 규칙(아래 §7) · docs/PROGRESS.md(지금 상태 · 다음 할 일, 짧게)
data/           규칙 · 콘텐츠 JSON만 — classes/ monsters/ spells/ items/ dungeons/ strings/ko.json · render.json · input.json
src/core/       Rng(시드) · Dice(굴림 "2d6+3") · Abilities · Checks(명중 · 내성 · 이점/불리) — 오토로드 비의존
src/rules/      Action · Turn(행동/추가/반응/이동) · Conditions · Spells · effects/<type>.gd (id → 핸들러 1파일)
src/world/      격자 지도 · 이동 · 시야 · 빛 · 문 · 함정 · 상자
src/ai/         몬스터 행동(종마다 고유 능력 = 데이터 + 핸들러)
src/ui/         키보드 UI(ChoiceGrid · 대화창 · 굴림 표시 · 행동 바 · 파티 패널)
assets/         던전 앤 스톤에서 가져온 그림 · 소리 · 글꼴(§6)
tests/          test_*.gd · smoke_ui      tools/  check.sh · validate_data · screenshot · 그림 도구
```

## 6. 던전 앤 스톤에서 가져오기

`python3 tools/export_kit.py <새 저장소 경로>` (목록 `docs/EXPORT_KIT.md`). 1단계에 쓰는 것과 쓰는 곳:

| 가져올 것 | 새 게임에서 |
|---|---|
| `kit` · `explore`(수정동굴 · 강철의 묘 · 탄광 바닥 · 벽 · 소품) | 던전 방 타일 · 장식 · 상자 · 함정 |
| `actors`(종족 5 · 차림 53 맵 걷기 시트) | 파티 4인 맵 그림 — 격자 위에서 그대로 싸운다 |
| `monsters` 맵 시트 | 고블린 `goblin` · 스켈레톤 `skeleton` · 구울 `ghoul` · 늑대 `frost_wolf` · 트롤 `half_troll` / 다음 후보: 코볼트 · 리자드포크 · 오크 · 아울베어 · 미라 · 레이스 · 웨어울프 · 가고일 · 젤리 `slime` · 거대 전갈 · 돌 골렘 |
| `items` 아이콘 450 | 무기 · 방어구 · 물약 · 두루마리 아이콘 |
| `explore_code` | 3/4 청크 그리기 · 시야 · 빛 — 구조를 참고해 새 격자 지도에 다시 쓴다 |
| `code` | Rng · JsonUtil · Strings · 데이터 검증 · InputSetup · UiTheme · ChoiceGrid · DialogueBox · check.sh · 테스트 틀 |
| `fonts` · `audio` | 그대로(소리는 판매 전 라이선스 확인) |
| `battle` · `town` | 1단계에는 안 씀(따로 전투 화면 · 마을 없음) — 넘기기만 |

가져온 뒤 원작 흔적이 남은 파일 이름(`bf_` 등)은 새 이름으로 바꾼다.

## 7. 새 CLAUDE.md에 그대로 옮길 규칙

정적 타이핑 · 한 스크립트 한 책임 300줄 · `.tscn` 최소 · 키보드 전용(Enter/Esc/WASD) · 콘텐츠는 JSON · 매직 넘버 금지 · 모든 무작위는 Rng · 레지스트리/핸들러 · 문자열은 ko.json · `check.sh` "모든 검증 통과" · 그림은 캡처해서 본다 · 한국어 짧은 커밋. **새로 더할 규칙**: 기능을 넣기 전에 한 판 해 볼 수 있는 상태 먼저 · 콘텐츠 추가보다 재미 확인 먼저.

## 8. 단계

| 단계 | 끝나면 | 
|---|---|
| M0 뼈대 | 저장소 · check.sh · 에셋 가져오기 · 빈 격자 방에 파티 4인이 걷는다 |
| M1 전투 | 주사위 · 명중 · 피해 · 차례 · 이동 · 기회 공격 · 고블린 · 스켈레톤과 싸운다 |
| M2 파티 | 4클래스 3레벨 능력 · 주문 슬롯 · 휴식 · 구울 · 늑대 고유 능력 |
| M3 던전 한 판 | 방 4개 · 함정 · 상자 · 보스 · 보상 → **사람이 처음부터 끝까지 해 본다** |
