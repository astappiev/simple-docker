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

# Up all compose projects in direct subfolders and remove orphans
function dc.ua() {
	local dir found
	shopt -s nullglob

	for dir in */; do
		(
			cd "$dir" || exit 1
			found=""

			for f in compose.yaml compose.yml docker-compose.yaml docker-compose.yml; do
				[[ -f "$f" ]] && found="$f" && break
			done

			if [ -n "$found" ]; then
				echo "==> $PWD ($found)"
				dc.u
			else
				echo "==> $PWD (skip: no compose file)"
			fi
		)
	done
}

# help [command] - Show help for a specific command
function dc.help() {
	cat <<'EOF'
dc [args...]              alias for docker compose
dc u [args...]            docker compose up -d
dc d [args...]            docker compose down -t TIMEOUT --remove-orphans
dc l [args...]            docker compose logs -f
dc r [args...]            restart compose stack
dc uf [args...]           up and follow logs
dc rf [args...]           restart and follow logs
dc sh [service] [index]   shell into service; default: first compose service, index 1
dc x SERVICE CMD [...]    exec arbitrary command in service
dc s [args...]            docker compose status (ps)
dc ua                     up all direct child compose projects and remove orphans
EOF
}

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
