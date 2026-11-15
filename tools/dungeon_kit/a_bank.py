"""은행 전용 물건: 은행 접수대(창살 창구) · 금고 문 · 소형 금고 · 대형 금고 · 철제 보관함 · 잠금장치 · 은행 창살 · 금화 더미 · 보석 보관함 ·
서류 더미 · 봉인 도구 · 보안용 철문 · 귀중품 진열장 · 은행 문양 · 줄 세우는 말뚝.
저울 · 장부 · 돈통은 상점의 것(a_shop — scale · ledger · coin_box)을, 감옥 철창 · 사슬 자물쇠는 a_wall · a_special의 것을 그대로 쓴다.
은행 문양은 동전 + 저울을 둥근 테에 넣은 중립 도형이다(글자 없음)."""
import numpy as np

from kit import (F, box, cap, cone, cyl, ell, flat, hcyl, pool, prop, ring_x, rot_x, rot_y, rot_z, rough, smin, sphere, sub, torus, v3, disc_x)  # noqa: F401
import mats as M
from a_furniture import _frustum

PI = np.pi


def many(fns):
    return lambda p: np.minimum.reduce([f(p) for f in fns])


def bank_mats(k):
    k.mat("vault", M.metal("#4a4c50", "#5a4636", 81, 0.2))
    k.mat("vault_d", M.metal("#2e3034", "#4a3a2e", 82, 0.25))
    k.mat("velvet", M.plain("#4a1c2a", 0.25, 0.1, 83))
    k.mat("silver", M.metal("#9a9ea0", "#5a5a58", 84, 0.1))
    k.mat("gem_r", M.glow("#c04050"))
    k.mat("gem_g", M.glow("#40a070"))
    k.mat("gem_b", M.glow("#4a78d0"))
    k.mat("wax_r", M.plain("#8a2a24", 0.25, 0.1, 85))
    k.mat("dark_wood", M.wood("#3a2a20", 0.2, 2, 86))
    k.mat("marble_d", M.stone("#6a645c", None, 87))
    return k


def rivets(x0, x1, z0, z1, y, n=4, r=0.014):
    """네모 테두리에 박은 리벳."""
    pts = [(x0 + (x1 - x0) * i / (n - 1), z) for i in range(n) for z in (z0, z1)] + [(x, z0 + (z1 - z0) * i / (n - 1)) for i in range(1, n - 1) for x in (x0, x1)]
    return many([lambda p, x=x, z=z: sphere(p, v3(x, y, z), r) for x, z in pts])


def coin_stack(x, y, z, n, r=0.03, t=0.009):
    return lambda p: cyl(p, v3(x, y, z), r, n * t, 0.003) + np.maximum(np.sin((p[:, 2] - z) / t * 2 * PI), 0) * 0.002


def grille(x0, x1, z0, z1, y, step=0.07, r=0.008):
    """세로 쇠살 + 위아래 가로대."""
    n = int((x1 - x0) / step) + 1
    return many([lambda p, x=x0 + i * step: cap(p, v3(x, y, z0), v3(x, y, z1), r) for i in range(n)] + [lambda p, z=z: hcyl(p, v3(x0 - 0.01, y, z), v3(x1 + 0.01, y, z), r * 1.4) for z in (z0, z1)])


# ── 접수대 ──────────────────────────────────────────────────────────────────

@prop("teller_counter", "bank", cell=(4, 4), collide=(1.8, 0.6), tags=["bank", "counter", "wood", "iron"], name_ko="은행 접수대", interact="counter",
    variants={"open": {}, "closed": {"state": "closed"}, "plain": {"state": "plain"}, "end": {"state": "end"}})
def teller_counter(k, state="open", seed=1):
    """짙은 나무 · 돌 걸레받이 접수대 위에 놋 창살 칸막이, 가운데 창구(open = 쪽창이 열려 동전 쟁반 · closed = 덧문) · plain = 창살만 · end = 끝 칸(옆벽 판)."""
    bank_mats(k)
    w, d, h = 0.9, 0.3, 0.7
    k.add(rough(lambda p: box(p, v3(0, 0, 0.05), (w + 0.02, d + 0.02, 0.05), 0.01), 0.005, 0.2, seed), "marble_d")
    k.add(rough(lambda p: box(p, v3(0, 0, h / 2 + 0.04), (w, d, h / 2 - 0.04), 0.01), 0.006, 0.2, seed), "dark_wood")
    k.add(many([lambda p, x=x: box(p, v3(x, -d - 0.005, 0.4), (0.2, 0.012, 0.2), 0.01) for x in (-0.45, 0.0, 0.45)]), "wood_d")
    k.add(rough(lambda p: box(p, v3(0, 0, h + 0.03), (w + 0.04, d + 0.04, 0.03), 0.008), 0.004, 0.2, seed + 1), "marble_d")
    zt, zb = h + 0.62, h + 0.06
    k.add(many([lambda p, x=x: box(p, v3(x, 0.05, (zt + zb) / 2), (0.025, 0.025, (zt - zb) / 2 + 0.02)) for x in (-w + 0.02, w - 0.02)] + [lambda p: box(p, v3(0, 0.05, zt + 0.03), (w + 0.02, 0.03, 0.03))]), "dark_wood")
    if state == "end":
        k.add(lambda p: box(p, v3(-w + 0.02, 0.05, (zt + zb) / 2), (0.02, d + 0.02, (zt - zb) / 2)), "dark_wood")
        k.add(grille(-w + 0.08, w - 0.08, zb, zt, 0.05), "brass")
        return {}
    if state == "plain":
        k.add(grille(-w + 0.08, w - 0.08, zb, zt, 0.05), "brass")
        return {}
    k.add(grille(-w + 0.08, -0.26, zb, zt, 0.05), "brass")
    k.add(grille(0.26, w - 0.08, zb, zt, 0.05), "brass")
    k.add(lambda p: sub(box(p, v3(0, 0.05, (zt + zb) / 2), (0.26, 0.03, (zt - zb) / 2)), box(p, v3(0, 0.05, zb + 0.22), (0.18, 0.06, 0.14))), "brass")
    if state == "closed":
        k.add(lambda p: box(p, v3(0, 0.03, zb + 0.22), (0.18, 0.02, 0.14), 0.006), "wood_d")
        k.add(lambda p: sphere(p, v3(0.12, 0.0, zb + 0.22), 0.015), "brass")
    else:
        k.add(lambda p: sub(cyl(p, v3(0, -0.08, h + 0.06), 0.12, 0.025, 0.006), cyl(p, v3(0, -0.08, h + 0.075), 0.1, 0.03)), "brass")
        k.add(many([coin_stack(-0.03, -0.08, h + 0.07, 3), coin_stack(0.04, -0.06, h + 0.07, 2), coin_stack(0.0, -0.13, h + 0.07, 1)]), "gold")
    return {}


