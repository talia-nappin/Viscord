module viscord

import net.websocket
import x.json2
import time
import os

pub fn start_client(discord_token string, websocket_url string) ! {

	// create websocket client
	mut client := websocket.new_client(websocket_url)!

	// get discord token from environment
	

	// set websocket callbacks
	client.on_open(fn (mut client websocket.Client) ! {})

	client.on_message(fn [discord_token] (mut client websocket.Client, message &websocket.Message) ! {
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
				heartbeat := data['heartbeat_interval']! as i64
				go hearbeats(mut client, heartbeat)

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
				
					api_version := data['v']! as i64

					go authorize_api(discord_token, api_version)

				} else if event_name == 'GUILD_CREATE' { // guild create
					
					// guild data
					guild_id := data['id']! as string
					
					// cache to json file if not cached or if cached but not up to date
					os.write_file('cache/${guild_id}.json', json2.encode_pretty(data)) or {
						println('failed to cache guild data:\n$err')
					} {
						println('$time.now() [CACHE] Guild data cached')
					}
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

