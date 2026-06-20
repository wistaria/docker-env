# docker-env

![Docker](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker&logoColor=white)
![Shell](https://img.shields.io/badge/Shell-POSIX-4EAA25?logo=gnu-bash&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-test%20environments-FCC624?logo=linux&logoColor=black)
![macOS](https://img.shields.io/badge/macOS-XQuartz%20optional-000000?logo=apple&logoColor=white)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Author](https://img.shields.io/badge/author-Synge%20Todo-blue)](https://github.com/wistaria)

A collection of scripts for quickly launching Linux distribution environments as Docker containers and logging in from the command line.

Each container creates a user with the same UID/GID as the host user, making file ownership easier to manage in mounted shared directories.

## Features

- Launch Docker environments for Debian, Ubuntu, Fedora, and Arch Linux
- Automatically build the dedicated Docker image on first run
- Restart and attach to the existing container on later runs
- Create a user with the same username, UID, and GID as the host user
- Automatically mount `~/.ssh-docker`, `~/share`, and Git settings when available
- Publish SSH, HTTP, and HTTPS ports to unprivileged host ports
- Set `DISPLAY` for X11 applications on macOS when XQuartz is available

## Supported Images

| Script | Base image | Docker image | Container |
| --- | --- | --- | --- |
| `debian.sh` | `debian:latest` | `docker-env-debian` | `docker-env-debian_1` |
| `ubuntu.sh` | `ubuntu:latest` | `docker-env-ubuntu` | `docker-env-ubuntu_1` |
| `fedora.sh` | `fedora:latest` | `docker-env-fedora` | `docker-env-fedora_1` |
| `archlinux.sh` | `archlinux:latest` | `docker-env-archlinux` | `docker-env-archlinux_1` |

## Requirements

- Docker
- A running Docker daemon
- XQuartz when using GUI applications on macOS

When XQuartz is installed, the scripts set `DISPLAY=host.docker.internal:0`. The scripts can still be used for command-line workloads without XQuartz.

## Quick Start

Run the script for the distribution you want to use with `sh`.

```sh
sh ubuntu.sh
```

Other distributions work the same way.

```sh
sh debian.sh
sh fedora.sh
sh archlinux.sh
```

On the first run, the script builds the Docker image, creates the container, and starts `/bin/bash`. On later runs, it restarts the existing container and attaches with `docker attach`.

To leave the container, exit the shell normally with `exit`. To detach without stopping the container, press:

```text
Ctrl-e e
```

## Container User

Inside the container, a user is created with the same username, UID, and GID as the host user.

| Item | Value |
| --- | --- |
| User | Same username as the host |
| UID/GID | Same UID/GID as the host |
| Home | `/home/<username>` |
| Password | `docker` |
| Hostname | Distribution name |

Debian and Ubuntu install `sudo`. Fedora additionally installs `gcc`, `make`, `vim`, and `wget`.

## Mounted Paths

If the following directories or configuration files exist on the host, they are mounted into the container automatically.

| Host | Container | Mode |
| --- | --- | --- |
| `~/.ssh-docker` | `~/.ssh` | read-only |
| `~/share` | `~/share` | read-write |
| `~/.config/git` | `~/.config/git` | read-only |
| `~/.gitconfig` | `~/.gitconfig` | read-only |

When `~/.config/git` exists, it takes precedence over `~/.gitconfig`. For safety, the scripts do not mount `~/.ssh` directly; they only mount the Docker-specific `~/.ssh-docker` directory.

The home directory is stored in the Docker volume `docker-env_1`. This volume is shared by all scripts.

## Ports

Each container publishes the following ports to the host.

| Host | Container | Purpose |
| --- | --- | --- |
| `8022` | `22` | SSH |
| `8080` | `80` | HTTP |
| `8443` | `443` | HTTPS |

## Project Layout

```text
.
├── LICENSE
├── README.md
├── README-jp.md
├── archlinux.sh
├── debian.sh
├── fedora.sh
└── ubuntu.sh
```

## Cleanup

To remove a container and image, run the commands for the target distribution.

```sh
docker rm docker-env-ubuntu_1
docker rmi docker-env-ubuntu
```

To also remove the volume used for home directories, run:

```sh
docker volume rm docker-env_1
```

Removing the volume also deletes files saved in container home directories.

## Notes

- Each script exits if the Docker daemon is not running.
- If a container with the same name already exists, the script connects to the existing container instead of creating a new one.
- Each container uses host ports `8022`, `8080`, and `8443`, so startup may fail if those ports are already in use.
- Running containers for multiple distributions at the same time causes published port conflicts.

## Contributing

Issues and pull requests are welcome. When adding a new distribution, follow the existing scripts for naming conventions, user creation, mounts, and port settings.

## License

This project is licensed under the [MIT License](LICENSE).
