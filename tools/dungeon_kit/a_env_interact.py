"""상호작용 오브젝트(도시 · 실내 라이브러리 AM69 — 비어 있던 것만): 보물 궤짝 · 잠긴 문 · 버튼 · 조사할 물건 · 비밀 장치 · 스위치 · 열쇠 구멍 판 ·
문 봉인 · 손을 얹는 비석. 상태 짝은 meta.states(idle · active · spent — 레버 · 문과 같은 틀). 실제 동작은 게임 쪽 몫이다(그림 · 충돌 · 귀띔만).
이미 있는 것: 상자 · 궤짝(crate · chest) · 문틀과 문(doorway) · 레버(lever · wall_lever) · 압력판 · 잠금 받침대 · 사슬 자물쇠 · 봉인 장치 · 석판 · 룬석."""
import numpy as np

import sdf
import fx
from kit import (F, box, cap, cyl, ell, flat, hcyl, prop, rot_x, rot_y, rot_z, rough, smin, sphere, sub, torus, v3)  # noqa: F401
from paint2d import hexc
from a_light import GLOWC, chain, rune_post, iglyph
from a_wall import _door_leaf

GOLD_GLOW = "#f0c868"


# ── 보물 궤짝 ────────────────────────────────────────────────────────────────

@prop("treasure_coffer", "special", cell=(2, 2), collide=(0.8, 0.5), tags=["treasure", "gold", "container"], name_ko="보물 궤짝", interact="container",
    variants={"closed": {}, "open": {"state": "open"}, "empty": {"state": "empty"}},
    light={"color": GOLD_GLOW, "radius": 2.0, "at": (0, 0, 0.45), "flicker": 0.1, "variants": ["open"]},
    meta={"states": {"idle": "closed", "active": "open", "spent": "empty"}})
def treasure_coffer(k, state="closed", seed=1):
    """금박 모서리 · 둥근 뚜껑 · 사자발 다리의 작고 화려한 궤짝(나무 보물상자 chest보다 작고 귀하다)."""
    w, d, h = 0.36, 0.24, 0.3
    k.mat("lacquer", __import__("mats").wood("#4a2420", 0.12, 0, 33))
    k.add(lambda p: sub(box(p, v3(0, 0, 0.06 + h / 2), (w, d, h / 2), 0.02), box(p, v3(0, 0, 0.1 + h / 2), (w - 0.04, d - 0.04, h / 2)) if state != "closed" else box(p, v3(0, 0, 9), (0.01, 0.01, 0.01))), "lacquer")
    for sx in (-1, 1):
        for sy in (-1, 1):
            k.add(lambda p, sx=sx, sy=sy: smin(sphere(p, v3(sx * (w - 0.04), sy * (d - 0.04), 0.035), 0.04), box(p, v3(sx * (w - 0.01), sy * (d - 0.01), 0.06 + h / 2), (0.025, 0.025, h / 2 + 0.005), 0.005), 0.02), "gold")
    k.add(lambda p: box(p, v3(0, -d - 0.004, 0.06 + h * 0.62), (0.07, 0.01, 0.06), 0.01), "gold")
    lid_c = v3(0, 0, 0.06 + h)
    lid = lambda p: np.maximum(np.hypot(p[:, 1] - lid_c[1], p[:, 2] - lid_c[2]) - d, np.maximum(np.abs(p[:, 0]) - w, lid_c[2] - p[:, 2]))
    if state == "closed":
        k.add(lid, "lacquer")
        k.add(lambda p: np.maximum(np.abs(np.hypot(p[:, 1], p[:, 2] - lid_c[2]) - d) - 0.012, np.maximum(np.abs(np.abs(p[:, 0]) - w * 0.6) - 0.03, lid_c[2] - p[:, 2])), "gold")
        return {}
    open_lid = lambda p: lid(rot_x(p, -1.9, (0, d, lid_c[2])))
    k.add(open_lid, "lacquer")
    if state == "open":
        k.add(rough(lambda p: ell(p, v3(0, 0, 0.06 + h - 0.02), (w - 0.06, d - 0.06, 0.07)), 0.03, 0.03, seed), "gold")
        for i in range(4):
            x, y = k.rng.uniform(-0.2, 0.2), k.rng.uniform(-0.1, 0.1)
            k.add(lambda p, x=x, y=y, i=i: sdf.length(p - v3(x, y, 0.06 + h + 0.04)) - 0.03, ("crystal_r", "crystal_b", "crystal_v", "gold")[i])
        return {"glow": [(0, 0, 0.06 + h + 0.05, 34, GOLD_GLOW, 0.45)]}
    return {}


