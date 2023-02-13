function get_ansible_container() {
  echo "$(docker compose -f ./servers/docker-compose.yml ps ansiblecm -q)"
}