#!/usr/bin/env python3
"""그림 가져오기 압축 맞추기(사용자 결정 2026-11-09 — 웹 꾸러미 198MB → 약 73MB).

원본 .webp가 손실 압축이면 Godot도 손실(품질 0.9)로, 무손실(VP8L — 동작 시트 · 바닥 타일 · 소품)이면 무손실로 가져온다.
무손실 원본을 무손실로 다시 저장하면 그대로지만, 손실 원본을 무손실로 다시 저장하면 화질은 같고 크기만 3~4배가 된다.

  python3 tools/texture_compress.py          # assets/의 .webp.import를 고친다(고친 수를 찍는다)
  python3 tools/texture_compress.py --check  # 고칠 것이 있으면 목록을 찍고 종료 코드 1

새 그림: project.godot [importer_defaults] texture가 손실 0.9라 새 .import는 손실로 생긴다.
무손실 원본(VP8L)을 새로 그렸으면 이 도구를 한 번 돌린다(tests/test_web.gd가 어긋난 것을 잡는다).
.import를 고친 뒤에는 godot --headless --path . --import 로 다시 가져온다.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LOSSY_QUALITY = "0.9"


def is_lossless(webp: pathlib.Path) -> bool:
    head = webp.read_bytes()[:256]
    return b"VP8L" in head  # VP8 = 손실, VP8X는 안에 VP8L(무손실)이나 VP8(손실 + 알파)이 온다


def want(webp: pathlib.Path) -> tuple[str, str | None]:
    return ("0", None) if is_lossless(webp) else ("1", LOSSY_QUALITY)


def main() -> int:
    check = "--check" in sys.argv
    bad: list[str] = []
    fixed = 0
    for imp in sorted((ROOT / "assets").rglob("*.webp.import")):
        src = imp.with_suffix("")
        if not src.exists():
            continue
        text = imp.read_text(encoding="utf-8")
        mode, quality = want(src)
        new = re.sub(r"(?m)^compress/mode=\d+$", "compress/mode=" + mode, text)
        if quality is not None:
            new = re.sub(r"(?m)^compress/lossy_quality=[\d.]+$", "compress/lossy_quality=" + quality, new)
        if new != text:
            bad.append(str(imp.relative_to(ROOT)))
            if not check:
                imp.write_text(new, encoding="utf-8", newline="\n")
                fixed += 1
    if check:
        for b in bad:
            print("압축 설정이 원본과 어긋남:", b)
        return 1 if bad else 0
    print("고친 .import %d개" % fixed)
    return 0


if __name__ == "__main__":
    sys.exit(main())
