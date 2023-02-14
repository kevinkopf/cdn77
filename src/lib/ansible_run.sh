function ansible_run() {
  local PLAYBOOK
  local HOSTS
  local EXTRA_VARS
  local PARAM=()

  while :; do
    case $1 in
      -p|--playbook)
        PLAYBOOK=$2
        shift
      ;;
      -h|--host)
        if [ -z "$HOSTS" ]; then
          HOSTS="passed_hosts=$2"
        else
          HOSTS="${HOSTS},$2"
        fi
        shift
      ;;
      -e|--extra)
        if [ -z "$EXTRA_VARS" ]; then
          EXTRA_VARS=$2
        else
          EXTRA_VARS="${EXTRA_VARS},$2"
        fi
        shift
      ;;
      *) break
    esac
    shift
  done

  if [ -n "$EXTRA_VARS" ] || [ -n "$HOSTS" ]; then
    PARAM=(--extra-vars="$HOSTS $EXTRA_VARS")
  fi

  docker exec -t "$(get_ansible_container)" ansible-playbook "$PLAYBOOK" "${PARAM[@]}"
}