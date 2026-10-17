# ComfyUI 프롬프트 — 게임 그림 84장 교체용

지금 게임 그림은 모두 코드(그림 도구)가 그렸다(`docs/ART.md`). 이 문서는 그 그림을 ComfyUI로 다시 그릴 때 쓰는 프롬프트 모음이다.
대상: 몬스터 정면 52 · 아군(탐험가 4 + 소환수 뒷모습 6) · 도시(하늘·배경 7, 건물 6, 실내 6, 차원광장 1).
**범위 밖**: 탐험 화면의 캐릭터·몬스터·바닥·벽과 아이템 아이콘(`ItemIconPainter`)은 그림 파일이 아니라 실행 중에 코드로 그린다. (탐험 맵은 그림 파일로 바꾸는 작업 중 — 교체 규격은 아래 §0-B, 프롬프트는 그림이 생긴 뒤 추가)

---

## 0. 먼저 읽을 것 (교체 규칙)

1. **파일 경로와 이름은 그대로** 덮어쓴다(WebP, 투명 배경 RGBA). 경로는 각 항목 제목에 있다.
2. **최종 크기는 지금 그림과 같게** 맞춘다(각 항목의 "최종"). 몬스터·아군은 투명 여백을 잘라 내고(발 = 그림 아래 끝) 그 크기로 줄인다.
   - 몬스터 크기가 바뀌면 `assets/monsters/index.json`의 몸 높이(발~정수리 px)도 고쳐야 무대 키가 맞는다. 같은 크기로 맞추면 고칠 것이 없다.
   - **`paint_monsters.gd`·`paint_city.gd`를 다시 돌리면 교체한 그림을 덮어쓴다.** 교체한 뒤로는 돌리지 않는다(`--only=`로 필요한 것만).
3. 넣은 뒤: `godot --headless --path . --import` → 캡처로 확인(`docs/ART.md` §4). 웹 용량을 위해 WebP 품질 80~90.
4. **투명 배경 만들기**: 단색 배경(짙은 회색)으로 그린 뒤 배경 제거 노드(BiRefNet·RMBG 2.0 등)를 쓴다. 털·연기·안개 가장자리는 마스크를 조금 부드럽게(feather 1~2px) 한다. 하늘(`sky*`)과 실내는 투명할 필요가 없다.
5. **구도를 지키는 가장 쉬운 방법**: 지금 그림을 ControlNet(Lineart·Depth·Canny, 강도 0.4~0.6)이나 img2img(denoise 0.55~0.7)로 넣는다. 자세·비율·발 위치·건물 크기·광장 고리 자리가 게임 배치와 맞는다. 특히 **거리(street)·차원광장·건물은 꼭 이렇게** 한다(위치가 코드 좌표와 맞물려 있다).
6. **그림체 통일**: 체크포인트·LoRA·샘플러·CFG를 처음부터 끝까지 하나로 고정한다. 마음에 드는 그림 1~2장이 나오면 IPAdapter(style 전용, weight 0.4~0.6)의 참고 그림으로 걸고 나머지를 뽑는다.
7. 프롬프트는 영어로 쓴다(모델이 영어로 학습됨). **공통 스타일 앞부분 + 항목별 내용** 순서로 붙인다. Flux는 부정 프롬프트를 무시하므로, Flux에서는 피하고 싶은 것을 긍정문으로 바꿔 넣는다("plain dark gray background, single figure").
8. 생성 해상도(SDXL 기준): 세로 긴 것 832×1216 또는 768×1344 · 정사각 1024×1024 · 가로 1216×832 / 1344×768. 그린 뒤 줄인다.

### 0-B. 탐험 맵 그림 교체 규격 (`docs/PROMPT_ART_MAP.md` A2~A5 — 1층 재질 5장은 A2에서 생김)

