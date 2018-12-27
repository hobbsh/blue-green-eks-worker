#!/bin/bash -e

#
# Author: Wylie Hobbs - 2018
#
# Drains the given node group in a kubernetes cluster based on a label value
# usage:
#    normal:  ./drain_old_nodes.sh 'eks_worker_group=blue'
#    dry run: ./drain_old_nodes.sh 'eks_worker_group=blue' noop

WORKER_GROUP_LABEL="$1"
DRY_RUN="$2"

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

#Not a great way of getting the nodes to drain based on grepping the AGE - this could break if there's a match in the node name"
NODES=$(kubectl get no --no-headers -l $WORKER_GROUP_LABEL | awk '{print $1}' | grep -v "No resources found.")

#Confirm the nodes to drain because the above command is weak
echo -e "Going to drain the following nodes: \n${NODES} \n\nWould you like to proceed (Y/N)?"
read proceed

if [ "$proceed" == "Y" ]; then
  echo "Waiting 10 seconds to drain nodes, in case you pressed the wrong key..."
  sleep 10

  if [ ${#NODES[@]} -ne 0 ]; then
    for NODE in ${NODES[@]}; do
      if [ "$NODE" != "" ]; then
        drain $NODE
      else
        echo "Node name is empty. Doing nothing"
      fi
    done
  else
    echo "No nodes found containing label '$WORKER_GROUP_LABEL'. Exiting."
    exit 1
  fi
else
  echo "You elected to not proceed with the draining - your input was: '$proceed'. Maybe you meant 'Y'? Exiting."
  exit 0
fi

