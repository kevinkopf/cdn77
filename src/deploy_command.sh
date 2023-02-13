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
elif [ "$NUM_CONTAINERS" -gt "$MAX_CONTAINERS" ]; then
    NUM_CONTAINERS=$MIN_CONTAINERS
elif [ "$NUM_CONTAINERS" -lt "$MIN_CONTAINERS" ]; then
    NUM_CONTAINERS=$MAX_CONTAINERS
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

prepare_servers "${RUNNING_SERVER_CONTAINERS[@]}"
prepare_ansible $RUNNING_ANSIBLE_CONTAINER

echo "Ansible Control Node is ready"

echo "Running Ansible Playbooks"
echo "Installing Prometheus"
ansible_run -p monitoring.yml -h "$(get_container_name ${RUNNING_SERVER_CONTAINERS[0]})"
echo "Prometheus is running on http://$(get_container_ip ${RUNNING_SERVER_CONTAINERS[0]}):9090"

echo "Setting up nginx"
ansible_run -p nginx.yml -h "$(get_container_name ${RUNNING_SERVER_CONTAINERS[1]})" -h "$(get_container_name ${RUNNING_SERVER_CONTAINERS[2]})"
echo "nginx is running on http://$(get_container_ip ${RUNNING_SERVER_CONTAINERS[1]})"
echo "Another nginx is running on http://$(get_container_ip ${RUNNING_SERVER_CONTAINERS[2]}), preparing to set it up as reverse caching proxy"

echo "Setting up caching reverse nginx"
ansible_run -p caching_reverse_proxy.yml -h "$(get_container_name ${RUNNING_SERVER_CONTAINERS[2]})" -e "nginx_host=$(get_container_ip ${RUNNING_SERVER_CONTAINERS[1]})"
echo "Caching reverse nginx is running on http://$(get_container_ip ${RUNNING_SERVER_CONTAINERS[2]})"