# ── 금고 ────────────────────────────────────────────────────────────────────

@prop("vault_door", "bank", layer="wall_decal", cell=(4, 4), collide=(2.0, 0.3), tags=["bank", "iron", "door"], name_ko="금고 문", interact="door",
    variants={"closed": {}, "ajar": {"state": "ajar"}, "open": {"state": "open"}}, meta={"states": {"closed": "ajar", "ajar": "open"}, "note": "벽에 박아 넣는다 — 원점 = 벽 밑동, 지름 약 1.7칸"})
def vault_door(k, state="closed", seed=1):
    """벽에 박은 두꺼운 쇠틀 + 둥근 금고 문(바퀴 손잡이 · 잠금 막대 · 경첩). ajar = 문이 조금 비껴 안이 어둡게 · open = 문이 옆으로 젖혀 안 선반의 금빛."""
    bank_mats(k)
    zc, R = 0.9, 0.8
    k.add(rough(lambda p: sub(box(p, v3(0, 0.0, zc), (R + 0.16, 0.06, R + 0.12), 0.02), np.maximum(np.hypot(p[:, 0], p[:, 2] - zc) - R + 0.02, np.abs(p[:, 1]) - 0.2)), 0.004, 0.2, seed), "vault_d")
    k.add(rivets(-R - 0.08, R + 0.08, zc - R - 0.04, zc + R + 0.04, -0.065, 6, 0.018), "vault")
    if state != "closed":
        k.add(lambda p: np.maximum(np.hypot(p[:, 0], p[:, 2] - zc) - R + 0.03, np.abs(p[:, 1] - 0.03) - 0.02), "void")
    if state == "open":
        k.add(many([lambda p, z=z: box(p, v3(0, 0.0, z), (0.5, 0.03, 0.012)) for z in (0.55, 0.9, 1.25)]), "wood_d")
        k.add(many([coin_stack(x, -0.0, 0.565, 3 + i % 3) for i, x in enumerate((-0.35, -0.25, -0.15, 0.2, 0.3))] + [lambda p: ell(p, v3(0.0, -0.0, 0.97), (0.1, 0.05, 0.07))]), "gold")
        k.add(many([lambda p, x=x: box(p, v3(x, -0.0, 1.31), (0.06, 0.04, 0.05), 0.01) for x in (-0.3, -0.12, 0.25)]), "leather")
    door_axis = {"closed": 0.0, "ajar": 0.35, "open": 1.45}[state]
    T = lambda p: rot_z(p - v3(R, 0, 0), -door_axis) + v3(R, 0, 0)
    face = lambda q: np.maximum(np.hypot(q[:, 0], q[:, 2] - zc) - R, np.abs(q[:, 1] + 0.1) - 0.08)
    k.add(lambda p: face(T(p)), "vault")
    k.add(lambda p: np.maximum(np.abs(np.hypot(T(p)[:, 0], T(p)[:, 2] - zc) - R * 0.72) - 0.02, np.abs(T(p)[:, 1] + 0.19) - 0.012), "vault_d")
    k.add(lambda p: np.minimum.reduce([torus(rot_x(T(p), PI / 2, (0, -0.24, zc)), v3(0, -0.24, zc), 0.22, 0.02)] + [cap(T(p), v3(0, -0.24, zc), v3(np.cos(a) * 0.22, -0.24, zc + np.sin(a) * 0.22), 0.015) for a in (0, PI / 2, PI, 3 * PI / 2)] + [cap(T(p), v3(0, -0.18, zc), v3(0, -0.25, zc), 0.045)]), "brass")
    k.add(lambda p: np.minimum.reduce([box(T(p), v3(R - 0.04, -0.12, zc + dz), (0.08, 0.06, 0.08), 0.01) for dz in (-0.45, 0.45)]), "vault_d")
    k.add(lambda p: np.minimum.reduce([sphere(T(p), v3(np.cos(a) * R * 0.86, -0.19, zc + np.sin(a) * R * 0.86), 0.022) for a in np.linspace(0, 2 * PI, 17)[:-1]]), "vault")
    return {"shadow": 0.3, "foot": 0.3}


@prop("strongbox", "bank", cell=(2, 2), collide=(0.55, 0.45), tags=["bank", "iron", "container"], name_ko="소형 금고", interact="container",
    variants={"closed": {}, "open": {"state": "open"}, "pried": {"state": "pried"}}, meta={"states": {"closed": "open"}})
def strongbox(k, state="closed", seed=1):
    """쇠띠 두른 작은 쇠 상자 + 자물쇠판. pried = 지렛대로 비틀어 연 자국 · 찌그러진 뚜껑."""
    bank_mats(k)
    w, d, h = 0.24, 0.17, 0.2
    k.add(rough(lambda p: sub(box(p, v3(0, 0, h / 2), (w, d, h / 2), 0.012), box(p, v3(0, 0, h), (w - 0.02, d - 0.02, h * 0.4))), 0.003, 0.2, seed), "vault")
    k.add(many([lambda p, x=x: box(p, v3(x, 0, h / 2), (0.018, d + 0.006, h / 2 + 0.004), 0.003) for x in (-w * 0.6, w * 0.6)]), "vault_d")
    k.add(lambda p: box(p, v3(0, -d - 0.004, h * 0.62), (0.045, 0.008, 0.05), 0.004), "brass")
    if state == "closed":
        k.add(lambda p: box(p, v3(0, 0, h + 0.03), (w + 0.006, d + 0.006, 0.03), 0.012), "vault")
        k.add(lambda p: hcyl(p, v3(-0.07, 0, h + 0.07), v3(0.07, 0, h + 0.07), 0.012), "vault_d")
        return {}
    a = 1.9 if state == "open" else 1.4
    k.add(lambda p: box(rot_x(p, -a, (0, d, h)), v3(0, d, h + 0.03), (w + 0.006, d + 0.006, 0.03), 0.012) + (sphere(p, v3(0.1, d, h + 0.05), 0.08) < 0) * 0.0 * (state == "pried"), "vault")
    k.add(lambda p: box(p, v3(0, 0, h - 0.05), (w - 0.025, d - 0.025, 0.01)), "void")
    if state == "open":
        k.add(many([coin_stack(-0.1, -0.05, h - 0.05, 4), coin_stack(-0.04, -0.06, h - 0.05, 3), lambda p: ell(p, v3(0.08, 0.02, h - 0.02), (0.1, 0.08, 0.04))]), "gold")
    else:
        k.add(lambda p: cap(p, v3(-0.3, -0.2, 0.02), v3(0.0, -0.05, 0.02), 0.014), "iron")      # 지렛대
        k.add(many([lambda p, x=x, y=y: cyl(p, v3(x, y, 0), 0.028, 0.008) for x, y in ((0.3, -0.18), (0.36, -0.1), (-0.32, 0.1))]), "gold")
    return {}


