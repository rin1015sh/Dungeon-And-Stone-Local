# 탐험 맵 플레이어 몸 그림 다시 만들기 — 다른 AI에 붙여 넣는 프롬프트

> 2026-10-17 사용자와 여러 번 고쳐 확정한 인간 탐험가·바바리안 맵 그림(`assets/actors/human.webp`·`barbarian.webp`)을
> 다른 AI(이미지 생성 AI·코딩 AI 어느 쪽이든)로 다시 만들 때 쓴다. 아래 **[공통 명세]**는 꼭 함께 붙이고,
> 이미지 생성 AI면 **[A]**, 코드로 그리는 AI면 **[B]**를 이어 붙인다. 참고 그림(피어 앤 헝거 맵 캐릭터 화면·주인공 걷기 시트)이 있으면 같이 첨부한다.
> 지금 게임 그림은 `tools/paint_actors.gd`(3D 점토 몸 → 줄이기)로 만든 것이고, 결정 기록은 `docs/ASSUMPTIONS.md` AM27.

---

## [공통 명세]

### 무엇을 만드나
2D 탑다운(3/4 쿼터뷰) 다크 판타지 던전 게임의 **플레이어 캐릭터 맵 스프라이트 시트** 2장:
1. `human.webp` — 인간 탐험가
2. `barbarian.webp` — 바바리안(인간보다 조금 크고 넓은 거구)

### 시트 형식 (정확히 지킬 것)
- 시트 크기 **216 × 432 px**, 배경 **투명**(PNG/WebP 알파).
- 칸 하나 **72 × 108 px**, **3열 × 4행**.
- 행(위→아래): **① 아래(정면, 보는 사람 쪽으로 걸음) ② 왼쪽 ③ 오른쪽 ④ 위(뒷모습)**.
  - ③ 오른쪽은 ② 왼쪽을 좌우 반전한 것이어도 된다.
- 열(왼→오): **걸음 A · 선 자세 · 걸음 B** (게임은 A → 섬 → B → 섬 순서로 돌린다).
- 발바닥 = 칸 **아래 가장자리에서 4px 위**, 가로 가운데. 모든 칸에서 발 높이가 같아야 걸을 때 위아래로 튀지 않는다(걸음 칸에서 몸이 1~2px 들썩이는 건 괜찮음).
- 인간 키(정수리~발바닥) **약 84px**, 바바리안 **약 92px**. 게임은 시트를 0.5배로 그려 화면에서 사람이 바닥 칸 약 1.3개 높이가 된다.