1. **경로**: `assets/floor/<장소>/<재질>.webp`(예: `assets/floor/f1/limestone.webp`). 어느 타일이 어느 파일을 쓰는지는 `data/tiles.json`이 정한다 — 파일만 같은 이름으로 덮어쓰면 바로 바뀐다.
2. **바닥 아틀라스**: 한 줄에 변형 6~8칸(짝수), 칸 = 정사각형 64px(바닥 칸 32px × `render.json view.art_scale` 2), 칸 사이 여백 없음, 칸 순서 = 변형 번호. 칸끼리 이어 붙여도 이음매가 안 보이게(타일링) 그린다.
3. **벽**: 윗면 칸 줄(64×64) + 앞면 조각 줄(64×48 — 앞면 24px × 2). 앞면 맨 위 몇 px는 윗면과 만나는 턱, 아래 끝은 바닥 접점. 앞면 앵커 = 조각 아래 끝(바닥 접점).
4. **소품·데칼**: 투명 RGBA 시트. 데칼 `decals.webp` = 줄마다 종류(층 JSON `art.decor.kinds` 순서), 칸마다 변형, 칸 64×64 — 물가는 그림 위쪽이 물 쪽. 소품 `props.webp` = 가로 8칸 × 96×96(1.5칸), 칸 번호 = `tools/floor_art/Props.gd ORDER`, 누운 것은 칸 높이 72% 근처가 바닥 가운데. 그림자는 그림에 포함.
5. **밝기**: 중립 밝기로 칠한다(조명은 게임이 곱한다). 그림 평균 색이 그 타일의 `data/tiles.json colors` 값과 비슷해야 화면 밝기가 맞는다. 수정·버섯·광물 같은 스스로 빛나는 것만 밝게. 무손실 WebP 권장(이음매).
6. 넣은 뒤 `--import` → `tools/shots/floor1.json` 일괄 캡처로 확인. 테스트(`test_floor_art.test_atlas_sizes`)와 데이터 검사가 파일 존재·아틀라스 크기·칸 수를 본다.
7. `tools/paint_floor.gd`를 다시 돌리면 교체한 그림을 덮어쓴다(`--only=`로 필요한 것만).

---

## 1. 공통 스타일

### 1-A. 몬스터·아군 (전투 그림)

긍정(앞에 붙임):
```
dark hand-painted horror RPG battle illustration, single creature, full body visible from head to feet, standing on the ground, feet touching the bottom edge, grim desaturated muddy palette, earthy browns and sickly grays, heavy reddish-brown shadows, light from the upper left, rough uneven ink outlines, cross-hatching pen strokes in the shadows, visible brush texture, grime, dried blood stains, gothic dark fantasy, grotesque, plain flat dark gray background
```
부정:
```
anime, manga, chibi, cute, kawaii, 3d render, cgi, octane, photo, photorealistic, pixel art, vector art, cel shading, flat colors, smooth airbrush gradient, glossy plastic, oversaturated, neon, vibrant colors, text, letters, watermark, signature, logo, frame, border, multiple characters, crowd, cropped, cut off feet, out of frame, scenery background, floor tiles, dynamic action pose, jumping, blurry, lowres, jpeg artifacts, deformed hands, extra limbs, extra heads
```
- 모습은 피어 앤 헝거 몬스터 그림처럼: **넓은 보폭, 체중 실은 다리, 팔은 몸 옆에 늘어뜨림**(치켜들거나 크게 벌리지 않는다 — 사용자 결정). 네발짐승은 다가오는 3/4 정면.
- 보스 등급(수호자·중간 보스·계층군주·변종 수호자)은 앞부분에 `imposing, overwhelming presence, towering`를 더한다.

### 1-B. 도시 (거리·건물·실내·광장)

긍정:
```
dark hand-painted illustration of an early-modern gothic European city like old Prague, oppressive gloom, desaturated colors with greenish-brown shadows and yellow-green highlights, only warm lantern and window light stands out, rough wobbly ink outlines, pen hatching under eaves and ledges, grime streaks running down the walls, painterly brush texture, film grain
```
부정:
```
anime, cartoon, cute, 3d render, cgi, photo, pixel art, vector, clean lines, bright colors, saturated, neon, modern buildings, cars, text, letters, signage text, watermark, signature, frame, border, blurry, lowres, tilted perspective, fisheye
```

---

## 2. 몬스터 정면 52장 — `assets/monsters/<id>.webp`

몸은 정면(사람형)이나 다가오는 3/4 정면(짐승)이다. 각 항목은 "1-A 앞부분 + 아래 내용"이다. 크기 = 지금 그림 px(가로×세로).

