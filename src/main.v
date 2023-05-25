module main

// imports
import os
import x.json2
import time
import net.websocket
import zztkm.vdotenv

// constants
const api = "https://discord.com/api/v10/"
const websocket_url = "wss://gateway.discord.gg/?v=10&encoding=json"

fn main() {

	vdotenv.load()
	go start_client()
	println('press enter to quit...')
	os.get_line()

}

fn start_client() ! {

	// create websocket client
	mut client := websocket.new_client(websocket_url)!

	// get discord token from environment
	discord_token := os.getenv('DISCORD_TOKEN')

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
				println('$time.now() [ ACK ] heartbeat acknowledged')

			} else if opcode == 0 && event_name == 'READY' { // ready
				//general data
				data := decoded_payload['d']! as map[string]json2.Any
				session_id := data['session_id']! as string
				resume_url := data['resume_gateway_url']! as string
				
				//user data
				user_data := data['user']! as map[string]json2.Any
				user_id := user_data['id']! as string
				username := (user_data['username']! as string) + '#' + (user_data['discriminator']! as string)

				//application data
				aplication_data := data['application']! as map[string]json2.Any
				application_id := aplication_data['id']! as string

				println('$time.now() [READY]\n\t> Session_id: $session_id\n\t> User_id: $user_id\n\t> Username: $username\n\t> Application_id: $application_id\n\t> Resume_url: $resume_url')
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
		}
	}

}