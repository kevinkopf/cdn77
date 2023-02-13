function ansible_run() {
  local PLAYBOOK
  local HOSTS

  while :; do
    case $1 in
      -p|--playbook)
        PLAYBOOK=$2
        shift
      ;;
      -h|--host)
        if [ -z "$HOSTS" ]; then
          HOSTS=$2
        else
          HOSTS="${HOSTS},$2"
        fi
        shift
      ;;
      *) break
    esac
    shift
  done

  docker exec -t "$(get_ansible_container)" ansible-playbook "$PLAYBOOK" --extra-vars="passed_hosts=$HOSTS"
}