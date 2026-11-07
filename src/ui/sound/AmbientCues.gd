class_name AmbientCues
extends RefCounted
## 층 분위기 효과음(data/audio.json ambience_cues — 층 art.ambience.loop 키, 균열은 "rift"): 항목마다 every [최소, 최대]초가 지나면 하나.
## tick(초)이 틀 소리 [{key, db}]를 돌려준다(화면이 AudioBus로 튼다 — 오토로드 비의존).

var _list: Array = []
var _due: Array[float] = []
var _rng := RandomNumberGenerator.new()


func setup(db: GameDatabase, key: String, seed_value: int = 0) -> void:
	_rng.seed = seed_value if seed_value != 0 else Time.get_ticks_usec()
	_list = JsonUtil.get_array(SoundData.section(db, "ambience_cues"), key)
	_due.clear()
	for v: Variant in _list:
		_due.append(_next(v))


func _next(v: Variant) -> float:
	var e := JsonUtil.get_array(v if v is Dictionary else {}, "every")
	return _rng.randf_range(float(e[0]), float(e[1])) if e.size() == 2 else 30.0


func tick(sec: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in _list.size():
		_due[i] -= sec
		if _due[i] <= 0.0:
			var d: Dictionary = _list[i]
			out.append({"key": JsonUtil.get_str(d, "sfx"), "db": JsonUtil.get_float(d, "db", 0.0)})
			_due[i] = _next(d)
	return out
