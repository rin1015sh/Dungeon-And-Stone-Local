"""환경 흔적: 해골 · 뼈 · 시체 · 핏자국 · 긁힌 자국 · 부서진 무기와 갑옷 · 깨진 병 · 낙서 · 먼지 · 물 얼룩 · 검은 점액 · 의식의 흔적."""
import numpy as np

import sdf
from kit import (F, K, box, cap, chip, cone, cut_above, cyl, ell, flat, hcyl, pool, prop, ring_x, rot_x, rot_y, rot_z, rough, smin, sphere, sub, torus, v3)  # noqa: F401
from paint2d import gblur, hexc, sstep

BLOOD, BLOOD_D, BLOOD_DRY = "#5c1412", "#2c0a0a", "#3c2018"


# ── 덩어리 도우미 ─────────────────────────────────────────────────────────────

def _bone(a, b, r=0.022):
    a, b = np.asarray(a, F), np.asarray(b, F)
    return lambda p: smin(cap(p, a, b, r), np.minimum(sphere(p, a, r * 1.7), sphere(p, b, r * 1.7)), r)


def _skull(k, c, r=0.085, yaw=0.0, tilt=0.0, mat="bone", cracked=False):
    """머리뼈: 둥근 머리통 + 광대 · 턱 + 눈구멍. c = 바닥에 닿는 점."""
    c = np.asarray(c, F)
    ctr = c + v3(0, 0, r)

    def tf(p):
        q = rot_z(p, yaw, c)
        return rot_x(q, tilt, ctr) if tilt else q
    body = lambda p: smin(sphere(p, ctr, r), box(p, c + v3(0, -r * 0.42, r * 0.42), (r * 0.56, r * 0.45, r * 0.38), r * 0.2), r * 0.3)
    if cracked:
        k.add(lambda p: np.maximum(body(tf(p)), -(np.abs(tf(p)[:, 0] - c[0] - r * 0.3 - (tf(p)[:, 2] - c[2]) * 0.3) - r * 0.12 + (tf(p)[:, 2] - c[2] - r * 1.3) * -0.4)), mat)
    else:
        k.add(lambda p: body(tf(p)), mat)
    k.add(lambda p: np.minimum.reduce([sphere(tf(p), ctr + v3(-r * 0.4, -r * 0.82, r * 0.02), r * 0.3), sphere(tf(p), ctr + v3(r * 0.4, -r * 0.82, r * 0.02), r * 0.3),
        box(tf(p), c + v3(0, -r * 0.9, r * 0.52), (r * 0.09, r * 0.1, r * 0.13)), box(tf(p), c + v3(0, -r * 0.88, r * 0.2), (r * 0.36, r * 0.06, r * 0.035))]), "void")


def _ribs(k, c, R=0.13, n=4, dz=0.07, mat="bone", r=0.016):
    for i in range(n):
        rr = R * (1.0 - abs(i - (n - 1) * 0.4) * 0.12)
        k.add(lambda p, i=i, rr=rr: torus(p, v3(c[0], c[1], c[2] + i * dz), rr, r), mat)


# ── 해골 · 뼈 ────────────────────────────────────────────────────────────────

@prop("skull", "trace", cell=(2, 3), tags=["bone", "death"], name_ko="해골",
    variants={"single": {}, "side": {"state": "side"}, "pair": {"state": "pair"}, "cracked": {"state": "cracked"}, "pike": {"state": "pike"}, "heap": {"state": "heap"}})
def skull(k, state="single", seed=1):
    if state == "single":
        _skull(k, (0, 0, 0), 0.09, 0.25)
    elif state == "side":
        _skull(k, (0, 0, 0), 0.09, 1.2, 0.0, "bone_d")
        k.add(_bone((0.16, -0.1, 0.02), (0.36, -0.04, 0.02), 0.018), "bone_d")
    elif state == "pair":
        _skull(k, (-0.13, 0.05, 0), 0.09, -0.4)
        _skull(k, (0.12, -0.06, 0), 0.08, 0.55, 0.0, "bone_d")
    elif state == "cracked":
        _skull(k, (0, 0, 0), 0.09, -0.2, 0.0, "bone", True)
        k.add(lambda p: np.minimum(ell(p, v3(0.18, -0.1, 0.015), (0.045, 0.03, 0.015)), ell(p, v3(0.24, 0.02, 0.012), (0.03, 0.025, 0.012))), "bone")
    elif state == "pike":
        k.add(rough(lambda p: cap(p, v3(0, 0, 0), v3(0.03, 0, 1.25), 0.03, 0.02), 0.012, 0.15, seed), "wood_d")
        _skull(k, (0.03, -0.01, 1.1), 0.095, 0.15, -0.15)
        k.add(lambda p: np.minimum(ell(p, v3(0.1, -0.08, 0.03), (0.07, 0.05, 0.03)), ell(p, v3(-0.09, -0.04, 0.025), (0.05, 0.04, 0.025))), "stone")
        return {"shadow": 0.4}
    else:   # heap: 쌓인 머리뼈
        for (x, y, z, a, m) in ((-0.17, 0.02, 0, -0.5, "bone_d"), (0.16, 0.03, 0, 0.6, "bone"), (0.0, -0.12, 0, 0.1, "bone"), (0.0, 0.05, 0.14, -0.2, "bone"), (-0.3, -0.12, 0, 1.3, "bone_d")):
            _skull(k, (x, y, z), 0.085, a, 0.0, m)
        k.add(_bone((0.22, -0.2, 0.02), (0.44, -0.12, 0.02), 0.018), "bone_d")
    return {}


@prop("bones", "trace", cell=(3, 2), tags=["bone", "death"], name_ko="뼈",
    variants={"scatter_a": {"seed": 3}, "scatter_b": {"seed": 8}, "crossed": {"state": "crossed"}, "pile": {"state": "pile"}, "ribcage": {"state": "ribcage"}, "spine": {"state": "spine"}})
def bones(k, state="scatter", seed=1):
    r = k.rng
    if state == "scatter":
        for i in range(6):
            x, y, a, ln = r.uniform(-0.45, 0.45), r.uniform(-0.25, 0.25), r.uniform(0, 3.14), r.uniform(0.1, 0.26)
            k.add(_bone((x - np.cos(a) * ln / 2, y - np.sin(a) * ln / 2, 0.022), (x + np.cos(a) * ln / 2, y + np.sin(a) * ln / 2, 0.022), r.uniform(0.014, 0.022)), "bone" if i % 3 else "bone_d")
        for i in range(4):
            x, y = r.uniform(-0.4, 0.4), r.uniform(-0.25, 0.25)
            k.add(lambda p, x=x, y=y: ell(p, v3(x, y, 0.015), (0.03, 0.022, 0.015)), "bone")
    elif state == "crossed":
        k.add(_bone((-0.3, -0.12, 0.03), (0.3, 0.12, 0.03), 0.026), "bone")
        k.add(_bone((-0.28, 0.14, 0.07), (0.3, -0.13, 0.07), 0.026), "bone_d")
        _skull(k, (0.0, -0.02, 0.07), 0.085, 0.1)
    elif state == "pile":
        for i in range(13):
            x, y, a, ln = r.uniform(-0.3, 0.3), r.uniform(-0.18, 0.18), r.uniform(0, 3.14), r.uniform(0.2, 0.42)
            z = 0.03 + (0.3 - np.hypot(x, y * 1.5)) * r.uniform(0.2, 0.6)
            t = r.uniform(-0.25, 0.25)
            k.add(_bone((x - np.cos(a) * ln / 2, y - np.sin(a) * ln / 2, max(0.022, z - t * ln)), (x + np.cos(a) * ln / 2, y + np.sin(a) * ln / 2, max(0.022, z + t * ln)), r.uniform(0.016, 0.024)), ("bone", "bone_d")[i % 2])
        _skull(k, (0.08, -0.12, 0.09), 0.08, 0.5)
        _skull(k, (-0.24, 0.0, 0.0), 0.075, -0.9, 0.0, "bone_d")
    elif state == "ribcage":   # 바닥에 반쯤 묻힌 갈비뼈
        k.add(lambda p: cap(p, v3(-0.3, 0, 0.04), v3(0.3, 0.02, 0.04), 0.028), "bone")
        for i in range(6):
            x = -0.26 + i * 0.105
            h = 0.26 - abs(i - 2.2) * 0.03
            for s in (-1, 1):
                k.add(lambda p, x=x, h=h, s=s: smin(cap(p, v3(x, 0, 0.05), v3(x + 0.01, s * 0.15, h), 0.014), cap(p, v3(x + 0.01, s * 0.15, h), v3(x + 0.02, s * 0.06, h + 0.1), 0.012, 0.007), 0.02), "bone" if s < 0 else "bone_d")
    else:   # spine: 등뼈 한 줄 + 골반
        for i in range(9):
            x = -0.36 + i * 0.075
            y = np.sin(i * 0.7) * 0.03
            k.add(lambda p, x=x, y=y: smin(ell(p, v3(x, y, 0.03), (0.03, 0.04, 0.03)), cap(p, v3(x, y, 0.03), v3(x, y + 0.01, 0.085), 0.01), 0.01), "bone")
        k.add(lambda p: sub(ell(p, v3(0.38, 0.0, 0.05), (0.1, 0.15, 0.05)), np.minimum(sphere(p, v3(0.4, -0.07, 0.06), 0.045), sphere(p, v3(0.4, 0.07, 0.06), 0.045))), "bone_d")
    return {}


def _lying_bones(k, mat="bone", arm_up=True):
    """대자로 누운 뼈대(머리 왼쪽)."""
    _skull(k, (-0.62, 0.03, 0), 0.085, 1.9, 0.0, mat)
    k.add(lambda p: cap(p, v3(-0.5, 0.0, 0.035), v3(0.05, -0.02, 0.035), 0.022), mat)
    for i in range(5):
        x = -0.42 + i * 0.075
        k.add(lambda p, x=x: np.maximum(np.abs(np.hypot(p[:, 1] + 0.005, (p[:, 2] - 0.03) * 1.5) - 0.115) - 0.013, np.abs(p[:, 0] - x) - 0.013), mat)
    k.add(lambda p: sub(ell(p, v3(0.1, -0.02, 0.045), (0.085, 0.13, 0.045)), sphere(p, v3(0.12, -0.02, 0.07), 0.05)), mat)
    limbs = [((0.14, -0.08, 0.03), (0.5, -0.2, 0.03)), ((0.5, -0.2, 0.03), (0.86, -0.14, 0.03)), ((0.14, 0.05, 0.03), (0.5, 0.16, 0.03)), ((0.5, 0.16, 0.03), (0.8, 0.3, 0.03)),
        ((-0.42, -0.13, 0.03), (-0.2, -0.32, 0.03)), ((-0.2, -0.32, 0.03), (0.06, -0.36, 0.03))]
    limbs += [((-0.42, 0.13, 0.03), (-0.62, 0.3, 0.03)), ((-0.62, 0.3, 0.03), (-0.86, 0.22, 0.03))] if arm_up else [((-0.42, 0.13, 0.03), (-0.16, 0.26, 0.03)), ((-0.16, 0.26, 0.03), (0.08, 0.2, 0.03))]
    for a, b in limbs:
        k.add(_bone(a, b, 0.019), mat)


@prop("skeleton", "trace", cell=(4, 3), tags=["bone", "death"], name_ko="유골", interact="search",
    variants={"lying": {}, "armored": {"state": "armored"}, "sitting": {"state": "sitting"}, "chained": {"state": "chained"}})
