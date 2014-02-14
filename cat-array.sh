#!/bin/sh

# Concatenates some files as if they each contain a valid JSON value, adding
# the appropriate brackets and commas.

echo -n '['
PRE=''

for f in "$@"; do
	echo $PRE
	PRE=','
	cat "$f"
done

echo ']'

	
	
