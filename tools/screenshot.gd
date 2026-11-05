extends Node
## 화면 캡처 도구(시각 확인용). 창이 잠깐 떴다가 PNG를 저장하고 닫힌다. 헤드리스에서는 렌더링이 없어 쓸 수 없다.
##   godot --path . res://tools/screenshot.tscn -- --screen=explore --out=C:/tmp/shot.png [--seed=123] [--walk=6] [--debug]
## --prof=<초>: (--rift 등으로 자리를 잡은 뒤) W/A/S/D를 돌려 누르며 걷고 프레임 시간(평균·95%·99%·최대·16.7ms·50ms 넘는 수)·그리기 호출을 찍고 끝(렉 찾기 — CT73)
## --screen=coin [--tails] [--frames=N] --out=<폴더>: 동전 연출을 N 시각마다 찍는다(V25)
## --screen: title(기본) / foundation / create / city / plaza(차원광장 — --opening이면 포탈이 반쯤 열린 순간, --weather 가능) / explore(차원광장을 거쳐 들어간다)
## city: --house=<집 실내 id> 일반 집 실내(CT110) · --facility=<id> --in_at=x,y [--face=…] 실내(CT106)에서 그 칸에 선다(그 방만 보인다) ·
##   --town_at=x,y(칸) [--face=up|down|left|right] 동네 지도에서 선 자리 · --door=<시설 id> 그 문 앞(CT82), --facility=<id> 시설 안, --activity=<id> 그 활동 한 번(패널형은 패널 열기 — --tab=buy|sell 상점 탭), --debug 도시 디버그 패널, --weather=<clear|overcast|fog> 날씨, --look=<1~4> 도시 그림 등급, --travel 특별 시설 가는 창
##   --happen=<사건 id,…> 오늘의 거리 사건을 건다(등롱), --month=<달> --period=<0~2> 날짜(세금 기한 등),
##   --street=<거리 사건 id> 그 거리 사건을 일으킨다(--dialog와 함께 — 없으면 거리 사건은 꺼 둔다)
## --seed: 탐험 층 시드 고정, --walk: 입장 후 오른쪽·아래로 몇 걸음 걸을지, --debug: 디버그 패널 열기,
## --portal: 가장 가까운 2층 포탈로 순간이동(1층 팔 끝 암흑지대 확인), --at=x,y: 그 칸으로 순간이동(고정 지도 좌표 — 공동·이벤트 자리 확인), --interact: 그 자리에서 살피기(E), --torch: 횃불 켜기, --reveal: 안개 걷기, --combat: 옆에 몬스터를 불러 전투 화면, --pause: 일시정지 화면
## --monster=<id>: --combat에서 부를 몬스터(--god = 무적), --mate: 동료를 붙여 행동 정하기 화면, --summon: 전투 화면에서 적 진영에 고블린 증원(카드가 붙는지 확인)
## --up=<포탈 dest>: 1층 그 포탈로 올라가 위층(2층) 도착 자리에서 찍는다(--reveal · --ezoom · --nomon(몬스터 치움)과 함께) · --spotted: (--near=boss|guardian과 함께) 그 보스가 알아채 전투 직전 한 줄이 뜬다(--dialog로 띄운 채), --rift_open=<균열 id>: 옆에 균열 포탈, --rift=<균열 id> [--chapter=n] [--engage[=guardian|riddle]] [--near=guardian|boss|<x>,<y>]: 들어가서 n번째 챕터로(riddle = 수수께끼 대화창, near = 그 무리 몇 칸 앞에 선다)
## (앞 챕터는 디버그로 치움, 출구 조건 아이템은 지급), 첫 조우(또는 그 종류의 조우)와 전투, --trap = 그 챕터 첫 함정을 밟는다(--trap=all = 모두 드러내기만), --murals = 벽화 힌트를 다 본 상태
## --near=mon:<id>: 그 몬스터가 낀 무리 앞에 선다 · --near=chest [--open_chest=<초>] [--pick=0|1]: 첫 상자 아래 칸(열고 그 초 뒤 — 앞뒤 고르기 창, --pick이면 고른 뒤 동전 연출, --dialog와 함께)
## --slay: (균열 마지막 챕터, --near=guardian과 함께) 수호자를 쓰러뜨린 것으로 해 그 자리에 생긴 탈출 포탈을 본다
## --lord: 맵에 계층군주 소환(붉은 수정·시야 2m) — --lord_at=<초> --dialog: 소환 연출을 그 시각에 멈춰 찍는다, --meters: 전투 화면에서 탐험가 게이지를 채우고 보스를 P2로(게이지 표시 확인)
## --dialog: 하단 대화창을 넘기지 않고 띄운 채(없으면 모든 대화창이 기다리지 않는다), --advance=N: 도시 활동 결과 대화창을 N쪽 넘겨서
## --equip=<아이템 id>: 주무기 칸에 그 무기(장비 인형 그림 크기), --tooltip: 아이템 툴팁(비교) 띄우기, --menu: Tab 메뉴 열기(--menu=party|character|inventory = 커서를 그 쪽에, --cell=<x>,<y> = 소지품 커서 칸, --ask = 그 칸에서 Enter)
## --monument[=ready|lord]: 대현자 기념비 곁에서 살피기(마석 넷 · ready = 네 종 처치 · lord = 균열 수호자 넷도) — 기념비 고르기 창
## --codex[=<분야 id>]: 도감(B) 열기 — 분야면 서적 쪽(--books = 서적 전부 읽은 것으로, --pick=<번호> = 그 대목에 커서, UI32 · --known --monster=<id> = 그 몬스터를 다 안다)
##   (--loot: 마석·장비 몇 개를 가방에 넣고 도감 기록을 채운다, --give=id,id: 그 아이템들만 든 큰 가방)
## --essence: 레벨 3으로 올리고 정수 하나 흡수 — --character와 함께
## --dust[=초]: 첫 적을 쓰러뜨려 빛 먼지로 흩어지는 중간을 찍는다
## --motions=<동작,…> [--motion_t=초]: 아군 탐험가마다 전투 동작(PartySprite — idle·stance·thrust·guard·swing·spell·damage·wait·escape·fall)
## --race=<종족 id>: 캐릭터 만들기에서 그 종족을 고른다
## --toast=<id,id,…>: 허기·피로 단계 알림(좌하단 ConditionToast)을 띄운 채(peckish·hungry·famished·starving·tired·weary·spent·collapse)
## --banner=<스킬 이름>: --combat에서 위쪽 스킬 알림창을 띄운다
## --known: --combat --monster=<id>에서 그 몬스터를 조사·상성까지 알고 있는 상태(무대엔 이름뿐 — 도감 B에서만 보인다)
## --parties: 곁에 신참 파티·약탈자·갓 죽은 탐험가를 세운다(다른 탐험가 맵 그림 확인 — --hostile이면 약탈자가 다가와 통행세 창)
## --meal=<요리 id>: 여관 요리 효과(Meals)를 건 채로 탐험 화면(--menu=character와 함께), --meal_pick=<요리 id>: 도시 여관 식사에서 그 요리(그림 확인)
## --statuses=<id,id>: --combat에서 적 모두에게 그 상태(머리 위 아이콘 확인), --party_statuses=<id,id>: 아군 모두에게
## --extra_turn: 지금 차례를 추가 차례로 표시해 파티 창 이름 옆 표시를 본다
## --summon=N: 적 N마리 증원(--summon=id,id면 그 몬스터들 — --rift … --engage 균열 조우에서도), --ally_summon[=id,id]: 아군 소환수(기본 병사 시체), --win: 적을 모두 쓰러뜨려 승리 결과 칸(보상)
## --mate[=종족,종족]: 그 종족 동료들을 붙인다(값이 없으면 인간 하나 + 행동 정하기 화면)
## --heal: --combat에서 참가자 모두 생명력을 깎았다가 25, 영혼력을 깎았다가 12 채운다(초록·파랑 회복 숫자 확인, UI46)
## --hit[=초]: 첫 적을 기본 공격하고 그 초만큼 기다려 찍는다(피해 숫자 확인 — 길게 기다리면 적의 반격까지)
## --drops[=who]: (--win과 함께) 첫 몬스터 자리에 정수 하나를 더 떨어뜨리고 "획득할까?" 창이 뜬 채 찍는다(=who: 획득한다를 눌러 받을 사람 고르기 창)
## --many: (--essence와 함께) 만렙 + 수호자 정수 여럿, --skills: 전투 행동창에서 스킬 목록, --keys=a,b: 행동창 키 액션 차례로
## --lock: (--essence와 함께) 정수를 하나 더 흡수한 뒤 레벨 1로 내려 잠긴 정수를 보인다
## --shots=<목록 json> --out=<폴더>: (explore) 장면 목록을 한 번에 찍어 <폴더>/<name>.png로(tools/ShotList.gd, 목록 예 tools/shots/floor1.json)
##   --rift=<균열 id> [--chapter=n]과 함께면 그 챕터 안에서 찍는다(목록의 장면마다 "rift"·"chapter"가 있으면 맞는 것만 — tools/shots/rift_void.json)

