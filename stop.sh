#!/bin/sh

. `dirname $0`/common.sh

echo $VARRUN

for i in $VARRUN/thin.pid $VARRUN/thin6.pid
do
	pid=`cat $i` 2> /dev/null 2> /dev/null && \
	kill -2 $pid && \
	sleep 1      && \
	kill -9 $pid 2> /dev/null

	rm -f $i
done


