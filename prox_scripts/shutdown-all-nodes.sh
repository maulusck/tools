#!/bin/bash

read -p "Press ENTER to begin shutdown of all nodes: "
read -p "Press ENTER again: "
echo "Begin..."

#NODES="prxnode1 prxnode2 prxnode3 prxnode4"
NODES="prxnode1 prxnode3 prxnode4"

SELF=$(hostname)
NODES=$(echo $NODES | sed "s/$SELF//g")

SHUTDOWN_VMS="/root/tools/shutdown-all-vm.sh"

# shut down VMs
for n in $NODES; do
	echo "Shutting down VMs on $n..."
	timeout 20 ssh $n $SHUTDOWN_VMS
done
# shut down nodes
for n in $NODES; do
	echo "Shutting down node $n..."
	ssh $n poweroff
done
# shut down self
echo "Shutting down self ($SELF)..."
$SHUTDOWN_VMS
poweroff

# should be ok
echo "Done."
