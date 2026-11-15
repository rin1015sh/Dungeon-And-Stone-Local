"""동네 집 리터칭(AM70 — 사용자 2026-11-15 "기존 도시 건물 시각적 개선 및 디테일 리터칭"):
꼴 · 크기 · 창문 · 문 · 색 계열은 그대로 두고, tools/paint_town_hand.gd가 찍은 날 그림 위에 입체감 · 빛 · 재질만 덧칠한다.
손그림 마감(town_handdrawn.finish) 앞에 부른다 — town_hand_bake.py가 자료 그림(_mat · _geo · _nrm)이 있으면 부른다.

  ① 해 그림자: 깊이 자료로 픽셀마다 3D 자리를 되살려 해 쪽(왼쪽 위 · 남쪽 — 날 그림의 빛과 같은 방향)으로 걸어 가며 가리는 것이 있으면 그늘
     (처마 · 지붕창 · 현관 · 탑 · 굴뚝 · 버팀벽 그림자). 빛을 받는 정도(n·L)만큼만 어둡게 — 원래 그늘진 면은 그대로.
  ② 틈 그늘(AO): 법선 반구 안으로 솟은 이웃이 있으면 어둡게 — 벽과 지붕이 만나는 곳 · 안쪽 모서리 · 처마 밑 · 계단 · 기둥 밑.
  ③ 모서리: 볼록한 모서리 중 빛 쪽은 밝게(닳은 돌 모서리는 끊기게), 지붕 처마 끝에 지붕 두께(밝은 테 + 어두운 처마널).
  ④ 땅 닿는 곳: 밑동 그늘 · 튄 흙 · 젖은 띠 · 이끼(구역 · 시설마다 다르게).
  ⑤ 재질 결(Paint.track_mat 번호): 돌 = 잔 구멍 · 실금 · 얼룩, 회벽 = 빗물 자국, 벽돌 = 굴뚝 그을음, 나무 = 결 · 바램,
     유리 = 창 안쪽 깊이(위 · 왼쪽 그늘) · 꺼진 창 반사, 지붕 = 처마 쪽 물때 · 이끼 · 마루 바램, 금속 = 녹청 · 반짝임, 천 = 주름.
  ⑥ 건물마다 다른 손질(PROFILE — 시설 · 구역): 대장간 그을음 · 신전 깨끗한 흰 돌 · 은행 날 선 모서리 · 여관 창빛 번짐 · 강변 물때 …
수치는 모두 아래 표(가정 — ASSUMPTIONS AM70). 무작위 없음(집 id로 정한 잡음).
"""
import zlib

import numpy as np
from PIL import Image

SUN = np.array([-0.6, 0.75, 0.35]) / np.linalg.norm([-0.6, 0.75, 0.35])  ## 해 쪽(paint_town_hand.gd 해와 같다 — 참 공간 X 동 · Y 위 · Z 남)
SHADOW_REACH = 1.7  ## 해 그림자를 찾는 거리(칸) — 처마 · 지붕창 · 현관 · 버팀벽 크기. 탑이 지붕에 드리우는 긴 그림자는 얼룩처럼 보여 뺐다.
KEEP_DARK = 0.03  ## 리터칭 뒤 집 전체 밝기가 원본보다 어두워져도 되는 몫(넘으면 고르게 되돌린다)
MAT_NAMES = ["trim", "plaster", "stone", "brick", "wood", "glass", "roof", "metal", "cloth"]

