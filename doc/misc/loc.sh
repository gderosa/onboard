#!/bin/sh

# Counts lines of code. Execute in the project top level dir.

#find . -name \*.rb -or -name \*.erb -and -not -wholename lib/json_printer \
#	| xargs wc

find . -name \*.rb -and -not -wholename lib/json_printer \
	| xargs wc

find . -name \*.erb -and -not -wholename lib/json_printer \
	| xargs wc

	

