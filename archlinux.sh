#!/bin/sh

OS="archlinux"
DENV="docker-env"
BASE="${OS}:latest"
IMAGE="${DENV}-${OS}"
CONTAINER="${IMAGE}_1"
VOLUME="${DENV}_1"

# check docker daemon
RES=$(docker images > /dev/null 2>&1; echo $?)
if [ ${RES} = 0 ]; then :; else
  echo "Error: docker daemon is not running."
  exit 1
fi

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

BUILD_IMAGE=0
RES=$(docker images --format "{{.Tag}}" ${IMAGE} | /usr/bin/head -1)
if [ -z ${RES} ]; then
  BUILD_IMAGE=1
fi

DOCKER_USERNAME=$(id -un)
DOCKER_HOME=/home/${DOCKER_USERNAME}
DOCKER_UID=$(id -u)
DOCKER_GID=$(id -g)
DOCKER_HOSTNAME="${OS}"

# build image
if [ ${BUILD_IMAGE} = 1 ]; then
  BASE="${BASE}"
  echo "Building building image ${IMAGE} from ${BASE}..."
  docker build -t ${IMAGE} - <<EOF
FROM ${BASE}

ARG USERNAME=${DOCKER_USERNAME}
ARG GROUPNAME=${DOCKER_USERNAME}
ARG UID=${DOCKER_UID}
ARG GID=${DOCKER_GID}
ARG PASSWORD=docker
RUN groupadd -f -g \$GID \$GROUPNAME \
 && useradd -m -s /bin/bash -u \$UID -g \$GID \$USERNAME \
 && echo \$USERNAME:\$PASSWORD | chpasswd \
 && echo "\$USERNAME ALL=(ALL) ALL" >> /etc/sudoers

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
  docker run -it --detach-keys='ctrl-e,e' --name "${CONTAINER}" --hostname ${DOCKER_HOSTNAME} ${CONFIG} --volume ${VOLUME}:${DOCKER_HOME} --user ${DOCKER_UID}:${DOCKER_GID} ${IMAGE} /bin/bash
else
  echo "Docker container: ${CONTAINER} (${CONTAINER_ID})"
  docker restart ${CONTAINER_ID} > /dev/null
  docker attach --detach-keys='ctrl-e,e' ${CONTAINER_ID}
fi

cat << EOF
To remove the container and image, run the following command:
  docker rm ${CONTAINER}; docker rmi ${IMAGE}
To remove the user volume (/home/user) as well, run the following command:
  docker volume rm ${VOLUME}
EOF
