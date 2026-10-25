extends RefCounted
## 시설 건물 그림(정면, 투명 배경, 아래 가장자리 = 땅). tools/paint_city.gd 전용.
## 통일 문법(Parts): 짙은 마름돌 기단 · 같은 창틀/창살 · 같은 잉크 윤곽 · 탁한 회벽과 점판암 · 같은 쇠 걸이 간판.
## 시설마다 특징: 여관 = 목조 2층 돌출과 불 켜진 창 · 도서관 = 높은 고딕 창과 장미창 · 신전 = 첨탑과 색유리 ·
## 상점 = 계단식 박공과 진열창·차양 · 은행 = 거친 돌·기둥·쇠창살 · 훈련장 = 성문 아치·목책 마당 ·
## 대장간 = 큰 굴뚝과 열린 화덕·모루 · 탐험가 길드 = 큰 목조 회관·게시판·깃발(Buildings3).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Parts := preload("res://tools/city_art/Parts.gd")
const Props := preload("res://tools/city_art/Props.gd")
const More := preload("res://tools/city_art/Buildings2.gd")
const Icons := preload("res://tools/city_art/Icons.gd")
const More3 := preload("res://tools/city_art/Buildings3.gd")

const PLASTER := Color("#8b8068")
const SLATE := Color("#3a4044")
const CLAY := Color("#6b3b2d")

## id → 크기(px, 화면 720 높이 기준 1:1)
const SIZES := {"inn": Vector2i(560, 470), "library": Vector2i(440, 520), "temple": Vector2i(430, 600),
	"shop": Vector2i(400, 500), "bank": Vector2i(470, 450), "training": Vector2i(600, 400),
	"smithy": Vector2i(520, 440), "guild": Vector2i(580, 560)}


static func paint(id: String, seed_value: int) -> Paint:
	var s: Vector2i = SIZES.get(id, Vector2i(400, 400))
	var p := Paint.new(s.x, s.y, seed_value)
	match id:
		"inn":
			_inn(p)
		"library":
			_library(p)
		"temple":
			_temple(p)
		"shop":
			More.shop(p)
		"bank":
			More.bank(p)
		"training":
			More.training(p)
		"smithy":
			More3.smithy(p)
		"guild":
			More3.guild(p)
	finish(p)
	return p


## 마감(모든 건물 공통): 바깥 잉크 윤곽 · 색 보정 · 그레인.
static func finish(p: Paint) -> void:
	Ink.light_dir(p, 0.4)
	Ink.silhouette(p, 2)
	Ink.grade(p, 0.3, 1.12)
	Ink.finish(p, 0.03)


