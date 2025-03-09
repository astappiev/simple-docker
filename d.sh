#!/bin/bash
#
# Docker simplified.
# https://github.com/astappiev/simple-docker
#

# Helper function to print container info
_print_container_info() {
    local container_id="$1"
    [ -z "$container_id" ] && return

    local container_inspect
    container_inspect=$(docker container inspect --format \
        '{{slice .Id 0 12}},{{slice .Name 1}},{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}},'\
'{{range $p, $conf := .NetworkSettings.Ports}}{{if $conf}}{{if ne (index $conf 0).HostIp "0.0.0.0"}}{{(index $conf 0).HostIp}}:{{end}}{{(index $conf 0).HostPort}}{{else}}null{{end}}:{{$p}} {{end}},'\
'{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}},{{range .NetworkSettings.Networks}}{{.Gateway}} {{end}}' \
        "$container_id")

    echo "$container_inspect" >>/tmp/d.ip.txt
}

# Helper function to print network info
_print_network_info() {
    local network_id="$1"
    [ -z "$network_id" ] && return

    local network_inspect
    network_inspect=$(docker network inspect --format \
        '{{slice .Id 0 12}},{{.Name}},{{range .IPAM.Config}}{{.Subnet}}{{end}},{{range .IPAM.Config}}{{if (index . "Gateway")}}{{.Gateway}}{{end}}{{end}}' \
        "$network_id")

    echo "$network_inspect" >>/tmp/d.net.txt
}

# ip [id] - Prints out a container's name, IPs, ports, networks and gateways. If no id or name provided, prints info for all containers.
function d.ip() {
    echo "Container Id,Container Name,Container IPs,Container Ports,Container Networks,Container Gateways" >/tmp/d.ip.txt

    local all_flag=""
    local container_search="$1"
    if [ "$1" == "-all" ]; then
        all_flag="-a"
        container_search="$2"
    fi

    if [ -z "$container_search" ]; then
        docker ps $all_flag -q | while read -r container_id; do
            _print_container_info "$container_id"
        done
    else
        docker container ls $all_flag --format "{{.ID}} {{.Names}}" | \
        awk "/^$container_search|[[:space:]]$container_search/ {print \$1}" | \
        while read -r container_id; do
            _print_container_info "$container_id"
        done
    fi

    awk -F, '{ for (i=1; i<=NF; i++) printf "%-20s", $i; print "" }' /tmp/d.ip.txt
    #column -s "," -t /tmp/d.ip.txt
    rm -f /tmp/d.ip.txt
}

# net [id] - Prints out a networks's name, IPs and gateways. If no id or name provided, prints info for all networks.
function d.net() {
    echo "Network ID,Network Name,Network Subnet,Network Gateway" >/tmp/d.net.txt

    local network_id
    local network_search="$1"

    if [ -z "$network_search" ]; then
        docker network ls --format "{{.ID}}" | while read -r network_id; do
            _print_network_info "$network_id"
        done
    else
        docker network ls --format "{{.ID}} {{.Name}}" | \
        awk "/^$network_search|[[:space:]]$network_search/ {print \$1}" | \
        while read -r network_id; do
            _print_network_info "$network_id"
        done
    fi

    column -s "," -t /tmp/d.net.txt
    rm /tmp/d.net.txt
}

# sh [id] - Attach a shell to a docker with an id
function d.sh() {
    if [ -z "$2" ]; then
        docker exec -it "$1" /bin/sh -c "[ -e /bin/bash ] && /bin/bash || /bin/sh"
    else
        docker exec -u "$1" -it "$2" /bin/sh -c "[ -e /bin/bash ] && /bin/bash || /bin/sh"
    fi
}

# logs [id] - Tail and follow the logs of a docker container
function d.logs() {
    local num_lines="$1"
    local container_id="$2"

    if [ -z "$container_id" ]; then
        docker logs -fn 0 "$num_lines"
    else
        docker logs -fn "$num_lines" "$container_id"
    fi
}

# v [filter] - Print volumes with sizes
function d.v() {
    local filter="$1"
    if [ -z "$filter" ]; then
        docker volume ls -f dangling=true --format '{{ .Mountpoint }}' | sudo xargs -L1 du -sh
    elif [ "$filter" == "all" ]; then
        docker volume ls --format '{{ .Mountpoint }}' | sudo xargs -L1 du -sh
    else
        docker volume ls -f "$filter" --format '{{ .Mountpoint }}' | sudo xargs -L1 du -sh
    fi
}

# bb [command] - Start a busybox container with an optional command
function d.bb() {
    if [ -t 0 ]; then
        docker run -it --rm busybox "$@"
    else
        docker run -i --rm busybox "$@"
    fi
}

# bb [command] - Start a ubuntu container with an optional command
function d.ub() {
    if [ -t 0 ]; then
        docker run -it --rm catthehacker/ubuntu:act-latest "$@"
    else
        docker run -i --rm catthehacker/ubuntu:act-latest "$@"
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
        echo "d logs [NUM_LINES] <ID>  tail (and follow) a container's logs (0 lines if blank)"
        echo "d bb [COMMAND]           start a busybox container with optional command"
        echo "d ub [COMMAND]           start a busybox container with optional command"
    fi
}

if [ "$(type -t d."$1")" == "function" ]; then
    "d.$@"
elif [ "$1" == "-h" ]; then
    d.help
elif [ -z "$1" ]; then
    docker $@
fi
