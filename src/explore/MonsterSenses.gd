class_name MonsterSenses
extends RefCounted
## 필드 몬스터의 감지(순수 로직, MonsterSteering이 가진다).
##   보기: 감지 반경 안이고 벽에 가리지 않고, 바라보는 쪽(Group.facing)과 플레이어 쪽의 내적이 cos(시야각/2) 이상.
##         시야각 = balance monsters.view_cone_deg(전체 각도), 몬스터 behavior view_cone_deg가 있으면 그 값.
##   기척: monsters.sense_near_tiles 안이면 등 뒤라도 안다. 이미 쫓는 중이면 시야각을 보지 않는다(MonsterSteering).
##   소리: 움직이는 플레이어가 감지 반경 × monsters.hear_ratio 안이면(벽에 가리지 않음) 그쪽으로 돌아본다 — 알아챈 것은 아니다.

var near: float = 1.5
var hear_ratio: float = 0.6
var hear_hold_hours: float = 0.05
var _cos_half: float = 0.5


func _init(db: GameDatabase) -> void:
	near = float(db.bal("monsters.sense_near_tiles", 1.5))
	hear_ratio = float(db.bal("monsters.hear_ratio", 0.6))
	hear_hold_hours = float(db.bal("monsters.hear_hold_hours", 0.05))
	_cos_half = cos(deg_to_rad(float(db.bal("monsters.view_cone_deg", 120.0)) * 0.5))


## 바라보는 쪽 facing(단위 벡터)에서 본 to(플레이어 쪽, 칸 단위)가 시야각 안인가.
func in_cone(facing: Vector2, to: Vector2, beh: Dictionary) -> bool:
	if to.length_squared() < 0.0001:
		return true
	var c := _cos_half
	if beh.has("view_cone_deg"):
		c = cos(deg_to_rad(JsonUtil.get_float(beh, "view_cone_deg") * 0.5))
	return facing.dot(to.normalized()) >= c
