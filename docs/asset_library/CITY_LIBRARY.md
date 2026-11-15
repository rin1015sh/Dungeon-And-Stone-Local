# CITY_LIBRARY — 도시 · 건물 실내 에셋 라이브러리 카탈로그 (AM69)

> `python3 tools/dungeon_kit/library.py`가 `assets/dungeon_kit/kit.json`에서 만든다 — **손으로 고치지 않는다**. 같은 내용의 JSON = `city_library.json`. 쓰는 법 `docs/DUNGEON_KIT.md` §3, 갤러리 `tools/kit_gallery.tscn`.

이번에 새로 만든 에셋 **295종** · 변형 984개 · 그림 1269장(키트 전체 583종). 아래 표에서 **새** 표시가 없는 줄은 원래 있던 공용 에셋을 그 자리에 그대로 꺼내 쓰는 것이다(다시 만들지 않았다).

- **파일 경로**: 그림은 분류마다 묶음 한 장(`assets/dungeon_kit/<분류>.webp`)이고 낱 그림의 자리 · 원점은 `kit.json`에 있다. 게임에서는 `DungeonKit.open().make(id, 변형)`(노드) · `.texture(id, 변형)`(AtlasTexture 낱장)로 하나씩 꺼낸다.
- **크기**: 첫 변형의 그림 px(칸 = 64px로 나눈 값). 게임 세계에 놓을 때는 0.5배(한 칸 32px).
- **충돌**: ○ = `collide` 네모가 있다(`make`가 StaticBody2D를 단다). **애니**: 여러 프레임인 변형 이름.

| 분류 | 새 에셋 | 꺼내 쓰는 공용 | 변형(새) |
|---|---|---|---|
| 도시 외부 | 75 | 26 | 310 |
| 공통 실내 | 32 | 36 | 109 |
| 대장간 | 23 | 9 | 66 |
| 여관 | 14 | 13 | 37 |
| 신전 | 23 | 10 | 69 |
| 상점 | 22 | 10 | 65 |
| 은행 | 16 | 9 | 47 |
| 환경 흔적 | 6 | 35 | 22 |
| 파손 · 폐허 | 8 | 34 | 22 |
| 상호작용 오브젝트 | 15 | 50 | 52 |
| 마법 · 환경 효과 | 18 | 16 | 69 |
| 아이템 | 29 | 0 | 96 |
| UI 아이콘 | 18 | 0 | 36 |

## 도시 외부 — 101종

| 에셋 이름 | id | 새 | 분류 · 층 | 묶음 파일 | 크기 px(칸) | 사용 목적 | 다시 쓸 곳 | 변형 | 충돌 | 애니 |
|---|---|---|---|---|---|---|---|---|---|---|
| 연석 | `curb` | 새 | city · decal | `city.webp` | 90×32 (1.4×0.5) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 바닥 장식 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | h · v · corner_ne · corner_nw · corner_se · corner_sw · end · drop … (9) |  |  |
| 배수로 | `gutter` | 새 | city · decal | `city.webp` | 56×66 (0.9×1.0) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 바닥 장식 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | v · h · corner_ne · corner_nw · corner_se · corner_sw · end · h_flow … (9) |  | h_flow · v_flow |
| 길바닥 배수구 | `drain_grate` | 새 | city · decal | `city.webp` | 68×48 (1.1×0.8) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 상호작용(examine) | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | grate · clogged · open |  |  |
| 맨홀 | `manhole` | 새 | city · decal | `city.webp` | 80×58 (1.2×0.9) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 상호작용(hatch) | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | closed · open · ajar |  |  |
| 돌계단 | `street_steps` | 새 | city · stand | `city.webp` | 186×97 (2.9×1.5) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 상호작용(stairs) | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | wide · narrow · worn · grand |  |  |
| 작은 경사로 | `street_ramp` | 새 | city · stand | `city.webp` | 136×95 (2.1×1.5) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 상호작용(stairs) | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | stone · plank · plank_broken |  |  |
| 길 꺼진 자리 | `road_patch` | 새 | city · decal | `city.webp` | 109×97 (1.7×1.5) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 바닥 장식 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | sunken · sunken_b · dirt_b · dirt |  |  |
| 수레바퀴 자국 | `cart_ruts` | 새 | city · decal | `city.webp` | 174×65 (2.7×1.0) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 바닥 장식 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | h · v · curve |  |  |
| 흩어진 짚 | `straw_scatter` | 새 | city · decal | `city.webp` | 140×91 (2.2×1.4) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 바닥 장식 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | a · dung · b |  |  |
| 석조 집 벽 | `house_wall_stone` | 새 | city · stand | `city_build.webp` | 68×192 (1.1×3.0) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 · 광원 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | plain · plain_b · cracked · window · worn · window_lit · door · window_open | ○ |  |
| 목골 집 벽 | `house_wall_timber` | 새 | city · stand | `city_build.webp` | 68×192 (1.1×3.0) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 · 광원 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | plain · plain_b · worn · window · cracked · window_open · window_lit · door | ○ |  |
| 회벽 집 벽 | `house_wall_plaster` | 새 | city · stand | `city_build.webp` | 68×192 (1.1×3.0) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 · 광원 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | worn · plain_b · cracked · window · window_open · window_lit · plain · door | ○ |  |
| 집 벽 끝 | `house_wall_end` | 새 | city · stand | `city_build.webp` | 66×192 (1.0×3.0) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | timber_r · stone_l · stone_r · plaster_l · plaster_r · timber_l | ○ |  |
| 집 벽 모서리 | `house_corner` | 새 | city · stand | `city_build.webp` | 90×193 (1.4×3.0) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | stone · timber · plaster · stone_worn | ○ |  |
| 층 사이 띠(돌림띠 · 내민 들보) | `house_band` | 새 | city · wall_decal | `city_build.webp` | 68×32 (1.1×0.5) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 벽 장식 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | stone · timber · stone_dentil |  |  |
| 나무 너와 지붕 | `roof_wood` | 새 | city · over | `city_build.webp` | 68×185 (1.1×2.9) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 머리 위 전경 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | eave_b · eave · damaged · end_l · end_r · worn |  |  |
| 돌 너와 지붕 | `roof_slate` | 새 | city · over | `city_build.webp` | 68×185 (1.1×2.9) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 머리 위 전경 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | eave · eave_b · worn · damaged · end_l · end_r |  |  |
| 앞으로 향한 박공 | `roof_gable_front` | 새 | city · over | `city_build.webp` | 250×240 (3.9×3.8) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 머리 위 전경 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | plaster · timber · stone · timber_window |  |  |
| 굴뚝 | `chimney` | 새 | city · stand | `city_build.webp` | 44×159 (0.7×2.5) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 장식 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | stone_smoke · brick · stone · brick_smoke · broken |  | brick_smoke · stone_smoke |
| 집 창문 | `house_window` | 새 | city · wall_decal | `city_build.webp` | 44×60 (0.7×0.9) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 상호작용(window) · 광원 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | square_shut · square_open · square_lit · square_broken · square_boarded · arch · round · arch_lit … (10) |  |  |
| 집 나무 문 | `house_door` | 새 | city · wall_decal | `city_build.webp` | 59×124 (0.9×1.9) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 · 상호작용(door) | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | plain · plain_ajar · reinforced · reinforced_ajar · double_ajar · double | ○ |  |
| 집 쇠 문 | `house_iron_door` | 새 | city · wall_decal | `city_build.webp` | 65×131 (1.0×2.0) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 · 상호작용(door) | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | rusted · ajar · closed | ○ |  |
| 돌 아치 들머리 | `porch_arch` | 새 | city · stand | `city_build.webp` | 160×175 (2.5×2.7) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | open · worn · door | ○ |  |
| 처마 기둥 | `porch_post` | 새 | city · stand | `city_build.webp` | 85×183 (1.3×2.9) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | wood · stone_worn · stone · wood_brace | ○ |  |
| 발코니 | `balcony` | 새 | city · wall_decal | `city_build.webp` | 132×62 (2.1×1.0) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 벽 장식 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | wood · wood_plants · stone · wood_broken |  |  |
| 집 나무 난간 | `wood_railing` | 새 | city · stand | `city_build.webp` | 68×54 (1.1×0.8) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | straight · post · broken · corner | ○ |  |
| 바깥 계단 | `outside_stairs` | 새 | city · stand | `city_build.webp` | 135×215 (2.1×3.4) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 · 상호작용(stairs) | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | wood · stoop · wood_l · stoop_worn | ○ |  |
| 짐수레 | `cart` | 새 | city · stand | `city_life.webp` | 234×119 (3.7×1.9) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 · 상호작용(container) | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | sacks · empty · barrels · hay · broken | ○ |  |
| 손수레 | `handcart` | 새 | city · stand | `city_life.webp` | 152×87 (2.4×1.4) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 · 상호작용(container) | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | empty · tipped · loaded | ○ |  |
| 시장 좌판 | `market_stall` | 새 | city · stand | `city_life.webp` | 190×176 (3.0×2.8) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 · 상호작용(shop) | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | produce · bread · pottery · fish · wrecked · cloth · empty | ○ |  |
| 차양 천막 | `market_awning` | 새 | city · stand | `city_life.webp` | 253×208 (4.0×3.2) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | striped · torn · plain | ○ |  |
| 벽 차양 | `wall_awning` | 새 | city · wall_decal | `city_life.webp` | 130×86 (2.0×1.3) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 벽 장식 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | striped · plain · torn |  |  |
| 청과 상자 | `produce_crate` | 새 | city · stand | `city_life.webp` | 65×43 (1.0×0.7) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | greens · apples · roots · stack | ○ |  |
| 깃대 | `flag_pole` | 새 | city · stand | `city_life.webp` | 109×260 (1.7×4.1) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | stripes · quartered · chevron · tattered · bare | ○ |  |
| 벽 깃발 | `wall_flag` | 새 | city · wall_decal | `city_life.webp` | 81×83 (1.3×1.3) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 벽 장식 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | stripes · chevron · tattered |  |  |
| 세로 현수막 | `banner_hanging` | 새 | city · wall_decal | `city_life.webp` | 60×102 (0.9×1.6) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 벽 장식 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | chevron · border · plain · torn |  |  |
| 줄 깃발 | `bunting` | 새 | city · over | `city_life.webp` | 354×55 (5.5×0.9) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 머리 위 전경 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | sparse · tattered · festive |  |  |
| 돌출 간판 | `shop_sign` | 새 | city · wall_decal | `city_life.webp` | 57×60 (0.9×0.9) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 벽 장식 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | inn · shop · smithy · bank · guild · library · blank · broken |  |  |
| 세움 간판 | `sign_aframe` | 새 | city · stand | `city_life.webp` | 93×80 (1.4×1.2) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | inn · shop · fallen · blank | ○ |  |
| 빨랫줄 | `clothesline` | 새 | city · stand | `city_life.webp` | 269×127 (4.2×2.0) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | laundry · sheets · empty | ○ |  |
| 골목 위 빨랫줄 | `clothesline_hanging` | 새 | city · over | `city_life.webp` | 364×70 (5.7×1.1) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 머리 위 전경 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | laundry · sparse |  |  |
| 화분 | `planter` | 새 | city · stand | `city_life.webp` | 84×73 (1.3×1.1) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 장식 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | herb · flowers · shrub · dead · broken · empty · group |  |  |
| 창가 꽃상자 | `flower_box` | 새 | city · wall_decal | `city_life.webp` | 87×45 (1.4×0.7) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 벽 장식 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | herb · flowers · dead · empty |  |  |
| 가로수 | `street_tree` | 새 | city · stand | `city_life.webp` | 141×171 (2.2×2.7) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | ring · trimmed · guard · bare | ○ |  |
| 다듬은 생울타리 | `hedge` | 새 | city · stand | `city_life.webp` | 109×73 (1.7×1.1) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | end · corner · overgrown · gap · straight | ○ |  |
| 낙엽 | `fallen_leaves` | 새 | city · decal | `city_life.webp` | 86×56 (1.3×0.9) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 바닥 장식 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | autumn · wet · pile · scatter |  |  |
| 물지게 | `water_yoke` | 새 | city · stand | `city_life.webp` | 106×50 (1.7×0.8) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 장식 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | full · empty · set_down |  |  |
| 버려진 물건 더미 | `junk_pile` | 새 | city · stand | `city_life.webp` | 118×62 (1.8×1.0) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 장식 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | large · small · alley |  |  |
| 빨래 함지 | `washtub` | 새 | city · stand | `city_life.webp` | 88×62 (1.4×1.0) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 장식 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | laundry · water · empty · board |  |  |
| 건초 더미 | `hay_bale` | 새 | city · stand | `city_life.webp` | 127×74 (2.0×1.2) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | stack · bale · loose · fork | ○ |  |
| 말 매는 말뚝 | `hitching_post` | 새 | city · stand | `city_life.webp` | 104×55 (1.6×0.9) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | rail · post · rail_rope · broken | ○ |  |
| 빗물 통 | `rain_barrel` | 새 | city · stand | `city_life.webp` | 94×124 (1.5×1.9) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | full · overflow · dry | ○ |  |
| 닭장 | `chicken_coop` | 새 | city · stand | `city_life.webp` | 123×103 (1.9×1.6) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | closed · open · broken | ○ |  |
| 우물 | `well` | 새 | city · stand | `city_public.webp` | 144×216 (2.2×3.4) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 · 상호작용(well) | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | roofed · plain · broken | ○ |  |
| 분수 | `fountain` | 새 | city · stand | `city_public.webp` | 211×193 (3.3×3.0) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 · 상호작용(examine) | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | running · broken · dry | ○ | running |
| 가로등 | `street_lamp` | 새 | city · stand | `city_public.webp` | 78×213 (1.2×3.3) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 · 광원 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | lit · unlit · bent | ○ | lit |
| 게시판 | `notice_board` | 새 | city · stand | `city_public.webp` | 149×177 (2.3×2.8) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 · 상호작용(examine) | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | notices · empty · torn | ○ |  |
| 갈림길 표지판 | `signpost` | 새 | city · stand | `city_public.webp` | 107×154 (1.7×2.4) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | two · three · one · leaning | ○ |  |
| 안내판 | `info_board` | 새 | city · stand | `city_public.webp` | 129×92 (2.0×1.4) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 · 상호작용(examine) | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | stone · wood · wall | ○ |  |
| 돌말뚝 | `bollard` | 새 | city · stand | `city_public.webp` | 69×61 (1.1×0.9) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | stone · chained · iron · broken | ○ |  |
| 물구유 | `horse_trough` | 새 | city · stand | `city_public.webp` | 135×61 (2.1×0.9) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | stone · wood_dry · wood | ○ |  |
| 광장 기념 돌 | `plaza_monument` | 새 | city · stand | `city_public.webp` | 122×233 (1.9×3.6) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | obelisk_worn · obelisk · sundial | ○ |  |
| 성벽 | `city_wall` | 새 | city · stand | `city_public.webp` | 68×325 (1.1×5.1) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 · 광원 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | straight · torch · damaged · drain | ○ | torch |
| 성벽 탑 | `city_wall_tower` | 새 | city · stand | `city_public.webp` | 194×447 (3.0×7.0) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | intact · lit · damaged | ○ |  |
| 성문 | `city_gate` | 새 | city · stand | `city_public.webp` | 352×424 (5.5×6.6) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 · 상호작용(gate) | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | open · open_banner · shut · portcullis | ○ |  |
| 나무 망루 | `watchtower` | 새 | city · stand | `city_public.webp` | 189×388 (3.0×6.1) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 · 광원 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | lit · intact · ruined | ○ | lit |
| 쇠 울타리 | `iron_fence` | 새 | city · stand | `city_public.webp` | 68×91 (1.1×1.4) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | straight · gate_open · post · gate_shut · bent | ○ |  |
| 나무 울타리 | `wood_fence` | 새 | city · stand | `city_public.webp` | 68×71 (1.1×1.1) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 이동 방해 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | rail · corner · gate · picket · gate_open · broken | ○ |  |
| 큰길 포석 | `street_setts` | 새 | floor · floor | `floors.webp` | 256×256 (4.0×4.0) | 바닥 타일(4 × 4칸 이어지는 그림) — 타일 | 도시 거리 · 건물 실내 · 미궁의 지은 공간 | b · a |  |  |
| 낡고 꺼진 포석 | `street_worn_setts` | 새 | floor · floor | `floors.webp` | 256×256 (4.0×4.0) | 바닥 타일(4 × 4칸 이어지는 그림) — 타일 | 도시 거리 · 건물 실내 · 미궁의 지은 공간 | a |  |  |
| 광장 판석 | `street_plaza` | 새 | floor · floor | `floors.webp` | 256×256 (4.0×4.0) | 바닥 타일(4 × 4칸 이어지는 그림) — 타일 | 도시 거리 · 건물 실내 · 미궁의 지은 공간 | b · a |  |  |
| 자갈길 | `street_gravel` | 새 | floor · floor | `floors.webp` | 256×256 (4.0×4.0) | 바닥 타일(4 × 4칸 이어지는 그림) — 타일 | 도시 거리 · 건물 실내 · 미궁의 지은 공간 | a · b |  |  |
| 판석 보도 | `street_sidewalk` | 새 | floor · floor | `floors.webp` | 256×256 (4.0×4.0) | 바닥 타일(4 × 4칸 이어지는 그림) — 타일 | 도시 거리 · 건물 실내 · 미궁의 지은 공간 | a · b |  |  |
| 풀이 자란 돌바닥 | `street_overgrown` | 새 | floor · floor | `floors.webp` | 256×256 (4.0×4.0) | 바닥 타일(4 × 4칸 이어지는 그림) — 타일 | 도시 거리 · 건물 실내 · 미궁의 지은 공간 | a · b |  |  |
| 바큇자국 난 흙길 | `street_rutted` | 새 | floor · floor | `floors.webp` | 256×256 (4.0×4.0) | 바닥 타일(4 × 4칸 이어지는 그림) — 타일 | 도시 거리 · 건물 실내 · 미궁의 지은 공간 | h · v · h_b |  |  |
| 석재 바닥 | `floor_flag` |  | floor · floor | `floors.webp` | 256×256 (4.0×4.0) | 바닥 타일(4 × 4칸 이어지는 그림) — 타일 | 도시 거리 · 건물 실내 · 미궁의 지은 공간 | a · b |  |  |
| 오래된 석재 바닥 | `floor_old` |  | floor · floor | `floors.webp` | 256×256 (4.0×4.0) | 바닥 타일(4 × 4칸 이어지는 그림) — 타일 | 도시 거리 · 건물 실내 · 미궁의 지은 공간 | a · b |  |  |
| 금이 간 바닥 | `floor_cracked` |  | floor · floor | `floors.webp` | 256×256 (4.0×4.0) | 바닥 타일(4 × 4칸 이어지는 그림) — 타일 | 도시 거리 · 건물 실내 · 미궁의 지은 공간 | a |  |  |
| 깨진 바닥 | `floor_broken` |  | floor · floor | `floors.webp` | 256×256 (4.0×4.0) | 바닥 타일(4 × 4칸 이어지는 그림) — 타일 | 도시 거리 · 건물 실내 · 미궁의 지은 공간 | a |  |  |
| 불규칙한 돌바닥 | `floor_cobble` |  | floor · floor | `floors.webp` | 256×256 (4.0×4.0) | 바닥 타일(4 × 4칸 이어지는 그림) — 타일 | 도시 거리 · 건물 실내 · 미궁의 지은 공간 | b · a |  |  |
| 흙바닥 | `floor_dirt` |  | floor · floor | `floors.webp` | 256×256 (4.0×4.0) | 바닥 타일(4 × 4칸 이어지는 그림) — 타일 | 도시 거리 · 건물 실내 · 미궁의 지은 공간 | a · b |  |  |
| 이끼가 낀 바닥 | `floor_mossy` |  | floor · floor | `floors.webp` | 256×256 (4.0×4.0) | 바닥 타일(4 × 4칸 이어지는 그림) — 타일 | 도시 거리 · 건물 실내 · 미궁의 지은 공간 | a |  |  |
| 검은 진흙 | `ground_mud` |  | floor · floor | `floors.webp` | 256×256 (4.0×4.0) | 바닥 타일(4 × 4칸 이어지는 그림) — 타일 | 도시 거리 · 건물 실내 · 미궁의 지은 공간 | b · a |  |  |
| 웅덩이 | `puddle` |  | nature · decal | `nature.webp` | 53×38 (0.8×0.6) | 자연물 — 바닥 장식 | 야외 · 동굴 | small · medium · murky · ripple · bloody · large |  | ripple |
| 바닥 균열 | `ground_crack` |  | nature · decal | `nature.webp` | 118×87 (1.8×1.4) | 자연물 — 바닥 장식 | 야외 · 동굴 | b · a · c · wide |  |  |
| 이끼 | `moss_patch` |  | nature · decal | `nature.webp` | 129×97 (2.0×1.5) | 자연물 — 바닥 장식 | 야외 · 동굴 | a · b · c · dry · d |  |  |
| 잡초 | `weeds` |  | nature · stand | `nature.webp` | 56×48 (0.9×0.8) | 자연물 — 장식 | 야외 · 동굴 | tuft_a · dead_bush · tuft_dry · fern · sprouts · bramble · tuft_b |  |  |
| 자갈 | `gravel` |  | nature · decal | `nature.webp` | 105×92 (1.6×1.4) | 자연물 — 바닥 장식 | 야외 · 동굴 | b · a · c · sparse |  |  |
| 말뚝 울타리 | `palisade` |  | structure · stand | `structure.webp` | 192×134 (3.0×2.1) | 이동을 막는 큰 구조물 — 이동 방해 | 미궁 · 도시 | straight_b · broken · corner · straight_a · gate · spiked · gate_open | ○ |  |
| 나무통 | `barrel` |  | furniture · stand | `furniture.webp` | 98×83 (1.5×1.3) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | intact · broken · toppled · water · stack | ○ |  |
| 나무 상자 | `crate` |  | furniture · stand | `furniture.webp` | 94×76 (1.5×1.2) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | intact · open · broken · stack | ○ |  |
| 자루 | `sack` |  | furniture · stand | `furniture.webp` | 70×40 (1.1×0.6) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | slumped · full · open · pile | ○ |  |
| 바구니 | `basket` |  | furniture · stand | `furniture.webp` | 63×49 (1.0×0.8) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | empty · food · toppled | ○ |  |
| 긴 의자 | `bench` |  | furniture · stand | `furniture.webp` | 125×45 (1.9×0.7) | 가구 · 생활 물건 — 이동 방해 | 실내 어디든 | base · broken | ○ |  |
| 덤불 | `bush` |  | flora · stand | `flora.webp` | 137×89 (2.1×1.4) |  — 장식 |  | a · b · wide · flowering · snowy · dry |  |  |
| 활엽수 | `tree_broadleaf` |  | flora · stand | `flora.webp` | 179×336 (2.8×5.2) |  — 이동 방해 |  | b · young · a · c · autumn · fruit · bare | ○ |  |
| 들꽃 무더기 | `flowers` |  | flora · stand | `flora.webp` | 94×47 (1.5×0.7) |  — 장식 |  | white · violet · yellow · mixed_a · mixed_b · red |  |  |
| 걸린 랜턴 | `lantern_hanging` |  | light · wall_decal | `light.webp` | 57×91 (0.9×1.4) | 빛을 내는 것 — 광원 | 어디든 | lit · unlit |  | lit |
| 벽 횃불 | `torch_wall` |  | light · wall_decal | `light.webp` | 97×102 (1.5×1.6) | 빛을 내는 것 — 광원 | 어디든 | lit · stub · unlit |  | lit |
| 아치 | `arch` |  | structure · stand | `structure.webp` | 250×238 (3.9×3.7) | 이동을 막는 큰 구조물 — 이동 방해 | 미궁 · 도시 | intact · mossy · ruined | ○ |  |
| 난간 | `railing` |  | structure · stand | `structure.webp` | 109×71 (1.7×1.1) | 이동을 막는 큰 구조물 — 이동 방해 | 미궁 · 도시 | straight · post · side · broken | ○ |  |

