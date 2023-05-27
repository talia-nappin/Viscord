module main

// imports
import os
import viscord
import zztkm.vdotenv

// constants
const websocket_url = "wss://gateway.discord.gg/?v=10&encoding=json"

fn main() {

	vdotenv.load()
	discord_token := os.getenv('DISCORD_TOKEN')
	go viscord.start_client(discord_token, websocket_url)
	println('press enter to quit...')
	os.get_line()

}