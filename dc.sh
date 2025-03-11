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
    $DOCKER_COMPOSE logs -f $@
}

# Start docker compose
# If `-f` is passed, follow the logs (similar to native `docker compose up`, but you can simply cancel it with `Ctrl+C` and container continues to run)
function dc.u() {
    local args=()
    local follow=false
    for arg in "$@"; do
        if [ "$arg" != "-f" ]; then
            args+=("$arg")
        else
            follow=true
        fi
    done

    $DOCKER_COMPOSE up -d "${args[@]}"

    if [ "$follow" = true ]; then
        $DOCKER_COMPOSE logs -f "${args[@]}"
    fi
}

# Start docker compose
function dc.d() {
    $DOCKER_COMPOSE down -t $DEFAULT_TIMEOUT --remove-orphans $@
}

# Restart docker compose
function dc.r() {
    $DOCKER_COMPOSE down -t $DEFAULT_TIMEOUT --remove-orphans $@
    $DOCKER_COMPOSE up -d $@
}

# Start docker compose and follow the logs
function dc.ul() {
    $DOCKER_COMPOSE up -d $@
    $DOCKER_COMPOSE logs -f $@
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
        echo "dc u [-f] [...]           alias for \`docker compose up\`"
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
else
    $DOCKER_COMPOSE $@
fi
