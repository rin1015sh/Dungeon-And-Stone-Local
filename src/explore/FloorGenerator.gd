class_name FloorGenerator
extends RefCounted
## 층 생성기 인터페이스(기반 클래스).
## src/explore/generators/<id>.gd 파일 하나 = 생성기 하나. floors/*.json의 "generator"가 그 id.
## 층 타입을 늘리려면 이 폴더에 파일을 하나 추가하면 된다(레지스트리는 자동으로 찾는다).


## 층 정의(floors/*.json)와 난수로 FloorMap을 만든다. 같은 시드면 같은 결과여야 한다.
func generate(_db: GameDatabase, _floor_def: Dictionary, _rng: Rng) -> FloorMap:
	push_error("FloorGenerator.generate()가 구현되지 않았다")
	return null


## 층 정의의 생성기 전용 값 검사(검증기가 부른다). 문제 목록 — 비면 통과.
func validate(_floor_def: Dictionary, _db: GameDatabase) -> PackedStringArray:
	return PackedStringArray()
