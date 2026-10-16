class_name CrossLayout
extends RefCounted
## 1층 수정동굴의 고정 뼈대: 거대한 두꺼운 십자가(중심부 + 동·서·남·북 팔). 시드와 무관하게 늘 같다.
## 값은 floors/*.json의 gen(core_size·arm_length·arm_width·margin·dark_depth·portal_inset)에서 온다.
##   중심부 = 중심에서 체비셰프 거리 core_half 이내의 정사각형
##   팔     = 중심부 바깥, 팔 방향 거리(u) 1..arm_length, 옆 거리 arm_half 이내
##   암흑지대 = 팔 끝 dark_depth칸(u > arm_length - dark_depth) — 수정이 없고 주변광이 0
##   2층 포탈 = 팔 중심선, 팔 끝에서 portal_inset칸 안쪽(암흑지대 안)
## 지도 위·아래·왼쪽·오른쪽 = 북·남·서·동(나침반과 같다).

const ZONE_CENTER := "center"
const ARMS: Array[String] = ["east", "west", "south", "north"]
const AXES := {"east": Vector2i(1, 0), "west": Vector2i(-1, 0), "south": Vector2i(0, 1), "north": Vector2i(0, -1)}

var side: int = 0          ## 지도 한 변(정사각형)
var center: Vector2i
var core_half: int = 0
var arm_half: int = 0
var arm_length: int = 0
var dark_depth: int = 0
var portal_inset: int = 0


func _init(gen: Dictionary) -> void:
	core_half = JsonUtil.get_int(gen, "core_size", 31) / 2
	arm_half = JsonUtil.get_int(gen, "arm_width", 25) / 2
	arm_length = JsonUtil.get_int(gen, "arm_length", 44)
	dark_depth = JsonUtil.get_int(gen, "dark_depth", 10)
	portal_inset = JsonUtil.get_int(gen, "portal_inset", 4)
	var margin := maxi(1, JsonUtil.get_int(gen, "margin", 2))
	side = 2 * (core_half + arm_length + margin) + 1
	center = Vector2i(side / 2, side / 2)


static func axis(dir: String) -> Vector2i:
	return AXES.get(dir, Vector2i.ZERO)


## 팔 방향에서 본 왼쪽(옆 방향 단위 벡터).
static func lateral(dir: String) -> Vector2i:
	var a := axis(dir)
	return Vector2i(-a.y, a.x)


## 칸이 속한 구역: "center" / 팔 방향 / ""(십자가 밖 암반).
func zone_of(p: Vector2i) -> String:
	var d := p - center
	if absi(d.x) <= core_half and absi(d.y) <= core_half:
		return ZONE_CENTER
	if absi(d.y) <= arm_half and absi(d.x) > core_half and absi(d.x) <= core_half + arm_length:
		return "east" if d.x > 0 else "west"
	if absi(d.x) <= arm_half and absi(d.y) > core_half and absi(d.y) <= core_half + arm_length:
		return "south" if d.y > 0 else "north"
	return ""


## 팔 안에서 중심부 가장자리부터 바깥으로 몇 칸 나왔는가(1..arm_length). 팔이 아니면 0.
func arm_depth(p: Vector2i) -> int:
	var dir := zone_of(p)
	if not ARMS.has(dir):
		return 0
	var d := p - center
	var a := axis(dir)
	return d.x * a.x + d.y * a.y - core_half


func is_dark(p: Vector2i) -> bool:
	return arm_depth(p) > arm_length - dark_depth


## 암흑지대가 시작되는 팔 깊이(이 값보다 깊으면 암흑).
func dark_start() -> int:
	return arm_length - dark_depth


## 팔 dir의 2층 포탈 자리(고정).
func portal_pos(dir: String) -> Vector2i:
	return center + axis(dir) * (core_half + arm_length - portal_inset)


## 팔 dir 전체를 덮는 사각형.
func arm_rect(dir: String) -> Rect2i:
	var a := axis(dir)
	var l := lateral(dir)
	var p1 := center + a * (core_half + 1) + l * arm_half
	var p2 := center + a * (core_half + arm_length) - l * arm_half
	var tl := Vector2i(mini(p1.x, p2.x), mini(p1.y, p2.y))
	return Rect2i(tl, Vector2i(absi(p1.x - p2.x) + 1, absi(p1.y - p2.y) + 1))


## 팔 dir의 암흑지대 사각형.
func dark_rect(dir: String) -> Rect2i:
	var a := axis(dir)
	var l := lateral(dir)
	var p1 := center + a * (core_half + dark_start() + 1) + l * arm_half
	var p2 := center + a * (core_half + arm_length) - l * arm_half
	var tl := Vector2i(mini(p1.x, p2.x), mini(p1.y, p2.y))
	return Rect2i(tl, Vector2i(absi(p1.x - p2.x) + 1, absi(p1.y - p2.y) + 1))


## 나침반 경로: from에서 dir 쪽으로 **뒤로 한 칸도 가지 않고**(앞·옆 걸음만) to에 닿는가.
static func compass_path(map: FloorMap, from: Vector2i, dir: String, to: Vector2i) -> bool:
	var a := axis(dir)
	if not map.is_walkable(from):
		return false
	var seen := PackedByteArray()
	seen.resize(map.width * map.height)
	seen[map.idx(from)] = 1
	var queue: Array[Vector2i] = [from]
	var head := 0
	while head < queue.size():
		var p := queue[head]
		head += 1
		if p == to:
			return true
		for d in FloorMap.DIRS4:
			var q := p + d
			if d.x * a.x + d.y * a.y >= 0 and map.is_walkable(q) and seen[map.idx(q)] == 0:
				seen[map.idx(q)] = 1
				queue.append(q)
	return false


func core_rect() -> Rect2i:
	return Rect2i(center - Vector2i(core_half, core_half), Vector2i(core_half * 2 + 1, core_half * 2 + 1))


## 지도에 구역 번호·암흑지대·중심을 적는다(지형과 무관한 고정 뼈대).
func mark_zones(map: FloorMap) -> void:
	map.center = center
	map.zone_ids = PackedStringArray([""])
	for z: String in [ZONE_CENTER] + Array(ARMS):
		map.zone_ids.append(z)
	_fill(map.zones, map.width, core_rect(), 1)
	for dir in ARMS:
		_fill(map.zones, map.width, arm_rect(dir), map.zone_ids.find(dir))
		_fill(map.dark, map.width, dark_rect(dir), 1)


## 빛나는 타일을 두면 안 되는 칸(암흑지대와 그 둘레 margin칸) = 1.
func no_light_mask(map: FloorMap, margin: int) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(map.tiles.size())
	for dir in ARMS:
		_fill(out, map.width, dark_rect(dir).grow(margin).intersection(Rect2i(0, 0, map.width, map.height)), 1)
	return out


static func _fill(arr: PackedByteArray, w: int, r: Rect2i, value: int) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			arr[y * w + x] = value
