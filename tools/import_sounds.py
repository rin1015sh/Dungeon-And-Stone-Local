#!/usr/bin/env python3
"""사용자가 준 소리 파일(한글 제목 mp3)을 게임 소리로 들인다(2026-11-07, 사용자 "게임 전체에 소리 — 행동마다 맞는 소리, 겹쳐도 좋다").

  python3 tools/import_sounds.py <음원 폴더>     # assets/audio/<갈래>/<키>.ogg 만들기 + docs/AUDIO.md 표
  python3 tools/import_sounds.py --doc            # 표만 다시

- 변환: ffmpeg → ogg vorbis. 효과음 · 걸음은 모노, 효과음은 앞 무음 잘라 냄 · 소리 크기 맞춤(loudnorm), 걸음 · 분위기 · 음악은 스테레오 그대로 더 작게.
- 키 → 쓰는 곳은 data/audio.json(sfx · steps · ambience · bgm · on_message · combat · cries · ambience_cues)이 정한다.
  이 표(MAP)의 "쓰인 곳"은 사람이 보는 설명 — audio.json을 바꾸면 여기도 고친다.
- 쓰지 않는 파일(비 · 아스팔트 달리기 등)은 SKIP — 지금 게임에 비가 오지 않는다(사용자).
"""
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets/audio")
DOC = os.path.join(ROOT, "docs/AUDIO.md")