@prop("big_safe", "bank", cell=(3, 4), collide=(0.9, 0.6), tags=["bank", "iron", "container"], name_ko="대형 금고", interact="container",
    variants={"closed": {}, "open": {"state": "open"}}, meta={"states": {"closed": "open"}})
def big_safe(k, state="closed", seed=1):
    """사람 키의 쇠 금고: 굵은 다리 · 두 겹 문 · 바퀴 손잡이 · 놋 열쇠판. open = 문 젖혀 안 선반의 주머니와 서류."""
    bank_mats(k)
    w, d, h = 0.42, 0.3, 1.25
    k.add(many([lambda p, x=x: box(p, v3(x, 0, 0.05), (0.06, d - 0.04, 0.05), 0.01) for x in (-w + 0.08, w - 0.08)]), "vault_d")
    k.add(rough(lambda p: sub(box(p, v3(0, 0, 0.1 + h / 2), (w, d, h / 2), 0.03), box(p, v3(0, -0.1, 0.1 + h / 2), (w - 0.05, d, h / 2 - 0.05))), 0.003, 0.2, seed), "vault")
    k.add(lambda p: box(p, v3(0, 0, 0.12 + h), (w + 0.02, d + 0.02, 0.03), 0.01), "vault_d")
    if state == "open":
        k.add(lambda p: box(p, v3(0, 0.2, 0.1 + h / 2), (w - 0.05, 0.02, h / 2 - 0.05)), "void")
        for z in (0.45, 0.85):
            k.add(lambda p, z=z: box(p, v3(0, 0.0, z), (w - 0.05, d - 0.07, 0.012)), "vault_d")
        k.add(many([lambda p, x=x: smin(ell(p, v3(x, 0.0, 0.53), (0.07, 0.06, 0.08)), cap(p, v3(x, 0.0, 0.6), v3(x, 0.0, 0.65), 0.025), 0.02) for x in (-0.22, -0.05, 0.15)]), "leather")
        k.add(many([lambda p, i=i: box(p, v3(-0.1 + i * 0.12, 0.0, 0.92 + i * 0.006), (0.09, 0.12, 0.05 - i * 0.01), 0.004) for i in range(3)]), "paper")
        k.add(many([coin_stack(0.25, -0.02, 0.86, 5), coin_stack(0.3, 0.06, 0.86, 3)]), "gold")
        D = lambda p: rot_z(p - v3(-w, -d, 0), 1.75) + v3(-w, -d, 0)
        k.add(lambda p: box(D(p), v3(0, -d - 0.04, 0.1 + h / 2), (w - 0.02, 0.04, h / 2 - 0.02), 0.015), "vault")
        k.add(lambda p: box(D(p), v3(0, -d + 0.01, 0.1 + h / 2), (w - 0.07, 0.02, h / 2 - 0.07)), "vault_d")
        return {}
    k.add(lambda p: box(p, v3(0, -d - 0.03, 0.1 + h / 2), (w - 0.02, 0.03, h / 2 - 0.02), 0.015), "vault")
    k.add(lambda p: sub(box(p, v3(0, -d - 0.06, 0.1 + h / 2), (w - 0.06, 0.006, h / 2 - 0.06)), box(p, v3(0, -d - 0.06, 0.1 + h / 2), (w - 0.09, 0.02, h / 2 - 0.09))), "brass")
    k.add(lambda p: np.minimum.reduce([torus(rot_x(p, PI / 2, (0, -d - 0.1, 0.8)), v3(0, -d - 0.1, 0.8), 0.12, 0.014)] + [cap(p, v3(0, -d - 0.1, 0.8), v3(np.cos(a) * 0.12, -d - 0.1, 0.8 + np.sin(a) * 0.12), 0.01) for a in (0.3, 0.3 + 2.1, 0.3 + 4.2)]), "brass")
    k.add(lambda p: np.minimum(box(p, v3(0, -d - 0.07, 0.5), (0.035, 0.01, 0.05), 0.006), cap(p, v3(0, -d - 0.07, 0.65), v3(0, -d - 0.12, 0.65), 0.02)), "brass")
    k.add(many([lambda p, z=z: box(p, v3(w - 0.03, -d - 0.04, z), (0.03, 0.04, 0.07), 0.01) for z in (0.3, 1.1)]), "vault_d")
    return {}


@prop("deposit_lockers", "bank", layer="wall_decal", cell=(3, 4), collide=(1.4, 0.4), tags=["bank", "iron", "container"], name_ko="철제 보관함", interact="container",
    variants={"closed": {}, "one_open": {"state": "one_open"}, "looted": {"state": "looted"}})
