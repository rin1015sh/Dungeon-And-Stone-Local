#!/usr/bin/env python3
"""1분 트레일러 만들기 — 실제 게임 화면을 녹화(Godot 무비 메이커)해 자막·카드·합성 소리를 붙인다.

  GODOT=<godot 경로> python3 tools/trailer.py --work=<작업 폴더> [--record] [--out=docs/trailer/trailer.mp4]

  --record  : CLIPS를 모두 다시 녹화한다(xvfb-run + opengl3, 4개씩 — 약 5분). 없으면 <작업 폴더>/clips/*.avi를 그대로 쓴다.
  녹화는 tools/screenshot.tscn의 --hold(찍지 않고 더 돌리기)·--live_walk(걷기)·--pan(도시 거리 밀기)으로 한다.
  TIMELINE의 "from"은 녹화 파일의 프레임 번호(30fps). 장면을 바꾸면 <작업 폴더>/clips/<이름>.avi에서 프레임을 골라 고친다.
필요: ffmpeg(libx264·drawtext 불필요), Pillow, numpy. 자막 글꼴은 assets/fonts/SongMyung-Regular.ttf.
"""
import argparse
import os
import subprocess
import sys
import wave
from concurrent.futures import ThreadPoolExecutor

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT = os.path.join(ROOT, "assets/fonts/SongMyung-Regular.ttf")
W, H, FPS, SR = 1280, 720, 30, 48000
BONE = (232, 220, 196)

# 녹화할 장면: 이름 → screenshot.tscn 인자
CLIPS = {
    "city": "--screen=city --scroll=0 --pan=1500 --hold=7",
    "lib": "--screen=city --facility=library --hold=3",
    "plaza": "--screen=plaza --opening --hold=4",
    "lake": "--screen=explore --seed=1 --at=322,676 --torch --hold=0.3 --live_walk=left:1.5,up:2,right:1.5",
    "camp": "--screen=explore --seed=1 --at=399,466 --torch --parties --hold=0.3 --live_walk=up:2,right:1.5",
    "lord": "--screen=explore --seed=1 --at=366,371 --lord --hold=7",
    "rw_glacier": "--screen=explore --rift=rift_glacier_cave --chapter=2 --torch --hold=0.3 --live_walk=right:2,down:1",
    "rw_mine": "--screen=explore --rift=rift_green_mine --chapter=2 --torch --hold=0.3 --live_walk=right:2.5",
    "rw_blood": "--screen=explore --rift=rift_blood_fortress --chapter=3 --torch --hold=0.3 --live_walk=up:1.5,right:1.5",
    "rw_tomb": "--screen=explore --rift=rift_iron_tomb --chapter=2 --torch --hold=0.3 --live_walk=right:2.5",
    "c_goblin": "--screen=explore --combat --monster=goblin --god --summon=goblin_archer,goblin_swordsman --hit=0.02 --hold=4",
    "c_wolf": "--screen=explore --combat --monster=giant_blade_wolf --god --hit=0.02 --hold=4",
    "c_owl": "--screen=explore --combat --monster=owlbear --god --hit=0.02 --hold=4",
    "c_ghoul": "--screen=explore --combat --monster=ghoul_lord --god --hit=0.05 --hold=4",
    "c_dread": "--screen=explore --combat --monster=dreadfear --god --hit=0.02 --hold=4",
    "g_blater": "--screen=explore --rift=rift_blood_fortress --chapter=5 --near=guardian --engage=guardian --god --hit=0.02 --hold=4",
    "g_tarun": "--screen=explore --rift=rift_glacier_cave --chapter=4 --near=guardian --engage=guardian --god --hit=0.02 --hold=4",
    "g_slime": "--screen=explore --rift=rift_green_mine --chapter=4 --near=guardian --engage=guardian --god --hit=0.02 --hold=4",
    "g_ildium": "--screen=explore --rift=rift_iron_tomb --chapter=4 --near=guardian --engage=guardian --god --hit=0.02 --hold=4",
    "menu": "--screen=explore --menu=character --essence --many --hold=2",
}

