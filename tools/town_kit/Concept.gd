extends RefCounted
## 도시 구상 배치 — 차원광장 구역(사용자 2026-11-02 "둘 다 쓸 거고 틀어진 각도랑 정면 각도 생각해서 도시 맵 다시 구상 · 차원광장 옆에는 탐험가 길드").
## 좌표 = 칸(Godot X 동 · Y 위 · Z 남). 테라스 넷: 아래 단 LOW · 광장 단 MID · 위 단 UP · 꼭대기 TOP(북쪽이 높다).
## 줄(rows) = 한 거리를 따라 붙어 선 집들 — yaw 0(정면 판) · −28.8(사선 판) · +28.8(거울 사선 판)만 쓴다. 집 앞면이 모두 카메라 쪽(남·남남서·남남동).
## 기획 설명: docs/plans/city_town_v2.md

const LOW := -3.6
const MID := 0.0
const UP := 3.6
const TOP := 7.2
const SIDE := -28.8
const MIRROR := 28.8
const PLAZA := Vector3(0.0, 0.0, -1.0)
const PLAZA_R := 9.0

## 카메라: center = 화면 가운데에 올 땅 점, height = 화면 높이(칸) · plan = 위에서 본 배치.
const FRAME := {"center": Vector3(0.0, 0.0, -31.0), "height": 39.0, "plan_z": -10.0, "plan_height": 64.0}


## 테라스·광장·계단·난간.
func ground() -> Array:
	var g: Array = []
	var cobble := "#8f8676"
	for t: Array in [[LOW, 8.0, 40.0], [MID, -17.0, 8.0], [UP, -29.0, -17.0], [TOP, -70.0, -29.0]]:
		g.append({"kind": "box", "a": Vector3(-70, -14, t[1]), "b": Vector3(70, t[0], t[2]), "mat": "ashlar", "color": "#a39b8a", "scale": 0.45})
		g.append({"kind": "box", "a": Vector3(-70, t[0], t[1] + 0.02), "b": Vector3(70, t[0] + 0.02, t[2]), "mat": "cobble", "color": cobble, "scale": 0.5})
		if t[0] > LOW:  # 옹벽 머리돌(앞으로 조금 나온 띠 — 단 끝이 읽히게)
			g.append({"kind": "box", "a": Vector3(-70, t[0] - 0.28, t[2] - 0.3), "b": Vector3(70, t[0] + 0.05, t[2] + 0.18), "mat": "slabs", "color": "#b0a794"})
	# 차원광장: 판석 원 + 세 단 돌 단 + 돌 고리
	g.append({"kind": "disc", "at": PLAZA + Vector3(0, 0.04, 0), "r": PLAZA_R, "h": 0.04, "mat": "plaza", "color": "#b3aa96", "scale": 0.35})
	for i in 3:
		g.append({"kind": "disc", "at": PLAZA + Vector3(0, 0.15 + 0.3 * i, 0), "r": 3.4 - 0.65 * i, "h": 0.3, "mat": "slabs", "color": "#a9a08c"})
	g.append({"kind": "torus", "at": PLAZA + Vector3(0, 0.9 + 1.95, 0), "r0": 1.5, "r1": 1.95, "mat": "ashlar", "color": "#9a9384", "scale": 1.2})
	# 광장 단 남쪽 난간(가운데 큰 계단 자리만 비움)
	for xs: Vector2 in [Vector2(-70, -3.2), Vector2(3.2, 70)]:
		g.append({"kind": "box", "a": Vector3(xs.x, MID, 7.55), "b": Vector3(xs.y, MID + 0.55, 8.0), "mat": "ashlar", "color": "#8a8476"})
	# 계단: 아래 단 → 광장(큰 계단) · 광장 → 위 단(길드 옆 골목) · 위 단 → 꼭대기
	g.append({"kind": "stairs", "a": Vector3(0, LOW, 8.0 + 12 * 0.4), "w": 5.6, "n": 12, "rise": 0.3, "run": 0.4})
	g.append({"kind": "stairs", "a": Vector3(-0.95, MID, -17.0 + 12 * 0.4), "w": 2.6, "n": 12, "rise": 0.3, "run": 0.4})
	g.append({"kind": "stairs", "a": Vector3(12.6, UP, -29.0 + 12 * 0.4), "w": 2.6, "n": 12, "rise": 0.3, "run": 0.4})
	return g


## 따로 선 건물: fn · at(앞면 가운데 바닥 x, z) · y · yaw · flip(좌우 뒤집기).
func buildings() -> Array:
	return [
		{"fn": "_guild", "at": Vector2(-8.4, -10.6), "y": MID, "yaw": 0.0},  # 차원광장 바로 북서 — 정면 판
	]


