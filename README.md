# Docker CLI simplified

It is a collection of shortcuts to common docker commands. The goal is to provide a simple way to interact with docker containers without having to remember or type all the commands.

## Installation

You need to downaload the scripts somewhere on your system and add them to your `.bashrc` profile.

Convenientlu, you can use the following commands to download and install the scripts:

```bash
wget -qO- https://raw.githubusercontent.com/astappiev/simple-docker/refs/heads/main/install.sh | bash
```

But always make sure to review the script before running it. Especially if you are not me.

### Shortcuts of `d` command

| Command                   | Description                                                                                     |
| ------------------------- | ----------------------------------------------------------------------------------------------- |
| `d`                       | alias for `docker`                                                                              |
| `d ip [-all] [ID]`        | print a container's name, IPs, ports, networks and gateways (all containers running if blank)   |
| `d v [filter]`            | prints volumes with sizes (dangling if blank, all if 'all')                                     |
| `d sh [USERNAME] <ID>`    | bash into a container with optional username                                                    |
| `d logs [NUM_LINES] <ID>` | tailg (and follow) a container's logs (0 lines if blank)                                        |
| `d bb [COMMAND]`          | start a busybox container with optional command                                                 |
| `d ub [COMMAND]`          | start a ubuntu container with optional command                                                  |

### Shortcuts of `dc` command

| Command                   | Description                                                                                     |
| ------------------------- | ----------------------------------------------------------------------------------------------- |
| `dc`                      | alias for `docker compose`                                                                      |
| `dc u`                    | alias for `docker compose up`                                                                   |
| `dc d`                    | alias for `docker compose down`                                                                 |
| `dc l`                    | alias for `docker compose logs`                                                                 |
| `dc r [container]`        | restart docker compose (`down` + `up`)                                                          |
| `dc ul [container]`       | start container and follow the logs (`up -d` + `logs -f`)                                       |
| `dc sh [container]`       | attach to a running container                                                                   |