### 1층 필드 · 묘지·시체
**deadman** 데드맨 — 최종 312×543 · 생성 768×1344
```
a walking corpse, emaciated gaunt dead man, pale yellow-gray skin mottled with dark bruise-purple patches, ragged black hair, screaming open mouth, pale dead eyes, clawed fingers, slightly hunched, one arm hanging and the other held a little away from the body, only a torn brown loincloth, smeared with fresh blood
```
**soldier_deadman** 병사 데드맨 — 352×598 · 768×1344
```
undead soldier corpse, gaunt pale gray face with an open mouth, dented iron kettle helmet, torn dark olive tunic, leather belt, worn brown boots, holding an old wooden spear upright in one hand and a battered round wooden shield in the other, arms lowered
```
**deadman_commander** 지휘관 데드맨 — 386×608 · 768×1344
```
undead commander corpse, gaunt pale face with a furious glare and shut mouth, dark gray iron plate armor on chest, shoulders and legs, long tattered dark blood-red cape, leather belt, holding a longsword pointing down, arms at the sides
```
**buried_one** 배리드언 — 335×521 · 768×1344
```
a corpse that has just clawed its way out of a grave, skin caked with dirt and earth-brown mottling, heavy grime, ragged hair, deeply hunched with bent knees, long hooked claws, one arm reaching forward low, loose rotten cloth strips wrapped around the limbs, loincloth
```
**mummy** 머미 — 307×568 · 768×1344
```
mummy, the whole body and head tightly wrapped in yellowed dirty linen bandages, uneven overlapping strips, dark empty eye slits, thin limbs, arms hanging at the sides, stained linen loincloth
```
**corpse_golem** 시체골렘 (중간 보스) — 500×566 · 1024×1024
```
corpse golem, huge obese flesh golem stitched together from many corpses, crude sewn seams and lumpy tumors, pale reddish-gray dead skin, small gaunt head thrust forward on the neck with an open mouth, ragged dark hair, very long hanging arms, holding a huge butcher cleaver, loincloth and belt, covered in blood
```
**skeleton_archer** 스켈레톤 아처 — 300×584 · 768×1344
```
skeleton archer, bare yellowed bones, grinning skull, holding a short wooden bow in the left hand down at the side, tattered dark loincloth and leather belt
```
**skeleton_mage** 스켈레톤 메이지 — 320×696 · 768×1344
```
skeleton mage, grinning skull face lit from within a deep dusty purple hood, long tattered dark violet robe, bony hands, holding a dark wooden staff topped with a glowing pale violet orb
```
**bone_knight** 본 나이트 — 459×660 · 832×1216
```
bone knight, tall skeleton warrior, skull with short curved horns, gray iron pauldrons and leg plates, belt, dark ragged cape, holding a long greatsword pointing down and a metal kite shield
```
**skull_rat** 스컬 랫 — 228×182 · 1216×832 (작게 줄임)
```
skull rat, a large rat whose head is an oversized bare skull, glowing orange eyes inside the sockets, mangy dark brown fur, long thin naked tail, low to the ground, front three-quarter view
```
**ghoul** 구울 — 260×220 · 1216×832
```
ghoul crawling on all fours toward the viewer, emaciated pale gray-green body, head held low, bony raised shoulders and arched spine, long thin arms planted forward with hooked claws, legs splayed out behind, blood on the hands and mouth, very low to the ground
```
**elder_ghoul** 엘더 구울 — 299×252 · 1216×832
```
elder ghoul crawling on all fours toward the viewer, larger and darker moss-green emaciated body, ragged black hair hanging over the face, faintly glowing pale eyes, bony arched back, long arms with hooked claws planted forward, heavily blood-stained
```
**ghoul_lord** 구울로드 — 327×275 · 1216×832
```
ghoul lord crawling on all fours toward the viewer, bulky dark olive ghoul, tarnished gold crown, two short dark horns, glowing orange-red eyes, long clawed arms planted forward, drenched in blood
```

### 핏빛성채
**banshee** 벤시 — 318×569 · 768×1344
```
banshee, ghostly translucent woman, pale blue-white skin, very long white hair, glowing white eyes, screaming mouth, tattered flowing blue-gray robe that fades into mist at the bottom, one arm held out, half transparent
```
**gargoyle_statue** 가고일 석상 — 563×540 · 1024×1024
```
living gargoyle statue, weathered gray stone demon crouching low with bent knees, short horns, pointed ears, fanged mouth, faintly glowing amber eyes, stone bat wings half spread, clawed stone hands, green moss stains and cracks
```
**deathfiend** 데스핀드 — 713×643 · 1024×1024
```
deathfiend demon, muscular dusky purple-gray body, curved black horns, glowing red eyes, fanged mouth, pointed ears, large dark leathery bat wings spread behind, long claws, dark loincloth, blood splatter
```
**kambormir** 뱀파이어 공작 캠보르미어 (변종 수호자) — 257×617 · 768×1344
```
Duke Kambormir, aristocratic vampire, tall and thin, pale lavender-white skin, slicked-back black hair, glowing red eyes, fangs, pointed ears, cold angry stare, long black high-collared coat with a tarnished gold collar, dark crimson cape, black boots, one clawed hand resting, elegant but monstrous
```
**blater** 저주받은 기사 블라터 (수호자) — 469×728 · 832×1216
```
Blater the cursed knight, dark maroon-black plate armor, horned helmet with glowing red eyes behind the visor, tattered blood-red cape, holding a dark greatsword at rest, dried blood on the armor
```
**corpse_golem** — 위 "묘지·시체" 참고 (핏빛성채 중간 보스).