## 줄: fns(서→동 · 줄 방향 순서) · start(줄 첫 집 앞면 왼쪽 끝 x, z) · y · yaw · gap(집 사이 틈) · flip(뒤집을 차례 번호).
func rows() -> Array:
	return [
		# 광장 단 — 광장 북쪽 정면 줄(골목·계단 동쪽)
		{"fns": ["_shop_house", "_step_gable", "_narrow_jetty"], "start": Vector2(0.9, -10.6), "y": MID, "yaw": 0.0, "gap": 0.15},
		# 광장 단 — 광장 북동 호: 사선 판(앞이 남남서 — 광장 쪽)
		{"fns": ["_tall_hip", "_arch_house", "_eaves_dormers", "_turret_house"], "start": Vector2(14.4, -9.6), "y": MID, "yaw": SIDE, "gap": 0.15, "jitter": 0.7},
		# 광장 단 — 광장 서쪽: 거울 사선 판(앞이 남남동 — 광장 쪽)
		{"fns": ["_workshop", "_narrow_jetty", "_shop_house", "_tall_hip"], "start": Vector2(-31.0, 5.4), "y": MID, "yaw": MIRROR, "gap": 0.15, "jitter": 0.7, "flip": [1]},
		# 위 단 정면 줄(계단 골목 하나 — x 11.3~13.9)
		{"fns": ["_mansard", "_tall_hip", "_bridge_pair", "_narrow_jetty", "_step_gable", "_eaves_dormers", "_turret_house", "_arch_house"], "start": Vector2(-40.0, -20.6), "y": UP, "yaw": 0.0, "gap": 0.15, "jitter": 1.1, "flip": [3, 6]},
		{"fns": ["_cross_gable", "_gallery_house", "_shop_house", "_tall_hip", "_workshop"], "start": Vector2(14.2, -20.6), "y": UP, "yaw": 0.0, "gap": 0.15, "jitter": 1.1},
		# 꼭대기 — 하늘선(종탑 · 신전 자리 · 저택)
		{"fns": ["_tall_hip", "_mansard", "_bell_tower", "_eaves_dormers", "_manor", "_chapel", "_step_gable", "_narrow_jetty", "_cross_gable", "_tall_hip", "_turret_house", "_mansard"], "start": Vector2(-40.0, -31.0), "y": TOP, "yaw": 0.0, "gap": 0.8, "jitter": 1.6, "flip": [3, 7, 10]},
		# 아래 단 — 광장 남쪽 낮은 집(앞은 아래 거리, 뒤가 옹벽에 붙는다), 가운데 큰 계단
		{"fns": ["_workshop", "_eaves_dormers", "_arch_house", "_workshop", "_gallery_house", "_workshop"], "start": Vector2(-38.0, 14.6), "y": LOW, "yaw": 0.0, "gap": 0.2, "jitter": 0.8, "flip": [3]},
		{"fns": ["_workshop", "_gallery_house", "_workshop", "_eaves_dormers", "_shop_house", "_workshop"], "start": Vector2(3.4, 14.6), "y": LOW, "yaw": 0.0, "gap": 0.2, "jitter": 0.8, "flip": [2, 3]},
	]


## 소품: kind · at · yaw.
func props() -> Array:
	var out: Array = [
		{"kind": "tent", "at": Vector3(-13.3, MID, -7.4)},  # 정산 천막 — 길드 앞
		{"kind": "board", "at": Vector3(-3.4, MID, -10.0)},  # 공시판 — 길드 문 옆
	]
	for a: float in [200.0, 240.0, 300.0, 340.0, 20.0, 160.0]:
		var d := Vector2.from_angle(deg_to_rad(a)) * (PLAZA_R + 0.6)
		out.append({"kind": "lamp", "at": PLAZA + Vector3(d.x, 0, d.y)})
	return out


## 이름표(그림 위에 python이 쓴다): text · at(3D 점) · kind(place = 시설·장소 · dir = 줄 방향 · step = 계단).
func labels() -> Array:
	return [
		{"text": "차원광장", "at": PLAZA + Vector3(0, 0, 7.0), "kind": "place"},
		{"text": "탐험가 길드", "at": Vector3(-8.4, 7.2, -10.6), "kind": "place"},
		{"text": "정산 천막", "at": Vector3(-13.3, 3.4, -7.4), "kind": "place"},
		{"text": "공시판", "at": Vector3(-3.4, 2.6, -10.0), "kind": "place"},
		{"text": "신전 자리", "at": Vector3(-2.9, 18.6, -31.0), "kind": "place"},
		{"text": "정면 줄", "at": Vector3(6.5, 6.6, -10.6), "kind": "dir"},
		{"text": "사선 줄", "at": Vector3(24.0, 6.0, -4.5), "kind": "dir"},
		{"text": "거울 사선 줄", "at": Vector3(-24.0, 6.5, 1.5), "kind": "dir"},
		{"text": "큰 계단", "at": Vector3(0, MID - 1.2, 10.4), "kind": "step"},
		{"text": "골목 계단", "at": Vector3(-0.95, MID + 3.0, -15.5), "kind": "step"},
		{"text": "위 계단", "at": Vector3(12.6, UP + 2.0, -26.5), "kind": "step"},
		{"text": "아래 단", "at": Vector3(-24.0, LOW + 6.2, 14.0), "kind": "step"},
	]