# ── 잠긴 문(벽 틈에 세우는 문틀 + 문짝) ────────────────────────────────────────

@prop("locked_door", "special", cell=(3, 4), collide=[(-0.5, -0.05, 1.0, 0.3)], tags=["door", "lock"], name_ko="잠긴 문", interact="door",
    variants={"wood_chained": {}, "wood_unlocked": {"state": "wood_unlocked"}, "iron_barred": {"kind": "iron", "state": "barred"},
              "iron_unbarred": {"kind": "iron", "state": "unbarred"}, "open": {"state": "open"}},
    meta={"states": {"idle": "wood_chained", "active": "wood_unlocked", "spent": "open"}, "states_iron": {"idle": "iron_barred", "active": "iron_unbarred"}, "mount": "gap"})
def locked_door(k, kind="wood", state="chained", seed=1):
    """나무 기둥 · 상인방 문틀(벽 틈 한 칸에 맞는다) + 문짝: 사슬과 자물쇠 / 쇠문에 가로지른 빗장. 열쇠로 풀면 사슬 · 빗장이 바닥에 떨어진다."""
    ow, oh = 0.36, 1.6
    for sx in (-1, 1):
        k.add(rough(lambda p, sx=sx: box(p, v3(sx * (ow + 0.07), 0.08, (oh + 0.12) / 2), (0.07, 0.09, (oh + 0.12) / 2), 0.01), 0.01, 0.1, seed), "wood_d")
    k.add(rough(lambda p: box(p, v3(0, 0.08, oh + 0.1), (ow + 0.18, 0.1, 0.07), 0.01), 0.01, 0.1, seed + 1), "wood_d")
    k.add(lambda p: box(p, v3(0, 0.2, oh / 2), (ow, 0.02, oh / 2)), "void")
    if state == "open":
        _door_leaf(k, -ow, ow, oh, kind, lambda fn: (lambda p: fn(rot_z(p, -1.3, (-ow, 0.1, 0)))), 0.1, seed)
        return {"foot": 1.2}
    _door_leaf(k, -ow, ow, oh, kind, lambda fn: fn, 0.1, seed)
    if state == "chained":   # 문고리 둘을 꿴 사슬 + 매달린 자물쇠
        for sx in (-0.3, 0.3):
            k.add(lambda p, sx=sx: torus(rot_x(p, 1.57, (sx, 0.02, 0.85)), v3(sx, 0.02, 0.85), 0.045, 0.012), "iron")
        k.add(chain(v3(-0.3, 0.0, 0.85), v3(0.0, -0.03, 0.74), 0.016), "iron")
        k.add(chain(v3(0.3, 0.0, 0.85), v3(0.0, -0.03, 0.74), 0.016), "iron")
        k.add(lambda p: np.minimum(box(p, v3(0, -0.04, 0.64), (0.06, 0.025, 0.065), 0.015), torus(rot_x(p, 1.57, (0, -0.04, 0.72)), v3(0, -0.04, 0.72), 0.04, 0.01)), "brass")
    elif state == "barred":  # 쇠고리 둘에 걸친 굵은 빗장 + 빗장 자물쇠
        for sx in (-0.42, 0.42):
            k.add(lambda p, sx=sx: box(p, v3(sx, 0.0, 0.9), (0.05, 0.05, 0.08), 0.01), "iron")
        k.add(lambda p: box(p, v3(0, -0.05, 0.9), (0.52, 0.03, 0.045), 0.01), "rust")
        k.add(lambda p: box(p, v3(0.12, -0.09, 0.86), (0.05, 0.02, 0.06), 0.01), "brass")
    else:                    # 풀림: 사슬 · 빗장이 문 앞 바닥에
        if kind == "wood":
            k.add(chain(v3(-0.3, -0.2, 0.02), v3(0.25, -0.3, 0.02), 0.016), "iron")
            k.add(lambda p: box(rot_z(p, 0.6, (0.33, -0.32, 0)), v3(0.33, -0.32, 0.03), (0.06, 0.025, 0.03), 0.01), "brass")
        else:
            k.add(lambda p: box(rot_z(p, 0.25, (0.05, -0.3, 0)), v3(0.05, -0.3, 0.035), (0.52, 0.045, 0.03), 0.01), "rust")
    return {"foot": 1.2}


