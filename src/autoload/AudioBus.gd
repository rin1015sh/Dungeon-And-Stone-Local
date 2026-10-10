extends Node
## 효과음/BGM 키 호출 래퍼(오토로드). 키 → 경로는 data/audio.json.
## 파일이 아직 없으면 조용히 건너뛴다(오류 없음). 아트·사운드 때문에 개발이 멈추지 않게.

var _sfx_players: Array[AudioStreamPlayer] = []
var _bgm_player: AudioStreamPlayer = null
var _next_sfx: int = 0
var _bgm_key: String = ""


func play_sfx(key: String) -> void:
	var stream := _stream("sfx", key)
	if stream == null:
		return
	_ensure_players()
	var p := _sfx_players[_next_sfx]
	_next_sfx = (_next_sfx + 1) % _sfx_players.size()
	p.stream = stream
	p.play()


func play_bgm(key: String) -> void:
	if key == _bgm_key:
		return
	_bgm_key = key
	var stream := _stream("bgm", key)
	_ensure_players()
	_bgm_player.stop()
	if stream != null:
		_bgm_player.stream = stream
		_bgm_player.play()


func stop_bgm() -> void:
	_bgm_key = ""
	if _bgm_player != null:
		_bgm_player.stop()


func _stream(kind: String, key: String) -> AudioStream:
	var audio: Dictionary = DataRegistry.db.singletons.get("audio", {})
	var path := JsonUtil.get_str(JsonUtil.get_dict(audio, kind), key)
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream


func _ensure_players() -> void:
	if _bgm_player != null:
		return
	var audio: Dictionary = DataRegistry.db.singletons.get("audio", {})
	for i in maxi(1, JsonUtil.get_int(audio, "sfx_voices", 1)):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_players.append(p)
	_bgm_player = AudioStreamPlayer.new()
	add_child(_bgm_player)