## 공통 실내 — 68종

| 에셋 이름 | id | 새 | 분류 · 층 | 묶음 파일 | 크기 px(칸) | 사용 목적 | 다시 쓸 곳 | 변형 | 충돌 | 애니 |
|---|---|---|---|---|---|---|---|---|---|---|
| 목재 마루 | `room_wood` | 새 | floor · floor | `floors.webp` | 256×256 (4.0×4.0) | 바닥 타일(4 × 4칸 이어지는 그림) — 타일 | 도시 거리 · 건물 실내 · 미궁의 지은 공간 | a · b |  |  |
| 낡은 마루 | `room_wood_old` | 새 | floor · floor | `floors.webp` | 256×256 (4.0×4.0) | 바닥 타일(4 × 4칸 이어지는 그림) — 타일 | 도시 거리 · 건물 실내 · 미궁의 지은 공간 | a |  |  |
| 무늬 타일 바닥 | `room_tile` | 새 | floor · floor | `floors.webp` | 256×256 (4.0×4.0) | 바닥 타일(4 × 4칸 이어지는 그림) — 타일 | 도시 거리 · 건물 실내 · 미궁의 지은 공간 | checker · inlay |  |  |
| 실내 창문 | `room_window` | 새 | interior · wall_decal | `interior.webp` | 67×86 (1.1×1.3) | 건물 안을 채우는 공용 가구 · 살림 · 장식 — 광원 | 모든 시설 · 일반 집 · 미궁 안 거처 · 균열의 방 | day · night · broken · shuttered · curtained |  |  |
| 나무 계단 | `wood_stairs` | 새 | interior · stand | `interior.webp` | 120×230 (1.9×3.6) | 건물 안을 채우는 공용 가구 · 살림 · 장식 — 이동 방해 | 모든 시설 · 일반 집 · 미궁 안 거처 · 균열의 방 | up · broken | ○ |  |
| 나무 기둥 | `wood_post` | 새 | interior · stand | `interior.webp` | 95×178 (1.5×2.8) | 건물 안을 채우는 공용 가구 · 살림 · 장식 — 이동 방해 | 모든 시설 · 일반 집 · 미궁 안 거처 · 균열의 방 | plain · cracked · braced | ○ |  |
| 나무 난간 | `banister` | 새 | interior · stand | `interior.webp` | 109×70 (1.7×1.1) | 건물 안을 채우는 공용 가구 · 살림 · 장식 — 이동 방해 | 모든 시설 · 일반 집 · 미궁 안 거처 · 균열의 방 | straight · post · broken | ○ |  |
| 긴 테이블 | `long_table` | 새 | interior · stand | `interior.webp` | 212×119 (3.3×1.9) | 건물 안을 채우는 공용 가구 · 살림 · 장식 — 이동 방해 | 모든 시설 · 일반 집 · 미궁 안 거처 · 균열의 방 | broken · empty · set | ○ |  |
| 작은 원탁 | `round_table` | 새 | interior · stand | `interior.webp` | 89×80 (1.4×1.2) | 건물 안을 채우는 공용 가구 · 살림 · 장식 — 이동 방해 · 광원 | 모든 시설 · 일반 집 · 미궁 안 거처 · 균열의 방 | candle · cloth · plain | ○ | candle |
| 협탁 | `nightstand` | 새 | interior · stand | `interior.webp` | 77×62 (1.2×1.0) | 건물 안을 채우는 공용 가구 · 살림 · 장식 — 이동 방해 · 광원 | 모든 시설 · 일반 집 · 미궁 안 거처 · 균열의 방 | plain · candle · open | ○ | candle |
| 카운터 | `counter` | 새 | interior · stand | `interior.webp` | 97×72 (1.5×1.1) | 건물 안을 채우는 공용 가구 · 살림 · 장식 — 이동 방해 · 상호작용(counter) | 모든 시설 · 일반 집 · 미궁 안 거처 · 균열의 방 | straight · side · corner · end_closed · end_open | ○ |  |
| 장식장 | `display_cabinet` | 새 | interior · stand | `interior.webp` | 104×127 (1.6×2.0) | 건물 안을 채우는 공용 가구 · 살림 · 장식 — 이동 방해 · 상호작용(container) | 모든 시설 · 일반 집 · 미궁 안 거처 · 균열의 방 | empty · broken · curios | ○ |  |
| 안락의자 | `armchair` | 새 | interior · stand | `interior.webp` | 94×104 (1.5×1.6) | 건물 안을 채우는 공용 가구 · 살림 · 장식 — 이동 방해 | 모든 시설 · 일반 집 · 미궁 안 거처 · 균열의 방 | s · e · w · worn · broken | ○ |  |
| 이층 침대 | `bunk_bed` | 새 | interior · stand | `interior.webp` | 164×142 (2.6×2.2) | 건물 안을 채우는 공용 가구 · 살림 · 장식 — 이동 방해 | 모든 시설 · 일반 집 · 미궁 안 거처 · 균열의 방 | made · messy | ○ |  |
| 태피스트리 | `tapestry` | 새 | interior · wall_decal | `interior.webp` | 123×99 (1.9×1.6) | 건물 안을 채우는 공용 가구 · 살림 · 장식 — 벽 장식 | 모든 시설 · 일반 집 · 미궁 안 거처 · 균열의 방 | foliage · bands · hunt · torn · worn |  |  |
| 벽걸이 천 | `wall_cloth` | 새 | interior · wall_decal | `interior.webp` | 42×98 (0.7×1.5) | 건물 안을 채우는 공용 가구 · 살림 · 장식 — 벽 장식 | 모든 시설 · 일반 집 · 미궁 안 거처 · 균열의 방 | red · faded · blue |  |  |
| 그림 액자 | `painting` | 새 | interior · wall_decal | `interior.webp` | 59×47 (0.9×0.7) | 건물 안을 채우는 공용 가구 · 살림 · 장식 — 벽 장식 | 모든 시설 · 일반 집 · 미궁 안 거처 · 균열의 방 | landscape · portrait · still_life · empty_frame · slashed · crooked |  |  |
| 장식 문양판 | `motif_plaque` | 새 | interior · wall_decal | `interior.webp` | 42×44 (0.7×0.7) | 건물 안을 채우는 공용 가구 · 살림 · 장식 — 벽 장식 | 모든 시설 · 일반 집 · 미궁 안 거처 · 균열의 방 | rosette · parted_shield · frieze |  |  |
| 벽걸이 장식 | `wall_ornament` | 새 | interior · wall_decal | `interior.webp` | 24×24 (0.4×0.4) | 건물 안을 채우는 공용 가구 · 살림 · 장식 — 벽 장식 | 모든 시설 · 일반 집 · 미궁 안 거처 · 균열의 방 | horseshoe · wreath · farm_tools · oars |  |  |
| 사냥 기념물 | `hunting_trophy` | 새 | interior · wall_decal | `interior.webp` | 27×42 (0.4×0.7) | 건물 안을 채우는 공용 가구 · 살림 · 장식 — 벽 장식 | 모든 시설 · 일반 집 · 미궁 안 거처 · 균열의 방 | boar_head · antlers · fish |  |  |
| 벽 깃발 줄 | `pennant_row` | 새 | interior · wall_decal | `interior.webp` | 160×28 (2.5×0.4) | 건물 안을 채우는 공용 가구 · 살림 · 장식 — 벽 장식 | 모든 시설 · 일반 집 · 미궁 안 거처 · 균열의 방 | faded · bright · torn |  |  |
| 짐승 가죽 깔개 | `pelt_rug` | 새 | interior · decal | `interior.webp` | 172×82 (2.7×1.3) | 건물 안을 채우는 공용 가구 · 살림 · 장식 — 바닥 장식 | 모든 시설 · 일반 집 · 미궁 안 거처 · 균열의 방 | wolf · bear |  |  |
| 실내 화분 | `potted_plant` | 새 | interior · stand | `interior.webp` | 73×51 (1.1×0.8) | 건물 안을 채우는 공용 가구 · 살림 · 장식 — 이동 방해 | 모든 시설 · 일반 집 · 미궁 안 거처 · 균열의 방 | fern · tree · dead | ○ |  |
| 장식 접시 걸이 | `plate_rack` | 새 | interior · wall_decal | `interior.webp` | 85×29 (1.3×0.5) | 건물 안을 채우는 공용 가구 · 살림 · 장식 — 벽 장식 | 모든 시설 · 일반 집 · 미궁 안 거처 · 균열의 방 | full · sparse |  |  |
| 걸이 화분 | `hanging_pot` | 새 | interior · over | `interior.webp` | 27×70 (0.4×1.1) | 건물 안을 채우는 공용 가구 · 살림 · 장식 — 머리 위 전경 | 모든 시설 · 일반 집 · 미궁 안 거처 · 균열의 방 | vines · dry |  |  |
| 저장 항아리 | `storage_jar` | 새 | interior · stand | `interior.webp` | 59×50 (0.9×0.8) | 건물 안을 채우는 공용 가구 · 살림 · 장식 — 이동 방해 · 상호작용(container) | 모든 시설 · 일반 집 · 미궁 안 거처 · 균열의 방 | jar · amphora · crock · group · cracked · broken | ○ |  |
| 잔 | `drinkware` | 새 | interior · stand | `interior.webp` | 45×27 (0.7×0.4) | 건물 안을 채우는 공용 가구 · 살림 · 장식 — 장식 | 모든 시설 · 일반 집 · 미궁 안 거처 · 균열의 방 | tankards · cups · goblets · toppled |  |  |
| 차린 음식 | `served_food` | 새 | interior · stand | `interior.webp` | 47×28 (0.7×0.4) | 건물 안을 채우는 공용 가구 · 살림 · 장식 — 장식 | 모든 시설 · 일반 집 · 미궁 안 거처 · 균열의 방 | loaves · cheese · fruit · roast · pie |  |  |
| 작은 장식품 | `trinket` | 새 | interior · stand | `interior.webp` | 43×35 (0.7×0.6) | 건물 안을 채우는 공용 가구 · 살림 · 장식 — 장식 | 모든 시설 · 일반 집 · 미궁 안 거처 · 균열의 방 | vase · figurine · hourglass · box |  |  |
| 목재 벽 | `wall_wood` | 새 | wall · wall | `wall_faces.webp` | 256×160 (4.0×2.5) | 벽 타일(윗면 자동 연결 + 벽면) — 타일 | 건물 실내 · 미궁의 지은 공간 | clean · cracked · mossy · damaged |  |  |
| 회벽 | `wall_plaster` | 새 | wall · wall | `wall_faces.webp` | 256×160 (4.0×2.5) | 벽 타일(윗면 자동 연결 + 벽면) — 타일 | 건물 실내 · 미궁의 지은 공간 | clean · cracked · mossy · damaged |  |  |
| 장식 판벽 | `wall_panel` | 새 | wall · wall | `wall_faces.webp` | 256×160 (4.0×2.5) | 벽 타일(윗면 자동 연결 + 벽면) — 타일 | 건물 실내 · 미궁의 지은 공간 | clean · cracked · mossy · damaged |  |  |
| 석재 바닥 | `floor_flag` |  | floor · floor | `floors.webp` | 256×256 (4.0×4.0) | 바닥 타일(4 × 4칸 이어지는 그림) — 타일 | 도시 거리 · 건물 실내 · 미궁의 지은 공간 | a · b |  |  |
| 벽돌 바닥 | `floor_brick` |  | floor · floor | `floors.webp` | 256×256 (4.0×4.0) | 바닥 타일(4 × 4칸 이어지는 그림) — 타일 | 도시 거리 · 건물 실내 · 미궁의 지은 공간 | b · a |  |  |
| 석벽 | `wall_stone` |  | wall · wall | `wall_faces.webp` | 256×160 (4.0×2.5) | 벽 타일(윗면 자동 연결 + 벽면) — 타일 | 건물 실내 · 미궁의 지은 공간 | clean · cracked · mossy · damaged |  |  |
| 벽돌벽 | `wall_brick` |  | wall · wall | `wall_faces.webp` | 256×160 (4.0×2.5) | 벽 타일(윗면 자동 연결 + 벽면) — 타일 | 건물 실내 · 미궁의 지은 공간 | clean · cracked · mossy · damaged |  |  |
| 문틀과 문 | `doorway` |  | wall · stand | `wall.webp` | 141×193 (2.2×3.0) | 벽 타일(윗면 자동 연결 + 벽면) — 이동 방해 · 상호작용(door) | 건물 실내 · 미궁의 지은 공간 | open · wood · wood_ajar · wood_broken · iron · portcullis · iron_ajar · portcullis_up … (9) | ○ |  |
| 기둥 | `pillar` |  | structure · stand | `structure.webp` | 117×216 (1.8×3.4) | 이동을 막는 큰 구조물 — 이동 방해 | 미궁 · 도시 | intact · cracked · mossy · broken · stump · fallen | ○ |  |
| 올라가는 계단 | `stairs_up` |  | structure · stand | `structure.webp` | 204×188 (3.2×2.9) | 이동을 막는 큰 구조물 — 이동 방해 · 상호작용(stairs) | 미궁 · 도시 | stone · worn | ○ |  |
| 내려가는 계단 | `stairs_down` |  | structure · decal | `structure.webp` | 126×99 (2.0×1.6) | 이동을 막는 큰 구조물 — 상호작용(stairs) | 미궁 · 도시 | stone |  |  |
| 깔개 | `carpet` |  | furniture · decal | `furniture.webp` | 200×124 (3.1×1.9) | 가구 · 생활 물건 — 바닥 장식 | 실내 어디든 | blue · red · green · round · worn · torn |  |  |
| 탁자 | `table` |  | furniture · stand | `furniture.webp` | 151×86 (2.4×1.3) | 가구 · 생활 물건 — 이동 방해 | 실내 어디든 | intact · set · toppled · broken | ○ |  |
| 책상 | `desk` |  | furniture · stand | `furniture.webp` | 147×77 (2.3×1.2) | 가구 · 생활 물건 — 이동 방해 | 실내 어디든 | intact · broken · cluttered | ○ |  |
| 의자 | `chair` |  | furniture · stand | `furniture.webp` | 89×80 (1.4×1.2) | 가구 · 생활 물건 — 이동 방해 | 실내 어디든 | s · e · w · n · toppled · broken | ○ |  |
| 걸상 | `stool` |  | furniture · stand | `furniture.webp` | 59×44 (0.9×0.7) | 가구 · 생활 물건 — 이동 방해 | 실내 어디든 | base · toppled | ○ |  |
| 긴 의자 | `bench` |  | furniture · stand | `furniture.webp` | 125×45 (1.9×0.7) | 가구 · 생활 물건 — 이동 방해 | 실내 어디든 | base · broken | ○ |  |
| 침대 | `bed` |  | furniture · stand | `furniture.webp` | 160×98 (2.5×1.5) | 가구 · 생활 물건 — 이동 방해 | 실내 어디든 | made · messy · bare · broken | ○ |  |
| 책장 | `bookshelf` |  | furniture · stand | `furniture.webp` | 142×143 (2.2×2.2) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | half · empty · full · broken | ○ |  |
| 벽 선반 | `wall_shelf` |  | furniture · wall_decal | `furniture.webp` | 82×30 (1.3×0.5) | 가구 · 생활 물건 — 벽 장식 | 실내 어디든 | bottles · empty · skull · books |  |  |
| 캐비닛 | `cabinet` |  | furniture · stand | `furniture.webp` | 143×141 (2.2×2.2) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | open · closed · broken | ○ |  |
| 서랍장 | `dresser` |  | furniture · stand | `furniture.webp` | 105×78 (1.6×1.2) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | open · closed | ○ |  |
| 나무 상자 | `crate` |  | furniture · stand | `furniture.webp` | 94×76 (1.5×1.2) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | intact · open · broken · stack | ○ |  |
| 보물상자 | `chest` |  | furniture · stand | `furniture.webp` | 97×56 (1.5×0.9) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | closed · open · locked · broken · empty | ○ |  |
| 나무통 | `barrel` |  | furniture · stand | `furniture.webp` | 98×83 (1.5×1.3) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | intact · broken · toppled · water · stack | ○ |  |
| 바구니 | `basket` |  | furniture · stand | `furniture.webp` | 63×49 (1.0×0.8) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | empty · food · toppled | ○ |  |
| 자루 | `sack` |  | furniture · stand | `furniture.webp` | 70×40 (1.1×0.6) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | slumped · full · open · pile | ○ |  |
| 병 | `bottles` |  | furniture · stand | `furniture.webp` | 51×37 (0.8×0.6) | 가구 · 생활 물건 — 장식 | 실내 어디든 | group · potion_red · potion_blue · fallen · wine |  |  |
| 식기 | `dishes` |  | furniture · stand | `furniture.webp` | 55×28 (0.9×0.4) | 가구 · 생활 물건 — 장식 | 실내 어디든 | set · bowls · dirty |  |  |
| 책 | `books` |  | furniture · stand | `furniture.webp` | 50×34 (0.8×0.5) | 가구 · 생활 물건 — 장식 | 실내 어디든 | open · stack · scattered · tall |  |  |
| 흩어진 문서 | `papers` |  | furniture · decal | `furniture.webp` | 82×44 (1.3×0.7) | 가구 · 생활 물건 — 바닥 장식 | 실내 어디든 | b · a · stack |  |  |
| 두루마리 | `scrolls` |  | furniture · stand | `furniture.webp` | 64×40 (1.0×0.6) | 가구 · 생활 물건 — 장식 | 실내 어디든 | pile · open · case |  |  |
| 양초 무더기 | `candles` |  | light · stand | `light.webp` | 78×69 (1.2×1.1) | 빛을 내는 것 — 광원 | 어디든 | lit · unlit · stubs |  | lit |
| 촛대 | `candlestick` |  | light · stand | `light.webp` | 87×116 (1.4×1.8) | 빛을 내는 것 — 이동 방해 · 광원 | 어디든 | lit · unlit | ○ | lit |
| 세 갈래 촛대 | `candelabra` |  | light · stand | `light.webp` | 97×133 (1.5×2.1) | 빛을 내는 것 — 이동 방해 · 광원 | 어디든 | lit · unlit | ○ | lit |
| 랜턴 | `lantern` |  | light · stand | `light.webp` | 85×67 (1.3×1.1) | 빛을 내는 것 — 광원 | 어디든 | lit · unlit · broken |  | lit |
| 벽 횃불 | `torch_wall` |  | light · wall_decal | `light.webp` | 97×102 (1.5×1.6) | 빛을 내는 것 — 광원 | 어디든 | lit · stub · unlit |  | lit |
| 샹들리에 | `chandelier` |  | light · over | `light.webp` | 83×116 (1.3×1.8) | 빛을 내는 것 — 광원 | 어디든 | lit · unlit |  | lit |
| 벽난로 | `fireplace` |  | light · stand | `light.webp` | 180×209 (2.8×3.3) | 빛을 내는 것 — 이동 방해 · 상호작용(fire) · 광원 | 어디든 | lit · dying · cold | ○ | dying · lit |

