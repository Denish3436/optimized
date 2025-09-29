#!/bin/bash
set -euo pipefail

# Validate arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <env> <branch_name>"
    echo "<env> should be either 'uat' or 'prod'"
    exit 1
fi

ENV="$1"
BRANCH_NAME=$(echo "$2" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')

# Load version properties
if [ -f "./version.properties" ]; then
    . ./version.properties
fi

VERSION=${version:-"unknown"}
IMAGE_NAME=${IMAGE_NAME:-"ftron"}
DOCKER_REPO=${DOCKER_REPO:-"ghcr.io/fintronners"}

# Append branch name to version if not main
if [ "$BRANCH_NAME" != "main" ]; then
    VERSION="${VERSION}-${BRANCH_NAME}"
fi

BASE_NAME="${DOCKER_REPO}/${IMAGE_NAME}:${VERSION}"

# Select Dockerfile based on environment
if [ "$ENV" = "prod" ]; then
    DOCKERFILE="docker/prod/compile/Dockerfile"
    BUILD_ARGS="--build-arg DD_GIT_REPOSITORY_URL=https://github.com/fintronners/Ftron --build-arg DD_GIT_COMMIT_SHA=$(git rev-parse HEAD)"
else
    DOCKERFILE="docker/compile/Dockerfile"
    BUILD_ARGS=""
fi

# Enable BuildKit
export DOCKER_BUILDKIT=1

echo "Building ${ENV} Docker image..."

# Build with buildx if available, otherwise use regular build
if docker buildx version >/dev/null 2>&1; then
    docker buildx build \
        --platform linux/amd64 \
        -t "${BASE_NAME}-${ENV}" \
        -t "${BASE_NAME}-${ENV}-latest" \
        -f "${DOCKERFILE}" \
        ${BUILD_ARGS} \
        .
else
    docker build \
        -t "${BASE_NAME}-${ENV}" \
        -t "${BASE_NAME}-${ENV}-latest" \
        -f "${DOCKERFILE}" \
        ${BUILD_ARGS} \
        .
fi

echo "Build complete for ${ENV}: ${BASE_NAME}-${ENV}"