# ── 버튼 · 스위치 · 비밀 장치 ─────────────────────────────────────────────────

@prop("wall_button", "special", layer="wall_decal", cell=(2, 3), tags=["machine", "stone"], name_ko="벽 버튼", interact="button",
    variants={"idle": {}, "pressed": {"state": "pressed"}, "glow": {"state": "glow"}},
    light={"color": GLOWC["blue"], "radius": 1.5, "at": (0, -0.1, 1.2), "flicker": 0.0, "variants": ["glow"]},
    meta={"states": {"idle": "idle", "active": "pressed"}})
def wall_button(k, state="idle", seed=1):
    k.add(rough(lambda p: box(p, v3(0, 0.05, 1.2), (0.2, 0.05, 0.2), 0.03), 0.012, 0.1, seed), "carved")
    k.add(lambda p: np.maximum(np.abs(np.hypot(p[:, 0], p[:, 2] - 1.2) - 0.13) - 0.012, np.abs(p[:, 1] + 0.005) - 0.01), "stone_d")
    depth = 0.0 if state == "pressed" else 0.05
    k.add(lambda p: np.maximum(np.hypot(p[:, 0], p[:, 2] - 1.2) - 0.09, np.abs(p[:, 1] + depth * 0.5 - 0.0) - depth * 0.5 - 0.012), "glow_b" if state == "glow" else "stone_l")
    if state == "glow":
        return {"shadow": 0.0, "glow": [(0, -0.06, 1.2, 22, GLOWC["blue"], 0.5)]}
    return {"shadow": 0.0}


@prop("floor_button", "special", cell=(2, 2), tags=["machine", "stone"], name_ko="바닥 버튼", interact="button",
    variants={"idle": {}, "pressed": {"state": "pressed"}, "glow": {"state": "glow"}},
    light={"color": GLOWC["blue"], "radius": 1.5, "at": (0, 0, 0.1), "flicker": 0.0, "variants": ["glow"]},
    meta={"states": {"idle": "idle", "active": "pressed"}})
def floor_button(k, state="idle", seed=1):
    """둥근 돌 받침에 솟은 단추(압력판보다 작고, 손 · 발로 누른다)."""
    k.add(rough(lambda p: sub(cyl(p, v3(0, 0, 0), 0.26, 0.06, 0.02), cyl(p, v3(0, 0, 0.03), 0.15, 0.1)), 0.012, 0.15, seed), "stone_d")
    hgt = 0.04 if state == "pressed" else 0.11
    k.add(lambda p: cyl(p, v3(0, 0, 0.02), 0.13, hgt, 0.025), "glow_b" if state == "glow" else "brass")
    if state == "glow":
        return {"glow": [(0, 0, 0.1, 24, GLOWC["blue"], 0.5)]}
    return {}


@prop("wall_switch", "special", layer="wall_decal", cell=(2, 3), tags=["machine"], name_ko="벽 스위치", interact="switch",
    variants={"knife_off": {}, "knife_on": {"state": "on"}, "rune_off": {"kind": "rune"}, "rune_on": {"kind": "rune", "state": "on"}},
    light={"color": GLOWC["violet"], "radius": 1.6, "at": (0, -0.1, 1.25), "flicker": 0.0, "variants": ["rune_on"]},
    meta={"states": {"idle": "knife_off", "active": "knife_on"}, "states_rune": {"idle": "rune_off", "active": "rune_on"}})
