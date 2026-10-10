class_name EffectHandler
extends RefCounted
## 효과 타입 하나의 처리기(기반 클래스).
## src/combat/effects/<type>.gd 파일 하나 = 타입 하나. 파일 이름이 데이터의 "type".
## 새 효과 = 파일 하나 추가. 레지스트리·기존 코드는 고치지 않는다.


## 효과를 적용한다. 실제로 무언가 일어났으면 true(아이템 소모 여부 등에 쓰인다).
func apply(_ctx: EffectContext, _data: Dictionary) -> bool:
	return false


## 데이터 형식 검사(검증기가 부른다). 문제 목록을 돌려준다 — 비면 통과.
func validate(_data: Dictionary, _db: GameDatabase) -> PackedStringArray:
	return PackedStringArray()
