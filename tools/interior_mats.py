"""실내 재질(CT106 — tools/interior_bake.py 전용): tex(u, v) → (rgb, 작은 면 번호|None). u · v = 칸 좌표(화면).
바닥: oak · honey(판자) · sandstone · limestone · flag(판석) · terracotta(흙 타일) · dirt(다진 흙) · marble(큰 대리석 판).
벽 앞면: plaster(회벽 + 검은 들보 — 동네 반목조 집과 같은 색) · stone_dark · sandstone · limestone · ashlar(마름돌) · plank(판자벽) · brick_soot(그을린 벽돌).
색은 동네 그림(손그림 집 · 바닥)에 맞춘 바랜 갈색 · 크림 · 잿빛 — 채도 높은 색을 넣지 않는다.
"""
import numpy as np

from interior_canvas import hash2, hexc, vnoise

FLOORS = {
    "oak": ("#6e5236", 0.42), "honey": ("#8a6a42", 0.46), "sandstone": ("#a08a68", 0), "limestone": ("#b4ac98", 0),
    "flag": ("#7c766a", 0), "terracotta": ("#7e5a44", 0), "dirt": ("#5e4e3c", 0), "marble": ("#c2b8a2", 0),
}


def _grain(u, v, seed, along_u=True):
    a, b = (u, v) if along_u else (v, u)
    return vnoise(a * 0.6, b * 9.0, 1.0, seed) * 0.6 + vnoise(a * 3.0, b * 20.0, 1.0, seed + 3) * 0.4


def planks(base, width, seed):
    c = hexc(base)

    def tex(u, v):
        row = np.floor(v / width).astype(np.int64)
        off = hash2(row, 0, seed) * 7.0
        seg_len = 2.2 + hash2(row, 1, seed) * 1.8
        seg = np.floor((u + off) / seg_len).astype(np.int64)
        tone = 0.84 + hash2(row, seg, seed + 5) * 0.3
        g = _grain(u, v, seed + 9)
        rgb = c[None, None, :] * (tone * (0.86 + g * 0.24))[..., None]
        ly = (v / width) % 1.0
        rgb = rgb * (1.0 - 0.18 * np.clip((ly - 0.82) / 0.18, 0, 1))[..., None]  # 판 아래쪽 그늘
        knot = (vnoise(u * 3, v * 3, 1.0, seed + 21) > 0.86)
        rgb = np.where(knot[..., None], rgb * 0.75, rgb)
        return rgb, (row * 97 + seg) & 4095
    return tex


def slabs(base, sw, sh, seed, var=0.22, vein=0.0):
    """엇갈려 깐 네모 돌판(줄마다 반쯤 밀림 · 판마다 폭이 조금 다르다)."""
    c = hexc(base)

    def tex(u, v):
        row = np.floor(v / sh).astype(np.int64)
        shift = (row % 2) * 0.5 * sw + hash2(row, 2, seed) * 0.3
        col = np.floor((u + shift) / sw).astype(np.int64)
        tone = 1.0 + (hash2(row, col, seed) - 0.5) * var * 2
        n = vnoise(u * 2.0, v * 2.0, 1.0, seed + 4) * 0.6 + vnoise(u * 7, v * 7, 1.0, seed + 8) * 0.4
        rgb = c[None, None, :] * (tone * (0.88 + n * 0.2))[..., None]
        if vein > 0:
            w = np.abs(np.sin((u * 1.3 + v * 0.7 + vnoise(u, v, 0.8, seed + 12) * 3.0) * 3.1))
            rgb = rgb * (1.0 - vein * np.clip(1 - w * 6, 0, 1))[..., None]
        lx = ((u + shift) / sw) % 1.0
        ly = (v / sh) % 1.0
        rim = np.clip(1 - np.minimum(lx, ly) * 14, 0, 1) * 0.12  # 왼쪽 위 모서리가 밝다
        rgb = rgb * (1 + rim)[..., None]
        drk = np.clip((np.maximum(lx, ly) - 0.9) * 10, 0, 1) * 0.14
        rgb = rgb * (1 - drk)[..., None]
        return rgb, (row * 131 + col) & 4095
    return tex


