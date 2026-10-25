# 던전 앤 스톤 (Godot 4 팬 프로젝트)

소설 『게임 속 바바리안으로 살아남기』의 작중 게임 「던전 앤 스톤」을 구현하는 **비상업 팬 프로젝트**입니다.
2D 3/4 쿼터뷰 던전 크롤러 + 민첩 기반 턴제 전투 + 하드코어 로그라이크 RPG.

- 엔진: **Godot 4.7** (GDScript, GL Compatibility 렌더러)
- 현재 단계: 도시 라비기온 + 미궁 1층 전부(필드·다른 탐험가·계층군주·균열 4개) + 10층 밸런스 곡선(1층 적용) — 지금 상태와 다음 할 일은 [docs/PROGRESS.md](docs/PROGRESS.md), 확정된 기획 요약은 [docs/CANON.md](docs/CANON.md), 문서 지도는 [docs/README.md](docs/README.md)

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

## 그림

모든 그림(도시·몬스터 전투·아군 뒷모습·탐험 맵·아이템·여관 요리·상태 아이콘·거리 사건)은 `tools/paint_*.gd`가 피어 앤 헝거풍 손그림으로 그려 WebP로 넣은 것입니다. 다시 만드는 명령·걸리는 시간·규칙은 [`docs/ART.md`](docs/ART.md) §0. 손으로 그린 그림으로 바꾸려면 같은 경로에 덮어쓰면 됩니다.

## 한글 폰트

Noto Sans KR Regular(SIL OFL 1.1, `assets/fonts/OFL.txt`)를 번들했습니다. 다른 OFL 한글 폰트를 쓰려면 `assets/fonts/`에 넣고 `data/render.json`의 `font.path`를 바꾸세요.

---

## 테스트 플레이 체크리스트

작업마다 직접 해 보고 확인할 것은 [`docs/PLAYTEST.md`](docs/PLAYTEST.md)에 있습니다(위가 최신).

## 문서

어떤 문서를 언제 읽는지는 [`docs/README.md`](docs/README.md)(문서 지도)를 보세요.
