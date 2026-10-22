extends CityEffect
## 조사 의뢰 보고(모험가 길드): {"type": "survey_report"} — 의뢰받은 종을 조사한 수만큼 받는다(값·상한은 city.json guild, CityGuild).


func apply(ctx: CityContext, _data: Dictionary) -> void:
	var p := CityGuild.report(ctx.state, ctx.pc)
	if int(p["n"]) <= 0:
		ctx.say("city.fx.no_survey", {}, "warn")
		return
	ctx.say("city.fx.survey_paid", {"name": DataNames.entry(ctx.db, "monsters", CityGuild.target(ctx.state)), "n": p["n"], "stones": p["stones"]}, "good")