def deposit_lockers(k, state="closed", seed=1):
    """벽에 붙인 쇠 보관함 벽: 4 × 5칸, 칸마다 열쇠 구멍 판 · 손잡이. 번호 대신 놋 판."""
    bank_mats(k)
    w, d, z0, z1 = 0.62, 0.2, 0.1, 1.6
    k.add(rough(lambda p: box(p, v3(0, -d, (z0 + z1) / 2), (w, d, (z1 - z0) / 2), 0.01), 0.003, 0.2, seed), "vault_d")
    cols, rows = 4, 5
    cw, ch = 2 * w / cols, (z1 - z0) / rows
    rng = np.random.default_rng(seed)
    opened = set()
    if state == "one_open":
        opened = {(2, 2)}
    elif state == "looted":
        opened = {(i, j) for i in range(cols) for j in range(rows) if rng.random() < 0.45}
    for i in range(cols):
        for j in range(rows):
            x, z = -w + cw * (i + 0.5), z0 + ch * (j + 0.5)
            if (i, j) in opened:
                k.add(lambda p, x=x, z=z: box(p, v3(x, -2 * d, z), (cw / 2 - 0.02, 0.012, ch / 2 - 0.02)), "void")
                a = 1.6 + rng.uniform(-0.2, 0.3)
                k.add(lambda p, x=x, z=z, a=a: box(rot_z(p - v3(x - cw / 2 + 0.02, -2 * d, 0), a) + v3(x - cw / 2 + 0.02, -2 * d, 0), v3(x, -2 * d - 0.01, z), (cw / 2 - 0.025, 0.012, ch / 2 - 0.025), 0.004), "vault")
                continue
            k.add(lambda p, x=x, z=z: box(p, v3(x, -2 * d - 0.006, z), (cw / 2 - 0.02, 0.01, ch / 2 - 0.02), 0.004), "vault")
            k.add(lambda p, x=x, z=z: np.minimum(box(p, v3(x, -2 * d - 0.02, z + 0.03), (0.022, 0.006, 0.026), 0.004), cap(p, v3(x - 0.04, -2 * d - 0.02, z - 0.04), v3(x + 0.04, -2 * d - 0.02, z - 0.04), 0.008)), "brass")
    return {"shadow": 0.4, "foot": 0.3}


@prop("lock_mechanism", "bank", cell=(2, 3), tags=["bank", "iron", "mechanism"], name_ko="금고 잠금장치", interact="lever",
    variants={"wall_locked": {}, "wall_open": {"state": "wall_open"}, "dial": {"state": "dial"}}, meta={"states": {"wall_locked": "wall_open"}})
def lock_mechanism(k, state="wall_locked", seed=1):
    """wall_* = 벽에 붙인 큰 잠금판(빗장 셋 + 바퀴 손잡이 — 바퀴를 돌리면 빗장이 빠진다) · dial = 바닥에 세운 다이얼 받침."""
    bank_mats(k)
    if state == "dial":
        k.add(rough(lambda p: smin(_frustum(p, v3(0, 0, 0), 0.2, 0.1, 0.7), cyl(p, v3(0, 0, 0), 0.24, 0.06, 0.01), 0.03), 0.003, 0.2, seed), "vault_d")
        k.add(lambda p: box(rot_x(p, -0.6, (0, 0, 0.78)), v3(0, 0, 0.78), (0.16, 0.12, 0.04), 0.01), "vault")
        k.add(lambda p: cyl(rot_x(p, -0.6 - PI / 2, (0, -0.02, 0.83)), v3(0, -0.02, 0.83), 0.08, 0.03, 0.01), "brass")
        k.add(lambda p: cap(rot_x(p, -0.6 - PI / 2, (0, -0.02, 0.83)), v3(0, -0.02, 0.86), v3(0, -0.02, 0.9), 0.02), "brass")
        return {}
    y = -0.04
    k.add(rough(lambda p: box(p, v3(0, y, 1.0), (0.32, 0.03, 0.42), 0.02), 0.003, 0.2, seed), "vault_d")
    k.add(rivets(-0.28, 0.28, 0.62, 1.38, y - 0.032, 4), "vault")
    slide = 0.0 if state == "wall_locked" else -0.18
    for z in (0.72, 1.0, 1.28):
        k.add(lambda p, z=z: hcyl(p, v3(-0.3 + slide, y - 0.05, z), v3(0.46 + slide, y - 0.05, z), 0.025), "vault")
        k.add(lambda p, z=z: box(p, v3(0.36, y - 0.05, z), (0.04, 0.035, 0.045), 0.006), "vault_d")
    k.add(lambda p: np.minimum.reduce([torus(rot_x(p, PI / 2, (-0.05, y - 0.12, 1.0)), v3(-0.05, y - 0.12, 1.0), 0.13, 0.015)] + [cap(p, v3(-0.05, y - 0.12, 1.0), v3(-0.05 + np.cos(a) * 0.13, y - 0.12, 1.0 + np.sin(a) * 0.13), 0.011) for a in (0.4 + slide * 6, 0.4 + slide * 6 + 2.1, 0.4 + slide * 6 + 4.2)]), "brass")
    return {"shadow": 0.0, "foot": 0.3}


@prop("bank_grille", "bank", cell=(3, 4), collide=(1.4, 0.15), tags=["bank", "brass", "partition"], name_ko="은행 창살 칸막이",
    variants={"panel": {}, "slot": {"state": "slot"}, "gate": {"state": "gate"}, "gate_open": {"state": "gate_open"}}, meta={"states": {"gate": "gate_open"}, "tile_w": 1.5})
