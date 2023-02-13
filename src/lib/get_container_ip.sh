function get_container_ip() {
  if [ -z "$1" ]; then exit 1; fi
  echo "$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $1)"
}