class_name Rng
extends RefCounted
## 시드 고정 가능한 난수기. 게임 로직의 모든 무작위는 이것을 거친다(테스트 재현성).
## seed 0 = 무작위 시드를 새로 뽑는다(뽑힌 값은 seed_value로 확인 가능).

var seed_value: int = 0
var _rng := RandomNumberGenerator.new()


func _init(p_seed: int = 0) -> void:
	reseed(p_seed)


func reseed(p_seed: int = 0) -> void:
	if p_seed == 0:
		var tmp := RandomNumberGenerator.new()
		tmp.randomize()
		p_seed = int(tmp.randi()) + 1
	seed_value = p_seed
	_rng.seed = p_seed


func randi_range(from: int, to: int) -> int:
	return _rng.randi_range(from, to)


func randf() -> float:
	return _rng.randf()


func randf_range(from: float, to: float) -> float:
	return _rng.randf_range(from, to)


## p(0~1) 확률로 true.
func chance(p: float) -> bool:
	if p <= 0.0:
		return false
	if p >= 1.0:
		return true
	return _rng.randf() < p


func pick(arr: Array) -> Variant:
	if arr.is_empty():
		return null
	return arr[_rng.randi_range(0, arr.size() - 1)]


## 가중치 배열에서 인덱스 하나. 합이 0 이하면 -1.
func weighted_index(weights: Array) -> int:
	var total := 0.0
	for w: Variant in weights:
		total += maxf(0.0, float(w))
	if total <= 0.0:
		return -1
	var r := _rng.randf() * total
	for i in weights.size():
		var w := maxf(0.0, float(weights[i]))
		if r < w:
			return i
		r -= w
	for i in range(weights.size() - 1, -1, -1):
		if float(weights[i]) > 0.0:
			return i
	return -1


## 제자리 셔플(Fisher–Yates).
func shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp: Variant = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


## 저장/복원용 상태. JSON 정밀도 문제를 피하려 문자열로 다룬다.
func get_state_string() -> String:
	return str(_rng.state)


func set_state_string(s: String) -> void:
	_rng.state = s.to_int()