# 편집: clip(녹화 이름·시작 프레임·초) / card(검은 화면 글) / title(끝 화면). text = 화면 아래 자막.
TIMELINE = [
    {"clip": "city", "from": 20, "sec": 6.0, "text": "스톤으로 버티는 도시, 라프도니아", "fade_in": 1.0},
    {"clip": "lib", "from": 30, "sec": 2.0},
    {"clip": "plaza", "from": 22, "sec": 4.0, "text": "달마다 한 번, 차원광장의 문이 열린다"},
    {"card": "미궁은 이레 동안만 열려 있다", "sec": 2.2},
    {"clip": "lake", "from": 40, "sec": 4.3, "text": "횃불이 닿는 곳까지가 네 세계다", "fade_in": 0.3},
    {"clip": "camp", "from": 62, "sec": 2.2, "text": "다른 탐험가도 같은 것을 노린다"},
    {"clip": "lake", "from": 158, "sec": 1.7},
    {"card": "균열 너머, 또 다른 세계", "sec": 2.0},
    {"clip": "rw_glacier", "from": 62, "sec": 1.3},
    {"clip": "rw_mine", "from": 70, "sec": 1.3},
    {"clip": "rw_blood", "from": 34, "sec": 1.3},
    {"clip": "rw_tomb", "from": 60, "sec": 1.3},
    {"card": "민첩이 순서를, 선택이 생사를 가른다", "sec": 2.2},
    {"clip": "c_goblin", "from": 38, "sec": 1.7},
    {"clip": "c_wolf", "from": 40, "sec": 1.3},
    {"clip": "c_owl", "from": 40, "sec": 1.3},
    {"clip": "c_ghoul", "from": 28, "sec": 1.5},
    {"clip": "g_slime", "from": 112, "sec": 1.3},
    {"clip": "g_tarun", "from": 112, "sec": 1.3},
    {"clip": "g_ildium", "from": 112, "sec": 1.3},
    {"clip": "g_blater", "from": 112, "sec": 1.5},
    {"card": "쓰러뜨린 것의 정수를 삼켜라", "sec": 2.2},
    {"clip": "menu", "from": 40, "sec": 1.6},
    {"clip": "lord", "from": 22, "sec": 1.1, "gamma": 1.45},
    {"clip": "lord", "from": 55, "sec": 1.9},
    {"card": "죽으면, 모든 것이 끝난다", "sec": 2.4},
    {"title": True, "clip": "plaza", "from": 16, "sec": None},  # 남은 시간을 채운다(전체 60초)
]
TOTAL = 60.0


def run(cmd: list) -> None:
    r = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    if r.returncode != 0:
        sys.exit("실패: %s\n%s" % (" ".join(cmd[:6]), r.stdout[-2000:]))


def record(work: str) -> None:
    godot = os.environ.get("GODOT", "godot")
    os.makedirs(os.path.join(work, "clips"), exist_ok=True)

    def one(name: str) -> str:
        avi = os.path.join(work, "clips", name + ".avi")
        cmd = ["timeout", "600", "xvfb-run", "-a", "-s", "-screen 0 %dx%dx24" % (W, H), godot, "--rendering-driver", "opengl3",
               "--path", ROOT, "--write-movie", avi, "--fixed-fps", str(FPS), "res://tools/screenshot.tscn", "--"] + CLIPS[name].split()
        r = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        return "%s %s" % (name, "ok" if r.returncode == 0 and os.path.exists(avi) else "실패")

    with ThreadPoolExecutor(4) as ex:
        for line in ex.map(one, CLIPS):
            print(line)


def font(px: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT, px)


def text_png(path: str, lines: list, band: bool) -> None:
    """lines = [(글, 크기, 색, y 가운데)] — 가운데 맞춤 + 흐린 그림자. band면 아래쪽을 어둡게 깔아 자막이 읽히게."""
    base = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    if band:
        shade = Image.new("L", (W, H), 0)
        sd = ImageDraw.Draw(shade)
        for y in range(H - 170, H):
            sd.line([(0, y), (W, y)], fill=int(170 * ((y - (H - 170)) / 170.0) ** 1.4))
        base.paste((0, 0, 0, 255), (0, 0), shade)
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    text = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for s, px, color, cy in lines:
        f = font(px)
        box = ImageDraw.Draw(text).textbbox((0, 0), s, font=f)
        xy = ((W - (box[2] - box[0])) / 2 - box[0], cy - (box[3] - box[1]) / 2 - box[1])
        ImageDraw.Draw(shadow).text((xy[0], xy[1] + 2), s, font=f, fill=(0, 0, 0, 235))
        ImageDraw.Draw(text).text(xy, s, font=f, fill=color + (255,))
    out = Image.alpha_composite(base, shadow.filter(ImageFilter.GaussianBlur(4)))
    Image.alpha_composite(out, text).save(path)


