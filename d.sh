#!/usr/bin/env bash
#
# Docker simplified.
# https://github.com/astappiev/simple-docker
#

# global variables
DOCKER=(docker)

# Validate docker is available
command -v "${DOCKER[0]}" &>/dev/null || {
	echo "Error: '${DOCKER[0]}' not found in PATH"
	return 1 2>/dev/null || exit 1
}

# Helper function to print comma-separated data as aligned columns
function _print_table() {
	awk -F, '
    {
        for (i=1; i<=NF; i++) {
            len = length($i)
            if (len > col[i]) col[i] = len
        }
        rows[NR] = $0
    }
    END {
        for (r=1; r<=NR; r++) {
            n = split(rows[r], fields, ",")
            for (i=1; i<=n; i++)
                printf "%-*s  ", col[i], fields[i]
            print ""
        }
    }'
}

# ip [-all] [id] - Prints out a container's name, IPs, ports, networks and gateways.
# If no id or name provided, prints info for all containers.
function d.ip() {
	local all_flag=""
	local container_search="${1-}"
	if [[ "$container_search" == "-all" ]]; then
		all_flag="-a"
		container_search="${2-}"
	fi

	local output="Container Id,Name,IPs,Ports,Networks,Gateways"
	local container_ids=()

	if [[ -z "$container_search" ]]; then
		mapfile -t container_ids < <("${DOCKER[@]}" ps $all_flag -q)
	else
		mapfile -t container_ids < <("${DOCKER[@]}" container ls $all_flag --format "{{.ID}} {{.Names}}" |
			awk -v s="$container_search" '$1 == s || $2 == s { print $1 }')
	fi

	for container_id in "${container_ids[@]}"; do
		[[ -z "$container_id" ]] && continue
		local info
		info=$("${DOCKER[@]}" container inspect --format \
			'{{slice .Id 0 12}},{{slice .Name 1}},{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}},{{range $p, $conf := .NetworkSettings.Ports}}{{if $conf}}{{if ne (index $conf 0).HostIp "0.0.0.0"}}{{(index $conf 0).HostIp}}:{{end}}{{(index $conf 0).HostPort}}{{else}}null{{end}}:{{$p}} {{end}},{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}},{{range .NetworkSettings.Networks}}{{.Gateway}} {{end}}' \
			"$container_id")
		output+=$'\n'"$info"
	done

	# Compute column widths from data, then print
	echo "$output" | _print_table
}

# net [id] - Prints out a network's name, IPs and gateways.
# If no id or name provided, prints info for all networks.
function d.net() {
	local network_search="${1-}"

	local output="Network ID,Name,Subnet,Gateway"
	local network_ids=()

	if [[ -z "$network_search" ]]; then
		mapfile -t network_ids < <("${DOCKER[@]}" network ls --format "{{.ID}}")
	else
		mapfile -t network_ids < <("${DOCKER[@]}" network ls --format "{{.ID}} {{.Name}}" |
			awk -v s="$network_search" '$1 == s || $2 == s { print $1 }')
	fi

	for network_id in "${network_ids[@]}"; do
		[[ -z "$network_id" ]] && continue
		local info
		info=$("${DOCKER[@]}" network inspect --format \
			'{{slice .Id 0 12}},{{.Name}},{{range .IPAM.Config}}{{.Subnet}}{{end}},{{range .IPAM.Config}}{{if (index . "Gateway")}}{{.Gateway}}{{end}}{{end}}' \
			"$network_id")
		output+=$'\n'"$info"
	done

	# Compute column widths from data, then print
	echo "$output" | _print_table
}

# sh <id> [USERNAME] - Attach a shell to a container, with optional username.
function d.sh() {
	local container="${1-}"
	local user="${2-}"

	if [[ -z "$container" ]]; then
		echo "Usage: d sh <container_id> [USERNAME]" >&2
		return 1
	fi

	if [[ -n "$user" ]]; then
		"${DOCKER[@]}" exec -u "$user" -it "$container" /bin/sh -c "[ -x /bin/bash ] && exec /bin/bash || exec /bin/sh"
	else
		"${DOCKER[@]}" exec -it "$container" /bin/sh -c "[ -x /bin/bash ] && exec /bin/bash || exec /bin/sh"
	fi
}

# l <id> [NUM_LINES] - Tail and follow the logs of a container.
# NUM_LINES defaults to 50.
function d.l() {
	local container="${1-}"
	local lines="${2:-50}"

	if [[ -z "$container" ]]; then
		echo "Usage: d l <container_id> [NUM_LINES]" >&2
		return 1
	fi

	"${DOCKER[@]}" logs -fn "$lines" "$container"
}

# v [filter] - Print volumes with sizes.
# No filter: dangling volumes only. 'all': all volumes. Otherwise passed as a --filter expression.
function d.v() {
	local filter="${1-}"
	local sudo_cmd=""
	
	if [[ "$EUID" -ne 0 ]] && command -v sudo &>/dev/null; then
		sudo_cmd="sudo"
		# If rootless docker is used, we don't need sudo
		if "${DOCKER[@]}" info --format '{{json .SecurityOptions}}' 2>/dev/null | grep -q "rootless"; then
			sudo_cmd=""
		fi
	fi

	if [[ -z "$filter" ]]; then
		"${DOCKER[@]}" volume ls -f dangling=true --format '{{ .Mountpoint }}' | $sudo_cmd xargs -r -L1 du -sh
	elif [[ "$filter" == "all" ]]; then
		"${DOCKER[@]}" volume ls --format '{{ .Mountpoint }}' | $sudo_cmd xargs -r -L1 du -sh
	else
		"${DOCKER[@]}" volume ls -f "$filter" --format '{{ .Mountpoint }}' | $sudo_cmd xargs -r -L1 du -sh
	fi
}

# bb [command] - Start a busybox container with an optional command.
function d.bb() {
	if [[ -t 0 ]]; then
		"${DOCKER[@]}" run -it --rm busybox "$@"
	else
		"${DOCKER[@]}" run -i --rm busybox "$@"
	fi
}

# ub [command] - Start an ubuntu (act-latest) container with an optional command.
function d.ub() {
	if [[ -t 0 ]]; then
		"${DOCKER[@]}" run -it --rm catthehacker/ubuntu:act-latest "$@"
	else
		"${DOCKER[@]}" run -i --rm catthehacker/ubuntu:act-latest "$@"
	fi
}

# help - Show help for a specific command, or list all commands.
function d.help() {
	cat <<'EOF'
d                              alias for `docker`
d ip [-all] [ID]               print container name, IPs, ports, networks, gateways -all: include non-running containers
d net [ID]                     print network name, subnet and gateway
d v [filter|all]               print volume sizes (dangling if blank, all if 'all', or any docker --filter expression)
d sh <ID> [USERNAME]           attach a shell (optionally as USERNAME)
d l <ID> [NUM_LINES]           follow container logs (default: 0 = all lines)
d bb [COMMAND]                 start a busybox container
d ub [COMMAND]                 start an ubuntu (act-latest) container
d help                         show this help
EOF
}

cmd="${1-}"
if [[ $# -gt 0 ]]; then
	shift
fi

if [[ -z "$cmd" || "$cmd" == "-h" || "$cmd" == "--help" ]]; then
	d.help
elif [[ "$(type -t "d.$cmd")" == "function" ]]; then
	"d.$cmd" "$@"
else
	"${DOCKER[@]}" "$cmd" "$@"
fi