def skeleton(k, state="lying", seed=1):
    if state == "lying":
        _lying_bones(k)
        return {}
    if state == "armored":   # 녹슨 갑옷을 걸친 채 누운 유골
        _lying_bones(k, "bone_d", False)
        k.add(rough(lambda p: sub(ell(p, v3(-0.26, 0.0, 0.07), (0.22, 0.17, 0.11)), sphere(p, v3(-0.2, -0.06, 0.2), 0.07)), 0.02, 0.1, seed), "rust")
        k.add(lambda p: sub(sphere(p, v3(-0.66, 0.02, 0.09), 0.11), box(p, v3(-0.7, -0.12, 0.06), (0.08, 0.06, 0.05))), "rust")
        k.add(lambda p: np.minimum(box(rot_z(p, 0.35, (0.2, -0.42, 0)), v3(0.2, -0.42, 0.015), (0.33, 0.022, 0.012)), box(rot_z(p, 0.35, (0.2, -0.42, 0)), v3(-0.08, -0.42, 0.02), (0.02, 0.09, 0.015))), "rust")
        k.add(rough(lambda p: np.maximum(sphere(p, v3(0.55, 0.42, -0.28), 0.38), -p[:, 2]), 0.02, 0.1, seed), "wood_d")
        k.add(lambda p: sphere(p, v3(0.55, 0.42, 0.07), 0.06), "rust")
        return {}
    if state == "sitting":   # 벽에 기대앉은 유골(원점 = 벽 밑)
        pel, neck = v3(0, -0.2, 0.07), v3(0.02, -0.07, 0.56)
        k.add(lambda p: sub(ell(p, pel, (0.14, 0.09, 0.07)), sphere(p, pel + v3(0, -0.05, 0.05), 0.05)), "bone")
        k.add(lambda p: cap(p, pel, neck, 0.022), "bone")
        for i in range(4):
            c = pel + (neck - pel) * (0.45 + i * 0.13)
            k.add(lambda p, c=c: torus(rot_x(p, 0.25, c), c, 0.12, 0.015), "bone")
        k.add(lambda p: cap(p, neck + v3(-0.16, 0, -0.03), neck + v3(0.16, 0, -0.03), 0.017), "bone")
        _skull(k, neck + v3(0.03, -0.05, 0.0), 0.088, 0.25, -0.35)
        for s in (-1, 1):
            k.add(_bone(pel + v3(s * 0.09, 0, 0), (s * 0.42, -0.4, 0.2 if s < 0 else 0.05), 0.022), "bone")   # 한쪽 무릎은 세웠다
            k.add(_bone((s * 0.42, -0.4, 0.2 if s < 0 else 0.05), (s * (0.48 if s < 0 else 0.78), -0.56, 0.03), 0.019), "bone_d")
            k.add(_bone(neck + v3(s * 0.16, 0, -0.03), (s * 0.24, -0.16, 0.26), 0.017), "bone")
            k.add(_bone((s * 0.24, -0.16, 0.26), (s * 0.26, -0.36, 0.03), 0.015), "bone_d")
        k.add(lambda p: ell(p, v3(0, -0.2, 0.03), (0.2, 0.14, 0.03)) + sdf.noise(p, 0.05, seed) * 0.02, "cloth_k")
        return {"cell": (3, 3), "foot": 1.2}
    # chained: 벽 쇠고랑에 두 팔이 매달린 유골(원점 = 벽 밑)
    y = -0.07
    neck = v3(0, y, 1.12)
    for s in (-1, 1):
        k.add(lambda p, s=s: np.minimum(box(p, v3(s * 0.42, -0.02, 1.62), (0.05, 0.02, 0.05), 0.01), ring_x(p, v3(s * 0.42, y, 1.52), 0.05, 0.016)), "iron")
        k.add(_bone((s * 0.4, y, 1.46), (s * 0.3, y, 1.24), 0.016), "bone")
        k.add(_bone((s * 0.3, y, 1.24), neck + v3(s * 0.16, 0, -0.03), 0.018), "bone_d")
        k.add(_bone((s * 0.08, y, 0.58), (s * 0.13, y - 0.03, 0.3), 0.021), "bone")
        k.add(_bone((s * 0.13, y - 0.03, 0.3), (s * 0.1, y, 0.04), 0.018), "bone_d")
    k.add(lambda p: cap(p, neck + v3(-0.16, 0, -0.03), neck + v3(0.16, 0, -0.03), 0.017), "bone")
    k.add(lambda p: cap(p, neck, v3(0, y, 0.6), 0.022), "bone")
    for i in range(4):
        k.add(lambda p, i=i: torus(p, v3(0, y - 0.02, 1.0 - i * 0.075), 0.12 - abs(i - 1) * 0.01, 0.015), "bone")
    k.add(lambda p: sub(ell(p, v3(0, y, 0.6), (0.14, 0.07, 0.07)), sphere(p, v3(0, y - 0.05, 0.6), 0.05)), "bone")
    _skull(k, neck + v3(0.03, -0.06, -0.02), 0.088, -0.2, -0.5)
    k.add(lambda p: np.minimum(ell(p, v3(0.06, -0.25, 0.02), (0.05, 0.03, 0.02)), ell(p, v3(-0.1, -0.2, 0.015), (0.035, 0.03, 0.015))), "bone_d")
    return {"cell": (3, 3), "foot": 0.6, "shadow": 0.35}


@prop("skeleton_chained", "trace", layer="wall_decal", cell=(3, 3), tags=["bone", "death", "prison"], name_ko="쇠고랑에 매달린 유골", variants={"base": {}})
def skeleton_chained(k, seed=1):
    return skeleton(k, "chained", seed)


# ── 시체 ─────────────────────────────────────────────────────────────────────

@prop("corpse", "trace", cell=(4, 3), tags=["death"], name_ko="시체", interact="search",
    variants={"explorer": {}, "shrouded": {"state": "shrouded"}, "rotten": {"state": "rotten"}, "explorer_b": {"state": "explorer", "yaw": 2.6, "seed": 5}})
def corpse(k, state="explorer", seed=1):
    if state == "explorer":   # 엎어진 탐험가: 망토 · 배낭 · 바닥의 피
        k.add(lambda p: pool(p, v3(-0.05, -0.12, 0.006), 0.6, 0.34, 0.006) + (sdf.noise(p, 0.14, seed) - 0.5) * 0.14, "blood")
        k.add(rough(lambda p: smin(ell(p, v3(-0.05, 0, 0.09), (0.4, 0.24, 0.1)), ell(p, v3(0.25, 0.03, 0.06), (0.3, 0.3, 0.06)), 0.08) + np.sin(p[:, 0] * 14.0 + p[:, 1] * 9.0) * 0.008, 0.03, 0.12, seed), "cloth_g")
        k.add(lambda p: smin(sphere(p, v3(-0.5, -0.03, 0.09), 0.105), ell(p, v3(-0.4, -0.02, 0.1), (0.13, 0.13, 0.09)), 0.04), "cloth_k")
        for a, b, r0, m in (((0.3, -0.12, 0.06), (0.66, -0.2, 0.05), 0.07, "leather_d"), ((0.66, -0.2, 0.05), (0.98, -0.12, 0.045), 0.055, "leather"),
                ((0.3, 0.1, 0.06), (0.68, 0.14, 0.05), 0.07, "leather_d"), ((0.68, 0.14, 0.05), (0.96, 0.3, 0.045), 0.055, "leather"),
                ((-0.3, -0.2, 0.05), (-0.52, -0.36, 0.04), 0.05, "cloth_g"), ((-0.52, -0.36, 0.04), (-0.8, -0.32, 0.035), 0.04, "flesh"),
                ((-0.3, 0.2, 0.05), (-0.1, 0.38, 0.04), 0.05, "cloth_g")):
            k.add(lambda p, a=a, b=b, r0=r0: cap(p, v3(*a), v3(*b), r0, r0 * 0.8), m)
        k.add(rough(lambda p: box(p, v3(-0.1, 0.06, 0.22), (0.15, 0.13, 0.09), 0.05), 0.02, 0.1, seed), "leather")
        k.add(lambda p: np.minimum(box(p, v3(-0.1, -0.075, 0.22), (0.09, 0.012, 0.05), 0.01), cap(p, v3(-0.25, 0.06, 0.26), v3(0.05, 0.06, 0.26), 0.035)), "leather_d")
        k.add(lambda p: cap(p, v3(-0.86, -0.3, 0.02), v3(-1.02, -0.22, 0.02), 0.02), "flesh")
        return {}
    if state == "shrouded":   # 수의에 싸 밧줄로 묶은 주검
        body = lambda p: smin(smin(ell(p, v3(-0.05, 0, 0.11), (0.52, 0.19, 0.12)), sphere(p, v3(-0.62, 0, 0.12), 0.125), 0.07), ell(p, v3(0.62, 0, 0.09), (0.26, 0.12, 0.1)), 0.1)
        k.add(rough(lambda p: body(p) + np.sin(p[:, 0] * 22.0 + np.sin(p[:, 1] * 9.0) * 1.5) * 0.007, 0.02, 0.12, seed), "linen")
        for x in (-0.46, -0.1, 0.3, 0.66):
            k.add(lambda p, x=x: np.maximum(body(p) - 0.012, np.abs(p[:, 0] - x - p[:, 1] * 0.15) - 0.014), "rope")
        k.add(lambda p: pool(p, v3(-0.1, -0.02, 0.21), 0.14, 0.1, 0.02) + (sdf.noise(p, 0.07, seed) - 0.5) * 0.06, "blood")
        return {}
    # rotten: 반쯤 뜯긴 채 썩은 주검 — 갈비뼈가 드러났다
    k.add(lambda p: pool(p, v3(0.0, -0.05, 0.006), 0.66, 0.36, 0.006) + (sdf.noise(p, 0.12, seed) - 0.5) * 0.16, k.mat("ooze", __import__("mats").plain("#2c2416", 0.5, 0.08, 3)))
    k.add(rough(lambda p: sub(smin(ell(p, v3(0.22, 0, 0.08), (0.3, 0.2, 0.09)), ell(p, v3(-0.3, 0, 0.07), (0.2, 0.17, 0.07)), 0.06), ell(p, v3(-0.2, -0.02, 0.14), (0.24, 0.14, 0.09))), 0.04, 0.1, seed), "rot")
    k.add(lambda p: ell(p, v3(-0.2, 0, 0.045), (0.22, 0.13, 0.03)), "flesh")
    for i in range(5):
        x = -0.36 + i * 0.08
        k.add(lambda p, x=x: np.maximum(np.abs(np.hypot(p[:, 1], (p[:, 2] - 0.04) * 1.3) - 0.125) - 0.013, np.abs(p[:, 0] - x) - 0.013), "bone")
    _skull(k, (-0.62, 0.02, 0), 0.085, 2.0, 0.0, "bone_d")
    for a, b, r0, m in (((0.4, -0.1, 0.05), (0.78, -0.2, 0.04), 0.06, "rot"), ((0.4, 0.08, 0.05), (0.72, 0.26, 0.04), 0.06, "cloth_k"), ((-0.4, 0.15, 0.03), (-0.2, 0.36, 0.03), 0.02, "bone"), ((-0.42, -0.16, 0.04), (-0.66, -0.34, 0.03), 0.045, "rot")):
        k.add(lambda p, a=a, b=b, r0=r0: cap(p, v3(*a), v3(*b), r0, r0 * 0.75), m)
    k.add(_bone((0.78, -0.2, 0.03), (1.02, -0.12, 0.03), 0.018), "bone_d")
    return {}


@prop("gibbet", "trace", cell=(2, 5), collide=(0.5, 0.4), tags=["death", "prison", "iron"], name_ko="매달린 쇠우리", variants={"skeleton": {}, "empty": {"state": "empty"}})
def gibbet(k, state="skeleton", seed=1):
    z0, z1, R = 0.75, 2.0, 0.24
    for i in range(8):
        a = i * np.pi / 4 + 0.2
        x, y = np.cos(a) * R, np.sin(a) * R
        k.add(lambda p, x=x, y=y: smin(cap(p, v3(x, y, z0), v3(x, y, z1), 0.016), cap(p, v3(x, y, z1), v3(0, 0, z1 + 0.3), 0.016), 0.02), "rust" if i % 3 == 0 else "iron")
    for z in (z0, (z0 + z1) / 2, z1):
        k.add(lambda p, z=z: torus(p, v3(0, 0, z), R, 0.02), "iron")
    k.add(lambda p: cyl(p, v3(0, 0, z0 - 0.02), R, 0.03), "iron")
    for i in range(7):
        z = z1 + 0.34 + i * 0.105
        k.add((lambda p, z=z: ring_x(p, v3(0, 0, z), 0.04, 0.013)) if i % 2 == 0 else (lambda p, z=z: cap(p, v3(0, 0, z - 0.04), v3(0, 0, z + 0.04), 0.013)), "iron")
    if state == "skeleton":
        k.add(lambda p: cap(p, v3(0, 0, 0.95), v3(0.02, 0, 1.5), 0.02), "bone")
        _ribs(k, (0, 0, 1.18), 0.12, 4, 0.075)
        _skull(k, (0.03, -0.04, 1.52), 0.085, 0.3, -0.3)
        k.add(_bone((0.1, -0.2, 0.95), (0.16, -0.27, 0.55), 0.018), "bone_d")
        k.add(lambda p: sub(ell(p, v3(0, 0, 0.9), (0.13, 0.08, 0.06)), sphere(p, v3(0, -0.05, 0.9), 0.045)), "bone")
    return {"foot": 0.6, "shadow": 0.3}


