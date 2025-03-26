#!/bin/bash
#
# Docker simplified.
# https://github.com/astappiev/simple-docker
#

# global variables
DOCKER="docker"

# ip [id] - Prints out a container's name, IPs, ports, networks and gateways. If no id or name provided, prints info for all containers.
function d.ip() {
    local all_flag=""
    local container_search="$1"
    if [ "$1" == "-all" ]; then
        all_flag="-a"
        container_search="$2"
    fi

    local output="Container Id,Name,IPs,Ports,Networks,Gateways"
    local container_ids=()

    if [ -z "$container_search" ]; then
        mapfile -t container_ids < <($DOCKER ps $all_flag -q)
    else
        mapfile -t container_ids < <($DOCKER container ls $all_flag --format "{{.ID}} {{.Names}}" |
            awk "/^$container_search|[[:space:]]$container_search/ {print \$1}")
    fi

    for container_id in "${container_ids[@]}"; do
        [ -z "$container_id" ] && continue
        local info=$($DOCKER container inspect --format \
            '{{slice .Id 0 12}},{{slice .Name 1}},{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}},{{range $p, $conf := .NetworkSettings.Ports}}{{if $conf}}{{if ne (index $conf 0).HostIp "0.0.0.0"}}{{(index $conf 0).HostIp}}:{{end}}{{(index $conf 0).HostPort}}{{else}}null{{end}}:{{$p}} {{end}},{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}},{{range .NetworkSettings.Networks}}{{.Gateway}} {{end}}' \
            "$container_id")
        output+=$'\n'"$info"
    done

    echo "$output" | awk -F, '{ for (i=1; i<=NF; i++) printf "%-20s", $i; print "" }'
}

# net [id] - Prints out a networks's name, IPs and gateways. If no id or name provided, prints info for all networks.
function d.net() {
    local network_search="$1"

    local output="Network ID,Name,Subnet,Gateway"
    local network_ids=()

    if [ -z "$network_search" ]; then
        mapfile -t network_ids < <($DOCKER network ls --format "{{.ID}}")
    else
        mapfile -t network_ids < <($DOCKER network ls --format "{{.ID}} {{.Name}}" |
            awk "/^$network_search|[[:space:]]$network_search/ {print \$1}")
    fi

    for network_id in "${network_ids[@]}"; do
        [ -z "$network_id" ] && continue
        local info=$($DOCKER network inspect --format \
            '{{slice .Id 0 12}},{{.Name}},{{range .IPAM.Config}}{{.Subnet}}{{end}},{{range .IPAM.Config}}{{if (index . "Gateway")}}{{.Gateway}}{{end}}{{end}}' \
            "$network_id")
        output+=$'\n'"$info"
    done

    echo "$output" | awk -F, '{ for (i=1; i<=NF; i++) printf "%-20s", $i; print "" }'
}

# sh [id] - Attach a shell to a container
function d.sh() {
    if [ -z "$2" ]; then
        $DOCKER exec -it "$1" /bin/sh -c "[ -e /bin/bash ] && /bin/bash || /bin/sh"
    else
        $DOCKER exec -u "$1" -it "$2" /bin/sh -c "[ -e /bin/bash ] && /bin/bash || /bin/sh"
    fi
}

# l [id] - Tail and follow the logs of the container
function d.l() {
    local num_lines="$1"
    local container_id="$2"

    if [ -z "$container_id" ]; then
        $DOCKER logs -fn 0 "$num_lines"
    else
        $DOCKER logs -fn "$num_lines" "$container_id"
    fi
}

# v [filter] - Print volumes with sizes
function d.v() {
    local filter="$1"
    if [ -z "$filter" ]; then
        $DOCKER volume ls -f dangling=true --format '{{ .Mountpoint }}' | sudo xargs -L1 du -sh
    elif [ "$filter" == "all" ]; then
        $DOCKER volume ls --format '{{ .Mountpoint }}' | sudo xargs -L1 du -sh
    else
        $DOCKER volume ls -f "$filter" --format '{{ .Mountpoint }}' | sudo xargs -L1 du -sh
    fi
}

# bb [command] - Start a busybox container with an optional command
function d.bb() {
    if [ -t 0 ]; then
        $DOCKER run -it --rm busybox "$@"
    else
        $DOCKER run -i --rm busybox "$@"
    fi
}

# bb [command] - Start a ubuntu container with an optional command
function d.ub() {
    if [ -t 0 ]; then
        $DOCKER run -it --rm catthehacker/ubuntu:act-latest "$@"
    else
        $DOCKER run -i --rm catthehacker/ubuntu:act-latest "$@"
    fi
}

# help [command] - Show help for a specific command
function d.help() {
    if [ "$(type -t d."$1")" == "function" ]; then
        declare -f "d.$1" | sed '1,2d;$d' | sed -e "s/^    //"
    else
        echo "d                        alias for \`docker\`"
        echo "d ip [-all] [ID]         print a container's name, IPs, ports, networks and gateways (all containers running if blank)"
        echo "                          -all option to search non running containers"
        echo "d net [ID]               print a networks's name, IPs and gateways (all networks if blank)"
        echo "d v [filter]             prints volumes with sizes (dangling if blank, all if 'all')"
        echo "d sh [USERNAME] <ID>     bash into a container with optional username"
        echo "d l [NUM_LINES] <ID>     tail (and follow) a container's logs (0 lines if blank)"
        echo "d bb [COMMAND]           start a busybox container with optional command"
        echo "d ub [COMMAND]           start a busybox container with optional command"
    fi
}

if [ "$(type -t d."$1")" == "function" ]; then
    "d.$@"
elif [ "$1" == "-h" ]; then
    d.help
else
    $DOCKER $@
fi