## 대장간 — 32종

| 에셋 이름 | id | 새 | 분류 · 층 | 묶음 파일 | 크기 px(칸) | 사용 목적 | 다시 쓸 곳 | 변형 | 충돌 | 애니 |
|---|---|---|---|---|---|---|---|---|---|---|
| 대장간 화덕 | `forge` | 새 | smithy · stand | `smithy.webp` | 196×240 (3.1×3.8) | 대장간의 정체성 — 불 · 쇠 · 연장 — 이동 방해 · 상호작용(fire) · 광원 | 대장간 · 광산 막사 · 야영지 작업장 · 성채 병기고 | lit · embers · cold | ○ | embers · lit |
| 풀무 | `bellows` | 새 | smithy · stand | `smithy.webp` | 167×129 (2.6×2.0) | 대장간의 정체성 — 불 · 쇠 · 연장 — 이동 방해 · 상호작용(lever) | 대장간 · 광산 막사 · 야영지 작업장 · 성채 병기고 | idle · compressed · torn | ○ |  |
| 담금질 통 | `quench_tub` | 새 | smithy · stand | `smithy.webp` | 120×74 (1.9×1.2) | 대장간의 정체성 — 불 · 쇠 · 연장 — 이동 방해 | 대장간 · 광산 막사 · 야영지 작업장 · 성채 병기고 | still · steam · dry | ○ | steam |
| 벽 연장걸이 | `tool_rack_wall` | 새 | smithy · wall_decal | `smithy.webp` | 106×15 (1.7×0.2) | 대장간의 정체성 — 불 · 쇠 · 연장 — 벽 장식 | 대장간 · 광산 막사 · 야영지 작업장 · 성채 병기고 | empty · full · sparse |  |  |
| 망치와 집게 | `smith_tools` | 새 | smithy · stand | `smithy.webp` | 96×59 (1.5×0.9) | 대장간의 정체성 — 불 · 쇠 · 연장 — 광원 | 대장간 · 광산 막사 · 야영지 작업장 · 성채 병기고 | block · hot_iron · scattered |  |  |
| 기둥 바이스 | `post_vise` | 새 | smithy · stand | `smithy.webp` | 84×95 (1.3×1.5) | 대장간의 정체성 — 불 · 쇠 · 연장 — 이동 방해 | 대장간 · 광산 막사 · 야영지 작업장 · 성채 병기고 | work · base | ○ |  |
| 금속 주괴 | `ingots` | 새 | smithy · stand | `smithy.webp` | 54×40 (0.8×0.6) | 대장간의 정체성 — 불 · 쇠 · 연장 — 이동 방해 · 상호작용(container) | 대장간 · 광산 막사 · 야영지 작업장 · 성채 병기고 | iron_stack · copper_pallet · steel_bars · loose | ○ |  |
| 철광석 | `iron_ore` | 새 | smithy · stand | `smithy.webp` | 96×61 (1.5×0.9) | 대장간의 정체성 — 불 · 쇠 · 연장 — 이동 방해 · 상호작용(container) | 대장간 · 광산 막사 · 야영지 작업장 · 성채 병기고 | pile · sacks · crate | ○ |  |
| 석탄 더미 | `coal_pile` | 새 | smithy · stand | `smithy.webp` | 115×65 (1.8×1.0) | 대장간의 정체성 — 불 · 쇠 · 연장 — 이동 방해 | 대장간 · 광산 막사 · 야영지 작업장 · 성채 병기고 | pile · shovel · bin | ○ |  |
| 장작 | `firewood` | 새 | smithy · stand | `smithy.webp` | 147×81 (2.3×1.3) | 대장간의 정체성 — 불 · 쇠 · 연장 — 이동 방해 | 대장간 · 광산 막사 · 야영지 작업장 · 성채 병기고 | cord · pile · block | ○ |  |
| 방패 거치대 | `shield_rack` | 새 | smithy · stand | `smithy.webp` | 156×79 (2.4×1.2) | 대장간의 정체성 — 불 · 쇠 · 연장 — 이동 방해 · 상호작용(container) | 대장간 · 광산 막사 · 야영지 작업장 · 성채 병기고 | empty · half · full | ○ |  |
| 검 진열대 | `sword_display` | 새 | smithy · wall_decal | `smithy.webp` | 104×67 (1.6×1.1) | 대장간의 정체성 — 불 · 쇠 · 연장 — 상호작용(container) | 대장간 · 광산 막사 · 야영지 작업장 · 성채 병기고 | sparse · full · empty |  |  |
| 도끼 진열대 | `axe_display` | 새 | smithy · stand | `smithy.webp` | 143×100 (2.2×1.6) | 대장간의 정체성 — 불 · 쇠 · 연장 — 이동 방해 · 상호작용(container) | 대장간 · 광산 막사 · 야영지 작업장 · 성채 병기고 | full · sparse · empty | ○ |  |
| 창 진열대 | `spear_display` | 새 | smithy · stand | `smithy.webp` | 95×169 (1.5×2.6) | 대장간의 정체성 — 불 · 쇠 · 연장 — 이동 방해 · 상호작용(container) | 대장간 · 광산 막사 · 야영지 작업장 · 성채 병기고 | full · empty · sparse | ○ |  |
| 도가니 | `crucible` | 새 | smithy · stand | `smithy.webp` | 75×63 (1.2×1.0) | 대장간의 정체성 — 불 · 쇠 · 연장 — 이동 방해 · 광원 | 대장간 · 광산 막사 · 야영지 작업장 · 성채 병기고 | molten · cold · spilled | ○ | molten |
| 주물 틀 | `casting_mold` | 새 | smithy · stand | `smithy.webp` | 60×37 (0.9×0.6) | 대장간의 정체성 — 불 · 쇠 · 연장 — 이동 방해 · 광원 | 대장간 · 광산 막사 · 야영지 작업장 · 성채 병기고 | empty · stack · poured | ○ |  |
| 편자와 못 | `ironware_heap` | 새 | smithy · stand | `smithy.webp` | 47×35 (0.7×0.6) | 대장간의 정체성 — 불 · 쇠 · 연장 — 장식 | 대장간 · 광산 막사 · 야영지 작업장 · 성채 병기고 | horseshoes · nail_keg · chains |  |  |
| 벼리다 만 칼날 | `blade_blanks` | 새 | smithy · stand | `smithy.webp` | 88×27 (1.4×0.4) | 대장간의 정체성 — 불 · 쇠 · 연장 — 이동 방해 | 대장간 · 광산 막사 · 야영지 작업장 · 성채 병기고 | bundle · bucket | ○ |  |
| 벽에 건 편자와 사슬 | `smithy_wall_hang` | 새 | smithy · wall_decal | `smithy.webp` | 60×21 (0.9×0.3) | 대장간의 정체성 — 불 · 쇠 · 연장 — 벽 장식 | 대장간 · 광산 막사 · 야영지 작업장 · 성채 병기고 | horseshoes · chains · apron |  |  |
| 물 양동이 | `water_bucket` | 새 | smithy · stand | `smithy.webp` | 62×49 (1.0×0.8) | 대장간의 정체성 — 불 · 쇠 · 연장 — 이동 방해 | 대장간 · 광산 막사 · 야영지 작업장 · 성채 병기고 | full · empty · toppled | ○ |  |
| 벽 그을음 | `wall_soot` | 새 | smithy · wall_decal | `smithy.webp` | 128×152 (2.0×2.4) | 대장간의 정체성 — 불 · 쇠 · 연장 — 벽 장식 | 대장간 · 광산 막사 · 야영지 작업장 · 성채 병기고 | heavy · streak · plume |  |  |
| 대장간 불티 | `forge_sparks` | 새 | smithy · over | `smithy.webp` | 28×25 (0.4×0.4) | 대장간의 정체성 — 불 · 쇠 · 연장 — 머리 위 전경 | 대장간 · 광산 막사 · 야영지 작업장 · 성채 병기고 | hammer · rising |  | hammer · rising |
| 대장간 연기 | `forge_smoke` | 새 | smithy · over | `smithy.webp` | 27×129 (0.4×2.0) | 대장간의 정체성 — 불 · 쇠 · 연장 — 머리 위 전경 | 대장간 · 광산 막사 · 야영지 작업장 · 성채 병기고 | thin · thick |  | thick · thin |
| 모루 | `anvil` |  | furniture · stand | `furniture.webp` | 83×61 (1.3×0.9) | 가구 · 생활 물건 — 이동 방해 | 실내 어디든 | base · hammer | ○ |  |
| 작업대 | `workbench` |  | furniture · stand | `furniture.webp` | 159×83 (2.5×1.3) | 가구 · 생활 물건 — 이동 방해 | 실내 어디든 | tools · empty | ○ |  |
| 숫돌 바퀴 | `grindstone` |  | furniture · stand | `furniture.webp` | 94×65 (1.5×1.0) | 가구 · 생활 물건 — 이동 방해 | 실내 어디든 | base | ○ |  |
| 연장통 | `toolbox` |  | furniture · stand | `furniture.webp` | 76×41 (1.2×0.6) | 가구 · 생활 물건 — 상호작용(container) | 실내 어디든 | full · empty |  |  |
| 무기 거치대 | `weapon_rack` |  | furniture · stand | `furniture.webp` | 152×138 (2.4×2.2) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | full · half · broken · empty | ○ |  |
| 갑옷 거치대 | `armor_stand` |  | furniture · stand | `furniture.webp` | 99×117 (1.6×1.8) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | armor · empty · fallen | ○ |  |
| 그을음 | `scorch` |  | trace · decal | `trace.webp` | 88×97 (1.4×1.5) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 바닥 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | a · b · blast |  |  |
| 화로 | `brazier` |  | light · stand | `light.webp` | 107×129 (1.7×2.0) | 빛을 내는 것 — 이동 방해 · 광원 | 어디든 | lit · embers · cold · toppled | ○ | embers · lit |
| 나무통 | `barrel` |  | furniture · stand | `furniture.webp` | 98×83 (1.5×1.3) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | intact · broken · toppled · water · stack | ○ |  |

## 여관 — 27종