def segment(work: str, i: int, seg: dict, sec: float) -> str:
    out = os.path.join(work, "seg", "%02d.mp4" % i)
    enc = ["-c:v", "libx264", "-crf", "14", "-preset", "medium", "-pix_fmt", "yuv420p", "-r", str(FPS), "-an", out]
    n = round(sec * FPS)
    if "card" in seg:
        png = os.path.join(work, "seg", "%02d.png" % i)
        text_png(png, [(seg["card"], 52, BONE, H / 2)], False)
        fo = sec - 0.45
        vf = "format=rgba,fade=in:st=0.15:d=0.45:alpha=1,fade=out:st=%.2f:d=0.4:alpha=1" % fo
        run(["ffmpeg", "-y", "-v", "error", "-f", "lavfi", "-i", "color=black:s=%dx%d:r=%d:d=%.3f" % (W, H, FPS, sec),
             "-loop", "1", "-framerate", str(FPS), "-i", png, "-filter_complex",
             "[1:v]%s[t];[0:v][t]overlay=shortest=1,trim=end_frame=%d" % (vf, n)] + enc)
        return out
    avi = os.path.join(work, "clips", seg["clip"] + ".avi")
    base = ("[0:v]trim=start_frame=%d,setpts=PTS-STARTPTS,tpad=stop_mode=clone:stop_duration=10,trim=end_frame=%d,"
            "setpts=PTS-STARTPTS,vignette=angle=0.45" % (seg["from"], n))
    if seg.get("title"):
        png = os.path.join(work, "seg", "%02d.png" % i)
        text_png(png, [("던전 앤 스톤", 128, BONE, H / 2 - 40),
                       ("쿼터뷰 던전 크롤러, 턴제 로그라이크", 30, (200, 188, 166), H / 2 + 70),
                       ("비상업 팬 프로젝트", 20, (150, 140, 124), H - 50)], False)
        base += ",crop=960:540:200:90,scale=%d:%d,boxblur=6:1," % (W, H) + "eq=brightness=-0.22:saturation=0.7,fade=in:st=0:d=0.8,fade=out:st=%.2f:d=1.2" % (sec - 1.3)
        vf = "format=rgba,fade=in:st=0.6:d=1.2:alpha=1,fade=out:st=%.2f:d=1.0:alpha=1" % (sec - 1.4)
        run(["ffmpeg", "-y", "-v", "error", "-i", avi, "-loop", "1", "-framerate", str(FPS), "-i", png, "-filter_complex",
             base + "[v];[1:v]%s[t];[v][t]overlay=shortest=1,trim=end_frame=%d" % (vf, n)] + enc)
        return out
    if seg.get("gamma"):  # 어두운 장면(군주가 일어나는 곳 — 시야 2m)을 밝힌다
        base += ",eq=gamma=%.2f" % seg["gamma"]
    if seg.get("fade_in"):
        base += ",fade=in:st=0:d=%.2f" % seg["fade_in"]
    if "text" in seg:
        png = os.path.join(work, "seg", "%02d.png" % i)
        text_png(png, [(seg["text"], 34, BONE, H - 62)], True)
        vf = "format=rgba,fade=in:st=0.25:d=0.5:alpha=1,fade=out:st=%.2f:d=0.4:alpha=1" % (sec - 0.5)
        run(["ffmpeg", "-y", "-v", "error", "-i", avi, "-loop", "1", "-framerate", str(FPS), "-i", png, "-filter_complex",
             base + "[v];[1:v]%s[t];[v][t]overlay=shortest=1,trim=end_frame=%d" % (vf, n)] + enc)
    else:
        run(["ffmpeg", "-y", "-v", "error", "-i", avi, "-filter_complex", base] + enc)
    return out


# ---- 소리(합성) ----
def _env(n: int, a: float, d: float) -> np.ndarray:
    t = np.arange(n) / SR
    return np.minimum(1.0, t / max(a, 1e-4)) * np.exp(-t / d)