## 여관: 돌 1층 + 목조 회벽 2층(앞으로 돌출) + 점판암 지붕과 지붕창 둘, 굴뚝 연기, 불 켜진 창이 많다. 술잔 간판·술통.
static func _inn(p: Paint) -> void:
	var g := float(p.h)
	Parts.chimney(p, 420, 24, 34, 80)
	Parts.roof(p, Paint.poly([Vector2(8, 196), Vector2(96, 62), Vector2(464, 62), Vector2(552, 196)]), Mat.slate(p, SLATE, 0, 62, 18, 11, 0.5))
	for dx: float in [170.0, 330.0]:
		var gab := Paint.poly([Vector2(dx - 44, 160), Vector2(dx - 44, 112), Vector2(dx, 72), Vector2(dx + 44, 112), Vector2(dx + 44, 160)])
		Parts.wall(p, gab, Mat.plaster(p, PLASTER.darkened(0.05)), 0.15)
		Parts.window(p, dx - 16, 112, 32, 38, "square", dx < 200.0)
		Parts.roof(p, Paint.poly([Vector2(dx - 56, 116), Vector2(dx, 64), Vector2(dx + 56, 116), Vector2(dx + 46, 120), Vector2(dx, 78), Vector2(dx - 46, 120)]), Mat.slate(p, SLATE.lightened(0.05), 0, 0, 12, 8, 0.3))
	var up := Paint.rect_poly(24, 194, 512, 134)
	Parts.wall(p, up, Mat.plaster(p, PLASTER, 0.18), 0.12)
	_timber(p, 24, 194, 512, 134, 6)
	var wx := [64.0, 176.0, 316.0, 432.0]
	for i in wx.size():
		Parts.window(p, wx[i], 226, 44, 58, "square", i != 2, i == 2 or i == 0)
	Ink.shade(p, Paint.rect_poly(36, 328, 488, 26), Vector2(0, 328), Vector2(0, 354), 0.0, 0.0)
	var low := Paint.rect_poly(40, 328, 480, g - 328)
	Parts.wall(p, low, Mat.ashlar(p, Color("#6e695e"), 40, 328), 0.1)
	Parts.ledge(p, 18, 322, 524, 8, Color("#5a4636"))
	Ink.shade(p, Paint.rect_poly(40, 330, 480, 34), Vector2(0, 330), Vector2(0, 364), 0.6, 0.0)
	Parts.door(p, 244, 364, 72, g - 364, true, Color("#3b2a1e"), true)
	Parts.steps(p, 280, g, 96, 1, 6)
	Parts.window(p, 92, 382, 54, 56, "arch", true)
	Parts.window(p, 404, 382, 54, 56, "arch", true)
	Parts.plinth(p, 40, g - 22, 480, 22)
	Parts.lantern(p, 228, 360)
	Parts.lantern(p, 332, 360)
	Parts.sign(p, 196, 342, "mug", -1.0)
	Props.barrel(p, 60, g, 34, 44)
	Props.barrel(p, 98, g, 34, 44)
	Props.barrel(p, 79, g - 42, 30, 38)
	Props.bench(p, 380, g, 90)
	Props.crate(p, 486, g, 34)


## 목조 뼈대(기둥·가로대·버팀대): n칸.
static func _timber(p: Paint, x: float, y: float, tw: float, th: float, n: int) -> void:
	var beam := Mat.beam(p)
	var bw := 9.0
	for i in n + 1:
		var bx := x + (tw - bw) * i / n
		p.fill_poly(Paint.rect_poly(bx, y, bw, th), beam)
		Ink.path(p, Paint.rect_poly(bx, y, bw, th), 1.4)
	for yy: float in [y, y + th - bw]:
		p.fill_poly(Paint.rect_poly(x, yy, tw, bw), beam)
		Ink.path(p, Paint.rect_poly(x, yy, tw, bw), 1.4)
	for i in n:
		if i % 2 == 0:
			continue
		var bx0 := x + (tw - bw) * i / n + bw
		var bx1 := x + (tw - bw) * (i + 1) / n
		Ink.line(p, Vector2(bx0, y + th - bw), Vector2(bx0 + (bx1 - bx0) * 0.35, y + bw), 7.0, Color("#2a1e15"), 1.0, 0.3)
		Ink.line(p, Vector2(bx1, y + th - bw), Vector2(bx1 - (bx1 - bx0) * 0.35, y + bw), 7.0, Color("#2a1e15"), 1.0, 0.3)