| 에셋 이름 | id | 새 | 분류 · 층 | 묶음 파일 | 크기 px(칸) | 사용 목적 | 다시 쓸 곳 | 변형 | 충돌 | 애니 |
|---|---|---|---|---|---|---|---|---|---|---|
| 여관 카운터 | `inn_bar` | 새 | inn · stand | `inn.webp` | 208×87 (3.2×1.4) | 여관의 정체성 — 술 · 부엌 · 잠자리 — 이동 방해 · 상호작용(counter) | 여관 · 선술집 · 일반 집 부엌 · 성채 식당 | straight · taps · corner · mugs | ○ |  |
| 꼭지 단 술통 | `inn_keg` | 새 | inn · stand | `inn.webp` | 83×56 (1.3×0.9) | 여관의 정체성 — 술 · 부엌 · 잠자리 — 이동 방해 · 상호작용(container) | 여관 · 선술집 · 일반 집 부엌 · 성채 식당 | tapped · plain · drip | ○ |  |
| 술통 거치대 | `keg_rack` | 새 | inn · stand | `inn.webp` | 147×108 (2.3×1.7) | 여관의 정체성 — 술 · 부엌 · 잠자리 — 이동 방해 · 상호작용(container) | 여관 · 선술집 · 일반 집 부엌 · 성채 식당 | empty · full · tapped | ○ |  |
| 주방 작업대 | `kitchen_table` | 새 | inn · stand | `inn.webp` | 150×79 (2.3×1.2) | 여관의 정체성 — 술 · 부엌 · 잠자리 — 이동 방해 | 여관 · 선술집 · 일반 집 부엌 · 성채 식당 | clean · messy | ○ |  |
| 식기 선반 | `dish_hutch` | 새 | inn · stand | `inn.webp` | 145×139 (2.3×2.2) | 여관의 정체성 — 술 · 부엌 · 잠자리 — 이동 방해 · 상호작용(container) | 여관 · 선술집 · 일반 집 부엌 · 성채 식당 | broken · full · sparse | ○ |  |
| 꼬치 굽는 화덕 | `spit_hearth` | 새 | inn · stand | `inn.webp` | 170×115 (2.7×1.8) | 여관의 정체성 — 술 · 부엌 · 잠자리 — 이동 방해 · 상호작용(fire) · 광원 | 여관 · 선술집 · 일반 집 부엌 · 성채 식당 | lit · cold | ○ | lit |
| 음식이 놓인 테이블 | `tavern_table` | 새 | inn · stand | `inn.webp` | 106×82 (1.7×1.3) | 여관의 정체성 — 술 · 부엌 · 잠자리 — 이동 방해 · 광원 | 여관 · 선술집 · 일반 집 부엌 · 성채 식당 | meal · after · candle | ○ | candle |
| 침구 더미 | `bedding` | 새 | inn · stand | `inn.webp` | 78×55 (1.2×0.9) | 여관의 정체성 — 술 · 부엌 · 잠자리 — 이동 방해 | 여관 · 선술집 · 일반 집 부엌 · 성채 식당 | stack · pillows | ○ |  |
| 열쇠 걸이 판 | `key_rack` | 새 | inn · wall_decal | `inn.webp` | 50×33 (0.8×0.5) | 여관의 정체성 — 술 · 부엌 · 잠자리 — 벽 장식 | 여관 · 선술집 · 일반 집 부엌 · 성채 식당 | full · few |  |  |
| 담요 | `blanket` | 새 | inn · stand | `inn.webp` | 99×52 (1.6×0.8) | 여관의 정체성 — 술 · 부엌 · 잠자리 — 장식 | 여관 · 선술집 · 일반 집 부엌 · 성채 식당 | crumpled · draped · folded |  |  |
| 외투 걸이 | `coat_pegs` | 새 | inn · wall_decal | `inn.webp` | 74×68 (1.2×1.1) | 여관의 정체성 — 술 · 부엌 · 잠자리 — 벽 장식 | 여관 · 선술집 · 일반 집 부엌 · 성채 식당 | cloaks · empty · hats |  |  |
| 걸어 둔 부엌살림 | `kitchen_hangings` | 새 | inn · wall_decal | `inn.webp` | 76×38 (1.2×0.6) | 여관의 정체성 — 술 · 부엌 · 잠자리 — 벽 장식 | 여관 · 선술집 · 일반 집 부엌 · 성채 식당 | sausages · pots · onions |  |  |
| 세면대 | `washstand` | 새 | inn · stand | `inn.webp` | 106×82 (1.7×1.3) | 여관의 정체성 — 술 · 부엌 · 잠자리 — 이동 방해 | 여관 · 선술집 · 일반 집 부엌 · 성채 식당 | used · jug | ○ |  |
| 술병 선반 | `wine_rack` | 새 | inn · stand | `inn.webp` | 142×108 (2.2×1.7) | 여관의 정체성 — 술 · 부엌 · 잠자리 — 이동 방해 · 상호작용(container) | 여관 · 선술집 · 일반 집 부엌 · 성채 식당 | full · half | ○ |  |
| 탁자 | `table` |  | furniture · stand | `furniture.webp` | 151×86 (2.4×1.3) | 가구 · 생활 물건 — 이동 방해 | 실내 어디든 | intact · set · toppled · broken | ○ |  |
| 의자 | `chair` |  | furniture · stand | `furniture.webp` | 89×80 (1.4×1.2) | 가구 · 생활 물건 — 이동 방해 | 실내 어디든 | s · e · w · n · toppled · broken | ○ |  |
| 긴 의자 | `bench` |  | furniture · stand | `furniture.webp` | 125×45 (1.9×0.7) | 가구 · 생활 물건 — 이동 방해 | 실내 어디든 | base · broken | ○ |  |
| 걸상 | `stool` |  | furniture · stand | `furniture.webp` | 59×44 (0.9×0.7) | 가구 · 생활 물건 — 이동 방해 | 실내 어디든 | base · toppled | ○ |  |
| 침대 | `bed` |  | furniture · stand | `furniture.webp` | 160×98 (2.5×1.5) | 가구 · 생활 물건 — 이동 방해 | 실내 어디든 | made · messy · bare · broken | ○ |  |
| 벽난로 | `fireplace` |  | light · stand | `light.webp` | 180×209 (2.8×3.3) | 빛을 내는 것 — 이동 방해 · 상호작용(fire) · 광원 | 어디든 | lit · dying · cold | ○ | dying · lit |
| 솥 | `cooking_pot` |  | furniture · stand | `furniture.webp` | 98×88 (1.5×1.4) | 가구 · 생활 물건 — 이동 방해 | 실내 어디든 | cold · ground · stew | ○ |  |
| 식기 | `dishes` |  | furniture · stand | `furniture.webp` | 55×28 (0.9×0.4) | 가구 · 생활 물건 — 장식 | 실내 어디든 | set · bowls · dirty |  |  |
| 병 | `bottles` |  | furniture · stand | `furniture.webp` | 51×37 (0.8×0.6) | 가구 · 생활 물건 — 장식 | 실내 어디든 | group · potion_red · potion_blue · fallen · wine |  |  |
| 나무통 | `barrel` |  | furniture · stand | `furniture.webp` | 98×83 (1.5×1.3) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | intact · broken · toppled · water · stack | ○ |  |
| 촛대 | `candlestick` |  | light · stand | `light.webp` | 87×116 (1.4×1.8) | 빛을 내는 것 — 이동 방해 · 광원 | 어디든 | lit · unlit | ○ | lit |
| 샹들리에 | `chandelier` |  | light · over | `light.webp` | 83×116 (1.3×1.8) | 빛을 내는 것 — 광원 | 어디든 | lit · unlit |  | lit |
| 깔개 | `carpet` |  | furniture · decal | `furniture.webp` | 200×124 (3.1×1.9) | 가구 · 생활 물건 — 바닥 장식 | 실내 어디든 | blue · red · green · round · worn · torn |  |  |

## 신전 — 33종

| 에셋 이름 | id | 새 | 분류 · 층 | 묶음 파일 | 크기 px(칸) | 사용 목적 | 다시 쓸 곳 | 변형 | 충돌 | 애니 |
|---|---|---|---|---|---|---|---|---|---|---|
| 신전 제단 | `shrine_altar` | 새 | shrine · stand | `shrine.webp` | 194×106 (3.0×1.7) | 신전의 정체성 — 제단 · 봉헌 · 기도 — 이동 방해 · 상호작용(altar) · 광원 | 신전 · 묘지 예배실 · 미궁 안 버려진 성소 | plain · lit · dressed · festival | ○ | festival · lit |
| 제단 단(세 단 계단) | `shrine_dais` | 새 | shrine · decal | `shrine.webp` | 164×90 (2.6×1.4) | 신전의 정체성 — 제단 · 봉헌 · 기도 — 바닥 장식 | 신전 · 묘지 예배실 · 미궁 안 버려진 성소 | straight · runner · corner · end |  |  |
| 봉헌상(그릇을 받쳐 든 석상) | `shrine_statue` | 새 | shrine · stand | `shrine.webp` | 130×188 (2.0×2.9) | 신전의 정체성 — 제단 · 봉헌 · 기도 — 이동 방해 · 상호작용(examine) · 광원 | 신전 · 묘지 예배실 · 미궁 안 버려진 성소 | plain · offerings · lamp | ○ | lamp |
| 작은 석상(받침 위) | `shrine_statuette` | 새 | shrine · stand | `shrine.webp` | 89×120 (1.4×1.9) | 신전의 정체성 — 제단 · 봉헌 · 기도 — 이동 방해 | 신전 · 묘지 예배실 · 미궁 안 버려진 성소 | single · pair · gilded | ○ |  |
| 기도대 | `prayer_kneeler` | 새 | shrine · stand | `shrine.webp` | 98×91 (1.5×1.4) | 신전의 정체성 — 제단 · 봉헌 · 기도 — 이동 방해 · 상호작용(pray) | 신전 · 묘지 예배실 · 미궁 안 버려진 성소 | plain · cushion · book | ○ |  |
| 신도석 | `pew` | 새 | shrine · stand | `shrine.webp` | 196×78 (3.1×1.2) | 신전의 정체성 — 제단 · 봉헌 · 기도 — 이동 방해 · 상호작용(sit) | 신전 · 묘지 예배실 · 미궁 안 버려진 성소 | facing_n · facing_s · books · short | ○ |  |
| 성물함 | `reliquary` | 새 | shrine · stand | `shrine.webp` | 96×93 (1.5×1.4) | 신전의 정체성 — 제단 · 봉헌 · 기도 — 이동 방해 · 상호작용(examine) · 광원 | 신전 · 묘지 예배실 · 미궁 안 버려진 성소 | closed · open · grille | ○ | open |
| 신도석(옆으로 놓인) | `pew_side` | 새 | shrine · stand | `shrine.webp` | 108×154 (1.7×2.4) | 신전의 정체성 — 제단 · 봉헌 · 기도 — 이동 방해 · 상호작용(sit) | 신전 · 묘지 예배실 · 미궁 안 버려진 성소 | facing_w · facing_e | ○ |  |
| 성배 받침 | `chalice_stand` | 새 | shrine · stand | `shrine.webp` | 90×83 (1.4×1.3) | 신전의 정체성 — 제단 · 봉헌 · 기도 — 이동 방해 | 신전 · 묘지 예배실 · 미궁 안 버려진 성소 | single · set · empty | ○ |  |
| 독경대 | `lectern` | 새 | shrine · stand | `shrine.webp` | 91×92 (1.4×1.4) | 신전의 정체성 — 제단 · 봉헌 · 기도 — 이동 방해 · 상호작용(read) | 신전 · 묘지 예배실 · 미궁 안 버려진 성소 | open · closed · empty | ○ |  |
| 헌금함 | `offering_box` | 새 | shrine · stand | `shrine.webp` | 89×60 (1.4×0.9) | 신전의 정체성 — 제단 · 봉헌 · 기도 — 이동 방해 · 상호작용(offer) | 신전 · 묘지 예배실 · 미궁 안 버려진 성소 | open · chest · post | ○ |  |
| 기도서 | `prayer_books` | 새 | shrine · stand | `shrine.webp` | 72×35 (1.1×0.6) | 신전의 정체성 — 제단 · 봉헌 · 기도 — 상호작용(read) | 신전 · 묘지 예배실 · 미궁 안 버려진 성소 | row · stack · open |  |  |
| 세운 향로 | `censer` | 새 | shrine · stand | `shrine.webp` | 80×121 (1.2×1.9) | 신전의 정체성 — 제단 · 봉헌 · 기도 — 이동 방해 | 신전 · 묘지 예배실 · 미궁 안 버려진 성소 | smoking · cold | ○ | smoking |
| 매단 향로 | `censer_hanging` | 새 | shrine · over | `shrine.webp` | 24×77 (0.4×1.2) | 신전의 정체성 — 제단 · 봉헌 · 기도 — 머리 위 전경 | 신전 · 묘지 예배실 · 미궁 안 버려진 성소 | smoking · cold |  | smoking |
| 봉헌 촛대 | `votive_rack` | 새 | shrine · stand | `shrine.webp` | 134×96 (2.1×1.5) | 신전의 정체성 — 제단 · 봉헌 · 기도 — 이동 방해 · 광원 | 신전 · 묘지 예배실 · 미궁 안 버려진 성소 | lit · half · out | ○ | half · lit |
| 색유리 창 | `stained_glass` | 새 | shrine · wall_decal | `shrine.webp` | 60×124 (0.9×1.9) | 신전의 정체성 — 제단 · 봉헌 · 기도 — 광원 | 신전 · 묘지 예배실 · 미궁 안 버려진 성소 | dim · pair · pair_glowing · glowing |  |  |
| 둥근 장미창 | `rose_window` | 새 | shrine · wall_decal | `shrine.webp` | 100×100 (1.6×1.6) | 신전의 정체성 — 제단 · 봉헌 · 기도 — 광원 | 신전 · 묘지 예배실 · 미궁 안 버려진 성소 | dim · glowing |  |  |
| 벽감 | `wall_niche` | 새 | shrine · wall_decal | `shrine.webp` | 46×67 (0.7×1.1) | 신전의 정체성 — 제단 · 봉헌 · 기도 — 광원 | 신전 · 묘지 예배실 · 미궁 안 버려진 성소 | candle · vessel · empty |  | candle |
| 신전 벽 장식 | `shrine_wall_panel` | 새 | shrine · wall_decal | `shrine.webp` | 79×80 (1.2×1.2) | 신전의 정체성 — 제단 · 봉헌 · 기도 — 벽 장식 | 신전 · 묘지 예배실 · 미궁 안 버려진 성소 | arcade · plaque · stoup |  |  |
| 신전 장식 기둥 | `temple_column` | 새 | shrine · stand | `shrine.webp` | 94×196 (1.5×3.1) | 신전의 정체성 — 제단 · 봉헌 · 기도 — 이동 방해 | 신전 · 묘지 예배실 · 미궁 안 버려진 성소 | clustered · fluted · banner | ○ |  |
| 봉헌물 | `offerings` | 새 | shrine · stand | `shrine.webp` | 58×31 (0.9×0.5) | 신전의 정체성 — 제단 · 봉헌 · 기도 — 광원 | 신전 · 묘지 예배실 · 미궁 안 버려진 성소 | flowers · candles · fruit · coins · cloth |  | candles |
| 성수반 | `temple_font` | 새 | shrine · stand | `shrine.webp` | 94×86 (1.5×1.3) | 신전의 정체성 — 제단 · 봉헌 · 기도 — 이동 방해 · 상호작용(examine) | 신전 · 묘지 예배실 · 미궁 안 버려진 성소 | water · dry | ○ | water |
| 신전 종 | `temple_bell` | 새 | shrine · stand | `shrine.webp` | 69×143 (1.1×2.2) | 신전의 정체성 — 제단 · 봉헌 · 기도 — 이동 방해 · 상호작용(examine) | 신전 · 묘지 예배실 · 미궁 안 버려진 성소 | rope · frame | ○ |  |
| 제단 | `altar` |  | structure · stand | `structure.webp` | 198×112 (3.1×1.8) | 이동을 막는 큰 구조물 — 이동 방해 · 상호작용(altar) | 미궁 · 도시 | plain · bloody · ritual · broken | ○ | ritual |
| 석상 | `statue` |  | structure · stand | `structure.webp` | 124×186 (1.9×2.9) | 이동을 막는 큰 구조물 — 이동 방해 | 미궁 · 도시 | intact · mossy · headless · broken · ruined | ○ |  |
| 두건 쓴 석상 | `statue_robed` |  | structure · stand | `structure.webp` | 125×177 (1.9×2.8) | 이동을 막는 큰 구조물 — 이동 방해 | 미궁 · 도시 | intact · weeping | ○ |  |
| 받침대 | `pedestal` |  | structure · stand | `structure.webp` | 97×101 (1.5×1.6) | 이동을 막는 큰 구조물 — 이동 방해 · 상호작용(pedestal) · 광원 | 미궁 · 도시 | empty · orb_red · broken · idol · orb | ○ |  |
| 흰 대리석 기둥 | `pillar_white` |  | structure · stand | `structure.webp` | 121×231 (1.9×3.6) | 이동을 막는 큰 구조물 — 이동 방해 · 광원 | 미궁 · 도시 | intact · cracked · glowing · broken · sunken | ○ | glowing |
| 촛대 | `candlestick` |  | light · stand | `light.webp` | 87×116 (1.4×1.8) | 빛을 내는 것 — 이동 방해 · 광원 | 어디든 | lit · unlit | ○ | lit |
| 세 갈래 촛대 | `candelabra` |  | light · stand | `light.webp` | 97×133 (1.5×2.1) | 빛을 내는 것 — 이동 방해 · 광원 | 어디든 | lit · unlit | ○ | lit |
| 양초 무더기 | `candles` |  | light · stand | `light.webp` | 78×69 (1.2×1.1) | 빛을 내는 것 — 광원 | 어디든 | lit · unlit · stubs |  | lit |
| 깔개 | `carpet` |  | furniture · decal | `furniture.webp` | 200×124 (3.1×1.9) | 가구 · 생활 물건 — 바닥 장식 | 실내 어디든 | blue · red · green · round · worn · torn |  |  |
| 책 | `books` |  | furniture · stand | `furniture.webp` | 50×34 (0.8×0.5) | 가구 · 생활 물건 — 장식 | 실내 어디든 | open · stack · scattered · tall |  |  |

## 상점 — 32종

