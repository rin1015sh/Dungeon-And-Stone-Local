extends RefCounted
## 사람형 뼈대: 키·자세 값으로 관절 위치(Vector3, 화면 x·y + 앞쪽 z)를 낸다. 정면에서 마주 선 모습이 기본.
## pose 키: stance(발 벌림, 키 비율) · knee(무릎 굽힘 0~1) · hunch(등 굽고 머리 앞으로 0~1) · lean(옆 기울기 -1~1)
##          weight(체중 실은 다리 -1~1) · knees_out(무릎 바깥으로) · splay(발끝 벌림 라디안)
##          twist(오른쪽 어깨가 앞으로 -1~1) · tilt(고개 기울기 라디안) · legs(다리 길이 배율) · neck(목 길이 배율)
##          arm_l / arm_r(팔 자세: hang·wide·claw·raise·hold·reach·cross·back·bow·staff) · sh(어깨 반폭) · hip(엉덩이 반폭) · head(머리 크기)
## 왼쪽 = 화면 왼쪽(무기는 보통 화면 왼쪽 손).


static func build(foot: Vector2, height: float, pose: Dictionary) -> Dictionary:
	var H := height
	var j := {}
	var hunch := float(pose.get("hunch", 0.0))
	var knee := float(pose.get("knee", 0.0))
	var lean := float(pose.get("lean", 0.0))
	var twist := float(pose.get("twist", 0.0))
	var legs := float(pose.get("legs", 1.0))
	var stance := float(pose.get("stance", 0.1)) * H
	var sh := float(pose.get("sh", 0.12)) * H
	var hip := float(pose.get("hip", 0.065)) * H
	var head := float(pose.get("head", 1.0))
	var weight := float(pose.get("weight", 0.0))  # 체중을 실은 다리(-1 왼쪽 · 1 오른쪽) — 그쪽 엉덩이가 올라가고 반대 다리는 풀린다
	var kout := float(pose.get("knees_out", 0.2))
	var drop := knee * 0.07 * H + hunch * 0.05 * H  # 굽힌 만큼 키가 줄어든다
	var hip_y := foot.y - 0.49 * H * legs - (1.0 - legs) * 0.02 * H + drop * 0.6
	j["pelvis"] = Vector3(foot.x + lean * 0.01 * H + weight * 0.012 * H, hip_y, 0.0)
	for s: int in [-1, 1]:
		var tag := "l" if s < 0 else "r"
		var bears := weight * s > 0.0
		var free := absf(weight) if weight * s < 0.0 else 0.0
		var hp := Vector3(foot.x + s * hip + weight * 0.012 * H, hip_y + 0.02 * H - weight * s * 0.014 * H, 0.0)
		var an := Vector3(foot.x + s * stance * (1.0 + free * 0.35), foot.y - 0.045 * H + free * 0.012 * H, free * 0.05 * H)
		var kb := knee + free * 0.4 - (0.1 if bears else 0.0)
		var kn := hp.lerp(an, 0.5) + Vector3(s * (kout * 0.03 + kb * 0.03) * H, -kb * 0.015 * H, (0.01 + kb * 0.07) * H)
		j["hip_" + tag] = hp
		j["knee_" + tag] = kn
		j["ankle_" + tag] = an
		j["toe_" + tag] = an + Vector3(s * 0.012 * H, 0.03 * H, 0.08 * H)
		j["foot_rot_" + tag] = s * float(pose.get("splay", 0.45))
	var torso_len := (0.33 - hunch * 0.06) * H
	var lean_x := lean * 0.05 * H
	j["waist"] = Vector3(foot.x + lean_x * 0.35, hip_y - torso_len * 0.32, hunch * 0.03 * H)
	j["chest"] = Vector3(foot.x + lean_x * 0.7, hip_y - torso_len * 0.66, hunch * 0.08 * H)
	j["neck"] = Vector3(foot.x + lean_x, hip_y - torso_len, hunch * 0.13 * H)
	for s: int in [-1, 1]:
		var tag := "l" if s < 0 else "r"
		var sz := s * twist * 0.04 * H
		j["shoulder_" + tag] = Vector3(foot.x + lean_x + s * sh, hip_y - torso_len * 0.93 + hunch * 0.02 * H + (lean * s) * 0.02 * H + weight * s * 0.012 * H, hunch * 0.09 * H + sz)
	var nk := float(pose.get("neck", 1.0))
	var head_h := 0.14 * H * head
	j["head_h"] = head_h
	j["head"] = Vector3(foot.x + lean_x * 1.2, hip_y - torso_len - head_h * 0.62 * nk + hunch * 0.05 * H, hunch * 0.17 * H)
	j["tilt"] = float(pose.get("tilt", 0.0))
	for s: int in [-1, 1]:
		var tag := "l" if s < 0 else "r"
		_arm(j, tag, s, str(pose.get("arm_" + tag, "hang")), H, float(pose.get("arms", 1.0)))
	return j


