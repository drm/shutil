#!/usr/bin/env bash

## Usage:
##
##	./gnu.sh 
##
## A utility to detect some essential utilities that may be non-GNU
## on this system. For Mac, it suggests to use brew to install the GNU
## variants of the utilities.
## 
## By default, it only checks find, sed, awk, grep and diff. To override,
## pass the UTILS environment variable in the form:
##
## UTILS=$'utilname:brewpackage\nutil2name:util2package...etc'
##
## Specifiy BIN_DIR="" to. It defaults to ~/bin.

set -euo pipefail

BIN_DIR="${BIN_DIR:-~/bin}"
UTILS="${UTILS:-"
find:findutils
sed:gnu-sed
awk:gawk
grep:grep
diff:diffutils
"}"

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


for u in $UTILS; do
	util="${u/:*}"
	echo -ne "$util\t$(which $util):\t"; 

	if [ "$($util --version 2>/dev/null | head -1 | grep "GNU")" != "" ]; then
		echo "OK"; 
	else
		echo "ERROR: not GNU!"
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
			exit;
		else
			BREW_PREFIX="$("$BREW_BIN" --prefix)"
			echo "Here's a suggestion on how to fix things:"
			echo ""
			echo 'mkdir -p "'"$BIN_DIR"'"'
			awk_script='
				print "brew install "$2" && ( cd '$BIN_DIR' && ln -sf '$BREW_PREFIX'/opt/"$2"/libexec/gnubin/"$1" )"
			'

			for e in $err; do
				echo "$UTILS" | awk -F ":" '/^'$e':/ { '"$awk_script"' }'
			done
		fi
	else
		echo "Sorry, not sure what to do to help you. Please fix the above errors manually." 
	fi	
fi