| 에셋 이름 | id | 새 | 분류 · 층 | 묶음 파일 | 크기 px(칸) | 사용 목적 | 다시 쓸 곳 | 변형 | 충돌 | 애니 |
|---|---|---|---|---|---|---|---|---|---|---|
| 상점 카운터 | `shop_counter` | 새 | shop · stand | `shop.webp` | 166×86 (2.6×1.3) | 상점의 정체성 — 진열 · 계산 — 이동 방해 · 상호작용(counter) | 잡화점 · 시장 좌판 · 떠돌이 상인 · 창고 | busy · closed · tidy | ○ |  |
| 계단식 상품 진열대 | `goods_stand` | 새 | shop · stand | `shop.webp` | 145×108 (2.3×1.7) | 상점의 정체성 — 진열 · 계산 — 이동 방해 · 상호작용(container) | 잡화점 · 시장 좌판 · 떠돌이 상인 · 창고 | food · potions · empty · mixed | ○ |  |
| 상품 선반 | `goods_shelf` | 새 | shop · stand | `shop.webp` | 151×139 (2.4×2.2) | 상점의 정체성 — 진열 · 계산 — 이동 방해 · 상호작용(container) | 잡화점 · 시장 좌판 · 떠돌이 상인 · 창고 | provisions · potions · sparse · empty · hardware | ○ |  |
| 약재 서랍장 | `apothecary_drawers` | 새 | shop · stand | `shop.webp` | 142×111 (2.2×1.7) | 상점의 정체성 — 진열 · 계산 — 이동 방해 · 상호작용(container) | 잡화점 · 시장 좌판 · 떠돌이 상인 · 창고 | closed · open · mortar | ○ |  |
| 상품 상자 | `goods_crate` | 새 | shop · stand | `shop.webp` | 71×59 (1.1×0.9) | 상점의 정체성 — 진열 · 계산 — 이동 방해 · 상호작용(container) | 잡화점 · 시장 좌판 · 떠돌이 상인 · 창고 | produce · bottles · herbs · candles | ○ |  |
| 빵과 치즈 판매대 | `bread_board` | 새 | shop · stand | `shop.webp` | 117×65 (1.8×1.0) | 상점의 정체성 — 진열 · 계산 — 이동 방해 | 잡화점 · 시장 좌판 · 떠돌이 상인 · 창고 | full · picked | ○ |  |
| 말린 고기 걸이 | `meat_rail` | 새 | shop · stand | `shop.webp` | 150×119 (2.3×1.9) | 상점의 정체성 — 진열 · 계산 — 이동 방해 | 잡화점 · 시장 좌판 · 떠돌이 상인 · 창고 | empty · few · full | ○ |  |
| 곡물 통 | `grain_bin` | 새 | shop · stand | `shop.webp` | 124×68 (1.9×1.1) | 상점의 정체성 — 진열 · 계산 — 이동 방해 · 상호작용(container) | 잡화점 · 시장 좌판 · 떠돌이 상인 · 창고 | full · low · lidded | ○ |  |
| 물약 꽂이 | `potion_rack` | 새 | shop · stand | `shop.webp` | 99×63 (1.6×1.0) | 상점의 정체성 — 진열 · 계산 — 이동 방해 · 상호작용(container) | 잡화점 · 시장 좌판 · 떠돌이 상인 · 창고 | tidy · half_sold · empty | ○ |  |
| 매단 약초 다발 | `herb_bundles` | 새 | shop · wall_decal | `shop.webp` | 86×37 (1.3×0.6) | 상점의 정체성 — 진열 · 계산 — 벽 장식 | 잡화점 · 시장 좌판 · 떠돌이 상인 · 창고 | full · mixed · sparse |  |  |
| 약초 쟁반 | `herb_tray` | 새 | shop · stand | `shop.webp` | 82×56 (1.3×0.9) | 상점의 정체성 — 진열 · 계산 — 이동 방해 · 상호작용(container) | 잡화점 · 시장 좌판 · 떠돌이 상인 · 창고 | sorted · fresh · dried | ○ |  |
| 걸어 둔 가방과 주머니 | `hanging_bags` | 새 | shop · wall_decal | `shop.webp` | 92×51 (1.4×0.8) | 상점의 정체성 — 진열 · 계산 — 벽 장식 | 잡화점 · 시장 좌판 · 떠돌이 상인 · 창고 | full · few |  |  |
| 밧줄 타래 | `rope_coil` | 새 | shop · stand | `shop.webp` | 60×39 (0.9×0.6) | 상점의 정체성 — 진열 · 계산 — 장식 | 잡화점 · 시장 좌판 · 떠돌이 상인 · 창고 | single · stack · spool |  |  |
| 연장 묶음 | `tool_bundle` | 새 | shop · stand | `shop.webp` | 92×109 (1.4×1.7) | 상점의 정체성 — 진열 · 계산 — 이동 방해 · 상호작용(container) | 잡화점 · 시장 좌판 · 떠돌이 상인 · 창고 | barrel · leaning | ○ |  |
| 연장 걸이판 | `tool_board` | 새 | shop · wall_decal | `shop.webp` | 91×55 (1.4×0.9) | 상점의 정체성 — 진열 · 계산 — 벽 장식 | 잡화점 · 시장 좌판 · 떠돌이 상인 · 창고 | gaps · full |  |  |
| 탐험 장비 진열대 | `gear_table` | 새 | shop · stand | `shop.webp` | 146×84 (2.3×1.3) | 상점의 정체성 — 진열 · 계산 — 이동 방해 · 상호작용(container) | 잡화점 · 시장 좌판 · 떠돌이 상인 · 창고 | full · picked | ○ |  |
| 횃불 통 | `torch_bin` | 새 | shop · stand | `shop.webp` | 91×90 (1.4×1.4) | 상점의 정체성 — 진열 · 계산 — 이동 방해 · 상호작용(container) | 잡화점 · 시장 좌판 · 떠돌이 상인 · 창고 | full · few | ○ |  |
| 양팔저울 | `scale` | 새 | shop · stand | `shop.webp` | 87×50 (1.4×0.8) | 상점의 정체성 — 진열 · 계산 — 장식 | 잡화점 · 시장 좌판 · 떠돌이 상인 · 창고 | level · weights · coins |  |  |
| 장부 | `ledger` | 새 | shop · stand | `shop.webp` | 53×35 (0.8×0.6) | 상점의 정체성 — 진열 · 계산 — 상호작용(read) | 잡화점 · 시장 좌판 · 떠돌이 상인 · 창고 | closed · open · stack |  |  |
| 돈통 | `coin_box` | 새 | shop · stand | `shop.webp` | 52×32 (0.8×0.5) | 상점의 정체성 — 진열 · 계산 — 상호작용(container) | 잡화점 · 시장 좌판 · 떠돌이 상인 · 창고 | closed · open |  |  |
| 포장한 꾸러미 | `parcels` | 새 | shop · stand | `shop.webp` | 48×33 (0.8×0.5) | 상점의 정체성 — 진열 · 계산 — 장식 | 잡화점 · 시장 좌판 · 떠돌이 상인 · 창고 | single · cloth · stack |  |  |
| 가격표와 상품 라벨 | `price_tags` | 새 | shop · wall_decal | `shop.webp` | 40×43 (0.6×0.7) | 상점의 정체성 — 진열 · 계산 — 벽 장식 | 잡화점 · 시장 좌판 · 떠돌이 상인 · 창고 | tag · tags_row · label_strip · chalk_board · chalk_board_worn |  |  |
| 나무 상자 | `crate` |  | furniture · stand | `furniture.webp` | 94×76 (1.5×1.2) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | intact · open · broken · stack | ○ |  |
| 나무통 | `barrel` |  | furniture · stand | `furniture.webp` | 98×83 (1.5×1.3) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | intact · broken · toppled · water · stack | ○ |  |
| 자루 | `sack` |  | furniture · stand | `furniture.webp` | 70×40 (1.1×0.6) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | slumped · full · open · pile | ○ |  |
| 바구니 | `basket` |  | furniture · stand | `furniture.webp` | 63×49 (1.0×0.8) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | empty · food · toppled | ○ |  |
| 병 | `bottles` |  | furniture · stand | `furniture.webp` | 51×37 (0.8×0.6) | 가구 · 생활 물건 — 장식 | 실내 어디든 | group · potion_red · potion_blue · fallen · wine |  |  |
| 배낭 | `backpack` |  | furniture · stand | `furniture.webp` | 83×55 (1.3×0.9) | 가구 · 생활 물건 — 상호작용(container) | 실내 어디든 | standing · opened |  |  |
| 랜턴 | `lantern` |  | light · stand | `light.webp` | 85×67 (1.3×1.1) | 빛을 내는 것 — 광원 | 어디든 | lit · unlit · broken |  | lit |
| 벽 선반 | `wall_shelf` |  | furniture · wall_decal | `furniture.webp` | 82×30 (1.3×0.5) | 가구 · 생활 물건 — 벽 장식 | 실내 어디든 | bottles · empty · skull · books |  |  |
| 보급품 더미 | `supply_pile` |  | furniture · stand | `furniture.webp` | 121×96 (1.9×1.5) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | a · b | ○ |  |
| 연장통 | `toolbox` |  | furniture · stand | `furniture.webp` | 76×41 (1.2×0.6) | 가구 · 생활 물건 — 상호작용(container) | 실내 어디든 | full · empty |  |  |

## 은행 — 25종

| 에셋 이름 | id | 새 | 분류 · 층 | 묶음 파일 | 크기 px(칸) | 사용 목적 | 다시 쓸 곳 | 변형 | 충돌 | 애니 |
|---|---|---|---|---|---|---|---|---|---|---|
| 은행 접수대 | `teller_counter` | 새 | bank · stand | `bank.webp` | 193×119 (3.0×1.9) | 은행의 정체성 — 금고 · 창살 · 서류 — 이동 방해 · 상호작용(counter) | 은행 · 길드 금고실 · 성채 보물고 · 세금 창구 | open · closed · plain · end | ○ |  |
| 금고 문 | `vault_door` | 새 | bank · wall_decal | `bank.webp` | 189×140 (3.0×2.2) | 은행의 정체성 — 금고 · 창살 · 서류 — 이동 방해 · 상호작용(door) | 은행 · 길드 금고실 · 성채 보물고 · 세금 창구 | closed · ajar · open | ○ |  |
| 소형 금고 | `strongbox` | 새 | bank · stand | `bank.webp` | 65×46 (1.0×0.7) | 은행의 정체성 — 금고 · 창살 · 서류 — 이동 방해 · 상호작용(container) | 은행 · 길드 금고실 · 성채 보물고 · 세금 창구 | closed · pried · open | ○ |  |
| 대형 금고 | `big_safe` | 새 | bank · stand | `bank.webp` | 132×131 (2.1×2.0) | 은행의 정체성 — 금고 · 창살 · 서류 — 이동 방해 · 상호작용(container) | 은행 · 길드 금고실 · 성채 보물고 · 세금 창구 | closed · open | ○ |  |
| 철제 보관함 | `deposit_lockers` | 새 | bank · wall_decal | `bank.webp` | 147×125 (2.3×1.9) | 은행의 정체성 — 금고 · 창살 · 서류 — 이동 방해 · 상호작용(container) | 은행 · 길드 금고실 · 성채 보물고 · 세금 창구 | one_open · looted · closed | ○ |  |
| 금고 잠금장치 | `lock_mechanism` | 새 | bank · stand | `bank.webp` | 63×62 (1.0×1.0) | 은행의 정체성 — 금고 · 창살 · 서류 — 상호작용(lever) | 은행 · 길드 금고실 · 성채 보물고 · 세금 창구 | wall_open · dial · wall_locked |  |  |
| 은행 창살 칸막이 | `bank_grille` | 새 | bank · stand | `bank.webp` | 157×128 (2.5×2.0) | 은행의 정체성 — 금고 · 창살 · 서류 — 이동 방해 | 은행 · 길드 금고실 · 성채 보물고 · 세금 창구 | panel · gate · slot · gate_open | ○ |  |
| 금화 더미 | `coin_piles` | 새 | bank · stand | `bank.webp` | 55×35 (0.9×0.6) | 은행의 정체성 — 금고 · 창살 · 서류 — 장식 | 은행 · 길드 금고실 · 성채 보물고 · 세금 창구 | small · stacks · heap · sack · tray · silver |  |  |
| 보석 보관함 | `gem_case` | 새 | bank · stand | `bank.webp` | 64×38 (1.0×0.6) | 은행의 정체성 — 금고 · 창살 · 서류 — 이동 방해 · 상호작용(container) | 은행 · 길드 금고실 · 성채 보물고 · 세금 창구 | tray · coffer_closed · coffer_open | ○ |  |
| 은행 서류 더미 | `bank_documents` | 새 | bank · stand | `bank.webp` | 144×114 (2.2×1.8) | 은행의 정체성 — 금고 · 창살 · 서류 — 이동 방해 · 상호작용(examine) | 은행 · 길드 금고실 · 성채 보물고 · 세금 창구 | pigeonholes · bundles · stacks | ○ |  |
| 봉인 도구 | `sealing_kit` | 새 | bank · stand | `bank.webp` | 54×34 (0.8×0.5) | 은행의 정체성 — 금고 · 창살 · 서류 — 장식 | 은행 · 길드 금고실 · 성채 보물고 · 세금 창구 | tray · letters |  |  |
| 귀중품 진열장 | `valuables_case` | 새 | bank · stand | `bank.webp` | 127×83 (2.0×1.3) | 은행의 정체성 — 금고 · 창살 · 서류 — 이동 방해 · 상호작용(container) | 은행 · 길드 금고실 · 성채 보물고 · 세금 창구 | full · empty | ○ |  |
| 보안용 철문 | `security_door` | 새 | bank · wall_decal | `bank.webp` | 112×152 (1.8×2.4) | 은행의 정체성 — 금고 · 창살 · 서류 — 이동 방해 · 상호작용(door) | 은행 · 길드 금고실 · 성채 보물고 · 세금 창구 | open · closed | ○ |  |
| 은행 문양 판 | `bank_emblem` | 새 | bank · wall_decal | `bank.webp` | 45×47 (0.7×0.7) | 은행의 정체성 — 금고 · 창살 · 서류 — 벽 장식 | 은행 · 길드 금고실 · 성채 보물고 · 세금 창구 | plaque · worn |  |  |
| 바닥 놋 문양 | `bank_inlay` | 새 | bank · decal | `bank.webp` | 152×110 (2.4×1.7) | 은행의 정체성 — 금고 · 창살 · 서류 — 바닥 장식 | 은행 · 길드 금고실 · 성채 보물고 · 세금 창구 | bright · worn |  |  |
| 줄 세우는 말뚝 | `queue_posts` | 새 | bank · stand | `bank.webp` | 185×75 (2.9×1.2) | 은행의 정체성 — 금고 · 창살 · 서류 — 이동 방해 | 은행 · 길드 금고실 · 성채 보물고 · 세금 창구 | rope · single · down | ○ |  |
| 보물상자 | `chest` |  | furniture · stand | `furniture.webp` | 97×56 (1.5×0.9) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | closed · open · locked · broken · empty | ○ |  |
| 흩어진 문서 | `papers` |  | furniture · decal | `furniture.webp` | 82×44 (1.3×0.7) | 가구 · 생활 물건 — 바닥 장식 | 실내 어디든 | b · a · stack |  |  |
| 책 | `books` |  | furniture · stand | `furniture.webp` | 50×34 (0.8×0.5) | 가구 · 생활 물건 — 장식 | 실내 어디든 | open · stack · scattered · tall |  |  |
| 두루마리 | `scrolls` |  | furniture · stand | `furniture.webp` | 64×40 (1.0×0.6) | 가구 · 생활 물건 — 장식 | 실내 어디든 | pile · open · case |  |  |
| 사슬 자물쇠 | `chained_lock` |  | special · wall_decal | `special.webp` | 80×107 (1.2×1.7) | 살피고 다루는 것 · 마법 장치 — 상호작용(lock) | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | locked · broken |  |  |
| 촛대 | `candlestick` |  | light · stand | `light.webp` | 87×116 (1.4×1.8) | 빛을 내는 것 — 이동 방해 · 광원 | 어디든 | lit · unlit | ○ | lit |
| 책상 | `desk` |  | furniture · stand | `furniture.webp` | 147×77 (2.3×1.2) | 가구 · 생활 물건 — 이동 방해 | 실내 어디든 | intact · broken · cluttered | ○ |  |
| 의자 | `chair` |  | furniture · stand | `furniture.webp` | 89×80 (1.4×1.2) | 가구 · 생활 물건 — 이동 방해 | 실내 어디든 | s · e · w · n · toppled · broken | ○ |  |
| 깔개 | `carpet` |  | furniture · decal | `furniture.webp` | 200×124 (3.1×1.9) | 가구 · 생활 물건 — 바닥 장식 | 실내 어디든 | blue · red · green · round · worn · torn |  |  |

## 환경 흔적 — 41종

