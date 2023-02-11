#!/bin/sh

docker compose -f ./servers/docker-compose.yml ps -q | xargs docker rm -f -v