def wall_switch(k, kind="knife", state="off", seed=1):
    """칼날 스위치(놋쇠 판 위 젖히는 손잡이 — 레버보다 작고 납작하다) · 룬 스위치(돌 판 위 돌리는 원반 — 켜면 룬이 빛난다)."""
    if kind == "knife":
        k.add(lambda p: box(p, v3(0, 0.04, 1.25), (0.14, 0.03, 0.22), 0.015), "wood_d")
        k.add(lambda p: np.minimum(box(p, v3(0, 0.0, 1.38), (0.05, 0.02, 0.025)), box(p, v3(0, 0.0, 1.1), (0.05, 0.02, 0.025))), "brass")
        a = -0.35 if state == "off" else 0.35
        tip = v3(0, -0.2 * np.cos(a), 1.25 + 0.2 * np.sin(a) * 1.4)
        k.add(lambda p: cap(p, v3(0, -0.01, 1.1 if state == "off" else 1.38), tip, 0.014), "steel")
        k.add(lambda p: sphere(p, tip, 0.04), "wood")
        return {"shadow": 0.0}
    k.add(rough(lambda p: box(p, v3(0, 0.05, 1.25), (0.2, 0.05, 0.2), 0.03), 0.012, 0.1, seed), "carved")
    rot = 0.0 if state == "off" else 0.8
    k.add(lambda p: np.maximum(np.hypot(p[:, 0], p[:, 2] - 1.25) - 0.15, np.abs(p[:, 1] + 0.01) - 0.02), "stone_l")
    k.add(lambda p: box(rot_y(p, rot, (0, 0, 1.25)), v3(0, -0.035, 1.25), (0.025, 0.012, 0.13), 0.008), "stone_d")
    post = [rune_post(0.0, -0.06, 1.25, 11, 3, "violet" if state == "on" else None)]
    return {"shadow": 0.0, "post": post}


@prop("secret_panel", "special", layer="wall_decal", cell=(3, 4), tags=["secret", "stone", "door"], name_ko="숨은 벽 문", interact="secret",
    variants={"closed": {}, "ajar": {"state": "ajar"}, "open": {"state": "open"}},
    meta={"states": {"idle": "closed", "active": "ajar", "spent": "open"}, "mount": "face"})
def secret_panel(k, state="closed", seed=1):
    """벽 앞면에 붙이는 판 — 닫히면 벽돌 줄눈과 섞이고 긁힌 반원 자국만 남는다, 열리면 판이 밀려 들어가 어두운 틈."""
    w, h = 0.42, 1.55
    if state != "closed":
        k.add(lambda p: box(p, v3(0, 0.12, h / 2), (w, 0.02, h / 2)), "void")
    shift = {"closed": 0.0, "ajar": 0.12, "open": 0.62}[state]
    slab = lambda p: box(p, v3(shift, 0.04 + (0.04 if state != "closed" else 0.0), h / 2), (w, 0.04, h / 2), 0.004)
    k.add(rough(slab, 0.01, 0.12, seed), "masonry")
    return {"shadow": 0.0, "foot": 1.2}


@prop("pull_chain", "special", layer="wall_decal", cell=(1, 4), tags=["secret", "machine", "iron"], name_ko="당기는 사슬", interact="secret",
    variants={"up": {}, "pulled": {"state": "pulled"}}, meta={"states": {"idle": "up", "active": "pulled"}})
def pull_chain(k, state="up", seed=1):
    k.add(lambda p: box(p, v3(0, 0.06, 2.25), (0.08, 0.03, 0.06), 0.015), "iron")
    end = 1.2 if state == "up" else 0.85
    k.add(chain(v3(0, 0.02, 2.2), v3(0, -0.02, end + 0.08), 0.018), "iron")
    k.add(lambda p: torus(rot_x(p, 1.57, (0, -0.02, end)), v3(0, -0.02, end), 0.06, 0.016), "brass")
    return {"shadow": 0.0}


@prop("sconce_switch", "special", layer="wall_decal", cell=(2, 4), tags=["secret", "machine", "iron", "fire"], name_ko="기울이는 횃대", interact="secret",
    variants={"upright": {}, "tilted": {"state": "tilted"}}, meta={"states": {"idle": "upright", "active": "tilted"}})
