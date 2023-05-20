module main

// imports
import os
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
	client.on_open(fn (mut client websocket.Client) ! {
		println('connected to websocket')
	})

	client.on_message(fn (mut client websocket.Client, msg &websocket.Message) ! {
		if msg.payload.len > 0 {
			println('$client.id got message: \n$msg.payload')
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