| 에셋 이름 | id | 새 | 분류 · 층 | 묶음 파일 | 크기 px(칸) | 사용 목적 | 다시 쓸 곳 | 변형 | 충돌 | 애니 |
|---|---|---|---|---|---|---|---|---|---|---|
| 흙 얼룩 | `mud_stain` | 새 | trace · decal | `trace.webp` | 129×82 (2.0×1.3) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 바닥 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | a · b · smear · wet |  |  |
| 손자국 | `handprints` | 새 | trace · decal | `trace.webp` | 95×52 (1.5×0.8) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 바닥 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | mud · dust · soot |  |  |
| 벽 손자국 | `wall_handprints` | 새 | trace · wall_decal | `trace.webp` | 65×48 (1.0×0.8) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 벽 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | soot · smear · dust |  |  |
| 쏟은 자국 | `spill_stain` | 새 | trace · decal | `trace.webp` | 123×83 (1.9×1.3) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 바닥 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | wine · ale · oil · wine_dried |  |  |
| 촛농 | `wax_drips` | 새 | trace · decal | `trace.webp` | 77×35 (1.2×0.6) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 바닥 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | a · pool · trail |  |  |
| 방치된 물건 | `abandoned_things` | 새 | trace · stand | `trace.webp` | 75×28 (1.2×0.4) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 상호작용(search) | 도시 뒷골목 · 폐가 · 미궁 어디든 | boot · bundle · bucket · coins · satchel |  |  |
| 해골 | `skull` |  | trace · stand | `trace.webp` | 36×29 (0.6×0.5) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | single · cracked · pair · side · heap · pike |  |  |
| 뼈 | `bones` |  | trace · stand | `trace.webp` | 91×45 (1.4×0.7) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | scatter_a · scatter_b · pile · crossed · ribcage · spine |  |  |
| 유골 | `skeleton` |  | trace · stand | `trace.webp` | 140×53 (2.2×0.8) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 상호작용(search) | 도시 뒷골목 · 폐가 · 미궁 어디든 | lying · sitting · armored · chained |  |  |
| 쇠고랑에 매달린 유골 | `skeleton_chained` |  | trace · wall_decal | `trace.webp` | 99×132 (1.6×2.1) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 벽 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | base |  |  |
| 시체 | `corpse` |  | trace · stand | `trace.webp` | 132×40 (2.1×0.6) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 상호작용(search) | 도시 뒷골목 · 폐가 · 미궁 어디든 | shrouded · explorer · rotten · explorer_b |  |  |
| 매달린 쇠우리 | `gibbet` |  | trace · stand | `trace.webp` | 78×201 (1.2×3.1) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 이동 방해 | 도시 뒷골목 · 폐가 · 미궁 어디든 | skeleton · empty | ○ |  |
| 부서진 무기 | `broken_weapon` |  | trace · stand | `trace.webp` | 101×34 (1.6×0.5) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | sword · spear · mace · helmet · arrows · pile · axe · shield |  |  |
| 부서진 갑옷 | `broken_armor` |  | trace · stand | `trace.webp` | 73×47 (1.1×0.7) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | breastplate · mail · pieces |  |  |
| 나무 잔해 | `debris_wood` |  | trace · stand | `trace.webp` | 72×51 (1.1×0.8) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | planks · splinters · furniture |  |  |
| 깨진 병 | `bottle_broken` |  | trace · stand | `trace.webp` | 80×37 (1.2×0.6) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | brown · red · green |  |  |
| 검은 점액 덩이 | `slime_blob` |  | trace · stand | `trace.webp` | 94×49 (1.5×0.8) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | a · b |  |  |
| 잿더미 | `ash_pile` |  | trace · stand | `trace.webp` | 81×48 (1.3×0.8) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | campfire · ash · pyre |  |  |
| 의식의 흔적 | `ritual_remains` |  | trace · stand | `trace.webp` | 110×78 (1.7×1.2) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | bone_circle · candle_ring · offering |  |  |
| 거미줄 고치 | `web_cocoon` |  | trace · stand | `trace.webp` | 65×182 (1.0×2.8) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | hanging · cluster · standing |  |  |
| 뼈와 넝마 둥지 | `nest` |  | trace · stand | `trace.webp` | 92×54 (1.4×0.8) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | base · eggs |  |  |
| 핏자국 | `blood_splat` |  | trace · decal | `trace.webp` | 72×107 (1.1×1.7) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 바닥 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | b · d · a · c · drops |  |  |
| 피 웅덩이 | `blood_pool` |  | trace · decal | `trace.webp` | 135×115 (2.1×1.8) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 바닥 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | fresh · fresh_b · dried · dried_b |  |  |
| 끌린 핏자국 | `blood_trail` |  | trace · decal | `trace.webp` | 179×68 (2.8×1.1) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 바닥 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | curved · hand · straight · vertical |  |  |
| 발자국 | `footprints` |  | trace · decal | `trace.webp` | 184×34 (2.9×0.5) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 바닥 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | bloody · dust · wet · bloody_fade |  |  |
| 썩은 자국 | `rot_stain` |  | trace · decal | `trace.webp` | 122×83 (1.9×1.3) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 바닥 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | a · c · b |  |  |
| 긁힌 자국 | `scratches` |  | trace · decal | `trace.webp` | 77×79 (1.2×1.2) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 바닥 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | b · a · c · deep |  |  |
| 끌린 자국 | `drag_marks` |  | trace · decal | `trace.webp` | 187×69 (2.9×1.1) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 바닥 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | curved · b · a |  |  |
| 먼지 | `dust` |  | trace · decal | `trace.webp` | 127×80 (2.0×1.2) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 바닥 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | a · b · c · drift |  |  |
| 거미줄 | `cobweb` |  | trace · wall_decal | `trace.webp` | 78×79 (1.2×1.2) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 벽 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | corner_l · torn · floor · corner_r · span |  |  |
| 물 얼룩 | `water_stain` |  | trace · decal | `trace.webp` | 106×90 (1.7×1.4) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 바닥 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | b · a · c |  |  |
| 벽 물자국 | `wall_stain` |  | trace · wall_decal | `trace.webp` | 62×148 (1.0×2.3) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 벽 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | a · b · c |  |  |
| 검은 점액 | `black_slime` |  | trace · decal | `trace.webp` | 87×74 (1.4×1.2) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 바닥 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | a · b · c · trail |  |  |
| 벽을 타고 흐르는 점액 | `wall_slime` |  | trace · wall_decal | `trace.webp` | 49×114 (0.8×1.8) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 벽 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | a · b |  |  |
| 그을음 | `scorch` |  | trace · decal | `trace.webp` | 88×97 (1.4×1.5) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 바닥 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | a · b · blast |  |  |
| 유리 조각 | `bottle_shards` |  | trace · decal | `trace.webp` | 55×42 (0.9×0.7) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 바닥 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | green · brown · clear |  |  |
| 벽 낙서 | `wall_graffiti` |  | trace · wall_decal | `trace.webp` | 98×32 (1.5×0.5) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 벽 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | chalk_c · chalk_a · chalk_b · chalk_d · blood_a · blood_c · blood_b |  |  |
| 벽에 새긴 글 | `wall_writing` |  | trace · wall_decal | `trace.webp` | 109×47 (1.7×0.7) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 벽 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | a · b · worn · c |  |  |
| 벽 긁힌 자국 | `wall_scratches` |  | trace · wall_decal | `trace.webp` | 54×95 (0.8×1.5) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 벽 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | claw_a · tally · tally_many · nails · claw_b |  |  |
| 벽에 튄 피 | `blood_wall` |  | trace · wall_decal | `trace.webp` | 72×115 (1.1×1.8) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 벽 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | a · b · hand · smear · c |  |  |
| 의식 표식 | `ritual_marks` |  | trace · decal | `trace.webp` | 168×168 (2.6×2.6) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 바닥 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | sigil_a · chalk_circle · salt_line · sigil_b · salt_ring |  |  |

## 파손 · 폐허 — 42종

| 에셋 이름 | id | 새 | 분류 · 층 | 묶음 파일 | 크기 px(칸) | 사용 목적 | 다시 쓸 곳 | 변형 | 충돌 | 애니 |
|---|---|---|---|---|---|---|---|---|---|---|
| 버려진 물건 더미 | `junk_pile` | 새 | city · stand | `city_life.webp` | 118×62 (1.8×1.0) | 도시 거리 · 광장 · 건물 겉을 짓고 꾸민다 — 장식 | 도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리 | large · small · alley |  |  |
| 깨진 창유리 조각 | `window_shards` | 새 | trace · decal | `trace.webp` | 109×61 (1.7×0.9) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 바닥 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | a · frame · few |  |  |
| 바닥 파편 | `floor_debris` | 새 | trace · decal | `trace.webp` | 162×109 (2.5×1.7) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 바닥 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | plaster · tile · slate |  |  |
| 무너진 선반 | `collapsed_shelf` | 새 | trace · stand | `trace.webp` | 165×108 (2.6×1.7) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 이동 방해 | 도시 뒷골목 · 폐가 · 미궁 어디든 | goods · books · bare | ○ |  |
| 낡은 문 | `old_door` | 새 | trace · stand | `trace.webp` | 89×86 (1.4×1.3) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | fallen · boarded · leaning |  |  |
| 무너진 목재 구조물 | `collapsed_timber` | 새 | trace · stand | `trace.webp` | 167×109 (2.6×1.7) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 이동 방해 | 도시 뒷골목 · 폐가 · 미궁 어디든 | rafters · scaffold | ○ |  |
| 쓰레기 더미 | `trash_heap` | 새 | trace · stand | `trace.webp` | 85×51 (1.3×0.8) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | small · large · rotten |  |  |
| 무너진 천장 회반죽 | `fallen_plaster` | 새 | trace · stand | `trace.webp` | 128×62 (2.0×1.0) | 누가 지나갔고 무슨 일이 있었는지 보이는 흔적 — 장식 | 도시 뒷골목 · 폐가 · 미궁 어디든 | lath · heap |  |  |
| 책상 | `desk` |  | furniture · stand | `furniture.webp` | 147×77 (2.3×1.2) | 가구 · 생활 물건 — 이동 방해 | 실내 어디든 | intact · broken · cluttered | ○ |  |
| 탁자 | `table` |  | furniture · stand | `furniture.webp` | 151×86 (2.4×1.3) | 가구 · 생활 물건 — 이동 방해 | 실내 어디든 | intact · set · toppled · broken | ○ |  |
| 의자 | `chair` |  | furniture · stand | `furniture.webp` | 89×80 (1.4×1.2) | 가구 · 생활 물건 — 이동 방해 | 실내 어디든 | s · e · w · n · toppled · broken | ○ |  |
| 긴 의자 | `bench` |  | furniture · stand | `furniture.webp` | 125×45 (1.9×0.7) | 가구 · 생활 물건 — 이동 방해 | 실내 어디든 | base · broken | ○ |  |
| 침대 | `bed` |  | furniture · stand | `furniture.webp` | 160×98 (2.5×1.5) | 가구 · 생활 물건 — 이동 방해 | 실내 어디든 | made · messy · bare · broken | ○ |  |
| 책장 | `bookshelf` |  | furniture · stand | `furniture.webp` | 142×143 (2.2×2.2) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | half · empty · full · broken | ○ |  |
| 캐비닛 | `cabinet` |  | furniture · stand | `furniture.webp` | 143×141 (2.2×2.2) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | open · closed · broken | ○ |  |
| 나무 상자 | `crate` |  | furniture · stand | `furniture.webp` | 94×76 (1.5×1.2) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | intact · open · broken · stack | ○ |  |
| 보물상자 | `chest` |  | furniture · stand | `furniture.webp` | 97×56 (1.5×0.9) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | closed · open · locked · broken · empty | ○ |  |
| 나무통 | `barrel` |  | furniture · stand | `furniture.webp` | 98×83 (1.5×1.3) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | intact · broken · toppled · water · stack | ○ |  |
| 무기 거치대 | `weapon_rack` |  | furniture · stand | `furniture.webp` | 152×138 (2.4×2.2) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | full · half · broken · empty | ○ |  |
| 갑옷 거치대 | `armor_stand` |  | furniture · stand | `furniture.webp` | 99×117 (1.6×1.8) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | armor · empty · fallen | ○ |  |
| 병 | `bottles` |  | furniture · stand | `furniture.webp` | 51×37 (0.8×0.6) | 가구 · 생활 물건 — 장식 | 실내 어디든 | group · potion_red · potion_blue · fallen · wine |  |  |
| 돌무더기 | `rubble` |  | nature · stand | `nature.webp` | 82×48 (1.3×0.8) | 자연물 — 장식 | 야외 · 동굴 | small · small_b · large_b · scatter · brick · brick_large · large |  |  |
| 벽을 뚫고 나온 뿌리 | `wall_roots` |  | nature · wall_decal | `nature.webp` | 127×145 (2.0×2.3) | 자연물 — 벽 장식 | 야외 · 동굴 | b · c · a |  |  |
| 다리 | `bridge` |  | structure · decal | `structure.webp` | 165×76 (2.6×1.2) | 이동을 막는 큰 구조물 — 바닥 장식 | 미궁 · 도시 | wood_h · wood_v · wood_broken · wood_end · stone_h · stone_v · stone_broken · rope_h |  |  |
| 폐허 담 | `ruin_wall` |  | structure · stand | `structure.webp` | 197×188 (3.1×2.9) | 이동을 막는 큰 구조물 — 이동 방해 | 미궁 · 도시 | window · low · straight_b · straight_a · doorway · corner · mossy · stub … (9) | ○ |  |
| 흰 대리석 기둥 | `pillar_white` |  | structure · stand | `structure.webp` | 121×231 (1.9×3.6) | 이동을 막는 큰 구조물 — 이동 방해 · 광원 | 미궁 · 도시 | intact · cracked · glowing · broken · sunken | ○ | glowing |
| 말뚝 울타리 | `palisade` |  | structure · stand | `structure.webp` | 192×134 (3.0×2.1) | 이동을 막는 큰 구조물 — 이동 방해 | 미궁 · 도시 | straight_b · broken · corner · straight_a · gate · spiked · gate_open | ○ |  |
| 천막 | `tent` |  | structure · stand | `structure.webp` | 166×170 (2.6×2.7) | 이동을 막는 큰 구조물 — 이동 방해 | 미궁 · 도시 | canvas · canvas_b · hide · collapsed | ○ |  |
| 철로 | `mine_track` |  | structure · decal | `structure.webp` | 128×54 (2.0×0.8) | 이동을 막는 큰 구조물 — 바닥 장식 | 미궁 · 도시 | straight_h · straight_v · end · broken · curve |  |  |
| 갱도 버팀목 | `mine_support` |  | structure · stand | `structure.webp` | 185×167 (2.9×2.6) | 이동을 막는 큰 구조물 — 이동 방해 | 미궁 · 도시 | intact · sagging · collapsed | ○ |  |
| 작은 배 | `boat` |  | structure · stand | `structure.webp` | 217×114 (3.4×1.8) | 이동을 막는 큰 구조물 — 이동 방해 · 상호작용(boat) | 미궁 · 도시 | oars · wreck · mast · beached | ○ |  |
| 천장 레일 | `overhead_rail` |  | structure · over | `structure.webp` | 133×93 (2.1×1.4) | 이동을 막는 큰 구조물 — 머리 위 전경 | 미궁 · 도시 | carriage · hook · broken · straight |  |  |
| 보석을 쥔 석상 | `statue_gem` |  | structure · stand | `structure.webp` | 125×181 (1.9×2.8) | 이동을 막는 큰 구조물 — 이동 방해 · 상호작용(statue) · 광원 | 미궁 · 도시 | lit · dark · white · broken | ○ | lit · white |
| 불탄 2층 벽돌집 | `burnt_house` |  | structure · stand | `structure.webp` | 283×319 (4.4×5.0) | 이동을 막는 큰 구조물 — 이동 방해 · 상호작용(door) | 미궁 · 도시 | ruin · door_open | ○ |  |
| 기둥 | `pillar` |  | structure · stand | `structure.webp` | 117×216 (1.8×3.4) | 이동을 막는 큰 구조물 — 이동 방해 | 미궁 · 도시 | intact · cracked · mossy · broken · stump · fallen | ○ |  |
| 석상 | `statue` |  | structure · stand | `structure.webp` | 124×186 (1.9×2.9) | 이동을 막는 큰 구조물 — 이동 방해 | 미궁 · 도시 | intact · mossy · headless · broken · ruined | ○ |  |
| 제단 | `altar` |  | structure · stand | `structure.webp` | 198×112 (3.1×1.8) | 이동을 막는 큰 구조물 — 이동 방해 · 상호작용(altar) | 미궁 · 도시 | plain · bloody · ritual · broken | ○ | ritual |
| 사다리 | `ladder` |  | structure · stand | `structure.webp` | 93×196 (1.4×3.1) | 이동을 막는 큰 구조물 — 상호작용(ladder) | 미궁 · 도시 | wall · broken · hatch |  |  |
| 석관 | `sarcophagus` |  | structure · stand | `structure.webp` | 200×102 (3.1×1.6) | 이동을 막는 큰 구조물 — 이동 방해 · 상호작용(container) | 미궁 · 도시 | open · ajar · closed · broken | ○ |  |
| 받침대 | `pedestal` |  | structure · stand | `structure.webp` | 97×101 (1.5×1.6) | 이동을 막는 큰 구조물 — 이동 방해 · 상호작용(pedestal) · 광원 | 미궁 · 도시 | empty · orb_red · broken · idol · orb | ○ |  |
| 난간 | `railing` |  | structure · stand | `structure.webp` | 109×71 (1.7×1.1) | 이동을 막는 큰 구조물 — 이동 방해 | 미궁 · 도시 | straight · post · side · broken | ○ |  |
| 아치 | `arch` |  | structure · stand | `structure.webp` | 250×238 (3.9×3.7) | 이동을 막는 큰 구조물 — 이동 방해 | 미궁 · 도시 | intact · mossy · ruined | ○ |  |

## 상호작용 오브젝트 — 65종

