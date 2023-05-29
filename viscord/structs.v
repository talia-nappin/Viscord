module viscord

// struct Channel {
// 	pub:
// 		name string
// 		id string
// 		@type i64
// }

// struct Guild {
// 	pub:
// 		name string
// 		id string
// 		channels []Channel
// }

const discord_epoch = u64(1420070400000)

pub struct Snowflake {
	pub:
		id u64
		timestamp u64
		worker_id u64
		process_id u64
		increment u64
}

fn deconstruct_snowflake (snowflake u64) Snowflake {
	return Snowflake {
		id: snowflake
		timestamp: (snowflake >> 22) + discord_epoch
		worker_id: (snowflake & 0x3E0000) >> 17
		process_id: (snowflake & 0x1F000) >> 12
		increment: snowflake & 0xFFF
	}
}