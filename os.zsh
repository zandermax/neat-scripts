function killport() {
	local port_number="$1"
	lsof -ti:"$port_number" | xargs kill -9
}
