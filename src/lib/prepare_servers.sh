function prepare_servers() {
  # Allow containers to communicate with each other via ssh
  docker compose -f ./servers/docker-compose.yml cp ./servers/.ssh server:/root/.ssh

  echo "[servers]" > ./playbooks/hosts

  RUNNING_SERVER_CONTAINERS=("$@")
  for CONTAINER_HASH in "${RUNNING_SERVER_CONTAINERS[@]}"
  do :
      CONTAINER_NAME=$(get_container_name $CONTAINER_HASH)
      CONTAINER_IP=$(get_container_ip $CONTAINER_HASH)
      echo "$CONTAINER_NAME ansible_host=$CONTAINER_IP" >> ./playbooks/hosts

      echo "Started $CONTAINER_NAME with hash $CONTAINER_HASH available on $CONTAINER_IP"
      echo "Updating $CONTAINER_NAME"
      (docker exec -t $CONTAINER_HASH apt-get update -y > /dev/null) & spinner
      (docker exec -t $CONTAINER_HASH apt-get upgrade -y > /dev/null) & spinner
      (docker exec -t $CONTAINER_HASH apt-get install -y \
                                                openssh-client \
                                                openssh-server \
                                                python3 \
                                                > /dev/null) & spinner
      (docker exec -t $CONTAINER_HASH apt-get update -y > /dev/null) & spinner
      echo "Starting services $CONTAINER_NAME"
      docker exec -t $CONTAINER_HASH service ssh start
      docker exec $CONTAINER_HASH chown -R root:root /root/.ssh
      echo "$CONTAINER_NAME is ready"
  done
  # And now we can connect over ssh between (containers) SERVERS!
  # I know that "StrictHostKeyChecking no" in .ssh/config is not secure, but it will do for this demo.
  # Containers are isolated on local machine anyway, so no worries.
}