# ----- DIR -----
alias dir="eza \
--git \
--git-repos \
--header \
--icons=always \
--no-user \
-H \
--long \
"

alias dira="dir --all"
alias dirc="dir --created"
alias dirtree="dir --tree --level=3 --git-ignore"

# ----- Processes -----

# Kill a process by port number
#
# @param $1: port number
function killport() {
	local port_number="$1"
	lsof -ti:"$port_number" | xargs kill -9
}
