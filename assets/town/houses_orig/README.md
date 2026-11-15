# 동네 집 그림 원본 백업(리터칭 전 — AM70, 2026-11-15)

`assets/town/houses/`를 리터칭(`tools/town_retouch.py`)하기 전 그대로 복사해 둔 것. `.gdignore`가 있어 Godot은 읽지 않는다(게임 · 웹 내보내기에 들어가지 않는다).

되돌리기:
- 그대로 되돌리기: `cp assets/town/houses_orig/*.webp assets/town/houses_orig/*.json assets/town/houses/` → `godot --headless --path . --import`
- 다시 구워서 되돌리기: `python3 tools/town_hand_bake.py --orig` → `paint_town_houses.gd -- --pack` → `python3 tools/town_house_masks.py` (날 그림은 리터칭 전과 같다)
