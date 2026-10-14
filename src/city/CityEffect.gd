class_name CityEffect
extends RefCounted
## 도시 활동 효과 하나의 처리기(기반 클래스). src/city/effects/<type>.gd 파일 하나 = 타입 하나(데이터의 "type").
## 새 효과 = 파일 하나 추가. 값이 null(미정)이면 '효과 없음'으로 처리하고 그렇다고 알린다.


func apply(_ctx: CityContext, _data: Dictionary) -> void:
	pass


## 데이터 형식 검사(검증기). null은 오류가 아니다(미정 — 경고 목록은 CityValues.nulls).
func validate(_data: Dictionary, _db: GameDatabase) -> PackedStringArray:
	return PackedStringArray()
