module viscord

struct Channel {
	pub:
		name string
		id string
		@type i64
}

struct Guild {
	pub:
		name string
		id string
		channels []Channel
}