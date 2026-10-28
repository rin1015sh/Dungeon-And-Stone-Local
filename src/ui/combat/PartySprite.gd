class_name PartySprite
extends RefCounted
## 탐험가 전투 동작(UI41): <종족>_back_motions.webp(줄 = 동작, 칸 3 — tools/paint_motions.gd)와 <종족>_back_dead.webp(누운 몸 1칸).
## 무기를 들었으면 무기 덮개 <종족>_back_w_<종류>.webp(한손 one_hand · 양손 two_hand · 활 bow — 맨몸 시트와 같은 칸에 무기만)를 몸 위에 겹친다.
## 늘 도는 동작(loop — 대기 · 내 차례면 전투 자세)은 0-1-2-1로 칸마다 loop_s초, 한 번 하는 동작(play — 공격·스킬·피격·회피)은
## 칸마다 act_s초로 0-1-2 뒤 마지막 칸에 act_hold_s초 머물고 loop로 돌아간다. hold(방어 중 = 전투 자세)면 그 동작을 돈다. fall = 피격을 보인 뒤 누운 몸.
## 줄 순서·빠르기는 render.json ui.combat_party_motion.

var _cells := {}  ## 동작 → [AtlasTexture ×3]
var _weapon := {}  ## 동작 → [AtlasTexture ×3](무기 덮개 — 맨손이면 비어 있다)
var _dead: Texture2D = null
var _loop := "idle"
var _loop_t := 0.0
var _one := ""  ## 지금 한 번 하는 동작("" = 없음)
var _one_t := 0.0
var _hold := ""  ## 방어 중이면 그 동작을 돈다
var _fallen := false  ## 쓰러짐: 한 번 하는 동작(피격)이 끝나면 누운 몸
var _cur := ["idle", 0]  ## 지금 칸(동작, 번호) — 무기 덮개도 같은 칸


## 시트가 없으면 null(BattlerView는 한 장 그림을 그대로 쓴다). kind = 무기 종류(weapon_kind — ""면 맨손).
static func load_for(race: String, kind: String = "") -> PartySprite:
	var dir := MonsterArt.party_dir()
	var sheet := MonsterArt.texture_in(dir, race + "_back_motions")
	if sheet == null:
		return null
	var rows := UiTheme.render_array("ui.combat_party_motion.rows")
	if rows.is_empty():
		return null
	var ps := PartySprite.new()
	ps._cells = _slice(sheet, rows)
	if not kind.is_empty():
		var w := MonsterArt.texture_in(dir, race + "_back_w_" + kind)
		if w != null:
			ps._weapon = _slice(w, rows)
	ps._dead = MonsterArt.texture_in(dir, race + "_back_dead")
	ps._loop_t = randf() * 10.0  # 아군끼리 숨이 맞지 않게
	return ps


static func _slice(sheet: Texture2D, rows: Array) -> Dictionary:
	var out := {}
	var cw := sheet.get_width() / 3.0
	var ch := sheet.get_height() / float(rows.size())
	for r in rows.size():
		var cells: Array = []
		for i in 3:
			var a := AtlasTexture.new()
			a.atlas = sheet
			a.region = Rect2(cw * i, ch * r, cw, ch)
			cells.append(a)
		out[str(rows[r])] = cells
	return out


## 주무기 → 덮개 종류: 원거리 = bow, 양손 = two_hand, 그 밖 = one_hand, 맨손 = "".
static func weapon_kind(db: GameDatabase, item_id: String) -> String:
	if item_id.is_empty():
		return ""
	if JsonUtil.get_bool(ItemInfo.weapon(db, item_id), "ranged"):
		return "bow"
	return "two_hand" if ItemInfo.two_handed(db, item_id) else "one_hand"


## 행동 → 동작 이름(전투 행동 dict — Battle.act): 기본 공격 = 무기 종류대로(한손 칼 휘두르기 · 양손 내려치기 · 활 쏘기 · 맨손 주먹),
## 물리 피해 스킬 = 주먹 지르기, 그 밖의 스킬·아이템·도망 = 주문, 방어 = 전투 자세(따로 방어 동작은 두지 않는다 — 사용자 2026-10-28).
static func motion_for(db: GameDatabase, action: Dictionary, kind: String = "one_hand") -> String:
	match str(action.get("kind", "")):
		"guard":
			return "stance"
		"item", "flee":
			return "spell"
		"skill":
			var id := str(action.get("skill", Battle.BASIC_ATTACK))
			if id == Battle.BASIC_ATTACK:
				return str({"one_hand": "swing", "two_hand": "heavy", "bow": "shoot"}.get(kind, "thrust"))
			for e: Variant in JsonUtil.get_array(db.get_entry("skills", id), "effects"):
				if e is Dictionary and JsonUtil.get_str(e, "type") == "damage" and JsonUtil.get_str(e, "scaling", "phys") != "magic":
					return "thrust"
			return "spell"
	return ""


func set_loop(name: String) -> void:
	if _cells.has(name):
		_loop = name


func play(name: String) -> void:
	if _cells.has(name) and not _fallen:
		_one = name
		_one_t = 0.0


func set_hold(name: String) -> void:
	_hold = name if _cells.has(name) else ""


## 쓰러짐: 피격을 한 번 보이고 누운 몸으로(누운 그림이 없으면 피격 끝 칸).
func fall() -> void:
	if _fallen:
		return
	play("damage")
	_fallen = true


func revive() -> void:
	_fallen = false
	_one = ""


func fallen() -> bool:
	return _fallen


## 그 칸이 누운 몸인지(BattlerView가 발 자리에 눕혀 그린다).
func lying(cell: Texture2D) -> bool:
	return cell != null and cell == _dead


## 지금 칸 위에 겹칠 무기(맨손·누운 몸이면 null).
func overlay() -> Texture2D:
	var cells: Array = _weapon.get(_cur[0], [])
	return cells[_cur[1]] if not cells.is_empty() else null


## 시간을 delta만큼 보내고 지금 그릴 칸.
func tick(delta: float) -> Texture2D:
	var cfg := UiTheme.ui_dict("combat_party_motion")
	_loop_t += delta
	if not _one.is_empty():
		_one_t += delta
		var act_s := maxf(0.01, JsonUtil.get_float(cfg, "act_s", 0.12))
		var i := int(_one_t / act_s)
		if i < 3:
			return _at(_one, i)
		if _one_t < act_s * 3.0 + JsonUtil.get_float(cfg, "act_hold_s", 0.25):
			return _at(_one, 2)
		_one = ""
	if _fallen:
		if _dead != null:
			_cur = ["", 0]
			return _dead
		return _at("damage", 2)
	var loop_i := int(_loop_t / maxf(0.01, JsonUtil.get_float(cfg, "loop_s", 0.35))) % 4
	return _at(_hold if not _hold.is_empty() else _loop, loop_i if loop_i < 3 else 1)


func _at(name: String, i: int) -> Texture2D:
	_cur = [name, i]
	return _cells[name][i]