def onepole(x: np.ndarray, k: float) -> np.ndarray:
    """1차 저역 통과 y[n] = k·y[n-1] + (1-k)·x[n] — 주파수 영역에서 한 번에."""
    size = 1 << int(np.ceil(np.log2(len(x) * 2)))
    w = 2 * np.pi * np.arange(size // 2 + 1) / size
    return np.fft.irfft(np.fft.rfft(x, size) * (1 - k) / (1 - k * np.exp(-1j * w)), size)[:len(x)]


def soundtrack(cuts: dict, total: float, path: str) -> None:
    n = int(total * SR)
    t = np.arange(n) / SR
    rng = np.random.default_rng(7)
    L = np.zeros(n)
    R = np.zeros(n)

    def add(sig: np.ndarray, at: float, gain: float = 1.0, pan: float = 0.0) -> None:
        s = int(at * SR)
        m = min(len(sig), n - s)
        if m <= 0:
            return
        L[s:s + m] += sig[:m] * gain * (1 - pan) ** 0.5
        R[s:s + m] += sig[:m] * gain * (1 + pan) ** 0.5

    # 낮게 깔리는 울림 — 전투 몽타주에서 커지고 끝 화면에서 잦아든다
    swell = np.interp(t, [0, 3, 12, cuts["combat"], cuts["combat_end"], cuts["title"], total - 0.5, total],
                      [0, .5, .55, .7, .85, .75, .25, 0])
    drone = sum(np.sin(2 * np.pi * f * t + 0.3 * np.sin(2 * np.pi * lf * t)) * g
                for f, lf, g in [(55, .07, .5), (82.41, .05, .3), (110, .11, .2), (164.81, .09, .08), (54.6, .03, .3)])
    wind = onepole(rng.standard_normal(n), np.exp(-2 * np.pi * 300 / SR)) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.13 * t))
    L += (drone + wind * 0.9) * swell * 0.42
    R += (drone * 0.97 + np.roll(wind, 900) * 0.9) * swell * 0.42

    # 화음 깔개(가 단조 — 카드마다 바뀐다): 부드럽게 들어오는 여러 겹 사인 + 살짝 어긋난 음
    chords = [[110, 130.81, 164.81], [87.31, 110, 130.81], [73.42, 87.31, 110], [82.41, 103.83, 123.47],
              [110, 130.81, 164.81], [73.42, 87.31, 116.54], [82.41, 103.83, 123.47], [110, 130.81, 164.81, 220]]
    marks = [0.0] + cuts["cards"] + [cuts["riser"], cuts["title"], total]
    for ci in range(len(marks) - 1):
        a, b = marks[ci], marks[ci + 1]
        m = int((b - a + 0.6) * SR)
        tt = np.arange(m) / SR
        env = np.minimum(1, tt / 0.8) * np.clip((b - a + 0.6 - tt) / 0.6, 0, 1)
        ch = chords[min(ci, len(chords) - 1)]
        pad = sum(np.sin(2 * np.pi * f * tt) + 0.5 * np.sin(2 * np.pi * f * 1.003 * tt) + 0.25 * np.sin(2 * np.pi * f * 2 * tt) for f in ch)
        add(pad * env / len(ch), max(0.0, a - 0.3), 0.16 if ci < len(marks) - 2 else 0.22, 0.15 * (-1) ** ci)

    # 문이 열릴 때 반짝이는 높은 울림
    sh = cuts["plaza"]
    m = int(4.0 * SR)
    tt = np.arange(m) / SR
    shimmer = sum(np.sin(2 * np.pi * f * tt) for f in (659.3, 987.8, 1318.5)) * np.sin(np.pi * tt / 4.0) ** 2 * (0.6 + 0.4 * np.sin(2 * np.pi * 6 * tt))
    add(shimmer, sh, 0.035, -0.3)
    add(np.roll(shimmer, 2400), sh, 0.035, 0.3)

    def boom(strength: float) -> np.ndarray:
        m = int(2.5 * SR)
        tt = np.arange(m) / SR
        f = 32 + 70 * np.exp(-tt / 0.12)
        sub = np.sin(2 * np.pi * np.cumsum(f) / SR) * _env(m, 0.004, 0.75)
        crack = onepole(rng.standard_normal(m), np.exp(-2 * np.pi * 1800 / SR)) * _env(m, 0.001, 0.07)
        return np.tanh((sub * 1.2 + crack * 0.8) * 1.5) * strength

    def tom() -> np.ndarray:
        m = int(0.6 * SR)
        tt = np.arange(m) / SR
        f = 48 + 60 * np.exp(-tt / 0.05)
        return (np.sin(2 * np.pi * np.cumsum(f) / SR) * _env(m, 0.002, 0.18)
                + onepole(rng.standard_normal(m), np.exp(-2 * np.pi * 900 / SR)) * _env(m, 0.001, 0.03) * 0.6)

    def braam(sec: float) -> np.ndarray:
        m = int(sec * SR)
        tt = np.arange(m) / SR
        saw = sum(((tt * f) % 1.0 * 2 - 1) * g for f, g in [(41.2, .5), (55, .5), (61.74, .35), (82.4, .25)])
        saw = onepole(saw, np.exp(-2 * np.pi * 420 / SR))
        return np.tanh(saw * 2.2) * np.minimum(1, tt / 0.25) * np.exp(-tt / (sec * 0.45))

    for at in cuts["cards"]:
        add(boom(0.7), at)
    # 전투 몽타주: 박자(초당 2.2번) + 장면 바뀔 때마다 강박
    beat = 1 / 2.2
    k = cuts["combat"]
    i = 0
    while k < cuts["combat_end"] - 0.05:
        add(tom(), k, 0.55 if i % 2 == 0 else 0.35, (-0.25 if i % 2 else 0.25))
        k += beat
        i += 1
    for at in cuts["combat_hits"]:
        add(boom(0.45), at)
    # 군주: 낮은 금관 울림
    add(braam(3.0), cuts["lord"], 0.8)
    # 끝 화면 앞 상승음 → 큰 울림
    rs, re = cuts["riser"], cuts["title"]
    m = int((re - rs) * SR)
    tt = np.arange(m) / SR
    u = tt / (re - rs)
    riser = np.sin(2 * np.pi * np.cumsum(120 + 500 * u ** 2) / SR) * u ** 2 * 0.25 \
        + onepole(rng.standard_normal(m), np.exp(-2 * np.pi * 2500 / SR)) * u ** 3 * 0.5
    add(riser, rs, 0.6)
    add(boom(1.0), re)
    add(braam(5.0), re, 0.35)

    # 잔향(짧은 감쇠 잡음과 합성곱)
    ir_n = int(2.2 * SR)
    ir = rng.standard_normal(ir_n) * np.exp(-np.arange(ir_n) / SR / 0.55)
    ir = onepole(ir, np.exp(-2 * np.pi * 3000 / SR))
    ir /= np.sqrt(np.sum(ir ** 2))

    def verb(x: np.ndarray) -> np.ndarray:
        size = 1 << int(np.ceil(np.log2(len(x) + ir_n)))
        return np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)[:len(x)]

    L, R = L + verb(L) * 0.35, R + verb(np.roll(R, 300)) * 0.35
    fade = np.interp(t, [0, 0.3, total - 1.2, total], [0, 1, 1, 0])
    st = np.stack([L, R], 1) * fade[:, None]
    st = np.tanh(st / np.max(np.abs(st)) * 1.8) * 0.9
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((st * 32767).astype("<i2").tobytes())


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--work", required=True)
    ap.add_argument("--out", default=os.path.join(ROOT, "docs/trailer/trailer.mp4"))
    ap.add_argument("--record", action="store_true")
    a = ap.parse_args()
    if a.record:
        record(a.work)
    os.makedirs(os.path.join(a.work, "seg"), exist_ok=True)
    fixed = sum(s["sec"] for s in TIMELINE if s["sec"] is not None)
    secs = [s["sec"] if s["sec"] is not None else round(TOTAL - fixed, 3) for s in TIMELINE]
    # 각 장면의 시작 시각 → 소리 맞추기
    starts, acc = [], 0.0
    for s in secs:
        starts.append(acc)
        acc += round(s * FPS) / FPS
    cuts = {"cards": [], "combat_hits": []}
    for i, seg in enumerate(TIMELINE):
        if "card" in seg:
            cuts["cards"].append(starts[i])
        if seg.get("clip") == "plaza" and "plaza" not in cuts:
            cuts["plaza"] = starts[i]
        if seg.get("clip", "").startswith(("c_", "g_")):
            cuts.setdefault("combat", starts[i])
            cuts["combat_end"] = starts[i] + secs[i]
            cuts["combat_hits"].append(starts[i])
        if seg.get("clip") == "lord" and "lord" not in cuts:
            cuts["lord"] = starts[i]
        if seg.get("title"):
            cuts["title"] = starts[i]
    cuts["riser"] = cuts["cards"][-1]
    cuts["cards"] = cuts["cards"][:-1]
    with ThreadPoolExecutor(4) as ex:
        files = list(ex.map(lambda p: segment(a.work, p[0], p[1], p[2]), [(i, s, secs[i]) for i, s in enumerate(TIMELINE)]))
    lst = os.path.join(a.work, "seg", "list.txt")
    with open(lst, "w") as f:
        f.writelines("file '%s'\n" % p for p in files)
    wav = os.path.join(a.work, "trailer.wav")
    soundtrack(cuts, TOTAL, wav)
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    run(["ffmpeg", "-y", "-v", "error", "-f", "concat", "-safe", "0", "-i", lst, "-i", wav, "-map", "0:v", "-map", "1:a",
         "-c:v", "libx264", "-crf", "20", "-preset", "slow", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k",
         "-t", str(TOTAL), "-movflags", "+faststart", a.out])
    print("트레일러 → %s (%.1f초, 장면 %d)" % (a.out, TOTAL, len(TIMELINE)))


if __name__ == "__main__":
    main()
