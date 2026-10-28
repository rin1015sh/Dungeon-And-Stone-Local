class_name MonsterArt
extends RefCounted
## 전투 일러스트: <render.json ui.combat_art_dir>/<몬스터 id>.webp(tools/paint_monsters.gd가 그림, 발 = 그림 아래 끝).
## 아군 쪽: 소환수 뒷모습 <몬스터 id>_back.webp(같은 폴더), 탐험가 <ui.combat_party_art_dir>/<종족>_back.webp.
## index.json(폴더마다) = 그림마다 몸 높이 px(들어 올린 무기·뿔은 뺀 발~정수리) — 무대가 정한 키를 이 높이에 맞춰 그림을 줄인다.
## 그림이 없으면 null → BattlerView는 CombatFigure 도형으로 그린다.

static var _indexes: Dictionary = {}  ## 폴더 → 색인


static func dir() -> String:
	return UiTheme.render_str("ui.combat_art_dir", "res://assets/monsters")


static func party_dir() -> String:
	return UiTheme.render_str("ui.combat_party_art_dir", "res://assets/party")


static func texture(monster_id: String) -> Texture2D:
	return texture_in(dir(), monster_id)


static func texture_in(folder: String, id: String) -> Texture2D:
	var path := folder.path_join(id + ".webp")
	if id == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


## 그림 속 몸 높이(px). 색인에 없으면 그림 높이 그대로.
static func body_height(monster_id: String, tex: Texture2D) -> float:
	return body_height_in(dir(), monster_id, tex)


static func body_height_in(folder: String, id: String, tex: Texture2D) -> float:
	if not _indexes.has(folder):
		_indexes[folder] = {}
		var path := folder.path_join("index.json")
		if FileAccess.file_exists(path):
			var errors: Array[String] = []
			var v: Variant = JsonUtil.read_file(path, errors)
			if v is Dictionary:
				_indexes[folder] = v
	return maxf(1.0, JsonUtil.get_float(_indexes[folder], id, float(tex.get_height())))
