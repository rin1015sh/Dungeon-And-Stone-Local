# 던전 앤 스톤 (Godot 4 팬 프로젝트)

소설 『게임 속 바바리안으로 살아남기』의 작중 게임 「던전 앤 스톤」을 구현하는 **비상업 팬 프로젝트**입니다.
2D 3/4 쿼터뷰 던전 크롤러 + 민첩 기반 턴제 전투 + 하드코어 로그라이크 RPG.

- 엔진: **Godot 4.7** (GDScript, GL Compatibility 렌더러)
- 현재 단계: 도시 라비기온 + 미궁 1층 전부(필드·계층군주·균열 4개) — 지금 상태와 다음 할 일은 [docs/PROGRESS.md](docs/PROGRESS.md), 확정된 기획 요약은 [docs/CANON.md](docs/CANON.md), 문서 지도는 [docs/README.md](docs/README.md)

## 실행

1. Godot 4.7로 이 폴더(`project.godot`가 있는 곳)를 연다.
2. F5(프로젝트 실행).

명령줄:

```bash
godot --path .
```

## 검증

```bash
GODOT=/path/to/godot bash tools/check.sh
```

데이터 검증 → 단위 테스트 → UI 스모크 → 메인 씬 스모크를 차례로 돌리고 "모든 검증 통과"를 출력하면 정상입니다.

## 웹(itch.io) 배포

```bash
GODOT=/path/to/godot bash tools/export_web.sh
```

`build/dungeon_and_stone_web.zip`을 itch.io에 HTML 게임으로 올립니다(Godot 4.7.2 내보내기 템플릿 필요). 설정·주의점은 [`docs/DEPLOY.md`](docs/DEPLOY.md).

## 콘텐츠 추가

콘텐츠는 `data/` 아래 JSON만 편집해서 추가합니다(코드 수정 없이). 각 폴더의 `_template.json`이 형식 예시입니다.
추가한 뒤 `godot --headless --path . --script res://tools/validate_data.gd`로 참조 오류를 확인하세요.

## 도시 그림

도시 그림(`assets/city/` — 거리 레이어 6장, 건물 6, 시설 내부 6, WebP)은 `tools/paint_city.gd`가 **손으로 칠한 듯한 어두운 일러스트**(피어 앤 헝거 2풍 — 거친 붓결·떨리는 잉크 윤곽·그늘 빗금·탁한 색·필름 그레인)로 그린 것입니다.
- 거리 = 레이어(`data/city.json`의 `street.layers`): 하늘 · 원경(언덕 위 성과 첨탑) · 중경(뒷골목 집들) · 안개 · 거리(인도·포석·골목 소품) · 비네트. 먼 레이어일수록 천천히 움직인다(시차).
- 시설 건물은 거리 레이어 위에 따로 놓이며(`data/facilities/*.json`의 `x`·`building`), 고를 수 있는 것만 잉크 윤곽·강조가 붙는다. 내부 그림은 `interior`.
- 좌표는 화면 높이 720 기준(`render.json`의 `city.street_height`·`baseline`·`building_scale`).

손으로 그린 그림으로 바꾸려면 같은 경로에 그림을 덮어쓰면 됩니다(PNG로 바꾸면 데이터 경로도 바꾸세요). 다시 생성하려면(약 2분):

```bash
godot --headless --path . --script res://tools/paint_city.gd            # 전부
godot --headless --path . --script res://tools/paint_city.gd -- --only=street   # street | buildings | interiors
```

## 몬스터 그림

전투 화면의 몬스터 그림(`assets/monsters/<id>.webp` 52장 + `index.json` 몸 높이)은 `tools/paint_monsters.gd`가 **피어 앤 헝거 몬스터 그림풍**(밝은 살과 적갈색 그늘의 붓 칠 · 근육 사이 잉크 골 · 펜 빗금 · 털 붓결 · 피)으로 그린 것입니다. 몸을 3D 덩어리로 빚은 뒤 칠합니다(`tools/monster_art/`).
- 모습 설계는 `tools/monster_art/Specs.gd`·`Specs2.gd`에 몬스터 id마다 한 항목(자세·체형·머리·옷·무기·색).
- 그림이 없는 몬스터는 예전처럼 도형으로 보입니다. 새 몬스터를 넣으면 설계를 추가하고 그 id만 다시 그리세요.

```bash
godot --headless --path . --script res://tools/paint_monsters.gd                       # 전부(약 4분)
godot --headless --path . --script res://tools/paint_monsters.gd -- --only=goblin,slime  # 일부
```

손으로 그린 원화로 바꾸려면 같은 경로에 덮어쓰고(발이 그림 아래 끝), `index.json`에 그 그림 속 몸 높이(px)를 적으세요.

## 한글 폰트

Noto Sans KR Regular(SIL OFL 1.1, `assets/fonts/OFL.txt`)를 번들했습니다. 다른 OFL 한글 폰트를 쓰려면 `assets/fonts/`에 넣고 `data/render.json`의 `font.path`를 바꾸세요.

---

## 테스트 플레이 체크리스트

작업마다 직접 해 보고 확인할 것은 [`docs/PLAYTEST.md`](docs/PLAYTEST.md)에 있습니다(위가 최신).

## 문서

어떤 문서를 언제 읽는지는 [`docs/README.md`](docs/README.md)(문서 지도)를 보세요.
