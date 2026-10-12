extends SceneTree
## 경험치 예산 검사(docs/PROMPT_FLOOR1_V2.md §5.5). 헤드리스:
##   godot --headless --path . --script res://tools/exp_budget.gd
## 몬스터 데이터의 종별 첫 처치 경험치를 층별로 합산해 progression.json의 레벨 표·층별 목표와 비교하고
## docs/balance/exp_budget.md에 리포트를 쓴다. 검사 실패(1~4층 합계 비율 범위 밖)면 종료 코드 1.
## 아직 데이터가 목표보다 적은 층은 목표치로 대체해 '예상'으로 표시한다.

const OUT := "res://docs/balance/exp_budget.md"


func _initialize() -> void:
	var db := GameDatabase.new()
	db.load_all("res://data")
	var r := ExpBudget.report(db)
	var dir := DirAccess.open("res://")
	dir.make_dir_recursive("docs/balance")
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(str(r["markdown"]))
	f.close()
	print(str(r["markdown"]))
	print("리포트 → %s" % ProjectSettings.globalize_path(OUT))
	quit(0 if bool(r["ok"]) else 1)
