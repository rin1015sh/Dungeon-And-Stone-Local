# 웹 배포 (itch.io 등)

> 2026-10-15 준비. 크로미움에서 실제 웹 빌드로 타이틀 → 새 탐험가 → 도시 → 차원광장 → 기록 → **새로고침 후 이어하기** → 포탈 → 미궁 1층까지 확인했다.
> 파이어폭스·사파리·모바일, 실제 itch.io 페이지는 아직 확인하지 않았다.

## 1. 빌드

1. Godot 4.7.2 **내보내기 템플릿**을 설치한다(처음 한 번).
   - 편집기: 편집기 → 내보내기 템플릿 관리 → 다운로드 및 설치.
   - 수동 설치: `Godot_v4.7.2-stable_export_templates.tpz`(zip)에서 `templates/web_*.zip`과 `version.txt`를 꺼내
     윈도우는 `%APPDATA%\Godot\export_templates\4.7.2.stable\`, 리눅스는 `~/.local/share/godot/export_templates/4.7.2.stable/`에 둔다.
2. 내보내기: `GODOT=<godot 경로> bash tools/export_web.sh`
   - 결과: `build/web/`(index.html · index.js · index.wasm · index.pck …)와 `build/dungeon_and_stone_web.zip`(그대로 올리는 파일).
   - 크기: wasm 38MB + pck 12MB, zip 21MB. 첫 로딩에 몇 초가 걸린다.
   - 편집기에서 하려면: 프로젝트 → 내보내기 → "Web" → 프로젝트 내보내기(`build/web/index.html`).
3. 내 컴퓨터에서 먼저 보기: `cd build/web && python3 -m http.server 8000` → 브라우저로 `http://localhost:8000`.
   (`index.html`을 더블클릭해 `file://`로 열면 동작하지 않는다.)

## 2. itch.io에 올리기

1. 새 프로젝트 → **Kind of project: HTML**.
2. Uploads에 `build/dungeon_and_stone_web.zip`을 올리고 **"This file will be played in the browser"**를 체크한다.
3. Embed options:
   - Viewport dimensions **1280 × 720**(게임 기준 해상도. 화면 비율이 달라도 늘어나 맞는다).
   - **Fullscreen button** 켬. **Mobile friendly**는 아직 끈다(터치 미검증).
   - **SharedArrayBuffer support**는 끈다(필요 없다 — 스레드 없는 템플릿을 쓴다. 켜면 오히려 다른 기능이 막힐 수 있다).
   - "Automatically start on page load"는 꺼 두기를 권한다(클릭해야 시작 → 브라우저 소리 자동 재생 제한도 함께 풀린다).
4. 업로드를 갱신해도 플레이어의 저장은 남는다(브라우저 저장소는 itch.io 게임 주소 단위).
5. 다른 곳(GitHub Pages·Netlify 등)도 `build/web/` 폴더를 그대로 올리면 된다. 특수 헤더(COOP/COEP)는 필요 없다.

## 3. 웹에서 다른 점(코드에 반영됨)

| 항목 | 내용 | 위치 |
|---|---|---|
| 스레드 | 끔(`variant/thread_support=false`) — itch.io·일반 정적 호스팅에서 바로 돈다 | `export_presets.cfg` |
| 데이터 | `data/*.json`을 꾸러미에 넣는다(JSON은 리소스가 아니라 기본으로는 빠진다) | `export_presets.cfg` include_filter |
| 종료 버튼 | 숨김(브라우저 탭은 게임이 닫을 수 없다) | `TitleScreen` `OS.has_feature("web")` |
| 기반 점검 | 릴리스 빌드에서 숨김(개발용) | `TitleScreen` `OS.is_debug_build()` |
| 저장 | `user://dungeon_and_stone/save.json` → 브라우저 IndexedDB. 같은 주소의 다른 Godot 게임과 겹치지 않게 게임 이름 폴더를 둔다. 파일을 닫을 때 저장소로 동기화된다 | `SaveGame` |
| 글꼴 | 웹에는 시스템 글꼴이 없다 → 화면 글자는 동봉 Noto Sans KR에 있는 것만. 없던 기호 ▸ ✕를 › ×로 바꿨고 테스트가 지킨다 | `tests/test_web.gd` |
| Esc | 전체 화면에서 Esc는 브라우저가 먼저 가져가 전체 화면만 풀린다. 미궁 정지는 P, 창구에서 나가기는 빈 곳 오른쪽 클릭도 된다 | `data/input.json` |

## 4. 저장에 대해 플레이어가 알아야 할 것

- 저장은 **그 브라우저·그 기기에만** 있다. 시크릿 창, "사이트 데이터 삭제", 다른 브라우저에서는 이어 할 수 없다.
- 사파리는 오래 방문하지 않은 사이트의 저장소를 지울 수 있다.
- 필요하면 나중에 "기록을 파일로 내보내기/불러오기"(텍스트 복사)를 붙일 수 있다(지금은 없음).

## 5. 공개 전 확인

- [ ] 디버그 패널(F1 — 날짜·값 바꾸기, 미궁으로)을 웹 공개 빌드에서 숨길지 결정(지금은 열린다).
- [ ] 파이어폭스·사파리·모바일 브라우저에서 시작·저장·이어하기.
- [ ] itch.io 페이지에 **비상업 팬 프로젝트**(원작: 『게임 속 바바리안으로 살아남기』)임을 밝히고 무료로 둔다. 원작 문장·실명 인물은 쓰지 않는다(CLAUDE.md 원작 반영 규칙).
- [ ] 동봉 글꼴 라이선스(OFL) 고지: `assets/fonts/OFL.txt`가 꾸러미에 들어간다.
