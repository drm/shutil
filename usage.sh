#!/usr/bin/env bash

# Prints the first '## ' commented block starting with '## Usage:'
usage() {
	echo ""
	awk '{ if(/^## Usage:/) { a=1; } if (!/^#/) { a=0; } if(a) {print;} }' < "${BASH_SOURCE[-1]}" | sed 's/^## \?//g'
	echo ""
}

# Prints usage to stderr, reporting a missing parameter.
missing() {
	usage >&2
	echo "Missing $1"
}