## 팔 하나: 어깨 → 팔꿈치 → 손목 → 손끝 방향.
static func _arm(j: Dictionary, tag: String, s: int, kind: String, H: float, arm_k: float) -> void:
	var sh: Vector3 = j["shoulder_" + tag]
	var ua := 0.165 * H * arm_k
	var fa := 0.15 * H * arm_k
	var el: Vector3
	var wr: Vector3
	match kind:
		"wide":
			el = sh + Vector3(s * 0.45, 0.9, 0.05).normalized() * ua
			wr = el + Vector3(s * 0.4, 0.9, 0.2).normalized() * fa
		"claw":  # 손을 앞으로 내밀어 할퀼 듯
			el = sh + Vector3(s * 0.55, 0.75, 0.3).normalized() * ua
			wr = el + Vector3(s * 0.1, -0.35, 0.9).normalized() * fa
		"raise":  # 머리 위로 치켜듦
			el = sh + Vector3(s * 0.65, -0.55, 0.1).normalized() * ua
			wr = el + Vector3(s * 0.1, -0.95, 0.2).normalized() * fa
		"hold":  # 무기를 옆구리 앞으로 쥠
			el = sh + Vector3(s * 0.35, 0.92, 0.05).normalized() * ua
			wr = el + Vector3(s * 0.15, 0.45, 0.85).normalized() * fa
		"reach":  # 옆으로 길게 뻗음
			el = sh + Vector3(s * 0.8, 0.45, 0.2).normalized() * ua
			wr = el + Vector3(s * 0.85, 0.2, 0.35).normalized() * fa
		"cross":  # 몸 앞으로 모음(지팡이·주문)
			el = sh + Vector3(s * 0.3, 0.9, 0.3).normalized() * ua
			wr = el + Vector3(-s * 0.75, -0.15, 0.6).normalized() * fa
		"staff":  # 지팡이를 세워 짚음
			el = sh + Vector3(s * 0.55, 0.8, 0.15).normalized() * ua
			wr = el + Vector3(s * 0.25, -0.2, 0.9).normalized() * fa
		"bow":  # 활을 앞으로 겨눔(정면이라 앞으로 뻗은 팔)
			el = sh + Vector3(s * 0.6, 0.3, 0.6).normalized() * ua
			wr = el + Vector3(s * 0.3, 0.0, 1.0).normalized() * fa
		"back":
			el = sh + Vector3(s * 0.25, 0.9, -0.3).normalized() * ua
			wr = el + Vector3(-s * 0.1, 0.8, -0.5).normalized() * fa
		_:  # hang(몸에서 조금 떨어져 팔꿈치가 살짝 굽은 채 늘어뜨림)
			el = sh + Vector3(s * 0.26, 0.96, -0.04).normalized() * ua
			wr = el + Vector3(s * 0.12, 0.95, 0.2).normalized() * fa
	j["elbow_" + tag] = el
	j["wrist_" + tag] = wr
	var dir := (wr - el).normalized()
	j["hand_dir_" + tag] = dir
	j["hand_" + tag] = wr + dir * 0.045 * H