def bank_grille(k, state="panel", seed=1):
    """낮은 돌 턱 위 놋 창살 칸막이(감옥 철창과 달리 위 끝이 창촉 · 고리 장식). 이어 붙이면 줄이 된다(폭 1.5칸)."""
    bank_mats(k)
    w, h = 0.75, 1.5
    k.add(rough(lambda p: box(p, v3(0, 0, 0.08), (w, 0.08, 0.08), 0.01), 0.004, 0.2, seed), "marble_d")
    posts = lambda p: np.minimum.reduce([box(p, v3(x, 0, 0.16 + h / 2), (0.03, 0.03, h / 2), 0.006) for x in (-w + 0.03, w - 0.03)])
    k.add(posts, "brass")
    k.add(many([lambda p, x=x: sphere(p, v3(x, 0, h + 0.2), 0.045) for x in (-w + 0.03, w - 0.03)]), "brass")
    if state == "gate_open":
        k.add(grille(-w + 0.1, -w + 0.25, 0.16, h + 0.12, 0.0, 0.07, 0.008), "brass")
        k.add(lambda p: grille(-0.32, 0.32, 0.16, h + 0.12, 0.0)(rot_z(p - v3(-w + 0.3, 0, 0), 1.3) + v3(-w + 0.3 + 0.32, 0, 0)), "brass")
        return {}
    k.add(grille(-w + 0.1, w - 0.1, 0.16, h + 0.12, 0.0), "brass")
    k.add(many([lambda p, x=x: cone(p, v3(x, 0, h + 0.12), 0.02, 0.07) for x in np.arange(-w + 0.1, w - 0.09, 0.07)]), "brass")
    k.add(many([lambda p, x=x: ring_x(p, v3(x, 0, h - 0.1), 0.04, 0.007) for x in np.arange(-w + 0.17, w - 0.15, 0.14)]), "brass")
    if state == "slot":
        k.add(lambda p: sub(box(p, v3(0, -0.02, 0.95), (0.22, 0.03, 0.1), 0.01), box(p, v3(0, -0.02, 0.95), (0.16, 0.06, 0.04))), "dark_wood")
        k.add(lambda p: box(p, v3(0, -0.12, 0.86), (0.24, 0.12, 0.015), 0.005), "dark_wood")
    if state == "gate":
        k.add(lambda p: box(p, v3(0.2, -0.02, 0.85), (0.04, 0.02, 0.06), 0.006), "iron")
    return {}


# ── 금화 · 보석 · 서류 ────────────────────────────────────────────────────────

@prop("coin_piles", "bank", cell=(2, 2), tags=["bank", "gold", "treasure"], name_ko="금화 더미",
    variants={"small": {}, "stacks": {"state": "stacks"}, "heap": {"state": "heap"}, "sack": {"state": "sack"}, "tray": {"state": "tray"}, "silver": {"state": "silver"}})
def coin_piles(k, state="small", seed=1):
    bank_mats(k)
    rng = np.random.default_rng(seed)
    if state in ("small", "heap"):
        r = 0.16 if state == "small" else 0.34
        k.add(rough(lambda p: ell(p, v3(0, 0, 0), (r, r * 0.85, r * 0.55)) + np.maximum(np.sin(p[:, 0] * 140) * np.sin(p[:, 1] * 130), 0) * 0.004, 0.02, 0.04, seed), "gold")
        k.add(many([lambda p, x=rng.uniform(-r, r) * 1.3, y=rng.uniform(-r, r): cyl(rot_x(p, rng.uniform(-0.4, 0.4), (x, y, 0)), v3(x, y, 0), 0.03, 0.008, 0.002) for _ in range(5 if state == "small" else 9)]), "gold")
        if state == "heap":
            k.add(many([lambda p, a=a: sphere(p, v3(np.cos(a) * 0.12, np.sin(a) * 0.1, r * 0.5), 0.025) for a in (0.5, 2.6)]), "gem_r")
        return {}
    if state in ("stacks", "silver"):
        mat = "gold" if state == "stacks" else "silver"
        for j in range(3):
            for i in range(4):
                n = int(rng.integers(3, 12)) if state == "stacks" else int(rng.integers(6, 16))
                k.add(coin_stack(-0.21 + i * 0.14, -0.1 + j * 0.1, 0, n, 0.032 if state == "stacks" else 0.026), mat)
        return {}
    if state == "sack":
        k.add(rough(lambda p: smin(sub(ell(p, v3(0, 0.03, 0.17), (0.2, 0.17, 0.18)), ell(p, v3(0, 0.03, 0.34), (0.14, 0.12, 0.08))), torus(p, v3(0, 0.03, 0.3), 0.14, 0.03), 0.04), 0.02, 0.1, seed), "leather")
        k.add(lambda p: ell(p, v3(0, 0.03, 0.3), (0.12, 0.1, 0.05)), "gold")
        k.add(rough(lambda p: ell(p, v3(0.1, -0.22, 0.0), (0.16, 0.1, 0.05)), 0.01, 0.04, seed), "gold")
        return {}
    k.add(lambda p: sub(box(p, v3(0, 0, 0.025), (0.3, 0.2, 0.025), 0.008), box(p, v3(0, 0, 0.045), (0.28, 0.18, 0.03))), "dark_wood")
    k.add(lambda p: box(p, v3(0, 0, 0.02), (0.28, 0.18, 0.006)), "velvet")
    for i in range(5):
        k.add(lambda p, i=i: box(p, v3(-0.22 + i * 0.11, 0, 0.035), (0.004, 0.18, 0.012)), "dark_wood")
        k.add(coin_stack(-0.17 + i * 0.11 - 0.05 * (i == 4), 0.0, 0.026, [6, 4, 8, 2, 5][i], 0.03), "gold" if i < 3 else "silver")
    return {}


@prop("gem_case", "bank", cell=(2, 2), collide=(0.6, 0.4), tags=["bank", "treasure", "glass"], name_ko="보석 보관함", interact="container",
    variants={"tray": {}, "coffer_closed": {"state": "coffer_closed"}, "coffer_open": {"state": "coffer_open"}})
