extends Node2D

var npc: Node = null

@onready var dialog_ui = $DialogUI

func show_dialog(npc, text = "", options = {}):
	AudioManager.play_sfx("open_dialog")
	if text != "":
		dialog_ui.show_dialog(npc.npc_name, text, options)
	else:
		var quest_dialog = npc.get_quest_dialog()
		
		if quest_dialog["text"] != "":
			dialog_ui.show_dialog(npc.npc_name, quest_dialog["text"], quest_dialog["options"])
		else:
			var dialog = npc.get_current_dialog()
			if dialog == null:
				return
			dialog_ui.show_dialog(npc.npc_name, dialog["text"], dialog["options"])

func hide_dialog():
	dialog_ui.hide_dialog()

func handle_dialog_choice(option):
	var current_dialog = npc.get_current_dialog()
	if current_dialog == null:
		return
	
	var next_state = current_dialog["options"].get(option, "start")
	npc.set_dialog_state(next_state)
	
	if next_state == "end":
		if npc.current_branch_index < npc.dialog_resource.get_npc_dialog(npc.npc_id).size() - 1:
			npc.set_dialog_tree(npc.current_branch_index + 1)
		hide_dialog()
	elif next_state == "exit":
		npc.set_dialog_state("start")
		hide_dialog()
	elif next_state == "give_quest":
		if npc.dialog_resource.get_npc_dialog(npc.npc_id)[npc.current_branch_index]["branch_id"] == "npc_default":
			offer_remaining_quests()
		else:
			offer_quests(npc.dialog_resource.get_npc_dialog(npc.npc_id)[npc.current_branch_index]["branch_id"])
		show_dialog(npc)
	elif next_state == "buy_health_potion":
		buy_health_potion()
		show_dialog(npc)
	else:
		show_dialog(npc)

func offer_quests(branch_id: String):
	for quest in npc.quests:
		if quest.unlock_id == branch_id and quest.state == "not_started":
			npc.offer_quest(quest.quest_id)

func offer_remaining_quests():
	for quest in npc.quests:
		if quest.state == "not_started":
			npc.offer_quest(quest.quest_id)

func buy_health_potion():
	# Kiểm tra xem người chơi có đủ tiền không (giá 50 gold)
	var potion_price = 50
	
	if Global.player.coin_amount >= potion_price:
		# Trừ tiền
		Global.player.coin_amount -= potion_price
		Global.player.update_coins()  # Cập nhật hiển thị tiền
		
		# Tạo item bình hồi máu với cấu trúc đúng
		var health_potion = {
			"item_type": "consumable",
			"item_name": "Bình máu",
			"item_effect": "heal",
			"quantity": 1,
			"scene_path": "res://scenes/entity/inventory_item.tscn",
			"item_texture": GameManager.get_item_texture("Bình máu")
		}
		
		# Thêm vào inventory sử dụng hàm Global.add_item()
		var success = Global.add_item(health_potion)
		
		if success:
			# Cập nhật dialog để thông báo mua thành công
			npc.set_dialog_state("purchase_success")
			print("Đã mua bình hồi máu thành công!")
			
			# Lưu dữ liệu player
			GameManager.save_player_positon()
		else:
			# Túi đồ đầy
			npc.set_dialog_state("inventory_full")
			print("Túi đồ đầy, không thể mua thêm!")
	else:
		# Không đủ tiền
		npc.set_dialog_state("insufficient_funds")
		print("Không đủ tiền để mua bình hồi máu!")
