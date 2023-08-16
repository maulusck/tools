#!/bin/bash

read -p "Press ENTER to begin shutdown of all nodes: "
read -p "Press ENTER again: "
echo "Begin..."

NODES="prxnode1 prxnode2 prxnode3 prxnode4"

SELF=$(hostname)
NODES=$(echo $NODES | sed "s/$SELF//g")

SHUTDOWN_SCRIPT="./shutdown-all-guests.sh"
MAX_TIME_WAIT=30

# shut down guests
for n in $NODES; do
	echo "Shutting down guests on $n..."
	timeout $MAX_TIME_WAIT ssh $n $SHUTDOWN_SCRIPT
done
# shut down nodes
for n in $NODES; do
	echo "Shutting down node $n..."
	ssh $n poweroff
done
# shut down self
echo "Shutting down self ($SELF)..."
timeout $MAX_TIME_WAIT $SHUTDOWN_SCRIPT
poweroff

# should be ok
echo "Done."