# ── 부서진 무기 · 갑옷 · 잔해 ─────────────────────────────────────────────────

def _blade(a, b, w=0.03, t=0.008):
    """바닥에 누운 칼날(a → b), 폭 w."""
    a, b = np.asarray(a, F), np.asarray(b, F)
    ang = np.arctan2(b[1] - a[1], b[0] - a[0])
    ln = float(np.hypot(b[0] - a[0], b[1] - a[1]))
    mid = (a + b) / 2
    return lambda p: box(rot_z(p, ang, mid), mid, (ln / 2, w, t), 0.004)


@prop("broken_weapon", "trace", cell=(3, 3), tags=["battle", "iron"], name_ko="부서진 무기",
    variants={"sword": {}, "spear": {"state": "spear"}, "shield": {"state": "shield"}, "helmet": {"state": "helmet"}, "mace": {"state": "mace"}, "arrows": {"state": "arrows"}, "pile": {"state": "pile"}, "axe": {"state": "axe"}})
def broken_weapon(k, state="sword", seed=1):
    if state == "sword":   # 두 동강 난 칼
        k.add(_blade((-0.42, -0.05, 0.014), (-0.02, 0.06, 0.014), 0.034), "steel")
        k.add(lambda p: np.minimum(box(rot_z(p, 0.27, (-0.44, -0.055, 0)), v3(-0.44, -0.055, 0.02), (0.022, 0.1, 0.018), 0.006), cap(p, v3(-0.46, -0.06, 0.02), v3(-0.62, -0.105, 0.02), 0.02)), "brass")
        k.add(lambda p: sphere(p, v3(-0.65, -0.112, 0.022), 0.03), "brass")
        k.add(lambda p: np.maximum(_blade((0.12, -0.2, 0.012), (0.48, -0.12, 0.012), 0.032)(p), (p[:, 0] - 0.4) * 0.7 + np.abs(p[:, 1] + 0.14) - 0.03), "rust")
    elif state == "spear":
        k.add(rough(lambda p: cap(p, v3(-0.65, 0.1, 0.02), v3(-0.02, -0.02, 0.02), 0.019), 0.008, 0.1, seed), "wood")
        k.add(rough(lambda p: cap(p, v3(0.1, -0.16, 0.02), v3(0.5, -0.04, 0.02), 0.019), 0.008, 0.1, seed), "wood")
        k.add(lambda p: np.maximum(_blade((0.48, -0.046, 0.02), (0.74, 0.03, 0.02), 0.05)(p), (p[:, 0] - 0.5) * 0.28 + np.abs(rot_z(p, 0.29, (0.5, -0.04, 0))[:, 1] + 0.04) - 0.055), "steel")
        k.add(lambda p: np.minimum(cap(p, v3(-0.02, -0.02, 0.02), v3(0.03, -0.05, 0.035), 0.013, 0.004), cap(p, v3(0.1, -0.16, 0.02), v3(0.06, -0.12, 0.04), 0.013, 0.004)), "wood_l")
    elif state == "shield":   # 쪼개진 둥근 방패
        disc = lambda p: np.maximum(sphere(p, v3(0, 0, -0.5), 0.6), -p[:, 2])
        gap = lambda p: np.abs(p[:, 0] - p[:, 1] * 0.35 + (sdf.noise(p, 0.07, seed) - 0.5) * 0.05) - 0.022
        k.add(rough(lambda p: np.maximum(disc(p), -gap(p)), 0.012, 0.08, seed), "plank_y")
        k.add(lambda p: np.maximum(np.maximum(np.abs(np.hypot(p[:, 0], p[:, 1]) - 0.31) - 0.025, np.abs(p[:, 2] - 0.04) - 0.03), -gap(p) + 0.01), "rust")
        k.add(lambda p: np.maximum(sphere(p, v3(0.03, 0, 0.07), 0.075), -gap(p)), "iron")
        k.add(lambda p: np.minimum(cap(p, v3(0.42, -0.15, 0.012), v3(0.52, -0.12, 0.012), 0.014), cap(p, v3(-0.4, 0.2, 0.012), v3(-0.46, 0.14, 0.012), 0.012)), "wood_l")
    elif state == "helmet":   # 찌그러진 투구
        dome = lambda p: sub(smin(sphere(p, v3(0, 0, 0.11), 0.13), cap(p, v3(0, -0.14, 0.19), v3(0, 0.1, 0.24), 0.012), 0.02), np.minimum(sphere(p, v3(0.11, -0.08, 0.2), 0.07), box(p, v3(0, -0.14, 0.07), (0.07, 0.05, 0.05))))
        k.add(rough(lambda p: np.maximum(dome(rot_y(p, 0.4, (0, 0, 0.1))), -p[:, 2]), 0.012, 0.08, seed), "steel")
        k.add(lambda p: box(rot_y(p, 0.4, (0, 0, 0.1)), v3(0, -0.1, 0.08), (0.06, 0.03, 0.04)), "void")
        k.add(lambda p: cap(p, v3(0.18, -0.08, 0.012), v3(0.26, -0.03, 0.012), 0.015), "leather_d")
    elif state == "mace":
        k.add(rough(lambda p: cap(p, v3(-0.42, 0.06, 0.022), v3(0.04, -0.03, 0.022), 0.02), 0.01, 0.1, seed), "wood_d")
        k.add(lambda p: cap(p, v3(0.04, -0.03, 0.022), v3(0.2, -0.1, 0.05), 0.02), "wood_d")   # 꺾였다
        hd = v3(0.27, -0.13, 0.075)
        k.add(lambda p: np.minimum.reduce([sphere(p, hd, 0.075)] + [cone(rot_y(rot_z(p, a, hd), 1.57, hd), hd + v3(0, 0, 0.05), 0.03, 0.07) for a in (0.0, 1.57, 3.14, 4.71)] + [cone(p, hd + v3(0, 0, 0.05), 0.03, 0.07)]), "rust")
    elif state == "arrows":   # 바닥에 박힌 화살
        for (x, y, lx, ly) in ((-0.2, 0.0, -0.14, 0.1), (0.1, -0.1, 0.1, 0.05), (0.3, 0.12, -0.05, 0.16), (-0.05, 0.2, 0.2, 0.1)):
            top = v3(x + lx, y + ly, 0.42)
            k.add(lambda p, x=x, y=y, top=top: cap(p, v3(x, y, 0), top, 0.01), "wood_l")
            k.add(lambda p, x=x, y=y, top=top: np.maximum(cap(p, v3(x, y, 0) + (top - v3(x, y, 0)) * 0.74, top, 0.035), np.abs(p[:, 1] - (y + (top[1] - y) * 0.87) - (p[:, 2] - 0.36) * 0.2) - 0.006), "linen")
        k.add(lambda p: cap(p, v3(0.42, -0.2, 0.011), v3(0.72, -0.12, 0.011), 0.01), "wood_l")
    elif state == "axe":
        k.add(rough(lambda p: cap(p, v3(-0.4, 0.08, 0.022), v3(0.26, -0.08, 0.022), 0.02), 0.01, 0.1, seed), "wood")
        hd = v3(0.24, -0.075, 0.022)
        k.add(lambda p: np.maximum(pool(p, hd + v3(0.02, -0.07, 0.014), 0.1, 0.1, 0.012), p[:, 1] - hd[1] + 0.01 + np.abs(p[:, 0] - hd[0] - 0.02) * -0.35), "steel")
        k.add(lambda p: box(p, hd, (0.045, 0.035, 0.03), 0.01), "rust")
    else:   # pile: 녹슨 무기 더미
        r = k.rng
        for i in range(7):
            x, y, a, ln = r.uniform(-0.25, 0.25), r.uniform(-0.12, 0.12), r.uniform(-0.6, 0.6) + (i % 2) * 2.2, r.uniform(0.5, 0.8)
            z = 0.02 + i * 0.016
            e0, e1 = (x - np.cos(a) * ln / 2, y - np.sin(a) * ln / 2, z), (x + np.cos(a) * ln / 2, y + np.sin(a) * ln / 2, z + r.uniform(0, 0.08))
            if i % 3 == 2:
                k.add(lambda p, e0=e0, e1=e1: cap(p, v3(*e0), v3(*e1), 0.017), "wood_d")
            else:
                k.add(_blade(e0, e1, 0.03, 0.01), "rust" if i % 2 else "iron")
                k.add(lambda p, e0=e0, a=a: box(rot_z(p, a, e0), v3(*e0) + v3(0.1 * np.cos(a), 0.1 * np.sin(a), 0.005), (0.018, 0.085, 0.016), 0.005), "bronze")
        k.add(rough(lambda p: np.maximum(sphere(p, v3(0.28, 0.16, -0.22), 0.36), -p[:, 2]), 0.015, 0.08, seed), "rust")
    return {}


@prop("broken_armor", "trace", cell=(3, 2), tags=["battle", "iron"], name_ko="부서진 갑옷", variants={"breastplate": {}, "pieces": {"state": "pieces"}, "mail": {"state": "mail"}})
def broken_armor(k, state="breastplate", seed=1):
    plate = lambda p, c: sub(smin(ell(p, c + v3(0, 0, 0.0), (0.24, 0.3, 0.12)), cap(p, c + v3(0, -0.26, 0.09), c + v3(0, 0.22, 0.11), 0.03), 0.04), ell(p, c + v3(0, 0, -0.02), (0.21, 0.27, 0.1)))
    if state == "breastplate":   # 구멍 뚫린 흉갑
        c = v3(0, 0, 0)
        k.add(rough(lambda p: np.maximum(sub(plate(p, c), np.minimum.reduce([sphere(p, v3(0.09, -0.04, 0.12), 0.055) + (sdf.noise(p, 0.03, seed) - 0.5) * 0.04, sphere(p, v3(0, 0.34, 0.05), 0.13), sphere(p, v3(-0.27, 0.12, 0.05), 0.1), sphere(p, v3(0.27, 0.12, 0.05), 0.1)])), -p[:, 2]), 0.012, 0.08, seed), "steel")
        k.add(lambda p: pool(p, v3(0.08, -0.03, 0.012), 0.1, 0.1), "void")
        k.add(lambda p: np.minimum(cap(p, v3(-0.2, -0.1, 0.012), v3(-0.34, -0.16, 0.012), 0.018), cap(p, v3(0.2, 0.05, 0.012), v3(0.36, 0.1, 0.012), 0.018)), "leather_d")
    elif state == "pieces":
        k.add(rough(lambda p: np.maximum(plate(p, v3(-0.3, 0.03, -0.04)), -p[:, 2]), 0.012, 0.08, seed), "rust")
        k.add(lambda p: np.maximum(sub(cap(p, v3(0.1, -0.1, 0.0), v3(0.36, -0.02, 0.0), 0.075), cap(p, v3(0.08, -0.1, -0.01), v3(0.38, -0.02, -0.01), 0.058)), -p[:, 2]), "steel")
        k.add(lambda p: np.maximum(sub(sphere(p, v3(0.22, 0.2, 0.0), 0.11), sphere(p, v3(0.22, 0.2, -0.02), 0.095)), -p[:, 2]), "steel")
        k.add(lambda p: np.minimum(box(rot_z(p, 0.5, (0.55, 0.1, 0)), v3(0.55, 0.1, 0.012), (0.08, 0.05, 0.012), 0.005), cap(p, v3(-0.05, -0.2, 0.012), v3(0.1, -0.26, 0.012), 0.016)), "leather_d")
    else:   # mail: 구겨진 사슬 갑옷
        k.mat("mail", lambda p, n: (np.tile(np.array([0.28, 0.29, 0.31], F), (len(p), 1)) * (0.6 + 0.6 * (np.sin(p[:, 0] * 90.0) * np.sin((p[:, 1] + p[:, 2]) * 90.0) > 0))[:, None] * (0.8 + sdf.fbm(p, 0.1, seed, 2)[:, None] * 0.4), np.zeros(len(p), F), np.zeros(len(p), F)))
        k.add(rough(lambda p: np.maximum(smin(ell(p, v3(0, 0, 0.03), (0.32, 0.22, 0.09)), ell(p, v3(0.3, -0.1, 0.0), (0.2, 0.09, 0.06)), 0.08) + np.sin(p[:, 0] * 19.0 + p[:, 1] * 11.0) * 0.012, -p[:, 2]), 0.03, 0.1, seed), "mail")
    return {}


