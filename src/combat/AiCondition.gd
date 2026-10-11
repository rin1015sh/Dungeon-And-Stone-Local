class_name AiCondition
extends RefCounted
## 몬스터 AI 규칙 조건(기반 클래스). src/combat/ai/<조건>.gd 파일 하나 = 조건 하나.
## 몬스터 데이터 ai: [{"if": "<조건 id>", "value": …, "use": "<스킬 id>", "target": "random|lowest_hp"}]
## 위에서부터 조건이 참이고 쓸 수 있는 첫 규칙을 고른다.


func test(_battle: Battle, _unit: Combatant, _rule: Dictionary) -> bool:
	return false