### 빙하굴
**frost_wolf** 서리 늑대 — 295×319 · 1024×1024
```
frost wolf approaching in front three-quarter view, head low, thick pale white-gray fur with icy blue shadows, frost crystals clinging to the fur, glowing pale blue eyes
```
**ice_orc_warrior** 아이스 오크 전사 — 455×613 · 832×1216
```
ice orc warrior, muscular pale blue-gray skinned orc with tusks and pointed ears, white fur mantle over the shoulders, gray loincloth, leather belt, boots, holding a steel-blue battle axe low
```
**ice_orc_shaman** 아이스 오크 주술사 — 381×708 · 768×1344
```
ice orc shaman, blue-skinned orc with tusks and pointed ears, long dark slate-blue robe, white fur collar, holding a pale bone staff topped with a glowing icy blue orb, other hand clawed at the side
```
**yeti** 예티 (정예) — 289×556 · 768×1344
```
yeti, tall hunched ape-like beast covered in long shaggy white fur, screaming ape face, long heavy arms hanging down, clawed hands and feet
```
**katumba** 설원의 군주 카툼바 (중간 보스) — 496×631 · 832×1216
```
Katumba, lord of the snowfield, giant hunched yeti, very long pure white shaggy fur with pale blue shadows, glowing icy blue eyes, screaming ape mouth, ice crystals growing from the shoulders and back, frost-covered, holding a huge frozen wooden club down at the side
```
**owlbear** 아울베어 — 364×345 · 1024×1024
```
owlbear, massive bulky bear body covered in brown-gray feathery fur, owl head with huge round amber-yellow eyes and a hooked beak, short tail, heavy paws, front three-quarter view
```
**sabertooth** 샤벨 타이거 — 294×316 · 1024×1024
```
sabertooth tiger approaching in front three-quarter view, pale cream short-haired big cat with dark brown stripes, long saber fangs, yellow eyes, thin tail
```
**wormstone** 웜스톤 — 340×504 · 832×1216
```
wormstone, giant rock worm rising out of the ground in an S-curve, body made of rough gray stone segments, a round open maw ringed with jagged teeth facing the viewer
```
**ice_golem** 아이스 골렘 — 358×611 · 768×1344
```
ice golem, heavy blocky humanoid made of translucent pale blue ice, frost and crystal shards on the shoulders, square block head with glowing white eyes, massive fists hanging down
```
**tarunbas** 폭군 타룬바스 (수호자) — 488×729 · 832×1216
```
Tarunbas the tyrant, huge skeleton king, oversized skull with a tarnished gold crown, glowing red eye sockets, heavy bronze-brown shoulder armor, dark purple cape and loincloth, a massive greatsword resting at his side
```
**kirdui** 타락한 짐승 키르뒤 (변종 수호자) — 429×716 · 768×1344
```
Kirdui the corrupted beast, huge hunched charcoal-black demon brute, long thick black horns, glowing red eyes, fanged maw, black spikes along the shoulders and arms, lumpy corrupted flesh with purple veins, very long arms hanging down with huge claws, dark loincloth, blood
```

### 녹색 탄광
**goblin** 고블린 — 261×462 · 768×1344
```
small goblin, skinny green skin, big head, long pointed ears, wide toothy grin, yellow eyes, hunched, clawed hands, holding a rusty dagger low, only a brown loincloth
```
**goblin_archer** 고블린 궁수 — 265×470 · 768×1344
```
goblin archer, skinny green goblin, long pointed ears, holding a short bow at the side, tattered brown shirt, loincloth
```
**goblin_swordsman** 고블린 검사 — 343×495 · 768×1344
```
goblin swordsman, green goblin of sturdier build, long pointed ears, grin, brown tunic with belt, holding a short sword and a round wooden shield
```
**goblin_miner** 고블린 광부 — 311×491 · 768×1344
```
goblin miner, green goblin with long ears, worn leather miner's cap, brown work shirt, holding a pickaxe down at the side
```
**hobgoblin_miner** 홉고블린 광부 — 441×588 · 832×1216
```
hobgoblin miner, larger muscular dark green hobgoblin, fanged mouth, pointed ears, leather cap, leather straps across the bare chest, belt, loincloth, holding a heavy pickaxe
```
**goblin_bomber** 고블린 폭탄병 (중간 보스) — 297×560 · 768×1344
```
goblin bomber, fat pot-bellied rust-orange goblin, long ears, wicked grin, leather straps across the chest with four round black bombs hanging from them, holding one bomb in the hand, belt, loincloth
```
**slime** 슬라임 — 335×196 · 1216×832
```
slime, small translucent green jelly blob, round dome with drooping edges spreading on the floor, a small bone faintly visible inside, glossy highlights, two tiny dot eyes
```
**mineral_slime** 광물 슬라임 — 356×222 · 1216×832
```
mineral slime, murky gray-green jelly blob with pale mint crystal shards growing out of it, chunks of ore inside, drooping edges
```
**king_slime** 킹 슬라임 (수호자) — 537×353 · 1216×832
```
king slime, huge translucent green jelly blob, small spiky golden crown on top, several bones and skulls visible inside, drooping edges spreading on the floor, glossy highlights
```
**gnome** 노움 — 266×169 · 1216×832
```
gnome earth spirit, a low lumpy mound of brown earth and stones with patches of moss, small face with glowing warm yellow eyes, tiny root-like arms
```
**corrupted_gnome** 타락한 노움 — 264×166 · 1216×832
```
corrupted gnome, a low mound of dark rotten earth and stone, pulsing purple-red veins across it, glowing red eyes, root-like arms
```
**copper_golem** 코퍼 골렘 — 353×612 · 768×1344
```
copper golem, heavy blocky humanoid of hammered copper plates with green verdigris patina, riveted lumpy body, square block head with glowing cyan eyes, massive fists hanging down
```

