#!/usr/bin/env python3
"""다른 프로젝트로 넘길 것만 추려 한 폴더(또는 zip)로 모은다 — 목록과 설명은 docs/EXPORT_KIT.md.

  python3 tools/export_kit.py <출력 폴더> [--only=kit,actors,...] [--zip] [--list]

저장소 안 경로를 그대로 유지해 복사한다(그림 도구 · 코드가 서로를 찾는 경로가 안 깨지게).
.import · __pycache__ · *_orig 백업은 뺀다(.uid는 Godot이 다시 만든다 — 같이 넘겨도 무방해 둔다).
"""
from __future__ import annotations

import os
import shutil
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# 묶음 id → (설명, 경로들). 경로는 파일 또는 폴더.
GROUPS: dict[str, tuple[str, list[str]]] = {
	"kit": ("던전 에셋 키트(바닥 · 벽 · 소품 · 물건 288종 + 지역 표) + 생성기 + 창구 코드", [
		"assets/dungeon_kit", "tools/dungeon_kit", "src/kit", "docs/DUNGEON_KIT.md", "docs/asset_library",
		"tools/kit_gallery.gd", "tools/kit_gallery.tscn", "tools/kit_demo.gd",
	]),
	"actors": ("플레이어 · 탐험가: 맵 걷기 시트(종족 5 · 차림 53) + 전투 뒷모습 · 동작 시트 + 그림 도구", [
		"assets/actors/barbarian.webp", "assets/actors/beastkin.webp", "assets/actors/dwarf.webp",
		"assets/actors/elf.webp", "assets/actors/human.webp", "assets/actors/looks", "assets/party",
		"tools/paint_actors.gd", "tools/paint_motions.gd", "tools/paint_look_preview.gd", "tools/art_review.py",
	]),
	"monsters": ("몬스터: 전투 그림(종마다 한 장) + 맵 걷기 · 등장 시트 + 그림 도구(3D 점토 몸 → 손그림 마감)", [
		"assets/monsters", "assets/actors/monsters", "tools/monster_art", "tools/paint_monsters.gd",
	]),
	"explore": ("탐험 화면 재질: 1층 수정동굴 · 핏빛성채 · 빙하굴 · 녹색 탄광 · 강철의 묘 · 2층 넷 · 3층 바닥 · 벽 · 소품 · 데칼 + 상자 + 셰이더 + 그림 도구", [
		"assets/floor", "assets/shaders", "data/tiles.json",
		"tools/floor_art", "tools/f2_art", "tools/paint_floor.gd", "tools/paint_chest.gd",
		"tools/sheet_bounds.py", "tools/texture_compress.py",
	]),
	"explore_code": ("탐험 화면 그리기 코드(3/4 시점 청크 · 벽 · 시야 · 빛 — 그대로는 안 돌고 참고 · 이식용)", [
		"src/explore/view", "src/explore/Fov.gd", "src/explore/LightField.gd", "src/explore/Vision.gd",
	]),
	"town": ("도시: 동네 손그림 집 · 바닥 · 소품 · 재질 + 시설 정면 그림 · 실내 · 원경 · 광장 + 그림 도구", [
		"assets/town/houses", "assets/town/ground", "assets/town/props", "assets/town/mat",
		"assets/city/buildings", "assets/city/interiors", "assets/city/layers",
		"assets/city/plaza.webp", "assets/city/settle.webp",
		"tools/town_kit", "tools/town_art", "tools/city_art", "tools/paint_town.gd", "tools/paint_town_hand.gd",
		"tools/paint_town_houses.gd", "tools/paint_town_props.gd", "tools/paint_city.gd",
		"tools/town_hand_bake.py", "tools/town_retouch.py", "tools/town_handdrawn.py", "tools/interior_bake.py",
	]),
	"battle": ("전투 뒷그림(지역마다 한 장) + 그림 도구(레이캐스트 장면)", [
		"assets/battle", "tools/battle_art", "tools/paint_battlebacks.gd",
	]),
	"items": ("아이템 아이콘(무기 · 방어구 · 소모품 · 재료) + 상태 아이콘 + 동전 + 음식 · 책 그림 + 그림 도구", [
		"assets/items", "assets/statuses", "assets/ui", "assets/city/meals", "assets/city/books",
		"tools/item_art", "tools/paint_items.gd", "tools/status_art", "tools/paint_status_icons.gd",
		"tools/meal_art", "tools/paint_meals.gd", "tools/book_art", "tools/paint_books.gd", "tools/paint_coin.gd",
	]),
	"fonts": ("한글 글꼴(송명 + Noto Sans KR 서브셋, 둘 다 SIL OFL 1.1 — 라이선스 파일 포함)", [
		"assets/fonts",
	]),
	"audio": ("소리 99개(효과음 · 걸음 · 분위기 — 사용자가 준 음원, 출처 · 라이선스는 받은 곳에서 확인) + 쓰인 곳 표", [
		"assets/audio", "docs/AUDIO.md", "tools/import_sounds.py",
	]),
	"code": ("게임 규칙과 무관한 기반 코드(무작위 · JSON · 문자열 · 데이터 검증 · 키 입력 · UI 틀 · 대화창 · 캡처 · 테스트 틀)", [
		"src/core/Rng.gd", "src/core/JsonUtil.gd", "src/core/Strings.gd", "src/core/ScriptRegistry.gd",
		"src/core/ValidatorBase.gd", "src/core/DataValidator.gd", "src/core/GameClock.gd",
		"src/ui/InputSetup.gd", "src/ui/theme",
		"src/ui/widgets/ChoiceGrid.gd", "src/ui/widgets/ChoicePopup.gd", "src/ui/widgets/DialogueBox.gd",
		"src/ui/widgets/DialogueSplit.gd", "src/ui/widgets/GothicWindow.gd", "src/ui/widgets/ResourceBar.gd",
		"src/ui/widgets/LogPanel.gd", "src/ui/widgets/InventoryGrid.gd",
		"tools/check.sh", "tools/screenshot.gd", "tools/screenshot.tscn", "tools/ShotList.gd",
		"tests/TestCase.gd", "tests/run_tests.gd",
	]),
	"docs": ("그림체 규칙 · 그림 도구 명령 · 이 목록", [
		"docs/ART.md", "docs/TOOLS.md", "docs/EXPORT_KIT.md",
	]),
}