| 에셋 이름 | id | 새 | 분류 · 층 | 묶음 파일 | 크기 px(칸) | 사용 목적 | 다시 쓸 곳 | 변형 | 충돌 | 애니 |
|---|---|---|---|---|---|---|---|---|---|---|
| 룬 고리 | `rune_ring` | 새 | special · decal | `special.webp` | 95×69 (1.5×1.1) | 살피고 다루는 것 · 마법 장치 — 상호작용(circle) · 광원 | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | off_b · off · blue · violet · gold |  | blue · gold · violet |
| 봉인 장막 | `seal_barrier` | 새 | special · stand | `special.webp` | 170×143 (2.7×2.2) | 살피고 다루는 것 · 마법 장치 — 이동 방해 · 상호작용(seal) · 광원 | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | blue · gold · violet · breaking | ○ | blue · breaking · gold · violet |
| 봉인된 길목(빛의 벽) | `seal_wall` | 새 | special · stand | `special.webp` | 64×160 (1.0×2.5) | 살피고 다루는 것 · 마법 장치 — 이동 방해 · 상호작용(seal) · 광원 | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | blue · gold · red · breaking | ○ | blue · breaking · gold · red |
| 보물 궤짝 | `treasure_coffer` | 새 | special · stand | `special.webp` | 101×67 (1.6×1.1) | 살피고 다루는 것 · 마법 장치 — 이동 방해 · 상호작용(container) · 광원 | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | closed · open · empty | ○ |  |
| 잠긴 문 | `locked_door` | 새 | special · stand | `special.webp` | 137×135 (2.1×2.1) | 살피고 다루는 것 · 마법 장치 — 이동 방해 · 상호작용(door) | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | wood_chained · wood_unlocked · iron_barred · open · iron_unbarred | ○ |  |
| 벽 버튼 | `wall_button` | 새 | special · wall_decal | `special.webp` | 32×35 (0.5×0.6) | 살피고 다루는 것 · 마법 장치 — 상호작용(button) · 광원 | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | idle · pressed · glow |  |  |
| 바닥 버튼 | `floor_button` | 새 | special · stand | `special.webp` | 60×42 (0.9×0.7) | 살피고 다루는 것 · 마법 장치 — 상호작용(button) · 광원 | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | idle · pressed · glow |  |  |
| 벽 스위치 | `wall_switch` | 새 | special · wall_decal | `special.webp` | 24×41 (0.4×0.6) | 살피고 다루는 것 · 마법 장치 — 상호작용(switch) · 광원 | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | knife_off · knife_on · rune_on · rune_off |  |  |
| 숨은 벽 문 | `secret_panel` | 새 | special · wall_decal | `special.webp` | 60×109 (0.9×1.7) | 살피고 다루는 것 · 마법 장치 — 상호작용(secret) | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | closed · ajar · open |  |  |
| 당기는 사슬 | `pull_chain` | 새 | special · wall_decal | `special.webp` | 16×88 (0.2×1.4) | 살피고 다루는 것 · 마법 장치 — 상호작용(secret) | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | up · pulled |  |  |
| 기울이는 횃대 | `sconce_switch` | 새 | special · wall_decal | `special.webp` | 19×33 (0.3×0.5) | 살피고 다루는 것 · 마법 장치 — 상호작용(secret) | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | upright · tilted |  |  |
| 수상한 자리 | `examine_spot` | 새 | special · stand | `special.webp` | 116×66 (1.8×1.0) | 살피고 다루는 것 · 마법 장치 — 상호작용(examine) | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | odd_slab · loose_brick · pinned_note · curio |  |  |
| 열쇠 구멍 판 | `keyhole_plate` | 새 | special · wall_decal | `special.webp` | 36×50 (0.6×0.8) | 살피고 다루는 것 · 마법 장치 — 상호작용(keyhole) · 광원 | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | plain · ornate · glow · key |  |  |
| 문 봉인 | `door_seal` | 새 | special · wall_decal | `special.webp` | 68×65 (1.1×1.0) | 살피고 다루는 것 · 마법 장치 — 상호작용(seal) · 광원 | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | sealed · broken |  | sealed |
| 손을 얹는 비석 | `hand_stele` | 새 | special · stand | `special.webp` | 101×78 (1.6×1.2) | 살피고 다루는 것 · 마법 장치 — 이동 방해 · 상호작용(touch) · 광원 | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | idle · glowing · spent · broken | ○ | glowing |
| 책장 | `bookshelf` |  | furniture · stand | `furniture.webp` | 142×143 (2.2×2.2) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | half · empty · full · broken | ○ |  |
| 서랍장 | `dresser` |  | furniture · stand | `furniture.webp` | 105×78 (1.6×1.2) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | open · closed | ○ |  |
| 캐비닛 | `cabinet` |  | furniture · stand | `furniture.webp` | 143×141 (2.2×2.2) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | open · closed · broken | ○ |  |
| 나무 상자 | `crate` |  | furniture · stand | `furniture.webp` | 94×76 (1.5×1.2) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | intact · open · broken · stack | ○ |  |
| 보물상자 | `chest` |  | furniture · stand | `furniture.webp` | 97×56 (1.5×0.9) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | closed · open · locked · broken · empty | ○ |  |
| 나무통 | `barrel` |  | furniture · stand | `furniture.webp` | 98×83 (1.5×1.3) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | intact · broken · toppled · water · stack | ○ |  |
| 바구니 | `basket` |  | furniture · stand | `furniture.webp` | 63×49 (1.0×0.8) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | empty · food · toppled | ○ |  |
| 무기 거치대 | `weapon_rack` |  | furniture · stand | `furniture.webp` | 152×138 (2.4×2.2) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | full · half · broken · empty | ○ |  |
| 갑옷 거치대 | `armor_stand` |  | furniture · stand | `furniture.webp` | 99×117 (1.6×1.8) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | armor · empty · fallen | ○ |  |
| 연장통 | `toolbox` |  | furniture · stand | `furniture.webp` | 76×41 (1.2×0.6) | 가구 · 생활 물건 — 상호작용(container) | 실내 어디든 | full · empty |  |  |
| 자루 | `sack` |  | furniture · stand | `furniture.webp` | 70×40 (1.1×0.6) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | slumped · full · open · pile | ○ |  |
| 배낭 | `backpack` |  | furniture · stand | `furniture.webp` | 83×55 (1.3×0.9) | 가구 · 생활 물건 — 상호작용(container) | 실내 어디든 | standing · opened |  |  |
| 보급품 더미 | `supply_pile` |  | furniture · stand | `furniture.webp` | 121×96 (1.9×1.5) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | a · b | ○ |  |
| 천장까지 닿는 책장 | `bookshelf_tall` |  | furniture · stand | `furniture.webp` | 146×264 (2.3×4.1) | 가구 · 생활 물건 — 이동 방해 · 상호작용(container) | 실내 어디든 | full_b · full · half · empty · ladder | ○ |  |
| 거울 | `great_mirror` |  | special · stand | `special.webp` | 144×190 (2.2×3.0) | 살피고 다루는 것 · 마법 장치 — 이동 방해 · 상호작용(portal) · 광원 | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | dormant · active · broken | ○ | active |
| 마법진 | `magic_circle` |  | special · decal | `special.webp` | 182×182 (2.8×2.8) | 살피고 다루는 것 · 마법 장치 — 상호작용(circle) · 광원 | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | a_chalk · a_blood · a_blue · a_red · b_blue · b_blood · b_chalk · b_red … (12) |  | a_blue · a_red · b_blue · b_red · c_blue · c_red |
| 봉인 장치 | `seal_device` |  | special · stand | `special.webp` | 140×183 (2.2×2.9) | 살피고 다루는 것 · 마법 장치 — 이동 방해 · 상호작용(seal) · 광원 | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | sealed · weakened · broken | ○ | sealed · weakened |
| 석판 | `stone_tablet` |  | special · stand | `special.webp` | 109×135 (1.7×2.1) | 살피고 다루는 것 · 마법 장치 — 이동 방해 · 상호작용(read) · 광원 | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | intact · glowing · mossy · broken | ○ | glowing |
| 벽 석판 | `wall_tablet` |  | special · wall_decal | `special.webp` | 92×68 (1.4×1.1) | 살피고 다루는 것 · 마법 장치 — 상호작용(read) | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | c · b · a |  |  |
| 고대 기계 장치 | `ancient_machine` |  | special · stand | `special.webp` | 196×134 (3.1×2.1) | 살피고 다루는 것 · 마법 장치 — 이동 방해 · 상호작용(machine) · 광원 | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | dormant · active · wrecked | ○ | active |
| 레버 | `lever` |  | special · stand | `special.webp` | 76×75 (1.2×1.2) | 살피고 다루는 것 · 마법 장치 — 이동 방해 · 상호작용(lever) | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | left · right · broken | ○ |  |
| 벽 레버 | `wall_lever` |  | special · wall_decal | `special.webp` | 32×56 (0.5×0.9) | 살피고 다루는 것 · 마법 장치 — 상호작용(lever) | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | up · down |  |  |
| 감는 틀 | `winch` |  | special · stand | `special.webp` | 132×108 (2.1×1.7) | 살피고 다루는 것 · 마법 장치 — 이동 방해 · 상호작용(winch) | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | idle · turned · turned2 | ○ |  |
| 밸브 바퀴 | `valve_wheel` |  | special · wall_decal | `special.webp` | 134×43 (2.1×0.7) | 살피고 다루는 것 · 마법 장치 — 상호작용(valve) | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | turned · idle · rusted |  |  |
| 차원 균열 | `rift` |  | special · decal | `special.webp` | 176×66 (2.8×1.0) | 살피고 다루는 것 · 마법 장치 — 상호작용(rift) · 광원 | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | active · dormant · active_b |  | active · active_b |
| 포털 | `portal` |  | special · stand | `special.webp` | 215×181 (3.4×2.8) | 살피고 다루는 것 · 마법 장치 — 이동 방해 · 상호작용(portal) · 광원 | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | dormant · violet · blue · shattered | ○ | blue · violet |
| 압력판 | `pressure_plate` |  | special · decal | `special.webp` | 86×62 (1.3×1.0) | 살피고 다루는 것 · 마법 장치 — 상호작용(plate) | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | up · pressed · rune · rune_pressed |  | rune_pressed |
| 잠금 받침대 | `lock_pedestal` |  | special · stand | `special.webp` | 98×98 (1.5×1.5) | 살피고 다루는 것 · 마법 장치 — 이동 방해 · 상호작용(lock) · 광원 | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | locked · unlocked · empty · keyhole | ○ | locked · unlocked |
| 사슬 자물쇠 | `chained_lock` |  | special · wall_decal | `special.webp` | 80×107 (1.2×1.7) | 살피고 다루는 것 · 마법 장치 — 상호작용(lock) | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | locked · broken |  |  |
| 포탈 비석 | `portal_stele` |  | structure · stand | `structure.webp` | 128×181 (2.0×2.8) | 이동을 막는 큰 구조물 — 이동 방해 · 상호작용(portal) · 광원 | 미궁 · 도시 | idle · active · active_dark · dead · giant · leaning | ○ | active · active_dark |
| 기념비 | `monument` |  | structure · stand | `structure.webp` | 175×184 (2.7×2.9) | 이동을 막는 큰 구조물 — 이동 방해 · 상호작용(altar) · 광원 | 미궁 · 도시 | plain · offered · worn | ○ | offered |
| 광차 | `mine_cart` |  | structure · stand | `structure.webp` | 128×93 (2.0×1.4) | 이동을 막는 큰 구조물 — 이동 방해 · 상호작용(container) | 미궁 · 도시 | ore · empty · rubble · tipped | ○ |  |
| 작은 배 | `boat` |  | structure · stand | `structure.webp` | 217×114 (3.4×1.8) | 이동을 막는 큰 구조물 — 이동 방해 · 상호작용(boat) | 미궁 · 도시 | oars · wreck · mast · beached | ○ |  |
| 얼음 · 유리 계단 | `stairs_ice` |  | structure · stand | `structure.webp` | 200×181 (3.1×2.8) | 이동을 막는 큰 구조물 — 이동 방해 · 상호작용(stairs) | 미궁 · 도시 | ice · ice_cracked · glass | ○ |  |
| 도개교 | `drawbridge` |  | structure · decal | `structure.webp` | 148×158 (2.3×2.5) | 이동을 막는 큰 구조물 — 상호작용(bridge) | 미궁 · 도시 | down · down_bloody |  |  |
| 올린 도개교 | `drawbridge_raised` |  | structure · stand | `structure.webp` | 195×227 (3.0×3.5) | 이동을 막는 큰 구조물 — 이동 방해 · 상호작용(bridge) | 미궁 · 도시 | up | ○ |  |
| 보석을 쥔 석상 | `statue_gem` |  | structure · stand | `structure.webp` | 125×181 (1.9×2.8) | 이동을 막는 큰 구조물 — 이동 방해 · 상호작용(statue) · 광원 | 미궁 · 도시 | lit · dark · white · broken | ○ | lit · white |
| 불탄 2층 벽돌집 | `burnt_house` |  | structure · stand | `structure.webp` | 283×319 (4.4×5.0) | 이동을 막는 큰 구조물 — 이동 방해 · 상호작용(door) | 미궁 · 도시 | ruin · door_open | ○ |  |
| 계단식 사원 | `pyramid_temple` |  | structure · stand | `structure.webp` | 336×289 (5.2×4.5) | 이동을 막는 큰 구조물 — 이동 방해 · 상호작용(entrance) · 광원 | 미궁 · 도시 | intact · sunken · lit | ○ | lit |
| 제단 | `altar` |  | structure · stand | `structure.webp` | 198×112 (3.1×1.8) | 이동을 막는 큰 구조물 — 이동 방해 · 상호작용(altar) | 미궁 · 도시 | plain · bloody · ritual · broken | ○ | ritual |
| 올라가는 계단 | `stairs_up` |  | structure · stand | `structure.webp` | 204×188 (3.2×2.9) | 이동을 막는 큰 구조물 — 이동 방해 · 상호작용(stairs) | 미궁 · 도시 | stone · worn | ○ |  |
| 사다리 | `ladder` |  | structure · stand | `structure.webp` | 93×196 (1.4×3.1) | 이동을 막는 큰 구조물 — 상호작용(ladder) | 미궁 · 도시 | wall · broken · hatch |  |  |
| 내려가는 계단 | `stairs_down` |  | structure · decal | `structure.webp` | 126×99 (2.0×1.6) | 이동을 막는 큰 구조물 — 상호작용(stairs) | 미궁 · 도시 | stone |  |  |
| 석관 | `sarcophagus` |  | structure · stand | `structure.webp` | 200×102 (3.1×1.6) | 이동을 막는 큰 구조물 — 이동 방해 · 상호작용(container) | 미궁 · 도시 | open · ajar · closed · broken | ○ |  |
| 받침대 | `pedestal` |  | structure · stand | `structure.webp` | 97×101 (1.5×1.6) | 이동을 막는 큰 구조물 — 이동 방해 · 상호작용(pedestal) · 광원 | 미궁 · 도시 | empty · orb_red · broken · idol · orb | ○ |  |
| 감옥 철창 | `bars` |  | wall · stand | `wall.webp` | 135×184 (2.1×2.9) | 벽 타일(윗면 자동 연결 + 벽면) — 이동 방해 · 상호작용(door) | 건물 실내 · 미궁의 지은 공간 | panel · bent · door_open · rusty · door · post | ○ |  |
| 문틀과 문 | `doorway` |  | wall · stand | `wall.webp` | 141×193 (2.2×3.0) | 벽 타일(윗면 자동 연결 + 벽면) — 이동 방해 · 상호작용(door) | 건물 실내 · 미궁의 지은 공간 | open · wood · wood_ajar · wood_broken · iron · portcullis · iron_ajar · portcullis_up … (9) | ○ |  |
| 아치형 통로 | `gateway` |  | wall · stand | `wall.webp` | 205×196 (3.2×3.1) | 벽 타일(윗면 자동 연결 + 벽면) — 이동 방해 · 상호작용(door) | 건물 실내 · 미궁의 지은 공간 | open · doors_open · barred · collapsed · doors | ○ |  |
| 문양 새긴 석문 | `sealed_door` |  | wall · stand | `wall.webp` | 200×198 (3.1×3.1) | 벽 타일(윗면 자동 연결 + 벽면) — 이동 방해 · 상호작용(door) · 광원 | 건물 실내 · 미궁의 지은 공간 | plain · fate · courage · wisdom · patience · lit · open | ○ | lit |
| 금 간 벽 | `cracked_wall` |  | wall · wall_decal | `wall.webp` | 83×111 (1.3×1.7) | 벽 타일(윗면 자동 연결 + 벽면) — 상호작용(breakable) | 건물 실내 · 미궁의 지은 공간 | loose · broken · cracked · cracked_b |  |  |

## 마법 · 환경 효과 — 34종

