# 문서 지도 — 무엇을 언제 읽는가 (2026-10-25)

> 새 세션은 **`CLAUDE.md`(자동으로 읽힘) → `docs/PROGRESS.md`** 두 개만 읽으면 이어갈 수 있다. 나머지는 필요할 때 찾아 읽는다.
> 문서끼리 어긋나면 **날짜가 늦은 사용자 결정이 이긴다**(순서는 `CANON.md` §0).

## 매번 / 자주

| 문서 | 무엇 | 언제 |
|---|---|---|
| `CLAUDE.md` | 작업 규칙 · 실행·검증 · 함정 · 폴더 구조 · 핵심 개념 | 매 세션(자동) |
| `docs/PROGRESS.md` | 지금 상태 · **다음 할 일** · 최근 작업 한 줄씩 · 유효한 이슈 | 매 세션 시작·끝 |
| `docs/CANON.md` | 지금 확정된 기획·설정 한 장 요약 · 문서 우선순위 · 미결정 표 · 명세와 일부러 다르게 한 것 | 기획을 건드리거나 "지금 게임이 어떻게 돼 있나"가 궁금할 때 |
| `docs/REFERENCE.md` | 데이터 키 사전(패시브·AI·보스·균열·상태이상·재기획 키, 동굴 요소, 도시 규칙) · 파일 하나하나의 역할 | 데이터·코드를 고칠 때 |
| `docs/ASSUMPTIONS.md` | 모든 가정·사용자 결정(번호 · 가정 / 이유 / 바꾸는 법). 행 앞의 "(바뀜 → X)"는 X가 대신한다 | 번호(J17·RF16·UI19 …)나 키워드로 **검색**해서 |
| `docs/STRINGS.md` | 게임 글 전부(`ko.json`) — 사용자가 고치고 `tools/strings_md.gd --apply`로 게임에 넣는다 | 문구를 고칠 때 · ko.json을 바꾼 뒤 다시 만든다 |
| `docs/PLAYTEST.md` | 작업마다 사용자가 직접 해 볼 체크리스트(위가 최신) | 작업이 끝나 체크리스트를 추가할 때, 플레이 점검할 때 |

## 주제별

| 문서 | 무엇 | 상태 |
|---|---|---|
| `docs/ART.md` | 그림체 규칙 · **그림 도구 명령(§0)** · 새 그림 넣는 절차 · 겪은 함정 · 탐험 맵(§6) | 정본 — 그림 작업이면 먼저 |
| `docs/DEPLOY.md` | 웹(itch.io) 내보내기·올리기·웹에서 다른 점 | 정본 |
| `docs/HANDOFF.md` | 다른 세션에 붙여 넣는 인계 프롬프트 · 새 기획 절차 · 큰 기획 후보 · 새 기획 요청서 | 새 세션·새 기획을 맡길 때 |
| `docs/balance/*.md` | 밸런스 표(도구가 만든 것: `exp_budget`·`rift`·`formula`·`curve`(10층 곡선 — `tools/balance_curve.py`)·`essences`(`tools/essences_md.py`)·`item_pool`, 정리표: `stats`(비율 공식)·`city`, 사용자 정수 표 변환 `essence_table`(+ `essence_table_converted.csv`, 원본 `source/`)) | 데이터가 정본 — 데이터를 고치면 표가 낡는다(도구로 다시 만든다) |
| `docs/plans/*.md` | 기획서(`map_design` 탐험 맵, `rift_spaces` 균열 공간, `status_redesign`·`essence_redesign` 재기획 — 모두 적용됨, `city_redesign` 도시 재기획 — 기획안·적용 안 함, `floor1_fill` 1층·균열 채우기 — A·B·C·D·F 적용, `dungeon_loop_review` 미궁 반복 루프 진단 — A1·A2·A3·B1 적용, `balance_10floors` 10층 밸런스(층별 기준 탐험가·몬스터·보스·정수·장비·비율 공식·CTB) — 1층에 적용됨(2026-10-25, 맨 위 "적용 결과"), 표는 `balance/curve.md`) | 기록 — 맨 위에 적용 여부 |

## 사용자가 준 원본 명세·지시서 (바꾸지 않는다)

| 문서 | 무엇 |
|---|---|
| `docs/PROMPT.md` | 맨 처음 마스터 지시서. 세계관 요약 §4.3은 지금도 유효, 나머지는 많이 바뀌었다(CANON §11) |
| `docs/PROMPT_FLOOR1_V2.md` | 1층 명세 v2 — 1층 몬스터·정수·균열·레벨의 원천 |
| `docs/PROMPT_ART_MAP.md` | 탐험 맵 그래픽 개편 지시서(A0~A6) |
| `docs/PROMPT_ACTOR_SPRITES.md` | 탐험 맵 몸 그림을 다른 AI로 다시 만들 때 붙이는 프롬프트 |
| `docs/COMFYUI_PROMPTS.md` | 게임 그림 84장을 ComfyUI로 다시 그릴 때의 프롬프트 모음 |

## 보관

| 문서 | 무엇 |
|---|---|
| `docs/archive/PROGRESS_LOG.md` | 작업 기록 전체(2026-10-10~). 새 작업의 자세한 기록도 맨 위에 쓴다. 날짜·제목으로 검색 |
| `docs/archive/PLAYTEST_OLD.md` | 2026-10-22까지의 테스트 체크리스트 |
| `docs/archive/DESIGN.md` · `balance_floor1.md` · `balance_rift_essences.md` | 옛 설계 요약 · 1층 G2 조정표 · 정수 상향 비교(옛 공식) — 기록일 뿐 |
| `docs/screens/` | 그림 전후 캡처(before/after) |

## 문서를 고칠 때

- 정해진 것이 바뀌면 **CANON.md와 ASSUMPTIONS를 함께** 고친다(옛 행에 "(바뀜 → X)").
- 새 데이터 키·규칙 → REFERENCE.md, 새 그림 도구·절차 → ART.md, 새 함정 → CLAUDE.md "함정".
- PROGRESS.md는 짧게(§5 규칙) — 길어지면 오래된 줄을 지운다(기록은 PROGRESS_LOG에 있다).
