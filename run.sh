#!/bin/bash

# Quick Config
MIN_CONTAINERS=2
MAX_CONTAINERS=5

# Logic
echo "I am going to run Debian in multiple Docker containers."
echo "Now think of a number between $MIN_CONTAINERS and $MAX_CONTAINERS and type it in."
echo "That's how many containers I'm going to run."
echo "Leave blank for random number of containers."

read NUM_CONTAINERS

if ! [[ "$NUM_CONTAINERS" =~ ^[0-9]+$ ]] ; then
   NUM_CONTAINERS=$(shuf -i $MIN_CONTAINERS-$MAX_CONTAINERS -n 1)
elif [ "$NUM_CONTAINERS" -gt "$MIN_CONTAINERS" ]; then
    NUM_CONTAINERS=5
elif [ "$NUM_CONTAINERS" -lt "$MAX_CONTAINERS" ]; then
    NUM_CONTAINERS=2
fi

echo "I will run $NUM_CONTAINERS now"

# Run multiple containers, but make sure no previous containers are recreated;
# to avoid non-clean containers spinning up
docker compose -f ./servers/docker-compose.yml up -d --scale server=$NUM_CONTAINERS --no-recreate

# Store container hashes in an array
RUNNING_CONTAINERS=( $(docker compose -f ./servers/docker-compose.yml ps -q) )

for i in "${RUNNING_CONTAINERS[@]}"
do
   :
   echo "Started container with hash $i"
done