# 제목(파일 이름, 확장자 없이) → (갈래, 키, 쓰인 곳)
MAP = [
    # ── 전투: 타격 · 헛침 · 방어 ──
    ("검으로 베는 금속감", "sfx", "hit_slash", "전투 베기 피해(검 · 발톱 · 도끼)"),
    ("가벼운 검으로 베는 금속감", "sfx", "hit_slash_light", "전투 베기 피해(변형 — 번갈아)"),
    ("2연속검으로베는", "sfx", "hit_slash_double", "멀리서 다른 탐험가가 싸우는 소리(앞)"),
    ("대검으로베는", "sfx", "hit_heavy", "전투 치명타"),
    ("금속을떄리는", "sfx", "hit_metal", "전투 피해 0(막힘) · 면역 · 큰 몸짓 끊김(겹침), 멀리서 싸우는 소리(뒤)"),
    ("무거운펀치", "sfx", "hit_blunt_heavy", "전투 둔기 피해(몽둥이 · 주먹 · 몸통 박치기)"),
    ("펀치소리", "sfx", "hit_blunt", "전투 둔기 피해(변형)"),
    ("화살이박히는", "sfx", "hit_pierce", "전투 찌르기 · 화살 피해, 화살 함정"),
    ("슬라임을베는", "sfx", "hit_slime", "슬라임 · 기생충 계열을 칠 때 · 독 피해 · 슬라임 울음"),
    ("채찍으로공격", "sfx", "hit_whip", "꼬리 휘두르기 · 붕대 감기 · 휘감기 스킬을 쓸 때"),
    ("검이바람을가르는", "sfx", "miss", "전투 헛침(회피)"),
    ("검이바람을가르는가벼운", "sfx", "miss_light", "전투 헛침(변형)"),
    ("검이바람을가르는매우가벼운", "sfx", "whoosh_faint", "전투 헛침(변형) · Tab 가방 열기 · 도망침 · 정수가 흩어짐"),
    ("방패로방어", "sfx", "guard", "전투 방어 · 예고된 일격을 막아 냄"),
    ("털썩쓰러지는", "sfx", "body_fall", "전투에서 쓰러짐(적 · 아군)"),
    ("활시위를당기는", "sfx", "bow_draw", "활 · 투석 스킬을 쓸 때(앞)"),
    ("화살을쏘는", "sfx", "arrow_shot", "활 · 투석 스킬을 쓸 때(뒤 — 겹침), 화살 함정"),
    ("금속을베려는듯한", "sfx", "blade_draw", "큰 몸짓을 준비할 때 · 약탈자 외침 · 숨어 기다린 매복 선공"),
    ("뼈가꺽이는듯한", "sfx", "bone_snap", "큰 몸짓이 끊김 · 아귀 입 닫힘 · 기절 · 움직이지 못함"),
    # ── 전투: 마법 · 상태 ──
    ("파이어볼", "sfx", "fireball", "화염 피해 · 폭탄"),
    ("얼어가는", "sfx", "freeze", "냉기 피해 · 빙결 · 서리"),
    ("번개", "sfx", "lightning", "번개 피해"),
    ("바람마법", "sfx", "wind_magic", "실명 · 독 시전 · 샌드맨 울음 · 바위사막 분위기(가끔)"),
    ("중력마법2", "sfx", "gravity_magic", "어둠 피해 · 어둠 · 대지 마법 시전"),
    ("마법진을전개", "sfx", "magic_circle", "마법 스킬 시전 · 신성 · 무속성 피해 · 균열 열림 · 균열 들어감 · 정수 흡수(앞)"),
    ("날카롭게과거를회상하는듯한", "sfx", "memory_sting", "죽은 자의 기억(예고) · 수수께끼 답 · 기념비에 바침 · 군주를 부름"),
    ("공포를부추기는귀신이나타난듯한", "sfx", "fear_ghost", "공포 · 혼란 · 스며드는 공포에 걸림, 수수께끼 오답"),
    ("심장박동", "sfx", "heartbeat", "생명력 30% 아래 — 계속(고리)"),
    ("유리가깨지는", "sfx", "glass_break", "빙결에 갇힘 · 수정 · 광맥 · 조각상 깨뜨림 · 보호막이 받아 냄 · 칼날 부러짐"),
    # ── 전투 시작 · 끝 ──
    ("공포무언가나타난듯한", "sfx", "fear_appear", "전투 시작(맞닥뜨림)"),
    ("다가오는공포(근데갑자기끓김.다른효과음과이어져야할듯함)", "sfx", "dread_rise", "덮쳐 옴 · 잠결 습격 · 보스 등장(앞 — 뒤에 낮은 종소리로 이어짐)"),
    ("중저음북", "sfx", "war_drum", "큰 무리 전투 시작 · 고블린 뿔피리 · 다음 무리"),
    ("매우낮은종소리무언가일어난듯한", "sfx", "bell_low", "보스 등장(뒤) · 계층군주 소환 · 보스 페이즈 전환"),
    ("어두운효과음베토벤", "sfx", "dark_sting", "사망(심장 → 털썩 → 울림) · 계층군주 등장 · 레벨 하락"),
    ("숨막히는공포", "ambience", "dread_loop", "망자의 땅 분위기(낮게 계속)"),
    ("게임스킬획득", "sfx", "skill_get", "레벨 업 · 정수 흡수(뒤) · 첫 처치 · 수호자 · 군주 공적"),
    ("결정적인버튼", "sfx", "confirm_big", "전투 승리 · 캐릭터 만들기 완료"),
    # ── 몬스터 울음 ──
    ("사자의낮게그르렁거리는소리", "sfx", "growl_low", "늑대 · 짐승이 알아챔 · 짐승 울음(전투 시작) · 불카르 · 소굴 분위기"),
    ("사자의소리1", "sfx", "roar_1", "곰 · 웨어울프 · 키메라 울음"),
    ("사자의소리2", "sfx", "roar_2", "샤벨타이거 · 불카르 울음"),
    ("늑대가길게짖는", "sfx", "wolf_howl", "늑대 무리 울음 · 소굴 분위기"),
    ("울부짖는좀비", "sfx", "zombie_howl", "언데드가 알아챔 · 구울 · 데드맨 울음"),
    ("위협하는듯몬스터울음", "sfx", "monster_threat", "몬스터가 알아챔 · 소환 · 해골쥐"),
    ("중저음몬스터울음", "sfx", "monster_low", "골렘 · 거석병 · 트롤 · 예티 · 키르뒤 울음 · 수호자 광분 · 균열 분위기"),
    ("트림하는듯몬스터울음", "sfx", "monster_burp", "고블린 · 코볼트 · 노움 외침"),
    ("맷돼지울음소리", "sfx", "boar_cry", "두더지 · 여왕 · 홉고블린 울음"),
    ("맷돼지가 코를킁킁거리는", "sfx", "boar_sniff", "짐승의 소굴 분위기(가끔)"),
    ("말의울음소리", "sfx", "horse", "듀라한 · 철기병 울음"),
    ("몬스터날개펄럭", "sfx", "wing_flap", "가고일 · 날개 달린 것 울음"),
    ("날카롭고높은익룡울음", "sfx", "shriek_high", "노움 경보 · 밴시 울음"),
    ("화난익룡울음", "sfx", "shriek_angry", "고블린 폭탄광 · 원령 울음"),
    ("드래곤의긴울음소리", "sfx", "dragon_long", "데쓰웜이 솟음 · 계층군주 울음"),
    ("드래곤의짧은울음", "sfx", "dragon_short", "데쓰웜 · 샌드웜 울음"),
    ("불길한새가우는소리", "sfx", "crow", "망자의 땅 · 고블린 숲 분위기(가끔)"),
    # ── 탐험: 사건 · 장치 ──
    ("교회의종소리", "sfx", "church_bell", "망자의 땅 종 치기"),
    ("불길한종소리", "sfx", "bell_ominous", "밤 종 · 무덤에서 망자가 일어남 · 징조"),
    ("유적의돌드르륵열리는", "sfx", "stone_door", "돌문 · 지하 묘실 · 탑 열림(요소의 gate_open 소리)"),
    ("낡은문을여는", "sfx", "old_door", "도시 시설 문 들어가기"),
    ("문을여는", "sfx", "door_open", "도시 시설에서 나옴 · 균열에서 빠져나옴"),
    ("열쇠로문을여는", "sfx", "key_unlock", "균열 잠긴 출구를 열쇠로 엶"),
    ("철문을여는", "sfx", "iron_door_open", "망자의 땅 고개 쇠문이 열림"),
    ("철문을닫는", "sfx", "iron_door_close", "보스 방 창살 닫힘 · 덫 닫힘"),
    ("금속드르륵", "sfx", "metal_rattle", "함정 · 올가미를 찾고 풂 · 사슬 감긴 쇠문 · 덫 닫힘(뒤)"),
    ("바위가깨지는", "sfx", "rock_break", "무너짐 · 모래 진동 경고 · 함정을 짓뭉갬 · 석화 · 대지 피해 · 샌드웜 · 데쓰웜(겹침)"),
    ("수면에떠오르는", "sfx", "surface", "샌드웜이 솟음 · 데쓰웜이 가라앉음 · 무덤에서 망자가 일어남"),
    ("먹구름천둥소리mp3", "sfx", "thunder", "데쓰웜 모래 폭풍이 일어남"),
    ("바람고속이동", "sfx", "wind_rush", "바위사막 · 수정동굴 분위기(가끔) · 오후 모래 폭풍"),
    ("물방울이 떨어지는", "sfx", "water_drip", "수정동굴 · 균열 분위기(가끔)"),
    ("상자를여는", "sfx", "chest_open", "상자 · 은닉처 열기"),
    ("보물과돈이쏟아지는", "sfx", "treasure", "귀환 정산(마석 → 스톤)"),
    ("동전하나떨어지는", "sfx", "coin_drop", "동전 던지기 떨어짐 · 정산(뒤)"),
    ("매우가벼운카샤", "sfx", "item_pick", "아이템을 얻음(모든 획득) · 동전 던지기"),
    ("중간금속재킷", "sfx", "armor_rustle", "장비를 입음 · 갑옷 소리"),
    ("페이지를넘기는", "sfx", "page_turn", "도감(B) 열기"),
    ("남성의비명", "sfx", "scream_man", "멀리서 탐험가가 죽음 · 아군 쓰러짐"),
    ("젊은남성의긴비명", "sfx", "scream_young", "멀리서 탐험가가 죽음(변형) · 아군 쓰러짐(변형)"),
    ("여자의긴비명소리", "sfx", "scream_woman", "멀리서 탐험가가 죽음(변형)"),
    # ── 메뉴 ──
    ("버튼클릭가벼운금속", "sfx", "ui_move", "메뉴 커서 옮김"),
    ("버튼클릭짤그락금속", "sfx", "ui_click", "메뉴 고르기(Enter) · 타이틀 메뉴"),
    ("울리는듯한버튼결정소리", "sfx", "ui_confirm", "전투 행동을 정함"),
    ("내려가는중저음취소", "sfx", "ui_back", "메뉴 뒤로 · 창 닫기(Esc)"),
    ("실패취소된듯한버튼", "sfx", "ui_denied", "못 하는 행동"),
    # ── 걸음(고리 — 걷는 동안) ──
    ("흙위를걷는", "steps", "step_dirt", "흙 바닥 걸음(1층 · 망자의 땅 · 소굴)"),
    ("흙위를 달리는", "steps", "run_dirt", "흙 바닥 — 몬스터에게 쫓길 때"),
    ("잔디를걷는", "steps", "step_grass", "풀 · 묘지 흙 걸음"),
    ("키큰잔디를걷는", "steps", "step_tallgrass", "고블린 숲 걸음"),
    ("잔디밭을달리는", "steps", "run_grass", "풀 — 쫓길 때"),
    ("풀무리 를달리는", "steps", "run_tallgrass", "고블린 숲 — 쫓길 때"),
    ("자갈을걷는", "steps", "step_gravel", "자갈 · 잔해 · 사막 흙판 · 판석 걸음"),
    ("자갈위를달리는", "steps", "run_gravel", "자갈 — 쫓길 때"),
    ("눈위를걷는", "steps", "step_snow", "빙하굴 · 모래 바다 걸음"),
    ("눈위를달리는", "steps", "run_snow", "눈 · 모래 — 쫓길 때"),
    ("무릎까지잠긴물걷는", "steps", "step_water", "진창 · 얕은 물 걸음"),
    ("물첨벙거리는", "steps", "run_water", "물 — 쫓길 때"),
    ("아스팔트를걷는", "steps", "step_stone", "돌 바닥 걸음(핏빛성채 · 강철의 묘 · 판석 · 계단)"),
    ("아스팔트를걷는2", "steps", "step_stone2", "도시 동네 돌길 걸음"),
    ("아스팔트를달리는", "steps", "run_stone", "돌 바닥 — 쫓길 때"),
    ("가죽신으로걷는", "steps", "step_wood", "나무 바닥 · 다리 · 밧줄 · 도시 시설 실내 걸음"),
    ("가죽신으로 달리는", "steps", "run_wood", "나무 바닥 — 쫓길 때"),
    # ── 음악 ──
    ("한밤중불길한피아노", "bgm", "night_piano", "타이틀 · 도시 음악(이어서)"),
]
SKIP = {
    "도시에비가내리는mp3": "비가 오지 않는다(사용자)",
    "비젖은길을달리는": "비가 오지 않는다(사용자)",
}
LOUD = {"sfx": -16, "steps": -24, "ambience": -22, "bgm": -20}


