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

echo "Pushing ${ENV} Docker images..."

# Push versioned tag
docker push "${BASE_NAME}-${ENV}"

# Push latest tag
docker push "${BASE_NAME}-${ENV}-latest"

echo "Push complete for ${ENV}."
echo "  - ${BASE_NAME}-${ENV}"
echo "  - ${BASE_NAME}-${ENV}-latest"