@prop("debris_wood", "trace", cell=(3, 3), tags=["battle", "wood"], name_ko="나무 잔해", variants={"planks": {"seed": 2}, "splinters": {"state": "splinters", "seed": 4}, "furniture": {"state": "furniture"}})
def debris_wood(k, state="planks", seed=1):
    r = k.rng

    def plank(c, ln, w, a, tilt=0.0, mat="plank_x", jag=True):
        c = np.asarray(c, F)

        def fn(p):
            q = rot_y(rot_z(p, a, c), tilt, c)
            d = box(q, c, (ln / 2, w / 2, 0.016), 0.004)
            return np.maximum(d, np.abs(q[:, 0] - c[0]) - ln / 2 + 0.05 + (sdf.noise(q * np.array([0.3, 1, 1], F), 0.022, seed) - 0.5) * 0.14) if jag else d
        k.add(fn, mat)
    if state == "planks":
        for i in range(6):
            plank((r.uniform(-0.3, 0.3), r.uniform(-0.2, 0.2), 0.02 + i * 0.022), r.uniform(0.4, 0.8), r.uniform(0.07, 0.11), r.uniform(-0.7, 0.7), r.uniform(-0.12, 0.12), ("plank_x", "plank_xd", "wood_l")[i % 3])
    elif state == "splinters":
        for i in range(11):
            plank((r.uniform(-0.45, 0.45), r.uniform(-0.28, 0.28), 0.014), r.uniform(0.1, 0.34), r.uniform(0.02, 0.05), r.uniform(0, 3.14), 0.0, ("plank_x", "wood_l", "plank_xd")[i % 3])
    else:   # furniture: 부서진 가구 — 다리 달린 판 + 흩어진 다리
        plank((0.0, 0.05, 0.16), 0.8, 0.5, 0.15, 0.32, "plank_x")
        plank((-0.25, -0.2, 0.02), 0.5, 0.09, -0.5, 0, "plank_xd")
        for a, b in (((0.3, -0.02, 0.0), (0.36, -0.06, 0.34)), ((-0.5, -0.3, 0.03), (-0.12, -0.4, 0.03)), ((0.42, -0.34, 0.03), (0.7, -0.2, 0.03)), ((0.2, 0.3, 0.0), (0.3, 0.3, 0.3))):
            k.add(lambda p, a=a, b=b: cap(p, v3(*a), v3(*b), 0.03, 0.024), "wood_d")
        for i in range(4):
            plank((r.uniform(-0.6, 0.6), r.uniform(-0.45, -0.2), 0.012), r.uniform(0.1, 0.2), 0.03, r.uniform(0, 3.14), 0, "wood_l")
    return {}


@prop("bottle_broken", "trace", cell=(2, 2), tags=["glass"], name_ko="깨진 병", variants={"green": {"seed": 2}, "brown": {"col": "brown", "seed": 5}, "red": {"col": "red", "seed": 9}})
def bottle_broken(k, col="green", seed=1):
    import mats as M
    r = k.rng
    g = k.mat("g", M.plain({"green": "#4a6a54", "brown": "#6a4a2a", "red": "#6a2a2e"}[col], 0.4, 0.08, seed))
    body = lambda p: sub(smin(hcyl(p, v3(-0.16, 0, 0.055), v3(0.04, 0, 0.055), 0.055), cap(p, v3(-0.16, 0, 0.055), v3(-0.3, 0, 0.055), 0.03, 0.022), 0.03), hcyl(p, v3(-0.12, 0, 0.055), v3(0.2, 0, 0.055), 0.042))
    k.add(lambda p: np.maximum(body(p), p[:, 0] - 0.0 - (sdf.noise(p, 0.03, seed) - 0.5) * 0.12), g)
    for i in range(7):
        x, y, a, s = r.uniform(0.02, 0.42), r.uniform(-0.2, 0.2), r.uniform(0, 3.14), r.uniform(0.02, 0.05)
        k.add(lambda p, x=x, y=y, a=a, s=s: np.maximum(box(rot_z(p, a, (x, y, 0)), v3(x, y, 0.006), (s, s * 0.6, 0.006)), rot_z(p, a, (x, y, 0))[:, 0] - x + rot_z(p, a, (x, y, 0))[:, 1] - y - s * 0.3), g)
    k.add(lambda p: pool(p, v3(0.14, 0.0, 0.004), 0.22, 0.14, 0.004) + (sdf.noise(p, 0.08, seed) - 0.5) * 0.1, k.mat("spill", M.plain({"green": "#26281e", "brown": "#2a2016", "red": "#3a1414"}[col], 0.3, 0.1)))
    return {"shadow": 0.3}


@prop("slime_blob", "trace", cell=(2, 2), tags=["slime"], name_ko="검은 점액 덩이", variants={"a": {"seed": 2}, "b": {"seed": 7, "big": True}})
def slime_blob(k, big=False, seed=1):
    import fx
    s = 1.45 if big else 1.0
    mound = lambda p: smin(smin(ell(p, v3(0, 0, 0.0), (0.26 * s, 0.2 * s, 0.17 * s)), ell(p, v3(0.2 * s, -0.08, 0), (0.15 * s, 0.12 * s, 0.09 * s)), 0.1), ell(p, v3(-0.2 * s, 0.05, 0), (0.13 * s, 0.11 * s, 0.07 * s)), 0.1)
    k.add(lambda p: np.maximum(mound(p) + (sdf.fbm(p, 0.12, seed, 2) - 0.5) * 0.05, -p[:, 2]), "slime")
    k.add(lambda p: pool(p, v3(0.02, -0.03, 0.005), 0.42 * s, 0.28 * s, 0.005) + (sdf.noise(p, 0.1, seed) - 0.5) * 0.14, "slime")
    pts = [(-0.06 * s, -0.1, 0.15 * s), (0.2 * s, -0.14, 0.07 * s)]
    return {"shadow": 0.25, "post": [lambda img, vw: fx.sparkle(img, [vw.px(*q) for q in pts], "#8a8a9a", 1.6)]}


@prop("ash_pile", "trace", cell=(2, 2), tags=["fire"], name_ko="잿더미", variants={"ash": {}, "campfire": {"state": "campfire"}, "pyre": {"state": "pyre"}})
def ash_pile(k, state="ash", seed=1):
    k.add(lambda p: pool(p, v3(0, 0, 0.004), 0.36, 0.26, 0.004) + (sdf.noise(p, 0.09, seed) - 0.5) * 0.12, "coal")
    k.add(rough(lambda p: np.maximum(ell(p, v3(0, 0, 0), (0.24, 0.18, 0.08)), -p[:, 2]), 0.04, 0.08, seed), "ash")
    if state in ("campfire", "pyre"):   # 꺼진 모닥불: 둘러놓은 돌 + 타다 남은 장작
        for i in range(8):
            a = i * np.pi / 4 + 0.2
            k.add(rough(lambda p, a=a, i=i: ell(p, v3(np.cos(a) * 0.34, np.sin(a) * 0.26, 0.04), (0.075 + (i % 3) * 0.012, 0.06, 0.05)), 0.03, 0.08, seed + i), "stone_d" if i % 2 else "stone")
        for a, b in (((-0.2, -0.08, 0.05), (0.18, 0.06, 0.1)), ((0.16, -0.1, 0.05), (-0.12, 0.1, 0.12)), ((-0.02, -0.16, 0.05), (0.04, 0.14, 0.09))):
            k.add(rough(lambda p, a=a, b=b: cap(p, v3(*a), v3(*b), 0.034, 0.026), 0.016, 0.06, seed), "coal")
    if state == "pyre":
        _skull(k, (0.02, -0.06, 0.07), 0.075, 0.3, 0.0, "bone_d")
        k.add(_bone((-0.2, -0.16, 0.06), (0.06, -0.2, 0.05), 0.016), "bone_d")
    return {"shadow": 0.3}


@prop("ritual_remains", "trace", cell=(4, 3), tags=["ritual"], name_ko="의식의 흔적", variants={"candle_ring": {}, "bone_circle": {"state": "bone_circle"}, "offering": {"state": "offering"}})
def ritual_remains(k, state="candle_ring", seed=1):
    r = k.rng
    if state == "candle_ring":   # 녹아내린 초 토막이 둥글게
        for i in range(9):
            a = i * 2 * np.pi / 9 + 0.1
            x, y, h = np.cos(a) * 0.72, np.sin(a) * 0.72, r.uniform(0.04, 0.16)
            k.add(lambda p, x=x, y=y, h=h: smin(cyl(p, v3(x, y, 0), 0.03, h, 0.008), pool(p, v3(x, y, 0.006), 0.065, 0.06, 0.006) + (sdf.noise(p, 0.03, seed) - 0.5) * 0.03, 0.03), "wax")
            k.add(lambda p, x=x, y=y, h=h: cap(p, v3(x, y, h), v3(x + 0.005, y, h + 0.02), 0.005), "coal")
        k.add(lambda p: pool(p, v3(0, 0, 0.004), 0.2, 0.2, 0.004) + (sdf.noise(p, 0.07, seed) - 0.5) * 0.1, "coal")
        return {"foot": 1.3, "shadow": 0.3}
    if state == "bone_circle":   # 뼈로 두른 원 + 가운데 머리뼈
        for i in range(10):
            a = i * 2 * np.pi / 10
            a2 = a + 0.5
            k.add(_bone((np.cos(a) * 0.62, np.sin(a) * 0.62, 0.022), (np.cos(a2) * 0.62, np.sin(a2) * 0.62, 0.022), 0.018), "bone" if i % 2 else "bone_d")
        _skull(k, (0, 0, 0), 0.09, 0.0)
        for a in (0.5, 2.6, 4.7):
            k.add(_bone((np.cos(a) * 0.14, np.sin(a) * 0.14, 0.02), (np.cos(a) * 0.5, np.sin(a) * 0.5, 0.02), 0.016), "bone_d")
        return {"foot": 1.2, "shadow": 0.3}
    # offering: 그릇 · 말린 꽃 · 피 묻은 칼 · 동전
    k.add(lambda p: sub(np.maximum(sphere(p, v3(0, 0, 0.12), 0.15), p[:, 2] - 0.11), sphere(p, v3(0, 0, 0.14), 0.13)), "bronze")
    k.add(lambda p: cyl(p, v3(0, 0, 0.06), 0.11, 0.02), "blood")
    k.add(_blade((0.22, -0.16, 0.012), (0.52, -0.06, 0.012), 0.025), "steel")
    k.add(lambda p: cap(p, v3(0.1, -0.2, 0.018), v3(0.22, -0.16, 0.018), 0.018), "leather_d")
    k.add(lambda p: pool(p, v3(0.42, -0.09, 0.02), 0.1, 0.03, 0.006), "blood")
    for i in range(6):
        x, y = r.uniform(-0.5, -0.18), r.uniform(-0.25, 0.2)
        k.add(lambda p, x=x, y=y: cyl(p, v3(x, y, 0), 0.024, 0.008), "gold" if i % 2 else "brass")
    for i in range(5):
        a = r.uniform(0, 6.28)
        k.add(lambda p, a=a, i=i: cap(p, v3(0.1 + i * 0.02, 0.22, 0.01), v3(0.1 + np.cos(a) * 0.16, 0.26 + abs(np.sin(a)) * 0.12, 0.012), 0.008), "leaf_dry")
    return {"cell": (3, 2), "shadow": 0.3}


@prop("web_cocoon", "trace", cell=(2, 4), tags=["web"], name_ko="거미줄 고치", variants={"standing": {}, "hanging": {"state": "hanging"}, "cluster": {"state": "cluster"}})
def web_cocoon(k, state="standing", seed=1):
    import mats as M
    silk = k.mat("silk", M.plain("#a8a498", 0.25, 0.06, seed))
    wrap = lambda p: np.sin((p[:, 2] * 34.0 + p[:, 0] * 22.0) + np.sin(p[:, 1] * 30.0)) * 0.008
    if state == "standing":
        k.add(rough(lambda p: smin(ell(p, v3(0, 0, 0.5), (0.2, 0.17, 0.5)), sphere(p, v3(0.01, -0.02, 0.98), 0.13), 0.08) + wrap(p), 0.02, 0.1, seed), silk)
        for a in (0.4, 2.2, 3.6, 5.2):
            k.add(lambda p, a=a: cap(p, v3(0, 0, 0.3), v3(np.cos(a) * 0.42, np.sin(a) * 0.3, 0.0), 0.012, 0.006), silk)
        return {"cell": (2, 3)}
    if state == "hanging":
        k.add(rough(lambda p: smin(ell(p, v3(0, 0, 1.45), (0.19, 0.16, 0.45)), cap(p, v3(0, 0, 1.8), v3(0, 0, 3.0), 0.05, 0.02), 0.12) + wrap(p), 0.02, 0.1, seed), silk)
        k.add(lambda p: cap(p, v3(0.03, -0.1, 1.05), v3(0.08, -0.12, 0.86), 0.022), "bone_d")
        return {"shadow": 0.25, "foot": 0.5}
    for (x, y, s) in ((-0.2, 0.05, 0.9), (0.18, 0.0, 1.1), (0.0, -0.16, 0.6)):
        k.add(rough(lambda p, x=x, y=y, s=s: ell(p, v3(x, y, 0.17 * s), (0.15 * s, 0.13 * s, 0.2 * s)) + wrap(p) * 0.7, 0.02, 0.1, seed), silk)
    return {"cell": (2, 2)}


