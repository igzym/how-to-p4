function htp4clo { p4 -ztag client -o | grep --color -C 10000 '^\.\.\. [^[:space:]]*'; } # client spec output
function htp4sto { p4 -ztag stream -o "$@" | grep --color -C 10000 '^\.\.\. [^[:space:]]*'; } # stream spec output

function htp4info {
	: p4 connection info
	local o=${1-u}; shift
	case $o in -h) echo "arguments: s|f|u"; return;; esac
	local server="Server (address|root|license|version|encryption|uptime):"
	{ p4 info; echo "Token: $(p4 login -s 2>&1)"; } |
	case $o in
		s) grep -E "$server";;
		u) grep -E -e "(Client|User) name:" -e "Client root:" -e "$server" -e "^Token:";;
		f) grep -E "^[^:]*:";;
		*) :; echo "unknown argument $o (try -h)" >&2; return;;
	esac
}

function htp4opened {
	: opened files with the changelist they belong to
	p4 opened "$@" | 
	awk '$(NF-1) != prev {c = $(NF-1);
	x = sprintf("p4 -ztag describe -s %s | perl -n -e '"'"'print if s/^... desc // .. /^$/'"'"' | cut -c-60", c);
	if (c != "change") { x | getline d; close(x) }
	else { d = "default"};
	print "\033[34m" "Change", c, "\033[35m" d "\033[0m";
	prev = $(NF-1)} { print }';
}

function __htp4chg_echo_trunc {
	local out=$1; shift
	local n=$(echo "$out" | wc -l)
	local nmax=20
	if [[ $n -gt $nmax ]]; then
		out=$(echo "$out" | head -20)
		out=$(echo "$out"; echo "(truncated...)")
	fi
	echo "$out"
}

function __htp4chg_filt {
	grep -E '\.\.\. (change |desc |depotFile)' | sed 's/ depotFile[[:digit:]]*//' |
	sed -e "s/\.\.\. desc.*/\x1B[35m&\x1B[0m/" -e "s/\.\.\. change.*/\x1B[34m&\x1B[0m/"
}

function htp4changes {
	: perforce pending changes
	local clientName=$(p4 -ztag info | awk '$2 == "clientName" { print $3 }')
	if [[ "$clientName" = "*unknown*" ]]; then
		echo "No client" >&2
		return 1
	fi
	local out
	out=$(p4 -ztag opened -C "$clientName" -c default | grep -E '\.\.\. depotFile' | 
		sed 's/ depotFile[[:digit:]]*//')
	if [ "$out" ]; then
		echo "---"
		echo "... change default"
		__htp4chg_echo_trunc "$out"
	fi
	p4 changes -s pending -c "$clientName" | awk '{print $2}' |
		while read c; do
			local out_pend
			local out_shlv
			out_pend=$(p4 -ztag describe -s "$c" | __htp4chg_filt)
			out_shlv=$(p4 -ztag describe -s -S "$c" | grep -v -e ' change ' -e ' desc ' | sed "s/^/\x1B[33mS\x1B[0m /" | __htp4chg_filt)
			out_shlv=$(__htp4chg_echo_trunc "$out_shlv")
			echo "---";
			__htp4chg_echo_trunc "$out_pend"
			__htp4chg_echo_trunc "$out_shlv"
		done
}

function htp4dc {
	: usage CHANGELISTS to show diffs for files open in given changelist
	local c=$1; shift
	p4 opened -c "$c" | sed 's/\(.*\)#.*/\1/' | p4 -x - diff -du "$@"
}


function htp4opened_rel {
	: "opened files as relative paths (common client/depot prefix removed)"
	# clientFile is in format //YOUR_CLIENT/a/b/c, sed simply removes the //YOUR_CLIENT/ prefix
	p4 -ztag opened | awk '$2 == "clientFile" { print $3 }; ' | sed 's;^//[^/]*/;;'
}

function htp4df_general {
    : "utility to view diffs in vim, for p4 diff, diff2 and describe"
    local diff="$1";
    shift;
    local opt="";
    while [ "${1#-}" != "$1" ]; do
        opt="$opt $1";
        shift;
    done;
    if [ "$opt" = "" ]; then
        opt="-du";
    fi;
    echo "p4 $diff $opt $@";
    local tmpfile=/tmp/p4df-$$.diffs;
    local filter="";
    if [ "$diff" = diff2 ]; then
        p4 $diff $opt "$@" | grep -v '=== identical$';
    else
        p4 $diff $opt "$@";
    fi > $tmpfile && {
        vi "+se filetype=diff" $tmpfile;
        rm -f $tmpfile
    }
}

function htp4df { htp4df_general diff "$@"; } # p4 diff in vim
function htp4df2 { htp4df_general diff2 "$@"; } # p4 diff2 in vim
function htp4dsc { htp4df_general describe "$@"; } # p4 describe in vim

function htp4_mystream {
	: show stream name
	p4 -F%Stream% -ztag stream -o
}

function htp4_mystream_parent {
	: show parent stream name
	p4 -ztag -F%Parent% stream -o
}

function htp4show {
    if [ -z "$1" ]; then
        echo "usage: $FUNCNAME FILE [REL_REV]
example:
        $FUNCNAME //depot/somefile.c
    will show diff2 of headRev - 1 and headRev of FILE
        $FUNCNAME //depot/somefile.c -1
    will show diff2 of headRev - 2 and headRev - 1 of FILE" >&2
        return 1
    fi
    local f=${1?arg1 (path) required}; shift
    local i=${1-0}; shift
    local hr=$(p4 -F%headRev% fstat $f)
    local r=$(($hr + $i))
    local rp=$(($r - 1))
    p4 diff2 -du ${f}#${rp} ${f}#${r}
}

function htp4clsw {
    : switch p4 client to a stream
    local stream=$1; shift
    if [ -z "$stream" ]; then
        echo "usage: $FUNCNAME STREAM" >&2
        return 1
    fi
    p4 client -s -S $stream "$@"
}

function htp4interc {
    : produce interchanges quoting original change and users
    if [ -z "$1" ]; then
        echo "usage: $FUNCNAME SPEC"
        echo "examples:"
        echo "   $FUNCNAME -b module_main_to_modules_stream_depot"
        echo "   $FUNCNAME -S //project/module-dev -r"
        return 1
    fi >&2
    p4 -ztag -F '%desc%(@%change% @%user%)' interchanges -l "$@" | sed 's/#review/review/g'
}

