#!/usr/bin/env bash
# Author: Jørgen Bele Reinfjell
# Date:   25.06.2019 [DD.MM.YYYY]
# File: docker-build-remote.sh
# Description:
#    Build a docker image at a remote server.

if [ "$1" = "-h" ]; then
    echo "Usage: $0 [-h] [-t IMAGE_TAG] BUILD_DIR"
    exit 0
fi

if [ "$1" = "-t" ]; then
    IMAGE_TAG="$2"
    shift 2
fi

if [ -z "$BUILD_DIR" ]; then
    BUILD_DIR="$1"
    if [ -z "$BUILD_DIR" ]; then
        echo "No build directory specified. Exiting!" >&2
        exit 1
    fi
fi

if [ -z "$IMAGE_TAG" ]; then
    build_dir="$(readlink -f "${BUILD_DIR}")"
    IMAGE_TAG="$(basename "${build_dir}"):latest"
fi

[ -z "$REMOTE" ] && REMOTE=srv
[ -z "$REMOTE_PATH" ] && REMOTE_PATH="/home/debbie/_docker_build/${IMAGE_TAG}"

echo "IMAGE_TAG=${IMAGE_TAG}"
echo "BUILD_DIR=${BUILD_DIR}"
echo "REMOTE=${REMOTE}"
echo "REMOTE_PATH=${REMOTE_PATH}"

bold() {
    if test -t 1; then
        echo -e "\n\e[1m$@\e[0m"
    else
        echo "$@"
    fi
}

lrun() {
    echo "$@"
    "$@"
}

makedirs() {
    ssh "$REMOTE" "mkdir -p $REMOTE_PATH"
}

fail() {
    bold 'FAILED'
    exit 1
}

bold ":: Building image ${IMAGE_TAG} from ${BUILD_DIR}"
bold "=> Making directories at remote"
lrun makedirs || fail
bold 'DONE'

bold "=> Copying build files to remote"
lrun rsync -Larvz "${BUILD_DIR}/" "${REMOTE}:${REMOTE_PATH}" || fail
bold 'DONE'

bold "=> Building at remote"
lrun ssh "${REMOTE}" "cd ${REMOTE_PATH} && docker build -t \"${IMAGE_TAG}\" ." || fail
bold 'DONE'

bold "=> Recieving built image from remote"
ssh "${REMOTE}" "cd ${REMOTE_PATH} && docker image save \"${IMAGE_TAG}\"" | pv | docker image load || fail
bold 'DONE'