@prop("nest", "trace", cell=(3, 2), tags=["beast"], name_ko="뼈와 넝마 둥지", variants={"base": {}, "eggs": {"state": "eggs"}})
def nest(k, state="base", seed=1):
    r = k.rng
    k.add(rough(lambda p: np.maximum(sub(ell(p, v3(0, 0, 0.02), (0.5, 0.36, 0.14)), ell(p, v3(0, 0, 0.16), (0.34, 0.24, 0.13))), -p[:, 2]) + np.sin(p[:, 0] * 40.0 + p[:, 1] * 27.0) * 0.006, 0.05, 0.07, seed), "leaf_dry")
    for i in range(12):
        a = r.uniform(0, 6.28)
        x, y = np.cos(a) * 0.42, np.sin(a) * 0.3
        a2 = a + 1.57 + r.uniform(-0.5, 0.5)
        ln = r.uniform(0.12, 0.22)
        m = ("bone", "wood_d", "bone_d", "cloth")[i % 4]
        k.add(lambda p, x=x, y=y, a2=a2, ln=ln: cap(p, v3(x - np.cos(a2) * ln, y - np.sin(a2) * ln, 0.1), v3(x + np.cos(a2) * ln, y + np.sin(a2) * ln, 0.13), 0.017), m)
    if state == "eggs":
        for (x, y) in ((-0.1, 0.0), (0.08, 0.04), (0.0, -0.08)):
            k.add(lambda p, x=x, y=y: ell(p, v3(x, y, 0.15), (0.07, 0.06, 0.085)), "bone")
    else:
        _skull(k, (0.05, 0.0, 0.07), 0.07, 0.6, 0.0, "bone_d")
    return {}


# ── 평면 자국 도우미 ─────────────────────────────────────────────────────────

def _tone(c, col, lo=0.75, hi=1.2, scale=10.0):
    return hexc(col)[None, None, :] * (lo + c.noise(scale) * (hi - lo))[..., None]


def _dots(c, pts, soft=0.8):
    m = np.zeros((c.H, c.W), F)
    for x, y, r in pts:
        m = np.maximum(m, np.clip((r - np.hypot(c.xx - x, c.yy - y)) / soft + 0.5, 0, 1))
    return m


def _stain(c, mask, col, rim=None, alpha=0.9, gloss=False, rim_w=1.6):
    """얼룩 한 겹: 잡음으로 흔든 색 + 어두운 테(+ 젖은 번들거림)."""
    c.paint(mask, _tone(c, col), alpha)
    if rim:
        c.paint(c.rim(mask, rim_w) * 0.75, rim, alpha)
    if gloss:
        hl = sstep(c.noise(7.0) - 0.62, 0, 0.12) * gblur(mask, 3.0) ** 3
        c.paint(np.roll(hl, (-2, -2), (0, 1)) * mask, "#b08a80", 0.55)


def _blood_pool_mask(c, cx, cy, r, rough=0.35):
    m = c.blob(cx, cy, r, r * c.rng.uniform(0.7, 0.95), rough, r * 0.7, 0.06, c.rng.uniform(0, 3.1))
    for _ in range(3):
        a = c.rng.uniform(0, 6.28)
        m = np.maximum(m, c.blob(cx + np.cos(a) * r * 0.8, cy + np.sin(a) * r * 0.75, r * 0.4, r * 0.3, 0.4, r * 0.3, 0.08, a))
    return m


def _spray(c, cx, cy, ang, spread, n, reach, r0=0.6, r1=2.6):
    """한쪽으로 튄 방울(길쭉한 꼬리가 달린다)."""
    m = np.zeros((c.H, c.W), F)
    for _ in range(n):
        a = ang + c.rng.normal(0, spread)
        d = reach * c.rng.uniform(0.25, 1.0) ** 0.8
        x, y, r = cx + np.cos(a) * d, cy + np.sin(a) * d, c.rng.uniform(r0, r1) * (1.1 - d / reach * 0.6)
        tail = r * c.rng.uniform(1.0, 3.5)
        m = np.maximum(m, c.seg([(x + np.cos(a) * tail, y + np.sin(a) * tail), (x, y)], r * 2.2, True))
        m = np.maximum(m, _dots(c, [(x, y, r)]))
    return m


@flat("blood_splat", "trace", cell=(112, 112), tags=["blood", "battle"], name_ko="핏자국", variants={"a": {"seed": 11}, "b": {"seed": 23, "kind": "spray"}, "c": {"seed": 37}, "d": {"seed": 41, "kind": "spray"}, "drops": {"seed": 5, "kind": "drops"}})
def blood_splat(c, kind="pool", seed=1):
    r = c.rng
    cx, cy = 56 + r.uniform(-6, 6), 56 + r.uniform(-6, 6)
    if kind == "pool":
        m = _blood_pool_mask(c, cx, cy, r.uniform(15, 21))
        m = np.maximum(m, _dots(c, [(cx + np.cos(a) * d, cy + np.sin(a) * d, s) for a, d, s in zip(r.uniform(0, 6.28, 16), r.uniform(20, 46, 16), r.uniform(0.8, 3.0, 16))]))
        m = np.maximum(m, _spray(c, cx, cy, r.uniform(0, 6.28), 0.5, 10, 46))
    elif kind == "spray":
        ang = r.uniform(0, 6.28)
        ox, oy = cx - np.cos(ang) * 28, cy - np.sin(ang) * 28
        m = np.maximum(_blood_pool_mask(c, ox, oy, 9), _spray(c, ox, oy, ang, 0.33, 38, 80, 0.7, 3.2))
    else:
        m = _dots(c, [(r.uniform(20, 92), r.uniform(20, 92), s) for s in r.uniform(1.0, 4.2, 14)])
        m = np.maximum(m, c.blob(cx, cy, 8, 7, 0.4, 5))
    _stain(c, m, BLOOD, BLOOD_D, 0.92, True)
    c.shade(gblur(m, 4.0) ** 2 * m, -0.25)


@flat("blood_pool", "trace", cell=(176, 150), tags=["blood", "death"], name_ko="피 웅덩이", variants={"fresh": {"seed": 3}, "fresh_b": {"seed": 19}, "dried": {"seed": 7, "dried": True}, "dried_b": {"seed": 29, "dried": True}})
def blood_pool(c, dried=False, seed=1):
    r = c.rng
    cx, cy = 88, 75
    m = _blood_pool_mask(c, cx, cy, r.uniform(36, 44), 0.3)
    m = np.maximum(m, c.blob(cx + r.uniform(-30, 30), cy + r.uniform(-20, 20), 26, 18, 0.4, 18, 0.06))
    m = np.maximum(m, _dots(c, [(cx + np.cos(a) * d, cy + np.sin(a) * d * 0.8, s) for a, d, s in zip(r.uniform(0, 6.28, 14), r.uniform(46, 76, 14), r.uniform(1.0, 3.6, 14))]))
    if dried:   # 마른 피: 갈색 · 갈라진 테 · 가운데가 옅다
        _stain(c, m, BLOOD_DRY, "#1e100c", 0.8, False, 2.4)
        inner = gblur(m, 7.0) ** 4
        c.paint(inner * sstep(c.noise(14.0), 0.35, 0.7), "#4a2a1e", 0.55)
        c.paint(c.cracks([(cx + r.uniform(-20, 20), cy + r.uniform(-14, 14), a, r.uniform(14, 30)) for a in r.uniform(0, 6.28, 7)], 1.3) * m, "#160c0a", 0.75)
        c.a *= 0.75 + c.noise(5.0) * 0.25
    else:
        _stain(c, m, BLOOD, BLOOD_D, 0.95, True, 2.0)
        c.shade(gblur(m, 8.0) ** 3 * m, -0.4)
        hl = c.blob(cx - 12, cy - 12, 16, 7, 0.5, 8, 0.4, -0.5) * gblur(m, 6.0) ** 3
        c.paint(hl, "#b88a80", 0.3)


@flat("blood_trail", "trace", cell=(200, 110), tags=["blood", "death"], name_ko="끌린 핏자국", variants={"straight": {"seed": 4}, "curved": {"seed": 9, "kind": "curved"}, "hand": {"seed": 14, "kind": "hand"}, "vertical": {"seed": 21, "kind": "vertical"}})
def blood_trail(c, kind="straight", seed=1):
    r = c.rng
    n = 16
    ts = np.linspace(0, 1, n)
    if kind == "curved":
        pts = [(16 + t * 168, 78 - np.sin(t * 2.6) * 46 + r.uniform(-2, 2)) for t in ts]
    elif kind == "vertical":
        pts = [(100 + np.sin(t * 5.0) * 7 + r.uniform(-2, 2), 6 + t * 98) for t in ts]
    else:
        pts = [(14 + t * 172, 55 + np.sin(t * 7.0) * 5 + r.uniform(-2, 2)) for t in ts]
    m = c.seg(pts, 15, True, 1.5) * sstep(c.noise(9.0, None, 3), 0.25, 0.55)
    for off in (-5.5, 0.5, 5.0):   # 끌린 결
        dx = (pts[-1][1] - pts[0][1]) * 0.0
        streak = c.seg([(x + dx, y + off + r.uniform(-1, 1)) for x, y in pts] if kind != "vertical" else [(x + off, y) for x, y in pts], 2.6, True, 0.8)
        m = np.maximum(m, streak * sstep(c.noise(16.0), 0.3, 0.5))
    m = np.maximum(m, _blood_pool_mask(c, pts[0][0] + 6, pts[0][1], 11))
    if kind == "hand":   # 끝에 짚은 손자국
        hx, hy = pts[-1][0] - 12, pts[-1][1] - 2
        m = np.maximum(m, c.blob(hx, hy, 7.5, 6.5, 0.2, 5))
        for i, a in enumerate((-0.75, -0.3, 0.05, 0.4, 1.1)):
            ln = (9, 12, 13, 11, 7)[i]
            m = np.maximum(m, c.seg([(hx + np.cos(a) * 6, hy + np.sin(a) * 6), (hx + np.cos(a) * (6 + ln), hy + np.sin(a) * (6 + ln))], 3.4, False))
    _stain(c, m, BLOOD, BLOOD_D, 0.85, False, 1.3)
    c.a *= 0.7 + c.noise(4.0) * 0.3


def _foot(c, x, y, ang, left, ln=21.0):
    """신발 자국: 앞꿈치 + 잘록한 허리 + 뒤꿈치."""
    ca, sa = np.cos(ang), np.sin(ang)
    m = c.blob(x + ca * ln * 0.2, y + sa * ln * 0.2, ln * 0.33, ln * 0.2, 0.12, 5, 0.15, ang)
    m = np.maximum(m, c.seg([(x + ca * ln * 0.1, y + sa * ln * 0.1), (x - ca * ln * 0.3, y - sa * ln * 0.3)], ln * 0.2, False, 0.8))
    return np.maximum(m, c.blob(x - ca * ln * 0.36, y - sa * ln * 0.36, ln * 0.17, ln * 0.16, 0.12, 4, 0.15, ang))


@flat("footprints", "trace", cell=(200, 90), tags=["blood"], name_ko="발자국", variants={"bloody": {"seed": 6, "n": 5}, "bloody_fade": {"seed": 12, "fade": True}, "dust": {"seed": 18, "col": "dust"}, "wet": {"seed": 25, "col": "wet"}})
def footprints(c, col="blood", fade=False, n=6, seed=1):
    r = c.rng
    m = np.zeros((c.H, c.W), F)
    for i in range(n):
        t = i / (n - 1.0)
        x, y = 20 + t * 160, 45 + (11 if i % 2 else -11) + r.uniform(-2, 2)
        k = (1.0 - t * 0.85) if (fade or col != "blood") else 1.0 - t * 0.3
        m = np.maximum(m, _foot(c, x, y, r.uniform(-0.15, 0.15) + (0.12 if i % 2 else -0.12), i % 2 == 0) * k * (0.7 + c.noise(5.0) * 0.3))
    cc, rim, al = {"blood": (BLOOD, BLOOD_D, 0.9), "dust": ("#8a8272", None, 0.6), "wet": ("#12161a", None, 0.75)}[col]
    _stain(c, m, cc, rim, al, False, 1.0)


