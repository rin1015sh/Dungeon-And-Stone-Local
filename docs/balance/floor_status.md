# 층 찍어내기 점검표 (도구가 만든 것 — 손으로 고치지 않는다)

`python3 tools/floor_status.py`가 데이터·파일을 읽어 만든다. ● 갖춤 · ◐ 일부 · ○ 없음. 부품 목록과 만드는 법은 `docs/plans/floors_2_10.md` §1. 한 층의 빠진 것만 보려면 `--floor=<n>`.

| 부품 | 1층 | 2층 | 3층 | 4층 | 5층 | 6층 | 7층 | 8층 | 9층 | 10층 |
|---|---|---|---|---|---|---|---|---|---|---|
| 층 정의 data/floors | ● | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| 생성기 src/explore/generators | ● | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| 고정 지도(bake_floor) | ● | ◐ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| 데칼 시트·굽기(bake_decor) | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| 전투 뒷그림 | ● | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| 환경음 audio.ambience | ● | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| 지역 스폰 regions | ● | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| 동굴 요소 features | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| 다른 탐험가 explorers | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| 위층 포탈 portals | ● | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| 계층군주 lord(+패턴) | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| 군주 등장 문구 explore.boss_notice | ◐ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| 필드 몬스터 | ● | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| 몬스터 그림 assets/monsters | ● | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| 정수 data/essences | ● | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| 균열 data/rifts | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| 도서관 서적(floor n) | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |

## 1층 (필드 등급 9 · 파티 1)
- ● 층 정의 data/floors — f1_crystal_cave
- ● 생성기 src/explore/generators — crystal_cave
- ● 고정 지도(bake_floor) — res://data/maps/f1_crystal_cave.json
- ● 데칼 시트·굽기(bake_decor) — res://assets/floor/f1/decals.webp
- ● 전투 뒷그림 — res://assets/battle/f1_crystal_cave.webp
- ● 환경음 audio.ambience — f1_cave
- ● 지역 스폰 regions — 5지역
- ● 동굴 요소 features — 25종 203곳
- ● 다른 탐험가 explorers
- ● 위층 포탈 portals — 4개
- ● 계층군주 lord(+패턴) — dreadfear · 패턴 dreadfear
- ◐ 군주 등장 문구 explore.boss_notice — dreadfear — 전용 문구 없음(any를 씀)
- ● 필드 몬스터 — 10종 · 등급 [9] (목표 9)
- ● 몬스터 그림 assets/monsters — 51장
- ● 정수 data/essences — 51종
- ● 균열 data/rifts — 핏빛성채 5챕터 / 빙하굴 4챕터 / 녹색 탄광 4챕터 / 강철의 묘 4챕터
- ○ 도서관 서적(floor n) — 0권 · 빠진 분야 dungeon, arms, ailments, monsters, survival, society

## 2층 (필드 등급 8 · 파티 2)
- ● 층 정의 data/floors — f2_land_of_dead
- ● 생성기 src/explore/generators — fields
- ◐ 고정 지도(bake_floor) — fixed_map 없음 — 입장마다 생성
- ○ 데칼 시트·굽기(bake_decor) — art.decor 없음
- ● 전투 뒷그림 — res://assets/battle/f2_land_of_dead.webp
- ● 환경음 audio.ambience — f1_cave
- ● 지역 스폰 regions — 3지역
- ○ 동굴 요소 features — 0종 0곳
- ○ 다른 탐험가 explorers
- ● 위층 포탈 portals — 1개
- ○ 계층군주 lord(+패턴)
- ● 필드 몬스터 — 4종 · 등급 [6, 7, 9] (목표 8)
- ● 몬스터 그림 assets/monsters — 4장
- ● 정수 data/essences — 4종
- ○ 균열 data/rifts
- ○ 도서관 서적(floor n) — 0권 · 빠진 분야 dungeon, arms, ailments, monsters, survival, society

## 3층 (필드 등급 7 · 파티 5)
- ○ 층 정의 data/floors — f3_<id>.json 없음
- ○ 필드 몬스터 — 0종 · 등급 [] (목표 7)
- ○ 몬스터 그림 assets/monsters — 0장
- ○ 정수 data/essences — 0종
- ○ 균열 data/rifts
- ○ 도서관 서적(floor n) — 0권 · 빠진 분야 dungeon, arms, ailments, monsters, survival, society

## 4층 (필드 등급 7 · 파티 5)
- ○ 층 정의 data/floors — f4_<id>.json 없음
- ○ 필드 몬스터 — 0종 · 등급 [] (목표 7)
- ○ 몬스터 그림 assets/monsters — 0장
- ○ 정수 data/essences — 0종
- ○ 균열 data/rifts
- ○ 도서관 서적(floor n) — 0권 · 빠진 분야 dungeon, arms, ailments, monsters, survival, society

## 5층 (필드 등급 6 · 파티 5)
- ○ 층 정의 data/floors — f5_<id>.json 없음
- ○ 필드 몬스터 — 0종 · 등급 [] (목표 6)
- ○ 몬스터 그림 assets/monsters — 0장
- ○ 정수 data/essences — 0종
- ○ 균열 data/rifts
- ○ 도서관 서적(floor n) — 0권 · 빠진 분야 dungeon, arms, ailments, monsters, survival, society

## 6층 (필드 등급 5 · 파티 5)
- ○ 층 정의 data/floors — f6_<id>.json 없음
- ○ 필드 몬스터 — 0종 · 등급 [] (목표 5)
- ○ 몬스터 그림 assets/monsters — 0장
- ○ 정수 data/essences — 0종
- ○ 균열 data/rifts
- ○ 도서관 서적(floor n) — 0권 · 빠진 분야 dungeon, arms, ailments, monsters, survival, society

## 7층 (필드 등급 5 · 파티 5)
- ○ 층 정의 data/floors — f7_<id>.json 없음
- ○ 필드 몬스터 — 0종 · 등급 [] (목표 5)
- ○ 몬스터 그림 assets/monsters — 0장
- ○ 정수 data/essences — 0종
- ○ 균열 data/rifts
- ○ 도서관 서적(floor n) — 0권 · 빠진 분야 dungeon, arms, ailments, monsters, survival, society

## 8층 (필드 등급 4 · 파티 5)
- ○ 층 정의 data/floors — f8_<id>.json 없음
- ○ 필드 몬스터 — 0종 · 등급 [] (목표 4)
- ○ 몬스터 그림 assets/monsters — 0장
- ○ 정수 data/essences — 0종
- ○ 균열 data/rifts
- ○ 도서관 서적(floor n) — 0권 · 빠진 분야 dungeon, arms, ailments, monsters, survival, society

## 9층 (필드 등급 4 · 파티 5)
- ○ 층 정의 data/floors — f9_<id>.json 없음
- ○ 필드 몬스터 — 0종 · 등급 [] (목표 4)
- ○ 몬스터 그림 assets/monsters — 0장
- ○ 정수 data/essences — 0종
- ○ 균열 data/rifts
- ○ 도서관 서적(floor n) — 0권 · 빠진 분야 dungeon, arms, ailments, monsters, survival, society

## 10층 (필드 등급 3 · 파티 5)
- ○ 층 정의 data/floors — f10_<id>.json 없음
- ○ 필드 몬스터 — 0종 · 등급 [] (목표 3)
- ○ 몬스터 그림 assets/monsters — 0장
- ○ 정수 data/essences — 0종
- ○ 균열 data/rifts
- ○ 도서관 서적(floor n) — 0권 · 빠진 분야 dungeon, arms, ailments, monsters, survival, society
