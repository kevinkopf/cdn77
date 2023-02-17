# Quick Config
MIN_CONTAINERS=8
MAX_CONTAINERS=8

cyan_bold "I am going to run Debian in multiple Docker containers."
cyan_bold "Now think of a number between $MIN_CONTAINERS and $MAX_CONTAINERS and type it in."
cyan_bold "That's how many containers I'm going to run."
cyan_bold "Leave blank for random number of containers."

if read -t 1 NUM_CONTAINERS; then
  NUM_CONTAINERS=$MAX_CONTAINERS
elif ! [[ "$NUM_CONTAINERS" =~ ^[0-9]+$ ]] ; then
   NUM_CONTAINERS=$(shuf -i $MIN_CONTAINERS-$MAX_CONTAINERS -n 1)
elif [ "$NUM_CONTAINERS" -gt "$MAX_CONTAINERS" ]; then
    NUM_CONTAINERS=$MIN_CONTAINERS
elif [ "$NUM_CONTAINERS" -lt "$MIN_CONTAINERS" ] || [ $? -eq 0 ]; then
    NUM_CONTAINERS=$MAX_CONTAINERS
fi

cyan "I will run $NUM_CONTAINERS servers"

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
sleep 5

green "Running Ansible Playbooks"
green "Prepare the server dependencies"
ansible_run -p prepare_servers.yml

INDEX_PROMETHEUS=0
INDEX_UPSTREAM_NGINX=1
INDEX_REVERSE_NGINX=2
INDEX_GRAFANA=3
INDEX_KAFKA_ONE=4
INDEX_KAFKA_TWO=5
INDEX_KAFKA_THR=6
INDEX_ZOOKEEPER=7

green "Setting up nginx"
ansible_run -p nginx.yml \
  -h "$(get_container_name ${RUNNING_SERVER_CONTAINERS[$INDEX_UPSTREAM_NGINX]})" \
  -h "$(get_container_name ${RUNNING_SERVER_CONTAINERS[$INDEX_REVERSE_NGINX]})"

green "Setting up caching reverse nginx"
ansible_run -p caching_reverse_proxy.yml \
  -h "$(get_container_name ${RUNNING_SERVER_CONTAINERS[$INDEX_REVERSE_NGINX]})" \
  -e "nginx_host=$(get_container_ip ${RUNNING_SERVER_CONTAINERS[$INDEX_UPSTREAM_NGINX]})"

green "Installing Prometheus"
ansible_run -p prometheus.yml \
  -h "$(get_container_name ${RUNNING_SERVER_CONTAINERS[$INDEX_PROMETHEUS]})" \
  -e "reverse_proxy=$(get_container_ip ${RUNNING_SERVER_CONTAINERS[$INDEX_REVERSE_NGINX]})"

green "Setting up Grafana"
ansible_run -p grafana.yml \
  -h "$(get_container_name ${RUNNING_SERVER_CONTAINERS[$INDEX_GRAFANA]})" \
  -e "prometheus_ip=$(get_container_ip ${RUNNING_SERVER_CONTAINERS[$INDEX_PROMETHEUS]})"

green "Prepare Kafka on Kafka and Zookeeper server"
ansible_run -p prepare_kafka.yml \
  -h "$(get_container_name ${RUNNING_SERVER_CONTAINERS[$INDEX_KAFKA_ONE]})" \
  -h "$(get_container_name ${RUNNING_SERVER_CONTAINERS[$INDEX_KAFKA_TWO]})" \
  -h "$(get_container_name ${RUNNING_SERVER_CONTAINERS[$INDEX_KAFKA_THR]})" \
  -h "$(get_container_name ${RUNNING_SERVER_CONTAINERS[$INDEX_ZOOKEEPER]})"

green "Set up Zookeeper"
ansible_run -p zookeeper.yml \
  -h "$(get_container_name ${RUNNING_SERVER_CONTAINERS[$INDEX_ZOOKEEPER]})" \
  -e "kafkas=$(get_container_ip ${RUNNING_SERVER_CONTAINERS[$INDEX_KAFKA_ONE]}),$(get_container_ip ${RUNNING_SERVER_CONTAINERS[$INDEX_KAFKA_TWO]}),$(get_container_ip ${RUNNING_SERVER_CONTAINERS[$INDEX_KAFKA_THR]})"

green "Set up Kafka servers"
ansible_run -p kafka.yml \
  -h "$(get_container_name ${RUNNING_SERVER_CONTAINERS[$INDEX_KAFKA_ONE]})" \
  -h "$(get_container_name ${RUNNING_SERVER_CONTAINERS[$INDEX_KAFKA_TWO]})" \
  -h "$(get_container_name ${RUNNING_SERVER_CONTAINERS[$INDEX_KAFKA_THR]})" \
  -e "zookeeper_ip=$(get_container_ip ${RUNNING_SERVER_CONTAINERS[$INDEX_ZOOKEEPER]})"

echo "Prometheus http://$(get_container_ip ${RUNNING_SERVER_CONTAINERS[$INDEX_PROMETHEUS]}):9090"
echo "Upstream nginx http://$(get_container_ip ${RUNNING_SERVER_CONTAINERS[$INDEX_UPSTREAM_NGINX]})"
echo "Caching reverse proxy nginx https://$(get_container_ip ${RUNNING_SERVER_CONTAINERS[$INDEX_REVERSE_NGINX]})"
echo "Grafana http://$(get_container_ip ${RUNNING_SERVER_CONTAINERS[$INDEX_GRAFANA]}):3000"