@flat("rot_stain", "trace", cell=(170, 120), tags=["death"], name_ko="썩은 자국", variants={"a": {"seed": 2}, "b": {"seed": 15}, "c": {"seed": 33}})
def rot_stain(c, seed=1):
    r = c.rng
    cx, cy = 85, 60
    # 누웠던 몸의 윤곽: 머리 · 몸통 · 팔다리
    body = np.maximum.reduce([c.blob(cx - 44, cy + r.uniform(-4, 4), 11, 10, 0.2, 6), c.blob(cx - 12, cy, 26, 15, 0.25, 12), c.seg([(cx + 8, cy - 5), (cx + 38, cy - 12 + r.uniform(-5, 5)), (cx + 62, cy - 8)], 11, True),
        c.seg([(cx + 8, cy + 6), (cx + 36, cy + 14 + r.uniform(-5, 5)), (cx + 60, cy + 22)], 11, True), c.seg([(cx - 26, cy - 10), (cx - 22, cy - 32), (cx - 4, cy - 40 + r.uniform(-4, 4))], 7, True),
        c.seg([(cx - 26, cy + 10), (cx - 34, cy + 30), (cx - 50, cy + 36 + r.uniform(-4, 4))], 7, True)])
    seep = np.clip(gblur(body, 9.0) * 1.7 + (c.noise(18.0) - 0.5) * 0.7, 0, 1)
    seep = sstep(seep, 0.3, 0.55)
    _stain(c, seep, "#2e2a1c", "#16130e", 0.6, False, 2.5)
    c.paint(body * sstep(c.noise(8.0), 0.2, 0.6), _tone(c, "#1a1612"), 0.8)
    c.paint(sstep(c.noise(5.0) - 0.6, 0, 0.1) * seep, "#4a4a2a", 0.4)
    c.paint(_dots(c, [(cx + r.uniform(-60, 60), cy + r.uniform(-40, 40), s) for s in r.uniform(0.8, 2.4, 14)]) * (1 - body), "#1a1612", 0.6)


@flat("scratches", "trace", cell=(110, 110), tags=["beast", "battle"], name_ko="긁힌 자국", variants={"a": {"seed": 3}, "b": {"seed": 8, "n": 4}, "c": {"seed": 17, "n": 3, "curve": 0.8}, "deep": {"seed": 31, "n": 3, "wide": 3.6}})
def scratches(c, n=3, curve=0.3, wide=2.6, seed=1):
    r = c.rng
    ang = r.uniform(0.5, 1.2) * r.choice([-1, 1]) + 1.57
    ca, sa = np.cos(ang), np.sin(ang)
    m = np.zeros((c.H, c.W), F)
    lip = np.zeros((c.H, c.W), F)
    for i in range(n):
        off = (i - (n - 1) / 2) * r.uniform(9, 12)
        ln = r.uniform(52, 76)
        bend = curve * r.uniform(0.6, 1.2) * 16
        pts = []
        for t in np.linspace(-0.5, 0.5, 9):
            x = 55 + ca * t * ln - sa * (off + np.sin((t + 0.5) * 3.1) * bend) + r.uniform(-0.6, 0.6)
            y = 55 + sa * t * ln + ca * (off + np.sin((t + 0.5) * 3.1) * bend) + r.uniform(-0.6, 0.6)
            pts.append((x, y))
        m = np.maximum(m, np.maximum(c.seg(pts[4:], wide, True, 0.6), c.seg(pts[4::-1], wide, True, 0.6)))
        lip = np.maximum(lip, c.seg([(x - 1.2, y - 1.2) for x, y in pts[1:-1]], wide * 0.8, False, 0.6))
    c.paint(lip * (1 - m), "#8a8478", 0.45)      # 밝은 돋은 가장자리
    c.paint(m, _tone(c, "#120e0c", 0.8, 1.2, 4.0), 0.92)
    c.paint(_dots(c, [(55 + r.uniform(-40, 40), 55 + r.uniform(-40, 40), s) for s in r.uniform(0.6, 1.6, 9)]), "#6a655c", 0.6)


@flat("drag_marks", "trace", cell=(200, 96), tags=["dust"], name_ko="끌린 자국", variants={"a": {"seed": 5}, "b": {"seed": 13, "n": 2}, "curved": {"seed": 22, "bend": 30.0}})
def drag_marks(c, n=4, bend=6.0, seed=1):
    r = c.rng
    m = np.zeros((c.H, c.W), F)
    lip = np.zeros((c.H, c.W), F)
    for i in range(n):
        off = (i - (n - 1) / 2) * r.uniform(8, 13) + r.uniform(-2, 2)
        x0, x1 = 12 + r.uniform(0, 26), 188 - r.uniform(0, 30)
        pts = [(x, 48 + off + np.sin((x - x0) / (x1 - x0) * 3.14) * bend + r.uniform(-0.8, 0.8)) for x in np.linspace(x0, x1, 14)]
        w = r.uniform(2.0, 4.5)
        m = np.maximum(m, c.seg(pts, w, False, 0.8) * sstep(c.noise(20.0), 0.22, 0.45))
        lip = np.maximum(lip, c.seg([(x, y - 1.6) for x, y in pts], w, False, 1.0))
    c.paint(gblur(m, 3.0) * 1.5, "#3a352e", 0.35)
    c.paint(lip * (1 - m), "#7c766a", 0.35)
    c.paint(m, _tone(c, "#16120f", 0.8, 1.2, 5.0), 0.8)
    c.paint(_dots(c, [(r.uniform(150, 195), 48 + r.uniform(-24, 24), s) for s in r.uniform(0.8, 2.2, 10)]), "#5a554c", 0.7)


@flat("dust", "trace", cell=(160, 130), tags=["dust"], name_ko="먼지", variants={"a": {"seed": 4}, "b": {"seed": 10}, "c": {"seed": 27}, "drift": {"seed": 35, "drift": True}})
def dust(c, drift=False, seed=1):
    r = c.rng
    m = c.blob(80, 65, 62, 46, 0.5, 40, 0.5, r.uniform(-0.4, 0.4))
    if drift:   # 벽 밑에 쌓인 먼지 더미(위쪽이 벽)
        m = sstep(1.0 - c.yy / 130.0 * 1.5 + (c.noise(30.0) - 0.5) * 0.7, 0.1, 0.7) * sstep(1.0 - np.abs(c.xx - 80) / 80.0 + (c.noise(20.0) - 0.5) * 0.4, 0.05, 0.4)
    c.paint(m * (0.45 + c.noise(26.0) * 0.55), hexc("#8a8272")[None, None, :] * (0.85 + c.noise(9.0) * 0.3)[..., None], 0.4)
    c.paint(m * sstep(c.noise(14.0) - 0.5, 0, 0.3), "#a69e8a", 0.22)   # 두껍게 쌓인 곳
    for _ in range(3 if not drift else 1):   # 먼지를 쓸고 간 자리
        x, y, a = 80 + r.uniform(-30, 30), 65 + r.uniform(-20, 20), r.uniform(0, 3.14)
        sw = c.seg([(x - np.cos(a) * 22, y - np.sin(a) * 22), (x + np.cos(a) * 22, y + np.sin(a) * 22)], r.uniform(4, 8), True, 2.0)
        c.a *= 1 - sw * 0.7


def _web(c, ax, ay, a0, a1, reach, nsp=6, nring=5):
    """모서리(ax, ay)에서 a0~a1 부채꼴로 뻗는 거미줄."""
    r = c.rng
    m = np.zeros((c.H, c.W), F)
    angs = np.linspace(a0, a1, nsp) + r.uniform(-0.04, 0.04, nsp)
    lens = reach * r.uniform(0.7, 1.0, nsp)
    for a, ln in zip(angs, lens):
        m = np.maximum(m, c.seg([(ax, ay), (ax + np.cos(a) * ln, ay + np.sin(a) * ln)], 1.1, False, 0.5))
    for j in range(1, nring + 1):
        t = j / (nring + 0.6)
        for i in range(nsp - 1):
            p0 = (ax + np.cos(angs[i]) * lens[i] * t, ay + np.sin(angs[i]) * lens[i] * t)
            p1 = (ax + np.cos(angs[i + 1]) * lens[i + 1] * t, ay + np.sin(angs[i + 1]) * lens[i + 1] * t)
            mid = ((p0[0] + p1[0]) / 2 - (p0[0] + p1[0] - 2 * ax) * 0.045, (p0[1] + p1[1]) / 2 - (p0[1] + p1[1] - 2 * ay) * 0.045)   # 안쪽으로 처진다
            if r.random() > 0.12:
                m = np.maximum(m, c.seg([p0, mid, p1], 0.9, False, 0.5))
    return m


@flat("cobweb", "trace", layer="wall_decal", cell=(96, 96), tags=["web", "dust"], name_ko="거미줄", meta={"mount": "face", "corner": True},
    variants={"corner_l": {"seed": 3}, "corner_r": {"seed": 9, "side": "r"}, "torn": {"seed": 14, "torn": True}, "span": {"seed": 21, "side": "span"}, "floor": {"seed": 30, "side": "floor"}})
def cobweb(c, side="l", torn=False, seed=1):
    r = c.rng
    if side == "l":
        m = _web(c, 2, 2, 0.04, 1.53, 88)
        c.origin = (0, 0)
    elif side == "r":
        m = _web(c, 94, 2, 1.61, 3.1, 88)
        c.origin = (96, 0)
    elif side == "span":
        m = _web(c, 48, 2, 0.25, 2.9, 80, 8, 5)
        c.origin = (48, 0)
    else:   # floor: 바닥 구석에 깔린 거미줄 뭉치
        m = np.maximum(_web(c, 48, 48, 0, 6.2, 44, 11, 5), 0)
    if torn:
        m = m * sstep(c.noise(20.0), 0.38, 0.5)
        m = np.maximum(m, c.seg([(40, 30), (44, 60), (41, 86)], 1.2, True) * 0.9)
    veil = gblur(m, 2.5) * 0.9
    c.paint(veil, "#8a887c", 0.32)
    c.paint(m, _tone(c, "#c8c4b4", 0.8, 1.1, 6.0), 0.8)
    c.paint(_dots(c, [(r.uniform(10, 86), r.uniform(10, 86), s) for s in r.uniform(0.7, 1.4, 5)]) * (veil > 0.1), "#3a362e", 0.7)
    c.graded = False


@flat("water_stain", "trace", cell=(128, 128), tags=["water"], name_ko="물 얼룩", variants={"a": {"seed": 6}, "b": {"seed": 16}, "c": {"seed": 28}})
def water_stain(c, seed=1):
    r = c.rng
    cx, cy = 64 + r.uniform(-6, 6), 64 + r.uniform(-6, 6)
    for i, rad in enumerate((50, 38, 24)):   # 말라 가며 남긴 겹겹의 테
        m = c.blob(cx + r.uniform(-4, 4), cy + r.uniform(-4, 4), rad, rad * r.uniform(0.75, 0.95), 0.3, 26, 0.1, r.uniform(0, 3))
        c.paint(m * (0.6 + c.noise(14.0) * 0.4), "#10151a", 0.14 + i * 0.07)
        c.paint(c.rim(m, 1.8) * sstep(c.noise(12.0), 0.25, 0.6), "#948e7e" if i == 0 else "#0c0e10", 0.28 if i == 0 else 0.3)
    c.paint(c.blob(cx, cy, 13, 11, 0.4, 8) * 0.9, "#0c1014", 0.5)