### 강철의 묘
**iron_lizardman** 아이언 리자드맨 — 353×606 · 768×1344
```
iron lizardman, muscular green-gray lizard warrior, reptile head with fangs, yellow slit eyes, scaled skin, long tail, iron chest plate and pauldrons, loincloth, holding a spear upright
```
**iron_cavalry** 철기병 — 354×687 · 768×1344
```
iron cavalry knight standing on foot, full steel plate armor, closed helmet with a dark red plume, dark brown cape, holding a long lance upright and a metal kite shield
```
**guardian_eye** 수호자의 눈 — 347×340 · 1024×1024
```
guardian eye, giant bloodshot eyeball with a yellow-olive iris, set in a fleshy reddish base, several limp tentacles hanging beneath, floating
```
**riddle_gatekeeper** 수수께끼 문지기 — 383×760 · 768×1344
```
riddle gatekeeper, tall stone statue of a robed guardian, gray stone body, plain block-shaped head with glowing pale eyes, long stone robe, holding a stone staff topped with a soft cream light, other arm across the chest
```
**ildium** 철인 일디움 (수호자) — 538×722 · 832×1216
```
Ildium the iron man, giant iron colossus in full dark steel plate armor, closed great helm with a glowing orange eye slit, enormously broad shoulders, holding a huge greatsword pointing down
```

### 계층군주
**dreadfear** 드레드피어 — 1291×793 · 1344×832 (몸 높이 = 그림 높이 × 0.8)
```
Dreadfear the floor lord, a colossal upper body filling the whole frame, no legs, the lower body dissolving into black smoke, a thick ring of shaggy brown fur around the neck and shoulders, several crow heads with long curved beaks and one glowing eye each sprouting from the fur collar, a small pale face with the eyes covered by a cloth blindfold, huge curled ram horns rising high above, a second face with glowing eyes and bared teeth embedded in the chest and belly, enormous red bat wings spread wide behind, long thick arms hanging down to the ground, golden ochre flesh with deep magenta shadows, imposing, overwhelming presence
```
**dreadfear_maggot** 드레드피어의 구더기 — 229×157 · 1216×832
```
giant pale cream maggot curled into a C shape, soft segmented body, tiny dark head with mandibles, side view, low to the ground
```

### 네발짐승 (칼날늑대 계열 · 키메라)
**blade_wolf** 칼날늑대 — 295×381 · 832×1216
```
blade wolf approaching in front three-quarter view, head low, large shaggy gray wolf, a row of steel blade-like spikes growing along the spine, yellow eyes
```
**blood_blade_wolf** 핏빛 칼날늑대 — 295×381 · 832×1216
```
blood blade wolf approaching in front three-quarter view, head low, reddish-brown shaggy wolf, blood-red bone blades along the spine, glowing red eyes, blood-soaked fur
```
**giant_blade_wolf** 거대 칼날늑대 — 346×443 · 832×1216
```
giant blade wolf approaching in front three-quarter view, huge bulky dark gray wolf, long steel blades along the back, yellow eyes
```
**chimera_wolf** 키메라 울프 — 298×418 · 832×1216
```
chimera wolf approaching in front three-quarter view, brown wolf with two dark curved horns, glowing orange eyes, a green snake for a tail rising over its back
```

---

## 3. 아군 — 뒷모습·옆모습

