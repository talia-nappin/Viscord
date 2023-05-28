module viscord

import time
import net.websocket
import x.json2

//todo: implement heartbeats ack checking

fn hearbeats(mut client websocket.Client, heartbeat_interval i64) {

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