### 그림체 — 피어 앤 헝거(Fear & Hunger) 맵 캐릭터
- 칠한 일러스트를 작게 줄인 느낌: **부드러운 붓 명암(3~4단) + 짙은 갈흑색 1px 바깥선**(#120c0a 근처), 몸 안 경계(겨드랑이·다리 사이·옷 경계)에도 진한 선.
- 깔끔한 단색 도트·만화풍·치비 아님. 어둡고 거친 중세 다크 판타지 분위기, 채도 낮게.
- 빛은 왼쪽 위에서. 형태는 근육·관절·옷 주름이 명암으로 조형돼야 한다(평평한 레고 조각처럼 보이면 실패).

### 비율·자세 (참고 시트에서 잰 값)
- **머리(머리카락 포함) = 키의 약 1/3**, 머리 폭 ≈ 키의 0.3(어깨 폭과 비슷). 너무 큰 대두는 실패.
- 몸통·팔다리는 **굵고 짧다**(다리 = 키의 약 30%). 엉덩이·허벅지도 굵다.
- 서 있을 때 **몸을 살짝 앞으로 숙이고, 어깨를 늘어뜨리고, 팔꿈치를 조금 굽혀 손이 허벅지 앞**에 온다. 두 발은 거의 붙여(살짝 벌림) 곧게 선다. **쩍벌·뒤틀린 몸 금지**.
- 옆 걸음: 보폭이 크고, **뒷발 뒤꿈치가 높이 들리고**(무릎이 굽어 발바닥이 보임), 팔은 다리와 반대로 앞뒤로 크게 흔든다.
- 정면·뒷모습 걸음: 한쪽 발이 조금 들리고 몸이 1px 들썩.

### 얼굴 (가장 많이 실패한 부분)
- **얼굴형은 깎은 모양**: 옆에서 보면 이마→턱끝이 매끈한 한 줄로 내려오고 **턱끝으로 좁아진다**. 둥근 공·항아리 얼굴 금지.
- **코·입·귀를 그리지 않는다.** 턱 밑·입 자리에 홈·주름·선이 생기면 해골 턱처럼 보여 실패.
- **눈 = 앞머리 그늘 속 짙은 눈구멍 얼룩**(가로로 조금 긴, 가운데가 가장 짙고 가장자리로 풀리는 그늘). 맵 크기에서 폭 3~4px. **점 눈·안경 같은 둥근 테·만화 눈 금지.**
- 옆모습은 90°보다 살짝 더 돌려 **얼굴이 보는 사람 쪽으로 조금 보이게**(뒤통수만 보이면 실패). 옆얼굴이 머리 그늘에 묻혀 너무 어두우면 안 된다 — 살갗을 조금 밝게.

### 머리카락
- **인간: 턱선까지 내려오는 짧은 머리, 굵은 타래 20여 가닥이 가지런히 내려오고 끝만 살짝 흩어진다**(정돈된 더벅머리). 앞머리는 눈썹~눈 위까지, 옆은 뺨을 덮고 뒤는 목덜미까지. 결이 보이게 몇 가닥은 밝게.
  - 실패 예: 매끈한 헬멧/그릇 모양, 가는 가닥이 사방으로 뻗친 산발, 버섯처럼 옆으로 부푼 머리.
  - 옆모습에서는 관자놀이 타래가 광대 높이에서 끝나 옆얼굴이 보여야 한다.
- **바바리안: 가르마 탄 어깨 아래 긴 머리 + 양쪽 땋은 머리 + 덥수룩한 수염**(같은 갈색). 이마는 드러난다.

### 복장 (게임 전투 화면 그림과 같은 옷 — 장비·무기는 그리지 않는다)
| | 인간 탐험가 | 바바리안 |
|---|---|---|
| 살갗 | #c49a78 | #b88866 |
| 머리 | #3a2a1e (짙은 갈색) | #4a2e1c, 수염 같은 색 |
| 상의 | 아마 셔츠 #b8a888, 소매를 팔꿈치까지 걷음 + 가죽 조끼 #5a3e28 | 맨 가슴·맨팔 + 가죽 조끼 #6a4a30 |
| 어깨 | 두건 달린 짧은 어깨 망토 #5a3028(두건은 목 뒤로 젖힘) | 털 어깨 망토 #6e5e4a(끝이 들쭉날쭉) |
| 팔 | 팔목 가죽 #4a3424 | 위팔 쇠띠 #6a5a3a, 팔목 가죽 #3e2c1c |
| 허리 | 허리띠 #2e2018 + 주머니 + 단검 손잡이 | 허리띠 #3a2818 + 주머니 |
| 다리 | 바지 #4a4236 | 바지 #5a4430 + 종아리를 감은 천 #8a7a60 |
| 발 | 가죽 장화 #3a2a1e | 털 단 장화 #4a3424(털 #7a6a54) |

### 검수 기준 (받은 그림을 이것으로 판단)
1. 시트 216×432, 72×108 칸 3×4, 행 순서·열 순서가 위와 같다. 발 높이가 모든 칸에서 같다.
2. 머리 ≈ 키의 1/3, 다리 짧고 굵음, 숙인 자세·늘어뜨린 팔, 쩍벌·뒤틀림 없음.
3. 얼굴에 코·입·귀·턱 홈 없음, 눈은 짙은 눈구멍, 옆얼굴이 깎인 선이고 보인다.
4. 인간 머리가 정돈된 턱선 더벅머리(헬멧·산발 아님), 바바리안은 긴 머리·땋은 머리·수염.
5. 옷 구성·색이 표와 같고 무기·장비가 없다.
6. 짙은 바깥선 + 칠한 명암, 배경 투명.

---

## [A] 이미지 생성 AI용 (영문 프롬프트 — 한 번에 시트가 안 나오면 칸별로 만들어 붙인다)

```
Sprite sheet, 3 columns x 4 rows, each cell 72x108 px, total 216x432 px, transparent background.
Rows top to bottom: walking toward camera (front), walking left (side profile), walking right (side profile), walking away (back view).
Columns: step A, standing, step B. Feet at the same baseline in every cell, 4 px above the cell bottom.
Style: Fear & Hunger (2018 RPG) map character sprite — small painted illustration, soft painterly 3-4 tone shading,
dark brown 1px outline and dark inner contour lines, desaturated grim medieval dark fantasy, light from top-left. Not chibi, not clean pixel art, not cartoon.
Proportions: head (with hair) about 1/3 of body height, short thick limbs, slightly hunched, shoulders slumped,
elbows slightly bent so hands hang in front of the thighs, feet almost together. Side walk: big stride, rear heel lifted high, arms swinging opposite.
Face: narrow carved face tapering to the chin, NO nose, NO mouth, NO ears, no lines on the jaw; eyes are dark shadowy sockets under the bangs (no dot eyes, no round rims).
Side view turned slightly toward the viewer so the face shows; face not too dark.
CHARACTER: [아래 둘 중 하나를 붙인다]
```

인간 탐험가:
```
Human explorer, about 84 px tall. Tidy shaggy chin-length dark brown hair (#3a2a1e) made of ~20 thick even locks with slightly ragged tips,
bangs down to the eyes, sides covering the cheeks (not a helmet shape, not messy spikes). Skin #c49a78.
Linen shirt #b8a888 with sleeves rolled to the elbows, leather vest #5a3e28, short hooded shoulder mantle #5a3028 with the hood down behind the neck,
leather bracers #4a3424, belt #2e2018 with a pouch and a dagger hilt, trousers #4a4236, leather boots #3a2a1e. No weapon in hand, no armor.
```

바바리안:
```
Barbarian, about 92 px tall, broader and bulkier than a human. Long center-parted dark brown hair (#4a2e1c) past the shoulders with two braids,
thick shaggy beard of the same color, forehead visible. Skin #b88866. Bare chest and bare arms under an open leather vest #6a4a30,
ragged fur shoulder mantle #6e5e4a, iron armbands #6a5a3a on the upper arms, leather bracers #3e2c1c, belt #3a2818 with a pouch,
trousers #5a4430 with cloth-wrapped shins #8a7a60, fur-trimmed boots #4a3424 (fur #7a6a54). No weapon in hand.
```

받은 뒤: 배경을 투명으로 지우고, 칸을 72×108에 맞춰 발 기준선을 정렬한 뒤 `assets/actors/<종족>.webp`(무손실)로 저장한다.

---

## [B] 코드로 그리는 AI용 (이 저장소를 받은 코딩 AI)

```
이 저장소(Godot 4.7.2 프로젝트 "던전 앤 스톤")에서 탐험 맵 플레이어 그림을 다시 만든다.
1. CLAUDE.md, docs/ART.md, docs/ASSUMPTIONS.md AM27, 그리고 이 문서의 [공통 명세]를 읽는다.
2. 그림은 tools/paint_actors.gd가 만든다(전투 그림과 같은 3D 점토 몸 tools/monster_art/{Back,Party,BackHair,BackKit,Render}.gd →
   맵 키의 2배(168px)로 그려 반으로 줄이고 대비·안쪽 선·바깥선). 비율·자세·얼굴·머리 값은 paint_actors.gd 맨 위 상수다.
3. 다시 그리기: godot --headless --path . --script res://tools/paint_actors.gd -- --only=human,barbarian
   시험(게임 그림을 건드리지 않음): ... -- --only=human --out=<폴더> --set=head=2.5,legs=0.68
4. 확인: godot --headless --path . --import 후
   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --path . res://tools/screenshot.tscn -- --screen=explore --seed=1 --race=barbarian --out=<png>
   로 게임 화면을 찍어 [공통 명세]의 검수 기준으로 직접 본다(헤드리스 테스트는 그림을 검증하지 못한다).
5. 전투 화면 그림(assets/party, assets/monsters)은 바뀌면 안 된다 — 새 값은 맵 그림에서만 켠다.
6. 끝나면 GODOT=<godot> bash tools/check.sh → "모든 검증 통과", PROGRESS·ASSUMPTIONS AM27 갱신, 한국어 커밋.
```
