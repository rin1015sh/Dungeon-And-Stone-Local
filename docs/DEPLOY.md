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
   - 크기(2026-11-08): wasm 38MB + **pck 198MB**, zip 204MB — 그림이 늘어 커졌다(가져온 그림이 무손실 ctex). 첫 로딩이 길다. itch.io는 압축을 푼 파일 하나가 200MB를 넘으면 받지 않는다 — pck가 넘으면 그림 가져오기를 손실 압축으로 바꾸는 등 줄여야 한다.
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
| 데이터 | `data/*.json` · `assets/*.json`(그림 색인 — 몸 높이 · 동네 바닥 · 실내 · 집 가림)을 꾸러미에 넣는다(JSON은 리소스가 아니라 기본으로는 빠진다). 그림(.webp)이 있는지는 `ResourceLoader.exists`로 본다 — 꾸러미에는 원본 그림 없이 가져온 것만 있어 `FileAccess.file_exists`는 false | `export_presets.cfg` include_filter |
| 종료 버튼 | 숨김(브라우저 탭은 게임이 닫을 수 없다) | `TitleScreen` `OS.has_feature("web")` |
| 기반 점검 | 릴리스 빌드에서 숨김(개발용) | `TitleScreen` `OS.is_debug_build()` |
| 저장 | `user://dungeon_and_stone/save.json` → 브라우저 IndexedDB. 같은 주소의 다른 Godot 게임과 겹치지 않게 게임 이름 폴더를 둔다. 파일을 닫을 때 저장소로 동기화된다 | `SaveGame` |
| 글꼴 | 웹에는 시스템 글꼴이 없다 → 화면 글자는 동봉 Noto Sans KR에 있는 것만. 없던 기호 ▸ ✕를 › ×로 바꿨고 테스트가 지킨다 | `tests/test_web.gd` |
| Esc | 전체 화면에서 Esc는 브라우저가 먼저 가져가 전체 화면만 풀린다. 미궁 정지는 P, 창 닫기·선택 창 뒤로·창구에서 나가기도 Esc라 전체 화면에서는 한 번 더 눌러야 한다(UI43 — Backspace는 전투 행동창 뒤로만) | `data/input.json` |

## 4. 저장에 대해 플레이어가 알아야 할 것

- 저장은 **그 브라우저·그 기기에만** 있다. 시크릿 창, "사이트 데이터 삭제", 다른 브라우저에서는 이어 할 수 없다.
- 사파리는 오래 방문하지 않은 사이트의 저장소를 지울 수 있다.
- 필요하면 나중에 "기록을 파일로 내보내기/불러오기"(텍스트 복사)를 붙일 수 있다(지금은 없음).

## 5. 공개 전 확인

- [ ] 디버그 패널(F1 — 날짜·값 바꾸기, 미궁으로)을 웹 공개 빌드에서 숨길지 결정(지금은 열린다).
- [ ] 파이어폭스·사파리·모바일 브라우저에서 시작·저장·이어하기.
- [ ] itch.io 페이지에 **비상업 팬 프로젝트**(원작: 『게임 속 바바리안으로 살아남기』)임을 밝히고 무료로 둔다. 원작 문장·실명 인물은 쓰지 않는다(CLAUDE.md 원작 반영 규칙).
- [ ] 동봉 글꼴 라이선스(OFL) 고지: `assets/fonts/OFL.txt`가 꾸러미에 들어간다.

## 6. 자동 배포 — main에 올리면 웹 테스트 빌드가 바뀐다(2026-11-08)

`.github/workflows/web.yml`: main에 push(또는 Actions 탭에서 "Run workflow") → 리눅스 Godot 4.7.2로 `tools/check.sh` → `tools/export_web.sh` → 배포. 15~25분 걸린다. 결과 폴더는 Actions 실행 화면 "Artifacts"의 `web`으로도 7일 동안 받을 수 있다. 화면 빌드 번호는 `version.txt`(커밋 7자리 · 시각).

**itch.io(추천 — 무료, 비공개 저장소여도 된다)** — 처음 한 번:
1. itch.io에 HTML 프로젝트를 만든다(§2와 같은 Embed 설정). **Visibility = Draft**(나만 보임) 또는 **Restricted**(비밀번호 · 초대한 사람만). 첫 업로드는 butler가 하므로 파일은 안 올려도 된다 — 처음 올라온 뒤 업로드에서 "This file will be played in the browser"를 한 번 켠다.
2. itch.io → Settings → API keys → "Generate new API key"를 복사.
3. GitHub 저장소 → Settings → Secrets and variables → Actions:
   - Secrets 탭 **`BUTLER_API_KEY`** = 2의 키
   - Variables 탭 **`ITCH_TARGET`** = `itch계정/게임주소:html5`(예: 게임 주소가 `https://abc.itch.io/dungeon-and-stone`면 `abc/dungeon-and-stone:html5`)
4. Actions 탭 → web → Run workflow로 한 번 돌린다. 이후로는 main에 올릴 때마다 바뀐다(butler는 바뀐 부분만 올린다).

**GitHub Pages(다른 길)**: 비공개 저장소는 유료 요금제(Pro 등)여야 하고, 페이지 주소는 공개다. Settings → Pages → Source = GitHub Actions, Variables에 **`DEPLOY_PAGES`** = `true`. 주소는 `https://<계정>.github.io/<저장소>/`.

- 검증이 실패하면 배포하지 않는다(그 커밋의 Actions 기록에 실패 단계가 남는다). 급할 때만 Variables **`SKIP_CHECK`** = `true`.
- 새로 배포된 뒤 브라우저가 옛 파일을 들고 있으면 새로고침(Ctrl+Shift+R). 저장은 같은 주소면 남는다.
