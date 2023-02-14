function prepare_ansible() {
  # Copy over the hosts file for Ansible into the container.
  # I copy it over and not map it through volumes because I want to chown it to root
  # And I don't want permission clashing on localhost.
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

  # Test the connection from Ansible to other servers
  docker exec $RUNNING_ANSIBLE_CONTAINER ansible all -m ping
  green "Ansible Control Node is ready"
}