#!/usr/bin/env bash
#
# Docker compose simplified.
# https://github.com/astappiev/simple-docker
#

# global variables
DOCKER_COMPOSE=(docker compose)
DEFAULT_TIMEOUT="${DEFAULT_TIMEOUT:-60}"

# Logs of the docker compose
function dc.l() {
	"${DOCKER_COMPOSE[@]}" logs -n 50 -f "$@"
}

# Start docker compose
function dc.u() {
	"${DOCKER_COMPOSE[@]}" up -d --remove-orphans "$@"
}

# Stop docker compose
function dc.d() {
	"${DOCKER_COMPOSE[@]}" down -t "$DEFAULT_TIMEOUT" --remove-orphans "$@"
}

# Pull docker compose
function dc.p() {
	"${DOCKER_COMPOSE[@]}" pull "$@"
}

# Start docker compose and follow the logs
function dc.uf() {
	dc.u "$@"
	dc.l "$@"
}

# Restart docker compose
function dc.r() {
	dc.d "$@"
	dc.u "$@"
}

# Restart docker compose and follow the logs
function dc.rf() {
	dc.d "$@"
	dc.u "$@"
	dc.l "$@"
}

# Attach to a running container
function dc.sh() {
	local service="${1-}"
	local index="${2:-1}"

	if [[ -z "$service" ]]; then
		service="$("${DOCKER_COMPOSE[@]}" ps --services 2>/dev/null | head -n1)"
	fi

	if [[ -z "$service" ]]; then
		echo "No compose service found in the current project." >&2
		return 1
	fi

	"${DOCKER_COMPOSE[@]}" exec --index "$index" "$service" \
		/bin/sh -c '[ -x /bin/bash ] && exec /bin/bash || exec /bin/sh'
}

# Execute a command in a running container
function dc.x() {
	"${DOCKER_COMPOSE[@]}" exec "$@"
}

# Show the status of the docker compose
function dc.s() {
	"${DOCKER_COMPOSE[@]}" ps "$@"
}

# Run any command across all compose projects in direct subfolders
function dc.a() {
	local cmd="${1-}"
	if [[ -z "$cmd" ]]; then
		echo "Usage: dc a <command> [args...]" >&2
		return 1
	fi
	if [[ "$cmd" == "a" || "$cmd" == "-r" || "$cmd" == "--recursive" ]]; then
		echo "Error: cannot nest recursive/all commands" >&2
		return 1
	fi
	shift

	local runner=()
	if [[ "$(type -t "dc.$cmd")" == "function" ]]; then
		runner=("dc.$cmd")
	else
		runner=("${DOCKER_COMPOSE[@]}" "$cmd")
	fi

	local dir found exit_code=0
	for dir in */; do
		[[ -d "$dir" ]] || continue
		(
			cd "$dir" || exit 1
			found=""

			for f in compose.yaml compose.yml docker-compose.yaml docker-compose.yml; do
				[[ -f "$f" ]] && found="$f" && break
			done

			if [[ -n "$found" ]]; then
				echo "==> $PWD ($found)"
				"${runner[@]}" "$@"
			else
				echo "==> $PWD (skip: no compose file)"
			fi
		) || exit_code=1
	done

	return "$exit_code"
}

# help [command] - Show help for a specific command
function dc.help() {
	cat <<'EOF'
dc [args...]              alias for docker compose
dc u [args...]            docker compose up -d
dc d [args...]            docker compose down -t TIMEOUT --remove-orphans
dc p [args...]            docker compose pull
dc l [args...]            docker compose logs -f
dc r [args...]            restart compose stack
dc uf [args...]           up and follow logs
dc rf [args...]           restart and follow logs
dc sh [service] [index]   shell into service; default: first compose service, index 1
dc x SERVICE CMD [...]    exec arbitrary command in service
dc s [args...]            docker compose status (ps)
dc a CMD [args...]        run command in all direct child compose projects
dc -r|--recursive CMD     alias for dc a CMD
EOF
}

if [[ "${1-}" == "-r" || "${1-}" == "--recursive" ]]; then
	shift
	if [[ $# -eq 0 ]]; then
		echo "Usage: dc -r <command> [args...]" >&2
		return 1 2>/dev/null || exit 1
	fi
	dc.a "$@"
else
	cmd="${1-}"
	if [[ $# -gt 0 ]]; then
		shift
	fi

	if [[ -z "$cmd" || "$cmd" == "-h" || "$cmd" == "--help" ]]; then
		dc.help
	elif [[ "$(type -t "dc.$cmd")" == "function" ]]; then
		"dc.$cmd" "$@"
	else
		"${DOCKER_COMPOSE[@]}" "$cmd" "$@"
	fi
fi