@flat("wall_stain", "trace", layer="wall_decal", cell=(72, 160), tags=["water"], name_ko="벽 물자국", variants={"a": {"seed": 5}, "b": {"seed": 12}, "c": {"seed": 24, "rust": True}})
def wall_stain(c, rust=False, seed=1):
    r = c.rng
    c.origin = (36, 160)
    m = np.zeros((c.H, c.W), F)
    for _ in range(int(r.integers(3, 6))):
        x = 36 + r.uniform(-20, 20)
        ln = r.uniform(70, 150)
        pts = [(x + np.sin(t * 0.07) * 2 + r.uniform(-0.8, 0.8), t) for t in np.linspace(4, 4 + ln, 9)]
        m = np.maximum(m, c.seg(pts, r.uniform(5, 13), True, 3.0))
    m = m * (0.55 + c.noise(9.0) * 0.45)
    top = c.blob(36, 6, 28, 10, 0.4, 12, 0.3)
    m = np.maximum(m, top * 0.8)
    col = "#4a2e1c" if rust else "#14181a"
    c.paint(m, _tone(c, col, 0.7, 1.2, 6.0), 0.72)
    c.paint(c.rim(m, 1.5) * 0.6, "#8a8474" if not rust else "#2a1810", 0.25)
    if not rust:
        c.paint(m * sstep(c.noise(4.0) - 0.62, 0, 0.1), "#3a4a34", 0.35)   # 물길 따라 낀 물때


@flat("black_slime", "trace", cell=(150, 130), tags=["slime"], name_ko="검은 점액", variants={"a": {"seed": 7}, "b": {"seed": 15}, "c": {"seed": 32}, "trail": {"seed": 40, "trail": True}})
def black_slime(c, trail=False, seed=1):
    r = c.rng
    cx, cy = 75, 65
    if trail:
        pts = [(14 + t * 122, cy + np.sin(t * 4.0 + 1) * 22) for t in np.linspace(0, 1, 12)]
        m = c.seg(pts, 20, False, 2.0)
        m = sstep(gblur(m, 3.0) + (c.noise(12.0) - 0.5) * 0.5, 0.35, 0.5)
    else:
        m = _blood_pool_mask(c, cx, cy, r.uniform(26, 33), 0.4)
        for _ in range(4):   # 흘러나간 줄기
            a = r.uniform(0, 6.28)
            ln = r.uniform(30, 52)
            m = np.maximum(m, c.seg([(cx, cy), (cx + np.cos(a) * ln * 0.6 + r.uniform(-5, 5), cy + np.sin(a) * ln * 0.6 + r.uniform(-5, 5)), (cx + np.cos(a) * ln, cy + np.sin(a) * ln)], r.uniform(7, 12), True, 1.2))
            m = np.maximum(m, c.blob(cx + np.cos(a) * ln, cy + np.sin(a) * ln, 5, 4.5, 0.2, 3))
    c.paint(gblur(m, 2.5) * 1.3 * (1 - m), "#0a080c", 0.35)
    c.paint(m, _tone(c, "#131118", 0.7, 1.3, 9.0), 0.97)
    inner = gblur(m, 4.0) ** 2 * m
    c.paint(inner * sstep(c.noise(11.0), 0.5, 0.75), "#2a2434", 0.6)      # 보랏빛 도는 두꺼운 곳
    c.paint(c.rim(m, 1.3), "#050406", 0.8)
    hl = gblur(sstep(c.noise(9.0, None, 2) - 0.68, 0, 0.06) * inner, 1.2)
    c.paint(np.roll(hl, (-3, -3), (0, 1)) * m, "#9090a4", 0.55)            # 번들거림
    for _ in range(5):
        x, y = cx + r.uniform(-28, 28), cy + r.uniform(-22, 22)
        c.paint(c.ring(x, y, r.uniform(2.0, 3.6), 1.0) * m, "#3a3648", 0.8)   # 기포
    c.graded = False


@flat("wall_slime", "trace", layer="wall_decal", cell=(84, 160), tags=["slime"], name_ko="벽을 타고 흐르는 점액", variants={"a": {"seed": 4}, "b": {"seed": 19}})
def wall_slime(c, seed=1):
    r = c.rng
    c.origin = (42, 160)
    y0 = r.uniform(20, 50)
    m = c.blob(42, y0, 24, 12, 0.4, 12, 0.1)
    for _ in range(int(r.integers(4, 7))):
        x = 42 + r.uniform(-20, 20)
        ln = r.uniform(40, 108)
        pts = [(x + r.uniform(-1, 1), y0 + t) for t in np.linspace(0, ln, 7)]
        m = np.maximum(m, c.seg(pts, r.uniform(4, 8), True, 1.0))
        m = np.maximum(m, c.blob(pts[-1][0], pts[-1][1], 3.4, 4.6, 0.1, 3))
    c.paint(m, _tone(c, "#131118", 0.7, 1.3, 7.0), 0.97)
    c.paint(c.rim(m, 1.2), "#050406", 0.8)
    c.paint(np.roll(m, (0, -3), (0, 1)) * m * sstep(c.noise(7.0, None, 2) - 0.62, 0, 0.08) * (gblur(m, 2.0) ** 2), "#8a8a9c", 0.5)
    c.graded = False


@flat("scorch", "trace", cell=(140, 140), tags=["fire", "battle"], name_ko="그을음", variants={"a": {"seed": 5}, "b": {"seed": 14}, "blast": {"seed": 26, "blast": True}})
def scorch(c, blast=False, seed=1):
    r = c.rng
    cx, cy = 70, 70
    m = c.blob(cx, cy, 44, 40, 0.5, 26, 0.6)
    if blast:   # 터진 자리: 바깥으로 뻗은 그을음 줄
        for a in np.linspace(0, 6.28, 15)[:-1]:
            a += r.uniform(-0.15, 0.15)
            ln = r.uniform(40, 66)
            m = np.maximum(m, c.seg([(cx + np.cos(a) * 14, cy + np.sin(a) * 14), (cx + np.cos(a) * ln, cy + np.sin(a) * ln)], r.uniform(5, 11), True, 2.5) * 0.85)
    m = m * (0.6 + c.noise(8.0) * 0.4)
    c.paint(m, _tone(c, "#0e0c0b", 0.8, 1.2, 5.0), 0.82)
    core = c.blob(cx, cy, 18, 16, 0.5, 10, 0.4)
    c.paint(core * sstep(c.noise(4.0), 0.35, 0.7), "#6a665e", 0.5)   # 재
    c.paint(_dots(c, [(cx + r.uniform(-50, 50), cy + r.uniform(-50, 50), s) for s in r.uniform(0.7, 2.0, 16)]), "#0e0c0b", 0.7)


@flat("bottle_shards", "trace", cell=(72, 72), tags=["glass"], name_ko="유리 조각", variants={"green": {"seed": 3}, "brown": {"seed": 8, "col": "#6a4a2a"}, "clear": {"seed": 13, "col": "#6a7a7a"}})
def bottle_shards(c, col="#4a6a54", seed=1):
    r = c.rng
    spill = c.blob(36, 38, 22, 16, 0.45, 12, 0.12)
    c.paint(spill, "#14140f", 0.5)
    base = hexc(col)
    for _ in range(11):
        x, y, s, a = 36 + r.uniform(-24, 24), 36 + r.uniform(-20, 20), r.uniform(2.5, 7.0), r.uniform(0, 6.28)
        pts = [(x + np.cos(a + da) * s * rr, y + np.sin(a + da) * s * rr) for da, rr in ((0, 1.0), (2.0 + r.uniform(-0.4, 0.4), 0.7), (4.1 + r.uniform(-0.4, 0.4), 0.9))]
        m = c.poly(pts)
        c.paint(gblur(m, 1.0) * 0.8, "#0e0c0a", 0.7)
        c.paint(m, base * r.uniform(0.7, 1.3), 0.92)
        c.paint(c.seg([pts[0], pts[1]], 1.0, False, 0.4), "#d8e8d8", 0.75)
    c.graded = False


# ── 벽 낙서 · 글 ─────────────────────────────────────────────────────────────

def _glyph(r, x, y, s):
    """지어낸 글자 한 자 → 꺾은 선들(실제 글자 아님): 3 × 4 격자점을 잇는다."""
    gx = lambda i: x + (i - 1) * s * 0.42
    gy = lambda j: y + (j - 1.5) * s * 0.36
    strokes = []
    for _ in range(int(r.integers(2, 4))):
        n = int(r.integers(2, 4))
        pts = [(gx(int(r.integers(0, 3))) + r.uniform(-0.6, 0.6), gy(int(r.integers(0, 4))) + r.uniform(-0.6, 0.6)) for _ in range(n)]
        if len(set(pts)) > 1:
            strokes.append(pts)
    return strokes


def _scrawl(c, kind, x, y, s):
    """휘갈긴 표식 → 꺾은 선 목록."""
    r = c.rng
    j = lambda v=1.0: r.uniform(-v, v)
    if kind == "arrow":
        a = r.choice([0.0, 3.14, -1.57])
        ca, sa = np.cos(a), np.sin(a)
        tip = (x + ca * s, y + sa * s)
        return [[(x - ca * s + j(), y - sa * s + j()), tip], [(tip[0] - ca * s * 0.5 - sa * s * 0.4, tip[1] - sa * s * 0.5 + ca * s * 0.4), tip, (tip[0] - ca * s * 0.5 + sa * s * 0.4, tip[1] - sa * s * 0.5 - ca * s * 0.4)]]
    if kind == "eye":
        top = [(x + t * s, y - np.sin((t + 1) * 1.57) * s * 0.5 + j(0.5)) for t in np.linspace(-1, 1, 7)]
        bot = [(x + t * s, y + np.sin((t + 1) * 1.57) * s * 0.42 + j(0.5)) for t in np.linspace(-1, 1, 7)]
        iris = [(x + np.cos(a) * s * 0.26, y + np.sin(a) * s * 0.26) for a in np.linspace(0, 6.3, 9)]
        return [top, bot, iris, [(x, y - s * 0.9), (x, y - s * 0.62)], [(x - s * 0.5, y - s * 0.8), (x - s * 0.4, y - s * 0.55)], [(x + s * 0.5, y - s * 0.8), (x + s * 0.4, y - s * 0.55)]]
    if kind == "skull":
        head = [(x + np.cos(a) * s * 0.7, y - s * 0.2 + np.sin(a) * s * 0.62) for a in np.linspace(2.4, 2.4 + 5.0, 10)]
        jaw = [head[0], (x - s * 0.35, y + s * 0.75), (x + s * 0.35, y + s * 0.75), head[-1]]
        eyes = [[(x - s * 0.36, y - s * 0.3), (x - s * 0.14, y - s * 0.1)], [(x - s * 0.14, y - s * 0.3), (x - s * 0.36, y - s * 0.1)], [(x + s * 0.14, y - s * 0.3), (x + s * 0.36, y - s * 0.1)], [(x + s * 0.36, y - s * 0.3), (x + s * 0.14, y - s * 0.1)]]
        teeth = [[(x + t * s, y + s * 0.42), (x + t * s, y + s * 0.75)] for t in (-0.15, 0.0, 0.15)]
        return [head, jaw] + eyes + teeth
    if kind == "tally":
        n = int(r.integers(3, 6))
        out = [[(x - s + i * s * 0.45 + j(0.5), y - s * 0.6 + j()), (x - s + i * s * 0.45 + j(0.5), y + s * 0.6 + j())] for i in range(n)]
        if n >= 4:
            out.append([(x - s * 1.2, y + s * 0.4), (x - s + n * s * 0.45, y - s * 0.4)])
        return out
    if kind == "cross":   # 지운 글자
        g = _glyph(r, x, y, s * 1.5)
        return g + [[(x - s, y - s * 0.7), (x + s, y + s * 0.7)], [(x - s, y + s * 0.7), (x + s, y - s * 0.7)]]
    if kind == "spiral":
        return [[(x + np.cos(a) * s * a / 12.0, y + np.sin(a) * s * a / 12.0) for a in np.linspace(0.5, 12.0, 26)]]
    if kind == "sun":
        ring = [(x + np.cos(a) * s * 0.42, y + np.sin(a) * s * 0.42) for a in np.linspace(0, 6.3, 10)]
        return [ring] + [[(x + np.cos(a) * s * 0.6, y + np.sin(a) * s * 0.6), (x + np.cos(a) * s, y + np.sin(a) * s)] for a in np.linspace(0, 6.28, 9)[:-1]]
    return _glyph(r, x, y, s * 1.6)


@flat("wall_graffiti", "trace", layer="wall_decal", cell=(128, 110), tags=["sign"], name_ko="벽 낙서", meta={"mount": "face"},
    variants={"chalk_a": {"seed": 4, "marks": ("arrow", "tally", "glyph")}, "chalk_b": {"seed": 11, "marks": ("eye", "glyph", "glyph")}, "chalk_c": {"seed": 20, "marks": ("skull", "arrow")},
        "chalk_d": {"seed": 44, "marks": ("sun", "tally", "spiral")}, "blood_a": {"seed": 27, "marks": ("skull", "cross"), "ink": "blood"}, "blood_b": {"seed": 36, "marks": ("eye", "tally", "cross"), "ink": "blood"},
        "blood_c": {"seed": 51, "marks": ("spiral", "arrow"), "ink": "blood"}})
