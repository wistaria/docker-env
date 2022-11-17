#!/bin/sh

function get_timezone () {
  TZ=$(basename $(dirname $(readlink /etc/localtime)))/$(basename $(readlink /etc/localtime))
}

OS="debian"
BASE="debian:11.5"
IMAGE="docker-env-${OS}"
CONTAINER="${IMAGE}_1"

# check docker daemon
RES=$(docker images > /dev/null 2>&1; echo $?)
if [ ${RES} = 0 ]; then :; else
  echo "Error: docker daemon is not running."
  exit 1
fi

COMMAND="$1"
if [ -z ${COMMAND} ]; then :; else
  if [ ${COMMAND} = remove ]; then
    RES=$(docker images --format "{{.Tag}}" ${IMAGE} | /usr/bin/head -1)
    if [ -z ${RES} ]; then
      echo "Error: No such image ${IMAGE}..."
      exit 1
    fi
    read -p "Really want to remove ${IMAGE}? (y/N): " yn
    case "$yn" in [yY]*)
      echo "Removing ${IMAGE}..."
      docker stop ${CONTAINER} > /dev/null
      docker rm ${CONTAINER} > /dev/null
      docker rmi ${IMAGE} > /dev/null
      exit 0;;
    *)
      exit 0;;
    esac
  else
    echo "Error: $0 [remove | clean]"
    exit 1
  fi
fi

VERSION=
BUILD_IMAGE=0

# check installed versions
RES=$(docker images --format "{{.Tag}}" ${IMAGE} | /usr/bin/head -1)
if [ -z ${RES} ]; then
  BUILD_IMAGE=1
fi

echo "Starting ${IMAGE}..."

# check X server
CONFIG=""
if [ -x /opt/X11/bin/xlsclients ]; then
  echo "Starting Xquartz..."
  xlsclients > /dev/null
  xhost + localhost > /dev/null
  CONFIG="--env DISPLAY=host.docker.internal:0"
else
  echo "Warning: Xquartz is not installed."
fi

DOCKER_USERNAME=$(id -un)
DOCKER_HOME=/home/${DOCKER_USERNAME}
DOCKER_UID=$(id -u)
DOCKER_GID=$(id -g)
DOCKER_HOSTNAME="${OS}"

# build image
if [ ${BUILD_IMAGE} = 1 ]; then
  BASE="${BASE}"
  malive_timezone
  echo "Building building image ${IMAGE} from ${BASE}..."
  docker build -t ${IMAGE} - <<EOF
FROM ${BASE}
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq \
 && apt-get -y upgrade \
 && apt-get -y install \
      build-essential \
      cmake \
      curl \
      gfortran \
      git \
      liblapack-dev \
      mpi-default-dev \
      sudo \
      vim \
      wget \
 && echo "unalias ls" >> /etc/skel/.bashrc

ARG USERNAME=${DOCKER_USERNAME}
ARG GROUPNAME=${DOCKER_USERNAME}
ARG UID=${DOCKER_UID}
ARG GID=${DOCKER_GID}
ARG PASSWORD=live
RUN groupadd -f -g \$GID \$GROUPNAME \
 && useradd -m -s /bin/bash -u \$UID -g \$GID -G sudo \$USERNAME \
 && echo \$USERNAME:\$PASSWORD | chpasswd \
 && echo "\$USERNAME ALL=(ALL) ALL" >> /etc/sudoers \
 && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime
USER \$USERNAME
WORKDIR /home/\$USERNAME/
EOF
fi

IMAGE_ID=$(docker images --format "{{.ID}}" ${IMAGE})
echo "Docker image: ${IMAGE} (${IMAGE_ID})"

# start container
CONTAINER_ID=$(docker ps --all --filter "name=${CONTAINER}" --format "{{.ID}}")
if [ -z ${CONTAINER_ID} ]; then
  echo "Starting container ${CONTAINER}..."
  if [ -d "${HOME}/.ssh" ]; then
    CONFIG="${CONFIG} -v ${HOME}/.ssh:${DOCKER_HOME}/.ssh:ro"
  fi
  if [ -d "${HOME}/share" ]; then
    CONFIG="${CONFIG} -v ${HOME}/share:${DOCKER_HOME}/share"
  fi
  if [ -d "${HOME}/development" ]; then
    CONFIG="${CONFIG} -v ${HOME}/development:${DOCKER_HOME}/development"
  fi
  if [ -d "${HOME}/.config/git" ]; then
    CONFIG="${CONFIG} -v ${HOME}/.config/git:${DOCKER_HOME}/.config/git:ro"
  elif [ -f "${HOME}/.gitconfig" ]; then
    CONFIG="${CONFIG} -v ${HOME}/.gitconfig:${DOCKER_HOME}/.gitconfig:ro"
  fi
  docker run -it --detach-keys='ctrl-e,e' --name "${CONTAINER}" --hostname ${DOCKER_HOSTNAME} ${CONFIG} --user ${DOCKER_UID}:${DOCKER_GID} ${IMAGE} /bin/bash
else
  echo "Docker container: ${CONTAINER} (${CONTAINER_ID})"
  docker restart ${CONTAINER_ID} > /dev/null
  docker attach --detach-keys='ctrl-e,e' ${CONTAINER_ID}
fi
