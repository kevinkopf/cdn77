#!/bin/bash

# Quick Config
MIN_CONTAINERS=2
MAX_CONTAINERS=5

# Some support logic
# Spinner taken from here: https://stackoverflow.com/a/20369590/3324556
spinner() {
  local pid=$!
  local delay=0.1
  local spinstr='|/-\'
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}

# Main logic
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

echo "I will run $NUM_CONTAINERS servers"

# Run multiple containers, but make sure no previous containers are recreated;
# to avoid non-clean containers spinning up
docker compose -f ./servers/docker-compose.yml up -d --scale server=$NUM_CONTAINERS --no-recreate

# Store container hashes in an array
RUNNING_SERVER_CONTAINERS=( $(docker compose -f ./servers/docker-compose.yml ps server -q) )
RUNNING_ANSIBLE_CONTAINER=$(docker compose -f ./servers/docker-compose.yml ps ansiblecm -q)
echo "[servers]" > ./playbooks/hosts
# PLEASE NOTICE!
# From this point forward I assume containers do not behave like containers, but like remote servers.
# Meaning, because I want to use Ansible, I will have to SSH between them to run Ansible Playbooks.
# If it were otherwise, running Prometheus, Grafana and other things would be a matter of using different Docker images.

# Let's configure the servers prior to starting anything.
# Allow containers to communicate with each other via ssh
docker compose -f ./servers/docker-compose.yml cp ./servers/.ssh server:/root/.ssh
docker compose -f ./servers/docker-compose.yml cp ./servers/.ssh ansiblecm:/root/.ssh

docker exec $RUNNING_ANSIBLE_CONTAINER chown -R root:root /root/.ssh

for CONTAINER_HASH in "${RUNNING_SERVER_CONTAINERS[@]}"
do :
    CONTAINER_NAME=$(docker inspect -f '{{.Name}}' $CONTAINER_HASH | cut -c2-)
    CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CONTAINER_HASH)

    echo "Started $CONTAINER_NAME with hash $CONTAINER_HASH available on $CONTAINER_IP"
    echo "Updating $CONTAINER_NAME"
    (docker exec -t $CONTAINER_HASH apt-get update -y > /dev/null) & spinner
    (docker exec -t $CONTAINER_HASH apt-get upgrade -y > /dev/null) & spinner
    echo "Installing dependencies"
    (docker exec -t $CONTAINER_HASH apt-get install -y ca-certificates gnupg openssh-client openssh-server software-properties-common > /dev/null) & spinner
    (docker exec -t $CONTAINER_HASH apt-get update -y > /dev/null) & spinner
    echo "Starting services $CONTAINER_NAME"
    (docker exec -t $CONTAINER_HASH service ssh start > /dev/null) & spinner
    docker exec $CONTAINER_HASH chown -R root:root /root/.ssh
    echo "$CONTAINER_NAME is ready"
    echo "$CONTAINER_NAME ansible_host=$CONTAINER_IP" >> ./playbooks/hosts
done
# And now we can connect over ssh between (containers) SERVERS!
# I know that "StrictHostKeyChecking no" in .ssh/config is not secure, but it will do for this demo.
# Containers are isolated on local machine anyway, so no worries.

# Last but not least, copy over the hosts file for Ansible into the container.
# I copy it over and not mapping it through volumes because I want to chown it to root
# And I don't want permission clashing on localhost.
echo "Configuring Ansible Control Node"
docker exec $RUNNING_ANSIBLE_CONTAINER mkdir /etc/ansible
docker compose -f ./servers/docker-compose.yml cp ./playbooks/hosts ansiblecm:/etc/ansible/hosts
docker exec $RUNNING_ANSIBLE_CONTAINER chown root:root /etc/ansible/hosts
rm ./playbooks/hosts
echo "Ansible Control Node is ready"
echo ""
read -p "Do you wish to test Ansible Control Node connection to all other servers? [y/N] " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]
then
    docker exec $RUNNING_ANSIBLE_CONTAINER ansible all -m ping -u root
fi