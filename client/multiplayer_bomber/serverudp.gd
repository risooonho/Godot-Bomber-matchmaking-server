extends Node

const SERVER_IP = '40.121.198.16' # Change this to your own Server IP
const PORT = 3456

onready var udp = PacketPeerUDP.new()
onready var player_name = "Godotchan"
onready var searching_match = false

onready var is_master = 0
onready var other_name = ""
onready var other_remote_ip = ""
onready var other_remote_port = 0
onready var other_private_ip = ""

onready var _other_packets_received = 0

signal server_ok
signal server_not_ok
signal match_found

# TO-DO: ping server constantly to not lose socket

func start_connection():
	udp.listen(PORT)
	udp.set_dest_address(SERVER_IP, PORT)
	
	var buffer = PoolByteArray()
	
	# Send packets to server - wait for response after all packets are sent
	
	buffer.append_array("n".to_utf8()) # name
	buffer.append_array(player_name.to_utf8())
	udp.put_packet(buffer)
	
	buffer.resize(0)
	buffer.append_array("i".to_utf8()) # private ip
	buffer.append_array(IP.get_local_addresses()[1].to_utf8())
	udp.put_packet(buffer)
	
	var err = udp.wait() # wait for server ok
	
	if (err == OK):
		print("Received ok from server, nice.")
		var packet = udp.get_packet()
		emit_signal("server_ok")
		searching_match = true
	else:
		print("Didn't receive ok from server!")
		emit_signal("server_not_ok")
		udp.close()

func _process(delta):
	if (searching_match):
		if (udp.is_listening() and udp.get_available_packet_count() > 0):
			_other_packets_received+=1
			var packet_string = udp.get_packet().get_string_from_utf8()
			var type = packet_string.substr(0,2)
			if(type == "im"): # is master
				is_master = int(packet_string.right(2))
			if(type == "na"): # name
				other_name = packet_string.right(2)
			if(type == "ri"): # remote ip
				other_remote_ip = packet_string.right(2)
			if(type == "rp"): # remote port
				other_remote_port = int(packet_string.right(2))
			if(type == "pi"): # private ip
				other_private_ip = packet_string.right(2)
			
			if(_other_packets_received == 5):
				udp.close()
				emit_signal("match_found")

func _ready():
	set_process(true)
	pass