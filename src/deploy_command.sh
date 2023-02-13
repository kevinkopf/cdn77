# Quick Config
MIN_CONTAINERS=3
MAX_CONTAINERS=3

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

# PLEASE NOTICE!
# From this point forward I assume containers do not behave like containers, but like remote servers.
# Meaning, because I want to use Ansible, I will have to SSH between them to run Ansible Playbooks.
# If it were otherwise, running Prometheus, Grafana and other things would be a matter of using different Docker images.

# Let's configure the servers prior to starting anything.

prepare_servers "${RUNNING_SERVER_CONTAINERS[@]}"
# And now we can connect over ssh between (containers) SERVERS!
# I know that "StrictHostKeyChecking no" in .ssh/config is not secure, but it will do for this demo.
# Containers are isolated on local machine anyway, so no worries.

# Last but not least, copy over the hosts file for Ansible into the container.
# I copy it over and not map it through volumes because I want to chown it to root
# And I don't want permission clashing on localhost.
prepare_ansible $RUNNING_ANSIBLE_CONTAINER

echo "Ansible Control Node is ready"
echo ""
read -t 10 -p "Do you wish to test Ansible Control Node connection to all other servers? [y/N] " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]
then
    docker exec $RUNNING_ANSIBLE_CONTAINER ansible all -m ping
fi

echo "Running Ansible Playbooks"
echo "Installing Prometheus"
ansible_run -p monitoring.yml -h "$(get_container_name ${RUNNING_SERVER_CONTAINERS[0]})"
echo "Prometheus is running on $(get_container_ip ${RUNNING_SERVER_CONTAINERS[0]}):9090"

echo "Setting up nginx"
ansible_run -p nginx.yml -h "$(get_container_name ${RUNNING_SERVER_CONTAINERS[1]})" -h "$(get_container_name ${RUNNING_SERVER_CONTAINERS[2]})"
echo "nginx is running on $(get_container_ip ${RUNNING_SERVER_CONTAINERS[1]}):80"
echo "Another nginx is running on $(get_container_ip ${RUNNING_SERVER_CONTAINERS[2]}):80, preparing to set it up as reverse caching proxy"