#!/usr/bin/env bash
# 전체 검증: 클래스 캐시 갱신 → 데이터 검증 → 단위 테스트 → 메인 씬 스모크 실행.
#   GODOT=/path/to/godot tools/check.sh
# GODOT를 안 주면 PATH의 godot / godot4를 찾는다.
# 하나라도 실패하면 종료 코드 1. 출력에 "SCRIPT ERROR"/"Parse Error"가 있어도 실패로 본다.
set -u
cd "$(dirname "$0")/.."

GODOT="${GODOT:-}"
if [ -z "$GODOT" ]; then
  for c in godot godot4; do
    if command -v "$c" >/dev/null 2>&1; then GODOT="$c"; break; fi
  done
fi
if [ -z "$GODOT" ]; then
  echo "Godot 실행 파일을 찾지 못했다. GODOT=/경로/godot tools/check.sh 로 실행하라."
  exit 2
fi

status=0
LOG="$(mktemp 2>/dev/null || echo /tmp/das_check.log)"

run_step() {
  local name="$1"; shift
  echo "== $name"
  "$@" >"$LOG" 2>&1
  local code=$?
  cat "$LOG"
  if [ $code -ne 0 ]; then
    echo "!! $name 실패 (종료 코드 $code)"; status=1
  elif grep -qE "SCRIPT ERROR|Parse Error|Failed to load script|ERROR: " "$LOG"; then
    echo "!! $name 출력에 오류가 있다"; status=1
  else
    echo "-- $name 통과"
  fi
}

"$GODOT" --version
echo "== 클래스 캐시/임포트 갱신"
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true

run_step "데이터 검증" "$GODOT" --headless --path . --script res://tools/validate_data.gd
run_step "단위 테스트" "$GODOT" --headless --path . --script res://tests/run_tests.gd
run_step "UI 스모크" "$GODOT" --headless --path . res://tests/smoke_ui.tscn
run_step "메인 씬 스모크" "$GODOT" --headless --path . --quit-after 120

rm -f "$LOG"
if [ $status -eq 0 ]; then echo "모든 검증 통과"; else echo "검증 실패"; fi
exit $status
