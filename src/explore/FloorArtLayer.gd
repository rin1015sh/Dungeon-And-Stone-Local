class_name FloorArtLayer
extends RefCounted
## 그림 층(docs/PROMPT_ART_MAP.md §5.4): 칸마다 어느 재질 변형을 그릴지. 좌표만으로 정해진다(같은 칸 = 늘 같은 그림).
## 변형 수 n(짝수)을 두 무리로 나눠 (x + y)의 홀짝으로 무리를 고르고 무리 안에서 해시로 고른다
## → 가로·세로로 맞닿은 두 칸은 늘 다른 변형(같은 변형 연속 1칸 — FloorArtCheck.MAX_RUN 2 이내).
## 벽 앞면도 같은 규칙(줄을 따라 이웃이 늘 다름). 그리기는 칸마다 부르고, 지도 전체 층은 도구·테스트만 만든다.


static func variant(x: int, y: int, n: int, salt: int = 0) -> int:
	if n <= 1:
		return 0
	var h := absi(hash(Vector3i(x, y, salt)))
	if n % 2 == 1:
		return h % n
	return (h % (n / 2)) * 2 + ((x + y) & 1)


## 지도 전체의 바닥 변형 층(FloorArtCheck 모양): 아틀라스가 있는 바닥 칸만 번호, 나머지 -1.
static func build(map: FloorMap) -> Dictionary:
	var v := PackedInt32Array()
	v.resize(map.width * map.height)
	v.fill(-1)
	for i in map.tiles.size():
		var def := map.defs[map.tiles[i]]
		if not def.is_wall() and not def.art_atlas.is_empty():
			var p := map.pos_of(i)
			v[i] = variant(p.x, p.y, def.art_variants, def.art_salt)
	return {"variants": v, "decor": []}
