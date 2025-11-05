#!/usr/bin/env bash

## Usage:
##
##	./gnu.sh 
##
## A utility to detect some essential utilities that may be non-GNU
## on this system. For Mac, it suggests to use brew to install the GNU
## variants of the utilities.
## 
## By default, it only checks find, sed, awk, grep and diff, which are
## the most common tools to use in bash scripting. For other utils, typically
## BSD utils are fairly similar to GNU. For a more complete override of all
## local utilities, you can either override UTILS as such:
##
## UTILS=$'utilname:brewpackage\nutil2name:util2package...etc' ./gnu.sh
##
## ... or simply use another utility that more completely tries to GNUify
## your environment.
##
## Specifiy BIN_DIR="" to set the BIN_DIR where to install the utils. It
## is added to the PATH while running the script, so you're not required to
## have it on your PATH to begin with. That way you don't need to install
## it on your global PATH, even though you obviously you still can.

set -euo pipefail

BIN_DIR="${BIN_DIR:-~/bin}"
UTILS="${UTILS:-"
	find:findutils:/GNU/ && ! /BSD/
	sed:gnu-sed:/GNU/ && ! /BSD/
	awk:gawk:/GNU/ && ! /BSD/
	grep:grep:/GNU/ && ! /BSD/
	diff:diffutils:/GNU/ && ! /BSD/
	jq:jq:/jq-1/"
}"

export PATH="$BIN_DIR:$PATH"

os=""
err=""

case "$OSTYPE" in
	linux-gnu*)
		echo "You're on GNU/Linux, you should be fine"
		os="L"
		;;
	mac*|darwin*)
		echo "You're on MAC, let's verify these utils..." 
		os="M"
		;;
	*)
		echo "Don't know this OS type, don't support it, all bets are off."
		echo "Nevertheless, if everything reports OK, you should be fine."
		;;
esac
echo ""

echo "$UTILS" | awk '/./' | while IFS=":" read util package pattern; do
	which_util="$(which $util || true)"
	header="$($util --version 2>/dev/null | head -1)"
	echo -ne "$util\t$which_util:\t";

	if [ "$(echo "$header" | awk "$pattern")" != "" ]; then
		echo "OK"; 
	else
		echo "ERROR: $header for util '$which_util' does not match pattern $pattern!"
		err="$err $util"
	fi
done;


echo ""
if [ "$err" != "" ]; then
	if [ "$os" == "M" ]; then
		BREW_BIN="$(which brew 2>/dev/null || true)"
		BREW_BIN="${BREW_BIN:-/usr/local/bin/brew}"

		if [ -f "/opt/homebrew/bin/brew" ]; then
			BREW_BIN="/opt/homebrew/bin/brew"
		fi
		if ! [ -x "$BREW_BIN" ]; then
			echo "brew is not installed..."
			echo "Giving up."
			exit 1;
		else
			BREW_PREFIX="$("$BREW_BIN" --prefix)"
			echo "Here's a suggestion on how to fix things:"
			echo ""
			echo 'mkdir -p "'"$BIN_DIR"'"'
			awk_script='
				print "brew install "$2" && ( cd '$BIN_DIR' && ln -sf '$BREW_PREFIX'/opt/"$2"/libexec/gnubin/"$1" )"
			'

			for e in $err; do
				echo "$UTILS" | awk -F ":" '/^'"$e"':/ { '"$awk_script"' }'
			done
		fi
	else
		echo "Sorry, not sure what to do to help you. Please fix the above errors manually." 
	fi	

	exit 1;
fi