def sconce_switch(k, state="upright", seed=1):
    """빈 횃대처럼 보이지만 아래로 젖히면 장치가 움직인다(횃불이 꽂히지 않은 쇠 고리 · 닳아 반들거리는 손잡이)."""
    k.add(rough(lambda p: box(p, v3(0, 0.07, 1.42), (0.1, 0.035, 0.2), 0.02), 0.01, 0.1, seed), "iron")
    a = -0.5 if state == "upright" else 0.7
    T = lambda p: rot_x(p, a, (0, 0.05, 1.38))
    k.add(lambda p: np.minimum(cap(T(p), v3(0, 0.05, 1.38), v3(0, -0.2, 1.38), 0.03), torus(T(p), v3(0, -0.24, 1.38), 0.07, 0.022)), "iron")
    k.add(lambda p: sphere(T(p), v3(0, -0.13, 1.38), 0.035), "brass")
    return {"shadow": 0.0}


# ── 조사할 물건 ───────────────────────────────────────────────────────────────

@prop("examine_spot", "special", cell=(2, 3), tags=["examine", "secret"], name_ko="수상한 자리", interact="examine",
    variants={"loose_brick": {}, "odd_slab": {"kind": "odd_slab"}, "pinned_note": {"kind": "pinned_note"}, "curio": {"kind": "curio"}})
def examine_spot(k, kind="loose_brick", seed=1):
    """살펴볼 만한 것: 벽에서 빠져나온 벽돌(뒤에 틈) · 둘레만 닳은 바닥 판석 · 칼로 꽂아 둔 쪽지 · 받침 위 낯선 장치."""
    if kind == "loose_brick":
        k.add(lambda p: box(p, v3(0, 0.1, 0.62), (0.15, 0.02, 0.07)), "void")
        k.add(rough(lambda p: box(p, v3(0.04, -0.05, 0.62), (0.15, 0.12, 0.068), 0.01), 0.01, 0.1, seed), "brick")
        k.add(rough(lambda p: box(p, v3(0, 0.15, 0.62), (0.4, 0.06, 0.62), 0.005), 0.01, 0.15, seed + 1), "brick")
        return {"foot": 0.8}
    if kind == "odd_slab":
        k.add(rough(lambda p: box(p, v3(0, 0, 0.012), (0.36, 0.26, 0.014), 0.01), 0.008, 0.2, seed), "stone_l")
        k.add(lambda p: sub(box(p, v3(0, 0, 0.006), (0.385, 0.285, 0.006)), box(p, v3(0, 0, 0.006), (0.362, 0.262, 0.02))), "coal")   # 둘레만 닳아 벌어진 틈
        k.add(lambda p: box(p, v3(0, 0, 0.0), (0.7, 0.5, 0.004)), "stone")
        k.add(lambda p: sphere(p, v3(0.27, -0.18, 0.02), 0.025), "iron")   # 들어 올리는 쇠고리 자리
        return {}
    if kind == "pinned_note":   # 나무 기둥에 단검으로 꽂은 쪽지
        k.add(rough(lambda p: cyl(p, v3(0, 0.1, 0), 0.12, 1.5, 0.02), 0.012, 0.1, seed), "wood")
        k.add(lambda p: box(rot_y(p, 0.08, (0, -0.03, 1.05)), v3(0, -0.03, 1.05), (0.09, 0.006, 0.12)), "paper")
        k.add(lambda p: cap(p, v3(0.02, -0.25, 1.12), v3(0.0, 0.05, 1.12), 0.01), "steel")
        k.add(lambda p: np.minimum(box(p, v3(0.02, -0.25, 1.12), (0.05, 0.01, 0.012)), cap(p, v3(0.02, -0.26, 1.12), v3(0.02, -0.38, 1.12), 0.018)), "leather_d")
        return {}
    k.add(lambda p: np.minimum(cyl(p, v3(0, 0, 0), 0.18, 0.06, 0.01), cyl(p, v3(0, 0, 0.06), 0.07, 0.5, 0.01)), "wood_d")   # 받침 + 위의 놋쇠 고리 장치
    k.add(lambda p: cyl(p, v3(0, 0, 0.56), 0.16, 0.04, 0.01), "wood_d")
    k.add(lambda p: np.minimum(torus(rot_x(p, 1.2, (0, 0, 0.78)), v3(0, 0, 0.78), 0.14, 0.012), torus(rot_y(p, 0.9, (0, 0, 0.78)), v3(0, 0, 0.78), 0.12, 0.012)), "brass")
    k.add(lambda p: sphere(p, v3(0, 0, 0.78), 0.05), "glass_b")
    k.add(lambda p: cap(p, v3(0, 0, 0.6), v3(0, 0, 0.72), 0.012), "brass")
    return {}


