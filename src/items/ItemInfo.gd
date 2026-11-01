class_name ItemInfo
extends RefCounted
## 아이템 정의(items/<id>.json) 읽기 도우미. 값이 없으면 기본값.
##   size: [w, h] 격자 칸 수(기본 1×1) · stack: 한 칸에 쌓는 최대 개수(기본 1)
##   equip: {slot, two_handed, modifiers: [수정자], weapon: {damage_type, attack}}
##   icon: 그림 종류(없으면 분류로 정함) · color · rarity(common/fine/numbers)

const DEFAULT_ICON := {"light": "torch", "food": "food", "potion": "potion", "magic_stone": "stone",
	"weapon": "sword", "armor": "armor", "scroll": "scroll", "tool": "pouch", "material": "stone", "misc": "pouch"}


static func def(db: GameDatabase, id: String) -> Dictionary:
	return db.get_entry("items", id) if db != null else {}


static func size(db: GameDatabase, id: String) -> Vector2i:
	var a := JsonUtil.get_array(def(db, id), "size")
	return Vector2i(maxi(1, int(a[0])), maxi(1, int(a[1]))) if a.size() == 2 else Vector2i.ONE


static func stack(db: GameDatabase, id: String) -> int:
	return maxi(1, JsonUtil.get_int(def(db, id), "stack", 1))


## 아이템을 얻었다는 문구 키 하나(사용자 2026-11-01 "아이템 획득 문구 전부 통일"): item.got(_n) — 누가 받았는지 보일 때는 item.got_by(_n).
## 인자: {"item": 이름, "n": 개수, "who": 받은 사람}.
static func got_key(n: int, by: bool = false) -> String:
	return ("item.got_by" if by else "item.got") + ("" if n == 1 else "_n")


static func equip(db: GameDatabase, id: String) -> Dictionary:
	return JsonUtil.get_dict(def(db, id), "equip")


static func slot(db: GameDatabase, id: String) -> String:
	return JsonUtil.get_str(equip(db, id), "slot")


static func two_handed(db: GameDatabase, id: String) -> bool:
	return JsonUtil.get_bool(equip(db, id), "two_handed")


static func weapon(db: GameDatabase, id: String) -> Dictionary:
	return JsonUtil.get_dict(equip(db, id), "weapon")


static func icon(db: GameDatabase, id: String) -> String:
	var d := def(db, id)
	var i := JsonUtil.get_str(d, "icon")
	return i if not i.is_empty() else str(DEFAULT_ICON.get(JsonUtil.get_str(d, "category"), "pouch"))


static func color(db: GameDatabase, id: String) -> Color:
	return Color.from_string(JsonUtil.get_str(def(db, id), "color"), Color(0.6, 0.58, 0.55))


static func price(db: GameDatabase, id: String) -> int:
	return JsonUtil.get_int(def(db, id), "price")