const ShotList := preload("res://tools/ShotList.gd")

var _main: Control
var _quick := false  ## --hit: 떠오른 숫자가 사라지기 전에 바로 찍는다
var _args: Dictionary = {"screen": "title", "out": "user://screenshot.png", "seed": "0", "walk": "0"}


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--"):
			var kv := arg.trim_prefix("--").split("=", true, 1)
			_args[kv[0]] = kv[1] if kv.size() > 1 else "true"
	GameState.debug_seed_override = str(_args["seed"]).to_int()
	CityAmbient.enabled = false
	DialogueBox.auto_skip = not _args.has("dialog")  # --dialog: 하단 대화창(알림·전투 안내·시설 결과)을 넘기지 않고 띄운 채 찍는다
	_main = (load("res://src/Main.tscn") as PackedScene).instantiate()
	add_child(_main)
	_run.call_deferred()


func _run() -> void:
	await _frames(3)
	var screen := str(_args["screen"])
	if screen == "coin":  # --screen=coin [--tails] --out=<폴더>: 동전 연출(CoinFlip)을 정해진 시각마다 찍어 <폴더>/coin_<번호>.png(V25 — 느린 캡처에서도 시각이 정확하다)
		await _coin_frames()
		return
	if screen != "title":
		var title := _main.current_screen() as TitleScreen
		if screen == "foundation":
			title.foundation_requested.emit()
		else:
			title.new_game_requested.emit()
		await _frames(3)
	if screen in ["explore", "city", "plaza"]:
		var create := _main.current_screen() as CharacterCreateScreen
		if _args.has("race"):  # --race=<종족 id>: 그 종족으로 시작(탐험 맵 몸 그림 확인)
			create._race_opt.select(create._race_ids.find(str(_args["race"])))
			create._race_opt.item_selected.emit(create._race_opt.selected)
			await _frames(2)
		for b: Node in create.find_children("*", "Button", true, false):
			if (b as Button).text == Strings.t("create.enter"):
				(b as Button).pressed.emit()
		await _frames(3)
	if screen == "city":
		await _city(_main.current_screen() as CityScreen)
	if screen == "plaza":
		var c := _main.current_screen() as CityScreen
		if _args.has("weather"):
			c.state.weather = str(_args["weather"])
		if _args.has("returning"):  # --returning[=N]: 미궁에서 돌아온 차원광장 — 길드 정산 대화창 N쪽째(--dialog와 함께, CT58)
			c.pc.inventory.add("magic_stone_9", 7)
			c.pc.inventory.add("magic_stone_8", 2)
			_main._return_to_city()
			await get_tree().create_timer(1.5).timeout
			for k in str(_args["returning"]).to_int() * 2 if str(_args["returning"]).is_valid_int() else 0:
				for db: Node in _main.find_children("*", "DialogueBox", true, false):
					(db as DialogueBox).advance()
				await _frames(2)
			await get_tree().create_timer(1.0).timeout
		else:
			c.dungeon_requested.emit()
			await _frames(3)
			var plaza := _main.current_screen() as PlazaScreen
			if _args.has("opening"):
				await get_tree().create_timer(2.0).timeout
			else:
				plaza.open_now()
				await _frames(30)
	if screen == "explore":
		(_main.current_screen() as CityScreen).dungeon_requested.emit()
		await _frames(3)
		var plaza_screen := _main.current_screen() as PlazaScreen
		plaza_screen.open_now()
		plaza_screen.enter_requested.emit()
		await _frames(3)
		var explore := _main.current_screen() as ExploreScreen
		if _args.has("shots"):  # 장면 목록 일괄 캡처 → --out 폴더(--rift면 그 균열 챕터에 들어가서)
			if _args.has("rift"):
				explore = await _enter_rift(explore)
			get_tree().quit(await ShotList.run(self, explore, str(_args["shots"]), str(_args["out"])))
			return
		if _args.has("up"):  # --up=<포탈 dest>(예 floor2_south): 그 1층 포탈로 올라가 위층 도착 자리에서 찍는다(FloorTravel)
			var ps := explore.session
			for p: Dictionary in ps.map.portals:
				if str(p.get("dest", "")) == str(_args["up"]):
					ps.relocate(p["pos"])
					ps.interact()
			for f in 60:
				await get_tree().process_frame
				if _main.current_screen() is ExploreScreen and (_main.current_screen() as ExploreScreen).session != ps:
					break
			await _frames(4)
			explore = _main.current_screen() as ExploreScreen
			explore.dialog().clear()
			print("[up] %s" % JsonUtil.get_str(explore.session.floor_def, "id"))
			if _args.has("nomon"):  # --nomon: 위층 몬스터를 모두 치운다(장식 · 지형만 찍기 — 순간이동한 자리에서 전투가 걸리지 않게)
				explore.session.monsters.groups.clear()
				explore.session.monsters_enabled = false
			if _args.has("reveal"):
				ExploreDebug.reveal(explore.session)
				explore.session.refresh_view()
			if _args.has("ezoom"):
				for c: Node in explore.find_children("*", "Camera2D", true, false):
					(c as Camera2D).zoom = Vector2.ONE * str(_args["ezoom"]).to_float()
			await _frames(6)
			if _args.has("cam"):  # --cam=x,y: 탐험 카메라를 그 칸(지도 좌표)에 고정해 찍는다(지도 전체 이어 붙이기 — --ezoom과 함께)
				var cxy := str(_args["cam"]).split(",")
				var fv: FloorView = explore.get("_view")
				fv.stream.radius = 40  # 지도 전체를 그린다(보통은 플레이어 둘레 청크만)
				fv.stream.active = Rect2i()
				fv.stream.around(Vector2i(cxy[0].to_int(), cxy[1].to_int()))
				await _frames(10)
				for c: Node in explore.find_children("*", "Camera2D", true, false):
					var cam := c as Camera2D
					cam.position_smoothing_enabled = false
					cam.top_level = true
					cam.global_position = Vector2(cxy[0].to_float(), cxy[1].to_float()) * float(explore.session.db.render["view"]["floor_tile_px"][0])
				await _frames(4)
		if _args.has("torch"):
			explore.session.use_category("light")
		var steps := str(_args["walk"]).to_int()
		for i in steps:
			explore.session.pass_time(explore.session.move_hours())  # 이동 간격을 채운다(실시간을 기다리지 않음)
			var dir := Vector2i(1, 0) if i % 2 == 0 else Vector2i(0, 1)
			if not explore.session.try_move(dir):
				explore.session.try_move(Vector2i(0, -1) if i % 2 == 0 else Vector2i(-1, 0))
			await _frames(2)
		if _args.has("portal"):
			ExploreDebug.teleport(explore.session, ExploreDebug.nearest_portal(explore.session))
			await _frames(2)
		if _args.has("at"):
			var xy := str(_args["at"]).split(",")
			ExploreDebug.teleport(explore.session, Vector2i(xy[0].to_int(), xy[1].to_int()))
			await _frames(2)
		if _args.has("monument"):  # --monument[=ready|lord]: 기념비 아래 칸에서 살피기 — 마석 넷(ready면 네 종 처치, lord면 수호자 넷도) — 고르기 창(RF22·DF17)
			var ms := explore.session
			for lm: Dictionary in ms.map.landmarks:
				if str(lm["id"]) == "sage_monument":
					ExploreDebug.teleport(ms, (lm["pos"] as Vector2i) + Vector2i(0, 1))
			var off := Monument.offering(ms)
			ms.player.inventory.add(JsonUtil.get_str(off, "item"), JsonUtil.get_int(off, "count", 1))
			if str(_args["monument"]) in ["ready", "lord"]:
				for m: Variant in JsonUtil.get_array(off, "kills"):
					ms.kills[str(m)] = 1
			if str(_args["monument"]) == "lord":
				for rid in RiftWatch.rifts_for(ms):
					ms.player.progression.record_kill(ms.db, JsonUtil.get_str(ms.db.get_entry("rifts", rid), "guardian"))
			await _frames(2)
			ms.interact()
			await _frames(4)
		if _args.has("interact"):
			explore.session.interact()
			await _frames(4)
		if _args.has("reveal"):
			ExploreDebug.reveal(explore.session)
		if _args.has("parties"):  # 곁에 신참 파티·약탈자·갓 죽은 탐험가(FieldParties 맵 그림 확인)
			var ps := explore.session
			var seen := func(c: Vector2i) -> bool: return ps.map.visible_now[ps.map.idx(c)] != 0 and (c - ps.pos).length_squared() >= 6
			ps.parties._spawn(ps, FieldParties.ROOKIE, FieldRoutes.random_cell_near(ps.map, ps.rng, ps.pos, 5, seen))
			var rg := ps.parties._spawn(ps, FieldParties.RAIDER, FieldRoutes.random_cell_near(ps.map, ps.rng, ps.pos, 5, seen))
			if rg != null and not _args.has("hostile"):  # 그림만 본다(--hostile이면 다가와 통행세 선택 창)
				rg.party["paid"] = true
			ps.parties.drop_corpse(ps, FieldRoutes.random_cell_near(ps.map, ps.rng, ps.pos, 4, seen), false)
			ps.refresh_view()
			await _frames(4)
		if _args.has("meal"):  # --meal=<요리 id>: 여관 요리 효과를 건 채(캐릭터 쪽 "걸린 상태")
			Meals.eat(explore.session.player, str(_args["meal"]))
		if _args.has("give"):  # --give=id,id: 가방에 그 아이템들(아이템 그림 확인) — 가방 크기는 기본(--bag=WxH면 그 크기)
			var bag := str(_args.get("bag", "%dx%d" % [int(explore.session.db.bal("inventory.width", 10)), int(explore.session.db.bal("inventory.height", 6))])).split("x")
			explore.session.player.inventory = Inventory.new(explore.session.db, int(bag[0]), int(bag[1]))
			for gid in str(_args["give"]).split(","):
				explore.session.player.inventory.add(gid)
		if _args.has("equip"):  # --equip=<아이템 id>: 그 무기를 주무기 칸에 낀다(장비 인형 그림 크기 확인 — UI49)
			var epc := explore.session.player
			epc.equipment.equip(epc.stats, str(_args["equip"]), "main_hand")
		if _args.has("loot"):
			var pc := explore.session.player
			pc.inventory.add("magic_stone_9", 7)
			pc.inventory.add("steel_spear")
			pc.inventory.add("copper_ring")
			pc.inventory.add("iron_helm")
			pc.inventory.add("medium_potion", 2)
			for id: String in ["goblin", "blade_wolf"]:
				pc.knowledge.see(id)
				pc.progression.gain(pc, pc.progression.record_kill(pc.db, id))
			pc.knowledge.learn_stats("blade_wolf")
			pc.knowledge.learn_affinity("blade_wolf", "lightning", 1.5)
		if _args.has("essence"):
			var epc := explore.session.player
			epc.set_level(3)
			epc.essences.absorb(epc, {"essence": "gnome", "color": "blue", "stats": {"p_res": 3, "m_res": 1, "agi": 2}})
			if _args.has("many"):  # 만렙 + 수호자 정수 여럿(스킬이 많은 행동창 확인)
				epc.set_level(11)
				for id: String in ["goblin", "ghoul", "blade_wolf", "chimera_wolf", "blater", "bone_knight"]:
					epc.essences.absorb(epc, {"essence": id, "color": "rainbow", "stats": {}})
			if _args.has("lock"):
				epc.essences.absorb(epc, {"essence": "ghoul", "color": "red", "stats": {"agi": 3}})
				epc.set_level(1)
		if _args.has("codex"):
			if _args.has("known") and _args.has("monster"):  # --known --monster=<id>: 그 몬스터를 다 아는 도감(상성 줄 확인)
				var kn := explore.session.player.knowledge
				kn.learn_all(DataRegistry.db, str(_args["monster"]))
			if _args.has("books"):
				for id: String in DataRegistry.db.get_collection("city_info"):
					explore.codex().known.append(id)
			var sec := str(_args["codex"])
			explore.codex().open(sec if CityInfo.field_ids(DataRegistry.db).has(sec) else CodexIndexPage.MONSTERS)
			await get_tree().process_frame
			if explore.codex().page() is LorePage:
				for i in int(str(_args.get("pick", "0"))):
					explore.codex().page().nav(Vector2i.DOWN)
		if _args.has("menu"):
			var page := str(_args["menu"]) if str(_args["menu"]) in GameMenu.PAGES else "inventory"
			if _args.has("party"):  # --party=<종족[:템플릿],…>: Tab 메뉴 왼쪽 아군 목록에 동료를 붙여 본다(UI26 — 줄 순서 C16: 궁수는 후위)
				for spec in str(_args["party"]).split(","):
					var bits := spec.split(":")
					var cls := bits[1] if bits.size() > 1 else "warrior"
					var mate := PlayerCharacter.create(DataRegistry.db, bits[0], cls, "동료 " + spec, {"str": 9, "agi": 8, "p_res": 9, "m_res": 6, "int": 6})
					mate.pool.set_current("hp", mate.pool.get_max("hp") * 0.6)
					explore.menu().party.append(mate)
				explore.menu().party = GameMenu.by_row(explore.menu().party)
			if _args.has("hunger"):  # --hunger=<허기 0~100>: 아군 모두 그만큼 배고픈 상태(화면 허기 = 최대 − 포만도, UI35)
				for a: PlayerCharacter in [explore.session.player] + explore.menu().party:
					a.pool.set_current("hunger", a.pool.get_max("hunger") - float(str(_args["hunger"])))
			explore.menu().open(page)
			if _args.has("grab") and page == "character":  # --grab: 캐릭터 쪽 첫 정수 카드를 집은 상태(순서 바꾸기 — UI34)
				await get_tree().process_frame
				explore.menu().focus("character")
				explore.menu().character().nav(Vector2i.DOWN)  # 요약 → 첫 카드(UI39)
				explore.menu().character().confirm()
			if _args.has("ally"):  # --ally=<번호>: 그 아군을 고른 상태
				await get_tree().process_frame
				explore.menu().show_ally(explore.menu().party[int(str(_args["ally"]))])
			if _args.has("cell"):
				var xy := str(_args["cell"]).split(",")
				await get_tree().process_frame
				explore.menu().inventory().cursor_to_cell(Vector2i(int(xy[0]), int(xy[1])))
				if _args.has("ask"):  # 그 칸 아이템의 할 일 고르기 창
					explore.menu().inventory().confirm()
		if _args.has("tooltip"):  # 툴팁 모양 확인: 가방의 창(장착 중인 무기와 비교)
			var tip := ItemTooltip.build(explore.session.db, "steel_spear", explore.session.player)
			explore.add_child(tip)
			tip.position = Vector2(80, 80)
		if _args.has("pause"):
			explore.set_paused(true)
		if _args.has("rift_open"):
			explore.session.rifts.force_open(explore.session, str(_args["rift_open"]), explore.session.pos)
		if _args.has("rift"):
			explore = await _enter_rift(explore)
		if _args.has("prof"):  # --prof=<초>: 그 자리에서 W/A/S/D를 돌려 누르며 걷고 프레임 시간을 찍는다(렉 찾기 — CT73)
			await _profile_walk(float(str(_args["prof"])))
			get_tree().quit(0)
			return
		if _args.has("lord"):
			explore.session.lord.summon(explore.session)
			if _args.has("lord_at"):  # --lord_at=<초>: 소환 연출(LordRiseFx)을 그 시각에 멈춰 찍는다(--dialog와 함께 — 느린 캡처에서도 시각이 정확하다, V27)
				await _frames(3)
				for n: Node in _main.find_children("*", "LordRiseFx", true, false):
					var fx := n as LordRiseFx
					fx.set_process(false)
					fx._t = float(str(_args["lord_at"]))
					fx._process(0.0)
					fx.set_process(false)
		if _args.has("combat"):
			GameState.debug_invulnerable = _args.has("god") or GameState.debug_invulnerable  # --god: 무적(계층군주처럼 첫 차례에 쓰러뜨리는 적을 찍을 때)
			if GameState.debug_invulnerable:  # 디버그 패널 무적과 같게 — 생명력이 1 밑으로 내려가지 않는다(플래그만으로는 막지 못했다)
				explore.session.player.pool.set_min_value("hp", 1.0)
			if _args.has("known") and _args.has("monster"):  # --known: 그 몬스터를 조사·상성까지 알고 있다(도감 B에만 보인다 — 무대엔 이름뿐, UI22)
				explore.session.player.knowledge.learn_all(explore.session.db, str(_args["monster"]))
			ExploreDebug.spawn_and_engage(explore.session, str(_args.get("monster", "")))
			if _args.has("meters"):
				await _frames(3)
				for n: Node in _main.find_children("*", "", true, false):
					if n is CombatScreen:
						var cb := (n as CombatScreen).battle
						var me := cb.side_units(Combatant.SIDE_PARTY)[0]
						me.actor.meters["dread_fear"] = 45.0
						me.actor.meters["dread_plague"] = 16.0
						var boss := cb.side_units(Combatant.SIDE_ENEMY)[0]
						boss.actor.pool.set_current("hp", boss.actor.pool.get_max("hp") * 0.6)
						BossHooks.check_all(cb)
						BossHooks.turn_end(cb, boss, false)
			if _args.has("summon"):
				await _summon()
		if _args.has("summon") and _args.has("engage") and not _args.has("combat"):  # 균열 조우 전투에도 증원(줄 배치 확인)
			await _summon()
		if _args.has("mate"):  # 동료를 하나 붙여 "행동 정하기"(첫 사람 방어 → 동료 차례)를 본다
			await _frames(5)
			for n: Node in _main.find_children("*", "", true, false):
				if n is CombatScreen:
					var ms := n as CombatScreen
					var mv := str(_args["mate"])
					for race in ("human" if mv == "true" else mv).split(","):
						var mate := PlayerCharacter.create(DataRegistry.db, race, "warrior", "동료", {"str": 9, "agi": 8, "p_res": 9, "m_res": 6, "int": 6})
						ms._add_unit(ms.battle.add(mate, Combatant.SIDE_PARTY))
					if mv == "true":
						ms._menu.close()
						ms._begin_planning(ms.battle.current)
						ms._on_chosen({"kind": "guard"})
		if _args.has("statuses") or _args.has("party_statuses"):  # 머리 위 상태 아이콘(UI24)
			await _frames(3)
			for n: Node in _main.find_children("*", "", true, false):
				if n is CombatScreen:
					var ss := n as CombatScreen
					for pair: Array in [["statuses", Combatant.SIDE_ENEMY], ["party_statuses", Combatant.SIDE_PARTY]]:
						if not _args.has(pair[0]):
							continue
						for u: Combatant in ss.battle.side_units(int(pair[1])):
							for sid in str(_args[pair[0]]).split(","):
								u.actor.statuses.apply(sid)
					ss._refresh()
		if _args.has("drops"):
			for n: Node in _main.find_children("*", "", true, false):
				if n is CombatScreen:
					var ds := n as CombatScreen
					var orig := ds.reward_provider
					ds.reward_provider = func(r: String, k: Array[String], c: Array[String]) -> Array:
						var msgs: Array = orig.call(r, k, c)
						var ess := EssenceDrop.make(ds.battle.db, EssenceDrop.essence_of_monster(ds.battle.db, k[0]), "", Rng.new(7), false) if not k.is_empty() else {}
						if not ess.is_empty():
							ds.drops.append({"kind": "essence", "inst": ess, "slot": 0, "monster": k[0]})
						return msgs
		if _args.has("dust"):  # 쓰러지는 연출(DeathDust): 첫 적을 쓰러뜨리고 --dust초(기본 0.5) 뒤에 찍는다
			await _frames(10)
			for n: Node in _main.find_children("*", "", true, false):
				if n is CombatScreen:
					var dcs := n as CombatScreen
					var du: Combatant = dcs.battle.side_units(Combatant.SIDE_ENEMY)[0]
					du.actor.pool.set_current("hp", 0.0)
					du.actor.dead = true
					dcs._stage.remove_unit(du)
			var dv := str(_args["dust"])
			await get_tree().create_timer(dv.to_float() if dv.is_valid_float() else 0.5).timeout
			for d: Node in _main.find_children("*", "DeathDust", true, false):
				d.set_process(false)  # 찍기 전 남은 기다림 동안 흩어지지 않게 그 순간에 멈춘다
		if _args.has("win"):  # 전투 승리 결과 칸(보상 안내) 확인: 적을 모두 쓰러뜨리고 방어로 차례를 넘긴다
			await _frames(10)
			for n: Node in _main.find_children("*", "", true, false):
				if n is CombatScreen:
					var wb := (n as CombatScreen).battle
					for u in wb.side_units(Combatant.SIDE_ENEMY):
						u.actor.pool.set_current("hp", 0.0)
					(n as CombatScreen)._on_chosen({"kind": "guard"})
		if _args.has("drops"):
			for k in 300:
				if not _main.find_children("*", "ChoicePopup", true, false).is_empty():
					break
				await _frames(1)
			if str(_args["drops"]) == "who":
				await _frames(2)
				var ev := InputEventAction.new()
				ev.action = "menu_confirm"
				ev.pressed = true
				Input.parse_input_event(ev)
				await _frames(4)
		if _args.has("drain"):  # 영혼력을 바닥내 "대가 부족" 칸을 보인다
			explore.session.player.pool.set_current("soul", 0.0)
		if _args.has("skills") or _args.has("extra_turn"):  # 전투 행동창에서 스킬 목록을 띄운다(정수 스킬 표시 확인 — --mate=<종족>이면 동료의 목록: 대화·조사·도주 없음)
			for n: Node in _main.find_children("*", "", true, false):
				if n is CombatScreen:
					var ks := n as CombatScreen
					for k in 400:  # 행동 정하기가 열릴 때까지
						if not ks._planning.is_empty():
							break
						await _frames(1)
					if _args.has("mate") and ks._plan_i == 0 and ks._planning.size() > 1:
						ks._on_chosen({"kind": "guard"})
					if _args.has("extra_turn"):  # 파티 창 이름 옆 "추가 턴" 표시(C14) — 지금 차례를 추가 차례로 보고 찍는다
						(ks._planning[ks._plan_i] as Combatant).extra_turn = true
						ks._roster.set_current(ks._planning[ks._plan_i])
					await _frames(2)
					if _args.has("skills"):
						var sv := str(_args["skills"])
						ks._menu._skills(sv.to_int() if sv.is_valid_int() else 0)  # --skills=N: N번째 칸에 커서(설명줄 확인)
		if _args.has("hit"):
			for n: Node in _main.find_children("*", "", true, false):
				if n is CombatScreen:
					var hs := n as CombatScreen
					for k in 400:  # 내 차례(행동 정하기)가 열릴 때까지
						if not hs._planning.is_empty():
							break
						await _frames(1)
					hs._on_chosen({"kind": "skill", "skill": Battle.BASIC_ATTACK, "target": hs.battle.side_units(Combatant.SIDE_ENEMY)[0]})
			var hv := str(_args["hit"])
			await get_tree().create_timer(hv.to_float() if hv.is_valid_float() else 0.25).timeout
			_quick = true
		if _args.has("heal"):  # --heal: 전투 참가자 모두 생명력을 깎았다가 일부 채워 초록 회복 숫자(UI46)를 본다
			await _frames(10)
			for n: Node in _main.find_children("*", "", true, false):
				if n is CombatScreen:
					for hu: Combatant in (n as CombatScreen).battle.units:
						hu.actor.pool.modify("hp", -40.0, "debug")
						hu.actor.pool.modify("hp", 25.0, "debug")
						if hu.actor.pool.has_resource("soul"):
							hu.actor.pool.modify("soul", -20.0, "debug")
							hu.actor.pool.modify("soul", 12.0, "debug")
			await get_tree().create_timer(0.25).timeout
			_quick = true
		if _args.has("keys"):  # 행동창 키 입력 흉내: --keys=menu_right,menu_right,menu_confirm (쪽 넘김·커서 확인)
			await _frames(10)
			for a: String in str(_args["keys"]).split(","):
				var kev := InputEventAction.new()
				kev.action = a
				kev.pressed = true
				Input.parse_input_event(kev)
				await _frames(2)
		if _args.has("debug"):
			var ev := InputEventAction.new()
			ev.action = "debug_toggle"
			ev.pressed = true
			Input.parse_input_event(ev)
		if not _quick:
			await _frames(30)
	if _args.has("target"):  # --target: (--combat과 함께) 첫 적을 대상으로 고른 상태 — 흰빛(UI40)
		await _frames(3)
		for n: Node in _main.find_children("*", "CombatScreen", true, false):
			var tcs := n as CombatScreen
			var foe: Combatant = tcs.battle.side_units(Combatant.SIDE_ENEMY)[0]
			tcs._stage.view(foe).set_targeted(true)
		await get_tree().create_timer(float(str(_args["target"])) if str(_args["target"]).is_valid_float() else 0.55).timeout
	if _args.has("motions"):  # --motions=<동작,동작,…>: (--combat과 함께) 아군 탐험가 차례대로 그 동작(PartySprite — fall = 쓰러짐), --motion_t초 뒤 찍는다(UI41)
		await _frames(3)
		for n: Node in _main.find_children("*", "CombatScreen", true, false):
			var mcs := n as CombatScreen
			var names := str(_args["motions"]).split(",")
			var k := 0
			for u: Combatant in mcs.battle.side_units(Combatant.SIDE_PARTY):
				var mv := mcs._stage.view(u)
				if mv == null or k >= names.size():
					continue
				if names[k] == "fall":
					u.actor.pool.set_current("hp", 0.0)
					u.actor.dead = true
					mv.fall()
				else:
					mv.motion(names[k])
				k += 1
		await get_tree().create_timer(float(str(_args.get("motion_t", "0.2")))).timeout
	if _args.has("banner"):  # --banner=<스킬 이름>: 위쪽 스킬 알림창(SkillBanner)을 띄운 채(찍기 바로 전에 — 금방 사라진다)
		for n: Node in _main.find_children("*", "CombatScreen", true, false):
			(n as CombatScreen).battle.message.emit("combat.use_skill", {"name": "", "skill": str(_args["banner"])}, "system")
	if _args.has("toast"):  # --toast=<id,id,…>: 허기·피로 단계 알림(ConditionToast — 예: peckish,famished,collapse)을 좌하단에 띄운 채
		for id: String in str(_args["toast"]).split(","):
			(_main._toast as ConditionToast).notice(id, "시험")
	await _frames(2 if _quick else 6)
	var img := get_viewport().get_texture().get_image()
	var out := str(_args["out"])
	var err := img.save_png(out)
	print("스크린샷 %s → %s" % ["저장" if err == OK else "실패(%d)" % err, ProjectSettings.globalize_path(out)])
	get_tree().quit(0 if err == OK else 1)


