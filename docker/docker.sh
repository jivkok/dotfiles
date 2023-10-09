alias datt='docker attach'
alias ddiff='docker diff'
alias dimg='docker images'
alias dins='docker inspect'
alias dps='docker ps'
alias drm='docker rm'
alias drmi='docker rmi'
alias drun='docker run'
alias dstart='docker start'
alias dstop='docker stop'
alias deb='dexbash'
alias dceb='dcexbash'
alias dc='docker-compose'
alias dcb='docker-compose build'
alias dclogs='docker-compose logs'
alias dcup='docker-compose up'
alias dcdown='docker-compose down'
alias dcstart='docker-compose start'
alias dcstop='docker-compose stop'

# Lists tags for containers from the official Docker registry
docker-tags() {
  if [ $# -lt 1 ]; then
    echo "Usage: $FUNCNAME publisher/container <tag filter> <max page count>"
    return 1
  fi

  repository_name="$1"
  tag_filter="$2"
  max_page_count=${3:-10}

  if [[ "$repository_name" != *"/"* ]]; then
    # Official image, maintained by Docker
    repository_name="library/$repository_name"
  fi

  # curl -s "https://registry.hub.docker.com/v2/repositories/"$1"/tags/" | jq '."results"[]["name","last_updated"]'
  results='.'
  i=0
  while [[ -n "$results" && $i -lt $max_page_count ]]; do
    i=$((i + 1))

    results=$(curl -s "https://registry.hub.docker.com/v2/repositories/$repository_name/tags/?page=$i" | jq '."results"[]["name","last_updated"]')

    if [[ -n "$tag_filter" ]]; then
      echo "$results" | tr -d '"' | grep -i "$tag_filter"
    else
      echo "$results" | tr -d '"'
    fi

  done
}

# Run a bash shell in the specified container
dexbash() {
  if [ $# -ne 1 ]; then
    echo "Usage: $FUNCNAME CONTAINER_ID"
    return 1
  fi

  docker exec -it "$1" /bin/bash
}

# Run a bash shell in the specified container (with docker-compose)
dcexbash() {
  if [ $# -ne 1 ]; then
    echo "Usage: $FUNCNAME CONTAINER_ID"
    return 1
  fi

  docker-compose exec "$1" /bin/bash
}
