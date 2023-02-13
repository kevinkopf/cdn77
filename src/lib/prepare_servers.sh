function prepare_servers() {
  # Allow containers to communicate with each other via ssh
  docker compose -f ./servers/docker-compose.yml cp ./servers/.ssh server:/root/.ssh

  echo "[servers]" > ./playbooks/hosts

  RUNNING_SERVER_CONTAINERS=("$@")
  for CONTAINER_HASH in "${RUNNING_SERVER_CONTAINERS[@]}"
  do :
      CONTAINER_NAME=$(get_container_name $CONTAINER_HASH)
      CONTAINER_IP=$(get_container_ip $CONTAINER_HASH)

      echo "Started $CONTAINER_NAME with hash $CONTAINER_HASH available on $CONTAINER_IP"
      echo "Updating $CONTAINER_NAME"
      (docker exec -t $CONTAINER_HASH apt-get update -y > /dev/null) & spinner
      (docker exec -t $CONTAINER_HASH apt-get upgrade -y > /dev/null) & spinner
      echo "Installing dependencies"
      (docker exec -t $CONTAINER_HASH apt-get install -y \
                                              ca-certificates \
                                              curl \
                                              gnupg \
                                              openssh-client \
                                              openssh-server \
                                              software-properties-common \
                                              sudo \
                                              wget \
                                      > /dev/null) & spinner
      (docker exec -t $CONTAINER_HASH apt-get update -y > /dev/null) & spinner
      echo "Starting services $CONTAINER_NAME"
      (docker exec -t $CONTAINER_HASH service ssh start > /dev/null) & spinner
      docker exec $CONTAINER_HASH chown -R root:root /root/.ssh
      echo "$CONTAINER_NAME is ready"
      echo "$CONTAINER_NAME ansible_host=$CONTAINER_IP" >> ./playbooks/hosts
  done
}