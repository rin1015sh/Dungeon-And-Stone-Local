# 한글 폰트

이 폴더에 **OFL 라이선스** 한글 폰트 파일(.ttf / .otf)을 넣으면 `UiTheme`이 자동으로 기본 폰트로 쓴다.

현재 번들: `NotoSansKR-Regular.otf` — Noto Sans KR Regular 한국어 서브셋(notofonts/noto-cjk, `Sans/SubsetOTF/KR`), 라이선스 `OFL.txt`(SIL OFL 1.1). `data/render.json`의 `font.path`가 이 파일을 가리킨다.

- 후보: Noto Sans KR(Google Fonts, OFL), Pretendard(OFL), 갈무리 등 픽셀 폰트(OFL)
- 여러 개면 파일 이름 순 첫 번째를 쓴다. 특정 파일을 지정하려면 `data/render.json`의 `font.path`.
- 폰트 라이선스 파일(OFL.txt)도 함께 넣는다.
- 폰트가 없으면 시스템 한글 폰트(맑은 고딕 등)로 대체된다 — 데스크톱에서만 동작하므로 **웹 내보내기 전에는 반드시 넣는다.**
