extends Control

@onready var progress_bar = $CenterContainer/VBoxContainer/ProgressBar
@onready var loading_label = $CenterContainer/VBoxContainer/LoadingLabel
@onready var loading_timer = $LoadingTimer

var target_scene: String = ""
var is_new_game: bool = false
var current_progress: float = 0.0
var loading_steps: Array = []
var current_step: int = 0

func _ready():
	# Ẩn mouse cursor trong loading
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# Tự động bắt đầu loading với thông tin từ Global
	if Global.loading_target_scene != "":
		start_loading(Global.loading_target_scene, Global.loading_is_new_game)
		# Reset thông tin sau khi sử dụng
		Global.loading_target_scene = ""
		Global.loading_is_new_game = false
		Global.loading_from_pause = false

func start_loading(scene_path: String, new_game: bool = false):
	"""Bắt đầu quá trình loading"""
	target_scene = scene_path
	is_new_game = new_game
	
	# Cập nhật title dựa trên loại loading
	var title_label = $CenterContainer/VBoxContainer/GameTitle
	if Global.loading_from_pause:
		title_label.text = "Đang quay về menu..."
	elif is_new_game:
		title_label.text = "Đang tạo game mới..."
	else:
		title_label.text = "Đang tải game..."
	
	# Thiết lập các bước loading
	if is_new_game:
		loading_steps = [
			"Đang xóa dữ liệu cũ...",
			"Đang tạo dữ liệu mới...",
			"Đang khởi tạo thế giới...",
			"Đang tải tài nguyên...",
			"Đang chuẩn bị nhân vật...",
			"Hoàn thành!"
		]
	elif Global.loading_from_pause:
		loading_steps = [
			"Đang dọn dẹp tài nguyên...",
			"Đang chuẩn bị menu chính...",
			"Đang tải giao diện...",
			"Đang hoàn tất...",
			"Đang kết thúc...",
			"Hoàn thành!"
		]
	else:
		loading_steps = [
			"Đang tải dữ liệu game...",
			"Đang khôi phục tiến trình...",
			"Đang tải inventory...",
			"Đang tải quest...",
			"Đang chuẩn bị thế giới...",
			"Hoàn thành!"
		]
	
	current_step = 0
	current_progress = 0.0
	progress_bar.value = 0
	
	# Bắt đầu loading
	loading_timer.start()
	_update_loading_step()

func _on_loading_timer_timeout():
	"""Xử lý mỗi bước loading"""
	current_progress += 16.67  # 100 / 6 steps ≈ 16.67
	progress_bar.value = current_progress
	
	# Thực hiện công việc thực tế cho bước hiện tại
	_perform_loading_step()
	
	current_step += 1
	
	if current_step < loading_steps.size():
		_update_loading_step()
	else:
		_finish_loading()

func _update_loading_step():
	"""Cập nhật text hiển thị bước loading"""
	if current_step < loading_steps.size():
		loading_label.text = loading_steps[current_step]

func _perform_loading_step():
	"""Thực hiện công việc thực tế cho từng bước"""
	# Sử dụng call_deferred để tránh blocking
	match current_step:
		0:  # Bước đầu tiên
			if is_new_game:
				# Xóa dữ liệu cũ (đã làm trong main_menu, chỉ cần delay)
				pass
			else:
				# Load dữ liệu game
				GameManager.load_game()
		
		1:  # Bước thứ hai
			if is_new_game:
				# Tạo dữ liệu mới (đã làm trong main_menu)
				pass
			else:
				# Khôi phục tiến trình
				pass
		
		2:  # Bước thứ ba
			if is_new_game:
				# Khởi tạo thế giới
				pass
			else:
				# Load inventory
				GameManager.load_inventory()
		
		3:  # Bước thứ tư
			if is_new_game:
				# Tải tài nguyên
				pass
			else:
				# Load quest
				GameManager.load_quests()
		
		4:  # Bước thứ năm
			# Chuẩn bị nhân vật/thế giới
			pass
		
		5:  # Bước cuối
			# Hoàn thành
			pass

func _finish_loading():
	"""Hoàn thành loading và chuyển scene"""
	loading_timer.stop()
	progress_bar.value = 100
	loading_label.text = "Hoàn thành!"
	
	# Hiển thị mouse cursor trở lại
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Sử dụng Timer thay vì await để tránh lỗi
	var finish_timer = Timer.new()
	add_child(finish_timer)
	finish_timer.wait_time = 0.5
	finish_timer.one_shot = true
	finish_timer.timeout.connect(_change_to_target_scene)
	finish_timer.start()

func _change_to_target_scene():
	"""Chuyển đến scene đích"""
	# Xử lý âm nhạc dựa trên scene đích
	if target_scene.ends_with("main_menu.tscn"):
		# Chuyển về main menu - dừng âm nhạc hiện tại
		# (main menu sẽ tự phát nhạc menu trong _ready())
		AudioManager.stop_music()
	elif target_scene.ends_with("main_map.tscn"):
		# Chuyển vào game - dừng nhạc menu
		# (main_map sẽ tự phát nhạc game trong _ready())
		AudioManager.stop_music()
	
	var load_scene = load(target_scene)
	get_tree().change_scene_to_packed(load_scene)

func _input(event):
	"""Cho phép skip loading bằng cách nhấn phím bất kỳ"""
	if event.is_pressed() and not event.is_echo():
		if current_step < loading_steps.size() - 1:
			# Skip đến bước cuối
			current_step = loading_steps.size() - 1
			current_progress = 100
			progress_bar.value = 100
			loading_label.text = loading_steps[current_step]
			loading_timer.stop()
			call_deferred("_finish_loading")