전투에서 아군은 화면 아래쪽에 **등을 보이고 적(화면 위쪽 안)을 바라본다.** 무릎 위만 보일 만큼 아래로 가라앉으니, 상반신이 특히 중요하다.
"1-A 앞부분"에서 `standing on the ground, feet touching the bottom edge`는 그대로 두고 아래를 붙인다.
- **탐험가는 장비·레벨과 상관없이 늘 이 모습이다.** 무기를 들지 않는다. 너무 허름하지도 차려입지도 않은 옷(사용자 결정).
- 같은 인물의 뒷모습·옆모습이 같아 보이게: 뒷모습을 먼저 뽑고 그 그림을 IPAdapter(weight 0.6~0.8)로 걸어 옆모습을 뽑는다. 아니면 `character turnaround sheet, back view and rear three-quarter view`로 한 장에 둘을 그려 자른다.
- 옆모습 = 뒤에서 본 3/4: 몸을 오른쪽으로 약 60° 돌려 오른쪽(적)을 본다. 등·오른 옆구리·오른쪽 옆얼굴이 보인다. 화면 오른쪽 자리는 게임이 좌우를 뒤집어 쓴다.

**party/human_back.webp** 인간 뒷모습 — 최종 229×555 · 768×1344
```
seen from directly behind, back view, a male human explorer standing upright, arms relaxed close to the body, short brown hair, rolled-up linen shirt sleeves, brown leather vest, short dark red-brown shoulder mantle with a hood hanging down the back, belt with a pouch and a sheathed knife, brown trousers, leather boots, no weapon, practical adventurer clothing, neither ragged nor fancy
```
**party/human_side.webp** 인간 옆모습 — 173×554 · 768×1344
```
rear three-quarter view, the same male human explorer turned toward the right, we see his back, right side and right cheek in profile, arms held close against the body, short brown hair, rolled-up linen shirt, brown leather vest, short dark red-brown hooded shoulder mantle, belt with pouch and knife, brown trousers, leather boots, no weapon
```
**party/barbarian_back.webp** 바바리안 뒷모습 — 283×631 · 768×1344 (인간보다 1.14배 크게 — 최종 키를 지킨다)
```
seen from directly behind, back view, a huge broad-shouldered muscular male barbarian, long dark brown hair woven into two thick braids, beard visible at the sides, thick shaggy fur pelt over the shoulders, bare muscular arms with iron bands on the upper arms and leather bracers, leather vest, belt, trousers with cloth-wrapped calves, fur-trimmed boots, no weapon, tribal but practical
```
**party/barbarian_side.webp** 바바리안 옆모습 — 238×631 · 768×1344
```
rear three-quarter view, the same huge muscular male barbarian turned toward the right, we see his back, right side and bearded right profile, arms held close against the body, two long dark braids, thick fur shoulder pelt, bare arms with iron armbands and leather bracers, leather vest, wrapped calves, fur-trimmed boots, no weapon
```

### 소환수 뒷모습 — `assets/monsters/<id>_back.webp`
정면 그림(같은 id)을 IPAdapter 참고로 걸고, 앞에 `seen from behind, back view, facing away from the viewer` 을 붙인다.

**soldier_deadman_back** — 302×627 · 768×1344
```
seen from behind, back view, undead soldier corpse, dented iron kettle helmet, torn dark olive tunic, belt, worn boots, wooden spear held upright in one hand, round wooden shield strapped on the other arm, gaunt gray skin on the neck and arms
```
**mummy_back** — 234×559 · 768×1344
```
seen from behind, back view, mummy wrapped head to toe in yellowed dirty linen bandages, loose strip ends hanging, thin limbs, arms at the sides
```
**iron_cavalry_back** — 347×764 · 768×1344
```
seen from behind, back view, iron cavalry knight on foot, steel plate armor, closed helmet with a dark red plume, long dark brown cape covering the back, long lance held upright, kite shield on the arm
```
**ghoul_back** — 260×266 · 1024×1024
```
seen from behind, back view, ghoul crawling away on all fours, emaciated pale gray-green body, knobby spine and raised shoulder blades, long thin arms planted ahead, legs splayed, blood smears
```
**elder_ghoul_back** — 298×306 · 1024×1024
```
seen from behind, back view, elder ghoul crawling away on all fours, larger dark moss-green emaciated body, ragged black hair, knobby arched spine, long clawed arms planted ahead, heavy blood stains
```
**slime_back** — 335×196 · 1216×832
```
seen from behind, small translucent green jelly blob, round dome with drooping edges spreading on the floor, glossy highlights, no face
```

---

## 4. 도시

거리 화면은 레이어를 겹친다(뒤 → 앞): 하늘(화면 고정) · 원경(0.2배 스크롤) · 중경(0.5배) · 안개 띠 · 거리(1배) · 시설 건물 · 비네트.
게임은 그림을 **2배로 키워** 그린다(sky·far·mid·haze·vignette의 `scale 2`). 그래서 그림 자체는 작고 흐려도 된다.
배경은 **흐리고, 채도·대비가 낮고, 안개색에 묻히고, 선이 가늘게**, 시설 건물은 **선명하고 굵은 윤곽과 따뜻한 창빛**으로 그려 둘이 구분돼야 한다.