| 에셋 이름 | id | 새 | 분류 · 층 | 묶음 파일 | 크기 px(칸) | 사용 목적 | 다시 쓸 곳 | 변형 | 충돌 | 애니 |
|---|---|---|---|---|---|---|---|---|---|---|
| 불꽃(낱 효과) | `flame` | 새 | fx · over | `fx.webp` | 61×58 (0.9×0.9) | 화면에 얹는 가벼운 연출(4프레임) — 광원 | 불 · 물 · 마법이 있는 곳 어디든 | small · medium · large · wide · blue |  | blue · large · medium · small · wide |
| 촛불 불꽃 | `candle_flame` | 새 | fx · over | `fx.webp` | 19×20 (0.3×0.3) | 화면에 얹는 가벼운 연출(4프레임) — 광원 | 불 · 물 · 마법이 있는 곳 어디든 | steady · guttering |  | guttering · steady |
| 횃불 불꽃 | `torch_flame` | 새 | fx · over | `fx.webp` | 75×73 (1.2×1.1) | 화면에 얹는 가벼운 연출(4프레임) — 광원 | 불 · 물 · 마법이 있는 곳 어디든 | steady · windblown · dying |  | dying · steady · windblown |
| 연기 | `smoke` | 새 | fx · over | `fx.webp` | 36×103 (0.6×1.6) | 화면에 얹는 가벼운 연출(4프레임) — 머리 위 전경 | 불 · 물 · 마법이 있는 곳 어디든 | wisp · column · black · chimney |  | black · chimney · column · wisp |
| 먼지 구름 | `dust_puff` | 새 | fx · over | `fx.webp` | 34×20 (0.5×0.3) | 화면에 얹는 가벼운 연출(4프레임) — 머리 위 전경 | 불 · 물 · 마법이 있는 곳 어디든 | impact · step · crumble |  | crumble · impact · step |
| 빛 알갱이 | `light_motes` | 새 | fx · over | `fx.webp` | 124×114 (1.9×1.8) | 화면에 얹는 가벼운 연출(4프레임) — 머리 위 전경 | 불 · 물 · 마법이 있는 곳 어디든 | warm · firefly · spore |  | firefly · spore · warm |
| 떨어지는 물방울 | `water_drip` | 새 | fx · over | `fx.webp` | 6×9 (0.1×0.1) | 화면에 얹는 가벼운 연출(4프레임) — 머리 위 전경 | 불 · 물 · 마법이 있는 곳 어디든 | fall · splash · trickle |  | fall · splash · trickle |
| 잔물결 고리 | `water_ripple` | 새 | fx · decal | `fx.webp` | 72×40 (1.1×0.6) | 화면에 얹는 가벼운 연출(4프레임) — 바닥 장식 | 불 · 물 · 마법이 있는 곳 어디든 | single · double · rain |  | double · rain · single |
| 물 반짝임 | `water_glint` | 새 | fx · decal | `fx.webp` | 79×26 (1.2×0.4) | 화면에 얹는 가벼운 연출(4프레임) — 바닥 장식 | 불 · 물 · 마법이 있는 곳 어디든 | day · day_b · moon · torch |  | day · day_b · moon · torch |
| 일렁이는 불빛(바닥) | `light_flicker` | 새 | fx · decal | `fx.webp` | 143×102 (2.2×1.6) | 화면에 얹는 가벼운 연출(4프레임) — 바닥 장식 | 불 · 물 · 마법이 있는 곳 어디든 | fire · candle · cold · forge |  | candle · cold · fire · forge |
| 창으로 든 빛(바닥) | `window_light` | 새 | fx · decal | `fx.webp` | 101×146 (1.6×2.3) | 화면에 얹는 가벼운 연출(4프레임) — 바닥 장식 | 불 · 물 · 마법이 있는 곳 어디든 | day · moon · arched · dusty |  | dusty |
| 작은 마력 구체 | `mana_orb` | 새 | light · over | `light.webp` | 34×57 (0.5×0.9) | 빛을 내는 것 — 광원 | 어디든 | blue · violet · red · gold |  | blue · gold · red · violet |
| 신비로운 빛기둥 | `light_shaft` | 새 | light · over | `light.webp` | 60×206 (0.9×3.2) | 빛을 내는 것 — 광원 | 어디든 | warm · pale · blue · narrow |  | blue · narrow · pale · warm |
| 룬 고리 | `rune_ring` | 새 | special · decal | `special.webp` | 95×69 (1.5×1.1) | 살피고 다루는 것 · 마법 장치 — 상호작용(circle) · 광원 | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | off_b · off · blue · violet · gold |  | blue · gold · violet |
| 마법 에너지 | `magic_energy` | 새 | special · over | `special.webp` | 40×124 (0.6×1.9) | 살피고 다루는 것 · 마법 장치 — 광원 | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | arc_blue · arc_violet · arc_red · wisp_blue · wisp_violet · wisp_gold |  | arc_blue · arc_red · arc_violet · wisp_blue · wisp_gold · wisp_violet |
| 봉인 장막 | `seal_barrier` | 새 | special · stand | `special.webp` | 170×143 (2.7×2.2) | 살피고 다루는 것 · 마법 장치 — 이동 방해 · 상호작용(seal) · 광원 | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | blue · gold · violet · breaking | ○ | blue · breaking · gold · violet |
| 봉인된 길목(빛의 벽) | `seal_wall` | 새 | special · stand | `special.webp` | 64×160 (1.0×2.5) | 살피고 다루는 것 · 마법 장치 — 이동 방해 · 상호작용(seal) · 광원 | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | blue · gold · red · breaking | ○ | blue · breaking · gold · red |
| 마법진 파편 | `circle_fragments` | 새 | special · decal | `special.webp` | 130×94 (2.0×1.5) | 살피고 다루는 것 · 마법 장치 — 광원 | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | dead_a · dead_b · faint_blue · faint_violet |  | faint_blue · faint_violet |
| 폭포 | `waterfall` |  | fx · wall_decal | `fx.webp` | 60×188 (0.9×2.9) | 화면에 얹는 가벼운 연출(4프레임) — 벽 장식 | 불 · 물 · 마법이 있는 곳 어디든 | clear · red · black · clear_wide |  | black · clear · clear_wide · red |
| 안개 | `mist` |  | fx · over | `fx.webp` | 195×94 (3.0×1.5) | 화면에 얹는 가벼운 연출(4프레임) — 머리 위 전경 | 불 · 물 · 마법이 있는 곳 어디든 | grey · black · violet · blue · grey_b · black_b |  | black · black_b · blue · grey · grey_b · violet |
| 은빛 구체 | `light_orb` |  | fx · over | `fx.webp` | 18×27 (0.3×0.4) | 화면에 얹는 가벼운 연출(4프레임) — 광원 | 불 · 물 · 마법이 있는 곳 어디든 | rise · rise_b · cluster |  | cluster · rise · rise_b |
| 흩날리는 입자 | `drift` |  | fx · over | `fx.webp` | 128×128 (2.0×2.0) | 화면에 얹는 가벼운 연출(4프레임) — 머리 위 전경 | 불 · 물 · 마법이 있는 곳 어디든 | snow · ember · ash · dust · frost |  | ash · dust · ember · frost · snow |
| 퍼지는 공간 균열(차원 붕괴) | `collapse_crack` |  | fx · over | `fx.webp` | 37×42 (0.6×0.7) | 화면에 얹는 가벼운 연출(4프레임) — 광원 | 불 · 물 · 마법이 있는 곳 어디든 | seed · spread · web · web_b |  | seed · spread · web · web_b |
| 붉은 빛(낙하 예고) | `red_beam` |  | fx · decal | `fx.webp` | 234×158 (3.7×2.5) | 화면에 얹는 가벼운 연출(4프레임) — 광원 | 불 · 물 · 마법이 있는 곳 어디든 | pulse |  | pulse |
| 벼락 줄기 | `lightning` |  | fx · over | `fx.webp` | 74×256 (1.2×4.0) | 화면에 얹는 가벼운 연출(4프레임) — 광원 | 불 · 물 · 마법이 있는 곳 어디든 | strike · strike_b |  | strike · strike_b |
| 까마귀 떼 | `crows` |  | fx · over | `fx.webp` | 94×56 (1.5×0.9) | 화면에 얹는 가벼운 연출(4프레임) — 머리 위 전경 | 불 · 물 · 마법이 있는 곳 어디든 | flock · flock_b · few |  | few · flock · flock_b |
| 떠다니는 부산물 | `flotsam` |  | fx · decal | `fx.webp` | 85×49 (1.3×0.8) | 화면에 얹는 가벼운 연출(4프레임) — 바닥 장식 | 불 · 물 · 마법이 있는 곳 어디든 | planks · barrel · mixed |  | barrel · mixed · planks |
| 마법 등 | `magic_lamp` |  | light · stand | `light.webp` | 96×133 (1.5×2.1) | 빛을 내는 것 — 이동 방해 · 광원 | 어디든 | blue · red · violet · dead | ○ | blue · red · violet |
| 빛나는 룬 | `glow_rune` |  | light · decal | `light.webp` | 53×53 (0.8×0.8) | 빛을 내는 것 — 광원 | 어디든 | a_off · b_off · c_off · a_blue · d_off · b_blue · c_blue · d_blue … (10) |  | a_blue · a_red · b_blue · c_blue · c_red · d_blue |
| 빛나는 균열 | `glow_crack` |  | light · decal | `light.webp` | 141×63 (2.2×1.0) | 빛을 내는 것 — 광원 | 어디든 | blue · red · dead · blue_b · dead_b |  | blue · blue_b · red |
| 벽 룬 글줄 | `wall_rune` |  | light · wall_decal | `light.webp` | 107×27 (1.7×0.4) | 빛을 내는 것 — 광원 | 어디든 | off · blue · red · blue_b · off_b |  | blue · blue_b · red |
| 룬석 | `rune_stone` |  | special · stand | `special.webp` | 106×82 (1.7×1.3) | 살피고 다루는 것 · 마법 장치 — 이동 방해 · 광원 | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | dormant · blue · red · dormant_b · blue_b · dormant_c · violet_c | ○ | blue · blue_b · red · violet_c |
| 수정 | `crystal` |  | special · stand | `special.webp` | 122×74 (1.9×1.2) | 살피고 다루는 것 · 마법 장치 — 이동 방해 · 광원 | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | blue_small · blue_large · violet_small · red_large · violet_large · red_small · dead · blue_small_b | ○ |  |
| 마력 잔류물 | `mana_residue` |  | special · decal | `special.webp` | 65×75 (1.0×1.2) | 살피고 다루는 것 · 마법 장치 — 광원 | 미궁 기믹 방 · 도시 하수도 · 숨은 방 | blue · violet · green · blue_b |  | blue · blue_b · green · violet |

## 아이템 — 29종

| 에셋 이름 | id | 새 | 분류 · 층 | 묶음 파일 | 크기 px(칸) | 사용 목적 | 다시 쓸 곳 | 변형 | 충돌 | 애니 |
|---|---|---|---|---|---|---|---|---|---|---|
| 물약병(아이템) | `item_potion` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | tall_blue · round_red · square_green · gourd_amber |  |  |
| 작은 물약병 | `item_vial` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | tube_red · drop_blue · facet_green |  |  |
| 약초 다발 | `item_herb` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | bundle · sprig · dried |  |  |
| 붕대 두루마리 | `item_bandage_roll` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | roll · pair · pad |  |  |
| 음식(아이템) | `item_food` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | meat · stew · cheese · apple |  |  |
| 휴대 식량 | `item_ration` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | pack · hardtack · jerky |  |  |
| 음료(아이템) | `item_drink` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | tankard · wine · waterskin |  |  |
| 치료 도구 | `item_healer_tools` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | salve · needle · mortar · splint |  |  |
| 마법석(아이템) | `item_magic_stone` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | raw_small · raw · cut · raw_large |  |  |
| 광석 덩어리 | `item_ore` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | copper · iron · silver |  |  |
| 금속 주괴(아이템) | `item_ingot` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | iron · gold · steel_stack · copper_pair |  |  |
| 보석(아이템) | `item_gem` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | round_red · emerald_green · teardrop_blue · raw_violet |  |  |
| 가죽(아이템) | `item_hide` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | strap · pelt · roll |  |  |
| 옷감 | `item_cloth` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | bolt · folded · rag |  |  |
| 뼈 재료 | `item_bone` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | bone · fang · horn |  |  |
| 목재(아이템) | `item_wood` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | log · planks · branch |  |  |
| 약초 재료 | `item_reagent_herb` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | mushroom · flower · berries · root |  |  |
| 마법 재료 | `item_reagent_magic` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | dust_vial · shard · feather · rune_chip · bead |  |  |
| 열쇠(아이템) | `item_key` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | ornate · iron · small |  |  |
| 낡은 열쇠 | `item_key_old` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | rusty · broken · bent |  |  |
| 보물 상자(아이템) | `item_treasure_box` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | closed · open · jeweled |  |  |
| 두루마리(아이템) | `item_scroll` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | rolled · sealed · open |  |  |
| 책(아이템) | `item_book` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | closed · clasp · tome |  |  |
| 지도(아이템) | `item_map` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | fragment · unrolled · folded |  |  |
| 문서(아이템) | `item_document` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | letter · contract · note |  |  |
| 유물(아이템) | `item_relic` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | device · disc · crown_piece |  |  |
| 장신구(아이템) | `item_trinket` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | ring · necklace · bracelet · brooch |  |  |
| 금화(아이템) | `item_gold_coin` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | single · stack · pile |  |  |
| 보석 주머니 | `item_gem_pouch` | 새 | item · decal | `item.webp` | 80×80 (1.2×1.2) | 가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다 — 바닥 장식 | Tab 메뉴 가방 · 상점 카드 · 전투 드롭 | open · closed |  |  |

## UI 아이콘 — 18종

| 에셋 이름 | id | 새 | 분류 · 층 | 묶음 파일 | 크기 px(칸) | 사용 목적 | 다시 쓸 곳 | 변형 | 충돌 | 애니 |
|---|---|---|---|---|---|---|---|---|---|---|
| 대장간 아이콘 | `icon_smithy` | 새 | icon · over | `icon.webp` | 96×96 (1.5×1.5) | 시설 · 표식 아이콘(96 × 96 — 상태이상 아이콘과 같은 판) — 머리 위 전경 | 지도 표식 · 시설 카드 · 안내 | plate · plain |  |  |
| 여관 아이콘 | `icon_inn` | 새 | icon · over | `icon.webp` | 96×96 (1.5×1.5) | 시설 · 표식 아이콘(96 × 96 — 상태이상 아이콘과 같은 판) — 머리 위 전경 | 지도 표식 · 시설 카드 · 안내 | plate · plain |  |  |
| 신전 아이콘 | `icon_shrine` | 새 | icon · over | `icon.webp` | 96×96 (1.5×1.5) | 시설 · 표식 아이콘(96 × 96 — 상태이상 아이콘과 같은 판) — 머리 위 전경 | 지도 표식 · 시설 카드 · 안내 | plain · plate |  |  |
| 상점 아이콘 | `icon_shop` | 새 | icon · over | `icon.webp` | 96×96 (1.5×1.5) | 시설 · 표식 아이콘(96 × 96 — 상태이상 아이콘과 같은 판) — 머리 위 전경 | 지도 표식 · 시설 카드 · 안내 | plain · plate |  |  |
| 은행 아이콘 | `icon_bank` | 새 | icon · over | `icon.webp` | 96×96 (1.5×1.5) | 시설 · 표식 아이콘(96 × 96 — 상태이상 아이콘과 같은 판) — 머리 위 전경 | 지도 표식 · 시설 카드 · 안내 | plate · plain |  |  |
| 탐험가 길드 아이콘 | `icon_guild` | 새 | icon · over | `icon.webp` | 96×96 (1.5×1.5) | 시설 · 표식 아이콘(96 × 96 — 상태이상 아이콘과 같은 판) — 머리 위 전경 | 지도 표식 · 시설 카드 · 안내 | plain · plate |  |  |
| 도서관 아이콘 | `icon_library` | 새 | icon · over | `icon.webp` | 96×96 (1.5×1.5) | 시설 · 표식 아이콘(96 × 96 — 상태이상 아이콘과 같은 판) — 머리 위 전경 | 지도 표식 · 시설 카드 · 안내 | plain · plate |  |  |
| 차원광장 아이콘 | `icon_plaza` | 새 | icon · over | `icon.webp` | 96×96 (1.5×1.5) | 시설 · 표식 아이콘(96 × 96 — 상태이상 아이콘과 같은 판) — 머리 위 전경 | 지도 표식 · 시설 카드 · 안내 | plate · plain |  |  |
| 도시 입구 아이콘 | `icon_city_gate` | 새 | icon · over | `icon.webp` | 96×96 (1.5×1.5) | 시설 · 표식 아이콘(96 × 96 — 상태이상 아이콘과 같은 판) — 머리 위 전경 | 지도 표식 · 시설 카드 · 안내 | plate · plain |  |  |
| 상호작용 아이콘 | `icon_interact` | 새 | icon · over | `icon.webp` | 96×96 (1.5×1.5) | 시설 · 표식 아이콘(96 × 96 — 상태이상 아이콘과 같은 판) — 머리 위 전경 | 지도 표식 · 시설 카드 · 안내 | plate · plain |  |  |
| 잠긴 문 아이콘 | `icon_locked_door` | 새 | icon · over | `icon.webp` | 96×96 (1.5×1.5) | 시설 · 표식 아이콘(96 × 96 — 상태이상 아이콘과 같은 판) — 머리 위 전경 | 지도 표식 · 시설 카드 · 안내 | plate · plain |  |  |
| 열쇠 아이콘 | `icon_key` | 새 | icon · over | `icon.webp` | 96×96 (1.5×1.5) | 시설 · 표식 아이콘(96 × 96 — 상태이상 아이콘과 같은 판) — 머리 위 전경 | 지도 표식 · 시설 카드 · 안내 | plain · plate |  |  |
| 보물 아이콘 | `icon_treasure` | 새 | icon · over | `icon.webp` | 96×96 (1.5×1.5) | 시설 · 표식 아이콘(96 × 96 — 상태이상 아이콘과 같은 판) — 머리 위 전경 | 지도 표식 · 시설 카드 · 안내 | plate · plain |  |  |
| 상자 아이콘 | `icon_chest` | 새 | icon · over | `icon.webp` | 96×96 (1.5×1.5) | 시설 · 표식 아이콘(96 × 96 — 상태이상 아이콘과 같은 판) — 머리 위 전경 | 지도 표식 · 시설 카드 · 안내 | plain · plate |  |  |
| 마석 아이콘 | `icon_magic_stone` | 새 | icon · over | `icon.webp` | 96×96 (1.5×1.5) | 시설 · 표식 아이콘(96 × 96 — 상태이상 아이콘과 같은 판) — 머리 위 전경 | 지도 표식 · 시설 카드 · 안내 | plate · plain |  |  |
| 물약 아이콘 | `icon_potion` | 새 | icon · over | `icon.webp` | 96×96 (1.5×1.5) | 시설 · 표식 아이콘(96 × 96 — 상태이상 아이콘과 같은 판) — 머리 위 전경 | 지도 표식 · 시설 카드 · 안내 | plain · plate |  |  |
| 재료 아이콘 | `icon_material` | 새 | icon · over | `icon.webp` | 96×96 (1.5×1.5) | 시설 · 표식 아이콘(96 × 96 — 상태이상 아이콘과 같은 판) — 머리 위 전경 | 지도 표식 · 시설 카드 · 안내 | plate · plain |  |  |
| 장비 아이콘 | `icon_equipment` | 새 | icon · over | `icon.webp` | 96×96 (1.5×1.5) | 시설 · 표식 아이콘(96 × 96 — 상태이상 아이콘과 같은 판) — 머리 위 전경 | 지도 표식 · 시설 카드 · 안내 | plate · plain |  |  |