def gem_case(k, state="tray", seed=1):
    bank_mats(k)
    if state == "tray":   # 유리 뚜껑 덮은 벨벳 쟁반
        k.add(lambda p: sub(box(p, v3(0, 0, 0.04), (0.3, 0.2, 0.04), 0.01), box(p, v3(0, 0, 0.07), (0.27, 0.17, 0.04))), "dark_wood")
        k.add(lambda p: box(p, v3(0, 0, 0.05), (0.27, 0.17, 0.006)), "velvet")
        mats_ = ("gem_r", "gem_g", "gem_b")
        for j in range(2):
            for i in range(4):
                k.add(lambda p, i=i, j=j: np.maximum(np.abs(p[:, 0] + 0.18 - i * 0.12) + np.abs(p[:, 1] + 0.06 - j * 0.12) - 0.035, np.abs(p[:, 2] - 0.07) - 0.018), mats_[(i + j) % 3])
        k.add(lambda p: sub(box(p, v3(0, 0, 0.1), (0.29, 0.19, 0.008)), box(p, v3(0, 0, 0.1), (0.27, 0.17, 0.02))), "brass")   # 유리 뚜껑의 놋 테(유리는 비친다 — 그리지 않는다)
        return {"glow": [(0, 0, 0.08, 18, "#c0a0d0", 0.15)]}
    k.add(rough(lambda p: box(p, v3(0, 0, 0.09), (0.2, 0.14, 0.09), 0.012), 0.003, 0.2, seed), "dark_wood")
    k.add(many([lambda p, x=x: box(p, v3(x, 0, 0.09), (0.014, 0.145, 0.092), 0.003) for x in (-0.13, 0.13)]), "gold")
    if state == "coffer_closed":
        k.add(lambda p: np.maximum(ell(p, v3(0, 0, 0.18), (0.205, 0.145, 0.07)), 0.18 - p[:, 2]), "dark_wood")
        k.add(lambda p: box(p, v3(0, -0.15, 0.16), (0.025, 0.008, 0.03), 0.004), "gold")
        return {}
    k.add(lambda p: box(p, v3(0, 0, 0.17), (0.18, 0.12, 0.006)), "velvet")
    k.add(lambda p: np.maximum(ell(rot_x(p, -1.8, (0, 0.14, 0.18)), v3(0, 0.14, 0.18), (0.205, 0.145, 0.07)), -(rot_x(p, -1.8, (0, 0.14, 0.18))[:, 2] - 0.18)), "dark_wood")
    k.add(many([lambda p, x=x, y=y: sphere(p, v3(x, y, 0.19), 0.028) for x, y in ((-0.08, -0.03), (0.05, 0.02), (0.1, -0.05))]), "gem_g")
    k.add(lambda p: torus(p, v3(-0.03, 0.05, 0.185), 0.05, 0.008), "gold")
    return {"glow": [(0, 0, 0.2, 16, "#a0d0b0", 0.2)]}


@prop("bank_documents", "bank", cell=(3, 4), collide=(1.2, 0.4), tags=["bank", "paper", "storage"], name_ko="은행 서류 더미", interact="examine",
    variants={"pigeonholes": {}, "bundles": {"state": "bundles"}, "stacks": {"state": "stacks"}})
def bank_documents(k, state="pigeonholes", seed=1):
    """pigeonholes = 칸칸이 말아 꽂은 서류 장 · bundles = 끈으로 묶은 서류 뭉치 · stacks = 위태롭게 쌓인 종이 탑."""
    bank_mats(k)
    rng = np.random.default_rng(seed)
    if state == "pigeonholes":
        w, d, h = 0.55, 0.2, 1.3
        k.add(rough(lambda p: sub(box(p, v3(0, 0, h / 2), (w, d, h / 2), 0.01), box(p, v3(0, -0.05, h / 2), (w - 0.03, d, h / 2 - 0.03))), 0.004, 0.2, seed), "dark_wood")
        for i in range(1, 5):
            k.add(lambda p, i=i: box(p, v3(-w + i * 2 * w / 5, 0, h / 2), (0.01, d - 0.01, h / 2 - 0.03)), "dark_wood")
        for j in range(1, 6):
            k.add(lambda p, j=j: box(p, v3(0, 0, j * h / 6), (w - 0.03, d - 0.01, 0.01)), "dark_wood")
        for i in range(5):
            for j in range(6):
                if rng.random() < 0.2:
                    continue
                x, z = -w + (i + 0.5) * 2 * w / 5, (j + 0.5) * h / 6 - 0.04
                for q in range(int(rng.integers(1, 4))):
                    k.add(lambda p, x=x + (q - 1) * 0.04, z=z + q * 0.02: hcyl(p, v3(x, -0.12, z), v3(x, 0.15, z), 0.022), "paper")
        return {}
    if state == "bundles":
        for i, (x, y, z, a) in enumerate(((-0.25, 0.0, 0, 0.1), (0.15, 0.05, 0, -0.2), (-0.05, -0.02, 0.12, 0.4), (0.3, -0.2, 0, 1.0))):
            T = lambda p, x=x, y=y, z=z, a=a: rot_z(p, a, (x, y, z))
            k.add(lambda p, T=T, x=x, y=y, z=z: box(T(p), v3(x, y, z + 0.055), (0.15, 0.11, 0.055), 0.008) + np.maximum(np.sin((T(p)[:, 2] - z) * 260), 0) * 0.002, "paper")
            k.add(lambda p, T=T, x=x, y=y, z=z: np.minimum(np.maximum(np.abs(T(p)[:, 0] - x) - 0.008, box(T(p), v3(x, y, z + 0.055), (0.2, 0.115, 0.06))), np.maximum(np.abs(T(p)[:, 1] - y) - 0.008, box(T(p), v3(x, y, z + 0.055), (0.155, 0.2, 0.06)))), "rope")
            k.add(lambda p, x=x, y=y, z=z: cyl(p, v3(x, y, z + 0.11), 0.02, 0.008), "wax_r")
        return {}
    for i, (x, y, n) in enumerate(((-0.25, 0.05, 9), (0.05, 0.0, 14), (0.3, -0.05, 6))):
        for q in range(n):
            a = rng.uniform(-0.15, 0.15)
            k.add(lambda p, x=x + rng.uniform(-0.015, 0.015) + q * 0.002 * (i - 1), y=y, q=q, a=a: box(rot_z(p, a, (x, y, 0)), v3(x, y, 0.025 + q * 0.05), (0.12, 0.09, 0.024), 0.004), "paper" if q % 3 else "linen")
    return {}


@prop("sealing_kit", "bank", cell=(2, 2), tags=["bank", "paper", "wax"], name_ko="봉인 도구",
    variants={"tray": {}, "letters": {"state": "letters"}})
