class_name CombatCoin
extends RefCounted
## 보스 동전 기술의 화면(C27 — 규칙은 BattleCoin): 적이 동전 스킬을 쓰기 직전에
##   ① 위쪽 작은 창에 스킬 이름 ② 앞면 · 뒷면 고르기(W/S · Enter — 질문 없이 두 칸, 뒤로 없음) ③ 동전 연출(CoinFlip)
## 돌려주는 값 = BattleCoin.roll 결과 — action["coin"]에 넣어 battle.act로 넘긴다(결과는 피해 숫자 · '회피'로 보인다, 글 없음).


static func ask(screen: Control, banner: SkillBanner, battle: Battle, c: Combatant, action: Dictionary) -> Dictionary:
	var sk := battle.db.get_entry("skills", str(action.get("skill", "")))
	banner.show_text(Strings.t("combat.banner_skill", {"name": c.label(), "skill": JsonUtil.get_str(sk, "name_ko")}))
	var guess := battle.rng.randi_range(0, 1)
	if not DialogueBox.auto_skip:  # 캡처 · 테스트: 고르지 않는다
		var opts: Array[Dictionary] = [{"text": Strings.t("explore.coin_heads")}, {"text": Strings.t("explore.coin_tails")}]
		guess = maxi(0, await ChoicePopup.ask(screen, "", opts, false))
	var out := BattleCoin.roll(battle, guess)
	if screen.is_inside_tree():
		await CoinFlip.play(screen, bool(out["heads"]))
	return out
