function prepare_ansible() {
  echo "Configuring Ansible Control Node"
  docker compose -f ./servers/docker-compose.yml cp ./servers/.ssh ansiblecm:/root/.ssh
  docker exec $1 chown -R root:root /root/.ssh
  docker exec $1 mkdir /etc/ansible
  docker compose -f ./servers/docker-compose.yml cp ./playbooks/hosts ansiblecm:/etc/ansible/hosts
  docker exec $1 chown root:root /etc/ansible/hosts
  rm ./playbooks/hosts

  # and 8 years later `docker cp` still doesn't support wildcards...
  # https://github.com/moby/moby/issues/7710
  for file in ./playbooks/*; do
    docker compose -f ./servers/docker-compose.yml cp "$file" "ansiblecm:/tmp/playbook/"
  done

  docker exec $1 chown -R root:root /tmp/playbook
}