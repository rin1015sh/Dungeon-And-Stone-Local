class_name Timeline
extends RefCounted
## CTB 행동 순서(33원정대식): 참가자마다 행동 게이지가 있고, 틱마다 게이지 += 속도(민첩).
## 게이지가 임계값 이상이면 행동하고, 행동 뒤 게이지 -= 임계값 + 스킬 delay_cost.
## 2배 빠르면 대략 2배 자주 행동한다. 틱 반복 대신 "다음 도달까지 필요한 틱"을 계산해 한 번에 넘긴다.

var threshold: float = 100.0
var min_speed: float = 1.0
var units: Array[Combatant] = []


func _init(p_threshold: float = 100.0, p_min_speed: float = 1.0) -> void:
	threshold = maxf(1.0, p_threshold)
	min_speed = maxf(0.001, p_min_speed)


func add(c: Combatant) -> void:
	units.append(c)


## 다음에 행동할 참가자. 게이지를 실제로 진행시킨다. 행동할 수 있는 참가자가 없으면 null.
func next() -> Combatant:
	var c := _pick(units, _gauges(units))
	if c == null:
		return null
	var ticks := _ticks_needed(c, c.gauge)
	for u in units:
		if u.is_active():
			u.gauge += u.speed(min_speed) * ticks
	return c


## 행동을 마친 참가자의 게이지를 깎는다.
func consume(c: Combatant, delay_cost: float = 0.0) -> void:
	c.gauge -= threshold + maxf(0.0, delay_cost)


## 앞으로 n번의 행동 순서(모두 delay_cost 0으로 가정). 실제 게이지는 바꾸지 않는다.
func preview(n: int) -> Array[Combatant]:
	var out: Array[Combatant] = []
	var g := _gauges(units)
	for i in n:
		var c := _pick(units, g)
		if c == null:
			break
		var ticks := _ticks_needed(c, g[c])
		for u in units:
			if u.is_active():
				g[u] = float(g[u]) + u.speed(min_speed) * ticks
		g[c] = float(g[c]) - threshold
		out.append(c)
	return out


## 다음 도달자: 필요한 틱이 가장 적은 참가자. 같으면 게이지 큰 쪽 → 빠른 쪽 → 먼저 등록된 쪽.
func _pick(list: Array[Combatant], g: Dictionary) -> Combatant:
	var best: Combatant = null
	var best_ticks := INF
	for u in list:
		if not u.is_active():
			continue
		var t := _ticks_needed(u, g[u])
		if best == null or t < best_ticks - 0.000001 or (absf(t - best_ticks) <= 0.000001 and _before(u, best, g)):
			best = u
			best_ticks = t
	return best


func _before(a: Combatant, b: Combatant, g: Dictionary) -> bool:
	if not is_equal_approx(float(g[a]), float(g[b])):
		return float(g[a]) > float(g[b])
	if not is_equal_approx(a.speed(min_speed), b.speed(min_speed)):
		return a.speed(min_speed) > b.speed(min_speed)
	return a.order < b.order


func _ticks_needed(c: Combatant, gauge: float) -> float:
	return maxf(0.0, (threshold - gauge) / c.speed(min_speed))


func _gauges(list: Array[Combatant]) -> Dictionary:
	var g := {}
	for u in list:
		g[u] = u.gauge
	return g