def dirt(base, seed):
    c = hexc(base)

    def tex(u, v):
        n = vnoise(u, v, 1.4, seed) * 0.5 + vnoise(u * 4, v * 4, 1.0, seed + 1) * 0.3 + vnoise(u * 14, v * 14, 1.0, seed + 2) * 0.2
        rgb = c[None, None, :] * (0.78 + n * 0.4)[..., None]
        peb = vnoise(u * 9, v * 9, 1.0, seed + 7) > 0.83
        rgb = np.where(peb[..., None], rgb * 1.18, rgb)
        return rgb, None
    return tex


def floor(name, seed):
    base, pw = FLOORS.get(name, FLOORS["oak"])
    if pw:
        return planks(base, pw, seed)
    if name == "dirt":
        return dirt(base, seed)
    if name == "terracotta":
        return slabs(base, 0.62, 0.62, seed, 0.16)
    if name == "marble":
        return slabs(base, 1.6, 1.1, seed, 0.08, vein=0.18)
    if name == "limestone":
        return slabs(base, 1.25, 0.9, seed, 0.1)
    if name == "sandstone":
        return slabs(base, 1.0, 0.72, seed, 0.14)
    return slabs(base, 0.95, 0.7, seed, 0.2)


# 벽 앞면 ---------------------------------------------------------------

WALLS = {
    "plaster": "#c8b896", "stone_dark": "#5a5248", "sandstone": "#8e7656", "limestone": "#a89e88",
    "ashlar": "#a29c8e", "plank": "#6a4e34", "brick_soot": "#7a4e3a",
}


def base_color(name):
    """걸레받이 · 처마 띠 색(벽보다 어둡게 — 바닥과 벽이 갈라 보이게)."""
    return {"plaster": hexc("#3a2c20"), "plank": hexc("#3a2a1c")}.get(name, hexc(WALLS.get(name, "#a29c8e")) * 0.55)


