extends RefCounted
## 소재마다 생김새(사용자 요청 2026-10-23 "무기 손잡이·날 모양이 다 비슷해 이름을 보기 전엔 구분이 안 된다 — 소재별로 자연스러운 특징을").
## 색만이 아니라 모양·손잡이·표면·장식이 소재 설정을 따른다(materials.json notes — 라이티늄 가볍다·아다만티움 무겁다·아크 용살 …).
## 키(없으면 기본값 BASE):
##   blade_w 날 폭 배율 · tip 날끝(point 보통 · long 길게 좁아짐 · leaf 잎 · chisel 넓고 비스듬히 자름) · edge 날(plain · wavy 물결 · serrated 톱니 · notched 이 빠짐)
##   guard 날밑(bar · slim · crescent 초승달 · block 덩어리 · ornate 소용돌이 · claw 발톱 · wings 뒤로 젖힌 날개)
##   pommel 자루 끝(ball · disc · crescent · block · gem · claw · ring) · grip 손잡이(leather · cloth 흰 천 · wire 쇠줄 · scale 비늘 · bone · dark)
##   head 도끼·미늘창 머리(classic · bearded 아래로 긴 턱 · crescent 큰 반달 · double 양날) · mace 철퇴 머리(flanged · spiked · block · ornate)
##   surface 표면 무늬(Surface.gd) · trim 둘레 장식(Surface.trim) · glow 빛 색(""면 없음) · grip_c 손잡이 색
## 그 밖 아이템(포션 등)은 BASE.

const BASE := {"blade_w": 1.0, "tip": "point", "edge": "plain", "guard": "bar", "pommel": "ball", "grip": "leather", "head": "classic",
	"mace": "flanged", "surface": "none", "trim": "none", "glow": "", "grip_c": ""}

const BY_MATERIAL := {
	# ── 금속 ── 날 모양·날밑·손잡이가 소재 성질을 따른다
	"steel": {"edge": "notched"},  # 1단계 — 투박하고 이가 빠졌다
	"lightium": {"blade_w": 0.72, "tip": "long", "guard": "slim", "pommel": "disc", "grip": "cloth", "grip_c": "#d8d4c8", "surface": "holes"},  # 2배 가벼움 — 가늘고 구멍 뚫린 날
	"airilje": {"tip": "long", "guard": "wings", "pommel": "ring", "grip": "wire", "head": "crescent", "surface": "damascus"},  # 미스릴+강철 합금 — 물결 단조 무늬
	"idium": {"blade_w": 1.15, "guard": "slim", "pommel": "block", "grip": "dark", "head": "bearded", "mace": "block", "surface": "dents", "trim": "rivets"},  # 검게 두드려 편 쇠 — 망치 자국
	"moonstone": {"guard": "crescent", "pommel": "crescent", "grip": "cloth", "grip_c": "#5a5a78", "head": "crescent", "surface": "crescents", "glow": "#d8dcff"},
	"orichalcum": {"tip": "leaf", "guard": "ornate", "pommel": "gem", "grip": "wire", "head": "double", "mace": "ornate", "surface": "runes", "glow": "#ffb060"},
	"mithril": {"blade_w": 0.85, "tip": "leaf", "guard": "wings", "pommel": "disc", "grip": "cloth", "grip_c": "#e8e4dc", "head": "crescent", "surface": "veins", "glow": "#bfe8ff"},
	"adamantium": {"blade_w": 1.45, "tip": "chisel", "edge": "notched", "guard": "block", "pommel": "block", "grip": "dark", "head": "bearded", "mace": "block", "surface": "dents", "trim": "bands"},
	"mystium": {"tip": "long", "guard": "ornate", "pommel": "gem", "grip": "wire", "head": "double", "mace": "ornate", "surface": "filigree", "trim": "gold", "glow": "#e0c8ff"},
	"ark": {"edge": "serrated", "guard": "claw", "pommel": "claw", "grip": "scale", "grip_c": "#2e3a4a", "head": "crescent", "mace": "spiked", "surface": "scales", "glow": "#7ab8ff"},  # 용살 — 용 비늘·발톱, 마력이 흩어지는 푸른 틈
	# ── 가죽 ──
	"tanned": {"surface": "stitch"},
	"wyvern": {"surface": "scales"},
	"troll_hide": {"surface": "warts", "trim": "patches"},
	"drake": {"surface": "big_scales"},
	"ogre": {"surface": "patches", "trim": "rivets"},
	"elder_dragon": {"surface": "big_scales", "trim": "spikes", "glow": "#ff8040"},
	# ── 목재 ──
	"oak": {"surface": "grain"},
	"redwood": {"surface": "grain", "trim": "bands_wood"},
	"ironwood": {"surface": "grain", "trim": "bands"},
	"bortal": {"surface": "knots", "glow": "#b080ff"},
	"artene": {"surface": "grain", "trim": "rope"},
	"world_tree": {"surface": "veins", "trim": "leaves", "glow": "#90e070"},
	# ── 천 ──
	"linen": {"surface": "patches"},
	"spider_silk": {"surface": "web"},
	"frost_wool": {"surface": "stitch", "trim": "fur"},
	"moon_silk": {"surface": "crescents", "glow": "#d8dcff"},
	"spirit_silk": {"surface": "veins", "glow": "#90f0e0"},
	"world_fiber": {"surface": "stitch", "trim": "leaves"},
	# ── 뼈 ──
	"beast_bone": {"surface": "cracks", "trim": "rope", "grip": "bone"},
	"troll_bone": {"surface": "warts", "grip": "bone"},
	"drake_bone": {"surface": "cracks", "trim": "spikes", "grip": "bone", "mace": "spiked"},
	# ── 보석(장신구) ──
	"quartz": {"surface": "facets"},
	"amber": {"surface": "none"},
	"jade": {"surface": "none"},
	"obsidian": {"surface": "facets"},
	"bloodstone": {"surface": "none", "glow": "#ff4040"},
	"bluestone": {"surface": "none", "glow": "#60a0ff"},
}


static func of(mat_id: String) -> Dictionary:
	var s := BASE.duplicate()
	s.merge(BY_MATERIAL.get(mat_id, {}), true)
	return s
