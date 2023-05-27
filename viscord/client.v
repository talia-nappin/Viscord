module viscord

import net.websocket
import x.json2
import time



pub fn start_client(discord_token string, websocket_url string) ! {

	// create websocket client
	mut client := websocket.new_client(websocket_url)!

	// get discord token from environment
	

	// set websocket callbacks
	client.on_open(fn (mut client websocket.Client) ! {})

	client.on_message(fn (mut client websocket.Client, message &websocket.Message) ! {
		if message.payload.len > 0 {
			// decode message payload
			raw_payload := json2.raw_decode(message.payload.bytestr())!
			// cast payload to object
			decoded_payload := raw_payload.as_map()
			// get message opcode and data
			opcode := decoded_payload['op']!.int()
			event_name := decoded_payload['t']!.str()
				
			// handle message opcode

			if opcode == 10 { // hello
				data := decoded_payload['d']! as map[string]json2.Any
				go handle_hello_message(mut client, data)

			} else if opcode == 11 { // heartbeat ack
				println('$time.now() [ACK  ] Heartbeat acknowledged')

			} else if opcode == 0 {

				data := decoded_payload['d']! as map[string]json2.Any

				if event_name == 'READY' { // ready
					//general data
					session_id := data['session_id']! as string
					resume_url := data['resume_gateway_url']! as string
					
					//user data
					user_data := data['user']! as map[string]json2.Any
					user_id := user_data['id']! as string
					username := (user_data['username']! as string) + '#' + (user_data['discriminator']! as string)

					//application data
					aplication_data := data['application']! as map[string]json2.Any
					application_id := aplication_data['id']! as string

					
					println('$time.now() [READY] Aplication ready\n\t> Session_id: $session_id\n\t> User_id: $user_id\n\t> Username: $username\n\t> Application_id: $application_id\n\t> Resume_url: $resume_url')
				} else if event_name == 'GUILD_CREATE' { // guild create
					//general data
					guild_name := data['name']! as string
					guild_id := data['id']! as string

					//channels data
					channels_data := data['channels']! as []json2.Any
					mut channels := []Channel{}

					for x in channels_data{
						channel_data := x as map[string]json2.Any
						channel_name := channel_data['name']! as string
						channel_id := channel_data['id']! as string
						channel_type := channel_data['type']! as i64
						channels << Channel{channel_name, channel_id, channel_type}
					}

					guild := Guild{guild_name, guild_id, channels}
					
					println('$time.now() [GUILD] Guild created\n\t> Guild_name: $guild.name\n\t> Guild_id: $guild.id\n\t> Channels:\n\t\t> ' + guild.channels.filter(it.@type == 0).map(it.name + ' (' + it.id + ')').join("\n\t\t> "))
				} else {
					println('$time.now() [MSG  ] $opcode $event_name')
				}
			} else {
				println('$time.now() [MSG  ] $opcode $event_name')
			}
		}
	})

	client.on_close(fn (mut client websocket.Client, code int, reason string) ! {
		println('websocket closed: $code $reason')
	})

	client.on_error(fn (mut client websocket.Client, err string) ! {
		println('websocket error: $err')
	})

	// connect to websocket
	client.connect() or {
		println('failed to connect to websocket:\n$err')
	}

	// send authentication payload
	client.write_string('{"op":2,"d":{"token":"$discord_token","properties":{"os":"linux","browser":"viscord","device":"viscord"},"intents":3}}') or {
		println('failed to send authentication payload:\n$err')
	} {
		println('$time.now() [SEND ] Authentication payload sent')
	}

	// update presence
	client.write_string('{"op":3,"d":{"since":null,"activities":[{"name":"Viscord","type":2}],"status":"online","afk":false}}') or {
		println('failed to update presence:\n$err')
	} {
		println('$time.now() [SEND ] Presence update sent')
	}

	// listen to websocket
	client.listen() or {
		println('failed to listen to websocket:\n$err')
	}

	// free websocket client
	unsafe {
		client.free()
	}
}

fn handle_hello_message(mut client websocket.Client, data map[string]json2.Any) ! {

	// get heartbeat interval
	heartbeat_interval := data['heartbeat_interval']!.int()

	// send heartbeat
	go send_heartbeat(mut client, heartbeat_interval)

}

fn send_heartbeat(mut client websocket.Client, heartbeat_interval int) {

	mut heartbeat := map[string]json2.Any{}
	heartbeat['op'] = 1
	heartbeat['d'] = json2.null

	// send heartbeat every heartbeat interval
	for {
		time.sleep(heartbeat_interval * time.millisecond)
		client.write_string(heartbeat.str()) or {
			println('failed to send heartbeat:\n$err')
		} {
			println('$time.now() [SEND ] Heartbeat sent')
		}
	}

}