## 기본 세기(모든 집 공통) — 건물마다 PROFILE이 곱한다.
BASE = {
    "shadow": 0.36,  # 해 그림자(빛 받는 면이 그늘이 될 때 줄어드는 몫 — 1이면 앰비언트만)
    "ao": 0.42,  # 틈 그늘
    "edge": 1.0,  # 빛 쪽 모서리 밝힘
    "wear": 0.6,  # 모서리 닳음(끊김)
    "grime": 0.6,  # 밑동 때 · 얼룩
    "damp": 0.5,  # 젖은 띠
    "moss": 0.4,  # 이끼
    "soot": 0.0,  # 그을음(대장간)
    "crack": 0.5,  # 실금
    "stain": 0.5,  # 빗물 자국
    "grain": 1.0,  # 재질 결 세기
    "spill": 0.5,  # 창빛 번짐
    "warm": 0.0,  # 따뜻한 기운(+) · 찬 기운(−)
}
## 건물마다(시설 → 구역 → 기본). 정체성: 대장간 = 거칠고 그을린, 여관 = 따뜻하고 손때, 신전 = 깨끗하고 엄숙, 상점 = 친근 · 실용, 은행 = 단단 · 날 선.
PROFILE = {
    "smithy": {"soot": 1.0, "grime": 1.2, "wear": 1.3, "moss": 0.2, "crack": 0.9, "edge": 0.8, "stain": 0.3, "warm": 0.02},
    "inn": {"spill": 1.0, "grime": 0.75, "wear": 0.8, "grain": 1.2, "stain": 0.6, "warm": 0.03},
    "temple": {"grime": 0.25, "moss": 0.15, "crack": 0.2, "stain": 0.25, "edge": 1.35, "wear": 0.3, "ao": 0.5, "warm": -0.01, "spill": 0.3},
    "shop": {"grime": 0.6, "spill": 0.7, "stain": 0.5, "warm": 0.015},
    "bank": {"grime": 0.3, "moss": 0.05, "crack": 0.1, "edge": 1.45, "wear": 0.2, "stain": 0.2, "ao": 0.48, "spill": 0.35},
    "guild": {"grime": 0.7, "wear": 0.9, "crack": 0.6, "moss": 0.3, "spill": 0.6},
    "library": {"grime": 0.35, "moss": 0.2, "crack": 0.25, "edge": 1.2, "stain": 0.45, "spill": 0.5},
    "civic": {"grime": 0.45, "moss": 0.25, "crack": 0.35, "edge": 1.15, "stain": 0.4},
    "market": {"grime": 0.65, "spill": 0.7, "stain": 0.5, "warm": 0.01},
    "res": {"grime": 0.7, "moss": 0.6, "stain": 0.6, "wear": 0.7},
    "river": {"grime": 0.75, "moss": 0.9, "damp": 1.0, "stain": 0.7, "crack": 0.6, "warm": -0.01},
    "townhall": {"grime": 0.4, "edge": 1.25, "crack": 0.3, "moss": 0.2},
}


def profile(meta):
    out = dict(BASE)
    for key in (meta.get("zone", ""), meta.get("fac", "")):  # 구역 다음 시설이 이긴다
        for k, v in PROFILE.get(key, {}).items():
            out[k] = BASE[k] * v if k not in ("warm",) else v
    return out


# ── 작은 도구 ───────────────────────────────────────────

def shift(a, dx, dy, fill=0):
    """a를 (dx, dy)만큼 민 것 — out[y, x] = a[y + dy, x + dx](밖은 fill)."""
    H, W = a.shape[:2]
    out = np.full_like(a, fill)
    ys0, ys1 = max(0, -dy), min(H, H - dy)
    xs0, xs1 = max(0, -dx), min(W, W - dx)
    if ys1 > ys0 and xs1 > xs0:
        out[ys0:ys1, xs0:xs1] = a[ys0 + dy:ys1 + dy, xs0 + dx:xs1 + dx]
    return out


def blur(a, r):
    """상자 흐림 두 번(가우스 비슷) — r px."""
    if r <= 0:
        return a
    for _ in range(2):
        for axis in (0, 1):
            c = np.cumsum(np.pad(a, [(r + 1, r) if i == axis else (0, 0) for i in range(a.ndim)], mode="edge"), axis=axis)
            hi = np.take(c, np.arange(2 * r + 1, c.shape[axis]), axis=axis)
            lo = np.take(c, np.arange(0, c.shape[axis] - 2 * r - 1), axis=axis)
            a = (hi - lo) / (2 * r + 1)
    return a


def noise(h, w, scale, seed, sx=1.0, sy=1.0):
    """부드러운 값 잡음(0~1) — scale px 격자, sx · sy = 가로 · 세로로 늘인 배율(나뭇결 · 빗물 자국)."""
    gh, gw = int(h / (scale * sy)) + 3, int(w / (scale * sx)) + 3
    g = np.random.default_rng(seed).random((gh, gw))
    im = Image.fromarray((g * 255).astype(np.uint8)).resize((int(gw * scale * sx), int(gh * scale * sy)), Image.BICUBIC)
    return np.asarray(im).astype(float)[:h, :w] / 255.0