SKIP_EXT = (".import",)
SKIP_DIRS = ("__pycache__",)


def _files(rel: str) -> list[str]:
	path = os.path.join(ROOT, rel)
	if os.path.isfile(path):
		return [rel]
	out: list[str] = []
	for d, dirs, files in os.walk(path):
		dirs[:] = [x for x in dirs if x not in SKIP_DIRS and not x.endswith("_orig")]
		for f in files:
			if f.endswith(SKIP_EXT):
				continue
			out.append(os.path.relpath(os.path.join(d, f), ROOT))
	return out


def collect(only: list[str]) -> dict[str, list[str]]:
	res: dict[str, list[str]] = {}
	for gid, (_, paths) in GROUPS.items():
		if only and gid not in only:
			continue
		files: list[str] = []
		for p in paths:
			if not os.path.exists(os.path.join(ROOT, p)):
				print("없음:", p, file=sys.stderr)
				continue
			files += _files(p)
		res[gid] = sorted(set(files))
	return res


def main() -> None:
	args = [a for a in sys.argv[1:] if not a.startswith("--")]
	opts = {a.split("=")[0]: (a.split("=", 1)[1] if "=" in a else "1") for a in sys.argv[1:] if a.startswith("--")}
	only = [x for x in opts.get("--only", "").split(",") if x]
	groups = collect(only)
	total = 0
	for gid, files in groups.items():
		size = sum(os.path.getsize(os.path.join(ROOT, f)) for f in files)
		total += size
		print(f"{gid:13s} {len(files):5d}개 {size / 1e6:7.1f} MB  {GROUPS[gid][0]}")
	print(f"{'합계':12s} {sum(len(v) for v in groups.values()):5d}개 {total / 1e6:7.1f} MB")
	if "--list" in opts or not args:
		return
	out = os.path.abspath(args[0])
	for files in groups.values():
		for f in files:
			dst = os.path.join(out, f)
			os.makedirs(os.path.dirname(dst), exist_ok=True)
			shutil.copy2(os.path.join(ROOT, f), dst)
	with open(os.path.join(out, "MANIFEST.txt"), "w", encoding="utf-8") as fp:
		for gid, files in groups.items():
			fp.write(f"## {gid} — {GROUPS[gid][0]}\n")
			fp.writelines(f + "\n" for f in files)
	print("복사:", out)
	if "--zip" in opts:
		zpath = out.rstrip("/") + ".zip"
		with zipfile.ZipFile(zpath, "w", zipfile.ZIP_STORED) as z:  # webp · ogg는 이미 압축돼 있다
			for d, _, files in os.walk(out):
				for f in files:
					full = os.path.join(d, f)
					z.write(full, os.path.relpath(full, os.path.dirname(out)))
		print("zip:", zpath, f"{os.path.getsize(zpath) / 1e6:.1f} MB")


if __name__ == "__main__":
	main()