def convert(src: str, kind: str, key: str) -> None:
    dst_dir = os.path.join(OUT, kind)
    os.makedirs(dst_dir, exist_ok=True)
    dst = os.path.join(dst_dir, key + ".ogg")
    af = []
    if kind == "sfx":
        af.append("silenceremove=start_periods=1:start_threshold=-50dB")
    af.append("loudnorm=I=%d:TP=-2:LRA=11" % LOUD[kind])
    args = ["ffmpeg", "-y", "-loglevel", "error", "-i", src, "-af", ",".join(af), "-ar", "44100"]
    if kind in ("sfx", "steps"):  # 걸음도 모노(웹 용량 — 길다)
        args += ["-ac", "1"]
    args += ["-c:a", "libvorbis", "-q:a", "3" if kind == "sfx" else "4", dst]
    subprocess.run(args, check=True)


def write_doc(found: dict) -> None:
    lines = ["# 소리 — 파일 제목별로 쓰인 곳",
             "",
             "> `tools/import_sounds.py`가 만든다(사용자가 준 음원 → `assets/audio/<갈래>/<키>.ogg`). 키를 어디서 트는지는 `data/audio.json`.",
             "> 걸음은 걷는 동안 고리로 틀고(바닥 그림으로 갈래를 정함 — `step_sounds.classes`), 몬스터에게 쫓기는 동안은 달리는 소리.",
             "",
             "| 제목 | 키 | 쓰인 곳 |", "|---|---|---|"]
    for title, kind, key, use in MAP:
        mark = "" if not found or title in found else " (파일 없음)"
        lines.append("| %s | `%s` | %s%s |" % (title, key, use, mark))
    lines += ["", "**쓰지 않은 것**", ""]
    for t, why in SKIP.items():
        lines.append("- %s — %s" % (t, why))
    open(DOC, "w", encoding="utf-8").write("\n".join(lines) + "\n")


def main() -> None:
    if len(sys.argv) > 1 and sys.argv[1] == "--doc":
        write_doc({})
        return
    src_dir = sys.argv[1]
    files = {os.path.splitext(f)[0]: os.path.join(src_dir, f) for f in os.listdir(src_dir) if f.lower().endswith((".mp3", ".wav", ".ogg"))}
    found = {}
    for title, kind, key, _use in MAP:
        if title not in files:
            print("없음:", title)
            continue
        convert(files[title], kind, key)
        found[title] = key
    unused = [t for t in files if t not in found and t not in SKIP]
    print("변환 %d개, 쓰지 않음 %d개, 표에 없는 파일 %s" % (len(found), len(SKIP), unused))
    write_doc(found)


if __name__ == "__main__":
    main()
