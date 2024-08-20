#!/bin/sh

OS="debian"
TAG="latest"
DENV="docker-env"
BASE="${OS}:${TAG}"
IMAGE="${DENV}-${OS}"
CONTAINER="${IMAGE}_1"
VOLUME="${DENV}_1"

export DOCKER_CLI_HINTS=false

# check docker daemon
RES=$(docker images > /dev/null 2>&1; echo $?)
if [ ${RES} = 0 ]; then :; else
  echo "Error: docker daemon is not running."
  exit 1
fi

# configurations
CONFIG=""

# check X server
if [ -x /opt/X11/bin/xlsclients ]; then
  echo "Starting Xquartz..."
  xlsclients > /dev/null
  xhost + localhost > /dev/null
  CONFIG="${CONFIG} --env DISPLAY=host.docker.internal:0"
else
  echo "Warning: Xquartz is not installed."
fi

BUILD_IMAGE=0
RES=$(docker images --format "{{.Tag}}" ${IMAGE} | /usr/bin/head -1)
if [ -z ${RES} ]; then
  BUILD_IMAGE=1
fi

D_USERNAME=$(id -un)
D_HOME=/home/${D_USERNAME}
D_UID=$(id -u)
D_GID=$(id -g)
D_HOSTNAME="${OS}"

# build image
if [ ${BUILD_IMAGE} = 1 ]; then
  BASE="${BASE}"
  echo "Building building image ${IMAGE} from ${BASE}..."
  docker build -t ${IMAGE} - <<EOF
FROM ${BASE}

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq \
 && apt-get -y upgrade \
 && apt-get -y install sudo
# RUN apt-get -y install build-essential curl sudo vim wget

ARG USERNAME=${D_USERNAME}
ARG GROUPNAME=${D_USERNAME}
ARG UID=${D_UID}
ARG GID=${D_GID}
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
  # configuration for share folders
  if [ -d "${HOME}/.ssh-docker" ]; then
    CONFIG="${CONFIG} -v ${HOME}/.ssh-docker:${D_HOME}/.ssh:ro"
  elif [ -d "${HOME}/.ssh" ]; then
    CONFIG="${CONFIG} -v ${HOME}/.ssh:${D_HOME}/.ssh:ro"
  fi
  if [ -d "${HOME}/share" ]; then
    CONFIG="${CONFIG} -v ${HOME}/share:${D_HOME}/share"
  fi
  if [ -d "${HOME}/development" ]; then
    CONFIG="${CONFIG} -v ${HOME}/development:${D_HOME}/development"
  fi
  if [ -d "${HOME}/.config/git" ]; then
    CONFIG="${CONFIG} -v ${HOME}/.config/git:${D_HOME}/.config/git:ro"
  elif [ -f "${HOME}/.gitconfig" ]; then
    CONFIG="${CONFIG} -v ${HOME}/.gitconfig:${D_HOME}/.gitconfig:ro"
  fi
  # configuration for sshd
  CONFIG="${CONFIG} --publish 22:22"
  # configuration for httpd
  CONFIG="${CONFIG} --publish 80:80"
  CONFIG="${CONFIG} --publish 443:443"
  # start container
  echo "Starting container ${CONTAINER}..."
  docker run -it --detach-keys='ctrl-e,e' --name "${CONTAINER}" --hostname ${D_HOSTNAME} ${CONFIG} --volume ${VOLUME}:${D_HOME} --user ${D_UID}:${D_GID} ${IMAGE} /bin/bash
else
  echo "Restarting container: ${CONTAINER} (${CONTAINER_ID})"
  docker restart ${CONTAINER_ID} > /dev/null
  docker attach --detach-keys='ctrl-e,e' ${CONTAINER_ID}
fi

cat << EOF
To remove the container and image, run the following command:
  docker rm ${CONTAINER}; docker rmi ${IMAGE}
To remove the user volume (/home/user) as well, run the following command:
  docker volume rm ${VOLUME}
EOF