def run_from(m, axis, reverse=False):
    """m(참 · 거짓)이 이어진 길이 — axis 방향으로 m 구역의 시작(reverse면 끝)에서 몇 픽셀째인가(m 밖은 0)."""
    a = m if not reverse else np.flip(m, axis)
    a = np.moveaxis(a, axis, 0)
    out = np.zeros(a.shape, np.int32)
    for i in range(a.shape[0]):
        out[i] = np.where(a[i], (out[i - 1] + 1) if i > 0 else 1, 0)
    out = np.moveaxis(out, 0, axis)
    return out if not reverse else np.flip(out, axis)


def _cracks(img, wall, opening, S, amount, seed):
    """실금 그리기 — 꺾은선(1px · 짙은 먹색 반투명). 자리: 틀 둘레 벽(70%) · 아무 벽(30%)."""
    from PIL import ImageDraw
    H, W = wall.shape
    rng = np.random.default_rng(seed)
    near = wall & (blur(opening.astype(float), 3) > 0.05)
    n = int(wall.sum() / (S * S) * 0.9 * amount)
    if n <= 0:
        return img
    cand = [np.argwhere(near), np.argwhere(wall)]
    layer = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(layer)
    for i in range(n):
        pool = cand[0] if (i % 10 < 7 and len(cand[0])) else cand[1]
        if not len(pool):
            continue
        y, x = pool[rng.integers(len(pool))]
        pts = [(float(x), float(y))]
        ang = np.pi / 2 + rng.uniform(-0.9, 0.9)
        for _ in range(rng.integers(3, 7)):
            ang += rng.uniform(-0.7, 0.7)
            ang = float(np.clip(ang, 0.25, np.pi - 0.25))
            ln = rng.uniform(S * 0.04, S * 0.1)
            pts.append((pts[-1][0] + np.cos(ang) * ln, pts[-1][1] + np.sin(ang) * ln))
            if rng.random() < 0.25:  # 곁가지
                b = pts[-1]
                a2 = ang + rng.choice([-1, 1]) * rng.uniform(0.6, 1.1)
                d.line([b, (b[0] + np.cos(a2) * ln * 0.6, b[1] + np.sin(a2) * ln * 0.6)], fill=110, width=1)
        d.line(pts, fill=150, width=1)
    a = np.asarray(layer).astype(float) / 255.0 * wall
    return img * (1 - a[..., None] * 0.55) + np.array([0.12, 0.1, 0.08]) * a[..., None] * 0.55


# ── 리터칭 ──────────────────────────────────────────────

