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
			opcode := decoded_payload['op'].int()
			data := decoded_payload['d'] as map[string]json2.Any
			// handle message opcode
			if opcode == 10 {
				go handle_hello_message(mut client, data)
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
	heartbeat_interval := data['heartbeat_interval'].int()
	println('heartbeat interval: $heartbeat_interval')

	// send heartbeat
	go send_heartbeat(mut client, heartbeat_interval)

}

fn send_heartbeat(mut client websocket.Client, heartbeat_interval int) {

	// send heartbeat every heartbeat interval
	for {
		time.sleep(heartbeat_interval * time.millisecond)
		client.write_string('{"op":1,"d":null}') or {
			println('failed to send heartbeat:\n$err')
		}
	}

}