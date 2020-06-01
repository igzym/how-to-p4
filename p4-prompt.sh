# ---- Perforce stream name in prompt

# set the environment variable to activate the functionality
# export P4_STREAM_PS1_SHOW=1

function __p4_stream_ps1 {
	if [ "$P4_STREAM_PS1_SHOW" = 1 ]; then
		local r=$(p4 -ztag stream -o 2>/dev/null | awk '$2 == "Name" {print $3}')
		if [ "$r" ]; then
			printf "(%s)" "$r"
		fi
	fi
}
