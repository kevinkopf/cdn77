function get_container_name() {
  if [ -z "$1" ]; then exit 1; fi
  echo "$(docker inspect -f '{{.Name}}' $1 | cut -c2-)"
}