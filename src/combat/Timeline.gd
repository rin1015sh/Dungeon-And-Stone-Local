class_name Timeline
extends RefCounted
## CTB 행동 순서(33원정대식): 참가자마다 행동 게이지가 있고, 틱마다 게이지 += 속도.
## 속도 = (민첩 + speed_base)^speed_exp × 등급 배율(몬스터 rank — combat.rank_speed: 엘리트 1.1 ~ 계층군주 1.4).
##   speed_exp 0.75 = 민첩 3배여도 행동 약 2.2배(10층 비율 공식 — 스탯이 수백이 되어도 행동 차이가 끝없이 벌어지지 않게).
## 게이지가 임계값 이상이면 행동하고, 행동 뒤 게이지 -= 임계값 + 스킬 delay_cost.
## 한 참가자가 연달아 max_streak번 움직였으면 다음은 다른 참가자(0이면 제한 없음) — 아무리 빨라도 상대가 한 번은 움직인다.
## 틱 반복 대신 "다음 도달까지 필요한 틱"을 계산해 한 번에 넘긴다.

var threshold: float = 100.0
var min_speed: float = 1.0
var speed_base: float = 0.0
var speed_exp: float = 1.0
var rank_speed: Dictionary = {}  ## 몬스터 rank → 속도 배율
var max_streak: int = 0
var units: Array[Combatant] = []

var _last: Combatant = null
var _streak: int = 0


func _init(p_threshold: float = 100.0, p_min_speed: float = 1.0, p_speed_base: float = 0.0, p_speed_exp: float = 1.0,
		p_rank_speed: Dictionary = {}, p_max_streak: int = 0) -> void:
	threshold = maxf(1.0, p_threshold)
	min_speed = maxf(0.001, p_min_speed)
	speed_base = maxf(0.0, p_speed_base)
	speed_exp = clampf(p_speed_exp, 0.1, 1.0)
	rank_speed = p_rank_speed
	max_streak = maxi(0, p_max_streak)


func speed_of(c: Combatant) -> float:
	var mult := 1.0
	if c.actor is Monster:
		mult = float(rank_speed.get(JsonUtil.get_str((c.actor as Monster).def, "rank"), 1.0))
	return maxf(min_speed, c.speed(min_speed, speed_base, speed_exp) * mult)


func add(c: Combatant) -> void:
	units.append(c)


## 다음에 행동할 참가자. 게이지를 실제로 진행시킨다. 행동할 수 있는 참가자가 없으면 null.
func next() -> Combatant:
	var c := _pick(units, _gauges(units), _blocked(_last, _streak))
	if c == null:
		return null
	if c == _last:
		_streak += 1
	else:
		_last = c
		_streak = 1
	var ticks := _ticks_needed(c, c.gauge)
	for u in units:
		if u.is_active():
			u.gauge += speed_of(u) * ticks
	return c


## 행동을 마친 참가자의 게이지를 깎는다.
func consume(c: Combatant, delay_cost: float = 0.0) -> void:
	c.gauge -= threshold + maxf(0.0, delay_cost)


## 앞으로 n번의 행동 순서(모두 delay_cost 0으로 가정). 실제 게이지는 바꾸지 않는다.
func preview(n: int) -> Array[Combatant]:
	var out: Array[Combatant] = []
	var g := _gauges(units)
	var last := _last
	var streak := _streak
	for i in n:
		var c := _pick(units, g, _blocked(last, streak))
		if c == null:
			break
		streak = streak + 1 if c == last else 1
		last = c
		var ticks := _ticks_needed(c, g[c])
		for u in units:
			if u.is_active():
				g[u] = float(g[u]) + speed_of(u) * ticks
		g[c] = float(g[c]) - threshold
		out.append(c)
	return out


## 연달아 max_streak번 움직인 참가자(다른 참가자가 있을 때만 막는다). 없으면 null.
func _blocked(last: Combatant, streak: int) -> Combatant:
	if max_streak <= 0 or last == null or streak < max_streak or not last.is_active():
		return null
	for u in units:
		if u != last and u.is_active():
			return last
	return null


## 다음 도달자: 필요한 틱이 가장 적은 참가자. 같으면 게이지 큰 쪽 → 빠른 쪽 → 먼저 등록된 쪽. skip은 이번에 빼고 본다.
func _pick(list: Array[Combatant], g: Dictionary, skip: Combatant = null) -> Combatant:
	var best: Combatant = null
	var best_ticks := INF
	for u in list:
		if not u.is_active() or u == skip:
			continue
		var t := _ticks_needed(u, g[u])
		if best == null or t < best_ticks - 0.000001 or (absf(t - best_ticks) <= 0.000001 and _before(u, best, g)):
			best = u
			best_ticks = t
	return best


func _before(a: Combatant, b: Combatant, g: Dictionary) -> bool:
	if not is_equal_approx(float(g[a]), float(g[b])):
		return float(g[a]) > float(g[b])
	if not is_equal_approx(speed_of(a), speed_of(b)):
		return speed_of(a) > speed_of(b)
	return a.order < b.order


func _ticks_needed(c: Combatant, gauge: float) -> float:
	return maxf(0.0, (threshold - gauge) / speed_of(c))


func _gauges(list: Array[Combatant]) -> Dictionary:
	var g := {}
	for u in list:
		g[u] = u.gauge
	return g