### 4-1. 하늘·배경 레이어 — `assets/city/layers/`
**sky.webp** 밤하늘(기본) — 640×360(RGB, 투명 아님) · 1344×768
```
overcast night sky over a gothic city, layered murky green-gray clouds, a pale sickly yellow-green full moon glowing through the clouds upper right of center, a few tiny black birds, the lower half fading into a thick yellowish-olive haze, no buildings, no ground, soft and blurry
```
**sky_clear.webp** 맑은 날 — 640×360(RGB) · 1344×768
```
clear daytime sky, washed-out pale blue at the top fading into creamy yellow haze toward the bottom, a hazy pale sun upper left, a few soft white clouds, tiny distant birds, no buildings, no ground, soft and grainy
```
**far.webp** 원경 — 1005×240(투명) · 1536×640에서 가로로 잘라 줄임
```
distant city skyline silhouette in flat side view, a hill crowned by a castle fortress, a twin-spired gothic cathedral, a sea of pointed roofs and towers, thin chimney smoke, a few tiny lit windows, very low contrast, foggy, gray-green, blurry, empty sky above (plain background)
```
**mid.webp** 중경 — 1237×250(투명) · 1536×640에서 잘라 줄임
```
a continuous row of narrow gothic townhouses in flat side elevation, every house different: stepped gables, pointed gables, rounded gables, gray-green plaster and dark brick walls, slate roofs, chimneys, small warm lit windows scattered, foggy and muted, thin ink lines, empty sky above (plain background)
```
- 원경·중경은 가로로 긴 띠라서 한 번에 안 된다: 가로 1536으로 2~3장 뽑아 아웃페인팅으로 이어 붙이거나, 지금 그림을 ControlNet으로 넣어 타일별로 그린다.

**street.webp** 거리 — 3246×720(투명) · 지금 그림을 ControlNet(Lineart/Canny)으로, 가로 1344짜리 타일 3~4장(겹침 15%)
```
flat side view of a gothic city street at night, cobblestone road along the bottom, a raised stone sidewalk, short sections of low rubble-stone wall topped with wrought-iron railings, iron street lamps with small warm flames, bare dead trees, a well, a notice board, a wooden cart, empty sky above (plain background)
```
- **돌담 사이 빈칸이 시설 건물 자리다**(`data/facilities`의 x 좌표). 빈칸 위치와 너비가 바뀌면 건물이 돌담과 겹친다 — 반드시 지금 그림을 구도 기준으로 쓴다.

**haze.webp**(안개 띠 1430×130)·**vignette.webp**(가장자리 어둡게 640×360)는 반투명 그러데이션이라 AI로 그려도 나아지는 점이 없다. **지금 것을 그대로 두는 것을 권한다.** 굳이 바꾸려면: haze = `soft horizontal band of gray-green fog, wispy, transparent edges`, vignette = 검은 원형 그러데이션(이미지 편집기로 만드는 편이 정확하다).

### 4-2. 시설 건물 6채 — `assets/city/buildings/<id>.webp` (투명)
**같은 문법**: 짙은 마름돌 기단, 같은 창틀(마름돌 테 + 짙은 창살 + 창턱), 같은 쇠 걸이 간판, 같은 등롱, 점판암 지붕(신전·훈련장만 붉은 기와). **정면 입면도**(원근 거의 없음), 땅에 닿는 아래 끝은 수평. 4-1보다 선이 굵고 선명하게, 창은 따뜻하게 빛난다.
공통 앞부분에 더함: `single building, straight-on front elevation, isolated on plain dark background, ground line at the bottom, crisp bold ink outline, warm glowing windows`

**inn.webp** 여관 — 560×470 · 1216×1024
```
a two-story half-timbered inn, timber-framed upper floor jutting out over a dark ashlar stone ground floor, slate roof with two dormer windows, a brick chimney with smoke, many warmly lit windows (the most of any building), a hanging iron sign with a tankard, wooden barrels by the door, arched wooden door
```
**library.webp** 도서관 — 440×520 · 896×1152
```
a library of pale dressed stone, tall pointed gothic windows, a gable with a round rose window, a large clock face on the facade, ivy climbing the walls, slate roof, a hanging iron sign with a book, tall arched double door
```
**temple.webp** 신전 — 430×600 · 832×1216
```
a stone temple, the tallest building, a slender bell tower with a pointed spire and a visible bell, a large stained-glass pointed window, buttresses, red tiled roof, a small sun emblem at the gable peak, candles at the entrance, tall arched door
```
**shop.webp** 상점 — 400×500 · 896×1152
```
a narrow tall merchant house, stepped gable, a wooden hoist beam with a pulley at the top, green shutters, a large display window on the ground floor with goods, a red-and-white striped awning, a hanging iron sign
```
**bank.webp** 은행 — 470×450 · 1024×1024
```
a symmetric bank of rough gray stone, triangular pediment with a key emblem, two stone columns flanking an arched door, iron bars on the windows, a round window in the pediment, heavy and fortified
```
**training.webp** 훈련장 — 600×400 · 1344×896
```
a training ground, a crenellated stone gatehouse with an open arched gate on the left, blood-red banners, a wooden barracks with a red tiled roof, a yard behind a wooden palisade with straw training dummies, crossed weapons sign
```