def sealing_kit(k, state="tray", seed=1):
    """tray = 작은 쟁반 위 붉은 밀랍 막대 · 도장 · 촛대 · 끈 / letters = 밀랍으로 봉한 편지 몇 통."""
    bank_mats(k)
    if state == "tray":
        k.add(lambda p: sub(box(p, v3(0, 0, 0.015), (0.22, 0.15, 0.015), 0.006), box(p, v3(0, 0, 0.03), (0.2, 0.13, 0.02))), "brass")
        k.add(many([lambda p, y=y: hcyl(p, v3(-0.16, y, 0.04), v3(-0.02, y + 0.02, 0.04), 0.016) for y in (-0.06, -0.02)]), "wax_r")
        k.add(lambda p: smin(cyl(p, v3(0.07, -0.04, 0.03), 0.03, 0.02, 0.005), cap(p, v3(0.07, -0.04, 0.05), v3(0.07, -0.04, 0.13), 0.015, 0.022), 0.015), "dark_wood")
        k.add(lambda p: cyl(p, v3(0.07, -0.04, 0.026), 0.026, 0.006), "brass")
        k.add(lambda p: np.minimum(cyl(p, v3(0.13, 0.08, 0.03), 0.03, 0.01), cyl(p, v3(0.13, 0.08, 0.04), 0.012, 0.06)), "wax")
        k.add(lambda p: torus(p, v3(-0.08, 0.07, 0.04), 0.04, 0.007), "rope")
        return {}
    for i, (x, y, a) in enumerate(((-0.1, 0.0, 0.2), (0.1, 0.05, -0.3), (0.0, -0.08, 0.6))):
        k.add(lambda p, x=x, y=y, a=a, i=i: box(rot_z(p, a, (x, y, 0)), v3(x, y, 0.008 + i * 0.012), (0.12, 0.08, 0.006), 0.003), "paper")
        k.add(lambda p, x=x, y=y, i=i: cyl(p, v3(x, y, 0.014 + i * 0.012), 0.022, 0.008, 0.003), "wax_r")
    return {}


# ── 문 · 진열장 · 문양 · 말뚝 ─────────────────────────────────────────────────

@prop("security_door", "bank", layer="wall_decal", cell=(2, 4), collide=(1.0, 0.2), tags=["bank", "iron", "door"], name_ko="보안용 철문", interact="door",
    variants={"closed": {}, "open": {"state": "open"}}, meta={"states": {"closed": "open"}, "note": "벽에 박아 넣는다 — 원점 = 벽 밑동"})
def security_door(k, state="closed", seed=1):
    """두꺼운 돌 문틀 + 리벳 박은 쇠문, 눈높이 엿보는 틈(덧판) · 굵은 빗장 둘."""
    bank_mats(k)
    w, h = 0.42, 1.6
    k.add(rough(lambda p: sub(box(p, v3(0, 0, (h + 0.1) / 2), (w + 0.12, 0.06, (h + 0.1) / 2), 0.01), box(p, v3(0, 0, h / 2), (w, 0.2, h / 2))), 0.004, 0.2, seed), "marble_d")
    if state == "open":
        k.add(lambda p: box(p, v3(0, 0.02, h / 2), (w, 0.02, h / 2)), "void")
        k.add(lambda p: box(rot_z(p - v3(-w, -0.06, 0), 1.45) + v3(-w, -0.06, 0), v3(0, -0.06, h / 2), (w - 0.01, 0.035, h / 2 - 0.01), 0.008), "vault")
        return {"shadow": 0.3, "foot": 0.3}
    k.add(lambda p: box(p, v3(0, -0.04, h / 2), (w - 0.01, 0.035, h / 2 - 0.01), 0.008), "vault")
    k.add(rivets(-w + 0.06, w - 0.06, 0.08, h - 0.08, -0.078, 5), "vault_d")
    k.add(lambda p: box(p, v3(0, -0.08, 1.25), (0.14, 0.01, 0.03), 0.004), "void")
    k.add(lambda p: box(p, v3(0, -0.09, 1.31), (0.17, 0.012, 0.02), 0.004), "vault_d")
    for z in (0.45, 1.0):
        k.add(lambda p, z=z: hcyl(p, v3(-w - 0.08, -0.12, z), v3(w + 0.08, -0.12, z), 0.03), "iron")
        k.add(many([lambda p, x=x, z=z: box(p, v3(x, -0.1, z), (0.035, 0.04, 0.05), 0.006) for x in (-w - 0.06, w + 0.06)]), "vault_d")
    k.add(lambda p: box(p, v3(w - 0.12, -0.085, 0.75), (0.03, 0.008, 0.045), 0.004), "brass")
    return {"shadow": 0.3, "foot": 0.3}


@prop("valuables_case", "bank", cell=(3, 3), collide=(1.0, 0.5), tags=["bank", "treasure", "glass", "display"], name_ko="귀중품 진열장", interact="container",
    variants={"full": {}, "empty": {"state": "empty"}})
def valuables_case(k, state="full", seed=1):
    """가는 다리의 짙은 나무 진열대 + 비스듬한 유리 뚜껑 + 놋 자물쇠 — 벨벳 위 반지 · 목걸이 · 작은 잔."""
    bank_mats(k)
    w, d, h = 0.48, 0.24, 0.72
    k.add(many([lambda p, x=x, y=y: cap(p, v3(x, y, 0), v3(x * 0.95, y * 0.95, h - 0.08), 0.018, 0.024) for x in (-w + 0.05, w - 0.05) for y in (-d + 0.05, d - 0.05)]), "dark_wood")
    k.add(lambda p: sub(box(p, v3(0, 0, h - 0.04), (w, d, 0.06), 0.01), box(p, v3(0, 0, h + 0.02), (w - 0.03, d - 0.03, 0.06))), "dark_wood")
    k.add(lambda p: box(p, v3(0, 0, h - 0.0), (w - 0.03, d - 0.03, 0.005)), "velvet")
    if state == "full":
        k.add(many([lambda p, x=x: torus(rot_x(p, 0.6, (x, -0.05, h + 0.02)), v3(x, -0.05, h + 0.02), 0.03, 0.007) for x in (-0.3, -0.18)]), "gold")
        k.add(lambda p: np.maximum(np.abs(np.hypot(p[:, 0] - 0.05, (p[:, 1] - 0.02) * 1.3) - 0.11) - 0.006, np.abs(p[:, 2] - h - 0.01) - 0.006), "gold")
        k.add(lambda p: sphere(p, v3(0.05, -0.08, h + 0.02), 0.02), "gem_r")
        k.add(lambda p: smin(_frustum(p, v3(0.32, 0.05, h), 0.035, 0.015, 0.03), sub(_frustum(p, v3(0.32, 0.05, h + 0.06), 0.02, 0.04, 0.05), cyl(p, v3(0.32, 0.05, h + 0.07), 0.032, 0.06)), 0.01), "silver")
        k.add(many([lambda p, x=x, y=y: sphere(p, v3(x, y, h + 0.012), 0.013) for x, y in ((-0.35, 0.1), (-0.25, 0.12), (0.2, -0.12))]), "gem_b")
    lid = lambda p: box(rot_x(p, 0.18, (0, d, h + 0.06)), v3(0, 0, h + 0.07), (w - 0.02, d - 0.02, 0.008))
    k.add(lambda p: sub(lid(p), box(rot_x(p, 0.18, (0, d, h + 0.06)), v3(0, 0, h + 0.07), (w - 0.05, d - 0.05, 0.03))), "brass")   # 유리 뚜껑 테만
    k.add(lambda p: box(p, v3(0, -d - 0.005, h - 0.03), (0.025, 0.008, 0.025), 0.004), "brass")
    return {}