def wall_graffiti(c, marks=("arrow",), ink="chalk", seed=1):
    r = c.rng
    n = len(marks)
    m = np.zeros((c.H, c.W), F)
    for i, kind in enumerate(marks):
        s = r.uniform(15, 19) if n <= 2 else r.uniform(12, 15)
        x = 128 * (i + 0.5) / n + r.uniform(-5, 5)
        y = 52 + r.uniform(-14, 14)
        for pts in _scrawl(c, kind, x, y, s):
            m = np.maximum(m, c.seg(pts, 2.6 if ink == "chalk" else 3.6, False, 0.8))
    if ink == "chalk":   # 분필: 거칠게 끊기고 가루가 번진다
        tex = sstep(c.noise(2.0, None, 2), 0.3, 0.55)
        c.paint(gblur(m, 2.0) * 0.8, "#b8b2a0", 0.22)
        c.paint(m * tex, _tone(c, "#d2ccb8", 0.85, 1.1, 5.0), 0.85)
        c.graded = False
    else:        # 피: 굵고 흘러내린다
        drips = np.zeros((c.H, c.W), F)
        ys, xs = np.nonzero(m[::8, ::8] > 0.5)
        for k in r.permutation(len(ys))[:9]:
            x, y = xs[k] * 4.0 + 2, ys[k] * 4.0 + 2
            ln = r.uniform(8, 30)
            drips = np.maximum(drips, c.seg([(x, y), (x + r.uniform(-0.6, 0.6), y + ln)], 2.4, True, 0.7))
            drips = np.maximum(drips, _dots(c, [(x, y + ln, 1.5)]))
        m = np.maximum(m * (0.75 + c.noise(4.0) * 0.25), drips)
        _stain(c, m, "#5a1612", BLOOD_D, 0.9, False, 1.0)


@flat("wall_writing", "trace", layer="wall_decal", cell=(128, 96), tags=["sign", "ancient"], name_ko="벽에 새긴 글", meta={"mount": "face"}, variants={"a": {"seed": 6}, "b": {"seed": 17, "rows": 4}, "c": {"seed": 29, "rows": 2, "big": True}, "worn": {"seed": 38, "worn": True}})
def wall_writing(c, rows=3, big=False, worn=False, seed=1):
    r = c.rng
    s = 13.0 if big else 9.0
    cut = np.zeros((c.H, c.W), F)
    for j in range(rows):
        y = 48 + (j - (rows - 1) / 2) * s * 1.75
        x = 10 + r.uniform(0, 6)
        while x < 118 - s:
            if r.random() < 0.14:
                x += s * 0.7   # 낱말 사이
                continue
            for pts in _glyph(r, x + s * 0.4, y, s):
                cut = np.maximum(cut, c.seg(pts, 1.8 if not big else 2.4, False, 0.5))
            x += s * r.uniform(1.0, 1.25)
    if worn:
        cut = cut * sstep(c.noise(22.0), 0.36, 0.56)
    c.paint(np.roll(cut, (2, 2), (0, 1)) * (1 - cut), "#a8a294", 0.4)   # 파인 홈 아래쪽 밝은 턱
    c.paint(cut, _tone(c, "#14100e", 0.8, 1.2, 4.0), 0.85)
    c.graded = False


@flat("wall_scratches", "trace", layer="wall_decal", cell=(96, 110), tags=["beast", "prison"], name_ko="벽 긁힌 자국", meta={"mount": "face"},
    variants={"claw_a": {"seed": 5}, "claw_b": {"seed": 12}, "tally": {"seed": 19, "kind": "tally"}, "tally_many": {"seed": 33, "kind": "tally", "groups": 7}, "nails": {"seed": 40, "kind": "nails"}})
def wall_scratches(c, kind="claw", groups=3, seed=1):
    r = c.rng
    m = np.zeros((c.H, c.W), F)
    if kind == "claw":
        for i in range(4):
            x = 30 + i * 11 + r.uniform(-2, 2)
            y0 = 12 + r.uniform(0, 12) + abs(i - 1.5) * 6
            pts = [(x + t * 16 + np.sin(t * 3) * 3, y0 + t * r.uniform(60, 78)) for t in np.linspace(0, 1, 8)]
            m = np.maximum(m, c.seg(pts, 3.4, True, 0.6))
    elif kind == "nails":   # 손톱으로 긁어내린 가는 줄 여럿
        for i in range(9):
            x = 16 + r.uniform(0, 64)
            y0 = 30 + r.uniform(0, 30)
            m = np.maximum(m, c.seg([(x + r.uniform(-1, 1), y0 + t) for t in np.linspace(0, r.uniform(24, 50), 6)], 1.5, True, 0.5))
    else:
        for g in range(groups):
            gx, gy = 14 + (g % 3) * 28 + r.uniform(-2, 2), 22 + (g // 3) * 30 + r.uniform(-2, 2)
            n = 5 if g < groups - 1 else int(r.integers(1, 5))
            for i in range(min(n, 4)):
                m = np.maximum(m, c.seg([(gx + i * 5 + r.uniform(-0.8, 0.8), gy), (gx + i * 5 + r.uniform(-0.8, 0.8), gy + 18 + r.uniform(-2, 2))], 1.7, False, 0.5))
            if n == 5:
                m = np.maximum(m, c.seg([(gx - 3, gy + 14), (gx + 18, gy + 4)], 1.7, False, 0.5))
    c.paint(np.roll(m, (2, 1), (0, 1)) * (1 - m), "#a09a8c", 0.4)
    c.paint(m, _tone(c, "#120e0c", 0.8, 1.2, 4.0), 0.88)
    c.graded = False


@flat("blood_wall", "trace", layer="wall_decal", cell=(110, 150), tags=["blood", "battle"], name_ko="벽에 튄 피", meta={"mount": "face"},
    variants={"a": {"seed": 4}, "b": {"seed": 13}, "c": {"seed": 22}, "hand": {"seed": 31, "kind": "hand"}, "smear": {"seed": 39, "kind": "smear"}})
def blood_wall(c, kind="splat", seed=1):
    r = c.rng
    cx, cy = 55, 42
    if kind == "splat":
        m = np.maximum(_blood_pool_mask(c, cx, cy, r.uniform(11, 16), 0.45), _spray(c, cx, cy, r.uniform(-2.6, -0.5), 0.9, 30, 44))
    elif kind == "hand":
        m = c.blob(cx, cy, 8.5, 9.5, 0.2, 5)
        for i, a in enumerate((-2.5, -1.95, -1.6, -1.25, -0.6)):
            ln = (8, 13, 15, 13, 9)[i]
            m = np.maximum(m, c.seg([(cx + np.cos(a) * 7, cy + np.sin(a) * 8), (cx + np.cos(a) * (7 + ln), cy + np.sin(a) * (8 + ln))], 3.8, False))
        m = np.maximum(m, c.seg([(cx - 2, cy + 6), (cx + 3, cy + 40), (cx + 9, cy + 84)], 15, True, 2.0) * sstep(c.noise(7.0), 0.3, 0.55))   # 미끄러져 내린 자국
    else:
        pts = [(18 + t * 74, 30 + np.sin(t * 2.4) * 16 + t * 20) for t in np.linspace(0, 1, 9)]
        m = c.seg(pts, 17, True, 2.0) * sstep(c.noise(8.0), 0.25, 0.55)
        m = np.maximum(m, c.blob(pts[0][0], pts[0][1], 10, 9, 0.4, 6))
    drips = np.zeros((c.H, c.W), F)
    ys, xs = np.nonzero(m[::6, ::6] > 0.6)
    for k in r.permutation(len(ys))[:8]:
        x, y = xs[k] * 3.0 + 1.5, ys[k] * 3.0 + 1.5
        ln = r.uniform(14, 62)
        drips = np.maximum(drips, c.seg([(x, y), (x + r.uniform(-0.8, 0.8), y + ln * 0.5), (x + r.uniform(-0.8, 0.8), y + ln)], r.uniform(2.2, 3.6), True, 0.7))
        drips = np.maximum(drips, _dots(c, [(x, y + ln, 1.7)]))
    m = np.maximum(m, drips)
    _stain(c, m, BLOOD, BLOOD_D, 0.9, False, 1.2)
    c.origin = (55, 42)


@flat("ritual_marks", "trace", cell=(190, 190), tags=["ritual"], name_ko="의식 표식", variants={"chalk_circle": {"seed": 5}, "sigil_a": {"seed": 12, "kind": "sigil"}, "sigil_b": {"seed": 23, "kind": "sigil", "pts": 7}, "salt_line": {"seed": 30, "kind": "salt"}, "salt_ring": {"seed": 37, "kind": "salt_ring"}})
def ritual_marks(c, kind="circle", pts=5, seed=1):
    r = c.rng
    cx, cy = 95, 95
    if kind == "circle":   # 반쯤 지워진 분필 원 + 둘레 글자
        m = np.maximum(c.ring(cx, cy, 80, 2.4), c.ring(cx, cy, 62, 1.8))
        for i in range(14):
            a = i * 6.283 / 14
            for st in _glyph(r, cx + np.cos(a) * 71, cy + np.sin(a) * 71, 9.0):
                m = np.maximum(m, c.seg(st, 1.6, False, 0.5))
        tri = [(cx + np.cos(a) * 62, cy + np.sin(a) * 62) for a in (-1.57, 0.52, 2.62, -1.57)]
        m = np.maximum(m, c.seg(tri, 2.0, False, 0.7))
        m = m * sstep(c.noise(26.0), 0.34, 0.5) * sstep(c.noise(2.0, None, 2), 0.25, 0.5)
        m = m * (1 - c.seg([(30, 150), (90, 110), (150, 140)], 26, False, 6.0) * 0.9)   # 발로 문질러 지운 자리
        c.paint(gblur(m, 2.0) * 0.8, "#b8b2a0", 0.2)
        c.paint(m, "#d0cab6", 0.8)
        c.graded = False
    elif kind == "sigil":   # 피로 그린 문양: 별 꼴 + 가운데 눈
        vs = [(cx + np.cos(-1.57 + i * 6.283 / pts) * 74, cy + np.sin(-1.57 + i * 6.283 / pts) * 74) for i in range(pts)]
        step = 2 if pts == 5 else 3
        m = c.ring(cx, cy, 80, 5.0) * sstep(c.noise(10.0), 0.2, 0.45)
        for i in range(pts):
            a, b = vs[i], vs[(i + step) % pts]
            mid = ((a[0] + b[0]) / 2 + r.uniform(-2, 2), (a[1] + b[1]) / 2 + r.uniform(-2, 2))
            m = np.maximum(m, c.seg([a, mid, b], r.uniform(4.0, 5.5), False, 1.0) * (0.7 + c.noise(5.0) * 0.3))
        m = np.maximum(m, c.ring(cx, cy, 13, 3.6))
        m = np.maximum(m, _dots(c, [(cx, cy, 4.5)] + [(v[0] + r.uniform(-6, 6), v[1] + r.uniform(-6, 6), r.uniform(1.5, 3.4)) for v in vs]))
        _stain(c, m, "#521210", BLOOD_D, 0.9, False, 1.2)
        c.paint(gblur(m, 3.0) ** 2 * m, "#2a0808", 0.4)
    else:   # 소금 줄 · 소금 고리
        if kind == "salt":
            line = c.seg([(8 + t * 174, cy + np.sin(t * 5.0) * 5 + r.uniform(-1, 1)) for t in np.linspace(0, 1, 14)], 9, False, 2.5)
            line = line * (1 - c.blob(120, cy, 13, 16, 0.4, 8) * 0.95)   # 끊긴 자리
        else:
            line = c.ring(cx, cy, 70, 9, 2.5) * (1 - c.blob(cx + 62, cy + 30, 15, 15, 0.4, 8) * 0.95)
        grain = sstep(c.noise(1.6, None, 2), 0.42, 0.62)
        c.paint(line * 0.6, "#8e8a80", 0.4)
        c.paint(line * grain, "#dedad0", 0.9)
        c.paint(gblur(line, 4.0) * sstep(c.noise(1.3, None, 1) - 0.72, 0, 0.05), "#dedad0", 0.8)
        c.graded = False
