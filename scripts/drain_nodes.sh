#!/bin/bash -e

#
# Author: Wylie Hobbs - 2018
#
# Drains the oldest node group in a kubernetes cluster
# usage:
#    normal:  ./drain_old_nodes.sh
#    dry run: ./drain_old_nodes.sh noop

DRY_RUN="$1"

function drain(){
  if [ "$DRY_RUN" == "noop" ]; then
    echo "Dry run specified - just echo'ing what would happen..."
    echo "kubectl drain $1 --ignore-daemonsets=true --delete-local-data --force"
  elif [ "$DRY_RUN" == "" ]; then
    kubectl drain $1 --ignore-daemonsets=true --delete-local-data
  else
    echo "Unknown value '$DRY_RUN' specified for dry-run - should be 'noop' or blank"
    exit 1
  fi

  if [ $? -eq 0 ]; then
    echo "Node $1 drained - sleeping for 10 seconds"
    sleep 10
  else
    echo "Failed to drain $1 - exiting"
    exit 1
  fi
}

#Get the AGE of the oldest node group to target for draining
AGE=$(kubectl get no --no-headers=true --sort-by=.metadata.creationTimestamp | awk '{print $4}' | head -n 1) 

#Not a great way of getting the nodes to drain based on grepping the AGE - this could break if there's a match in the node name"
NODES=$(kubectl get no | awk '{print $4" "$1}' | grep $AGE | awk '{print $2}')

#Confirm the nodes to drain because the above command is weak
echo -e "Going to drain \n${NODES} \n\nWould you like to proceed (Y/N)?"
read proceed

if [ "$proceed" == "Y" ]; then
  echo "Waiting 10 seconds to drain nodes, in case you pressed the wrong key..."
  sleep 10

  if [ "$AGE" != "" ]; then
    for NODE in ${NODES[@]}; do
      if [ "$NODE" != "" ]; then
        drain $NODE
      else
        echo "Node name is empty. Doing nothing"
      fi
    done
  else
    echo "Could not determine age of oldest nodes - exiting"
    exit 1
  fi
else
  echo "You elected to not proceed with the draining - your input was: '$proceed'. Maybe you meant 'Y'? Exiting."
  exit 0
fi

