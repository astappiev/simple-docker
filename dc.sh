#!/bin/bash
#
# Docker compose simplified.
# https://github.com/astappiev/simple-docker
#

# global variables
DOCKER_COMPOSE="docker compose"
DEFAULT_TIMEOUT=120

# Logs of the docker compose
function dc.l() {
    $DOCKER_COMPOSE logs $1
}

# Start docker compose
function dc.u() {
    $DOCKER_COMPOSE up $1
}

# Start docker compose
function dc.d() {
    $DOCKER_COMPOSE down -t $DEFAULT_TIMEOUT $1
}

# Restart docker compose
function dc.r() {
    $DOCKER_COMPOSE down -t $DEFAULT_TIMEOUT $1
    $DOCKER_COMPOSE up -d --remove-orphans $1
}

# Start docker compose and follow the logs
function dc.ul() {
    $DOCKER_COMPOSE up -d $1
    $DOCKER_COMPOSE logs -f $1
}

# Attach to a running container
function dc.sh() {
    $DOCKER_COMPOSE exec $1 /bin/sh -c "[ -e /bin/bash ] && /bin/bash || /bin/sh"
}

# help [command] - Show help for a specific command
function dc.help() {
    if [ "$(type -t dc."$1")" == "function" ]; then
        declare -f "dc.$1" | sed '1,2d;$d' | sed -e "s/^    //"
    else
        echo "dc [...]                  alias for \`docker compose\`"
        echo "dc u [...]                alias for \`docker compose up\`"
        echo "dc d [...]                alias for \`docker compose down\`"
        echo "dc l [...]                alias for \`docker compose logs\`"
        echo "dc r [container]          restart docker compose (down + up)"
        echo "dc ul [container]         start container and follow the logs"
        echo "dc sh [container]         attach to a running container"
    fi
}

if [ "$(type -t dc."$1")" == "function" ]; then
    "dc.$@"
elif [ "$1" == "-h" ]; then
    dc.help
elif [ -z "$1" ]; then
    $DOCKER_COMPOSE $@
fi