# ── 열쇠 구멍 판 · 봉인 · 비석 ─────────────────────────────────────────────────

@flat("keyhole_plate", "special", layer="wall_decal", cell=(64, 88), tags=["lock", "brass"], name_ko="열쇠 구멍 판", interact="keyhole", meta={"mount": "face"},
    variants={"plain": {}, "ornate": {"ornate": True}, "glow": {"ornate": True, "glow": True}, "key": {"key": True}},
    light={"color": GLOWC["blue"], "radius": 1.2, "at": (0, -0.05, 1.0), "flicker": 0.0, "variants": ["glow"]})
def keyhole_plate(c, ornate=False, glow=False, key=False, seed=1):
    c.origin = (32, 88 + 64 * 0.4)   # 벽 밑동에서 1칸쯤 위 — 문 높이의 자물쇠 자리
    plate = c.blob(32, 44, 17, 24, 0.0, 10, 0.06) if not ornate else np.maximum(c.blob(32, 44, 15, 26, 0.0, 10, 0.06), c.blob(32, 44, 22, 14, 0.0, 10, 0.06))
    c.paint(plate, "#7a6436")
    c.relief(gblur_(plate, 2.0), 3.0)
    c.paint(c.rim(plate, 1.4), "#2a1e10")
    if ornate:
        c.paint(c.ring(32, 44, 12, 1.5), "#4a3a1e", 0.8)
    hole = np.maximum(c.blob(32, 40, 4.5, 4.5, 0, 4, 0.08), c.poly([(29, 42), (35, 42), (36.5, 55), (27.5, 55)]))
    c.paint(hole, "#0a0807" if not glow else "#3a6ab0")
    if glow:
        c.glow(hole, GLOWC["blue"], 5, 0.8)
    if key:
        c.paint(c.rect(30.5, 30, 33.5, 46), "#6a6a64")
        bow = c.ring(32, 22, 7, 3)
        c.paint(bow, "#8a8270")
        c.paint(c.rim(np.maximum(bow, c.rect(30.5, 30, 33.5, 46)), 1.0), "#1a1614", 0.8)
    for x, y in ((32, 24), (32, 64)) if not ornate else ((32, 20), (32, 68), (14, 44), (50, 44)):
        c.paint(c.blob(x, y, 2.0, 2.0, 0, 2, 0.1), "#c8b070")


def gblur_(m, r):
    from paint2d import gblur
    return gblur(m, r)


@prop("door_seal", "special", layer="wall_decal", cell=(3, 4), tags=["magic", "seal", "door"], name_ko="문 봉인", interact="seal",
    variants={"sealed": {"frames": 4}, "broken": {"state": "broken"}},
    light={"color": GLOWC["violet"], "radius": 2.5, "at": (0, -0.1, 0.9), "flicker": 0.15, "variants": ["sealed"]},
    meta={"states": {"idle": "sealed", "spent": "broken"}, "mount": "over_door"})