@prop("bank_emblem", "bank", layer="wall_decal", cell=(2, 3), tags=["bank", "brass", "ornament"], name_ko="은행 문양 판",
    variants={"plaque": {}, "worn": {"state": "worn"}})
def bank_emblem(k, state="plaque", seed=1):
    """벽에 거는 둥근 놋 문양판: 테 안에 양팔저울, 접시마다 동전 하나 — 글자 없음. 원점 = 벽 밑동(판 가운데 1.7칸)."""
    bank_mats(k)
    zc, y, R = 1.7, -0.03, 0.3
    mat = "brass" if state == "plaque" else "bronze"
    k.add(lambda p: disc_x(p, v3(0, y, zc), R, 0.02), "dark_wood")
    k.add(lambda p: ring_x(p, v3(0, y - 0.025, zc), R - 0.02, 0.022), mat)
    k.add(lambda p: np.minimum.reduce([cap(p, v3(0, y - 0.03, zc - 0.18), v3(0, y - 0.03, zc + 0.16), 0.014), box(p, v3(0, y - 0.03, zc - 0.19), (0.07, 0.01, 0.015), 0.004),
        cap(p, v3(-0.16, y - 0.03, zc + 0.12), v3(0.16, y - 0.03, zc + 0.12), 0.011)] + [cap(p, v3(sx * 0.15, y - 0.03, zc + 0.12), v3(sx * 0.15 + dx, y - 0.03, zc - 0.02), 0.004) for sx in (-1, 1) for dx in (-0.05, 0.05)]), mat)
    k.add(many([lambda p, sx=sx: np.maximum(np.hypot(p[:, 0] - sx * 0.15, (p[:, 2] - zc + 0.04) * 2.5) - 0.07, np.abs(p[:, 1] - y + 0.03) - 0.012) for sx in (-1, 1)]), mat)
    k.add(many([lambda p, sx=sx: disc_x(p, v3(sx * 0.15, y - 0.045, zc - 0.0), 0.032, 0.006) for sx in (-1, 1)]), "gold")
    return {"shadow": 0.0, "foot": 0.3}


@flat("bank_inlay", "bank", cell=(160, 120), tags=["bank", "brass", "ornament", "floor"], name_ko="바닥 놋 문양",
    variants={"bright": {}, "worn": {"worn": True}}, meta={"note": "로비 바닥 가운데에 박는 놋 원반(바닥 깊이로 눌린 타원)"})
def bank_inlay(c, worn=False, seed=1):
    cx, cy = 80, 60
    rx, ry = 72, 72 * 0.72
    disc = 1 - np.clip((c.dist(cx, cy, rx, ry) - 1) * 40, 0, 1)
    c.paint(disc, "#4e4840")
    for r, wd, col in ((1.0, 4.0, "#8a7440"), (0.82, 2.0, "#8a7440"), (0.42, 2.5, "#a08850")):
        c.paint(c.ring(cx, cy, rx * r, wd, 0.7, ry * r), col)
    ang = np.arctan2((c.yy - cy) / ry, (c.xx - cx) / rx)
    rr = c.dist(cx, cy, rx, ry)
    spokes = (np.abs(((ang / (2 * np.pi) * 16) % 1) - 0.5) < 0.06) * (rr > 0.44) * (rr < 0.8)
    c.paint(spokes.astype(np.float32), "#8a7440")
    dots = np.zeros_like(c.xx)
    for i in range(8):
        a = i * np.pi / 4 + np.pi / 8
        dots = np.maximum(dots, 1 - np.clip(c.dist(cx + np.cos(a) * rx * 0.91, cy + np.sin(a) * ry * 0.91, 3.5) - 1, 0, 1) * 1.0)
    c.paint(dots, "#b09448")
    c.paint(1 - np.clip(c.dist(cx, cy, rx * 0.2, ry * 0.2) - 1, 0, 1), "#b09448")
    if worn:
        c.shade(disc * (c.noise(10, seed) > 0.55), -0.35)
        c.shade(disc * (c.noise(3, seed + 1) > 0.7), -0.2)


@prop("queue_posts", "bank", cell=(4, 2), collide=(1.8, 0.2), tags=["bank", "brass", "partition"], name_ko="줄 세우는 말뚝",
    variants={"rope": {}, "single": {"state": "single"}, "down": {"state": "down"}})
def queue_posts(k, state="rope", seed=1):
    """무거운 받침의 놋 기둥 둘 + 사이에 늘어진 붉은 벨벳 줄. single = 기둥 하나 · down = 줄이 바닥에 떨어진 채."""
    bank_mats(k)
    xs = (-0.8, 0.8) if state != "single" else (0.0,)
    for x in xs:
        k.add(lambda p, x=x: np.minimum.reduce([_frustum(p, v3(x, 0, 0), 0.14, 0.1, 0.05), cyl(p, v3(x, 0, 0.04), 0.025, 0.75, 0.008), sphere(p, v3(x, 0, 0.82), 0.045)]), "brass")
    if state == "rope":
        k.add(lambda p: np.maximum(np.hypot(p[:, 1], p[:, 2] - (0.72 - 0.25 * (1 - (p[:, 0] / 0.8) ** 2))) - 0.022, np.abs(p[:, 0]) - 0.78), "velvet")
    elif state == "down":
        k.add(lambda p: np.maximum(np.hypot(p[:, 1] + 0.1 * np.sin(p[:, 0] * 3), p[:, 2] - 0.022) - 0.022, np.abs(p[:, 0]) - 0.7), "velvet")
    return {}
