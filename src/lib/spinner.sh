# Spinner taken from here: https://stackoverflow.com/a/20369590/3324556
function spinner() {
  local pid=$!
  local delay=0.1
  local spinstr='|/-\'
  stty -echo
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  stty echo
  printf "    \b\b\b\b"
}