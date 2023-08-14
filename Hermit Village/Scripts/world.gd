extends Node3D

var rng = RandomNumberGenerator.new()

@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/LineEdit

var players = []
var maniac_chosen
var security_chosen

const PORT = 8080
var enet_peer = ENetMultiplayerPeer.new()

func _process(delta):
	if Input.is_action_pressed("cancel"):
		get_tree().quit()
	

func _on_host_button_down():
	main_menu.hide()
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(on_connect)
	on_connect(multiplayer.get_unique_id())

func _on_join_button_down():
	main_menu.hide()
	enet_peer.create_client(address_entry.text,PORT)
	multiplayer.multiplayer_peer = enet_peer


func on_connect(peer_id):
	var Player = load("res://Scenes/player.tscn")
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)
	players.append(peer_id)
	if len(players) >= 4:
		rng.randomize()
		var role = rng.randi_range(0, 3)
		get_node(str(players[role])).rpc("maniac")
		maniac_chosen = true
	if len(players) >= 3 and maniac_chosen:
		rng.randomize()
		var role = rng.randi_range(0,2)
		get_node(str(players[role])).rpc("security")
		security_chosen = true
	if len(players) >= 2 and security_chosen:
		for i in len(players):
			i += 1
			rng.randomize()
			var role = rng.randi_range(0,1)
			get_node(str(players[role])).rpc("peaceful")


func _on_line_edit_mouse_entered():
	$AudioStreamPlayer.play()


func _on_join_mouse_entered():
	$AudioStreamPlayer.play()


func _on_host_mouse_entered():
	$AudioStreamPlayer.play()
