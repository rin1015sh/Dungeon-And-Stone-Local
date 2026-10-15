#!/usr/bin/env bash
# 웹(itch.io 등) 내보내기: build/web/ (index.html …) + build/dungeon_and_stone_web.zip(itch.io에 그대로 올리는 압축 파일).
#   GODOT=<godot 경로> bash tools/export_web.sh
# 필요: Godot 4.7.2 내보내기 템플릿(편집기 → 내보내기 템플릿 관리자, 또는 export_templates.tpz의 web_* 파일을
#       ~/.local/share/godot/export_templates/4.7.2.stable/ — 윈도우는 %APPDATA%\Godot\export_templates\4.7.2.stable\ 에 풀기).
# 설정은 export_presets.cfg "Web"(스레드 끔 → itch.io의 SharedArrayBuffer 설정 불필요, data/*.json 포함). 자세한 것은 docs/DEPLOY.md.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
rm -rf build/web
mkdir -p build/web
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . --export-release "Web" build/web/index.html 2>&1 | grep -E "ERROR|error|DONE" | grep -v "Godot MCP" || true
if [ ! -f build/web/index.pck ]; then
	echo "내보내기 실패: build/web/index.pck 없음(내보내기 템플릿이 설치됐는지 확인)"
	exit 1
fi
rm -f build/dungeon_and_stone_web.zip
(cd build/web && zip -q -r ../dungeon_and_stone_web.zip .)
du -h build/web/index.wasm build/web/index.pck build/dungeon_and_stone_web.zip
echo "웹 내보내기 완료: build/web/ · build/dungeon_and_stone_web.zip"
