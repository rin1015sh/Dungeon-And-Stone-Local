extends Node
## 소리 키 호출 래퍼(오토로드). 키 → 소리는 data/audio.json(사용자 음원 — tools/import_sounds.py, docs/AUDIO.md).
## 파일이 없으면 조용히 건너뛴다(오류 없음).
##   sfx     {키: 경로} — 파일 하나
##   alias   {키: [키, …]} — 그중 하나를 무작위로(같은 소리가 되풀이되지 않게)
##   cues    {키: [{"sfx": 키, "at": 초, "db": 데시벨}, …]} — 여럿을 겹치거나 잇는다("덮쳐 오는 공포 → 낮은 종")
##   volume  {키: 데시벨} — 키마다 크기
##   steps / bgm / ambience {키: 경로} — 고리(걸음 · 음악 · 분위기). 걸음 · 심장은 loop 채널(set_loop)
## 음성 수 sfx_voices — 겹치는 효과음 수(넘치면 가장 오래된 것부터 끊는다).

var _sfx_players: Array[AudioStreamPlayer] = []
var _bgm_player: AudioStreamPlayer = null
var _next_sfx: int = 0
var _bgm_key: String = ""
var _amb_player: AudioStreamPlayer = null
var _amb_key: String = ""
var _loops: Dictionary = {}  ## 채널 → {"player": AudioStreamPlayer, "key": 키}
var _rng := RandomNumberGenerator.new()
## 헤드리스(테스트 · 도구 · 캡처)에서는 소리를 틀지 않는다 — 들리지도 않고, 울리던 재생 객체가 끝날 때 남는다("resources still in use").
var _silent: bool = DisplayServer.get_name() == "headless"


func _audio() -> Dictionary:
	return DataRegistry.db.singletons.get("audio", {})


## 효과음 하나(별칭이면 무작위 하나, 묶음이면 겹치고 잇는다). db = 더할 크기.
func play_sfx(key: String, db: float = 0.0) -> void:
	if key.is_empty() or _silent:
		return
	var a := _audio()
	var cue := JsonUtil.get_array(JsonUtil.get_dict(a, "cues"), key)
	if not cue.is_empty():
		for v: Variant in cue:
			var part: Dictionary = v if v is Dictionary else {}
			var at := JsonUtil.get_float(part, "at", 0.0)
			var k := JsonUtil.get_str(part, "sfx")
			var extra := JsonUtil.get_float(part, "db", 0.0) + db
			if at <= 0.0:
				play_sfx(k, extra)
			elif is_inside_tree():
				get_tree().create_timer(at).timeout.connect(play_sfx.bind(k, extra))
		return
	var alias := JsonUtil.get_array(JsonUtil.get_dict(a, "alias"), key)
	if not alias.is_empty():
		play_sfx(str(alias[_rng.randi_range(0, alias.size() - 1)]), db + _vol(key))
		return
	var stream := _stream("sfx", key)
	if stream == null:
		return
	_ensure_players()
	var p := _sfx_players[_next_sfx]
	_next_sfx = (_next_sfx + 1) % _sfx_players.size()
	p.stream = stream
	p.volume_db = _vol(key) + db
	p.pitch_scale = 1.0 + _rng.randf_range(-0.04, 0.04)  # 같은 소리도 조금씩 다르게
	p.play()


## 고리 채널(걸음 · 심장 박동 …): key가 바뀔 때만 다시 튼다. 빈 key = 멈춤. kind = audio.json의 갈래(steps · sfx).
func set_loop(channel: String, kind: String, key: String, db: float = 0.0) -> void:
	_ensure_players()
	if not _loops.has(channel):
		var pl := AudioStreamPlayer.new()
		add_child(pl)
		_loops[channel] = {"player": pl, "key": ""}
	var ch: Dictionary = _loops[channel]
	if str(ch["key"]) == key:
		return
	ch["key"] = key
	if _silent:
		return
	var p: AudioStreamPlayer = ch["player"]
	p.stop()
	var stream := _stream(kind, key) if not key.is_empty() else null
	if stream == null:
		return
	_set_loop(stream)
	p.stream = stream
	p.volume_db = _vol(key) + db
	p.play()


func loop_key(channel: String) -> String:
	return str((_loops.get(channel, {}) as Dictionary).get("key", ""))


func play_bgm(key: String) -> void:
	if key == _bgm_key:
		return
	_bgm_key = key
	var stream := _stream("bgm", key)
	_ensure_players()
	_bgm_player.stop()
	if stream != null and not _silent:
		_set_loop(stream)
		_bgm_player.stream = stream
		_bgm_player.volume_db = _vol(key)
		_bgm_player.play()


func stop_bgm() -> void:
	_bgm_key = ""
	if _bgm_player != null:
		_bgm_player.stop()


## 환경음 고리(data/audio.json ambience — 층 JSON art.ambience.loop). BGM과 따로 겹쳐 튼다. 분위기 효과음(가끔)은 AmbientCues.
func play_ambience(key: String) -> void:
	if key == _amb_key:
		return
	_amb_key = key
	_ensure_players()
	_amb_player.stop()
	var stream := _stream("ambience", key) if not key.is_empty() else null
	if stream != null and not _silent:
		_set_loop(stream)
		_amb_player.stream = stream
		_amb_player.volume_db = _vol(key)
		_amb_player.play()


## 지금 환경음이 key일 때만 멈춘다(빈 key = 무엇이든).
func stop_ambience(key: String = "") -> void:
	if not key.is_empty() and key != _amb_key:
		return
	_amb_key = ""
	if _amb_player != null:
		_amb_player.stop()


func _vol(key: String) -> float:
	return JsonUtil.get_float(JsonUtil.get_dict(_audio(), "volume"), key, 0.0)


static func _set_loop(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true


func _stream(kind: String, key: String) -> AudioStream:
	var path := JsonUtil.get_str(JsonUtil.get_dict(_audio(), kind), key)
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var s := load(path) as AudioStream
	if kind == "sfx" and s is AudioStreamOggVorbis:
		s = s.duplicate()  # 고리로 튼 같은 파일(심장 박동)이 효과음으로도 쓰일 때 한 번만 울리게
		(s as AudioStreamOggVorbis).loop = false
	return s


func _ensure_players() -> void:
	if _bgm_player != null:
		return
	for i in maxi(1, JsonUtil.get_int(_audio(), "sfx_voices", 1)):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_players.append(p)
	_bgm_player = AudioStreamPlayer.new()
	add_child(_bgm_player)
	_amb_player = AudioStreamPlayer.new()
	add_child(_amb_player)


## 끝낼 때: 울리는 소리를 모두 멈추고 놓는다(재생 중인 채로 끝나면 재생 객체가 남는다 — "resources still in use").
func _exit_tree() -> void:
	var all: Array[AudioStreamPlayer] = []
	all.append_array(_sfx_players)
	for p: AudioStreamPlayer in [_bgm_player, _amb_player]:
		if p != null:
			all.append(p)
	for ch: Dictionary in _loops.values():
		all.append(ch["player"] as AudioStreamPlayer)
	for p in all:
		p.stop()
		p.stream = null
