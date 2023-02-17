##
# Run multiple scripts in parallel like this:
#
# 	source shutil/bg.sh
#
# 	fn() {
# 		sleep 1;
# 		echo "This took one second"
# 	}
#
# 	fn2() {
# 		sleep 1;
# 		echo "This took one second too"
#	}
#
# 	background fn1
# 	background fn2
#
# 	time waitall
#
# Output:
#
#	This took one second
#	This took one second too
#
#	real	0m1.017s
#	user	0m0.010s
#	sys	0m0.023s
#	Waiting for child processes to finish ...
#	
# (or something similar)
#

_TRAPPED=""
_INT_COUNT=0

force_kill() {
	kill "$1" 9
}

_all_pids() {
	local what="$1"
	for pid in ${BG_PIDS[@]}; do
		if ps -p $pid > /dev/null; then
			$what $pid;
		fi
	done;
}

background() {
	if [ "$_TRAPPED" == "" ]; then
		_TRAPPED="1"
		trap waitall EXIT;
		trap cleanup SIGINT;
	fi

	( $@ ) &
	BG_PIDS+=( $! );
}

cleanup() {
	_filter_pids
	if [ "${BG_PIDS[@]}" != "" ]; then
		echo "Killing child processes ..."

		_INT_COUNT=$(($_INT_COUNT + 1))

		if [[ $_INT_COUNT -gt 2 ]]; then
			_all_pids force_kill
			if [[ $_INT_COUNT -gt 3 ]]; then
				echo "Giving up..."
				exit
			fi
		else
			_all_pids 'kill'
		fi
	fi
}

_filter_pids() {
	BG_PIDS=("$(_all_pids echo)")
}

waitall() {
	_filter_pids
	if [ "${BG_PIDS[@]}" != "" ]; then
		echo "Waiting for child processes to finish ..."
		_all_pids 'wait'
	fi
}