def retouch(raw, code, mat, geo, nrm, meta, hid="", layers=None):
    """raw(H, W, 3 · 0~1) · code(면 번호) · mat(재질 번호) · geo(H, W, 3 바이트) · nrm(H, W, 3 바이트) → 리터칭한 날 그림."""
    S = float(meta.get("s", 96.0))
    span = float(meta.get("span", 64.0))
    pr = profile(meta)
    seed = zlib.crc32(hid.encode()) & 0xFFFF
    mask = code != 0
    H, W = mask.shape
    gi = geo.astype(np.int64)
    z = ((gi[..., 0] * 256 + gi[..., 1]) / 65535.0 - 0.5) * span  # 남쪽 깊이(칸 — 집 가운데 기준)
    hgt = gi[..., 2] / 10.0  # 참 높이(칸)
    n = nrm.astype(float) / 255.0 * 2.0 - 1.0
    n /= np.maximum(1e-6, np.linalg.norm(n, axis=-1, keepdims=True))
    yy, xx = np.mgrid[0:H, 0:W]
    P = np.stack([xx / S, -yy / S + z, z], -1)  # 참 3D 자리(칸 — 상대값)
    ndl = np.clip((n * SUN).sum(-1), 0.0, 1.0)
    img = raw.copy()
    lum0 = raw @ np.array([0.3, 0.59, 0.11])
    trace = layers.setdefault("trace", []) if layers is not None else None

    def mark(name):
        if trace is not None:
            trace.append((name, float((img @ np.array([0.3, 0.59, 0.11]))[mask].mean())))

    # ① 해 그림자 — 해 쪽으로 걸으며 깊이 자료에서 앞을 가리는 것을 찾는다
    shade = np.zeros((H, W))
    idx = np.nonzero(mask & (ndl > 0.02))
    py, px = idx
    pz = z[idx]
    hit = np.zeros(py.shape, bool)
    tt = np.zeros(py.shape)  # 가리는 것까지 거리(칸)
    t = 2.0 / S
    while t < SHADOW_REACH and not hit.all():
        qx = np.rint(px + SUN[0] * t * S).astype(np.int64)
        qy = np.rint(py - (SUN[1] - SUN[2]) * t * S).astype(np.int64)
        ok = (qx >= 0) & (qx < W) & (qy >= 0) & (qy < H)
        qz = np.where(ok, z[qy.clip(0, H - 1), qx.clip(0, W - 1)], -1e9)
        qm = ok & mask[qy.clip(0, H - 1), qx.clip(0, W - 1)]
        rz = pz + SUN[2] * t
        new = ~hit & qm & (qz > rz + 0.03 + t * 0.01) & (qz < rz + 2.5)
        tt[new] = t
        hit |= new
        t += max(1.5 / S, t * 0.06)
    shade[idx] = hit * np.clip(1.0 - tt / SHADOW_REACH, 0, 1) ** 0.7  # 가까운 것만 진하게(긴 탑 그림자는 바닥 그림이 맡는다)
    shade = np.clip(blur(shade, 2) * 0.7 + blur(shade, 5) * 0.3, 0, 1) * mask  # 반그림자(가장자리 부드럽게)
    sh_amt = shade * pr["shadow"] * np.clip(ndl / 0.75, 0, 1.15)
    img *= (1.0 - sh_amt)[..., None]
    img = img * (1 - shade[..., None] * 0.25) + img * np.array([0.95, 0.98, 1.05]) * shade[..., None] * 0.25  # 그늘은 아주 조금 차게

    mark('② 틈 그늘')
    # ② 틈 그늘 — 법선 반구 안으로 솟은 이웃(평면은 0)
    occ = np.zeros((H, W))
    cnt = 0
    for rad in (5, 11, 22, 40):
        for k in range(8):
            ang = (k + (rad % 3) * 0.33) * np.pi / 4.0
            dx, dy = int(round(np.cos(ang) * rad)), int(round(np.sin(ang) * rad))
            Q = shift(P, dx, dy)
            qm = shift(mask, dx, dy, False)
            d = Q - P
            dist = np.linalg.norm(d, axis=-1) + 1e-6
            up = (d * n).sum(-1) / dist
            w = np.clip(up - 0.12, 0, 1) * np.clip(1.0 - dist / 1.6, 0, 1) * qm
            occ += w
            cnt += 1
    occ = np.clip(occ / cnt * 2.6, 0, 1)
    occ = blur(occ, 2) * mask
    img *= (1.0 - occ * pr["ao"])[..., None]

    mark('③ 볼록')
    # ③ 볼록 모서리(빛 쪽 밝게 · 닳아 끊김) · 지붕 두께
    conv = np.zeros((H, W))
    for dx, dy in ((3, 0), (-3, 0), (0, 3), (0, -3)):
        Q = shift(P, dx, dy)
        qm = shift(mask, dx, dy, False)
        d = Q - P
        dist = np.linalg.norm(d, axis=-1) + 1e-6
        conv = np.maximum(conv, np.clip(-(d * n).sum(-1) / dist - 0.15, 0, 1) * qm)
    conv = np.clip(blur(conv, 1) * 1.6, 0, 1) * mask
    chip = noise(H, W, 5, seed + 1) > (0.3 + 0.4 * min(1.0, pr["wear"]))
    lit_edge = conv * (0.35 + ndl) * np.where(chip | (mat == 6) | (mat == 7), 1.0, 0.35)
    img = img + (1.0 - img) * (lit_edge * 0.16 * pr["edge"])[..., None]
    roof = mat == 6
    eave = run_from(roof, 0, reverse=True)  # 지붕 아래 끝(처마)에서 몇 픽셀째
    fascia = roof & (eave <= 3)
    lipline = roof & (eave >= 4) & (eave <= 5)
    img[fascia] *= 0.62  # 처마널(지붕 두께의 그늘진 단면)
    img[lipline] = img[lipline] + (1 - img[lipline]) * 0.16  # 기와 끝 밝은 테

    mark('③-2')
    # ③-2 처마 밑 그늘(지붕 아래 끝에서 내려가며 옅어짐 — 처마가 하늘빛을 가린다)
    roof_bottom = roof & ~shift(roof, 0, 1, False)
    ue = np.zeros((H, W))
    step = 3
    reach = int(S * 0.55)
    for k in range(step, reach, step):
        ue = np.maximum(ue, shift(roof_bottom, 0, -k, False) * (1.0 - k / reach) ** 1.6)
    ue = blur(ue, 2) * mask * ~roof
    img *= (1.0 - ue * 0.34 * pr["ao"] / BASE["ao"])[..., None]

    mark('③-3')
    # ③-3 틀 · 돌림띠 · 문틀이 벽에 드리운 작은 그림자(오른쪽 아래 — 틀의 두께) · 문 안쪽 깊이
    wallm = np.isin(mat, (1, 2, 3)) & mask
    trim = (mat == 0) & mask
    cast = np.zeros((H, W))
    for k in range(1, 6):
        cast = np.maximum(cast, shift(trim, -k, -k, False) * (1.0 - k / 6.0))
    cast = blur(cast, 1) * wallm
    img *= (1.0 - cast * 0.3)[..., None]
    doorw = (mat == 4) & mask & (hgt < 1.4)
    dt = run_from(doorw, 0)
    dl = run_from(doorw, 1)
    dr = run_from(doorw, 1, reverse=True)
    wide = (dl + dr) > S * 0.4
    drec = doorw * wide * np.maximum(np.clip(1.0 - dt / 12.0, 0, 1), np.clip(1.0 - dl / 8.0, 0, 1) * 0.7)
    img *= (1.0 - drec * 0.4)[..., None]

    mark('③-4')
    # ③-4 돌 · 벽돌 · 기와 사이 깊이: 줄눈(어두운 가는 선) 바로 아래 · 오른쪽 = 빛 받는 돌 윗 · 왼 모서리, 위 · 왼쪽 = 그늘진 아랫 · 오른 모서리
    mason = np.isin(mat, (2, 3, 6)) | (trim & (pr["edge"] > 1.1))
    lum_r = raw @ np.array([0.3, 0.59, 0.11])
    mort = (lum_r < blur(lum_r, 3) - 0.045) & mask
    litb = (shift(mort, 0, -1, False) | shift(mort, -1, 0, False) | shift(mort, 0, -2, False)) & ~mort & mason
    darkb = (shift(mort, 0, 1, False) | shift(mort, 1, 0, False)) & ~mort & mason
    bev = 0.09 * pr["grain"] * min(1.3, pr["edge"])
    img[litb] = img[litb] + (1 - img[litb]) * bev
    img[darkb] *= (1.0 - bev * np.where(trim[darkb], 0.7, 1.2))[:, None]
    img[mort & mason & ~trim] *= 0.9

    mark('④ 땅')
    # ④ 땅 닿는 곳 — 밑동 그늘 · 튄 흙 · 젖은 띠 · 이끼
    vert = np.clip(1.0 - np.abs(n[..., 1]) * 1.6, 0, 1)  # 선 면만(계단 · 현관 바닥 같은 윗면은 밑동이 아니다)
    low = np.clip(1.0 - hgt / 0.5, 0, 1) * mask * (~roof) * vert
    n_big = noise(H, W, 18, seed + 2)
    n_mid = noise(H, W, 6, seed + 3)
    img *= (1.0 - low * (0.16 + 0.12 * pr["grime"]))[..., None]
    splash = np.clip(1.0 - hgt / 0.28, 0, 1) * (n_mid > 0.55) * mask * (~roof) * vert
    img = img * (1 - splash[..., None] * 0.25 * pr["grime"]) + np.array([0.24, 0.2, 0.15]) * splash[..., None] * 0.25 * pr["grime"]
    dampband = np.clip(1.0 - hgt / (0.45 + 0.35 * pr["damp"]), 0, 1) * (0.6 + 0.4 * n_big) * mask * (~roof) * vert * np.isin(mat, (1, 2, 3, 0))
    img *= (1.0 - dampband * 0.14 * pr["damp"])[..., None]
    mossy = np.isin(mat, (2, 0, 3)) * mask * np.clip(1.0 - hgt / 0.9, 0, 1) * np.clip((n_big - 0.45) * 3, 0, 1) * (n_mid > 0.4)
    mossy = np.maximum(mossy, (mat == 6) * np.clip((n_big - 0.62) * 4, 0, 1) * (noise(H, W, 3, seed + 4) > 0.5) * np.clip(1 - eave / (S * 0.8), 0, 1))
    mcol = np.array([0.32, 0.36, 0.2])
    img = img * (1 - mossy[..., None] * 0.35 * pr["moss"]) + mcol * (img.mean(-1, keepdims=True) * 1.4) * mossy[..., None] * 0.35 * pr["moss"]

    mark('⑤ 재질')
    # ⑤ 재질 결
    fine = noise(H, W, 2, seed + 5) - 0.5
    speck = noise(H, W, 1.2, seed + 6)
    g = pr["grain"]
    stone = np.isin(mat, (2, 0)) & mask
    img[stone] *= (1.0 + fine[stone] * 0.07 * g)[:, None]
    pores = stone & (speck > 0.9)
    img[pores] *= 0.86
    # 실금: 짧고 꺾인 금(대부분 아래로) — 창 · 문 모서리(틀 둘레)에서 많이, 벽 가운데는 드물게
    img = _cracks(img, np.isin(mat, (1, 2)) & mask & vert.astype(bool), (mat == 0) | (mat == 5), S, pr["crack"], seed + 7)
    # 회벽 빗물 자국: 위(처마 · 창 밑)에서 흘러내린 세로 얼룩
    plaster = (mat == 1) & mask
    streak = noise(H, W, 7, seed + 9, sx=0.6, sy=9.0)
    from_top = np.clip(1.0 - run_from(plaster | (mat == 0), 0) / (S * 1.4), 0, 1)
    sill = shift((mat == 5) | (mat == 0), 0, -6, False)
    below_open = np.clip(blur(sill.astype(float), 4) * 3, 0, 1)
    stain = plaster * np.clip((streak - 0.55) * 3.5, 0, 1) * np.maximum(from_top, below_open) * pr["stain"]
    img *= (1.0 - stain * 0.16)[..., None]
    img[plaster] *= (1.0 + fine[plaster] * 0.04 * g)[:, None]
    # 나무: 세로 결 · 아래쪽 바램
    wood = (mat == 4) & mask
    wg = noise(H, W, 2.0, seed + 10, sx=0.5, sy=14.0) - 0.5
    img[wood] *= (1.0 + wg[wood] * 0.16 * g)[:, None]
    wlow = wood & (hgt < 0.6)
    img[wlow] = img[wlow] * 0.85 + img[wlow].mean(-1, keepdims=True) * 0.15
    # 벽돌: 굴뚝 · 위 끝 그을음
    brick = (mat == 3) & mask
    btop = run_from(brick, 0)
    soot_b = brick * np.clip(1.0 - btop / (S * 0.45), 0, 1)
    img *= (1.0 - soot_b * (0.32 + 0.3 * pr["soot"]))[..., None]
    # 유리: 창 안쪽 깊이(위 · 왼쪽 틀이 드리운 그늘) · 꺼진 창 하늘 반사
    glass = (mat == 5) & mask
    gt = run_from(glass, 0)
    gl = run_from(glass, 1)
    gr = run_from(glass, 1, reverse=True)
    rec = glass * np.maximum(np.clip(1.0 - gt / 9.0, 0, 1), np.clip(1.0 - gl / 6.0, 0, 1) * 0.7)
    img *= (1.0 - rec * 0.42)[..., None]
    warm = glass & (raw[..., 0] > raw[..., 2] * 1.5) & (lum0 > 0.35)
    dark = glass & ~warm
    diag = gl - gt * 0.8  # 창 왼쪽 위 모서리에서 비스듬히 — 하늘빛 반사 줄 하나(굵게) + 가는 줄 하나
    glint = np.clip(1.0 - np.abs(diag - 7.0) / 2.5, 0, 1) + np.clip(1.0 - np.abs(diag - 13.0) / 1.2, 0, 1) * 0.6
    glint = glint * dark * (gt >= 3) * (gt <= 22) * (gr >= 3)
    img = img + (np.array([0.62, 0.7, 0.72]) - img) * (glint * 0.32)[..., None]
    # 창빛 번짐(켜진 창 둘레 벽에 따뜻한 빛 — 안팎 깊이 차)
    spill = blur(warm.astype(float), 10) * mask * ~glass
    img = img + np.array([1.0, 0.66, 0.3]) * (spill * 0.22 * pr["spill"])[..., None] * (1 - img)
    # 지붕: 처마 쪽 물때 · 마루 쪽 바램 · 결
    rtop = run_from(roof, 0)
    rfrac = np.clip(rtop / np.maximum(1, rtop + eave), 0, 1)
    img[roof] *= (1.0 - (rfrac[roof] ** 2) * 0.12 + (1 - rfrac[roof]) * 0.04)[:, None]
    img[roof] *= (1.0 + fine[roof] * 0.05 * g)[:, None]
    rstreak = roof & (noise(H, W, 5, seed + 11, sx=0.7, sy=5.0) > 0.7) & (rfrac > 0.5)
    img[rstreak] *= 0.93
    # 금속(돔 · 납): 녹청 줄 · 반짝임
    metal = (mat == 7) & mask
    V = np.array([0.0, 0.6, 0.8])
    Hh = (SUN + V) / np.linalg.norm(SUN + V)
    spec = blur(np.clip((n * Hh).sum(-1), 0, 1) ** 16 * metal, 8)  # 면이 각져도 번지게(조각마다 하얗게 튀지 않게)
    img = img + (np.array([0.66, 0.7, 0.64]) - img) * (spec * 0.2 * metal)[..., None]
    verd = metal & (noise(H, W, 4, seed + 12, sx=0.6, sy=6.0) > 0.6)
    img[verd] = img[verd] * 0.8 + np.array([0.24, 0.36, 0.32]) * 0.2
    # 천(차양 · 깃발): 세로 주름
    cloth = (mat == 8) & mask
    fold = np.sin(xx / (S * 0.09) + noise(H, W, 20, seed + 13) * 4) * 0.5 + 0.5
    img[cloth] *= (0.9 + fold[cloth] * 0.14)[:, None]

    mark('⑥ 시설')
    # ⑥ 시설 손질 — 그을음(대장간: 위로 갈수록 · 창 · 문 위로 번진 검댕) · 따뜻한/찬 기운
    if pr["soot"] > 0:
        openings = (mat == 5) | ((mat == 4) & (hgt < 1.2))
        rise = np.zeros((H, W))
        for k in range(1, 12):
            rise = np.maximum(rise, shift(openings, 0, k * 4, False) * (1 - k / 12))
        rise = blur(rise, 6) * mask * ~openings * ~roof
        top_soot = np.clip((hgt - 0.6) / 2.0, 0, 1) * mask * ~roof * 0.5
        sootm = np.clip(rise * 1.1 + top_soot, 0, 1) * (0.7 + 0.3 * n_big) * pr["soot"]
        img = img * (1 - sootm[..., None] * 0.45) + np.array([0.09, 0.08, 0.07]) * sootm[..., None] * 0.45

    # 굴뚝 둘레 지붕 그을음(모든 집 조금 · 대장간 많이 — 화덕 연기)
    chim = blur((mat == 3).astype(float), int(S * (0.25 + 0.35 * pr["soot"])))
    roof_soot = roof * np.clip(chim * 3.0, 0, 1) * (0.6 + 0.4 * n_big) * (0.12 + 0.4 * pr["soot"])
    img = img * (1 - roof_soot[..., None]) + np.array([0.08, 0.07, 0.06]) * roof_soot[..., None]
    if pr["warm"]:
        img = img * (1 + np.array([1.0, 0.3, -0.8]) * pr["warm"])
    mark("end")
    # 밝기 지키기: 깊이를 그리며 집 전체가 어두워진 몫을 조금 되돌린다(원래 밝기에서 3%까지만 어둡게 — 색 계열 · 분위기 유지)
    lw = np.array([0.3, 0.59, 0.11])
    l0, l1 = float(lum0[mask].mean()), float((img @ lw)[mask].mean())
    gain = float(np.clip(l0 * (1.0 - KEEP_DARK) / max(1e-6, l1), 1.0, 1.08))
    img[mask] = img[mask] * gain
    mark("gain")
    img = np.where(mask[..., None], np.clip(img, 0, 1), raw)
    if layers is not None:
        layers.update({"shadow": shade, "ao": occ, "edge": conv, "mat": mat})
    return img
