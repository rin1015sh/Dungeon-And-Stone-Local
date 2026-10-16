extends RefCounted
## 재질 종류별 칠 기본값과 잉크 색(Render·Pen 공용).

const INK_C := Color("#140d0a")

## 재질 기본값: tex(결 세기) · spec(번들) · hatch(빗금 배율) · contrast(명암 폭)
const KINDS := {
	"skin": {"tex": 0.22, "spec": 0.15, "hatch": 1.0, "contrast": 1.0},
	"fur": {"tex": 0.3, "spec": 0.0, "hatch": 0.3, "contrast": 0.6},
	"hair": {"tex": 0.35, "spec": 0.1, "hatch": 0.4, "contrast": 0.9},
	"cloth": {"tex": 0.25, "spec": 0.0, "hatch": 0.9, "contrast": 0.9},
	"leather": {"tex": 0.25, "spec": 0.2, "hatch": 0.8, "contrast": 1.0},
	"metal": {"tex": 0.18, "spec": 0.55, "hatch": 0.7, "contrast": 1.25},
	"bone": {"tex": 0.2, "spec": 0.15, "hatch": 0.9, "contrast": 1.05},
	"stone": {"tex": 0.4, "spec": 0.0, "hatch": 0.8, "contrast": 1.1},
	"wood": {"tex": 0.35, "spec": 0.05, "hatch": 0.6, "contrast": 1.0},
	"slime": {"tex": 0.15, "spec": 1.0, "hatch": 0.25, "contrast": 0.8},
	"glow": {"tex": 0.0, "spec": 0.0, "hatch": 0.0, "contrast": 0.0},
	"eye": {"tex": 0.05, "spec": 1.2, "hatch": 0.0, "contrast": 0.7},
}