## 도서관: 밝은 다듬은 돌 3층, 높은 고딕 창, 가운데 박공에 장미창, 시계, 돌계단 위 쌍여닫이 문, 담쟁이. 책 간판.
static func _library(p: Paint) -> void:
	var g := float(p.h)
	var stone := Color("#7a7262")
	Parts.roof(p, Paint.poly([Vector2(6, 176), Vector2(70, 70), Vector2(370, 70), Vector2(434, 176)]), Mat.slate(p, SLATE.darkened(0.05), 0, 70, 16, 10, 0.35))
	Parts.chimney(p, 90, 40, 26, 60, false)
	var body := Paint.rect_poly(20, 170, 400, g - 170)
	Parts.wall(p, body, Mat.ashlar(p, stone, 20, 170, 44, 20), 0.12)
	var gab := Paint.poly([Vector2(140, 176), Vector2(140, 120), Vector2(220, 18), Vector2(300, 120), Vector2(300, 176)])
	Parts.wall(p, gab, Mat.ashlar(p, stone.lightened(0.05), 140, 18, 40, 18), 0.18)
	Parts.roof(p, Paint.poly([Vector2(128, 126), Vector2(220, 6), Vector2(312, 126), Vector2(300, 128), Vector2(220, 24), Vector2(140, 128)]), Mat.slate(p, SLATE, 0, 0, 12, 8, 0.2))
	More.rose_window(p, Vector2(220, 104), 34, false)
	Parts.ledge(p, 12, 168, 416, 9)
	Parts.ledge(p, 12, 320, 416, 8)
	for wx: float in [44.0, 118.0, 290.0, 364.0]:
		Parts.window(p, wx, 196, 34, 100, "gothic", wx == 118.0 or wx == 290.0)
		Parts.window(p, wx, 350, 34, 76, "gothic", wx == 364.0)
	More.clock(p, Vector2(220, 222), 30)
	Parts.door(p, 180, 330, 80, g - 352, true, Color("#3a281b"), false)
	Ink.line(p, Vector2(220, 336), Vector2(220, g - 22), 2.0, Ink.INK, 0.9)
	Parts.steps(p, 220, g, 120, 3, 7)
	Parts.plinth(p, 20, g - 20, 400, 20)
	Props.ivy(p, 20, 180, 70, 260)
	Props.ivy(p, 360, 330, 60, 150)
	Parts.sign(p, 312, 300, "book", 1.0, 44)
	Parts.lantern(p, 166, 336)
	Props.crate(p, 400, g, 30)


## 신전: 왼쪽 높은 종탑과 첨탑(놋쇠 해 문장), 오른쪽 예배당 박공 + 붉은 기와, 큰 색유리 창, 버팀벽, 큰 아치 문, 촛불.
static func _temple(p: Paint) -> void:
	var g := float(p.h)
	var stone := Color("#857c69")
	var tower := Paint.rect_poly(18, 150, 120, g - 150)
	var spire := Paint.poly([Vector2(8, 158), Vector2(78, 18), Vector2(148, 158)])
	Parts.roof(p, spire, Mat.slate(p, SLATE.darkened(0.1), 0, 18, 12, 9, 0.25))
	Ink.line(p, Vector2(78, 14), Vector2(78, 26), 3.0, Color("#8a6d3a"), 1.0, 0.1)
	Icons.draw(p, "sun", Vector2(78, 10), 8)
	Parts.wall(p, tower, Mat.ashlar(p, stone.darkened(0.06), 18, 150, 36, 18), 0.25)
	Parts.window(p, 54, 190, 48, 70, "gothic", false)
	More.bell(p, Vector2(78, 236))
	Parts.window(p, 60, 330, 36, 90, "gothic", true)
	Parts.ledge(p, 10, 150, 136, 9)
	Parts.ledge(p, 10, 290, 136, 7)
	var nave := Paint.poly([Vector2(140, g), Vector2(140, 270), Vector2(282, 120), Vector2(424, 270), Vector2(424, g)])
	Parts.wall(p, nave, Mat.ashlar(p, stone, 140, 120, 42, 20), 0.15)
	Parts.roof(p, Paint.poly([Vector2(128, 278), Vector2(282, 112), Vector2(436, 278), Vector2(424, 282), Vector2(282, 132), Vector2(140, 282)]), Mat.clay(p, CLAY, 0, 0))
	More.stained_glass(p, 238, 200, 88, 150)
	for bx: float in [148.0, 400.0]:
		More.buttress(p, bx, 300, 24, g - 300)
	Parts.door(p, 236, 380, 92, g - 392, true, Color("#3d2a1c"), true)
	Parts.steps(p, 282, g, 140, 3, 6)
	Parts.plinth(p, 18, g - 20, 406, 20)
	Icons.draw(p, "sun", Vector2(282, 166), 20)
	for cx: float in [196.0, 214.0, 350.0, 368.0]:
		Props.candle(p, cx, g - 14)
	Props.ivy(p, 18, 380, 60, 190)