def wall(name, seed, base_y=0.0):
    """벽 앞면 재질. base_y = 그 벽의 땅 자리(화면 칸 y) — 높이 z = base_y − v."""
    c = hexc(WALLS.get(name, WALLS["ashlar"]))
    if name == "plaster":
        beam = hexc("#3a2c20")

        def tex(u, v):
            z = base_y - v
            n = vnoise(u * 1.2, v * 1.2, 1.0, seed) * 0.6 + vnoise(u * 6, v * 6, 1.0, seed + 1) * 0.4
            rgb = c[None, None, :] * (0.86 + n * 0.18)[..., None]
            stain = np.clip((0.55 - z) / 0.55, 0, 1) * 0.22 + np.clip(vnoise(u, v, 2.5, seed + 3) - 0.6, 0, 1) * 0.5
            rgb = rgb * (1 - stain)[..., None]
            post = ((u + 0.16) % 2.0) < 0.26
            rail = (np.abs(z - 2.05) < 0.12) | (z < 0.16)
            diag = (np.abs(((u % 2.0) - 0.26) - (z - 0.16) * 0.8) < 0.09) & (z > 0.16) & (z < 1.95) & ((u // 2.0) % 2 == 0)
            tim = post | rail | diag
            wood = beam[None, None, :] * (0.85 + vnoise(u * 2, v * 12, 1.0, seed + 5) * 0.3)[..., None]
            rgb = np.where(tim[..., None], wood, rgb)
            sub = np.where(tim, 1 + (np.floor((u + 0.16) / 2.0).astype(np.int64) % 64) * 4 + rail * 2 + diag, 0)
            return rgb, sub
        return tex
    if name == "plank":
        def tex(u, v):
            col = np.floor(u / 0.42).astype(np.int64)
            tone = 0.85 + hash2(col, 3, seed) * 0.28
            g = _grain(v, u, seed)
            rgb = c[None, None, :] * (tone * (0.85 + g * 0.25))[..., None]
            return rgb, col & 4095
        return tex
    bw, bh = (0.5, 0.25) if name == "brick_soot" else (0.62, 0.3)

    def tex(u, v):
        z = base_y - v
        row = np.floor(z / bh).astype(np.int64)
        shift = (row % 2) * bw * 0.5
        col = np.floor((u + shift) / bw).astype(np.int64)
        tone = 0.86 + hash2(row, col, seed) * 0.26
        n = vnoise(u * 4, v * 4, 1.0, seed + 2)
        rgb = c[None, None, :] * (tone * (0.88 + n * 0.18))[..., None]
        if name == "brick_soot":
            rgb = rgb * (1 - np.clip((z - 1.0) / 1.4, 0, 1) * 0.45)[..., None]
        ly = (z / bh) % 1.0
        rgb = rgb * (1 + np.clip(ly - 0.85, 0, 1) * 0.8)[..., None]
        return rgb, (row * 53 + col) & 4095
    return tex


def wood(base, seed, along_u=True):
    c = hexc(base)

    def tex(u, v):
        g = _grain(u, v, seed, along_u)
        return c[None, None, :] * (0.82 + g * 0.3)[..., None], None
    return tex


def grainy(base, seed, amt=0.16, scale=3.0):
    c = hexc(base)

    def tex(u, v):
        n = vnoise(u * scale, v * scale, 1.0, seed)
        return c[None, None, :] * (1 - amt + n * amt * 2)[..., None], None
    return tex


def books(seed, h=0.32):
    """책 등(칸 줄마다 색이 다른 책) — 책장 칸에."""
    cols = [hexc(s) for s in ("#6a2a22", "#2e4258", "#5a4a2a", "#3a4a30", "#4e3424", "#7a6a48", "#3a2a3a", "#8a7a5a")]
    pal = np.stack(cols, 0)

    def tex(u, v):
        row = np.floor(v / h).astype(np.int64)
        bwid = 0.07 + hash2(row, 4, seed) * 0.03
        b = np.floor(u / bwid + hash2(row, 7, seed) * 5).astype(np.int64)
        k = (hash2(b, row, seed) * len(cols)).astype(np.int64) % len(cols)
        rgb = pal[k] * (0.8 + hash2(b, row, seed + 1)[..., None] * 0.35)
        top = ((v / h) % 1.0) < (0.12 + hash2(b, row, seed + 2) * 0.25)
        rgb = np.where(top[..., None], rgb * 0.25, rgb)  # 책 위 빈틈(어둠)
        return rgb, (row * 211 + b) & 4095
    return tex


def plank_door(seed):
    c = hexc("#4e3624")

    def tex(u, v):
        col = np.floor(u / 0.2).astype(np.int64)
        tone = 0.85 + hash2(col, 9, seed) * 0.25
        g = _grain(v, u, seed + 2)
        return c[None, None, :] * (tone * (0.85 + g * 0.25))[..., None], col & 4095
    return tex


def glass(pair, seed):
    """색유리(납 줄로 나뉜 작은 판 — 두 색이 섞인다)."""
    a, b = hexc(pair[0]), hexc(pair[1])
    lead = hexc("#1c1a18")

    def tex(u, v):
        i, j = np.floor(u / 0.16).astype(np.int64), np.floor(v / 0.2).astype(np.int64)
        k = hash2(i, j, seed)
        rgb = np.where((k > 0.5)[..., None], a[None, None, :], b[None, None, :]) * (0.85 + k[..., None] * 0.35)
        edge = (((u / 0.16) % 1.0) < 0.12) | (((v / 0.2) % 1.0) < 0.1)
        rgb = np.where(edge[..., None], lead[None, None, :], rgb)
        return rgb, None
    return tex


def coals(seed):
    """화덕 숯불(검은 숯 사이로 붉게 타는 덩이)."""
    hot, cold = hexc("#ff7a2a"), hexc("#2a1a12")

    def tex(u, v):
        n = vnoise(u * 5, v * 5, 1.0, seed) * 0.7 + vnoise(u * 13, v * 13, 1.0, seed + 1) * 0.3
        k = np.clip((n - 0.35) / 0.4, 0, 1)
        rgb = cold[None, None, :] * (1 - k[..., None]) + hot[None, None, :] * k[..., None] * (0.8 + n[..., None] * 0.5)
        return rgb, None
    return tex
