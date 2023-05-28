module viscord

import net.http

fn authorize_api (discord_token string, api_version i64) ! {

	api_url := "https://discord.com/api/v" + api_version.str()

	mut req := http.new_request(http.Method.get, api_url + '/users/@me', '')
	req.add_custom_header("Authorization", "Bot " + discord_token)!
	res := req.do()!

	if res.status_code != 200 {
		return error("Failerd API authorization: " + res.status_code.str() + " " + res.body)
	} else {
		println("API authorized successfully: " + res.status_code.str() + " " + res.body)
	}

}