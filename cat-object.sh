#!/bin/sh

# Concatenates some files as if they each contain a valid JSON value,
# associating each file with its basename as a key (assuming no escaping is
# required), adding the appropriate braces and commas.

echo -n '{'
PRE=''

for f in "$@"; do
	echo $PRE
	PRE=','
	key=`basename $f .json.tmp`
	echo -n '"'"$key"'": '
	cat "$f"
done

echo '}'