### 4-3. 시설 내부 6곳 — `assets/city/interiors/<id>.webp` (960×540, 생성 1344×768)
**정면에서 본 방**(한 점 투시, 뒷벽이 가운데), 촛불·등잔 빛만 밝고 나머지는 어둠. 시설 사람 한 명이 가운데 근처에 서 있다(직함만 — 원작 실명 인물 아님). 사람은 피어 앤 헝거 인물화풍: 거친 얼굴, 깊은 그늘, 두꺼운 바깥선.
공통 앞부분에 더함: `interior room seen straight on, one-point perspective, the back wall in the center, dim candlelight, deep darkness at the edges, one person`

**inn** 여관
```
a dark tavern interior with dark wooden plank walls, a stone fireplace with a fire on the back wall, a mantel with candles, shelves of bottles, stacked barrels, long wooden tables and benches in front, wall lanterns; the innkeeper, a woman in a rust-red dress with a cream apron and a green headscarf, standing by the fireplace, arms at her sides
```
**library** 도서관
```
a gloomy library interior, towering bookshelves full of old books on both sides, a tall pointed gothic window at the back, stone floor, a desk with an open book, a candle and a small skull; the librarian, an old bald man with a full white beard and round glasses in a dark green robe, holding a book behind the desk
```
**temple** 신전
```
a stone temple interior, gray stone block walls and pillars, an altar draped in red cloth at the back under a stained-glass niche with a pale saint statue, rows of candles on both sides, dark wooden pews; a priestess in a pale hooded robe with a red stole standing near the altar
```
**shop** 상점
```
a cramped shop interior, dark wooden walls with stains, shelves of colored bottles, jars and boxes behind a long wooden counter, brass scales and a few coins on the counter, a candle; the shopkeeper, a stout bald man with a mustache in a tan shirt and a leather apron, leaning on the counter with both hands
```
**bank** 은행
```
a bank interior, dark gray stone walls and two pillars, a huge round iron vault door on the back wall, a long dark counter with papers and coins, two small green-shaded lamps; a bank clerk, a woman with her hair in a bun, round glasses, a dark dress with a pale collar, standing behind the counter with hands on it
```
**training** 훈련장
```
an indoor training hall, dark wooden side walls, a rough fieldstone back wall with round red-and-white targets, hanging shields and a red banner, two straw training dummies, a few spears, wall torches, packed earth floor; the instructor, a muscular man with short black hair, stubble and a scar, bare arms, brown vest and belt, arms crossed
```

### 4-4. 차원광장 — `assets/city/plaza.webp` (1280×720, 투명 부분 있음 · 생성 1344×768, 지금 그림을 ControlNet Depth/Lineart로)
```
a grand circular stone plaza at dusk, one-point perspective, a semicircular colonnade of pale stone columns curving around the back with dark arched doorways, concentric and radial flagstone paving, a three-step round stone dais in the center, on it a huge upright stone ring made of thick carved blocks with a keystone on top, the inside of the ring is empty, two burning iron braziers on tripods left and right, tall flag poles with long dark red banners at both front edges, crates and barrels at the sides, a few explorers and guards in cloaks and armor standing at different depths, empty sky above the colonnade (plain background)
```
- **고리 안쪽과 회랑 위 하늘은 투명해야 한다.** 고리 안에는 게임이 포탈 효과(셰이더)를 그리고, 하늘에는 하늘 레이어·먼 첨탑이 비친다. 고리 위치·크기는 `render.json city.plaza` 좌표와 맞물려 있으니 지금 그림을 구도 기준으로 쓴다.

---

## 5. 넣는 순서 제안
1. 몬스터 1장(예: `goblin`)으로 체크포인트·LoRA·공통 프롬프트를 정한다 → 게임에 넣고 캡처로 무대 크기·바닥선을 확인한다.
2. 같은 설정으로 몬스터 52 → 아군 10(정면 그림을 참고로 소환수 뒷모습) → 건물·실내 → 거리·광장 순서로 진행한다.
3. 크기·자르기가 귀찮으면 말해 달라: 투명 여백 자르기 + 지금 크기로 맞추기 + `index.json` 몸 높이 다시 재기를 하는 가져오기 도구를 만들 수 있다.
