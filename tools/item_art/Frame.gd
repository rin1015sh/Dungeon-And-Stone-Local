extends RefCounted
## 아이템 그림 좌표 도우미(부품 공용 — ItemArt를 preload하면 순환이라 따로 둔다).
## 세로 축: t 0~1(아래 = 손잡이 → 위 = 끝), s = 가운데에서 가로 비율(캔버스 폭 기준 −0.5~0.5), dz = 앞으로(폭 비율).


static func V(ctx: Dictionary, t: float, s: float = 0.0, dz: float = 0.0) -> Vector3:
	var W: float = ctx["W"]
	var H: float = ctx["H"]
	var m := minf(W, H) * 0.08
	return Vector3(W * 0.5 + s * W, H - m - t * (H - 2.0 * m), dz * W)


static func P(ctx: Dictionary, t: float, s: float = 0.0) -> Vector2:
	var v := V(ctx, t, s)
	return Vector2(v.x, v.y)


## 두 축 좌표(가로 u 0~1 왼→오, 세로 v 0~1 위→아래) — 갑옷·방패처럼 칸을 채우는 물건.
static func Q(ctx: Dictionary, u: float, v: float) -> Vector2:
	return Vector2(float(ctx["W"]) * u, float(ctx["H"]) * v)


static func Q3(ctx: Dictionary, u: float, v: float, dz: float = 0.0) -> Vector3:
	return Vector3(float(ctx["W"]) * u, float(ctx["H"]) * v, dz * float(ctx["W"]))


static func poly(ctx: Dictionary, uv: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q: Vector2 in uv:
		out.append(Q(ctx, q.x, q.y))
	return out


## 5~6단계 소재 장비의 은은한 빛.
static func aura(ctx: Dictionary, at: Vector2, r: float) -> void:
	if ctx.has("aura"):
		ctx["glows"].append([at, r, ctx["aura"], 0.35])