def door_seal(k, state="sealed", seed=1, f=0):
    """문 앞을 X자로 가로지른 빛 띠 + 가운데 룬 원반(문 · 상자 위에 겹쳐 놓는다). 깨지면 끊긴 쇠 띠와 금 간 원반만 남는다."""
    if state == "broken":
        k.add(lambda p: box(rot_y(p, 0.8, (-0.25, -0.02, 0.5)), v3(-0.25, -0.02, 0.5), (0.25, 0.012, 0.025)), "iron")
        k.add(lambda p: box(rot_y(p, -0.8, (0.28, -0.02, 1.3)), v3(0.28, -0.02, 1.3), (0.22, 0.012, 0.025)), "iron")
        k.add(rough(lambda p: sub(np.maximum(np.hypot(p[:, 0], p[:, 2] - 0.9) - 0.16, np.abs(p[:, 1] + 0.03) - 0.02), box(rot_y(p, 0.5, (0.05, 0, 0.9)), v3(0.05, -0.03, 0.9), (0.01, 0.05, 0.2))), 0.01, 0.1, seed), "stone_d")
        return {"shadow": 0.0}
    k.add(lambda p: np.minimum(box(rot_y(p, 0.75, (0, -0.02, 0.9)), v3(0, -0.02, 0.9), (0.62, 0.008, 0.035)), box(rot_y(p, -0.75, (0, -0.02, 0.9)), v3(0, -0.02, 0.9), (0.62, 0.008, 0.035))), "glow_v")
    k.add(lambda p: np.maximum(np.hypot(p[:, 0], p[:, 2] - 0.9) - 0.16, np.abs(p[:, 1] + 0.035) - 0.02), "stone_d")
    pulse = 0.75 + 0.25 * np.sin(f * 1.57)
    return {"shadow": 0.0, "post": [rune_post(0.0, -0.06, 0.9, 13, 5 + 0, "violet", f)], "glow": [(0, -0.05, 0.9, 50, GLOWC["violet"], 0.35 * pulse)]}


@prop("hand_stele", "special", cell=(2, 3), collide=(0.8, 0.4), tags=["stone", "lore", "magic"], name_ko="손을 얹는 비석", interact="touch",
    variants={"idle": {}, "glowing": {"state": "glowing", "frames": 4}, "spent": {"state": "spent"}, "broken": {"state": "broken"}},
    light={"color": GLOWC["blue"], "radius": 2.5, "at": (0, -0.2, 0.75), "flicker": 0.1, "variants": ["glowing"]},
    meta={"states": {"idle": "idle", "active": "glowing", "spent": "spent"}})
def hand_stele(k, state="idle", seed=1, f=0):
    """낮은 받침 위 비스듬히 누운 글 판 — 가운데 손바닥 모양으로 팬 자리. 석판(stone_tablet) · 룬석보다 낮고, 손을 얹는 높이."""
    k.add(rough(lambda p: box(p, v3(0, 0.05, 0.22), (0.38, 0.24, 0.22), 0.03), 0.02, 0.15, seed), "stone_d")
    T = lambda p: rot_x(p, -0.55, (0, 0.0, 0.5))
    if state == "broken":
        k.add(rough(lambda p: np.maximum(box(T(p), v3(0, 0.0, 0.56), (0.34, 0.04, 0.24), 0.02), p[:, 0] + 0.05 + (sdf.noise(p, 0.07, seed) - 0.5) * 0.15), 0.015, 0.1, seed), "carved")
        k.add(rough(lambda p: box(rot_z(p, 0.7, (0.4, -0.45, 0)), v3(0.4, -0.45, 0.04), (0.18, 0.12, 0.035), 0.015), 0.02, 0.1, seed), "carved")
        return {}
    hand = lambda p: np.minimum(ell(T(p), v3(0, -0.04, 0.52), (0.09, 0.035, 0.1)),
        np.minimum.reduce([cap(T(p), v3(dx, -0.04, 0.6), v3(dx * 1.35, -0.04, 0.6 + ln), 0.026) for dx, ln in ((-0.06, 0.11), (-0.02, 0.14), (0.02, 0.14), (0.06, 0.11))]))
    k.add(lambda p: sub(box(T(p), v3(0, 0.0, 0.56), (0.34, 0.04, 0.24), 0.02), hand(p)), "carved")
    if state == "glowing":
        k.add(lambda p: np.maximum(hand(p), np.abs(T(p)[:, 1] + 0.01) - 0.012), "glow_b")
    post = []
    for i, x in enumerate((-0.26, -0.18, 0.18, 0.26)):
        post.append(rune_post(x, -0.04, 0.5 + 0.06 * (i % 2), 7, 10 + i, "blue" if state == "glowing" else None, f))
    out = {"post": post}
    if state == "glowing":
        out["glow"] = [(0, -0.05, 0.62, 30, GLOWC["blue"], 0.35 + 0.15 * np.sin(f * 1.57))]
    return out
