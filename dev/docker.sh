#!/bin/bash

#
# Build and optionally push new image to Docker hub.
#
# When pushing, this script uses the following Travis secure variables:
#  - DOCKER_USERNAME
#  - DOCKER_PASSWORD
#
# These are set via https://github.com/oracle/opengrok/settings/secrets
#

set -e

API_URL="https://hub.docker.com/v2"
IMAGE="registry.cn-hangzhou.aliyuncs.com/opengrok/docker"

if [[ -n $OPENGROK_REF && $OPENGROK_REF == refs/tags/* ]]; then
	OPENGROK_TAG=${OPENGROK_REF#"refs/tags/"}
fi

if [[ -n $OPENGROK_TAG ]]; then
	VERSION="$OPENGROK_TAG"
	VERSION_SHORT=$( echo $VERSION | cut -d. -f1,2 )
else
	VERSION="latest"
	VERSION_SHORT="latest"
fi

if [[ -z $VERSION ]]; then
	echo "empty VERSION"
	exit 1
fi

if [[ -z $VERSION_SHORT ]]; then
	echo "empty VERSION_SHORT"
	exit 1
fi

echo "Version: $VERSION"
echo "Short version: $VERSION_SHORT"

# Build the image.
echo "Building docker image"
docker build \
    -t $IMAGE:$VERSION 

#
# Run the image in container. This is not strictly needed however
# serves as additional test in automatic builds.
#
echo "Running the image in container"
docker run -d $IMAGE
docker ps -a



# Allow Docker push for release builds only.
if [[ -z $OPENGROK_TAG ]]; then
	echo "OPENGROK_TAG is empty"
	exit 0
fi

if [[ -z $DOCKER_USERNAME ]]; then
	echo "DOCKER_USERNAME is empty"
	exit 1
fi

if [[ -z $DOCKER_PASSWORD ]]; then
	echo "DOCKER_PASSWORD is empty"
	exit 1
fi

# Publish the image to Docker hub.
if [ -n "$DOCKER_PASSWORD" -a -n "$DOCKER_USERNAME" -a -n "$VERSION" ]; then
	echo "Logging into Docker Hub"
	echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

	# All the tags need to be pushed individually:
	echo "Pushing Docker image for tag $VERSION"
	docker push $IMAGE:$VERSION
fi
