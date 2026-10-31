# 게임 글 모음 — 도서관 책 · 플레이버 · 상황 문구

> 게임에 나오는 읽을거리를 한 파일에 모았다(1197개). **고친 뒤 이 파일을 보내 주면 바뀐 글만 게임에 넣는다**(`python3 tools/texts_md.py --apply`).
> - 항목 = `#### 이름 · \`파일:경로\`` 줄 + 그 아래 글. **`####` 줄(특히 \` \` 안 경로)은 바꾸지 말고, 아래 글만** 고친다. 글은 여러 줄이어도 된다(다음 `#` 줄 전까지가 한 글).
> - `{이름}`은 자리표시자(게임이 값을 넣는다) — 그대로 둔다(바꾸면 그 줄은 적용하지 않는다). `\n`이 필요한 자리는 그냥 줄을 바꿔 쓴다.
> - 대화창은 **한 쪽에 한 문장**이다(UI44) — 문장을 끊으면 Enter 한 번씩 넘어간다.
> - 도서관 책: 고서 문체, **숫자·%·괄호·존댓말 금지**(CT52). 거주 등급·층은 제목 줄에 적혀 있다(바꾸지 않는다).
> - 항목을 지우거나 새로 써도 게임에는 들어가지 않는다(새 글은 따로 말해 주면 데이터에 더한다). 버튼·이름 같은 짧은 화면 글은 `docs/STRINGS.md`, 이름(`name_ko`)은 각 데이터 파일.

## 차례

- **도서관 책** — 미궁에 관하여(24) · 소재와 무기에 관하여(18) · 상태이상에 관하여(24) · 몬스터와 정수에 관하여(24) · 생존과 야영에 관하여(18) · 도시와 탐험가에 관하여(28)
- **플레이버 · 설명 글** — 아이템(131) · 장비 소재(37) · 장비 종류(31) · 몬스터(104) · 정수(51) · 스킬(11) · 상태이상(66) · 전투 게이지(6) · 랜드마크(3) · 종족 · 직업(6) · 균열(설명 · 챕터)(21) · 수수께끼(문제 · 벽화)(32)
- **상황 문구** — 기록 · 일반 알림(18) · 캐릭터 만들기(1) · 탐험 알림 · boss_notice(10) · 탐험 알림(86) · 탐험 알림 · hidden(21) · 아이템 · 스킬 효과(16) · 전투(132) · 보상 · 정수(11) · 소지품(3) · 아군(2) · 도감(1) · 도감(몬스터)(3) · 정수 칸(3) · 수수께끼(1) · 차원광장 · 정산(4) · 도시(28) · 도시 · fx(25) · 도시 · lines(46) · 도시 · street(37) · 도시 · meal(24) · 동굴 요소(75) · 동굴 요소 · corpse(15)

## 도서관 책

### 미궁에 관하여

#### 제목 (1등급 거주 · 1층) · `data/city_info/dungeon.json:{d_cave_shape}.name_ko`
수정동굴의 생김새

#### 수정동굴의 생김새 · `data/city_info/dungeon.json:{d_cave_shape}.text_ko`
첫째 층은 십자 모양으로 뻗은 거대한 동굴이다. 한가운데 대현자의 기념비가 서 있고, 동서남북 네 갈래 굴이 그 둘레로 뻗어 나간다. 갈래마다 사는 마물이 다르니, 어느 굴로 갈지는 문을 넘기 전에 정해 두는 것이 좋다.

#### 제목 (1등급 거주 · 1층) · `data/city_info/dungeon.json:{d_dark}.name_ko`
빛이 닿지 않는 곳

#### 빛이 닿지 않는 곳 · `data/city_info/dungeon.json:{d_dark}.text_ko`
굴 끝으로 갈수록 수정의 빛이 옅어지다가 끝내 아무 빛도 없는 어둠에 이른다. 그곳에서는 제 손에 든 불빛만이 길을 밝힌다. 불 없이 어둠에 드는 것은 눈을 감고 걷는 것과 다르지 않다.

#### 제목 (1등급 거주 · 1층) · `data/city_info/dungeon.json:{d_close}.name_ko`
문이 닫히는 때

#### 문이 닫히는 때 · `data/city_info/dungeon.json:{d_close}.text_ko`
차원광장에서 열린 문은 이레 동안만 열려 있다. 닫힐 날이 가까워지면 동굴이 먼저 그 낌새를 알린다. 끝내 문이 닫히면 남은 자는 차원광장의 돌바닥 위로 내던져진다. 위층으로 오른 자는 그 층의 문이 닫힐 때를 따로 셈해야 한다.

#### 제목 (2등급 거주 · 1층) · `data/city_info/dungeon.json:{d_monument}.name_ko`
대현자의 기념비

#### 대현자의 기념비 · `data/city_info/dungeon.json:{d_monument}.text_ko`
동굴 한가운데 비석 둘레는 이상하리만치 고요하다. 마물이 좀처럼 다가오지 않아, 예로부터 탐험가들이 숨을 돌리고 잠을 청하는 자리로 써 왔다. 깊이 잠들려거든 반드시 이런 곳을 골라라.

#### 제목 (2등급 거주 · 1층) · `data/city_info/dungeon.json:{d_up}.name_ko`
위층으로 오르는 문

#### 위층으로 오르는 문 · `data/city_info/dungeon.json:{d_up}.text_ko`
미궁은 첫째 층이 가장 아래이고, 층을 오를수록 위태로워진다. 네 갈래 굴의 맨 끝, 가장 짙은 어둠 속에 위층으로 오르는 문이 있다. 빛이 전혀 닿지 않는 곳이니 불을 넉넉히 챙겨 가야 한다.

#### 제목 (2등급 거주 · 1층) · `data/city_info/dungeon.json:{d_days}.name_ko`
날이 갈수록 거칠어지는 동굴

#### 날이 갈수록 거칠어지는 동굴 · `data/city_info/dungeon.json:{d_days}.text_ko`
동굴은 날이 갈수록 거칠어진다. 처음 며칠은 마물이 홀로 다니지만, 날이 지날수록 무리가 커진다. 사흘째부터는 남쪽 굴과 한가운데에 구울이 모여든다는 기록이 있다.

#### 제목 (3등급 거주 · 1층) · `data/city_info/dungeon.json:{d_rift_nature}.name_ko`
균열이 열리는 이치

#### 균열이 열리는 이치 · `data/city_info/dungeon.json:{d_rift_nature}.text_ko`
첫째 층에는 이따금 다른 땅으로 통하는 균열이 열린다. 한 번 열린 뒤 두어 달은 잠잠하고, 너덧 달이 지나면 열리는 일이 잦아지며, 여덟 달을 넘기는 일은 없다고 한다. 열리는 때는 문이 열린 동안의 어느 날이니, 들어가 보기 전에는 알 수 없다.

#### 제목 (3등급 거주 · 1층) · `data/city_info/dungeon.json:{d_rift_force}.name_ko`
때가 아닌 균열을 여는 법

#### 때가 아닌 균열을 여는 법 · `data/city_info/dungeon.json:{d_rift_force}.text_ko`
때가 아닌 균열도 열 수 있다. 한 번의 원정에서 첫째 층의 네 마물, 곧 고블린과 칼날늑대와 노움과 구울을 모두 쓰러뜨린 뒤, 그 마석 넷을 대현자의 기념비에 바치면 비석 곁에 균열이 열린다. 어느 땅으로 통할지는 열려 보아야 안다. 바친 뒤에 또 열려면 네 마물을 다시 잡아야 한다.

#### 제목 (3등급 거주 · 1층) · `data/city_info/dungeon.json:{d_rift_inside}.name_ko`
균열 안의 길

#### 균열 안의 길 · `data/city_info/dungeon.json:{d_rift_inside}.text_ko`
균열 안은 몇 개의 마당으로 나뉘고, 마당과 마당은 좁은 길목으로 이어진다. 길목은 되돌아 걸을 수도 있다. 가장 깊은 마당에는 그 땅의 수호자가 있으며, 수호자가 쓰러진 자리에 돌아가는 문이 열린다.

#### 제목 (4등급 거주 · 1층) · `data/city_info/dungeon.json:{d_rift_lands}.name_ko`
균열 너머의 네 땅

#### 균열 너머의 네 땅 · `data/city_info/dungeon.json:{d_rift_lands}.text_ko`
첫째 층의 균열은 네 땅으로 통한다. 붉은 하늘 아래 흑빛 성채가 선 핏빛성채, 얼음 호수 너머 굴로 이어지는 빙하굴, 철로가 깔린 음산한 녹색 탄광, 문양이 새겨진 금속 복도의 강철의 묘다. 땅마다 수호자가 있다.

#### 제목 (4등급 거주 · 1층) · `data/city_info/dungeon.json:{d_lord_summon}.name_ko`
계층군주를 부르는 법

#### 계층군주를 부르는 법 · `data/city_info/dungeon.json:{d_lord_summon}.text_ko`
첫째 층의 네 균열에서 수호자를 모두 쓰러뜨린 자는 대현자의 기념비에서 계층군주를 부를 수 있다. 비석에 손을 얹으면 발밑에서 대답이 온다.

#### 제목 (4등급 거주 · 1층) · `data/city_info/dungeon.json:{d_lord_omen}.name_ko`
군주가 깨어난 뒤

#### 군주가 깨어난 뒤 · `data/city_info/dungeon.json:{d_lord_omen}.text_ko`
군주가 깨어나면 수정의 빛이 핏빛으로 바뀌고, 곁에 있던 이들의 기척이 멀어지며 눈앞이 어둑해진다. 군주는 눈이 어두워 멀리 있는 자를 알아보지 못한다. 쓰러진 군주는 한나절쯤 잠잠하다가 다시 부름에 답한다.

### 소재와 무기에 관하여

#### 제목 (1등급 거주 · 1층) · `data/city_info/arms.json:{a_kinds}.name_ko`
무기의 갈래

#### 무기의 갈래 · `data/city_info/arms.json:{a_kinds}.text_ko`
칼과 도끼는 베고, 창과 단검과 화살은 찌르고, 철퇴와 망치와 곤봉은 부순다. 마물마다 잘 듣는 공격이 다르니 한 갈래의 무기만 믿지 마라.

#### 제목 (1등급 거주 · 1층) · `data/city_info/arms.json:{a_common}.name_ko`
흔한 소재

#### 흔한 소재 · `data/city_info/arms.json:{a_common}.text_ko`
가장 흔한 소재는 강철, 무두질 가죽, 참나무, 리넨, 짐승 뼈, 수정이다. 어느 대장간에서나 다루고 값이 싸며, 쓰기에 무난하다.

#### 제목 (2등급 거주 · 1층) · `data/city_info/arms.json:{a_grade}.name_ko`
소재의 격

#### 소재의 격 · `data/city_info/arms.json:{a_grade}.text_ko`
소재에는 격이 있다. 격이 높을수록 무기는 날카로워지고 갑옷은 단단해지지만, 무거운 것은 여전히 무겁다. 격이 높은 소재는 좋은 구역의 대장간에만 들어온다.

#### 제목 (2등급 거주 · 1층) · `data/city_info/arms.json:{a_two_hands}.name_ko`
두 손 무기의 값

#### 두 손 무기의 값 · `data/city_info/arms.json:{a_two_hands}.text_ko`
대검과 전투 망치, 미늘창과 활은 두 손을 쓴다. 강하지만 방패를 함께 들 수 없고, 무거운 것은 몸을 굼뜨게 한다. 창은 공격이 세지는 대신 몸놀림을 조금 잃는다.

#### 제목 (2등급 거주 · 1층) · `data/city_info/arms.json:{a_second}.name_ko`
둘째 격의 소재

#### 둘째 격의 소재 · `data/city_info/arms.json:{a_second}.text_ko`
라이티늄은 깃털처럼 가벼워 몸놀림을 덜 해친다. 와이번 가죽은 몸을 날래게 하고, 레드우드로 깎은 무기는 잘 맞는다. 거미 비단은 독을, 호박은 불을 조금 막아 준다.

#### 제목 (3등급 거주 · 1층) · `data/city_info/arms.json:{a_third}.name_ko`
셋째 격의 소재

#### 셋째 격의 소재 · `data/city_info/arms.json:{a_third}.text_ko`
아이릴제로 벼린 날은 한층 깊이 박히고, 아이디움 갑옷은 무겁지만 몸에 닿는 타격을 덜어 준다. 트롤의 가죽과 뼈는 상처를 빨리 아물게 하고, 흑철목은 쇠처럼 단단하다. 서리 양모는 추위를, 비취는 독을 막는다.

#### 제목 (3등급 거주 · 1층) · `data/city_info/arms.json:{a_shield}.name_ko`
방패의 쓰임

#### 방패의 쓰임 · `data/city_info/arms.json:{a_shield}.text_ko`
작은 방패는 가벼워 몸놀림을 덜 해치고, 큰 방패는 무겁지만 몸을 통째로 가린다. 방패를 든 손으로는 두 손 무기를 쥘 수 없으니, 막을 것인지 벨 것인지 먼저 정하라.

#### 제목 (4등급 거주 · 1층) · `data/city_info/arms.json:{a_fourth}.name_ko`
넷째 격의 소재

#### 넷째 격의 소재 · `data/city_info/arms.json:{a_fourth}.text_ko`
월광석과 월광 비단과 흑요석은 어둠을 막는다. 오리하르콘은 쥔 이의 정신을 맑게 하고, 드레이크 가죽은 불에 타지 않으며 마법을 잘 막는다. 보르탈 나무는 영혼의 기운을 빨리 되찾게 한다.

#### 제목 (4등급 거주 · 1층) · `data/city_info/arms.json:{a_beyond}.name_ko`
그 너머의 소재

#### 그 너머의 소재 · `data/city_info/arms.json:{a_beyond}.text_ko`
넷째 격 위로도 소재가 있다고 전한다. 미스릴, 아다만티움, 세계수와 같은 이름이 그것이다. 그러나 그런 것은 도시의 대장간에서 살 수 없고, 미궁의 높은 층에서 제 손으로 구해야 한다.

### 상태이상에 관하여

#### 제목 (1등급 거주 · 1층) · `data/city_info/ailments.json:{s_bleed}.name_ko`
출혈

#### 출혈 · `data/city_info/ailments.json:{s_bleed}.text_ko`
베이거나 찢긴 상처에서 피가 흐르면 시시각각 기력이 빠진다. 상처가 겹치면 더 많이 흐른다. 붕대로 싸매면 멎으며, 몸이 단단한 자는 덜 흘린다.

#### 제목 (1등급 거주 · 1층) · `data/city_info/ailments.json:{s_poison}.name_ko`
중독

#### 중독 · `data/city_info/ailments.json:{s_poison}.text_ko`
독이 돌면 시시각각 생명이 깎인다. 해독제로 씻어 낼 수 있다. 독에 강한 체질은 덜 걸리고 덜 아프다.

#### 제목 (1등급 거주 · 1층) · `data/city_info/ailments.json:{s_paralysis}.name_ko`
마비

#### 마비 · `data/city_info/ailments.json:{s_paralysis}.text_ko`
고블린의 칼에 발린 독은 몸을 굳게 한다. 굳으면 한동안 손끝 하나 움직일 수 없다. 항마력이 높은 자는 잘 버틴다.

#### 제목 (2등급 거주 · 1층) · `data/city_info/ailments.json:{s_stun}.name_ko`
기절

#### 기절 · `data/city_info/ailments.json:{s_stun}.text_ko`
머리를 세게 맞으면 정신이 아득해져 한동안 움직이지 못한다. 한 번 깨어나면 곧바로 다시 기절하지는 않는다. 몸이 단단한 자는 덜 쓰러진다.

#### 제목 (2등급 거주 · 1층) · `data/city_info/ailments.json:{s_blind}.name_ko`
실명

#### 실명 · `data/city_info/ailments.json:{s_blind}.text_ko`
눈에 흙이나 모래가 들어가면 공격이 잘 맞지 않는다. 눈이 밝은 자는 덜 걸린다.

#### 제목 (2등급 거주 · 1층) · `data/city_info/ailments.json:{s_snare}.name_ko`
속박

#### 속박 · `data/city_info/ailments.json:{s_snare}.text_ko`
발이 묶이면 달아날 수 없고 몸놀림이 둔해진다. 힘센 자는 쉽게 끊어 낸다.

#### 제목 (3등급 거주 · 1층) · `data/city_info/ailments.json:{s_lingers}.name_ko`
싸움이 끝나도 남는 것

#### 싸움이 끝나도 남는 것 · `data/city_info/ailments.json:{s_lingers}.text_ko`
출혈과 중독, 부패와 화상은 싸움이 끝나도 몸에 남아, 동굴을 걷는 동안에도 기력을 앗아간다. 그 밖의 상태는 대개 싸움이 끝나면 풀린다.

#### 제목 (3등급 거주 · 1층) · `data/city_info/ailments.json:{s_rot}.name_ko`
부패

#### 부패 · `data/city_info/ailments.json:{s_rot}.text_ko`
썩은 것에게 입은 상처는 속으로 썩어 들어가 저절로는 낫지 않는다. 항마력이 높은 자가 잘 버틴다.

#### 제목 (3등급 거주 · 1층) · `data/city_info/ailments.json:{s_fear}.name_ko`
공포와 위축

#### 공포와 위축 · `data/city_info/ailments.json:{s_fear}.text_ko`
끔찍한 것을 보면 공포에 사로잡히고, 포효를 들으면 기가 죽어 힘이 빠진다. 정신이 굳센 자는 잘 버틴다.

#### 제목 (4등급 거주 · 1층) · `data/city_info/ailments.json:{s_frost}.name_ko`
서리와 빙결

#### 서리와 빙결 · `data/city_info/ailments.json:{s_frost}.text_ko`
서리가 내려앉으면 몸이 굼떠지고, 서리가 겹겹이 쌓이면 끝내 얼음에 갇힌다. 얼음은 불에 닿으면 녹는다. 추위에 강한 자는 잘 버틴다.

#### 제목 (4등급 거주 · 1층) · `data/city_info/ailments.json:{s_petrify}.name_ko`
석화

#### 석화 · `data/city_info/ailments.json:{s_petrify}.text_ko`
몸이 돌로 굳으면 한동안 움직일 수 없지만, 그동안은 몸이 돌처럼 단단해진다.

#### 제목 (4등급 거주 · 1층) · `data/city_info/ailments.json:{s_confusion}.name_ko`
혼란

#### 혼란 · `data/city_info/ailments.json:{s_confusion}.text_ko`
정신이 흐려지면 눈앞의 누구든 친다. 동료라도 예외가 아니다. 정신이 굳센 자는 잘 버틴다.

### 몬스터와 정수에 관하여

#### 제목 (1등급 거주 · 1층) · `data/city_info/monsters.json:{m_goblin}.name_ko`
고블린

#### 고블린 · `data/city_info/monsters.json:{m_goblin}.text_ko`
가장 약한 마물이지만 얕볼 것이 못 된다. 짧은 칼에 마비독을 바르고 길목에 덫을 놓는다. 서너 마리씩 몰려다니며, 북쪽 굴에 많다. 겁을 먹으면 달아나기도 한다.

#### 제목 (1등급 거주 · 1층) · `data/city_info/monsters.json:{m_wolf}.name_ko`
칼날늑대

#### 칼날늑대 · `data/city_info/monsters.json:{m_wolf}.text_ko`
칼날 같은 털을 세운 늑대다. 냄새를 쫓아오므로 숨어 있어도 소용이 없고, 무리 가운데 약한 자부터 문다. 동쪽 굴에 살며 번개에 약하다고 한다.

#### 제목 (1등급 거주 · 1층) · `data/city_info/monsters.json:{m_gnome}.name_ko`
노움

#### 노움 · `data/city_info/monsters.json:{m_gnome}.text_ko`
진흙으로 빚은 인형이다. 둘레와 하나가 되어 있어 코앞에 이르기 전에는 보이지 않는다. 서쪽 굴에 살며, 몸을 돌처럼 굳히기도 하고 진흙을 던져 눈을 가리기도 한다.

#### 제목 (1등급 거주 · 1층) · `data/city_info/monsters.json:{m_ghoul}.name_ko`
구울

#### 구울 · `data/city_info/monsters.json:{m_ghoul}.text_ko`
네 발로 기는 시체 먹는 자다. 가까이 가지 않으면 먼저 덤비지 않으며, 할퀴는 순서가 늘 같다. 시체 냄새를 맡고 모여드니 죽은 자 곁을 조심하라. 불과 신성한 힘에 약하며, 남쪽 굴에 많다.

#### 제목 (2등급 거주 · 1층) · `data/city_info/monsters.json:{m_essence}.name_ko`
정수란 무엇인가

#### 정수란 무엇인가 · `data/city_info/monsters.json:{m_essence}.text_ko`
마물을 쓰러뜨리면 드물게 그 자리에 빛나는 정수가 남는다. 정수를 몸에 받아들이면 그 마물의 힘과 재주 일부가 깃든다. 몸에 담을 수 있는 정수의 수는 쌓은 공적에 따른다. 남은 정수는 오래 머물지 않으니, 받을 자를 곧 정해야 한다.

#### 제목 (2등급 거주 · 1층) · `data/city_info/monsters.json:{m_essence_chance}.name_ko`
정수가 남는 이치

#### 정수가 남는 이치 · `data/city_info/monsters.json:{m_essence_chance}.text_ko`
등급이 낮은 마물일수록 정수가 잘 남지 않는다. 첫째 층 마물이 정수를 남기는 일은 하에 속한다. 등급이 오를수록 조금씩 잦아지고, 균열의 수호자에 이르면 상이라 할 만하다. 사람은 정수를 남기지 않는다.

#### 제목 (2등급 거주 · 1층) · `data/city_info/monsters.json:{m_investigate}.name_ko`
마물을 살피는 법

#### 마물을 살피는 법 · `data/city_info/monsters.json:{m_investigate}.text_ko`
싸움 중에 마물을 찬찬히 살피면 그 체력과 힘을 가늠할 수 있다. 한 번 알아 둔 것은 다음 싸움에서도 잊히지 않는다. 어떤 공격이 잘 듣고 어떤 공격이 듣지 않는지는 직접 겪어 보아야 안다.

#### 제목 (3등급 거주 · 1층) · `data/city_info/monsters.json:{m_essence_color}.name_ko`
정수의 빛깔

#### 정수의 빛깔 · `data/city_info/monsters.json:{m_essence_color}.text_ko`
같은 마물의 정수라도 빛깔에 따라 깃드는 재주가 다르다. 수호자의 정수는 무지갯빛을 띠는데, 그 마물의 모든 재주를 담고 힘도 한층 크다.

#### 제목 (3등급 거주 · 1층) · `data/city_info/monsters.json:{m_essence_clash}.name_ko`
정수끼리 부딪칠 때

#### 정수끼리 부딪칠 때 · `data/city_info/monsters.json:{m_essence_clash}.text_ko`
같은 성질의 재주를 지닌 정수 둘은 한 몸에 담기지 않는다. 이미 받아들인 정수를 빼내려면 신전을 찾아야 하는데, 뺄 때마다 값이 오른다.

#### 제목 (3등급 거주 · 1층) · `data/city_info/monsters.json:{m_lineage}.name_ko`
핏줄을 나눈 마물

#### 핏줄을 나눈 마물 · `data/city_info/monsters.json:{m_lineage}.text_ko`
생김새는 달라도 같은 재주를 나눠 가진 마물이 있다. 한 마물의 재주를 알아 두면, 같은 핏줄의 다른 마물을 처음 만나도 그 수를 짐작할 수 있다.

#### 제목 (4등급 거주 · 1층) · `data/city_info/monsters.json:{m_guardians}.name_ko`
균열의 수호자들

#### 균열의 수호자들 · `data/city_info/monsters.json:{m_guardians}.text_ko`
핏빛성채에는 원한에 사로잡힌 기사 블라터가, 빙하굴에는 얼음 몽둥이를 휘두르는 폭군 타룬바스가 있다. 녹색 탄광의 깊은 공동에는 킹 슬라임이, 강철의 묘에는 철인 일디움이 잠들어 있다. 어느 것이든 첫째 층을 다니는 무리가 상대하기에는 버겁다.

#### 제목 (4등급 거주 · 1층) · `data/city_info/monsters.json:{m_dreadfear}.name_ko`
드레드피어

#### 드레드피어 · `data/city_info/monsters.json:{m_dreadfear}.text_ko`
첫째 층의 계층군주다. 왜소한 사람의 형체에 구더기가 들끓고, 뼈로 된 대검을 휘두른다. 군주 앞에서는 달아날 수 없으니, 맞설 각오가 없다면 부르지 마라.

### 생존과 야영에 관하여

#### 제목 (1등급 거주 · 1층) · `data/city_info/survival.json:{v_hunger}.name_ko`
허기

#### 허기 · `data/city_info/survival.json:{v_hunger}.text_ko`
미궁 안에서는 시간이 흐를수록 배가 고파진다. 배가 비면 힘이 빠지고, 오래 굶으면 상처가 아물지 않다가 끝내 굶어 죽는다. 무기의 재주를 부리면 배가 더 빨리 꺼진다. 마른 식량은 돌빵보다 든든하다.

#### 제목 (1등급 거주 · 1층) · `data/city_info/survival.json:{v_light}.name_ko`
불빛

#### 불빛 · `data/city_info/survival.json:{v_light}.text_ko`
횃불은 오래 타지 않는다. 어둠 속에서 불이 꺼지면 길을 잃기 쉬우니, 꺼지기 전에 다음 불을 챙겨라. 랜턴은 횃불보다 오래 간다.

#### 제목 (1등급 거주 · 1층) · `data/city_info/survival.json:{v_rest}.name_ko`
쉼과 잠

#### 쉼과 잠 · `data/city_info/survival.json:{v_rest}.text_ko`
트인 굴에서 잠들면 마물이 덮친다. 고요한 자리에서만 깊이 쉴 수 있다. 꺼진 모닥불 자리 곁이라면 피로가 더 잘 풀린다.

#### 제목 (2등급 거주 · 1층) · `data/city_info/survival.json:{v_fatigue}.name_ko`
피로

#### 피로 · `data/city_info/survival.json:{v_fatigue}.text_ko`
오래 걷고 싸우고 재주를 부리면 피로가 쌓인다. 피로가 중에 이르면 몸이 무뎌지고, 상에 이르면 힘마저 빠진다. 여관에서 자고 먹으면 풀린다.

#### 제목 (2등급 거주 · 1층) · `data/city_info/survival.json:{v_spring}.name_ko`
맑은 샘

#### 맑은 샘 · `data/city_info/survival.json:{v_spring}.text_ko`
동굴 어딘가에 고인 맑은 샘물은 피로를 씻어 준다. 병에 담아 가는 이도 있다.

#### 제목 (2등급 거주 · 1층) · `data/city_info/survival.json:{v_mushroom}.name_ko`
동굴의 먹을거리

#### 동굴의 먹을거리 · `data/city_info/survival.json:{v_mushroom}.text_ko`
수정 버섯은 허기를 달래 주지만 가끔 탈이 난다. 썩은 고기는 먹을 것이 못 된다.

#### 제목 (3등급 거주 · 1층) · `data/city_info/survival.json:{v_mates}.name_ko`
동료의 끼니

#### 동료의 끼니 · `data/city_info/survival.json:{v_mates}.text_ko`
동료도 배가 고프고 지친다. 함께 다니는 이의 허기를 살피지 않으면 어느새 굶어 쓰러진다. 먹을 것은 한 자루에 넣어 다녀도, 먹이는 일은 하나하나 챙겨야 한다.

#### 제목 (3등급 거주 · 1층) · `data/city_info/survival.json:{v_corpses}.name_ko`
죽은 자의 짐

#### 죽은 자의 짐 · `data/city_info/survival.json:{v_corpses}.text_ko`
동굴에서 쓰러진 탐험가의 짐에는 쓸 만한 것이 남아 있곤 하다. 다만 갓 죽은 자 곁에는 구울이 모여드니 오래 머물지 마라.

#### 제목 (4등급 거주 · 1층) · `data/city_info/survival.json:{v_meals}.name_ko`
여관의 차림

#### 여관의 차림 · `data/city_info/survival.json:{v_meals}.text_ko`
좋은 구역의 여관일수록 차림이 낫다. 든든한 식사는 몇 차례의 싸움 동안 몸을 북돋우고, 특식은 그보다 크다. 동굴 송로 수프를 먹으면 한동안 배가 잘 꺼지지 않는다.

### 도시와 탐험가에 관하여

#### 제목 (1등급 거주 · 1층) · `data/city_info/society.json:{c_tax}.name_ko`
세금

#### 세금 · `data/city_info/society.json:{c_tax}.text_ko`
라비기온의 탐험가는 해마다 세금을 낸다. 기한 안에 내지 못한 자는 신분을 가리지 않고 교수대에 오른다. 세금은 은행에서 낸다.

#### 제목 (1등급 거주 · 1층) · `data/city_info/society.json:{c_raiders}.name_ko`
약탈자

#### 약탈자 · `data/city_info/society.json:{c_raiders}.text_ko`
미궁에서 가장 무서운 것은 마물이 아니라 사람이다. 약탈자는 통행세를 요구하고, 거절하면 칼을 뽑는다. 쓰러뜨려도 마석이나 정수는 남지 않는다.

#### 제목 (1등급 거주 · 1층) · `data/city_info/society.json:{c_tags}.name_ko`
신원패

#### 신원패 · `data/city_info/society.json:{c_tags}.text_ko`
죽은 탐험가의 신원패를 탐험가 길드에 돌려주면 사례를 받는다. 길드는 마물을 살핀 기록도 사들인다.

#### 제목 (2등급 거주 · 1층) · `data/city_info/society.json:{c_survey}.name_ko`
조사 의뢰

#### 조사 의뢰 · `data/city_info/society.json:{c_survey}.text_ko`
탐험가 길드는 때마다 마물 한 종의 조사를 맡긴다. 기한 안에 그 마물을 살핀 기록을 가져가면 마릿수만큼 값을 쳐 준다.

#### 제목 (2등급 거주 · 1층) · `data/city_info/society.json:{c_bank}.name_ko`
은행의 셈

#### 은행의 셈 · `data/city_info/society.json:{c_bank}.text_ko`
은행에 맡긴 돈에는 순마다 이자가 붙는다. 찾을 때는 수수료가 조금 빠진다. 미궁에 들고 간 돈은 죽으면 그만이다.

#### 제목 (2등급 거주 · 1층) · `data/city_info/society.json:{c_stones}.name_ko`
마석의 시세

#### 마석의 시세 · `data/city_info/society.json:{c_stones}.text_ko`
원정대가 한꺼번에 돌아오면 마석 값이 떨어지고, 누군가 마석을 사들이면 값이 뛴다. 팔 때를 골라라.

#### 제목 (1등급 거주 · 1층) · `data/city_info/society.json:{c_city}.name_ko`
라프도니아

#### 라프도니아 · `data/city_info/society.json:{c_city}.text_ko`
세상에 남은 단 하나의 성채 도시다. 높다란 성벽이 둘레를 감싸고, 성문은 투박한 쇠바퀴 소리를 내며 열린다. 안쪽에는 잿빛 돌로 지은 높은 집들과 곧게 닦은 길이 끝없이 이어진다. 하늘은 늘 흐리고 강도 기름진 밭도 없어, 사람들은 마석으로 먹을 것을 지어낸다.

#### 제목 (1등급 거주 · 1층) · `data/city_info/society.json:{c_districts}.name_ko`
열네 구역

#### 열네 구역 · `data/city_info/society.json:{c_districts}.text_ko`
라프도니아는 열네 구역으로 나뉜다. 한가운데 왕가와 귀족이 사는 황도 카르논이 있고, 그 둘레를 상업지구 컴멜비가 띠처럼 감싼다. 귀족의 휴양지 노움트리가 따로 있으며, 남은 일곱 구역이 라비기온이다. 차원광장은 라비기온의 구역마다 하나씩 있다.

#### 제목 (2등급 거주 · 1층) · `data/city_info/society.json:{c_rabigion}.name_ko`
라비기온

#### 라비기온 · `data/city_info/society.json:{c_rabigion}.text_ko`
도시 사람 열에 일곱이 라비기온에 산다. 높은 이들은 이곳 사람을 모두 서민이라 부르지만, 그 안에서도 형편은 갈린다. 광장 가까운 대로변은 경비가 돌고 살 만하나, 큰 블록 안쪽 뒷골목에서는 낡은 건물을 수십 칸으로 쪼개 방 한 칸씩 빌려 산다.

#### 제목 (2등급 거주 · 1층) · `data/city_info/society.json:{c_streets}.name_ko`
구역을 옮기는 일

#### 구역을 옮기는 일 · `data/city_info/society.json:{c_streets}.text_ko`
형편이 피면 더 나은 구역으로 옮겨 간다. 좋은 구역일수록 소매치기가 드물고 경비대가 자주 돈다. 좋은 상점과 대장간, 귀한 책을 둔 도서관도 그런 곳에 모인다. 다만 물가도 그만큼 비싸다.

#### 제목 (3등급 거주 · 1층) · `data/city_info/society.json:{c_commelby}.name_ko`
컴멜비

#### 컴멜비 · `data/city_info/society.json:{c_commelby}.text_ko`
카르논을 둘러싼 상업지구로, 흔히 자유시장이라 부른다. 장인과 장사가 잘되는 가게가 모여 있고, 북쪽 구역에는 넉넉한 이들이 산다. 여관에서 하룻밤 묵는 값이 서민의 며칠 벌이에 맞먹는다.

#### 제목 (3등급 거주 · 1층) · `data/city_info/society.json:{c_temple}.name_ko`
신전의 공덕

#### 신전의 공덕 · `data/city_info/society.json:{c_temple}.text_ko`
신전에 시주하고 예배하면 공덕이 쌓인다. 쌓인 공덕은 언젠가 신관의 손을 빌릴 때 쓰인다고 한다.

#### 제목 (4등급 거주 · 1층) · `data/city_info/society.json:{c_karnon}.name_ko`
카르논과 노움트리

#### 카르논과 노움트리 · `data/city_info/society.json:{c_karnon}.text_ko`
황도 카르논은 이름이 널리 알려진 자가 아니면 발을 들일 수 없다. 노움트리는 귀족의 휴양지로, 요정이 밭을 갈고 드워프가 풍차를 돌리며 수인이 가축을 친다. 그곳에서는 마석으로 지은 것이 아닌 진짜 고기와 빵을 먹는다고 한다.

#### 제목 (4등급 거주 · 1층) · `data/city_info/society.json:{c_numbers}.name_ko`
넘버스

#### 넘버스 · `data/city_info/society.json:{c_numbers}.text_ko`
균열의 수호자는 드물게 번호가 새겨진 물건을 남긴다. 사람들은 이를 넘버스라 부르며, 한 점이면 평생을 먹고살 만하다고 한다.

## 플레이버 · 설명 글

### 아이템

#### 해독제 · `data/items/antidote.json:.desc_ko`
쓴 풀을 달여 졸인 검은 물. 혀가 아릴 만큼 쓰다.

#### 붕대 · `data/items/bandage.json:.desc_ko`
삶아 말린 천. 피를 멎게 하는 데는 이만한 것이 없다.

#### 피의 성배 · `data/items/blood_chalice.json:.desc_ko`
우물에 부은 피가 굳어 생긴 잔. 아직 따뜻하다.

#### 뼈 목걸이 · `data/items/bone_amulet.json:.desc_ko`
짐승 뼈를 깎은 부적. 마음이 가라앉는다.

#### 부러진 화살촉 · `data/items/broken_arrowhead.json:.desc_ko`
과녁에 박혔다 빠진 화살에서 떨어진 촉. 끝은 아직 쓸 만하다.

#### 부러진 칼날 · `data/items/broken_blade.json:.desc_ko`
담금질을 버티지 못하고 갈라진 날. 대장장이는 다시 녹일 생각이었다.

#### 깨진 봉랍 · `data/items/broken_seal.json:.desc_ko`
뜯긴 서류에서 떨어진 붉은 봉랍 조각. 문장 반쪽이 남아 있다.

#### 양초 토막 · `data/items/candle_stub.json:.desc_ko`
촛대에서 빼낸 짧은 초. 밤새 버티지는 못한다.

#### 깎인 은화 · `data/items/clipped_coin.json:.desc_ko`
가장자리를 몰래 깎아 낸 은화. 창구에서는 받아 주지 않는다.

#### 구리 광석 조각 · `data/items/copper_ore.json:.desc_ko`
푸른 녹이 슨 광석 조각. 대장간에서 몇 푼 쳐준다.

#### 구리 반지 · `data/items/copper_ring.json:.desc_ko`
녹이 슨 구리 반지. 손가락이 조금 서늘하다.

#### 수정 버섯 · `data/items/crystal_mushroom.json:.desc_ko`
수정처럼 비치는 갓. 씹으면 시원하지만 가끔 탈이 난다.

#### 데스마스크 · `data/items/death_mask.json:.desc_ko`
이름 모를 기사의 얼굴을 본뜬 쇠 가면. 눈구멍이 아직도 이쪽을 본다.

#### 귀퉁이 접힌 책 · `data/items/dog_eared_book.json:.desc_ko`
누군가 읽다 만 자리마다 귀퉁이를 접어 두었다. 끝까지 읽은 사람은 없는 듯하다.

#### 뼈 대검 · `data/items/dread_bone_greatsword.json:.desc_ko`
계층군주가 휘두르던 뼈 대검. 군주가 공포라는 이름을 얻기 전부터 쥐고 있던 것이라 한다.

#### 빈 병 · `data/items/empty_bottle.json:.desc_ko`
바닥에 찌꺼기가 말라붙은 빈 병. 던지면 요란하게 깨진다.

#### 만년빙 결정 · `data/items/eternal_ice.json:.desc_ko`
녹지 않는 얼음. 손바닥에 올려도 차갑기만 하다.

#### 탐험가 신원패 · `data/items/explorer_tag.json:.desc_ko`
스무 해를 채운 날 처음 목에 거는 쇠 패. 길드에 돌려주면 누군가는 소식을 듣는다.

#### 김빠진 맥주 · `data/items/flat_ale.json:.desc_ko`
뚜껑을 덜 닫아 김이 다 빠진 맥주. 그래도 목은 축인다.

#### 수정동굴의 계층석 · `data/items/floor_stone_1.json:.desc_ko`
수정동굴의 숨이 굳은 돌. 쥐면 발밑 깊은 곳의 울림이 전해지는데, 기념비 곁에서 가장 크다.

#### 성채 군량 빵 · `data/items/fortress_bread.json:.desc_ko`
돌처럼 굳은 검은 빵. 성채 문장이 찍혀 있다.

#### 성채 사슬 갑옷 · `data/items/fortress_chainmail.json:.desc_ko`
검게 녹슨 사슬 갑옷. 이상하게도 망자의 손톱이 잘 박히지 않는다.

#### 핏빛 문장 망토 · `data/items/fortress_cloak.json:.desc_ko`
성채 문장이 수놓인 붉은 망토. 바래도 핏빛은 그대로다.

#### 망루 석궁 · `data/items/fortress_crossbow.json:.desc_ko`
망루에 걸려 있던 석궁. 시위가 아직 팽팽하다.

#### 수비대 미늘창 · `data/items/fortress_halberd.json:.desc_ko`
성문 수비대가 들던 미늘창. 자루에 수비대 번호가 깎여 있다.

#### 성수 병 · `data/items/fortress_holy_water.json:.desc_ko`
성채 예배당에 남아 있던 성수. 병마개 안쪽이 아직 서늘하다.

#### 무기고 열쇠 · `data/items/fortress_key.json:.desc_ko`
녹슨 큰 열쇠. 성채 어딘가의 자물쇠를 기억하고 있다. 성채 밖에서는 녹아내린다.

#### 성채 기사의 장검 · `data/items/fortress_knight_sword.json:.desc_ko`
쓰러진 기사가 끝까지 놓지 않던 장검. 날밑에 핏빛 문장이 새겨져 있다.

#### 영주가의 은 술잔 · `data/items/fortress_silver_cup.json:.desc_ko`
영주의 문장이 새겨진 은 술잔. 가장자리에 검붉은 얼룩이 배었다.

#### 군용 지혈대 · `data/items/fortress_tourniquet.json:.desc_ko`
성채 병사들이 허리에 차고 다니던 가죽 지혈대. 핏자국이 겹겹이 말라붙었다.

#### 검붉은 포도주 · `data/items/fortress_wine.json:.desc_ko`
영주의 지하 창고에서 나온 술. 한 모금이면 떨림이 멎는다.

#### 서리 낀 뼈 장신구 · `data/items/frost_bone_charm.json:.desc_ko`
서리가 엉겨 붙은 뼈 장식. 끈을 매던 구멍이 반들반들하다.

#### 꽁꽁 언 고기 · `data/items/frozen_meat.json:.desc_ko`
얼음째 굳은 고기. 녹이면 먹을 수 있을지도 모른다.

#### 푸른 빙결정 · `data/items/glacier_blue_crystal.json:.desc_ko`
녹지 않는 푸른 결정. 손에 쥐면 손바닥이 시리다.

#### 늑대 송곳니 목걸이 · `data/items/glacier_fang_amulet.json:.desc_ko`
토템 앞에 바쳐져 있던 송곳니 목걸이. 짐승 냄새가 짙다.

#### 늑대 이빨 단검 · `data/items/glacier_fang_dagger.json:.desc_ko`
서리 늑대의 송곳니를 갈아 만든 단검. 날이 차갑다.

#### 서리 약초 · `data/items/glacier_frost_herb.json:.desc_ko`
얼음 틈에서 자란 푸른 약초. 씹으면 몸속에서 열이 올라온다.

#### 탐사대 털망토 · `data/items/glacier_fur_cloak.json:.desc_ko`
탐사대가 두고 간 두꺼운 털망토. 안쪽에 아직 온기가 남은 듯하다.

#### 설원 사냥꾼의 활 · `data/items/glacier_hunter_bow.json:.desc_ko`
언 숲 사냥꾼의 활. 손잡이에 늑대 가죽을 감았다.

#### 얼음 송곳 · `data/items/glacier_ice_spike.json:.desc_ko`
결정 굴에서 떼어 낸 얼음 송곳. 던지면 박힌 자리가 얼어붙는다.

#### 기름 과자 · `data/items/glacier_oil_cake.json:.desc_ko`
탐사대가 챙겨 온 기름진 과자. 얼어도 부서지지 않는다.

#### 오크 주술사의 지팡이 · `data/items/glacier_orc_staff.json:.desc_ko`
얼음 속 오크 주술사가 쥐고 있던 지팡이. 끝에 얼음 구슬이 박혔다.

#### 예티 기름 연고 · `data/items/glacier_yeti_salve.json:.desc_ko`
예티 기름을 졸인 연고. 바르면 언 살갗이 금세 풀린다.

#### 형광 이끼 덩이 · `data/items/glow_moss.json:.desc_ko`
어둠 속에서 푸르게 빛나는 이끼. 약재상이 좋아한다.

#### 노움의 반짝이 돌 · `data/items/gnome_trinket.json:.desc_ko`
노움들이 모아 두는 반짝이는 돌. 다음 달 문이 열리면 노움도, 돌도 처음 자리에 돌아와 있다.

#### 고블 쿼츠 · `data/items/gobl_quartz.json:.desc_ko`
광맥에서 캐낸 탁한 초록 수정. 가루를 내어 삼키면 독이 덜 받는다.

#### 여신의 눈물 · `data/items/goddess_tear.json:.desc_ko`
분수대 조각상 속 작은 상자에 있던 맑은 눈물. 악한 것 앞에서 뜨겁게 빛난다. 성채 밖으로는 가져갈 수 없다.

#### 상급 포션 · `data/items/greater_potion.json:.desc_ko`
짙은 붉은 물약. 마시면 살이 차오르는 것이 느껴진다.

#### 초록 보석 · `data/items/green_gem.json:.desc_ko`
끊긴 철로 너머 샛길에서 찾은 커다란 초록 보석. 들여다보면 깊은 물 같다.

#### 녹색 광맥 덩이 · `data/items/green_vein.json:.desc_ko`
초록빛이 결을 따라 흐르는 광맥 덩이. 무겁고 값지다.

#### 성수 몇 방울 · `data/items/holy_drops.json:.desc_ko`
성수반 바닥에 남은 것을 작은 병에 받았다. 축성은 아직 풀리지 않았다.

#### 사냥 활 · `data/items/hunting_bow.json:.desc_ko`
짐승을 잡던 활. 성벽 밖 들판에 아직 짐승이 뛰놀던 시절의 꼴 그대로다.

#### 사냥용 단검 · `data/items/hunting_dagger.json:.desc_ko`
가죽을 벗길 때 쓰던 칼. 급할 때는 찌를 수도 있다.

#### 얼음 수정 부스러기 · `data/items/ice_chips.json:.desc_ko`
얼음 결정에서 떨어진 부스러기. 녹지 않고 반짝인다.

#### 빙정 · `data/items/ice_crystal.json:.desc_ko`
작은 연못 속에서 건진 붉은 얼음 구슬. 삼키면 냉기를 다루는 감각이 깨어난다.

#### 향 한 개비 · `data/items/incense_stick.json:.desc_ko`
제단 앞에서 피우다 남은 향. 연기가 가라앉으면 마음도 가라앉는다.

#### 잉크병 · `data/items/ink_pot.json:.desc_ko`
마개를 꽉 닫아 둔 검은 잉크. 쏟으면 좀처럼 지워지지 않는다.

#### 철 투구 · `data/items/iron_helm.json:.desc_ko`
이마와 정수리를 지키는 투구. 횃불을 꽂을 홈이 있다.

#### 철퇴 · `data/items/iron_mace.json:.desc_ko`
쇠뭉치를 박은 곤봉. 단단한 것을 깨는 데 좋다.

#### 쇳조각 · `data/items/iron_scrap.json:.desc_ko`
모루 밑에 쓸어 모은 쇳조각. 모서리가 아직 날카롭다.

#### 랜턴 · `data/items/lantern.json:.desc_ko`
기름을 채워 오래 켜 두는 등. 높은 층의 어둠은 이 불빛마저 몇 걸음 안에서 삼킨다고 한다.

#### 가죽 갑옷 · `data/items/leather_armor.json:.desc_ko`
무두질한 가죽 조끼. 움직이기 편하다.

#### 가죽 허리띠 · `data/items/leather_belt.json:.desc_ko`
주머니를 몇 개 달 수 있다.

#### 가죽 장화 · `data/items/leather_boots.json:.desc_ko`
발목까지 오는 장화. 소리가 덜 난다.

#### 가죽 장갑 · `data/items/leather_gloves.json:.desc_ko`
손이 미끄러지지 않는다.

#### 가죽 두건 · `data/items/leather_hood.json:.desc_ko`
머리와 목을 덮는 두건.

#### 남은 음식 · `data/items/leftovers.json:.desc_ko`
여관에서 싸 준 식은 음식. 배는 채워 준다.

#### 흩어진 책장 · `data/items/loose_pages.json:.desc_ko`
제본이 풀려 떨어져 나온 낱장. 앞뒤 장이 없어 무슨 책인지 알 수 없다.

#### 5등급 마석 · `data/items/magic_stone_5.json:.desc_ko`
속에서 빛이 천천히 맴도는 마석. 이 정도면 미궁 꽤 높은 층 몬스터의 것이다.

#### 6등급 마석 · `data/items/magic_stone_6.json:.desc_ko`
손바닥 위에서 은은하게 데워지는 마석.

#### 7등급 마석 · `data/items/magic_stone_7.json:.desc_ko`
맑은 빛이 결을 따라 흐르는 마석.

#### 8등급 마석 · `data/items/magic_stone_8.json:.desc_ko`
9등급보다 한결 맑게 빛나는 마석.

#### 9등급 마석 · `data/items/magic_stone_9.json:.desc_ko`
가장 흔한 마석. 성벽 안의 빵은 대개 이런 흐릿한 빛으로 구워진다.

#### 마력이 깃든 얼음 조각 · `data/items/mana_ice_shard.json:.desc_ko`
세 번째 기둥 속에 박혀 있던 얼음 조각. 녹여 마시면 추위가 덜 스민다.

#### 중급 포션 · `data/items/medium_potion.json:.desc_ko`
깊은 상처도 아물지만 통증이 오래 간다.

#### 광부의 쓴 차 · `data/items/mine_bitter_tea.json:.desc_ko`
갱도에서 졸음을 쫓던 검은 찻물. 식은 지 오래인데도 혀끝이 저리다.

#### 갱도 폭약 · `data/items/mine_explosive.json:.desc_ko`
광부들이 숨겨 둔 폭약. 무너진 갱도도 뚫는다. 탄광 밖으로는 가져갈 수 없다.

#### 고블린 가죽 장화 · `data/items/mine_goblin_boots.json:.desc_ko`
고블린 광부가 신던 장화를 사람 발에 맞게 늘인 것. 바닥에 쇠못이 박혀 있다.

#### 녹광 물약 · `data/items/mine_green_tonic.json:.desc_ko`
녹색 결정 가루를 녹인 물약. 마시면 상처 둘레가 희미하게 빛나며 아문다.

#### 광부의 망치 · `data/items/mine_hammer.json:.desc_ko`
바위를 깨던 묵직한 망치. 자루에 손때가 새까맣게 배었다.

#### 녹색 결정 · `data/items/mine_heart.json:.desc_ko`
광차 밑에 깔려 있던 녹색 결정. 쥐면 맥박이 빨라진다.

#### 광부 안전모 · `data/items/mine_helmet.json:.desc_ko`
초를 꽂는 받침이 달린 쇠 모자. 이마 쪽이 돌에 수없이 긁혀 있다.

#### 광부 도시락 · `data/items/mine_lunchbox.json:.desc_ko`
양철 통에 꾹꾹 눌러 담은 보리밥과 절인 고기. 뚜껑에 누군가의 이름이 긁혀 있다.

#### 형광 이끼 고약 · `data/items/mine_moss_salve.json:.desc_ko`
빛나는 이끼를 짓이겨 기름에 갠 고약. 바르면 화끈하다가 이내 서늘해진다.

#### 고블린 화약 주머니 · `data/items/mine_powder_pouch.json:.desc_ko`
고블린이 심지째 묶어 둔 화약 주머니. 냄새만 맡아도 눈이 맵다.

#### 녹수정 반지 · `data/items/mine_quartz_ring.json:.desc_ko`
갱도에서 캔 초록 수정을 깎아 끼운 반지. 어둠 속에서 아주 희미하게 빛난다.

#### 덜 다듬은 녹색 원석 · `data/items/mine_rough_gem.json:.desc_ko`
광맥에서 떼어 낸 녹색 원석. 다듬으면 제법 값이 나간다.

#### 하급 포션 · `data/items/minor_potion.json:.desc_ko`
상처가 빠르게 아문다. 아무는 동안 신경이 곤두선다.

#### 네크로노미콘 · `data/items/necronomicon.json:.desc_ko`
피로 쓴 흑마법서. 펼치면 글자가 꿈틀댄다. 성채 밖으로 가져가면 비싸게 팔린다.

#### 오래된 금화 · `data/items/old_gold_coin.json:.desc_ko`
묘에 함께 묻힌 금화. 새겨진 얼굴도, 그 얼굴이 다스리던 성벽 밖의 나라도 이제 아무도 모른다.

#### 오래된 은화 · `data/items/old_silver_coin.json:.desc_ko`
균열 너머 성채에서 쓰던 은화. 라프도니아의 어느 상인도 이 무늬의 나라를 알지 못한다.

#### 누빔 갑옷 · `data/items/padded_armor.json:.desc_ko`
천을 여러 겹 누빈 갑옷. 무겁고 덥다.

#### 마른 식량 · `data/items/ration.json:.desc_ko`
딱딱하게 말린 빵과 고기. 고기 역시 마석으로 지은 것이니, 무엇의 고기인지는 묻지 않는 편이 낫다.

#### 균열석 · `data/items/rift_stone.json:.desc_ko`
균열의 수호자가 남긴 붉은 돌. 쥐면 바람이 느껴지는데, 이 세상 어디에도 없는 하늘에서 부는 바람이다.

#### 썩은 고기 · `data/items/rotten_meat.json:.desc_ko`
코를 찌르는 냄새. 먹을 것은 못 되지만 미끼로 사 가는 사람이 있다.

#### 녹슨 군장 버클 · `data/items/rusty_buckle.json:.desc_ko`
성채 병사들의 군장에 달려 있던 버클. 녹 사이로 문장이 보인다.

#### 녹슨 못 한 줌 · `data/items/rusty_nails.json:.desc_ko`
굽은 못과 부러진 못이 뒤섞여 있다. 녹이 손에 묻어난다.

#### 녹슨 곡괭이 날 · `data/items/rusty_pick_head.json:.desc_ko`
자루가 빠진 곡괭이 날. 녹을 벗기면 쓸 만하다.

#### 낡은 수의 조각 · `data/items/shroud_rag.json:.desc_ko`
시신을 감쌌던 천 조각. 미궁은 시신을 문 밖으로 내보내지 않으니, 남는 것은 이런 천뿐이다.

#### 성채 은화 상자 · `data/items/silver_chest.json:.desc_ko`
성채 무기고에 숨겨 두었던 은화 상자. 흔들면 묵직한 소리가 난다.

#### 연막탄 · `data/items/smoke_bomb.json:.desc_ko`
던지면 깨지며 매운 연기를 쏟아 낸다. 도망칠 틈을 번다.

#### 설련화 · `data/items/snow_lotus.json:.desc_ko`
얼음 위에서만 피는 흰 꽃. 꽃잎을 씹으면 몸속까지 맑아진다.

#### 영혼 포션 · `data/items/soul_potion.json:.desc_ko`
푸르게 빛나는 물약. 약사들은 마석 가루로 빚는다지만, 그 빛은 마석보다 정수를 닮았다.

#### 샘물 병 · `data/items/spring_water.json:.desc_ko`
맑은 샘에서 떠 온 물. 한 모금이면 다리가 가벼워진다.

#### 딱딱한 빵 끄트머리 · `data/items/stale_crust.json:.desc_ko`
손님이 남기고 간 빵 끄트머리. 이로 뜯어야 할 만큼 굳었다.

#### 강철 사리 · `data/items/steel_relic.json:.desc_ko`
회전 칼날 속에서 굳은 강철 구슬. 묘를 지키던 이의 마지막 조각이다.

#### 강철 창 · `data/items/steel_spear.json:.desc_ko`
긴 창. 다가오기 전에 찌른다.

#### 강철 검 · `data/items/steel_sword.json:.desc_ko`
평범한 강철 검. 날이 서 있는 동안은 믿을 만하다.

#### 돌빵 · `data/items/stone_bread.json:.desc_ko`
이름처럼 딱딱하다. 한 끼라기보다 이를 단련하는 간식.

#### 방부 연고 · `data/items/tomb_embalm_salve.json:.desc_ko`
시신을 보존하던 연고. 산 사람의 상처에도 썩음을 멈춘다.

#### 묘지기 건틀릿 · `data/items/tomb_gauntlets.json:.desc_ko`
갑옷 진열실에 걸려 있던 건틀릿. 손가락 마디마다 쇠못이 박혔다.

#### 황금 부장품 · `data/items/tomb_gold.json:.desc_ko`
관 곁에 놓여 있던 황금 장신구. 진짜만 이렇게 무겁다.

#### 묘지기의 통투구 · `data/items/tomb_greathelm.json:.desc_ko`
얼굴까지 가리는 통투구. 숨구멍으로 묘의 냉기가 스민다.

#### 정화의 향 · `data/items/tomb_incense.json:.desc_ko`
묘지기가 피우던 향. 연기가 몸에 붙은 저주를 걷어 낸다.

#### 기사단 방패 · `data/items/tomb_knight_shield.json:.desc_ko`
묘에 잠든 기사단의 방패. 문장 위로 금빛이 바랬다.

#### 묘지기의 등잔 기름 · `data/items/tomb_lamp_oil.json:.desc_ko`
묘지기가 등잔에 붓던 기름. 횃불에 적시면 하루를 버틴다.

#### 금박 장례 가면 조각 · `data/items/tomb_mask_shard.json:.desc_ko`
금박을 입힌 장례 가면의 조각. 반쪽 얼굴이 웃고 있다.

#### 묘지기의 성유 · `data/items/tomb_oil.json:.desc_ko`
묘지기가 등잔에 쓰던 성유. 손등에 바르면 몸이 가벼워진다.

#### 의식 목걸이 · `data/items/tomb_ritual_amulet.json:.desc_ko`
망자의 목에 걸려 있던 수정 목걸이. 맑은 소리가 난다.

#### 의식용 단검 · `data/items/tomb_ritual_dagger.json:.desc_ko`
장례 의식에 쓰던 단검. 날에 새겨진 기도문은 어느 신전에서도 쓰지 않는 말이다.

#### 봉인 부적 · `data/items/tomb_seal_charm.json:.desc_ko`
석관 뚜껑에 붙어 있던 부적. 망자에게 붙이면 움직임이 굳는다.

#### 부장품 은반지 · `data/items/tomb_silver_ring.json:.desc_ko`
석관 속 손가락에서 빠져나온 은반지.

#### 횃불 · `data/items/torch.json:.desc_ko`
한 번 불을 붙이면 사흘쯤 탄다. 투구 홈에 꽂아 두면 손이 자유롭다.

#### 타다 남은 횃불 · `data/items/torch_stub.json:.desc_ko`
누군가 쓰다 버린 횃불 토막. 버린 이가 차원문 밖으로 돌아갔는지는 알 수 없다.

#### 찢어진 수배서 · `data/items/torn_bounty.json:.desc_ko`
게시판에서 떨어진 수배서. 현상금 자리만 찢겨 나갔다.

#### 여행용 망토 · `data/items/travel_cloak.json:.desc_ko`
찬 바닥에서 덮고 자는 망토. 라비기온 뒷골목에서는 이것 한 장이 이불이다.

#### 노끈 타래 · `data/items/twine.json:.desc_ko`
짐을 묶다 남은 노끈. 어디에 쓰든 하나쯤 있으면 든든하다.

#### 깨진 항아리 조각 · `data/items/urn_shard.json:.desc_ko`
부장품 항아리의 조각. 유약이 아직 곱다.

#### 숫돌 · `data/items/whetstone.json:.desc_ko`
고운 숫돌. 몇 번 문지르면 날에 다시 빛이 돈다.

#### 나무 방패 · `data/items/wooden_shield.json:.desc_ko`
판자에 쇠테를 두른 방패.

#### 손목 감개 · `data/items/wrist_wrap.json:.desc_ko`
수련생들이 손목에 감던 천. 땀 냄새가 배어 있다.

### 장비 소재

#### 강철 · `data/materials.json:{steel}.flavor_ko`
어느 대장간에서나 두드리는 흔한 쇠.

#### 라이티늄 · `data/materials.json:{lightium}.flavor_ko`
깃털처럼 가벼운 은빛 금속.

#### 아이릴제 · `data/materials.json:{airilje}.flavor_ko`
담금질하면 푸른 결이 도는 금속.

#### 아이디움 · `data/materials.json:{idium}.flavor_ko`
무겁고 둔하지만 좀처럼 이가 나가지 않는 금속.

#### 월광석 · `data/materials.json:{moonstone}.flavor_ko`
어둠 속에서 달빛처럼 희미하게 빛나는 광석.

#### 오리하르콘 · `data/materials.json:{orichalcum}.flavor_ko`
붉은 금빛이 도는 옛 금속. 쥐면 미지근하다.

#### 미스릴 · `data/materials.json:{mithril}.flavor_ko`
은보다 가볍고 강철보다 질기다.

#### 아다만티움 · `data/materials.json:{adamantium}.flavor_ko`
웬만한 불로는 녹지도 않는 금속.

#### 미스티움 · `data/materials.json:{mystium}.flavor_ko`
마력이 스미는 금속. 쥐고 있으면 손끝이 저릿하다.

#### 아크 · `data/materials.json:{ark}.flavor_ko`
미궁 높은 층에서만 나온다는 검은 금속.

#### 무두질 가죽 · `data/materials.json:{tanned}.flavor_ko`
잘 무두질한 소가죽.

#### 와이번 가죽 · `data/materials.json:{wyvern}.flavor_ko`
비늘 자국이 남은 와이번의 질긴 가죽.

#### 트롤 가죽 · `data/materials.json:{troll_hide}.flavor_ko`
두껍고 냄새가 빠지지 않는 트롤 가죽.

#### 드레이크 가죽 · `data/materials.json:{drake}.flavor_ko`
불에 그을려도 타지 않는 드레이크 가죽.

#### 오우거 가죽 · `data/materials.json:{ogre}.flavor_ko`
칼날을 튕겨 내는 오우거의 두꺼운 가죽.

#### 고룡 가죽 · `data/materials.json:{elder_dragon}.flavor_ko`
오래 산 용의 가죽. 비늘 한 장이 손바닥보다 크다.

#### 참나무 · `data/materials.json:{oak}.flavor_ko`
곧게 자란 참나무.

#### 레드우드 · `data/materials.json:{redwood}.flavor_ko`
붉은 결이 고운 레드우드.

#### 흑철목 · `data/materials.json:{ironwood}.flavor_ko`
쇠처럼 무겁고 단단한 검은 나무.

#### 보르탈 나무 · `data/materials.json:{bortal}.flavor_ko`
휘어도 부러지지 않는 보르탈 나무.

#### 아르테네목 · `data/materials.json:{artene}.flavor_ko`
은은한 향이 나고 벌레가 슬지 않는 아르테네목.

#### 세계수 · `data/materials.json:{world_tree}.flavor_ko`
세계수에서 떨어진 가지. 아직 살아 있는 듯 따뜻하다.

#### 리넨 · `data/materials.json:{linen}.flavor_ko`
거칠게 짠 리넨.

#### 거미 비단 · `data/materials.json:{spider_silk}.flavor_ko`
거대 거미의 실로 짠 비단. 가볍고 잘 찢어지지 않는다.

#### 서리 양모 · `data/materials.json:{frost_wool}.flavor_ko`
설원 양의 털. 젖어도 온기가 남는다.

#### 월광 비단 · `data/materials.json:{moon_silk}.flavor_ko`
달빛 아래서만 뽑는다는 비단.

#### 정령 비단 · `data/materials.json:{spirit_silk}.flavor_ko`
정령이 머물던 고치에서 풀어낸 실.

#### 세계수 섬유 · `data/materials.json:{world_fiber}.flavor_ko`
세계수 껍질에서 뽑아낸 섬유.

#### 짐승 뼈 · `data/materials.json:{beast_bone}.flavor_ko`
짐승 뼈를 깎아 다듬었다.

#### 트롤 뼈 · `data/materials.json:{troll_bone}.flavor_ko`
부러져도 다시 붙는다는 트롤의 뼈.

#### 드레이크 뼈 · `data/materials.json:{drake_bone}.flavor_ko`
불 냄새가 밴 드레이크의 뼈.

#### 수정 · `data/materials.json:{quartz}.flavor_ko`
맑은 수정.

#### 호박 · `data/materials.json:{amber}.flavor_ko`
작은 벌레 하나가 갇힌 호박.

#### 비취 · `data/materials.json:{jade}.flavor_ko`
서늘한 초록빛 비취.

#### 흑요석 · `data/materials.json:{obsidian}.flavor_ko`
가장자리가 칼날처럼 날카로운 흑요석.

#### 용혈석 · `data/materials.json:{bloodstone}.flavor_ko`
붉은 줄이 맥박처럼 흐르는 용혈석.

#### 블루스톤 · `data/materials.json:{bluestone}.flavor_ko`
깊은 물빛의 블루스톤. 오래 들여다보면 어지럽다.

### 장비 종류

#### 단검 · `data/item_types.json:{dagger}.flavor_ko`
짧고 가벼워 소매 속에 숨기기 좋다.

#### 장검 · `data/item_types.json:{sword}.flavor_ko`
베고 찌르기에 두루 쓰는 곧은 날.

#### 대검 · `data/item_types.json:{greatsword}.flavor_ko`
두 손으로 휘둘러야 하는 길고 무거운 날.

#### 도끼 · `data/item_types.json:{axe}.flavor_ko`
날 끝에 무게가 몰려 내리찍을 때 힘이 실린다.

#### 철퇴 · `data/item_types.json:{mace}.flavor_ko`
갑옷째 뼈를 부수는 머리.

#### 전투 망치 · `data/item_types.json:{warhammer}.flavor_ko`
한 번 휘두르면 투구가 우그러진다.

#### 창 · `data/item_types.json:{spear}.flavor_ko`
상대가 다가오기 전에 먼저 찌른다.

#### 미늘창 · `data/item_types.json:{halberd}.flavor_ko`
창날과 도끼날을 한 자루에 달았다.

#### 곤봉 · `data/item_types.json:{club}.flavor_ko`
투박하지만 맞으면 아프다.

#### 활 · `data/item_types.json:{bow}.flavor_ko`
시위를 당기면 팔이 떨릴 만큼 팽팽하다.

#### 석궁 · `data/item_types.json:{crossbow}.flavor_ko`
장전은 느려도 한 발이 무겁다.

#### 지팡이 · `data/item_types.json:{staff}.flavor_ko`
걸을 때 짚고 싸울 때 휘두른다.

#### 소형 방패 · `data/item_types.json:{buckler}.flavor_ko`
주먹만 한 방패. 막기보다 쳐내는 데 쓴다.

#### 방패 · `data/item_types.json:{shield}.flavor_ko`
몸통을 가릴 만한 방패.

#### 대형 방패 · `data/item_types.json:{tower_shield}.flavor_ko`
뒤에 숨으면 사람 하나가 다 가려진다.

#### 누비 갑옷 · `data/item_types.json:{padded}.flavor_ko`
여러 겹 누볐다. 덥지만 몸을 감싼다.

#### 로브 · `data/item_types.json:{robe}.flavor_ko`
발목까지 내려오는 헐렁한 옷.

#### 가죽 갑옷 · `data/item_types.json:{leather_armor}.flavor_ko`
몸에 맞게 재단한 조끼. 움직이기 편하다.

#### 사슬 갑옷 · `data/item_types.json:{chainmail}.flavor_ko`
고리 수천 개를 엮었다. 무게가 어깨에 걸린다.

#### 판금 갑옷 · `data/item_types.json:{plate}.flavor_ko`
온몸을 판으로 감쌌다. 무겁다.

#### 두건 · `data/item_types.json:{hood}.flavor_ko`
머리와 목을 덮는다.

#### 투구 · `data/item_types.json:{helm}.flavor_ko`
이마와 정수리를 지킨다.

#### 통투구 · `data/item_types.json:{greathelm}.flavor_ko`
얼굴까지 덮어 제 숨소리가 크게 들린다.

#### 장갑 · `data/item_types.json:{gloves}.flavor_ko`
손에 꼭 맞아 손잡이가 미끄러지지 않는다.

#### 건틀릿 · `data/item_types.json:{gauntlets}.flavor_ko`
마디마디 손가락을 감싼다.

#### 장화 · `data/item_types.json:{boots}.flavor_ko`
발목까지 올라온다. 발소리가 작다.

#### 쇠 장화 · `data/item_types.json:{sabatons}.flavor_ko`
무겁지만 발등을 밟혀도 끄떡없다.

#### 허리띠 · `data/item_types.json:{belt}.flavor_ko`
주머니와 칼집을 달 수 있다.

#### 망토 · `data/item_types.json:{cloak}.flavor_ko`
바람을 막고, 찬 바닥에서는 덮고 잔다.

#### 반지 · `data/item_types.json:{ring}.flavor_ko`
손가락에 꼭 맞는 작은 고리.

#### 목걸이 · `data/item_types.json:{amulet}.flavor_ko`
목에 걸어 가슴께에 늘어뜨린다.

### 몬스터

#### 원령 · `data/monsters/banshee.json:.passives{banshee_wraith}.desc_ko`
물리 공격이 통하지 않는다. 먼저 손댄 자에게 원한을 새긴다.

#### 벤시 · `data/monsters/banshee.json:.desc_ko`
흐느끼는 영체. 거의 먼저 덤비지 않는다.

#### 추적 후각 · `data/monsters/blade_wolf.json:.passives{wolf_tracking_scent}.desc_ko`
냄새로 숨은 것을 찾아내고, 달아나는 것을 놓치지 않는다.

#### 칼날늑대 · `data/monsters/blade_wolf.json:.desc_ko`
칼날 같은 털을 세운 늑대. 무리 지어 약한 쪽부터 문다.

#### 원한 · `data/monsters/blater.json:.passives{blater_grudge_aura}.desc_ko`
데스나이트의 원한이 적의 치유와 재생을 절반으로 만든다.

#### 저주받은 기사 블라터 · `data/monsters/blater.json:.desc_ko`
핏빛성채의 수호자. 원한에 사로잡힌 데스나이트.

#### 피 냄새 · `data/monsters/blood_blade_wolf.json:.passives{wolf_blood_scent}.desc_ko`
피 흘리는 상대에게 더 사납게 덤빈다.

#### 핏빛 칼날늑대 · `data/monsters/blood_blade_wolf.json:.desc_ko`
털끝이 피에 젖은 듯 붉다. 상처 난 먹잇감을 놓지 않는다.

#### 방부제 · `data/monsters/bone_knight.json:.passives{bk_preservative}.desc_ko`
중독·출혈·부패의 피해가 절반이다.

#### 본 나이트 · `data/monsters/bone_knight.json:.desc_ko`
뼈 장검을 든 기사. 갈망·슬픔·증오 중 하나의 기운을 띤다. 증오의 기사는 영혼을 벤다.

#### 관 속의 망자 · `data/monsters/buried_one.json:.passives{coffin_dead}.desc_ko`
한 번 쓰러져도 관에서 다시 일어난다.

#### 배리드언 · `data/monsters/buried_one.json:.desc_ko`
묘지 철퇴를 든 매장된 자. 쓰러뜨려도 한 번은 일어난다.

#### 여러 개의 머리 · `data/monsters/chimera_wolf.json:.passives{chimera_many_heads}.desc_ko`
머리가 여럿이라 한 번에 두 번 문다.

#### 키메라 울프 · `data/monsters/chimera_wolf.json:.desc_ko`
근육이 울퉁불퉁한 돌연변이 늑대. 머리가 서너 개.

#### 구리 몸체 · `data/monsters/copper_golem.json:.passives{copper_body}.desc_ko`
베고 찌르는 공격에 강하지만 전기가 잘 통한다.

#### 코퍼 골렘 · `data/monsters/copper_golem.json:.desc_ko`
구리로 만든 골렘. 달아오르면 더 세게 친다.

#### 시체 덩어리 · `data/monsters/corpse_golem.json:.passives{golem_corpse_mass}.desc_ko`
불에 약하다. 많이 타거나 반쯤 부서지면 뼈대만 남는다.

#### 시체골렘 · `data/monsters/corpse_golem.json:.desc_ko`
사람의 팔다리와 머리 수천 개를 뭉친 덩어리. 입마다 기괴한 말을 쏟아낸다.

#### 오염된 진흙 · `data/monsters/corrupted_gnome.json:.passives{gnome_corrupted_mud}.desc_ko`
독이 스민 진흙. 맞으면 가끔 중독되고, 진흙 몸의 성질도 반쯤 남아 있다.

#### 타락한 노움 · `data/monsters/corrupted_gnome.json:.desc_ko`
검게 썩은 진흙으로 빚어진 노움. 저주를 던진다.

#### 썩은 몸 · `data/monsters/deadman.json:.passives{deadman_rotten_body}.desc_ko`
썩어 버린 몸이라 출혈도 독도 듣지 않는다.

#### 데드맨 · `data/monsters/deadman.json:.desc_ko`
걸어 다니는 시체. 물어뜯고 붙잡는다.

#### 썩은 지휘 · `data/monsters/deadman_commander.json:.passives{deadman_rotten_command}.desc_ko`
곁의 데드맨들이 더 힘껏 휘두른다.

#### 지휘관 데드맨 · `data/monsters/deadman_commander.json:.desc_ko`
조금 큰 체구의 데드맨. 뿔피리를 지녔다.

#### 육체보존 · `data/monsters/deathfiend.json:.passives{deathfiend_preservation}.desc_ko`
출혈이 금세 멎고, 상처가 빠르게 아문다.

#### 데스핀드 · `data/monsters/deathfiend.json:.desc_ko`
키가 3m 넘는 언데드. 양팔에 칼과 방패가 달렸다. 느리고 영역 밖으로는 쫓지 않는다.

#### 갉아먹는 공포 · `data/monsters/dreadfear.json:.passives{dread_gnawing_fear}.desc_ko`
라운드가 끝날 때마다 주변의 공포를 키우고, 상처 입을수록 분노한다.

#### 드레드피어 · `data/monsters/dreadfear.json:.desc_ko`
1층의 계층군주. 왜소한 사람의 형체에 구더기가 들끓고, 뼈로 된 대검을 휘두른다. 균열의 수호자를 모두 쓰러뜨린 자가 대현자 기념비에서 부르면 나타난다.

#### 들러붙는 구더기 · `data/monsters/dreadfear_maggot.json:.passives{dread_maggot_cling}.desc_ko`
맞힌 상대의 공포를 키운다.

#### 드레드피어의 구더기 · `data/monsters/dreadfear_maggot.json:.desc_ko`
드레드피어의 몸에서 떨어져 나온 엄지손가락만 한 구더기. 들러붙어 공포를 옮긴다.

#### 썩은 거구 · `data/monsters/elder_ghoul.json:.passives{elder_rotten_bulk}.desc_ko`
두꺼운 썩은 살이 충격을 먹고, 피도 흐르지 않는다.

#### 엘더 구울 · `data/monsters/elder_ghoul.json:.desc_ko`
보통 구울의 두 배쯤 되는 몸집.

#### 서리 털가죽 · `data/monsters/frost_wolf.json:.passives{frost_fur}.desc_ko`
냉기에 강하고, 물리면 서리가 내려앉는다.

#### 서리 늑대 · `data/monsters/frost_wolf.json:.desc_ko`
흰 털에 서리가 낀 늑대. 균열을 빼면 6층에서야 만난다.

#### 돌 피부 · `data/monsters/gargoyle_statue.json:.passives{gargoyle_stone_skin}.desc_ko`
베고 찌르는 공격에 강하고 둔기에 약하다.

#### 가고일 석상 · `data/monsters/gargoyle_statue.json:.desc_ko`
가만히 있다가 다가오면 석화를 쏘며 움직인다.

#### 네 발 짐승 · `data/monsters/ghoul.json:.passives{ghoul_four_legs}.desc_ko`
네 발로 튀어나가 먼저 덤벼든다.

#### 구울 · `data/monsters/ghoul.json:.desc_ko`
썩은 살갗에 긴 손톱, 네 발로 긴다. 가까이 가기 전에는 먼저 덤비지 않고, 늘 같은 순서로 할퀸다.

#### 무리의 주인 · `data/monsters/ghoul_lord.json:.passives{ghoullord_master}.desc_ko`
엘더 구울을 거느리고, 곁의 구울들을 사납게 만든다.

#### 구울로드 · `data/monsters/ghoul_lord.json:.desc_ko`
엘더 구울을 서른 마리씩 데리고 다닌다.

#### 두꺼운 칼날털 · `data/monsters/giant_blade_wolf.json:.passives{wolf_thick_bladefur}.desc_ko`
가까이서 때리면 칼날털에 베인다.

#### 거대 칼날늑대 · `data/monsters/giant_blade_wolf.json:.desc_ko`
보통 칼날늑대보다 훨씬 큰 놈. 털이 갑옷처럼 두껍다.

#### 진흙 몸 · `data/monsters/gnome.json:.passives{gnome_mud_body}.desc_ko`
베고 찌르는 것엔 무르지만 내려치면 잘 부서진다.

#### 노움 · `data/monsters/gnome.json:.desc_ko`
진흙 인형. [일체화]로 주변과 하나가 되어, 3m 안에 들어와야 모습이 보인다.

#### 마비독 칼날 · `data/monsters/goblin.json:.passives{goblin_paralytic_blade}.desc_ko`
근접 공격이 맞으면 가끔 상대를 마비독에 빠뜨린다.

#### 고블린 · `data/monsters/goblin.json:.desc_ko`
가장 약한 마물. 짧은 단검에 마비독을 바르고 덫을 놓는다. 서너 마리씩 몰려다닌다.

#### 독화살 · `data/monsters/goblin_archer.json:.passives{goblin_poison_arrow}.desc_ko`
활로 맞히면 가끔 독이 퍼진다.

#### 고블린 궁수 · `data/monsters/goblin_archer.json:.desc_ko`
키키키 웃으며 작은 단궁을 쏜다. 화살촉엔 독, 몸에는 은신의 이능.

#### 폭약 주머니 · `data/monsters/goblin_bomber.json:.passives{powder_pouch}.desc_ko`
허리춤에 폭약이 잔뜩 — 쓰러지면 터지고, 불이 닿으면 가끔 제 몸에서 터진다.

#### 고블린 폭탄병 · `data/monsters/goblin_bomber.json:.desc_ko`
폭약 주머니를 주렁주렁 단 고블린. 불을 대면 제 폭약에 다친다.

#### 광부모 · `data/monsters/goblin_miner.json:.passives{miner_helmet}.desc_ko`
광부모가 첫 일격을 받아 낸다.

#### 고블린 광부 · `data/monsters/goblin_miner.json:.desc_ko`
광부모를 쓰고 곡괭이를 멘 다부진 고블린. 1층 균열에서만 나온다.

#### 어설픈 검술 · `data/monsters/goblin_swordsman.json:.passives{goblin_crude_swordplay}.desc_ko`
베기 공격의 치명타가 잦고, 치명타는 출혈을 남긴다.

#### 고블린 검사 · `data/monsters/goblin_swordsman.json:.desc_ko`
조악한 검을 든 고블린. 그 검은 사람이 쓰기엔 형편없다.

#### 감시자 · `data/monsters/guardian_eye.json:.passives{watcher}.desc_ko`
숨은 것도 보고, 이 눈이 지켜보는 곳에선 함정이 더 잘 발동한다.

#### 수호자의 눈 · `data/monsters/guardian_eye.json:.desc_ko`
묘를 감시하며 떠다니는 커다란 눈.

#### 광부의 근력 · `data/monsters/hobgoblin_miner.json:.passives{miner_strength}.desc_ko`
곡괭이가 갑옷 틈을 파고든다.

#### 홉고블린 광부 · `data/monsters/hobgoblin_miner.json:.desc_ko`
홉고블린의 변이종. 대형 곡괭이를 휘두르고 무기에 독을 바른다.

#### 냉기 오러 · `data/monsters/ice_golem.json:.passives{cold_aura}.desc_ko`
주위에 냉기를 뿌린다. 시간이 지날수록 몸이 무거워진다.

#### 아이스 골렘 · `data/monsters/ice_golem.json:.desc_ko`
얼음으로 빚은 거인. 곁에 있으면 몸이 점점 굳는다.

#### 한기의 매개 · `data/monsters/ice_orc_shaman.json:.passives{chill_medium}.desc_ko`
곁의 아군이 다루는 냉기가 강해진다.

#### 아이스 오크 주술사 · `data/monsters/ice_orc_shaman.json:.desc_ko`
얼음 지팡이를 든 오크. 동료 앞에 강철 같은 얼음벽을 세운다.

#### 얼음 피부 · `data/monsters/ice_orc_warrior.json:.passives{ice_skin}.desc_ko`
냉기에 강하지만 불에 약하다.

#### 아이스 오크 전사 · `data/monsters/ice_orc_warrior.json:.desc_ko`
얼음 기둥에 갇혀 있다 깨어난 오크. 얼음 도끼를 휘두른다.

#### 불멸의 강철 · `data/monsters/ildium.json:.passives{immortal_steel}.desc_ko`
칼날이 거의 들지 않고 전기가 통한다. 절반쯤 부서지면 달아오른다.

#### 철인 일디움 · `data/monsters/ildium.json:.desc_ko`
강철의 분묘에 잠든 강철 거인.

#### 강철 갑주 · `data/monsters/iron_cavalry.json:.passives{steel_plate}.desc_ko`
칼날이 잘 안 들지만 전기가 통한다. 첫 돌격이 빠르다.

#### 철기병 · `data/monsters/iron_cavalry.json:.desc_ko`
강철 갑주를 두른 기병. 랜스를 낮추고 돌격한다.

#### 강철 비늘 · `data/monsters/iron_lizardman.json:.passives{steel_scales}.desc_ko`
강철 비늘이 칼날을 막지만 추위에 약하다.

#### 아이언 리자드맨 · `data/monsters/iron_lizardman.json:.desc_ko`
강철 비늘의 리자드맨. 삼지창과 꼬리를 쓴다.

#### 뱀파이어의 육신 · `data/monsters/kambormir.json:.passives{vamp_flesh}.desc_ko`
상처가 순식간에 아문다.

#### 뱀파이어 공작 캠보르미어 · `data/monsters/kambormir.json:.desc_ko`
창백한 피부의 흡혈귀 공작. 피로 문신을 새겨 제물로 삼는다. 태양에 약하다.

#### 설원의 군주 · `data/monsters/katumba.json:.passives{snow_lord}.desc_ko`
냉기가 듣지 않고, 상처가 조금씩 아문다.

#### 설원의 군주 카툼바 · `data/monsters/katumba.json:.desc_ko`
예티의 상위 변이종. 토템의 마지막 물결 뒤에 나타나 짓누른다.

#### 슬라임의 왕 · `data/monsters/king_slime.json:.passives{slime_king}.desc_ko`
둔기는 튕겨 낸다. 크게 다칠 때마다 슬라임이 떨어져 나온다.

#### 킹 슬라임 · `data/monsters/king_slime.json:.desc_ko`
'뀨이이잇' 소리를 내는 거대한 초록 점액. 반경 50m 공동의 주인.

#### 트롤의 재생 · `data/monsters/kirdui.json:.passives{troll_regen}.desc_ko`
상처가 눈에 보이게 아문다. 머리를 노려라.

#### 타락한 짐승 키르뒤 · `data/monsters/kirdui.json:.desc_ko`
검은 피부의 거대한 트롤. 오우거의 휘두르기를 쓴다.

#### 광물 외피 · `data/monsters/mineral_slime.json:.passives{mineral_shell}.desc_ko`
광석이 박힌 외피가 칼날을 막지만 마법에 약하다.

#### 광물 슬라임 · `data/monsters/mineral_slime.json:.desc_ko`
광석 조각이 잔뜩 박힌 슬라임.

#### 미라 붕대 · `data/monsters/mummy.json:.passives{mummy_bandage}.desc_ko`
마른 붕대라 독도 출혈도 없지만 불에 잘 탄다.

#### 머미 · `data/monsters/mummy.json:.desc_ko`
누런 붕대로 감긴 시체.

#### 야행 시각 · `data/monsters/owlbear.json:.passives{night_sight}.desc_ko`
숨은 것도 본다. 잘 맞힌다.

#### 아울베어 · `data/monsters/owlbear.json:.desc_ko`
부엉이 머리에 곰의 몸. 빙하굴 개체는 털빛이 옅다.

#### 수수께끼의 봉인 · `data/monsters/riddle_gatekeeper.json:.passives{riddle_seal}.desc_ko`
마주한 자에게 수수께끼를 낸다. 답에 따라 길을 내주거나, 약해지거나, 성을 낸다.

#### 수수께끼 문지기 · `data/monsters/riddle_gatekeeper.json:.desc_ko`
3챕터 끝 문 앞의 강철 문지기. 창을 세우고 수수께끼를 낸다.

#### 기습 사냥꾼 · `data/monsters/sabertooth.json:.passives{ambush_hunter}.desc_ko`
첫 일격에 급소를 노린다.

#### 샤벨 타이거 · `data/monsters/sabertooth.json:.desc_ko`
긴 송곳니의 큰 고양이. 빙하굴 개체는 털빛이 희다.

#### 갈비뼈 속 핵 · `data/monsters/skeleton_archer.json:.passives{skeleton_core}.desc_ko`
베고 찌르는 공격은 갈비뼈에 막힌다. 핵을 노리거나 부숴라.

#### 스켈레톤 아처 · `data/monsters/skeleton_archer.json:.desc_ko`
뼈로 된 활을 쏜다.

#### 갈비뼈 속 핵 · `data/monsters/skeleton_mage.json:.passives{skeleton_core}.desc_ko`
베고 찌르는 공격은 갈비뼈에 막힌다. 핵을 노리거나 부숴라.

#### 스켈레톤 메이지 · `data/monsters/skeleton_mage.json:.desc_ko`
그림자 화살을 날리는 해골 마법사.

#### 쥐떼 · `data/monsters/skull_rat.json:.passives{rat_swarm}.desc_ko`
늘 떼로 몰려다닌다.

#### 스컬 랫 · `data/monsters/skull_rat.json:.desc_ko`
뼈만 남은 쥐.

#### 말랑한 몸 · `data/monsters/slime.json:.passives{soft_body}.desc_ko`
둔기는 튕겨 내지만 베이면 잘 갈라진다.

#### 슬라임 · `data/monsters/slime.json:.desc_ko`
초록 점액 덩어리. 반쯤 다치면 둘로 갈라진다.

#### 썩은 몸 · `data/monsters/soldier_deadman.json:.passives{deadman_rotten_body}.desc_ko`
썩어 버린 몸이라 출혈도 독도 듣지 않는다.

#### 병사 데드맨 · `data/monsters/soldier_deadman.json:.desc_ko`
녹슨 갑옷을 걸친 데드맨.

#### 혹한의 폭군 · `data/monsters/tarunbas.json:.passives{tyrant_of_frost}.desc_ko`
냉기가 듣지 않고 전기에 약하다. 가까이서 맞으면 서리가 맺힌다.

#### 폭군 타룬바스 · `data/monsters/tarunbas.json:.desc_ko`
회백색 털의 거대한 라이칸스로프. 얼음몽둥이로 땅을 무너뜨린다.

#### 암석 껍질 · `data/monsters/wormstone.json:.passives{rock_shell}.desc_ko`
바위 껍질이 베고 찌르는 공격을 막는다.

#### 웜스톤 · `data/monsters/wormstone.json:.desc_ko`
바위 껍질을 두른 커다란 벌레. 얼음 틈에 숨어 있다 튀어나온다.

#### 설인의 털 · `data/monsters/yeti.json:.passives{yeti_fur}.desc_ko`
냉기에 아주 강하지만 불에 약하다.

#### 예티 · `data/monsters/yeti.json:.desc_ko`
흰 털로 뒤덮인 거인. 빙하굴 입구를 지키는 문지기.

### 정수

#### 원령 · `data/essences/banshee.json:.passive.desc_ko`
받는 물리 피해가 조금 줄고, 그 울음을 들은 상대는 공포에 더 깊이 얼어붙는다.

#### 추적 후각 · `data/essences/blade_wolf.json:.passive.desc_ko`
코끝으로 숨은 것을 찾아내고, 피 냄새를 따라 흘리는 상대를 놓치지 않는다.

#### 원한 · `data/essences/blater.json:.passive.desc_ko`
전투가 시작되면 적 전원의 치유가 줄어든다.

#### 피 냄새 · `data/essences/blood_blade_wolf.json:.passive.desc_ko`
피 흘리는 상대에게 조금 더 아프게 들어간다.

#### 방부제 · `data/essences/bone_knight.json:.passive.desc_ko`
중독·출혈·부패의 피해가 절반이다.

#### 관 속의 망자 · `data/essences/buried_one.json:.passive.desc_ko`
전투마다 한 번, 쓰러질 일격을 생명력 1로 버틴다.

#### 여러 개의 머리 · `data/essences/chimera_wolf.json:.passive.desc_ko`
기본 공격이 가끔 한 번 더 들어간다.

#### 구리 몸체 · `data/essences/copper_golem.json:.passive.desc_ko`
칼날에 조금 강해지지만 전기를 더 탄다.

#### 시체 덩어리 · `data/essences/corpse_golem.json:.passive.desc_ko`
물리 피해에 강해지지만 불에 약해진다.

#### 오염된 진흙 · `data/essences/corrupted_gnome.json:.passive.desc_ko`
맞힌 상대를 가끔 중독시키고, 독이 돈 상대를 더 아프게 하며, 진흙 몸의 성질이 조금 남는다.

#### 썩은 몸 · `data/essences/deadman.json:.passive.desc_ko`
썩어 버린 몸이라 출혈도 독도 듣지 않는다.

#### 썩은 지휘 · `data/essences/deadman_commander.json:.passive.desc_ko`
곁의 데드맨 계열 동료가 조금 더 힘을 낸다.

#### 육체보존 · `data/essences/deathfiend.json:.passive.desc_ko`
상처가 빨리 아물고 출혈이 일찍 멎으며, 적을 쓰러뜨리면 몸을 추스른다.

#### 공포의 군주 · `data/essences/dreadfear.json:.passive.desc_ko`
전투가 시작되면 적 전원이 위축된다.

#### 썩은 거구 · `data/essences/elder_ghoul.json:.passive.desc_ko`
몸이 두꺼워져 물리 피해를 조금 덜 받고, 피가 흐르지 않는다.

#### 서리 털가죽 · `data/essences/frost_wolf.json:.passive.desc_ko`
냉기에 조금 강하고, 물린 쪽에 서리가 내려앉는다.

#### 돌 피부 · `data/essences/gargoyle_statue.json:.passive.desc_ko`
베고 찌르는 공격에 강하고 둔기에 약하며, 웅크린 채 맞으면 돌 발톱으로 되받아친다.

#### 네 발 짐승 · `data/essences/ghoul.json:.passive.desc_ko`
전투가 시작되면 먼저 몸을 날리고, 쓰러뜨린 상대를 뜯어 상처를 메운다.

#### 무리의 주인 · `data/essences/ghoul_lord.json:.passive.desc_ko`
불러낸 구울 계열 동료의 근력이 오른다.

#### 두꺼운 칼날털 · `data/essences/giant_blade_wolf.json:.passive.desc_ko`
가까이서 때린 상대가 칼날털에 베여 피를 흘린다.

#### 진흙 몸 · `data/essences/gnome.json:.passive.desc_ko`
베기·찌르기에 덜 다치지만 둔기에는 더 다친다.

#### 마비독 칼날 · `data/essences/goblin.json:.passive.desc_ko`
근접 무기로 맞힐 때 가끔 마비독을 남기고, 묶인 상대를 더 아프게 벤다.

#### 독화살 · `data/essences/goblin_archer.json:.passive.desc_ko`
활로 맞히면 가끔 독이 퍼지고, 독이 돈 상대를 더 아프게 맞힌다.

#### 폭약 주머니 · `data/essences/goblin_bomber.json:.passive.desc_ko`
불을 더 잘 다루지만 불에 더 다친다.

#### 광부모 · `data/essences/goblin_miner.json:.passive.desc_ko`
전투의 첫 피격을 조금 덜 아프게 받는다.

#### 어설픈 검술 · `data/essences/goblin_swordsman.json:.passive.desc_ko`
베기 치명타가 잦고, 치명타는 출혈을 남기며, 피 흘리는 상대를 더 깊게 벤다.

#### 감시자 · `data/essences/guardian_eye.json:.passive.desc_ko`
숨은 적도 겨눌 수 있다.

#### 광부의 근력 · `data/essences/hobgoblin_miner.json:.passive.desc_ko`
공격이 방어를 조금 파고든다.

#### 냉기 오러 · `data/essences/ice_golem.json:.passive.desc_ko`
자기 차례가 끝날 때마다 적 하나를 굼뜨게 한다.

#### 한기의 매개 · `data/essences/ice_orc_shaman.json:.passive.desc_ko`
동료가 다루는 냉기가 조금 강해진다.

#### 얼음 피부 · `data/essences/ice_orc_warrior.json:.passive.desc_ko`
냉기에 조금 강하지만 불에 조금 약해진다.

#### 불멸의 강철 · `data/essences/ildium.json:.passive.desc_ko`
칼날에 강해진다.

#### 강철 갑주 · `data/essences/iron_cavalry.json:.passive.desc_ko`
칼날에 조금 강해지고 첫 차례가 조금 빠르다.

#### 강철 비늘 · `data/essences/iron_lizardman.json:.passive.desc_ko`
베기에 조금 강해지지만 추위를 더 탄다.

#### 뱀파이어의 육신 · `data/essences/kambormir.json:.passive.desc_ko`
상처가 빨리 아물지만 태양에 약해진다.

#### 설원의 군주 · `data/essences/katumba.json:.passive.desc_ko`
냉기에 강해지고 상처가 아주 조금씩 아문다.

#### 슬라임의 왕 · `data/essences/king_slime.json:.passive.desc_ko`
둔기에 강해지고, 처음 크게 다치면 슬라임 둘이 도우러 나온다.

#### 트롤의 재생 · `data/essences/kirdui.json:.passive.desc_ko`
상처가 빠르게 아문다.

#### 광물 외피 · `data/essences/mineral_slime.json:.passive.desc_ko`
칼날에 조금 강해지지만 마법에 조금 약해진다.

#### 미라 붕대 · `data/essences/mummy.json:.passive.desc_ko`
출혈이 듣지 않지만 불에 조금 약해진다.

#### 야행 시각 · `data/essences/owlbear.json:.passive.desc_ko`
숨은 적도 겨눌 수 있고, 조금 더 잘 맞힌다.

#### 수수께끼의 봉인 · `data/essences/riddle_gatekeeper.json:.passive.desc_ko`
봉인이 듣지 않는다.

#### 기습 사냥꾼 · `data/essences/sabertooth.json:.passive.desc_ko`
전투의 첫 일격 치명타율이 오른다.

#### 갈비뼈 속 핵 · `data/essences/skeleton_archer.json:.passive.desc_ko`
베고 찌르는 공격에 조금 강하지만 둔기에 약하다.

#### 갈비뼈 속 핵 · `data/essences/skeleton_mage.json:.passive.desc_ko`
베고 찌르는 공격에 조금 강하지만 둔기에 약하다.

#### 쥐떼 · `data/essences/skull_rat.json:.passive.desc_ko`
몸이 날래 남보다 조금 먼저 움직인다.

#### 말랑한 몸 · `data/essences/slime.json:.passive.desc_ko`
둔기에 조금 강해지지만 베기에 조금 약해진다.

#### 썩은 몸 · `data/essences/soldier_deadman.json:.passive.desc_ko`
썩어 버린 몸이라 출혈도 독도 듣지 않는다.

#### 혹한의 폭군 · `data/essences/tarunbas.json:.passive.desc_ko`
냉기에 강해지고, 둔기로 때리면 냉기가 함께 들어간다.

#### 암석 껍질 · `data/essences/wormstone.json:.passive.desc_ko`
베고 찌르는 공격을 조금 막는다.

#### 설인의 털 · `data/essences/yeti.json:.passive.desc_ko`
냉기에 강해지지만 불에 약해진다.

### 스킬

#### 공격 · `data/skills/basic_attack.json:.desc_ko`
손에 든 것으로 친다.

#### 뼈 대검 내려치기 · `data/skills/dread_bone_cleave.json:.desc_ko`
구더기가 들끓는 뼈 대검을 내리친다.

#### 죽은 자의 기억 · `data/skills/dread_dead_memory.json:.desc_ko`
죽은 자들의 기억을 불러 모은다. 잠시 뒤 어둠이 세 번 떨어진다.

#### 증오 폭발 · `data/skills/dread_hate_explosion.json:.desc_ko`
쌓인 증오가 터져 모두를 집어삼킨다.

#### 면죄부 · `data/skills/dread_indulgence.json:.desc_ko`
대열을 흐트러뜨리고 한 명을 홀로 떼어 놓는다.

#### 내면의 거울 · `data/skills/dread_inner_mirror.json:.desc_ko`
마음속 공포를 비춰 그만큼 상처를 입힌다. 피하거나 막을 수 없다.

#### 구더기 소환 · `data/skills/dread_summon_maggots.json:.desc_ko`
몸에서 구더기 떼가 쏟아져 나온다.

#### 조사 · `data/skills/investigate.json:.desc_ko`
상대를 찬찬히 살펴 알아낸다. 살피는 동안 손은 놀고 있다.

#### 기어올라 물기 · `data/skills/maggot_crawl_bite.json:.desc_ko`
몸을 타고 기어올라 문다.

#### 강타 · `data/skills/power_strike.json:.desc_ko`
온 힘을 실어 내려친다. 다음 차례가 늦어진다.

#### 대화 · `data/skills/talk.json:.desc_ko`
말을 건다. 말이 통하는 상대라면 흔들 수도, 자극할 수도 있다. 마수에게는 통하지 않는다.

### 상태이상

#### 허기 · `data/statuses.json:{hungry}.desc_ko`
배가 고프다. 몸이 조금 무겁다.

#### 굶주림 · `data/statuses.json:{starving}.desc_ko`
굶주림에 손이 떨린다. 상처도 아물지 않는다.

#### 아사 · `data/statuses.json:{starvation}.desc_ko`
몸이 스스로를 갉아먹는다.

#### 영혼탈진 · `data/statuses.json:{soul_exhaustion}.desc_ko`
영혼이 바닥났다. 이능을 쓸 수 없다.

#### 중독 · `data/statuses.json:{poison}.desc_ko`
독이 돈다. 차례마다 생명력이 깎인다. 독 저항이 높으면 덜 걸리고 덜 아프다.

#### 기절 · `data/statuses.json:{stun}.desc_ko`
정신이 아득해져 한 차례 움직일 수 없다.

#### 저체온증 · `data/statuses.json:{hypothermia}.desc_ko`
뼛속까지 얼어붙는다. 냉기 내성이 낮을수록 굼떠지고(최대 민첩 −30%), 냉기에 두 배로 다친다.

#### 실명 · `data/statuses.json:{blind}.desc_ko`
눈에 무언가 들어갔다. 공격이 잘 맞지 않는다.

#### 덫 · `data/statuses.json:{trap_set}.desc_ko`
발밑에 덫이 놓였다. 다음 차례에 덫이 문다.

#### 마비 · `data/statuses.json:{paralysis}.desc_ko`
몸이 말을 듣지 않는다. 한 차례 움직일 수 없다.

#### 속박 · `data/statuses.json:{snare}.desc_ko`
발이 묶였다. 도망칠 수 없고 몸놀림이 둔하다.

#### 은신 · `data/statuses.json:{hidden}.desc_ko`
모습을 감췄다. 다른 상대가 있으면 노려지지 않는다.

#### 부패 · `data/statuses.json:{rot}.desc_ko`
상처가 썩어 들어간다. 저절로 낫지 않는다.

#### 막고 찌르기 · `data/statuses.json:{counter_stance}.desc_ko`
검을 세워 막는다. 근접 공격을 받으면 되찌른다.

#### 위축 · `data/statuses.json:{intimidated}.desc_ko`
포효에 기가 죽었다. 힘이 빠진다.

#### 무기력증 · `data/statuses.json:{lethargy}.desc_ko`
영혼이 축 늘어졌다. 이능을 쓸 수 없고 영혼력이 차오르지 않는다.

#### 탈진 · `data/statuses.json:{exhaustion}.desc_ko`
몸이 말을 듣지 않는다. 근력·민첩·물리내성이 크게 떨어진다.

#### 고립 · `data/statuses.json:{isolated}.desc_ko`
대열에서 떨어져 홀로 남았다. 받는 피해가 늘어난다.

#### 공포의 증식 · `data/statuses.json:{dread_proliferating}.desc_ko`
공포가 불어난다. 중첩마다 근력·정신력이 오르고, 많이 쌓이면 더 자주 움직인다.

#### 스며드는 공포 · `data/statuses.json:{dread_seeping}.desc_ko`
공포가 스며들어 손이 떨린다. 명중률이 떨어지고 가끔 동료를 친다.

#### 배신의 장막 · `data/statuses.json:{dread_veil}.desc_ko`
서로를 알아볼 수 없다. 동료 하나를 고르는 이능을 쓸 수 없고, 공격이 자주 동료에게 향한다.

#### 보호기제 · `data/statuses.json:{dread_groggy}.desc_ko`
껍질 속으로 숨어 움직이지 않는다. 받는 피해가 늘어난다.

#### 분노 · `data/statuses.json:{dread_rage}.desc_ko`
분노로 모든 피해가 두 배가 된다.

#### 증오 폭발 · `data/statuses.json:{dread_hatred_burst}.desc_ko`
증오가 넘쳐흐른다. 매 차례 모두를 덮친다.

#### 사람의 형체 · `data/statuses.json:{dread_human_form}.desc_ko`
구더기가 흩어지고 사람의 모습이 드러났다. 라운드마다 두 번 움직인다.

#### 뼈에 새겨진 기억 · `data/statuses.json:{dread_buff_bone_memory}.desc_ko`
주는 피해가 늘고, 맞힌 상대의 영혼을 빨아들여 증오를 키운다.

#### 밀랍 갑주 · `data/statuses.json:{dread_buff_wax_armor}.desc_ko`
녹아내린 밀랍이 몸을 덮어 물리 피해를 덜 받는다.

#### 응시하는 눈 · `data/statuses.json:{dread_buff_staring_eye}.desc_ko`
수많은 눈이 열려 빈틈을 노린다. 명중률과 치명타율이 오른다.

#### 구더기 둥지 · `data/statuses.json:{dread_buff_maggot_nest}.desc_ko`
몸이 둥지가 되어 라운드마다 구더기가 기어 나온다.

#### 원망의 메아리 · `data/statuses.json:{dread_buff_echo}.desc_ko`
공격이 맞을 때마다 원망이 메아리친다.

#### 석화 · `data/statuses.json:{petrify}.desc_ko`
몸이 돌로 굳었다. 두 차례 움직일 수 없지만 단단해진다.

#### 진압 · `data/statuses.json:{suppress}.desc_ko`
짓눌려 움직일 수 없다. 피해를 조금이라도 받으면 풀린다.

#### 서리 · `data/statuses.json:{frost}.desc_ko`
서리가 내려앉는다. 쌓일수록 굼떠지고, 세 겹이면 얼어붙는다.

#### 빙결 · `data/statuses.json:{frozen}.desc_ko`
얼음에 갇혔다. 한 차례 움직일 수 없다. 불에 닿으면 녹는다.

#### 혼란 · `data/statuses.json:{confusion}.desc_ko`
정신이 흐려져 아무나 공격한다.

#### 원한의 징표 · `data/statuses.json:{grudge_mark}.desc_ko`
벤시의 원한이 새겨졌다. 미궁이 닫힐 때까지 벤시가 멀리서도 알아보고 먼저 노린다.

#### 제물 · `data/statuses.json:{sacrifice_mark}.desc_ko`
제물로 찍혔다. 표식마다 캠보르미어가 강해진다.

#### 봉인 · `data/statuses.json:{seal}.desc_ko`
이능 하나가 봉인되었다.

#### 원한 · `data/statuses.json:{heal_block}.desc_ko`
원한이 상처를 붙든다. 받는 치유와 재생이 절반이 된다.

#### 예고 · `data/statuses.json:{telegraphed}.desc_ko`
무언가가 이쪽을 노리고 있다. 막을 준비를 하라.

#### 진군 명령 · `data/statuses.json:{march_order}.desc_ko`
다음 공격이 강해진다.

#### 방패팔 막기 · `data/statuses.json:{shield_arm}.desc_ko`
방패팔을 세워 물리 피해를 막는다.

#### 생기 흡수 · `data/statuses.json:{vitality_drain}.desc_ko`
공격이 맞으면 준 피해의 일부를 빨아들인다.

#### 타오른 살점 · `data/statuses.json:{golem_burned}.desc_ko`
살점이 타 버렸다.

#### 뼈대 형태 · `data/statuses.json:{golem_skeleton}.desc_ko`
살점이 떨어져 뼈대만 남았다. 마력핵이 드러난다.

#### 원한 · `data/statuses.json:{blater_grudge}.desc_ko`
데스나이트의 원한이 상처를 붙든다. 받는 치유와 재생이 절반이 된다.

#### 옅은 원한 · `data/statuses.json:{blater_grudge_weak}.desc_ko`
받는 치유가 줄어든다.

#### 광분 · `data/statuses.json:{guardian_frenzy}.desc_ko`
궁지에 몰려 연달아 움직인다.

#### 피의 향연 · `data/statuses.json:{vamp_blood_feast}.desc_ko`
제물의 수만큼 육체가 강해진다.

#### 피의 장막 · `data/statuses.json:{vamp_blood_veil}.desc_ko`
피의 장막이 몸을 감싼다.

#### 재생 정지 · `data/statuses.json:{regen_stopped}.desc_ko`
심장이 꿰뚫려 재생이 멎었다.

#### 봉인된 저항 · `data/statuses.json:{tear_sealed}.desc_ko`
여신의 눈물이 악의 저항을 봉인했다.

#### 기습 사냥꾼 · `data/statuses.json:{ambush_hunter}.desc_ko`
첫 일격을 노린다. 치명타율이 크게 오른다.

#### 기습 · `data/statuses.json:{ambush_hunter_weak}.desc_ko`
첫 일격의 치명타율이 오른다.

#### 강철빙벽 · `data/statuses.json:{steel_ice_wall}.desc_ko`
강철처럼 단단한 얼음벽이 피해를 먼저 받아 낸다.

#### 트롤의 광분 · `data/statuses.json:{troll_frenzy}.desc_ko`
통증이 사라지고 육체가 부풀어 오른다. 공포도 기절도 듣지 않는다.

#### 광부모 · `data/statuses.json:{miner_helmet}.desc_ko`
단단한 광부모가 첫 일격을 받아 낸다.

#### 광부모 · `data/statuses.json:{miner_helmet_weak}.desc_ko`
첫 일격을 조금 덜 아프게 받는다.

#### 독성부여 · `data/statuses.json:{venom_weapon}.desc_ko`
무기에 독이 발렸다. 맞히면 중독시킨다.

#### 과열 · `data/statuses.json:{overheat}.desc_ko`
몸이 벌겋게 달아올라 힘이 세지지만, 스스로 녹아내린다.

#### 부식 · `data/statuses.json:{acid_corrosion}.desc_ko`
산성 점액이 갑옷과 살갗을 녹인다.

#### 방패 벽 · `data/statuses.json:{shield_wall}.desc_ko`
방패를 맞대어 벽을 세웠다.

#### 과열 · `data/statuses.json:{ildium_overheat}.desc_ko`
강철 몸이 벌겋게 달아올랐다. 힘은 세지고 몸은 물러졌다.

#### 자석 · `data/statuses.json:{magnetized}.desc_ko`
몸이 강철 거인 쪽으로 끌려간다. 다음 일격은 피할 수 없다.

#### 풀린 봉인 · `data/statuses.json:{riddle_weakened}.desc_ko`
수수께끼가 풀려 문지기를 묶던 힘이 빠졌다.

#### 분노한 봉인 · `data/statuses.json:{riddle_empowered}.desc_ko`
틀린 답에 문지기의 봉인이 성을 낸다.

### 전투 게이지

#### 공포 · `data/meters.json:{dread_fear}.desc_ko`
마음을 갉아먹는 두려움. 가득 차면 공포에 질린다.

#### 역병 · `data/meters.json:{dread_plague}.desc_ko`
영혼을 좀먹는 역병. 가득 차면 무기력증에 빠진다.

#### 원망 · `data/meters.json:{dread_resentment}.desc_ko`
몸에 쌓이는 원망. 가득 차면 탈진한다.

#### 분노 · `data/meters.json:{dread_rage}.desc_ko`
받은 상처만큼 끓어오른다. 가득 차면 모든 피해가 두 배가 된다.

#### 증오 · `data/meters.json:{dread_hatred}.desc_ko`
가득 차면 증오가 폭발해 매 차례 모두를 덮친다.

#### 타는 살점 · `data/meters.json:{golem_fire}.desc_ko`
받은 화염 피해가 쌓인다. 가득 차면 살점이 타 버린다.

### 랜드마크

#### 대현자 기념비 · `data/landmarks.json:{sage_monument}.desc_ko`
동굴 한가운데 선 오래된 비석. 주변은 이상하리만치 조용하다.

#### 네모 수정 삼거리 · `data/landmarks.json:{square_crystal_junction}.desc_ko`
여러 갈래 길이 만나는 작은 공터 한가운데 네모반듯한 수정이 박혀 있다.

#### 큰바위 옆 연못 · `data/landmarks.json:{boulder_pond}.desc_ko`
집채만 한 바위 곁에 검은 물이 고여 있다.

### 종족 · 직업

#### 인간 · `data/races.json:{human}.desc_ko`
어디에나 있는 종족. 모든 면에서 무난하다.

#### 바바리안 · `data/races.json:{barbarian}.desc_ko`
거구의 전사 종족. 힘과 맷집은 타고났지만 이능에는 둔하다.

#### 전사 · `data/classes.json:{warrior}.desc_ko`
방패를 들고 앞을 막는다.

#### 검사 · `data/classes.json:{swordsman}.desc_ko`
검 한 자루로 길을 연다.

#### 창술사 · `data/classes.json:{spearman}.desc_ko`
긴 창으로 거리를 지배한다.

#### 궁수 · `data/classes.json:{archer}.desc_ko`
어둠 너머를 노린다. 가까이 붙으면 끝이다.

### 균열(설명 · 챕터)

#### 핏빛성채 · `data/rifts/rift_blood_fortress.json:.desc_ko`
검은 포탈 너머 붉은 하늘과 까마귀 떼, 멀리 흑빛 성채가 보인다.

#### 외곽 검문소 · `data/rifts/rift_blood_fortress.json:.chapters{ch1}.desc_ko`
데드맨들이 지키는 검문소.

#### 도개교 · `data/rifts/rift_blood_fortress.json:.chapters{ch2}.desc_ko`
내려진 도개교 너머로 성채의 문이 보인다.

#### 외성벽 시가지 · `data/rifts/rift_blood_fortress.json:.chapters{ch3}.desc_ko`
한 무리에 수십 마리 — 쉴 틈 없는 연전. 광장 한가운데 마른 분수대가 있다.

#### 내성벽 지하 감옥 · `data/rifts/rift_blood_fortress.json:.chapters{ch4}.desc_ko`
축축한 감옥. 쥐와 영체가 떠돌고, 깊은 곳에 시체골렘이 웅얼거린다.

#### 영주성 악마 숭배실 · `data/rifts/rift_blood_fortress.json:.chapters{ch5}.desc_ko`
'ㅁ'자 회랑 끝 숭배실. 썩은 책장들 너머에서 수호자가 깨어난다.

#### 빙하굴 · `data/rifts/rift_glacier_cave.json:.desc_ko`
얼어붙은 설산과 눈송이, 얼음에 반사된 햇빛. 호수 지대를 지나면 땅속으로 이어지는 굴이 나온다.

#### 문지기와 얼음 동굴 · `data/rifts/rift_glacier_cave.json:.chapters{ch1}.desc_ko`
문지기 예티를 지나면 서리 늑대가 사는 얼음 동굴. 일정한 간격의 기둥이 길잡이다. 시작 자리 옆에 작은 연못이 있다.

#### 얼음 계단과 토템 · `data/rifts/rift_glacier_cave.json:.chapters{ch2}.desc_ko`
얼음 계단 아래 중심 토템에서 끝없이 쏟아지는 무리 — 아홉 물결 뒤 설원의 군주. 길잡이 기둥 하나에 금이 가 있다.

#### 지하수맥 · `data/rifts/rift_glacier_cave.json:.chapters{ch3}.desc_ko`
타룬바스가 지면을 무너뜨려 떨어졌고, 지하수맥 폭포에 떠밀렸다. 뼛속까지 춥다. 얼음벽 너머에서 무언가 움직이고, 공동의 얼음 기둥 속에 오크들이 갇혀 있다.

#### 얼음 가루가 쏟아지는 공동 · `data/rifts/rift_glacier_cave.json:.chapters{ch4}.desc_ko`
천장에서 얼음 가루가 쏟아지며 수호자가 내려온다.

#### 녹색 탄광 · `data/rifts/rift_green_mine.json:.desc_ko`
철로가 깔린 음산한 갱도. 나무 폐자재가 널려 있다.

#### 일자 갱도 · `data/rifts/rift_green_mine.json:.chapters{ch1}.desc_ko`
천장이 무너져 막힌 곳에서 시작한다. 철로를 따라 곡괭이 소리가 울린다. 어딘가 철로가 끊긴 벽이 있다.

#### 무너진 다리 · `data/rifts/rift_green_mine.json:.chapters{ch2}.desc_ko`
3분의 2가 무너진 다리. 옆 통로로 돌거나 건너뛸 수 있다. 다리 너머에서 폭약 냄새가 난다.

#### 절벽의 원형 계단 · `data/rifts/rift_green_mine.json:.chapters{ch3}.desc_ko`
절벽 가장자리를 따라 원형 계단을 내려간다. 아래 갱도는 무너져 막혀 있다 — 어딘가 폭약이 있을 것이다.

#### 무너진 공동 · `data/rifts/rift_green_mine.json:.chapters{ch4}.desc_ko`
폭약으로 뚫은 갱도 끝, 반경 50m의 공동. 끈적한 소리가 사방에서 들린다.

#### 강철의 묘 · `data/rifts/rift_iron_tomb.json:.desc_ko`
사방이 어둡고 좁은 금속 복도. 벽화 같은 문양이 새겨져 있다.

#### 함정 복도 · `data/rifts/rift_iron_tomb.json:.chapters{ch1}.desc_ko`
사방이 어둡고 좁은 금속 복도. 벽에는 벽화 같은 문양이 새겨져 있고, 바닥 어딘가에 압력판과 화살 함정이 숨어 있다.

#### 회전 칼날의 방 · `data/rifts/rift_iron_tomb.json:.chapters{ch2}.desc_ko`
칼날이 도는 방을 지난다. 떠다니는 눈이 복도를 지켜본다.

#### 수수께끼 문 앞 · `data/rifts/rift_iron_tomb.json:.chapters{ch3}.desc_ko`
묘실로 가는 마지막 복도. 문 앞에 강철 문지기가 창을 세우고 서 있다.

#### 강철의 분묘 · `data/rifts/rift_iron_tomb.json:.chapters{ch4}.desc_ko`
강철로 된 분묘. 거대한 강철 거인이 몸을 일으킨다.

### 수수께끼(문제 · 벽화)

#### 수수께끼 · `data/riddles/iron_tomb_riddles.json:{riddle_steel}.question_ko`
불 속에서 태어나 물속에서 단단해진다. 쉬게 두면 붉게 늙어 무너지고, 날마다 부리면 오래 산다. 나는 무엇인가?

#### 수수께끼 1 · `data/riddles/iron_tomb_riddles.json:{riddle_steel}.hints_ko[0]`
벽화: 도공이 가마에서 갓 꺼낸 것을 찬물에 담그자, 쩍 소리와 함께 갈라진다.

#### 수수께끼 2 · `data/riddles/iron_tomb_riddles.json:{riddle_steel}.hints_ko[1]`
벽화: 푸른 녹이 앉은 종은 아직 맑게 울리는데, 그 곁의 붉게 얼룩진 문짝은 주저앉아 있다.

#### 수수께끼 3 · `data/riddles/iron_tomb_riddles.json:{riddle_steel}.hints_ko[2]`
벽화: 흙을 구워 쌓은 담은 세울 때부터 붉었고, 백 년이 지나도 그대로 서 있다.

#### 수수께끼 · `data/riddles/iron_tomb_riddles.json:{riddle_coffin}.question_ko`
만드는 이는 팔려고 만들고, 값을 치른 이는 제 몸에 쓰지 않으며, 쓰는 이는 끝내 그것을 보지 못한다. 나는 무엇인가?

#### 수수께끼 1 · `data/riddles/iron_tomb_riddles.json:{riddle_coffin}.hints_ko[0]`
벽화: 흔들리는 바구니 속 아기가 눈을 뜨고, 머리 위에 매달린 방울을 바라본다.

#### 수수께끼 2 · `data/riddles/iron_tomb_riddles.json:{riddle_coffin}.hints_ko[1]`
벽화: 왕이 제 손으로 무언가를 머리에 얹고, 거울 속 자신을 오래 들여다본다.

#### 수수께끼 3 · `data/riddles/iron_tomb_riddles.json:{riddle_coffin}.hints_ko[2]`
벽화: 지친 일꾼이 제 돈으로 산 것 위에 몸을 누이고 코를 곤다.

#### 수수께끼 · `data/riddles/iron_tomb_riddles.json:{riddle_shadow}.question_ko`
눈이 없어도 너를 따라오고, 발이 없어도 때로 너보다 앞서 간다. 해가 뜨면 깨어나고, 모든 빛이 꺼지면 함께 잠든다. 나는 무엇인가?

#### 수수께끼 1 · `data/riddles/iron_tomb_riddles.json:{riddle_shadow}.hints_ko[0]`
벽화: 소리치는 사람과 입을 다문 사람이 나란히 걷는데, 둘 다 똑같이 무언가를 데리고 간다.

#### 수수께끼 2 · `data/riddles/iron_tomb_riddles.json:{riddle_shadow}.hints_ko[1]`
벽화: 얕은 물을 건너는 나그네 — 지나온 물 위에는 아무것도 남지 않았는데, 그는 혼자가 아니다.

#### 수수께끼 3 · `data/riddles/iron_tomb_riddles.json:{riddle_shadow}.hints_ko[2]`
벽화: 한낮의 밭, 눈을 뜨고 일하는 사람들 곁에 저마다 짝이 하나씩 붙어 있다.

#### 수수께끼 · `data/riddles/iron_tomb_riddles.json:{riddle_silence}.question_ko`
누구나 만들 수 있고 누구나 깰 수 있다. 그러나 나를 부르는 순간, 나는 이미 깨져 있다. 나는 무엇인가?

#### 수수께끼 1 · `data/riddles/iron_tomb_riddles.json:{riddle_silence}.hints_ko[0]`
벽화: 사람들이 거울 앞에서 목청껏 외친다 — 거울 속 얼굴들도 따라 입을 벌릴 뿐, 금 하나 가지 않는다.

#### 수수께끼 2 · `data/riddles/iron_tomb_riddles.json:{riddle_silence}.hints_ko[1]`
벽화: 한 사내가 큰 소리로 맹세하고, 사람들이 그 말을 돌에 새긴다. 입 밖에 내고 나서야 그것이 생겼다.

#### 수수께끼 3 · `data/riddles/iron_tomb_riddles.json:{riddle_silence}.hints_ko[2]`
벽화: 언 호수 위에서 아이들이 노래하며 뛰논다. 발밑은 멀쩡하다.

#### 수수께끼 · `data/riddles/iron_tomb_riddles.json:{riddle_dark}.question_ko`
많이 모일수록 앞이 덜 보인다. 손으로 쥘 수 없고, 등불 하나에 물러나지만 등불이 꺼지면 어김없이 돌아온다. 나는 무엇인가?

#### 수수께끼 1 · `data/riddles/iron_tomb_riddles.json:{riddle_dark}.hints_ko[0]`
벽화: 백발의 묘지기가 묘실 끝까지 걸어가, 벽에 작은 글씨를 또박또박 새긴다.

#### 수수께끼 2 · `data/riddles/iron_tomb_riddles.json:{riddle_dark}.hints_ko[1]`
벽화: 우는 아이에게 누군가 소매를 내밀자, 아이가 얼굴을 훔친다.

#### 수수께끼 3 · `data/riddles/iron_tomb_riddles.json:{riddle_dark}.hints_ko[2]`
벽화: 늪가에서 등불을 높이 들었는데도, 한 치 앞이 여전히 뿌옇다.

#### 수수께끼 · `data/riddles/iron_tomb_riddles.json:{riddle_fire}.question_ko`
먹이면 자라고, 굶기면 죽는다. 그런데 물을 마시면 그 자리에서 죽는다. 나는 무엇인가?

#### 수수께끼 1 · `data/riddles/iron_tomb_riddles.json:{riddle_fire}.hints_ko[0]`
벽화: 가뭄 끝에 비가 내리자, 시들던 가지마다 새잎이 돋는다.

#### 수수께끼 2 · `data/riddles/iron_tomb_riddles.json:{riddle_fire}.hints_ko[1]`
벽화: 사막을 걷는 나그네 — 아무것도 먹지 않았는데, 그를 괴롭히는 것은 점점 커진다.

#### 수수께끼 3 · `data/riddles/iron_tomb_riddles.json:{riddle_fire}.hints_ko[2]`
벽화: 상인이 자루를 창고 구석에 둔다. 해가 바뀌어도 자루는 늘지도 줄지도 않았다.

#### 수수께끼 · `data/riddles/iron_tomb_riddles.json:{riddle_key}.question_ko`
이가 있어도 물지 않는다. 평생 단 하나의 짝만 알아보고, 그 짝을 만나면 막힌 길을 연다. 나는 무엇인가?

#### 수수께끼 1 · `data/riddles/iron_tomb_riddles.json:{riddle_key}.hints_ko[0]`
벽화: 목수가 이 달린 것으로 통나무를 물어뜯듯 켜 나간다.

#### 수수께끼 2 · `data/riddles/iron_tomb_riddles.json:{riddle_key}.hints_ko[1]`
벽화: 여인이 엉킨 머리를 이 달린 것으로 가지런히 고른다. 그녀의 방문은 여전히 닫혀 있다.

#### 수수께끼 3 · `data/riddles/iron_tomb_riddles.json:{riddle_key}.hints_ko[2]`
벽화: 마당에 흩어진 낙엽을 이 달린 것으로 긁어모은다.

#### 수수께끼 · `data/riddles/iron_tomb_riddles.json:{riddle_name}.question_ko`
분명 네 것인데 남들이 너보다 더 자주 쓴다. 네가 죽어도 돌 위에 남는다. 나는 무엇인가?

#### 수수께끼 1 · `data/riddles/iron_tomb_riddles.json:{riddle_name}.hints_ko[0]`
벽화: 묘비 앞에서 사람들이 고인을 부르지만, 돌에서는 아무 소리도 돌아오지 않는다.

#### 수수께끼 2 · `data/riddles/iron_tomb_riddles.json:{riddle_name}.hints_ko[1]`
벽화: 무덤 안에는 한 사람만 누워 있고, 다른 이들은 그 앞에 서 있을 뿐 들어가지 않는다.

#### 수수께끼 3 · `data/riddles/iron_tomb_riddles.json:{riddle_name}.hints_ko[2]`
벽화: 비가 그친 진흙길 — 어제 지나간 이들의 흔적이 모두 씻겨 나갔다.

## 상황 문구

### 기록 · 일반 알림

#### welcome · `data/strings/ko.json:.log.welcome`
차원광장의 돌바닥은 차갑다. 기록을 시작한다.

#### rolled · `data/strings/ko.json:.log.rolled`
{race} {template}. 타고난 몸을 확인했다.

#### damage · `data/strings/ko.json:.log.damage`
{amount}의 피해를 입었다.

#### spend_ok · `data/strings/ko.json:.log.spend_ok`
영혼력 {amount}을 태웠다.

#### spend_fail · `data/strings/ko.json:.log.spend_fail`
영혼력이 모자란다. 아무 일도 일어나지 않았다.

#### turn · `data/strings/ko.json:.log.turn`
한 턴이 지났다.

#### hour · `data/strings/ko.json:.log.hour`
한 시간이 지났다.

#### hour_city · `data/strings/ko.json:.log.hour_city`
한 시간이 지났다. 도시에서는 배가 고파지지 않는다.

#### eat · `data/strings/ko.json:.log.eat`
마른 식량을 씹어 삼켰다.

#### buff_on · `data/strings/ko.json:.log.buff_on`
근력의 비약을 들이켰다. 근력 +{amount}.

#### buff_off · `data/strings/ko.json:.log.buff_off`
비약 기운을 털어냈다.

#### buff_expired · `data/strings/ko.json:.log.buff_expired`
근력의 비약 기운이 빠져나갔다.

#### status_on · `data/strings/ko.json:.log.status_on`
[{status}] 상태가 되었다.

#### status_off · `data/strings/ko.json:.log.status_off`
[{status}] 상태에서 벗어났다.

#### depleted · `data/strings/ko.json:.log.depleted`
{resource}이(가) 바닥났다.

#### recovered · `data/strings/ko.json:.log.recovered`
{resource}이(가) 다시 차오른다.

#### level · `data/strings/ko.json:.log.level`
레벨 {level}. 영혼의 그릇이 달라졌다.

#### restore · `data/strings/ko.json:.log.restore`
숨을 고르고 몸을 추슬렀다.

### 캐릭터 만들기

#### items_none · `data/strings/ko.json:.create.items_none`
빈손이다.

### 탐험 알림 · boss_notice

#### boss_notice.any · `data/strings/ko.json:.explore.boss_notice.any`
{name}이(가) 당신을 응시한다.

#### boss_notice.blater · `data/strings/ko.json:.explore.boss_notice.blater`
녹슨 갑옷의 기사가 천천히 고개를 든다. 투구 틈의 붉은 눈이 당신을 응시한다.

#### boss_notice.kambormir · `data/strings/ko.json:.explore.boss_notice.kambormir`
창백한 사내가 천천히 고개를 돌린다. 핏기 없는 입가에 웃음이 번진다.

#### boss_notice.corpse_golem · `data/strings/ko.json:.explore.boss_notice.corpse_golem`
엉겨 붙은 시체 더미가 몸을 돌린다. 수십 개의 흐린 눈이 한꺼번에 당신을 향한다.

#### boss_notice.katumba · `data/strings/ko.json:.explore.boss_notice.katumba`
눈보라 속 흰 거체가 움직임을 멈춘다. 무언가 당신을 내려다보고 있다.

#### boss_notice.tarunbas · `data/strings/ko.json:.explore.boss_notice.tarunbas`
얼음 가루 너머에서 회백색 짐승이 몸을 일으킨다. 핏발 선 두 눈이 당신을 노려본다.

#### boss_notice.kirdui · `data/strings/ko.json:.explore.boss_notice.kirdui`
웅크린 검은 거체는 꼼짝하지 않는다. 눈만이 당신을 따라 움직인다.

#### boss_notice.goblin_bomber · `data/strings/ko.json:.explore.boss_notice.goblin_bomber`
폭약 주머니를 주렁주렁 단 고블린이 당신을 발견하고 누런 이를 드러낸다.

#### boss_notice.king_slime · `data/strings/ko.json:.explore.boss_notice.king_slime`
공동 한가운데의 거대한 점액 덩어리가 출렁임을 멈춘다. 당신 쪽으로 몸을 기울인다.

#### boss_notice.ildium · `data/strings/ko.json:.explore.boss_notice.ildium`
강철 거인이 투구를 들어 올린다. 텅 빈 눈구멍이 당신을 응시한다.

### 탐험 알림

#### rift_exit_needs · `data/strings/ko.json:.explore.rift_exit_needs`
길이 막혀 있다. [{item}]이(가) 있어야 할 것 같다.

#### rift_exit_used · `data/strings/ko.json:.explore.rift_exit_used`
[{item}]을(를) 썼다.

#### rift_key_held · `data/strings/ko.json:.explore.rift_key_held`
가방에 자리가 없어 [{item}]을(를) 손에 쥐었다.

#### fortress_tear · `data/strings/ko.json:.explore.fortress_tear`
조각상을 깨뜨리자 작은 상자가 나왔다. 안에는 [{item}]이(가) 맑게 빛난다.

#### fortress_necronomicon · `data/strings/ko.json:.explore.fortress_necronomicon`
썩은 책장 사이에서 피로 쓴 책 한 권을 찾았다 — [{item}].

#### hidden_no_room · `data/strings/ko.json:.explore.hidden_no_room`
{item}을(를) 찾았지만 가방에 자리가 없다.

#### scavenge_found · `data/strings/ko.json:.explore.scavenge_found`
{tile}을(를) 뒤져 {item}을(를) 찾았다.

#### scavenge_empty · `data/strings/ko.json:.explore.scavenge_empty`
{tile}에는 건질 것이 없다.

#### scavenge_no_room · `data/strings/ko.json:.explore.scavenge_no_room`
{item}을(를) 찾았지만 가방에 자리가 없다.

#### loot_found · `data/strings/ko.json:.explore.loot_found`
{item}을(를) 주웠다.

#### loot_found_n · `data/strings/ko.json:.explore.loot_found_n`
{item} {n}개를 주웠다.

#### hidden_found · `data/strings/ko.json:.explore.hidden_found`
숨겨진 것을 찾았다 — [{item}].

#### rift_item_lost · `data/strings/ko.json:.explore.rift_item_lost`
[{item}]이(가) 균열을 나서는 순간 빛을 잃고 흩어졌다.

#### rift_opened · `data/strings/ko.json:.explore.rift_opened`
동굴 곳곳에 균열 포탈 {count}개가 열렸다!

#### rift_forced · `data/strings/ko.json:.explore.rift_forced`
기념비가 마석을 삼키고, 옆에 {name}(으)로 통하는 균열 포탈이 열렸다.

#### rift_offer · `data/strings/ko.json:.explore.rift_offer`
대현자 기념비에 {item}을(를) 바쳤다.

#### rift_offer_failed · `data/strings/ko.json:.explore.rift_offer_failed`
마석이 잠시 빛나다 꺼졌다. 균열이 열릴 자리를 찾지 못했다 — 마석은 그대로다.

#### rift_portal_found · `data/strings/ko.json:.explore.rift_portal_found`
붉게 일렁이는 균열 포탈이 보인다.

#### rift_portal_here · `data/strings/ko.json:.explore.rift_portal_here`
균열 포탈 앞이다.

#### rift_enter · `data/strings/ko.json:.explore.rift_enter`
균열 속으로 발을 들였다 — {name}.

#### rift_variant · `data/strings/ko.json:.explore.rift_variant`
공기가 무겁다. 이곳의 수호자는 평소와 다르다…

#### rift_exit_found · `data/strings/ko.json:.explore.rift_exit_found`
앞쪽에 출구가 보인다.

#### rift_exit_here · `data/strings/ko.json:.explore.rift_exit_here`
출구 앞이다.

#### rift_left · `data/strings/ko.json:.explore.rift_left`
{name}에서 빠져나왔다. 수정동굴의 공기가 반갑다.

#### lord_summoned · `data/strings/ko.json:.explore.lord_summoned`
수정의 광채가 핏빛으로 바뀐다. 무언가가 깨어났다 — {name}!

#### lord_bond · `data/strings/ko.json:.explore.lord_bond`
동료들과의 결속이 끊어진 듯 서로의 기척이 멀어진다. 눈앞이 어둑해진다.

#### lord_defeated · `data/strings/ko.json:.explore.lord_defeated`
{name}이(가) 무너져 구더기 더미가 된다. 수정의 빛이 제 색을 되찾는다.

#### lord_vanished · `data/strings/ko.json:.explore.lord_vanished`
핏빛 광채가 걷히고, 그것은 소리 없이 사라졌다.

#### enter · `data/strings/ko.json:.explore.enter`
{floor}. 발밑이 차갑다. 포탈은 등 뒤에서 닫혔다.

#### wait · `data/strings/ko.json:.explore.wait`
숨을 죽이고 {hours}시간을 기다렸다.

#### rest_safe · `data/strings/ko.json:.explore.rest_safe`
안전한 자리에서 {hours}시간을 잤다. 몸이 조금 풀렸다.

#### rest_unsafe · `data/strings/ko.json:.explore.rest_unsafe`
벽에 기대 {hours}시간을 졸았다. 쉰 것 같지 않다.

#### no_item · `data/strings/ko.json:.explore.no_item`
{item}이(가) 없다.

#### no_category · `data/strings/ko.json:.explore.no_category`
가진 {category}이(가) 없다.

#### portal_locked · `data/strings/ko.json:.explore.portal_locked`
{floor}층으로 가는 포탈이다. 소용돌이가 아직 닫혀 있어 그 너머로 갈 수 없다.

#### monument · `data/strings/ko.json:.explore.monument`
대현자 기념비. 이 근처에는 아무것도 다가오지 않는다.

#### monument_lord_call · `data/strings/ko.json:.explore.monument_lord_call`
비석에 손을 얹자 발밑 깊은 곳에서 무언가가 대답한다.

#### nothing_here · `data/strings/ko.json:.explore.nothing_here`
살펴볼 만한 것이 없다.

#### closing_soon · `data/strings/ko.json:.explore.closing_soon`
공기가 무거워진다. 층이 닫히기까지 {hours}시간.

#### closed · `data/strings/ko.json:.explore.closed`
층이 닫힌다. 보이지 않는 힘이 몸을 끌어당긴다.

#### portal_found · `data/strings/ko.json:.explore.portal_found`
{dir}에서 포탈의 빛을 보았다.

#### portal_here · `data/strings/ko.json:.explore.portal_here`
포탈 위에 섰다.

#### safe_enter · `data/strings/ko.json:.explore.safe_enter`
고요함이 감싼다. 안전지대다 — 여기서는 쉴 수 있다.

#### safe_leave · `data/strings/ko.json:.explore.safe_leave`
안전지대를 벗어났다.

#### dark_enter · `data/strings/ko.json:.explore.dark_enter`
수정 빛이 닿지 않는 곳이다. 한 치 앞도 보이지 않는다.

#### status_on · `data/strings/ko.json:.explore.status_on`
[{status}] 상태가 되었다.

#### status_off · `data/strings/ko.json:.explore.status_off`
[{status}] 상태에서 벗어났다.

#### light_out · `data/strings/ko.json:.explore.light_out`
{item}이(가) 꺼졌다. 어둠이 다가온다.

#### died · `data/strings/ko.json:.explore.died`
숨이 멎었다.

#### cannot_use · `data/strings/ko.json:.explore.cannot_use`
{item}은(는) 여기서 쓸 수 있는 물건이 아니다.

#### ambush · `data/strings/ko.json:.explore.ambush`
잠결에 무언가가 다가왔다!

#### glacier_crystal · `data/strings/ko.json:.explore.glacier_crystal`
연못 바닥에서 붉게 빛나는 얼음 구슬을 건졌다 — [{item}].

#### glacier_shard · `data/strings/ko.json:.explore.glacier_shard`
금 간 기둥을 부수자 마력이 서린 얼음 조각이 굴러 나왔다 — [{item}].

#### hazard_pass · `data/strings/ko.json:.explore.hazard_pass`
위험한 길을 무사히 지났다.

#### hazard_fail · `data/strings/ko.json:.explore.hazard_fail`
발을 헛디뎠다!

#### hazard_slick_pass · `data/strings/ko.json:.explore.hazard_slick_pass`
미끄러운 얼음 위를 조심조심 건넜다.

#### hazard_slick_fail · `data/strings/ko.json:.explore.hazard_slick_fail`
얼음에 미끄러져 크게 넘어졌다!

#### hazard_slope_pass · `data/strings/ko.json:.explore.hazard_slope_pass`
얼음 급경사를 버티며 내려갔다.

#### hazard_slope_fail · `data/strings/ko.json:.explore.hazard_slope_fail`
급경사에서 미끄러져 바닥까지 굴렀다!

#### hazard_rope_pass · `data/strings/ko.json:.explore.hazard_rope_pass`
언 로프를 붙잡고 끝까지 건넜다.

#### hazard_rope_fail · `data/strings/ko.json:.explore.hazard_rope_fail`
언 로프를 놓쳐 아래로 떨어졌다!

#### mine_gem · `data/strings/ko.json:.explore.mine_gem`
철로가 끊긴 벽을 부수자 좁은 샛길이 나왔다. 안쪽에서 [{item}]이(가) 초록빛으로 반짝인다.

#### mine_quartz · `data/strings/ko.json:.explore.mine_quartz`
광맥을 깨뜨리자 탁한 초록 수정이 떨어졌다 — [{item}].

#### mine_explosive · `data/strings/ko.json:.explore.mine_explosive`
낡은 상자 속에 광부들이 숨겨 둔 [{item}]이(가) 있다.

#### mine_blast · `data/strings/ko.json:.explore.mine_blast`
무너진 갱도가 뚫렸다.

#### mine_smash · `data/strings/ko.json:.explore.mine_smash`
무너진 바위를 맨손으로 밀어 치웠다.

#### rift_exit_forced · `data/strings/ko.json:.explore.rift_exit_forced`
힘으로 길을 열었다.

#### hazard_bridge_pass · `data/strings/ko.json:.explore.hazard_bridge_pass`
무너진 다리의 남은 들보를 딛고 건넜다.

#### hazard_bridge_fail · `data/strings/ko.json:.explore.hazard_bridge_fail`
들보가 부러져 아래로 떨어졌다!

#### hazard_stairs_pass · `data/strings/ko.json:.explore.hazard_stairs_pass`
절벽의 원형 계단을 조심조심 내려갔다.

#### hazard_stairs_fail · `data/strings/ko.json:.explore.hazard_stairs_fail`
계단이 무너져 몇 단을 굴러떨어졌다!

#### trap_detected · `data/strings/ko.json:.explore.trap_detected`
바닥 문양이 미묘하게 어긋나 있다 — 함정이다!

#### trap_disarmed · `data/strings/ko.json:.explore.trap_disarmed`
함정의 장치를 조심스럽게 풀었다.

#### trap_crushed · `data/strings/ko.json:.explore.trap_crushed`
함정을 밟아 그대로 짓뭉갰다. 이 정도로는 흠집도 안 난다.

#### trap_plate_fail · `data/strings/ko.json:.explore.trap_plate_fail`
압력판이 꺼지며 벽에서 쇠말뚝이 튀어나왔다!

#### trap_arrow_fail · `data/strings/ko.json:.explore.trap_arrow_fail`
벽 틈에서 화살이 쏟아졌다!

#### trap_blades_fail · `data/strings/ko.json:.explore.trap_blades_fail`
회전 칼날에 베였다!

#### riddle_pass · `data/strings/ko.json:.explore.riddle_pass`
문지기가 창을 거두고 옆으로 비켜선다.

#### riddle_weaken · `data/strings/ko.json:.explore.riddle_weaken`
문지기를 묶던 봉인이 풀린다 — 약해진 문지기가 창을 겨눈다.

#### riddle_wrong · `data/strings/ko.json:.explore.riddle_wrong`
틀렸다. 문지기의 문양이 붉게 타오른다!

#### party.rumor_portal · `data/strings/ko.json:.explore.party.rumor_portal`
{dir} 끝에 위층으로 오르는 포탈이 있다고 한다.

#### party.rumor_rift · `data/strings/ko.json:.explore.party.rumor_rift`
{dir}에서 균열을 봤다고 한다.

#### hidden_revealed · `data/strings/ko.json:.explore.hidden_revealed`
무언가 드러났다.

#### hidden_locked · `data/strings/ko.json:.explore.hidden_locked`
지금은 아무것도 할 수 없다.

#### hidden_failed · `data/strings/ko.json:.explore.hidden_failed`
손에 넣지 못했다.

#### hidden_decoy · `data/strings/ko.json:.explore.hidden_decoy`
손대자마자 무너져 내렸다.

### 탐험 알림 · hidden

#### hidden.tomb_oil · `data/strings/ko.json:.explore.hidden.tomb_oil`
벽감 깊숙이 봉해진 기름 단지가 그대로 있다. 묘지기들이 관절에 바르던 [{item}]이다.

#### hidden.tomb_oil_locked · `data/strings/ko.json:.explore.hidden.tomb_oil_locked`
벽감 안의 기름 단지가 깨져 있다. 함정이 울린 진동에 쓰러진 모양이다.

#### hidden.steel_relic_reveal · `data/strings/ko.json:.explore.hidden.steel_relic_reveal`
칼날이 부서지며 홈 바닥이 갈라졌다. 틈에서 작은 함 하나가 굴러 나왔다.

#### hidden.steel_relic · `data/strings/ko.json:.explore.hidden.steel_relic`
작은 함 속에 쇳빛 구슬이 들어 있다 — [{item}].

#### hidden.coffin_locked · `data/strings/ko.json:.explore.hidden.coffin_locked`
관 뚜껑에 봉인이 걸려 있다. 문지기의 물음에 답한 자만 열 수 있을 것 같다.

#### hidden.death_mask · `data/strings/ko.json:.explore.hidden.death_mask`
봉인이 풀린 관 안, 이름 모를 왕의 얼굴에 [{item}]가 씌워져 있다.

#### hidden.treasure_mark · `data/strings/ko.json:.explore.hidden.treasure_mark`
금화 사이에 벽화와 같은 문양이 새겨진 상자가 묻혀 있다.

#### hidden.treasure_plain · `data/strings/ko.json:.explore.hidden.treasure_plain`
금화가 수북하다. 아무 문양도 없다.

#### hidden.treasure_cursed · `data/strings/ko.json:.explore.hidden.treasure_cursed`
금화가 손안에서 잿가루로 부서졌다. 차가운 기운이 등줄기를 타고 오른다.

#### hidden.tomb_gold · `data/strings/ko.json:.explore.hidden.tomb_gold`
금화 더미 속에서 [{item}]을 끌어냈다.

#### hidden.fortress_key · `data/strings/ko.json:.explore.hidden.fortress_key`
고문대 손잡이에 녹슨 열쇠꾸러미가 걸려 있다 — [{item}].

#### hidden.wagon_locked · `data/strings/ko.json:.explore.hidden.wagon_locked`
수레 짐칸에 자물쇠가 채워져 있다.

#### hidden.silver_chest · `data/strings/ko.json:.explore.hidden.silver_chest`
열쇠가 맞았다. 짐칸 깊숙한 곳에 [{item}]가 실려 있다.

#### hidden.falls_locked · `data/strings/ko.json:.explore.hidden.falls_locked`
물보라가 거세다. 젖은 몸으로는 폭포 뒤로 들어갈 엄두가 나지 않는다.

#### hidden.snow_lotus · `data/strings/ko.json:.explore.hidden.snow_lotus`
폭포 뒤 바위틈에 얼음꽃 한 송이가 피어 있다 — [{item}].

#### hidden.ice_core_locked · `data/strings/ko.json:.explore.hidden.ice_core_locked`
얼음 가루가 쉴 새 없이 쏟아져 고드름 속이 보이지 않는다.

#### hidden.eternal_ice · `data/strings/ko.json:.explore.hidden.eternal_ice`
가루가 그친 공동, 고드름 속에 푸른 결정이 갇혀 있다. 조심스레 깨어 [{item}]을 꺼냈다.

#### hidden.cart_fail · `data/strings/ko.json:.explore.hidden.cart_fail`
광차를 힘껏 밀었지만 바퀴가 철로에서 빠지며 옆으로 넘어졌다.

#### hidden.mine_heart · `data/strings/ko.json:.explore.hidden.mine_heart`
광차가 무너진 벽을 들이받자 숨은 갱도가 열렸다. 안쪽에서 [{item}]이 빛난다.

#### hidden.vein_reveal · `data/strings/ko.json:.explore.hidden.vein_reveal`
다리를 건너뛰는 순간, 아래 벼랑에 녹색 광맥이 드러난 것이 보였다.

#### hidden.green_vein · `data/strings/ko.json:.explore.hidden.green_vein`
벼랑에 붙은 광맥에서 [{item}]를 떼어 냈다.

### 아이템 · 스킬 효과

#### smite_heal · `data/strings/ko.json:.effect.smite_heal`
여신의 눈물이 {name}의 상처를 감싼다.

#### status_resisted · `data/strings/ko.json:.effect.status_resisted`
{name}은(는) [{status}]을(를) 버텨 냈다.

#### status_broken · `data/strings/ko.json:.effect.status_broken`
{name}의 [{status}]이(가) 풀렸다.

#### restore · `data/strings/ko.json:.effect.restore`
{resource}이(가) {amount}만큼 변했다.

#### restore_none · `data/strings/ko.json:.effect.restore_none`
{resource}은(는) 이미 가득하다.

#### light_on · `data/strings/ko.json:.effect.light_on`
횃불에 불을 붙였다. {hours}시간쯤 탈 것이다.

#### status_on · `data/strings/ko.json:.effect.status_on`
[{status}] 상태가 되었다.

#### status_on_named · `data/strings/ko.json:.effect.status_on_named`
{name}은(는) [{status}] 상태가 되었다.

#### status_off · `data/strings/ko.json:.effect.status_off`
[{status}] 상태가 풀렸다.

#### status_immune · `data/strings/ko.json:.effect.status_immune`
{name}에게는 [{status}]이(가) 듣지 않는다.

#### barrier_on · `data/strings/ko.json:.effect.barrier_on`
{name} 앞에 보호막이 선다({amount}).

#### boon_limit · `data/strings/ko.json:.effect.boon_limit`
{name}은(는) 이미 이 효과를 {max}번 받았다. 더는 듣지 않는다.

#### fatigue_down · `data/strings/ko.json:.effect.fatigue_down`
피로가 {amount}만큼 풀렸다.

#### fatigue_up · `data/strings/ko.json:.effect.fatigue_up`
피로가 {amount}만큼 쌓였다.

#### fatigue_none · `data/strings/ko.json:.effect.fatigue_none`
지친 데가 없다.

#### battle_only · `data/strings/ko.json:.effect.battle_only`
싸울 때 쓰는 물건이다.

### 전투

#### start · `data/strings/ko.json:.combat.start`
{enemies}와(과) 맞닥뜨렸다.

#### start_ambushed · `data/strings/ko.json:.combat.start_ambushed`
{enemies}이(가) 덮쳐 왔다!

#### menu_target · `data/strings/ko.json:.combat.menu_target`
누구를?

#### no_usable_item · `data/strings/ko.json:.combat.no_usable_item`
전투 중에 쓸 수 있는 소지품이 없다.

#### miss · `data/strings/ko.json:.combat.miss`
{source}의 공격이 빗나갔다.

#### immune · `data/strings/ko.json:.combat.immune`
{source}의 공격이 {target}에게 통하지 않는다.

#### hit · `data/strings/ko.json:.combat.hit`
{source} → {target}, {amount}의 피해.

#### crit · `data/strings/ko.json:.combat.crit`
{source}의 일격이 {target}의 급소를 스쳤다! {amount}의 피해.

#### weak_hit · `data/strings/ko.json:.combat.weak_hit`
{source}가 {target}의 약점을 꿰뚫었다! {amount}의 피해.

#### effective · `data/strings/ko.json:.combat.effective`
잘 먹힌다.

#### lethal · `data/strings/ko.json:.combat.lethal`
{target}이(가) 치명상을 입고 무너진다.

#### use_item · `data/strings/ko.json:.combat.use_item`
{name}이(가) {item}을(를) 썼다.

#### no_item · `data/strings/ko.json:.combat.no_item`
쓸 아이템이 없다.

#### guard · `data/strings/ko.json:.combat.guard`
{name}이(가) 몸을 웅크려 방어한다.

#### skip · `data/strings/ko.json:.combat.skip`
{name}은(는) 움직이지 못한다.

#### flee_ok · `data/strings/ko.json:.combat.flee_ok`
{name}이(가) 도망쳤다.

#### flee_fail · `data/strings/ko.json:.combat.flee_fail`
{name}은(는) 도망치지 못했다.

#### down_monster · `data/strings/ko.json:.combat.down_monster`
{name}이(가) 빛 먼지로 흩어졌다.

#### down_party · `data/strings/ko.json:.combat.down_party`
{name}이(가) 쓰러졌다.

#### end_victory · `data/strings/ko.json:.combat.end_victory`
적이 모두 사라졌다.

#### end_defeat · `data/strings/ko.json:.combat.end_defeat`
숨이 끊어진다.

#### end_fled · `data/strings/ko.json:.combat.end_fled`
가까스로 빠져나왔다.

#### reason_sealed · `data/strings/ko.json:.combat.reason_sealed`
지금은 이능을 쓸 수 없는 상태다.

#### reason_cooldown · `data/strings/ko.json:.combat.reason_cooldown`
아직 다시 쓸 수 없다.

#### no_effect · `data/strings/ko.json:.combat.no_effect`
{name}의 [{skill}]은(는) 아무 효과도 내지 못했다.

#### reason_cost · `data/strings/ko.json:.combat.reason_cost`
대가를 치를 수 없다.

#### reason_unknown · `data/strings/ko.json:.combat.reason_unknown`
그 기술은 모른다.

#### reason_no_target · `data/strings/ko.json:.combat.reason_no_target`
대상이 더는 그 자리에 없다.

#### talk_no_reply · `data/strings/ko.json:.combat.talk_no_reply`
{source}이(가) 말을 건넸지만 {target}은(는) 알아듣는 기색이 없다.

#### talk_no_reply_beast · `data/strings/ko.json:.combat.talk_no_reply_beast`
{source}의 목소리에 {target}이(가) 이빨을 드러내며 낮게 으르렁거린다.

#### talk_no_reply_undead · `data/strings/ko.json:.combat.talk_no_reply_undead`
{target}의 텅 빈 눈은 {source}을(를) 먹잇감으로만 본다.

#### talk_no_reply_construct · `data/strings/ko.json:.combat.talk_no_reply_construct`
{target}은(는) 돌처럼 아무 대답이 없다.

#### talk_no_reply_humanoid · `data/strings/ko.json:.combat.talk_no_reply_humanoid`
{target}이(가) 알 수 없는 소리로 끽끽대며 단검을 고쳐 쥔다.

#### talk_waver · `data/strings/ko.json:.combat.talk_waver`
{source}의 말에 {target}이(가) 머뭇거린다.

#### talk_ignore · `data/strings/ko.json:.combat.talk_ignore`
{target}은(는) {source}의 말을 흘려듣는다.

#### talk_provoke · `data/strings/ko.json:.combat.talk_provoke`
{source}의 말이 {target}을(를) 자극했다. 서둘러 덤벼든다!

#### talk_withdraw · `data/strings/ko.json:.combat.talk_withdraw`
{target}이(가) {source}의 말에 무기를 내리고 뒷걸음질 친다.

#### withdraw · `data/strings/ko.json:.combat.withdraw`
{name}이(가) 싸움에서 물러났다.

#### info_ally · `data/strings/ko.json:.combat.info_ally`
[조사] {name} — 생명력 {hp}%.

#### drop_ask · `data/strings/ko.json:.combat.drop_ask`
{what} — 획득할까?

#### drop_cannot · `data/strings/ko.json:.combat.drop_cannot`
받을 수 없다.

#### drop_who · `data/strings/ko.json:.combat.drop_who`
누가 받을까?

#### result_defeat · `data/strings/ko.json:.combat.result_defeat`
당신은 패배했다...

#### reflect · `data/strings/ko.json:.combat.reflect`
{source}의 칼날털이 {target}에게 {amount}만큼 되돌려 베었다.

#### counter · `data/strings/ko.json:.combat.counter`
{source}이(가) 막아 내고 {target}을(를) 찔렀다 — {amount}.

#### cover · `data/strings/ko.json:.combat.cover`
{protector}이(가) {name} 앞을 막아선다.

#### covered_hit · `data/strings/ko.json:.combat.covered_hit`
{protector}이(가) {name} 대신 공격을 받아 낸다.

#### drain · `data/strings/ko.json:.combat.drain`
{source}이(가) 피를 핥아 {amount} 회복했다.

#### summon · `data/strings/ko.json:.combat.summon`
{name}의 울부짖음에 {monster}이(가) 달려왔다!

#### summon_ally · `data/strings/ko.json:.combat.summon_ally`
{name}이(가) {monster}을(를) 불러냈다.

#### down_summon · `data/strings/ko.json:.combat.down_summon`
{name}이(가) 흩어졌다.

#### dot · `data/strings/ko.json:.combat.dot`
{name}이(가) [{list}]으로 생명력 {amount}을(를) 잃었다.

#### dot_plain · `data/strings/ko.json:.combat.dot_plain`
{name}이(가) 생명력 {amount}을(를) 잃었다.

#### summon_fail · `data/strings/ko.json:.combat.summon_fail`
{name}이(가) 울부짖었지만 아무도 오지 않았다.

#### reason_hidden · `data/strings/ko.json:.combat.reason_hidden`
그 상대는 모습을 감추고 있다.

#### reason_no_flee · `data/strings/ko.json:.combat.reason_no_flee`
도망칠 길이 없다.

#### reason_leader_only · `data/strings/ko.json:.combat.reason_leader_only`
일행을 이끄는 사람만 할 수 있다.

#### reason_veiled · `data/strings/ko.json:.combat.reason_veiled`
장막 너머의 동료를 알아볼 수 없다.

#### sealed · `data/strings/ko.json:.combat.sealed`
{name}의 [{skill}]이(가) 봉인되었다.

#### pushed_back · `data/strings/ko.json:.combat.pushed_back`
{name}이(가) 밀려나 다음 차례가 늦어진다.

#### telegraph_guarded · `data/strings/ko.json:.combat.telegraph_guarded`
{name}이(가) 예고된 일격을 막아 냈다!

#### marked · `data/strings/ko.json:.combat.marked`
{source}의 원한이 {name}에게 새겨졌다 — [{status}]!

#### extra_hit · `data/strings/ko.json:.combat.extra_hit`
{name}이(가) 한 번 더 문다!

#### monster_type · `data/strings/ko.json:.combat.monster_type`
{name} — 기운이 느껴진다.

#### bone_knight_hatred · `data/strings/ko.json:.combat.bone_knight_hatred`
경고: {name}은(는) 영혼을 베는 기사다. 레벨이 내려갈 수 있다!

#### soul_slash_miss · `data/strings/ko.json:.combat.soul_slash_miss`
{name}의 영혼이 서늘해졌지만 버텨 냈다.

#### soul_slash_level · `data/strings/ko.json:.combat.soul_slash_level`
{name}의 영혼이 베였다 — 레벨 {level}(으)로 떨어졌다!

#### soul_slash_essence · `data/strings/ko.json:.combat.soul_slash_essence`
{name}의 영혼에서 [{essence}]이(가) 떨어져 나가 사라졌다!

#### soul_slash_soul · `data/strings/ko.json:.combat.soul_slash_soul`
{name}의 영혼력이 {amount} 흩어졌다.

#### golem_skeleton · `data/strings/ko.json:.combat.golem_skeleton`
{name}의 살점이 무너져 내리고 뼈대가 드러난다 — 마력핵이 보인다!

#### golem_mumble_1 · `data/strings/ko.json:.combat.golem_mumble_1`
{name}: "…춥다… 춥다… 누가 문을…"

#### golem_mumble_2 · `data/strings/ko.json:.combat.golem_mumble_2`
{name}: "내 손… 내 손은 어디… 여기, 여기 있다…"

#### golem_mumble_3 · `data/strings/ko.json:.combat.golem_mumble_3`
{name}: "배고파, 배고파, 같이 있자, 같이…"

#### golem_mumble_4 · `data/strings/ko.json:.combat.golem_mumble_4`
{name}의 입 수십 개가 동시에 웃는다.

#### guardian_frenzy · `data/strings/ko.json:.combat.guardian_frenzy`
{name}이(가) 궁지에 몰려 광분한다 — 연달아 움직인다!

#### blater_intro · `data/strings/ko.json:.combat.blater_intro`
{name}이(가) 녹슨 대검을 바닥에 끌며 일어선다. 원한이 공기를 무겁게 누른다.

#### kambormir_intro · `data/strings/ko.json:.combat.kambormir_intro`
{name}: "손님이 오셨군. 피가 따뜻할 때 인사해 두지."

#### survived · `data/strings/ko.json:.combat.survived`
{rounds}라운드를 버텨 냈다!

#### reinforce · `data/strings/ko.json:.combat.reinforce`
{monster}이(가) 기어오른다!

#### meter_full · `data/strings/ko.json:.combat.meter_full`
{name}의 {meter}이(가) 가득 찼다 — {status}!

#### meter_damage_none · `data/strings/ko.json:.combat.meter_damage_none`
{target}의 마음에는 비출 공포가 없다.

#### delayed_warn · `data/strings/ko.json:.combat.delayed_warn`
{name}의 주위로 죽은 자들의 기억이 모여든다…

#### delayed_fire · `data/strings/ko.json:.combat.delayed_fire`
{name}이(가) 불러 모은 기억이 쏟아진다!

#### delayed_dropped · `data/strings/ko.json:.combat.delayed_dropped`
{name}이(가) 준비하던 공격이 흩어졌다.

#### tarun_collapse_warn · `data/strings/ko.json:.combat.tarun_collapse_warn`
{name}이(가) 얼음몽둥이를 높이 쳐든다 — 천장과 바닥에 금이 쩍쩍 간다!

#### tarun_collapse_fire · `data/strings/ko.json:.combat.tarun_collapse_fire`
{name}의 몽둥이가 지면을 내리찍는다 — 발밑이 무너진다!

#### blater_sentence_warn · `data/strings/ko.json:.combat.blater_sentence_warn`
{name}이(가) 대검으로 한 사람을 가리킨다 — 사형 선고.

#### blater_sentence_fire · `data/strings/ko.json:.combat.blater_sentence_fire`
{name}의 선고가 집행된다!

#### misdirect · `data/strings/ko.json:.combat.misdirect`
{name}의 공격이 빗나가 {target}에게 향한다!

#### rows_shuffled · `data/strings/ko.json:.combat.rows_shuffled`
대열이 뒤엉켰다!

#### extra_action · `data/strings/ko.json:.combat.extra_action`
{name}이(가) 한 번 더 움직인다!

#### enrage · `data/strings/ko.json:.combat.enrage`
{name}의 숨이 거칠어진다. 휘두르는 손길에 망설임이 사라졌다.

#### dread_p1 · `data/strings/ko.json:.combat.dread_p1`
수정의 빛이 핏빛으로 물든다. {name}이(가) 구더기를 흩뿌리며 다가온다.

#### dread_p2 · `data/strings/ko.json:.combat.dread_p2`
{name}의 공포가 스며든다. 손끝이 떨리고, 원망이 쌓이기 시작한다.

#### dread_p3 · `data/strings/ko.json:.combat.dread_p3`
{name}을(를) 둘러싼 증오가 짙어진다. 동료의 얼굴이 낯설게 보인다.

#### dread_p4 · `data/strings/ko.json:.combat.dread_p4`
구더기가 흩어지고 {name}의 사람 형체가 드러난다!

#### dread_proliferate · `data/strings/ko.json:.combat.dread_proliferate`
{name}의 공포가 불어난다({stacks}중첩).

#### dread_veil · `data/strings/ko.json:.combat.dread_veil`
배신의 장막이 내려앉는다 — 누가 동료인지 알 수 없다.

#### dread_groggy · `data/strings/ko.json:.combat.dread_groggy`
{name}이(가) 껍질 속으로 숨어 웅크린다. 지금이 기회다!

#### dread_buff · `data/strings/ko.json:.combat.dread_buff`
{name}이(가) 껍질을 벗고 새 모습을 얻었다: {buff}.

#### dread_flag_old_memory · `data/strings/ko.json:.combat.dread_flag_old_memory`
{name}에게서 아주 오래된 기억이 스친다.

#### dread_flag_twisted_memory · `data/strings/ko.json:.combat.dread_flag_twisted_memory`
마비독의 냄새에 {name}의 기억이 뒤틀린다.

#### barrier_absorb · `data/strings/ko.json:.combat.barrier_absorb`
{name}의 보호막이 피해 {amount}을(를) 받아 냈다.

#### rider_hit · `data/strings/ko.json:.combat.rider_hit`
{target}에게 {type} 피해 {amount}.

#### aura_tick · `data/strings/ko.json:.combat.aura_tick`
{name}의 기운이 퍼진다 — [{status}].

#### katumba_intro · `data/strings/ko.json:.combat.katumba_intro`
토템이 부서지며 거대한 흰 그림자가 내려선다. {name}이(가) 눈보라를 몰고 온다.

#### tarunbas_intro · `data/strings/ko.json:.combat.tarunbas_intro`
얼음 가루가 쏟아지는 천장에서 {name}이(가) 뛰어내린다. 얼음몽둥이가 바닥을 울린다.

#### tarunbas_roar · `data/strings/ko.json:.combat.tarunbas_roar`
{name}이(가) 울부짖는다 — 몸이 부풀어 오르고 연달아 움직인다!

#### kirdui_intro · `data/strings/ko.json:.combat.kirdui_intro`
검은 거체가 몸을 일으킨다. {name}의 송곳니 사이로 김이 새어 나온다.

#### split · `data/strings/ko.json:.combat.split`
{name}이(가) 둘로 갈라진다 — {monster}!

#### absorb · `data/strings/ko.json:.combat.absorb`
{name}이(가) {target}을(를) 집어삼켰다. 생명력 {amount} 회복.

#### absorb_none · `data/strings/ko.json:.combat.absorb_none`
{name}이(가) 삼킬 것을 찾지 못했다.

#### summon_expired · `data/strings/ko.json:.combat.summon_expired`
{name}이(가) 사라졌다.

#### death_blast · `data/strings/ko.json:.combat.death_blast`
{name}이(가) 쓰러지며 폭발한다!

#### self_blast · `data/strings/ko.json:.combat.self_blast`
{name}이(가) 제 몸의 폭발에 휘말렸다({amount}).

#### bomber_cookoff · `data/strings/ko.json:.combat.bomber_cookoff`
불길이 폭약 주머니에 옮겨붙었다 — {name}의 허리춤이 터진다({amount})!

#### bomber_fuse_warn · `data/strings/ko.json:.combat.bomber_fuse_warn`
{name}이(가) 심지에 불을 붙인 폭탄을 굴린다!

#### bomber_fuse_fire · `data/strings/ko.json:.combat.bomber_fuse_fire`
{name}의 지연 폭탄이 터진다!

#### king_jump_warn · `data/strings/ko.json:.combat.king_jump_warn`
{name}이(가) 몸을 잔뜩 웅크린다 — 천장까지 뛰어오를 기세다!

#### king_jump_fire · `data/strings/ko.json:.combat.king_jump_fire`
{name}이(가) 떨어져 내리며 모두를 짓누른다!

#### bomber_intro · `data/strings/ko.json:.combat.bomber_intro`
{name}이(가) 폭약 주머니를 흔들며 낄낄댄다.

#### king_slime_intro · `data/strings/ko.json:.combat.king_slime_intro`
공동 한가운데에서 {name}이(가) 출렁인다.

#### king_slime_split · `data/strings/ko.json:.combat.king_slime_split`
{name}의 몸이 찢어지며 슬라임들이 떨어져 나온다!

#### revive · `data/strings/ko.json:.combat.revive`
{name}이(가) 다시 일어난다!

#### buried_rise · `data/strings/ko.json:.combat.buried_rise`
관 뚜껑이 열리듯 {name}이(가) 흙을 털며 다시 일어난다!

#### endure · `data/strings/ko.json:.combat.endure`
{name}이(가) 쓰러질 일격을 버텨 냈다!

#### ildium_intro · `data/strings/ko.json:.combat.ildium_intro`
분묘 한가운데에서 {name}이(가) 삐걱거리며 몸을 일으킨다.

#### ildium_overheat · `data/strings/ko.json:.combat.ildium_overheat`
{name}의 강철 몸이 벌겋게 달아오른다 — 힘이 세지고 몸이 물러진다!

#### ildium_trap_warn · `data/strings/ko.json:.combat.ildium_trap_warn`
{name}이(가) 바닥을 내리친다!

#### ildium_trap_fire · `data/strings/ko.json:.combat.ildium_trap_fire`
분묘의 함정이 일제히 튀어 오른다!

#### start_first · `data/strings/ko.json:.combat.start_first`
{enemies}을(를) 먼저 발견했다. 싸운다.

#### split_blocked · `data/strings/ko.json:.combat.split_blocked`
{name}이(가) 그을린 몸을 비틀지만 갈라지지 못한다.

### 보상 · 정수

#### first_kill · `data/strings/ko.json:.reward.first_kill`
처음 쓰러뜨린 {name} — 공적 {exp}.

#### loot · `data/strings/ko.json:.reward.loot`
{item} ×{count}을(를) 주웠다.

#### loot_by · `data/strings/ko.json:.reward.loot_by`
{who}이(가) {item} ×{count}을(를) 주웠다.

#### loot_left · `data/strings/ko.json:.reward.loot_left`
{what}을(를) 두고 간다.

#### essence_absorbed · `data/strings/ko.json:.reward.essence_absorbed`
{who}의 몸속으로 {what}이(가) 스며들었다.

#### essence_left · `data/strings/ko.json:.reward.essence_left`
{what}이(가) 빛 먼지가 되어 흩어졌다.

#### bag_full · `data/strings/ko.json:.reward.bag_full`
가방에 자리가 없어 {item} ×{count}을(를) 두고 간다.

#### level_up · `data/strings/ko.json:.reward.level_up`
영혼이 한 겹 더 단단해졌다. 레벨 {level} (정수 슬롯 {slots}).

#### guardian_bonus · `data/strings/ko.json:.reward.guardian_bonus`
수호자 {name}을(를) 쓰러뜨렸다 — 공적 {exp}.

#### lord_bonus · `data/strings/ko.json:.reward.lord_bonus`
계층군주 {name}을(를) 처음으로 쓰러뜨렸다 — 공적 {exp}.

#### level_down · `data/strings/ko.json:.reward.level_down`
영혼이 깎여 나갔다. 레벨 {level} — 정수 {locked}개가 잠들었다.

### 소지품

#### discarded · `data/strings/ko.json:.inventory.discarded`
{item} ×{count}을(를) 버렸다.

#### no_room_swap · `data/strings/ko.json:.inventory.no_room_swap`
가방에 자리가 없어 {item}을(를) 바꿔 낄 수 없다.

#### no_room_unequip · `data/strings/ko.json:.inventory.no_room_unequip`
가방에 자리가 없어 {item}을(를) 벗을 수 없다.

### 아군

#### release_ask · `data/strings/ko.json:.party.release_ask`
{name}을(를) 파티에서 내보낼까?

#### mate_died · `data/strings/ko.json:.party.mate_died`
{name}이(가) 숨을 거두었다.

### 도감

#### lore_empty · `data/strings/ko.json:.codex.lore_empty`
아직 읽은 대목이 없다.

### 도감(몬스터)

#### empty · `data/strings/ko.json:.bestiary.empty`
아직 마주친 몬스터가 없다.

#### stats_unknown · `data/strings/ko.json:.bestiary.stats_unknown`
생명력·스탯: ???

#### variant_of · `data/strings/ko.json:.bestiary.variant_of`
{name}의 변이종.

### 정수 칸

#### reason_unknown · `data/strings/ko.json:.essence.reason_unknown`
알 수 없는 정수다.

#### reason_no_slot · `data/strings/ko.json:.essence.reason_no_slot`
빈 정수 슬롯이 없다.

#### reason_duplicate · `data/strings/ko.json:.essence.reason_duplicate`
이미 같은 이능이 영혼에 새겨져 있어 받아들일 수 없다.

### 수수께끼

#### correct · `data/strings/ko.json:.riddle.correct`
"맞았다." 문지기가 묻는다 — 그냥 지나가겠는가, 봉인이 풀린 나와 겨루겠는가?

### 차원광장 · 정산

#### settle_tag · `data/strings/ko.json:.plaza.settle_tag`
길드 직원이 신원패를 받아 든다. "{name} 님, {grade}등급 탐험가. 무사히 돌아오셨군요."

#### settle_count · `data/strings/ko.json:.plaza.settle_count`
"{list}. 확인했습니다."

#### settle_total · `data/strings/ko.json:.plaza.settle_total`
"정산하면 {n} 스톤입니다." 직원이 스톤 꾸러미를 내민다.

#### settle_none · `data/strings/ko.json:.plaza.settle_none`
"가져오신 마석은 없군요. 다음엔 빈손으로 오지 마세요."

### 도시

#### spent_stones · `data/strings/ko.json:.city.spent_stones`
{n} 스톤을 치렀다.

#### reason_unknown · `data/strings/ko.json:.city.reason_unknown`
알 수 없는 시설·활동이다.

#### reason_inside · `data/strings/ko.json:.city.reason_inside`
이미 시설 안에 있다.

#### reason_no_ap · `data/strings/ko.json:.city.reason_no_ap`
행동력이 모자란다.

#### reason_no_money · `data/strings/ko.json:.city.reason_no_money`
돈이 모자란다.

#### reason_not_here · `data/strings/ko.json:.city.reason_not_here`
이 시설에서 할 수 없는 활동이다.

#### reason_panel · `data/strings/ko.json:.city.reason_panel`
이 활동은 창구에서 한다.

#### reason_not_sold · `data/strings/ko.json:.city.reason_not_sold`
팔지 않는 물건이다.

#### reason_bag_full · `data/strings/ko.json:.city.reason_bag_full`
가방에 자리가 없다.

#### reason_cannot_sell · `data/strings/ko.json:.city.reason_cannot_sell`
팔 수 없는 물건이다.

#### reason_bad_amount · `data/strings/ko.json:.city.reason_bad_amount`
금액을 1 스톤 이상 넣어야 한다.

#### reason_no_balance · `data/strings/ko.json:.city.reason_no_balance`
맡긴 돈이 그만큼 없다.

#### reason_no_essence · `data/strings/ko.json:.city.reason_no_essence`
그 정수는 없다.

#### shop_bought · `data/strings/ko.json:.city.shop_bought`
{item} {n}개를 {price} 스톤에 샀다.

#### shop_sold · `data/strings/ko.json:.city.shop_sold`
{item} {n}개를 {price} 스톤에 넘겼다.

#### bank_deposited · `data/strings/ko.json:.city.bank_deposited`
{amount} 스톤을 맡겼다.

#### bank_withdrew · `data/strings/ko.json:.city.bank_withdrew`
{amount} 스톤을 찾았다.

#### essence_none · `data/strings/ko.json:.city.essence_none`
흡수한 정수가 없다.

#### essence_removed · `data/strings/ko.json:.city.essence_removed`
{name} 정수가 몸에서 빠져나갔다. {cost} 스톤을 치렀다.

#### debug_applied · `data/strings/ko.json:.city.debug_applied`
임시값 {n}개 적용.

#### debug_cleared · `data/strings/ko.json:.city.debug_cleared`
임시값을 모두 지웠다.

#### expedition_auto · `data/strings/ko.json:.city.expedition_auto`
{date}이 저물었다. 미궁으로 향한다.

#### bank_withdrew_fee · `data/strings/ko.json:.city.bank_withdrew_fee`
{amount} 스톤을 찾았다. 수수료로 {fee} 스톤이 빠졌다.

#### cannot_use_here · `data/strings/ko.json:.city.cannot_use_here`
여기서는 쓸 수 없다.

#### tax_execution.1 · `data/strings/ko.json:.city.tax_execution.1`
포탈 광장으로 가는 길목에서 경비대가 앞을 막는다. 대장이 장부를 펼친다.

#### tax_execution.2 · `data/strings/ko.json:.city.tax_execution.2`
"올해 세금 납부 기록이 없군." 대답을 기다리는 사람은 아무도 없다.

#### tax_execution.3 · `data/strings/ko.json:.city.tax_execution.3`
광장 끝 교수대에 밧줄이 하나 더 걸린다.

#### reason_no_item · `data/strings/ko.json:.city.reason_no_item`
필요한 물건이 없다.

### 도시 · fx

#### fx.fatigue_same · `data/strings/ko.json:.city.fx.fatigue_same`
몸 상태는 그대로다.

#### fx.stat_up · `data/strings/ko.json:.city.fx.stat_up`
{stat}이 늘었다.

#### fx.stat_fail · `data/strings/ko.json:.city.fx.stat_fail`
별다른 소득은 없었다.

#### fx.book_none · `data/strings/ko.json:.city.fx.book_none`
서가를 다 뒤졌지만 처음 보는 대목은 없었다.

#### fx.merit · `data/strings/ko.json:.city.fx.merit`
신전 일을 거들었다. 신관이 고개를 끄덕인다.

#### fx.fatigue_up · `data/strings/ko.json:.city.fx.fatigue_up`
몸이 무겁다.

#### fx.fatigue_down · `data/strings/ko.json:.city.fx.fatigue_down`
몸이 한결 가볍다.

#### fx.restore · `data/strings/ko.json:.city.fx.restore`
상처가 아물고 머리가 맑아졌다.

#### fx.restore_full · `data/strings/ko.json:.city.fx.restore_full`
다친 데도 없이 개운하게 일어났다.

#### fx.item_got · `data/strings/ko.json:.city.fx.item_got`
{name}을(를) 챙겼다.

#### fx.item_no_room · `data/strings/ko.json:.city.fx.item_no_room`
{name}을(를) 넣을 자리가 없다.

#### fx.tax_paid · `data/strings/ko.json:.city.fx.tax_paid`
세금 {n} 스톤을 냈다. 납부 증서에 붉은 인장이 찍힌다.

#### fx.money_lost · `data/strings/ko.json:.city.fx.money_lost`
{n} 스톤을 잃었다.

#### fx.money_got · `data/strings/ko.json:.city.fx.money_got`
{n} 스톤을 받았다.

#### fx.closed · `data/strings/ko.json:.city.fx.closed`
{name}이(가) 문을 닫았다.

#### fx.no_tags · `data/strings/ko.json:.city.fx.no_tags`
신원패가 없다.

#### fx.tags_returned · `data/strings/ko.json:.city.fx.tags_returned`
신원패 {n}장을 넘기고 {stones} 스톤을 받았다.

#### fx.no_records · `data/strings/ko.json:.city.fx.no_records`
넘길 기록이 없다.

#### fx.records_sold · `data/strings/ko.json:.city.fx.records_sold`
기록 {n}건을 넘기고 {stones} 스톤을 받았다.

#### fx.no_survey · `data/strings/ko.json:.city.fx.no_survey`
의뢰받은 조사가 없다.

#### fx.survey_paid · `data/strings/ko.json:.city.fx.survey_paid`
{name} 조사 {n}건을 넘기고 {stones} 스톤을 받았다.

#### fx.meal_none · `data/strings/ko.json:.city.fx.meal_none`
오늘은 내올 요리가 없다고 한다.

#### fx.item_boon · `data/strings/ko.json:.city.fx.item_boon`
{stat}이(가) 단단해졌다.

#### fx.item_boon_none · `data/strings/ko.json:.city.fx.item_boon_none`
해독할 책이 없다.

#### fx.item_boon_known · `data/strings/ko.json:.city.fx.item_boon_known`
이미 읽어 낸 책이다.

### 도시 · lines

#### lines.inn_rest.spent_stones.1 · `data/strings/ko.json:.city.lines.inn_rest.spent_stones.1`
숙박비로 {n} 스톤을 냈다.

#### lines.inn_rest.fatigue_down.1 · `data/strings/ko.json:.city.lines.inn_rest.fatigue_down.1`
삐걱거리는 침대였지만 오랜만에 깊이 잠들었다.

#### lines.inn_rest.fatigue_down.2 · `data/strings/ko.json:.city.lines.inn_rest.fatigue_down.2`
푹 자고 일어나니 몸이 한결 가볍다.

#### lines.inn_rest.fatigue_down.3 · `data/strings/ko.json:.city.lines.inn_rest.fatigue_down.3`
옆방 코골이에도 아랑곳없이 곯아떨어졌다.

#### lines.inn_rest.fatigue_same.1 · `data/strings/ko.json:.city.lines.inn_rest.fatigue_same.1`
피곤하지도 않은데 괜히 침대에서 뒹굴었다.

#### lines.inn_rest.restore.1 · `data/strings/ko.json:.city.lines.inn_rest.restore.1`
눅눅한 이불이었지만 상처가 꾸덕하게 아물었다.

#### lines.inn_rest.restore.2 · `data/strings/ko.json:.city.lines.inn_rest.restore.2`
깊이 자고 나니 쑤시던 곳이 잠잠하다.

#### lines.inn_rest.restore_full.1 · `data/strings/ko.json:.city.lines.inn_rest.restore_full.1`
멀쩡한 몸으로 하룻밤을 늘어지게 잤다.

#### lines.inn_snack.spent_stones.1 · `data/strings/ko.json:.city.lines.inn_snack.spent_stones.1`
{n} 스톤을 내고 구석 자리에 앉았다.

#### lines.inn_snack.fatigue_down.1 · `data/strings/ko.json:.city.lines.inn_snack.fatigue_down.1`
허기를 달래고 나니 다리에 힘이 조금 돌아왔다.

#### lines.inn_snack.fatigue_down.2 · `data/strings/ko.json:.city.lines.inn_snack.fatigue_down.2`
멀건 죽이라도 속이 데워지니 살 만하다.

#### lines.inn_snack.fatigue_same.1 · `data/strings/ko.json:.city.lines.inn_snack.fatigue_same.1`
그릇을 비웠지만 피곤은 그대로다.

#### lines.inn_hearty.spent_stones.1 · `data/strings/ko.json:.city.lines.inn_hearty.spent_stones.1`
넉넉히 {n} 스톤을 치렀다.

#### lines.inn_hearty.fatigue_down.1 · `data/strings/ko.json:.city.lines.inn_hearty.fatigue_down.1`
배가 터지도록 먹고 나니 몸이 다시 내 것 같다.

#### lines.inn_hearty.fatigue_down.2 · `data/strings/ko.json:.city.lines.inn_hearty.fatigue_down.2`
기름진 한 상을 비우자 눈이 맑아졌다.

#### lines.inn_hearty.fatigue_same.1 · `data/strings/ko.json:.city.lines.inn_hearty.fatigue_same.1`
든든하게 먹었다.

#### lines.inn_meal.spent_stones.1 · `data/strings/ko.json:.city.lines.inn_meal.spent_stones.1`
밥값으로 {n} 스톤을 냈다.

#### lines.inn_meal.fatigue_down.1 · `data/strings/ko.json:.city.lines.inn_meal.fatigue_down.1`
배가 든든해지니 굳은 어깨가 풀렸다.

#### lines.inn_meal.fatigue_down.2 · `data/strings/ko.json:.city.lines.inn_meal.fatigue_down.2`
뜨끈한 것이 들어가니 그제야 살 것 같다.

#### lines.inn_meal.fatigue_down.3 · `data/strings/ko.json:.city.lines.inn_meal.fatigue_down.3`
시끄러운 홀 구석에서 배불리 먹었다.

#### lines.inn_meal.fatigue_same.1 · `data/strings/ko.json:.city.lines.inn_meal.fatigue_same.1`
느긋하게 그릇을 비웠다.

#### lines.library_read.stat_up.1 · `data/strings/ko.json:.city.lines.library_read.stat_up.1`
읽은 내용이 머릿속에 차곡차곡 쌓인다. {stat}이 늘었다.

#### lines.library_read.stat_fail.1 · `data/strings/ko.json:.city.lines.library_read.stat_fail.1`
글자가 좀처럼 눈에 들어오지 않았다.

#### lines.library_read.stat_fail.2 · `data/strings/ko.json:.city.lines.library_read.stat_fail.2`
같은 줄만 몇 번이고 다시 읽었다.

#### lines.library_read.fatigue_up.1 · `data/strings/ko.json:.city.lines.library_read.fatigue_up.1`
눈이 뻑뻑하다.

#### lines.library_read.fatigue_up.2 · `data/strings/ko.json:.city.lines.library_read.fatigue_up.2`
어깨가 뻐근하다.

#### lines.training_train.spent_stones.1 · `data/strings/ko.json:.city.lines.training_train.spent_stones.1`
교관에게 {n} 스톤을 건넸다.

#### lines.training_train.stat_up.1 · `data/strings/ko.json:.city.lines.training_train.stat_up.1`
땀 흘린 보람이 있다. {stat}이 늘었다.

#### lines.training_train.stat_up.2 · `data/strings/ko.json:.city.lines.training_train.stat_up.2`
몸이 달라진 게 느껴진다. {stat}이 늘었다.

#### lines.training_train.stat_fail.1 · `data/strings/ko.json:.city.lines.training_train.stat_fail.1`
고된 훈련으로 근육통만 생겼다.

#### lines.training_train.stat_fail.2 · `data/strings/ko.json:.city.lines.training_train.stat_fail.2`
교관의 호통만 실컷 들었다.

#### lines.training_train.stat_fail.3 · `data/strings/ko.json:.city.lines.training_train.stat_fail.3`
허수아비만 애꿎게 두들겼다.

#### lines.training_train.fatigue_up.1 · `data/strings/ko.json:.city.lines.training_train.fatigue_up.1`
온몸이 욱신거린다.

#### lines.training_train.fatigue_up.2 · `data/strings/ko.json:.city.lines.training_train.fatigue_up.2`
팔다리가 천근만근이다.

#### lines.temple_service.merit.1 · `data/strings/ko.json:.city.lines.temple_service.merit.1`
신전 바닥을 닦고 촛농을 긁어냈다. 신관이 고개를 끄덕인다.

#### lines.temple_service.merit.2 · `data/strings/ko.json:.city.lines.temple_service.merit.2`
구호소에서 죽을 나눠 주었다. 손등이 데었다.

#### lines.temple_service.merit.3 · `data/strings/ko.json:.city.lines.temple_service.merit.3`
제단의 향로를 닦았다. 손에 밴 향이 좀처럼 빠지지 않는다.

#### lines.training_lecture.stat_fail.1 · `data/strings/ko.json:.city.lines.training_lecture.stat_fail.1`
교관의 시범은 화려했지만 몸이 따라가지 못했다.

#### lines.training_spar.stat_fail.1 · `data/strings/ko.json:.city.lines.training_spar.stat_fail.1`
상대 모험가에게 몇 번이고 바닥에 메다꽂혔다. 배운 건 낙법뿐이다.

#### lines.library_rare.stat_fail.1 · `data/strings/ko.json:.city.lines.library_rare.stat_fail.1`
귀한 책이었지만 글자가 너무 낡아 반도 읽지 못했다.

#### lines.inn_feast.spent_stones.1 · `data/strings/ko.json:.city.lines.inn_feast.spent_stones.1`
특식 값으로 {n} 스톤을 냈다.

#### lines.inn_feast.fatigue_down.1 · `data/strings/ko.json:.city.lines.inn_feast.fatigue_down.1`
접시를 다 비우고 나니 온몸에 기운이 돈다.

#### lines.inn_feast.fatigue_down.2 · `data/strings/ko.json:.city.lines.inn_feast.fatigue_down.2`
오랜만에 사람 사는 맛을 봤다.

#### lines.inn_feast.fatigue_same.1 · `data/strings/ko.json:.city.lines.inn_feast.fatigue_same.1`
접시를 깨끗이 비웠다.

#### lines.library_decode.item_boon.1 · `data/strings/ko.json:.city.lines.library_decode.item_boon.1`
밤새 검은 책장을 넘겼다. 마지막 장을 덮자 책은 재가 되어 흩어졌고, 어둠을 견디는 법만 머리에 남았다.

#### lines.library_decode.item_boon.2 · `data/strings/ko.json:.city.lines.library_decode.item_boon.2`
사서가 등불을 몇 번이나 갈아 주었다. 해독을 마친 책은 손안에서 바스러졌다.

### 도시 · street

#### street.hanging.intro.1 · `data/strings/ko.json:.city.street.hanging.intro.1`
광장 끝 교수대 앞에 사람들이 모여 있다. 지난해 세금을 내지 못한 자들이다.

#### street.hanging.intro.2 · `data/strings/ko.json:.city.street.hanging.intro.2`
인간도, 수인도, 드워프도 같은 줄에 서 있다. 밧줄은 종족을 묻지 않는다.

#### street.hanging.intro.3 · `data/strings/ko.json:.city.street.hanging.intro.3`
발판이 빠지는 소리가 몇 번 나고, 구경꾼들은 곧 제 갈 길로 흩어진다.

#### street.tax_notice.intro.1 · `data/strings/ko.json:.city.street.tax_notice.intro.1`
광장에 관리가 올라서서 두루마리를 편다.

#### street.tax_notice.intro.2 · `data/strings/ko.json:.city.street.tax_notice.intro.2`
"올해 세금은 이번 달 하순이 끝나기 전까지 은행에 납부하라. 기한을 넘긴 자는 교수대에 오른다."

#### street.pickpocket.intro.1 · `data/strings/ko.json:.city.street.pickpocket.intro.1`
붐비는 골목에서 누군가 어깨를 세게 스치고 지나간다.

#### street.pickpocket.result_ok.1 · `data/strings/ko.json:.city.street.pickpocket.result_ok.1`
허리춤으로 뻗어 온 손목을 붙잡았다. 소년이 몸을 비틀어 빠져나가 인파 속으로 사라진다.

#### street.pickpocket.result_fail.1 · `data/strings/ko.json:.city.street.pickpocket.result_fail.1`
몇 걸음 뒤에야 허리춤이 가볍다는 것을 알았다. {n} 스톤어치 동전이 사라졌다.

#### street.checkpoint.intro.1 · `data/strings/ko.json:.city.street.checkpoint.intro.1`
경비대가 거리를 가로막고 지나가는 사람들의 얼굴을 하나하나 살핀다.

#### street.checkpoint.result.1 · `data/strings/ko.json:.city.street.checkpoint.result.1`
수배자를 찾는다며 {name} 앞 골목을 통째로 막아 버렸다.

#### street.wanted.intro.1 · `data/strings/ko.json:.city.street.wanted.intro.1`
게시판에 새 현상수배 전단이 붙었다. 미궁 안에서 동료를 베고 혼자 돌아온 탐험가라고 한다.

#### street.wanted.intro.2 · `data/strings/ko.json:.city.street.wanted.intro.2`
전단 아래 적힌 현상금 액수를 두고 사람들이 수군거린다.

#### street.stone_glut.intro.1 · `data/strings/ko.json:.city.street.stone_glut.intro.1`
큰 원정대가 한꺼번에 돌아왔다. 짐수레마다 마석 자루가 실려 있다.

#### street.stone_glut.intro.2 · `data/strings/ko.json:.city.street.stone_glut.intro.2`
상점 주인들은 마석 값을 깎을 핑계가 생겼다며 웃는다.

#### street.stone_demand.intro.1 · `data/strings/ko.json:.city.street.stone_demand.intro.1`
마도 공방 사람들이 거리마다 다니며 마석을 사들인다.

#### street.stone_demand.intro.2 · `data/strings/ko.json:.city.street.stone_demand.intro.2`
상점 앞에 마석 값을 올려 받는다는 쪽지가 붙었다.

#### street.potion_shortage.intro.1 · `data/strings/ko.json:.city.street.potion_shortage.intro.1`
신전에서 내려오는 포션 물량이 끊겼다는 소문이 돈다.

#### street.potion_shortage.intro.2 · `data/strings/ko.json:.city.street.potion_shortage.intro.2`
상점 진열대의 포션 앞에 새 가격표가 붙어 있다.

#### street.dubious_peddler.intro.1 · `data/strings/ko.json:.city.street.dubious_peddler.intro.1`
골목 그늘에서 사내가 손짓한다. 품속에서 붉은 물약 병을 꺼내 보인다.

#### street.dubious_peddler.intro.2 · `data/strings/ko.json:.city.street.dubious_peddler.intro.2`
"신전 것과 똑같은 물건이오. 값은 반의반이고."

#### street.dubious_peddler.buy_ok.1 · `data/strings/ko.json:.city.street.dubious_peddler.buy_ok.1`
병을 따 냄새를 맡아 보니 진짜 포션이다. 사내는 이미 자리를 떴다.

#### street.dubious_peddler.buy_fail.1 · `data/strings/ko.json:.city.street.dubious_peddler.buy_fail.1`
병 속에는 붉게 물들인 물뿐이었다. 사내가 있던 자리는 비어 있다.

#### street.dubious_peddler.pass.1 · `data/strings/ko.json:.city.street.dubious_peddler.pass.1`
사내는 혀를 차고 다음 사람을 부른다.

#### street.beggar.intro.1 · `data/strings/ko.json:.city.street.beggar.intro.1`
한쪽 팔이 없는 사내가 담벼락에 기대 앉아 있다. 옆에 찌그러진 투구가 엎어져 있다.

#### street.beggar.give.1 · `data/strings/ko.json:.city.street.beggar.give.1`
투구에 동전이 떨어지는 소리에 사내가 고개를 든다. "미궁에서 살아 돌아오길."

#### street.beggar.pass.1 · `data/strings/ko.json:.city.street.beggar.pass.1`
사내는 고개를 숙인 채 움직이지 않는다.

#### street.drunk.intro.1 · `data/strings/ko.json:.city.street.drunk.intro.1`
술 냄새를 풍기는 덩치가 길을 막아선다. "어이, 거기. 어깨를 쳤으면 사과를 해야지."

#### street.drunk.fight_ok.1 · `data/strings/ko.json:.city.street.drunk.fight_ok.1`
덩치가 진흙탕에 나뒹굴자 구경꾼들이 환호하며 동전을 던진다. {n} 스톤이 모였다.

#### street.drunk.fight_fail.1 · `data/strings/ko.json:.city.street.drunk.fight_fail.1`
주먹다짐 끝에 둘 다 진흙탕에 나뒹굴었다. 온몸이 쑤신다.

#### street.drunk.avoid.1 · `data/strings/ko.json:.city.street.drunk.avoid.1`
뒤에서 비웃음이 들리지만 돌아보지 않았다.

#### street.errand.intro.1 · `data/strings/ko.json:.city.street.errand.intro.1`
짐수레를 끌던 노인이 바퀴가 빠졌다며 도움을 청한다.

#### street.errand.accept.1 · `data/strings/ko.json:.city.street.errand.accept.1`
짐을 다 옮기고 나니 해가 기울었다. 노인이 {n} 스톤을 손에 쥐여 준다.

#### street.errand.decline.1 · `data/strings/ko.json:.city.street.errand.decline.1`
노인은 다른 사람을 부르러 간다.

#### street.fire.intro.1 · `data/strings/ko.json:.city.street.fire.intro.1`
밤사이 불이 났다. 매캐한 연기가 아직 골목에 남아 있다.

#### street.fire.result.1 · `data/strings/ko.json:.city.street.fire.result.1`
{name} 쪽이 그을음투성이다. 오늘은 문을 열지 못할 것 같다.

#### street.plague.intro.1 · `data/strings/ko.json:.city.street.plague.intro.1`
기침하는 사람이 부쩍 늘었다. 역병이 돈다는 소문에 신전 앞에 줄이 길다.

#### street.plague.intro.2 · `data/strings/ko.json:.city.street.plague.intro.2`
여관들도 식사와 잠자리 값을 슬그머니 올렸다.

### 도시 · meal

#### meal.squid_ink_fry · `data/strings/ko.json:.city.meal.squid_ink_fry`
새까만 튀김옷 속에서 오징어 다리가 꿈틀대듯 말려 있다. 짭조름한 먹물 맛에 발끝까지 가벼워진다.

#### meal.boar_rib_grill · `data/strings/ko.json:.city.meal.boar_rib_grill`
숯불 연기가 밴 멧돼지 갈비를 뼈째 뜯었다. 팔뚝에 힘이 들어간다.

#### meal.honey_quail · `data/strings/ko.json:.city.meal.honey_quail`
꿀을 발라 구운 메추리 두 마리가 나왔다. 손가락까지 핥고 나니 몸이 날렵해진 기분이다.

#### meal.goat_cheese_soup · `data/strings/ko.json:.city.meal.goat_cheese_soup`
산양젖 치즈가 실처럼 늘어나는 수프. 뱃속부터 단단히 데워진다.

#### meal.black_mushroom_risotto · `data/strings/ko.json:.city.meal.black_mushroom_risotto`
검은 버섯 향이 코끝을 찌르는 리소토. 머리가 맑게 개었다.

#### meal.mugwort_dumpling · `data/strings/ko.json:.city.meal.mugwort_dumpling`
쌉쌀한 쑥 경단을 콩고물에 굴려 먹었다. 마음이 차분히 가라앉는다.

#### meal.smoked_eel_rice · `data/strings/ko.json:.city.meal.smoked_eel_rice`
윤기 흐르는 훈제 장어를 밥 위에 얹어 먹었다. 몸 깊은 곳에서 기운이 차오른다.

#### meal.ginger_rye · `data/strings/ko.json:.city.meal.ginger_rye`
생강꿀차 한 잔에 호밀빵을 적셔 먹었다. 눈이 또렷해진다.

#### meal.grilled_sweetfish · `data/strings/ko.json:.city.meal.grilled_sweetfish`
소금을 뿌려 숯불에 구운 은어. 몸놀림이 물고기처럼 미끄러워진 것 같다.

#### meal.salted_herring · `data/strings/ko.json:.city.meal.salted_herring`
레몬 즙을 짜 넣은 소금 청어구이. 시큼한 맛에 정신이 번쩍 든다.

#### meal.blood_sausage · `data/strings/ko.json:.city.meal.blood_sausage`
김이 오르는 선지 소시지를 썰어 먹었다. 피가 피를 부르는 맛이다.

#### meal.bitter_herb_gukbap · `data/strings/ko.json:.city.meal.bitter_herb_gukbap`
쓴나물을 듬뿍 넣은 국밥. 혀가 얼얼하지만 속이 깨끗해진다.

#### meal.garlic_lamb_skewer · `data/strings/ko.json:.city.meal.garlic_lamb_skewer`
통마늘을 끼워 구운 양꼬치. 입에서 나는 마늘 냄새에 어둠도 물러설 것 같다.

#### meal.chili_oil_noodle · `data/strings/ko.json:.city.meal.chili_oil_noodle`
붉은 고추기름이 둥둥 뜬 국수. 이마에 땀이 맺히고 손발까지 후끈하다.

#### meal.mint_sherbet · `data/strings/ko.json:.city.meal.mint_sherbet`
박하 향이 도는 얼음과자를 사각사각 깨물었다. 몸속이 서늘하게 식는다.

#### meal.roast_carrot_stew · `data/strings/ko.json:.city.meal.roast_carrot_stew`
달큰하게 구운 당근을 듬뿍 넣은 스튜. 어둑한 홀 구석까지 잘 보인다.

#### meal.barley_porridge · `data/strings/ko.json:.city.meal.barley_porridge`
보리와 귀리를 푹 끓인 죽. 한 그릇이면 한참은 배가 꺼지지 않을 것 같다.

#### meal.bean_porridge · `data/strings/ko.json:.city.meal.bean_porridge`
따끈한 콩죽을 천천히 떠먹었다. 빈속이 겨우 달래진다.

#### meal.drake_tail_steak · `data/strings/ko.json:.city.meal.drake_tail_steak`
주인장이 아껴 둔 드레이크 꼬리를 두툼하게 잘라 구웠다. 씹을 때마다 피가 끓는다.

#### meal.butter_salmon · `data/strings/ko.json:.city.meal.butter_salmon`
버터에 졸인 감자를 곁들인 연어 통구이. 온몸이 가뿐하다.

#### meal.moonberry_tart · `data/strings/ko.json:.city.meal.moonberry_tart`
달빛 아래서만 익는다는 산딸기를 얹은 타르트. 머릿속이 은은하게 빛난다.

#### meal.whole_pig_roast · `data/strings/ko.json:.city.meal.whole_pig_roast`
홀 한가운데서 통째로 돌려 구운 돼지를 나눠 받았다. 몸이 한층 두꺼워진 것 같다.

#### meal.royal_herb_hotpot · `data/strings/ko.json:.city.meal.royal_herb_hotpot`
이름 모를 약초가 가득한 전골. 냄비 바닥까지 긁어 먹고 나니 몸이 독기를 밀어낸다.

#### meal.cave_truffle_soup · `data/strings/ko.json:.city.meal.cave_truffle_soup`
미궁 동굴에서 캐 왔다는 송로를 갈아 넣은 수프. 눈이 밝아지고 속이 든든하다.

### 동굴 요소

#### done · `data/strings/ko.json:.field.done`
이미 손을 댄 자리다.

#### done_today · `data/strings/ko.json:.field.done_today`
오늘은 이만하면 됐다.

#### missing · `data/strings/ko.json:.field.missing`
{status} 상태가 아니다.

#### no_cost · `data/strings/ko.json:.field.no_cost`
{item}이(가) 없다.

#### got · `data/strings/ko.json:.field.got`
{item}을(를) 챙겼다.

#### got_n · `data/strings/ko.json:.field.got_n`
{item} {n}개를 챙겼다.

#### no_room · `data/strings/ko.json:.field.no_room`
가방이 가득 차 {item}을(를) 두고 간다.

#### learned · `data/strings/ko.json:.field.learned`
{monster}의 습성을 짐작할 수 있게 됐다.

#### found_hidden · `data/strings/ko.json:.field.found_hidden`
발밑에 무언가 있다.

#### rest_campfire · `data/strings/ko.json:.field.rest_campfire`
꺼진 모닥불 곁에 자리를 잡는다. 남은 온기가 굳은 몸을 풀어 준다.

#### corpse_done · `data/strings/ko.json:.field.corpse_done`
이미 뒤진 시체다. 더는 아무것도 없다.

#### stones.1 · `data/strings/ko.json:.field.stones.1`
누군가 쏟아 놓고 간 마석이 한 줌 흩어져 있다. 가방이 넘쳤던 모양이다.

#### stones.2 · `data/strings/ko.json:.field.stones.2`
돌 틈에 마석이 소복이 쌓여 있다. 더 값진 것을 담으려 버리고 간 것 같다.

#### campfire.1 · `data/strings/ko.json:.field.campfire.1`
재가 식은 지 오래다. 장작 끝에 타다 만 횃불이 걸려 있다.

#### campfire.2 · `data/strings/ko.json:.field.campfire.2`
둥글게 쌓은 돌 안에 재만 남았다. 누군가 여기서 밤을 보냈다.

#### campfire_done · `data/strings/ko.json:.field.campfire_done`
식은 재만 남았다.

#### gear.1 · `data/strings/ko.json:.field.gear.1`
부러진 창대와 찢긴 가죽이 뒤엉켜 있다. 쓸 만한 것을 골라낸다.

#### gear.2 · `data/strings/ko.json:.field.gear.2`
녹슨 쇳조각을 하나씩 들춰 본다.

#### gear_done · `data/strings/ko.json:.field.gear_done`
쓸 만한 것은 이미 다 골라냈다.

#### cache_found · `data/strings/ko.json:.field.cache_found`
돌무더기가 어딘가 일부러 쌓은 듯 반듯하다.

#### cache · `data/strings/ko.json:.field.cache`
돌을 들어내자 기름 먹인 천 꾸러미가 나온다. 누군가 돌아올 생각이었나 보다.

#### cache_done · `data/strings/ko.json:.field.cache_done`
빈 구덩이만 남았다.

#### offering_offer · `data/strings/ko.json:.field.offering_offer`
기념비 앞에 마석 하나를 내려놓는다. 앞서 간 이들의 공물 곁에.

#### offering_no_stone · `data/strings/ko.json:.field.offering_no_stone`
바칠 마석이 없다.

#### offering_offered · `data/strings/ko.json:.field.offering_offered`
이미 공물을 바쳤다.

#### offering_take · `data/strings/ko.json:.field.offering_take`
공물 더미에서 마석을 집어 든다. 등 뒤가 서늘하다.

#### offering_taken · `data/strings/ko.json:.field.offering_taken`
남은 공물에는 손이 가지 않는다.

#### spring_drink.1 · `data/strings/ko.json:.field.spring_drink.1`
차고 맑은 물이 목을 타고 내려간다. 다리에 힘이 돈다.

#### spring_drink.2 · `data/strings/ko.json:.field.spring_drink.2`
손을 모아 물을 떠 마신다. 수정 빛이 물결에 흔들린다.

#### spring_full · `data/strings/ko.json:.field.spring_full`
배가 출렁일 만큼 마셨다.

#### spring_wash · `data/strings/ko.json:.field.spring_wash`
상처를 물에 담그자 굳은 피가 풀려 흘러간다.

#### spring_no_wound · `data/strings/ko.json:.field.spring_no_wound`
씻어 낼 상처가 없다.

#### spring_fill · `data/strings/ko.json:.field.spring_fill`
병에 샘물을 가득 담는다.

#### spring_filled · `data/strings/ko.json:.field.spring_filled`
오늘은 이미 물을 담았다.

#### drip · `data/strings/ko.json:.field.drip`
종유석 끝에서 떨어지는 물방울을 혀로 받는다. 차가운 수정 맛에 머리가 맑아진다.

#### drip_done · `data/strings/ko.json:.field.drip_done`
물방울은 너무 느리게 떨어진다.

#### stalagmites.1 · `data/strings/ko.json:.field.stalagmites.1`
석순이 숲처럼 솟아 있다. 사이로 몸을 숨길 만하다.

#### stalagmites.2 · `data/strings/ko.json:.field.stalagmites.2`
천장의 종유석과 바닥의 석순이 거의 맞닿아 있다. 오랜 세월이다.

#### mushroom · `data/strings/ko.json:.field.mushroom`
벽 틈에 핀 버섯이 희미하게 빛난다. 몇 송이를 딴다.

#### wolf_den · `data/strings/ko.json:.field.wolf_den`
뼈와 털이 수북하다. 칼날늑대의 잠자리다. 물어다 나른 먹이의 흔적으로 무리의 크기와 습성을 가늠한다.

#### wolf_den_done · `data/strings/ko.json:.field.wolf_den_done`
늑대 냄새가 진하게 배어 있다.

#### gnome_trinkets.1 · `data/strings/ko.json:.field.gnome_trinkets.1`
작은 망치와 깎다 만 돌 인형이 놓여 있다. 노움의 솜씨다.

#### gnome_trinkets.2 · `data/strings/ko.json:.field.gnome_trinkets.2`
손바닥만 한 돌 조각상들이 줄지어 서 있다. 하나같이 이쪽을 보고 있다.

#### gnome_stash_done · `data/strings/ko.json:.field.gnome_stash_done`
털린 은닉처는 텅 비었다.

#### ghoul_feast · `data/strings/ko.json:.field.ghoul_feast`
뜯어 먹힌 시체가 겹겹이 쌓여 있다. 썩은 살 사이로 손을 밀어 넣는다.

#### ghoul_feast_done · `data/strings/ko.json:.field.ghoul_feast_done`
더 뒤질 엄두가 나지 않는다.

#### rot_smell · `data/strings/ko.json:.field.rot_smell`
썩은 고기 냄새가 바람을 타고 온다. 가까운 곳에 구울이 있다.

#### goblin_camp · `data/strings/ko.json:.field.goblin_camp`
고블린들의 모닥불이다. 꼬치에 꿴 고기와 훔쳐 온 물건이 널려 있다.

#### goblin_camp_done · `data/strings/ko.json:.field.goblin_camp_done`
어지럽게 흩어진 뼈다귀만 남았다.

#### snare_detected · `data/strings/ko.json:.field.snare_detected`
발밑에 엉성하게 덮은 올가미가 보인다.

#### snare_disarmed · `data/strings/ko.json:.field.snare_disarmed`
올가미를 조심스레 풀어 치운다.

#### snare_pass · `data/strings/ko.json:.field.snare_pass`
발이 올가미를 스쳤지만 걸리지 않았다.

#### snare_fail · `data/strings/ko.json:.field.snare_fail`
올가미가 발목을 낚아챈다. 숨겨 둔 날붙이가 살을 파고든다.

#### slope_pass · `data/strings/ko.json:.field.slope_pass`
젖은 비탈을 조심스레 내려간다.

#### slope_fail · `data/strings/ko.json:.field.slope_fail`
물기에 발이 미끄러져 바위에 몸을 부딪는다.

#### portal_footprints · `data/strings/ko.json:.field.portal_footprints`
포탈 쪽으로 수많은 발자국이 이어진다. 돌아 나온 발자국은 드물다.

#### torch_stubs · `data/strings/ko.json:.field.torch_stubs`
암흑 경계에 횃불 꽁무니들이 꽂혀 있다. 아직 탈 만한 것을 하나 뽑는다.

#### old_skeleton.1 · `data/strings/ko.json:.field.old_skeleton.1`
아주 오래된 해골이 반쯤 바닥에 묻혀 있다. 곁의 장비는 처음 보는 모양이다.

#### old_skeleton.2 · `data/strings/ko.json:.field.old_skeleton.2`
흙빛으로 바랜 뼈 사이로 수정이 자라 들어가 있다.

#### crystal_glow · `data/strings/ko.json:.field.crystal_glow`
벽마다 수정이 촘촘해 동굴이 낮처럼 밝다.

#### mud_tracks · `data/strings/ko.json:.field.mud_tracks`
진흙 바닥에 무리가 지나간 발자국이 깊게 패어 있다. 아직 축축하다.

#### breeze · `data/strings/ko.json:.field.breeze`
바위 틈에서 서늘한 바람이 새어 나온다. 어딘가 큰 공간이 있다.

#### cairn · `data/strings/ko.json:.field.cairn`
누군가 납작한 돌을 쌓아 탑을 세웠다. 맨 위의 돌에는 아직 먼지가 앉지 않았다.

#### blood_well_pour · `data/strings/ko.json:.field.blood_well_pour`
손바닥을 그어 우물에 피를 흘려 넣었다. 바닥에서 검붉은 잔이 떠오른다.

#### blood_well_done · `data/strings/ko.json:.field.blood_well_done`
우물은 더 이상 피를 받지 않는다.

#### blood_well_look · `data/strings/ko.json:.field.blood_well_look`
우물 바닥에서 비릿한 냄새가 올라온다. 무언가가 목마른 것 같다.

#### dark_crystal_found · `data/strings/ko.json:.field.dark_crystal_found`
어둠 속에서 무언가 희미하게 빛난다. 불빛 아래서는 그냥 돌이었을 것이다.

#### dark_crystal_touch · `data/strings/ko.json:.field.dark_crystal_touch`
손끝이 닿자 수정의 빛이 눈 속으로 스며들었다. 어둠의 결이 조금 더 또렷하다.

#### offering_mushroom · `data/strings/ko.json:.field.offering_mushroom`
수정 버섯 세 송이를 공물 더미 위에 가지런히 올려 두었다.

#### offering_no_mushroom · `data/strings/ko.json:.field.offering_no_mushroom`
바칠 것이 모자라다.

#### offering_mushroom_done · `data/strings/ko.json:.field.offering_mushroom_done`
버섯은 이미 올려 두었다.

#### offering_nothing · `data/strings/ko.json:.field.offering_nothing`
돌과 마석 부스러기뿐이다.

#### offering_wait · `data/strings/ko.json:.field.offering_wait`
올려 둔 버섯이 그대로다.

#### offering_answer · `data/strings/ko.json:.field.offering_answer`
버섯은 사라지고, 그 자리에 서늘한 기운이 고여 있다. 들이마시자 넋이 맑아진다.

#### offering_answered · `data/strings/ko.json:.field.offering_answered`
공물 더미는 조용하다.

### 동굴 요소 · corpse

#### corpse.center.1 · `data/strings/ko.json:.field.corpse.center.1`
엎드린 채 굳은 탐험가다. 상처가 여러 갈래라 무엇에 당했는지 알 수 없다. 주머니를 뒤진다.

#### corpse.center.2 · `data/strings/ko.json:.field.corpse.center.2`
벽에 기대앉은 시체. 숨이 끊어질 때까지 누군가를 기다린 모양이다. 짐을 풀어 본다.

#### corpse.center.3 · `data/strings/ko.json:.field.corpse.center.3`
가죽 갑옷이 찢긴 채 쓰러진 탐험가. 손에 쥔 것을 하나씩 떼어 낸다.

#### corpse.east.1 · `data/strings/ko.json:.field.corpse.east.1`
목덜미에 반듯하게 베인 자국이 여럿이다. 짐승 이빨이라기엔 지나치게 날카롭다. 짐을 뒤진다.

#### corpse.east.2 · `data/strings/ko.json:.field.corpse.east.2`
갑옷째 그어진 할퀸 자국. 무리에게 둘러싸였던 것 같다. 남은 것을 챙긴다.

#### corpse.east.3 · `data/strings/ko.json:.field.corpse.east.3`
말라붙은 핏자국 위로 짐승 발자국이 어지럽다. 시체의 주머니를 뒤진다.

#### corpse.west.1 · `data/strings/ko.json:.field.corpse.west.1`
머리에 둔기 자국이 있다. 작은 손이 휘두른 망치 같다. 짐을 뒤진다.

#### corpse.west.2 · `data/strings/ko.json:.field.corpse.west.2`
주머니가 뒤집혀 있다. 누군가 반짝이는 것만 골라 가고 나머지를 버렸다.

#### corpse.west.3 · `data/strings/ko.json:.field.corpse.west.3`
온몸에 자잘한 돌멩이 상처가 남아 있다. 시체의 짐을 풀어 본다.

#### corpse.south.1 · `data/strings/ko.json:.field.corpse.south.1`
살점이 뜯겨 나간 자리가 검게 썩어 있다. 숨을 참고 짐을 뒤진다.

#### corpse.south.2 · `data/strings/ko.json:.field.corpse.south.2`
반쯤 먹힌 시체다. 이빨 자국이 사람의 것과 닮았다. 남은 것을 챙긴다.

#### corpse.south.3 · `data/strings/ko.json:.field.corpse.south.3`
썩은 냄새가 코를 찌른다. 고개를 돌린 채 주머니를 더듬는다.

#### corpse.north.1 · `data/strings/ko.json:.field.corpse.north.1`
등에 조잡한 화살촉이 박혀 있다. 짐을 뒤진다.

#### corpse.north.2 · `data/strings/ko.json:.field.corpse.north.2`
독에 부은 얼굴로 쓰러져 있다. 몸이 굳어 도망치지 못한 듯하다. 짐을 풀어 본다.

#### corpse.north.3 · `data/strings/ko.json:.field.corpse.north.3`
목에 올가미 자국이 남아 있다. 시체의 주머니를 뒤진다.
