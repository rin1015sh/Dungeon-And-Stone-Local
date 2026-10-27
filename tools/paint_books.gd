extends SceneTree
## 도서관 서적 그림 생성기(CT57): city.json library.fields 분야마다 art 경로에 960×540 그림 한 장(펼친 책 — tools/book_art/).
##   godot --headless --path . --script res://tools/paint_books.gd [-- --only=<분야 id,…>] [--out=<폴더>(시험 — art 경로 대신)]
## 장당 몇 초. 다 그린 뒤 --import. 확인은 캡처 --screen=city --facility=library --activity=library_<분야> --dialog.

const BookArt := preload("res://tools/book_art/BookArt.gd")
const Plates := preload("res://tools/book_art/Plates.gd")
const Plates2 := preload("res://tools/book_art/Plates2.gd")
const SEED := 4417

## 분야 id → [스크립트, 함수]
const PLATES := {
	"dungeon": [Plates, "dungeon"],
	"arms": [Plates, "arms"],
	"ailments": [Plates, "ailments"],
	"monsters": [Plates2, "monsters"],
	"survival": [Plates2, "survival"],
	"society": [Plates2, "society"],
}


func _init() -> void:
	var only: PackedStringArray = []
	var out := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	var db := GameDatabase.new()
	db.load_all("res://data")
	for f: Variant in CityInfo.fields(db):
		var id := JsonUtil.get_str(f, "id")
		if not only.is_empty() and not only.has(id):
			continue
		var path := JsonUtil.get_str(f, "art") if out.is_empty() else out.path_join(id + ".webp")
		if path.is_empty() or not PLATES.has(id):
			print("건너뜀: %s(그림 경로·그리는 함수 없음)" % id)
			continue
		var t0 := Time.get_ticks_msec()
		var pl: Array = PLATES[id]
		BookArt.paint(pl[0] as Script, str(pl[1]), SEED + absi(id.hash()) % 9973).save(path)
		print("그림: 서적 %s (%d ms)" % [id, Time.get_ticks_msec() - t0])
	quit(0)