func _coin_frames() -> void:
	var root := Control.new()
	_main.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("#3a2c28")
	root.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	DialogueBox.auto_skip = false  # 자동 넘김이면 CoinFlip이 첫 프레임에 끝나 버린다
	var c := CoinFlip.new()
	c.heads = not _args.has("tails")
	root.add_child(c)
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.set_process(false)
	await _frames(1)
	var out := str(_args["out"])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var n := int(str(_args.get("frames", "24")))
	for i in n:
		c._t = c._total * float(i) / float(n)
		c.queue_redraw()
		await _frames(2)
		get_viewport().get_texture().get_image().save_png("%s/coin_%02d.png" % [out, i])
	print("동전 %d장 → %s" % [n, out])
	get_tree().quit()


func _city(city: CityScreen) -> void:
	await _frames(2)
	var st := city.state
	if _args.has("month"):
		st.month = str(_args["month"]).to_int()
		st.period = str(_args.get("period", "0")).to_int()
	if _args.has("happen"):
		st.happenings.assign(str(_args["happen"]).split(","))
	if _args.has("look"):  # --look=<1~4>: 도시 그림 등급(CT63 — 디버그 임시값)
		st.set_override("city/district/look", str(_args["look"]).to_int())
	st.changed.emit()
	var faces := {"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT, "right": Vector2i.RIGHT}
	if _args.has("town_at"):  # --town_at=x,y(칸) --face=…: 동네 지도에서 선 자리·보는 쪽(CT82)
		var at := str(_args["town_at"]).split(",")
		city.town().pos = Vector2(at[0].to_float(), at[1].to_float())
		city.town().facing = faces.get(str(_args.get("face", "down")), Vector2i.DOWN)
	if _args.has("door"):  # --door=<시설 id>: 그 문 앞에서 문을 본다
		city.town().stand_before(str(_args["door"]))
	if _args.has("zoom"):  # --zoom=<배율>: 동네 카메라 배율만 바꿔 찍는다(건물 전체 보기 — 그림 확인용)
		for c: Node in city.town().find_children("*", "Camera2D", true, false):
			(c as Camera2D).zoom = Vector2.ONE * str(_args["zoom"]).to_float()
	await _frames(3)
	if _args.has("travel"):  # --travel: 구역문에서 Enter — 특별 시설로 가는 창(CT63)
		city.offer_travel()
		await _frames(4)
	if _args.has("weather"):
		city.state.weather = str(_args["weather"])
		city.state.changed.emit()
	if _args.has("meal_pick"):  # --meal_pick=<요리 id>: 여관 식사에서 그 요리가 나온다(요리 그림 확인)
		Meals.force_pick = str(_args["meal_pick"])
	if _args.has("house"):  # --house=<실내 id>: 일반 집 실내를 바로 연다(잠금과 상관없이 — 그림 확인용, CT110)
		var kinds := JsonUtil.get_dict(CityValues.city_section(city.state.db, city.state.overrides, "interior"), "house_kinds")
		for design: String in kinds:
			if JsonUtil.get_str(kinds, design) == str(_args["house"]):
				city.visit_house("h0", design)
				break
		_args["facility"] = ""
	if _args.has("facility"):
		if not str(_args["facility"]).is_empty():
			city.choose_facility(str(_args["facility"]))
		await _frames(2)
		var iv := city.facility_view() as InteriorView
		if iv != null and _args.has("in_at"):  # --in_at=x,y [--face=…]: 실내에서 그 칸에 선다(그 방만 보인다 — CT106)
			var xy := str(_args["in_at"]).split(",")
			iv.place(Vector2(float(xy[0]), float(xy[1])), faces.get(str(_args.get("face", "up")), Vector2i.UP))
			await _frames(30)
		if iv != null and _args.has("activity"):  # 실내: 그 활동을 바로(창구는 카드)
			var aid := str(_args["activity"])
			if JsonUtil.get_str(city.state.activity(aid), "panel").is_empty():
				iv.use(aid)
			else:
				iv.open_panel(aid, str(_args.get("tab", "")))
			if _args.has("dialog"):
				await get_tree().create_timer(1.5).timeout
		elif _args.has("activity"):
			var name := DataNames.entry(city.state.db, "activities", str(_args["activity"]))
			city.facility_view()._choose(str(_args["activity"]), str(_args.get("tab", "")))
			if name.is_empty():
				push_warning("활동 없음: " + str(_args["activity"]))
			if _args.has("advance"):  # --advance=N: 결과 대화창을 N쪽 넘긴다(--dialog와 함께 — 뒤 쪽 문구 확인)
				for k in str(_args["advance"]).to_int() * 2:  # 한 번은 글자 다 보이기, 한 번은 다음 쪽
					await _frames(2)
					for db: Node in city.find_children("*", "DialogueBox", true, false):
						(db as DialogueBox).advance()
			if _args.has("dialog"):
				await get_tree().create_timer(1.5).timeout  # 글자가 다 나올 때까지
	if _args.has("debug"):
		city.debug_panel().visible = true
	if _args.has("street"):
		city.street_event(str(_args["street"]))
		await get_tree().create_timer(0.5).timeout  # 일러스트가 다 나타날 때까지(StreetEventView fade)
	await _frames(4)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _enter_rift(explore: ExploreScreen) -> ExploreScreen:
	var s := explore.session
	s.rifts.force_open(s, str(_args["rift"]), s.pos)
	var portal: Dictionary = s.map.portals.filter(func(q: Dictionary) -> bool: return str(q.get("kind", "")) == "rift")[0]
	s.relocate(portal["pos"])
	s.interact()
	await _frames(4)
	explore = _main.current_screen() as ExploreScreen
	var keep_skip := DialogueBox.auto_skip
	DialogueBox.auto_skip = true  # 챕터를 건너가는 동안은 대화창을 넘긴다(--dialog면 도착 문구가 Enter를 기다려 멈췄다)
	if int(str(_args.get("chapter", "1"))) > 1:
		explore.dialog().clear()
	for i in int(str(_args.get("chapter", "1"))) - 1:
		explore.session.rift_run.debug_clear()
		var req := JsonUtil.get_dict(explore.session.rift_run.chapters()[explore.session.rift_run.chapter], "exit_requires")
		if not req.is_empty():
			explore.session.player.inventory.add(JsonUtil.get_str(req, "item"), 1)
		var before := explore.session
		explore.session.relocate(explore.session.map.portals[0]["pos"])
		explore.session.interact()
		for f in 180:  # 챕터 세션이 바뀔 때까지(화면은 그대로 두고 어두워진 뒤 세션만 바꾼다 — 몇 프레임으로는 모자랐다)
			await get_tree().process_frame
			var now := _main.current_screen() as ExploreScreen
			if now != null and now.session != before:
				break
		await _frames(2)
		explore = _main.current_screen() as ExploreScreen
		explore.dialog().clear()
	DialogueBox.auto_skip = keep_skip
	if _args.has("near") and str(_args["near"]).contains(","):  # --near=<x>,<y>: 챕터 지도의 그 칸에 선다
		var xy := str(_args["near"]).split(",")
		explore.session.relocate(Vector2i(int(xy[0]), int(xy[1])))
		for o: FieldMonsters.Group in explore.session.monsters.groups:
			o.grace_until = explore.session.clock.total_hours + 100.0 if o.tag != "ambush" else -1.0
		for i in int(str(_args.get("chase", "0"))):  # --chase=N: 매복 무리(RiftAmbush)가 N걸음만큼 쫓아온 뒤
			explore.session.pass_time(explore.session.move_hours())
			await _frames(1)
	elif str(_args.get("near", "")) == "chest":  # --near=chest: 첫 잠긴 상자 아래 칸에 선다(V25) · --open_chest[=초]: 열고(동전) 그 초 뒤에 찍는다
		var es0 := explore.session
		for at: Vector2i in es0.loot:
			if RiftChest.locked(es0.loot[at]):
				es0.relocate(at + Vector2i(0, 1) if es0.map.is_walkable(at + Vector2i(0, 1)) else at)
				break
		for o: FieldMonsters.Group in es0.monsters.groups:
			o.grace_until = es0.clock.total_hours + 100.0
		await _frames(3)
		if _args.has("open_chest"):
			explore.dialog().clear()
			await _frames(2)
			es0.interact()
			if _args.has("pick"):  # --pick=0|1: 앞뒤 고르기 창에서 그 칸을 고른다(없으면 창이 뜬 채 찍는다)
				await _frames(3)
				for n: Node in _main.find_children("*", "ChoicePopup", true, false):
					(n as ChoicePopup).picked.emit(int(str(_args["pick"])))
			var sec := str(_args["open_chest"])
			await get_tree().create_timer(sec.to_float() if sec.is_valid_float() else 1.0).timeout
	elif str(_args.get("near", "")) == "scavenge":  # --near=scavenge: 뒤질 수 있는 장식 옆에 서서 살핀다(RF19 — 잡템 대화창은 --dialog)
		var es := explore.session
		var done := false
		for y in es.map.height:
			for x in es.map.width:
				var d := es.map.def_at(Vector2i(x, y))
				if done or d == null or d.scavenge.is_empty():
					continue
				for k in FloorMap.DIRS4:
					if not done and es.relocate(Vector2i(x, y) + k):
						done = true
		for o: FieldMonsters.Group in es.monsters.groups:
			o.grace_until = es.clock.total_hours + 100.0
		await _frames(3)
		es.interact()
	elif _args.has("near"):  # --near=guardian|<tag>: 그 무리에서 몇 칸 떨어진 곳에 선다(보스가 기다리는 방을 보려고 — 전투는 걸지 않는다)
		var run0 := explore.session.rift_run
		for g: FieldMonsters.Group in run0.remaining:
			var want := str(_args["near"])  # --near=mon:<몬스터 id>: 그 몬스터가 낀 무리
			if g.tag == want or (want == "boss" and not g.boss.is_empty()) or (want.begins_with("mon:") and g.monster_ids.has(want.trim_prefix("mon:"))):
				print("[near] 무리 %s %s 칸 %s" % [g.tag, str(g.monster_ids), str(g.pos)])
				var spot := Vector2i(-1, -1)
				for r in ([5, 6, 4, 7, 8] if not g.boss.is_empty() else [7, 8, 9, 6]):  # 보통 무리는 알아채는 거리 밖에서
					for dy in range(-r, r + 1):
						for dx in range(-r, r + 1):
							var c: Vector2i = g.pos + Vector2i(dx, dy)
							if spot.x < 0 and maxi(absi(dx), absi(dy)) == r and dy >= 0 and explore.session.map.is_walkable(c):
								spot = c
				if spot.x >= 0:
					explore.session.relocate(spot)
				for o: FieldMonsters.Group in explore.session.monsters.groups:  # 캡처하는 동안 전투가 걸리지 않게(쫓지 않음)
					o.grace_until = explore.session.clock.total_hours + 100.0
				if _args.has("spotted"):  # --spotted: 그 보스만 알아채게 둔다 — 전투 직전 한 줄(explore.boss_notice, --dialog와 함께)
					g.grace_until = -1.0
					var wait_s := str(_args["spotted"])  # --spotted=<초>: 그만큼 뒤에 찍는다(보스 등장 연출 중간 — V22, 기본 1.5)
					await get_tree().create_timer(wait_s.to_float() if wait_s.is_valid_float() else 1.5).timeout
					if _args.has("then_at"):  # --then_at=x,y: 등장 연출 뒤 그 칸으로 옮겨 찍는다(보스 방 창살 확인 — V23)
						var ta := str(_args["then_at"]).split(",")
						explore.session.pos = Vector2i(ta[0].to_int(), ta[1].to_int())
						explore.session.fpos = Kinematics.center_of(explore.session.pos)
						explore.session.body_moved.emit(explore.session.fpos)
						explore.session.refresh_view()
						await _frames(6)
				break
	if _args.has("slay"):  # --slay: 수호자를 쓰러뜨린 것으로 — 그 자리에 탈출 포탈(RiftRun._open_escape)
		var rr := explore.session.rift_run
		for g: FieldMonsters.Group in rr.remaining.duplicate():
			if g.tag == "guardian":
				rr.on_battle_end(explore.session, g, Battle.RESULT_VICTORY, [rr.guardian_id()])
		await _frames(3)
	if _args.has("trap"):  # --trap: 이 챕터의 첫 함정·위험을 밟아 판정한다(판정 뒤에도 그 자리에 남는지 확인), --trap=all: 함정을 모두 드러내기만
		var hz := explore.session.rift_run.hazards
		if str(_args["trap"]) == "all":
			var groups: Array = []
			for c: Vector2i in hz.at:
				if not groups.has(hz.at[c]):
					groups.append(hz.at[c])
			for g: Dictionary in groups:
				hz._show(explore.session, g)
		elif not hz.at.is_empty():
			explore.session.relocate(hz.at.keys()[0])
	if _args.has("murals") and explore.session.rift_run.riddle != null:  # --murals: 수수께끼 벽화 힌트를 모두 본 상태(대화창에 장면이 보인다)
		var rd := explore.session.rift_run.riddle
		for i in rd.hints().size():
			explore.session.player.knowledge.learn_fact(rd._fact(i))
	if _args.has("engage"):
		var run := explore.session.rift_run
		var pick: FieldMonsters.Group = run.remaining[0]
		for g: FieldMonsters.Group in run.remaining:
			if g.tag == str(_args["engage"]):
				pick = g
		explore.session.engage(pick, true)
	if _args.has("reveal"):  # 챕터 세션이 바뀐 뒤라 다시 걷는다
		ExploreDebug.reveal(explore.session)
		explore.session.refresh_view()
	if _args.has("ezoom"):  # --ezoom=<배율>: 탐험 카메라 배율만 바꿔 찍는다(챕터 테두리 넓게 보기 — 그림 확인용)
		for c: Node in explore.find_children("*", "Camera2D", true, false):
			(c as Camera2D).zoom = Vector2.ONE * str(_args["ezoom"]).to_float()
		await _frames(8)
	return explore


## --summon: 지금 전투 화면의 적 진영에 증원(=N 고블린 N마리, =id,id 그 몬스터들), --ally_summon이면 아군 소환수도.
func _summon() -> void:
	await _frames(3)
	for n: Node in _main.find_children("*", "", true, false):
		if n is CombatScreen:
			var cs := n as CombatScreen
			var sv := str(_args["summon"])
			if sv.is_valid_int() or sv == "true":  # --summon=N: 고블린 N마리
				for k in (sv.to_int() if sv.is_valid_int() else 1):
					BattleRules.summon(cs.battle, cs.battle.side_units(Combatant.SIDE_ENEMY)[0], {"monster": "goblin"})
			else:  # --summon=id,id: 그 몬스터들(그림 확인) — --summon_each면 하나씩 몇 프레임 뒤에(전투 중 소환처럼 — 배치가 뒤틀리는지)
				for mid in sv.split(","):
					BattleRules.summon(cs.battle, cs.battle.side_units(Combatant.SIDE_ENEMY)[0], {"monster": mid})
					if _args.has("summon_each"):
						await _frames(3)
			if _args.has("ally_summon"):  # 아군 소환수(뒷모습 그림 확인)
				var av := str(_args["ally_summon"])
				for aid in ("soldier_deadman" if av == "true" else av).split(","):
					BattleRules.summon(cs.battle, cs.battle.side_units(Combatant.SIDE_PARTY)[0], {"monster": aid})


## 걷기 프레임 시간: 키 넷을 1.2초씩 돌려 누르며 sec초 — 평균·95%·최대·느린 프레임 수와 그리기 호출·노드 수.
func _profile_walk(sec: float) -> void:
	var keys := ["move_right", "move_down", "move_left", "move_up"]
	var times: Array[float] = []
	var t0 := Time.get_ticks_usec()
	var last := t0
	var k := -1
	while (Time.get_ticks_usec() - t0) / 1e6 < sec:
		var idx := int((Time.get_ticks_usec() - t0) / 1.2e6) % keys.size()
		if idx != k:
			if k >= 0:
				Input.action_release(keys[k])
			k = idx
			Input.action_press(keys[k])
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		times.append((now - last) / 1000.0)
		last = now
	Input.action_release(keys[k])
	times.sort()
	var avg := 0.0
	for v in times:
		avg += v / times.size()
	var slow := times.filter(func(v: float) -> bool: return v > 50.0).size()
	var hitch := times.filter(func(v: float) -> bool: return v > 16.7).size()
	print("프레임 %d · 평균 %.1f ms · 95%% %.1f ms · 99%% %.1f ms · 최대 %.1f ms · 16.7ms 넘는 프레임 %d · 50ms 넘는 프레임 %d" % [times.size(), avg,
		times[int(times.size() * 0.95)], times[int(times.size() * 0.99)], times.back(), hitch, slow])
	print("그리기 호출 %d · 노드 %d · 처리 %.1f ms" % [Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0])
