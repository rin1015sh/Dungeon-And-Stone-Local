class_name ResourcePanel
extends VBoxContainer
## ResourcePool의 게이지 묶음. visible=false이거나 지금 비활성 범위인 자원(예: 도시의 허기)은 숨긴다.

var _pool: ResourcePool = null
var _bars: Dictionary = {}  # id -> ResourceBar


func bind(pool: ResourcePool) -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_bars.clear()
	_pool = pool
	for id in pool.ids():
		var bar := ResourceBar.new()
		bar.setup(pool.get_def(id))
		add_child(bar)
		_bars[id] = bar
	pool.changed.connect(_on_changed)
	pool.context_changed.connect(_on_context_changed)
	refresh()


func refresh() -> void:
	if _pool == null:
		return
	for id: String in _bars:
		var bar: ResourceBar = _bars[id]
		bar.visible = _pool.get_def(id).visible and _pool.is_active(id)
		bar.set_values(_pool.get_current(id), _pool.get_max(id))


func _on_changed(_id: String, _current: float, _maximum: float) -> void:
	refresh()


func _on_context_changed(_key: String, _active: bool) -> void:
	refresh()
