#!/usr/bin/env bash
#
# Build the Docker image and push it to the Snowflake image repository.
#
# Prerequisites:
#   - Docker running locally
#   - SNOWFLAKE_ACCOUNT env var set (org-account format, e.g. MYORG-MYACCT)
#   - Snowflake user credentials for docker login
#
# Usage:
#   ./tools/05_build_and_push.sh            # tag as :latest
#   ./tools/05_build_and_push.sh v2         # tag as :v2

set -euo pipefail
cd "$(dirname "$0")/.."

TAG="${1:-latest}"
ACCOUNT="${SNOWFLAKE_ACCOUNT:?Set SNOWFLAKE_ACCOUNT (org-account format, e.g. MYORG-MYACCT)}"

# Snowflake image registry uses lowercase account
REGISTRY="$(echo "${ACCOUNT}" | tr '[:upper:]' '[:lower:]').registry.snowflakecomputing.com"
IMAGE_PATH="${REGISTRY}/snowflake_example/agent_multicontext/images/agent-multicontext"

echo "=== Snowflake Image Registry ==="
echo "Registry : ${REGISTRY}"
echo "Image    : ${IMAGE_PATH}:${TAG}"
echo ""

# Step 1: Authenticate with the Snowflake registry
echo "--- Step 1: Docker login ---"
echo "Enter your Snowflake username when prompted."
docker login "${REGISTRY}"

# Step 2: Build the image (linux/amd64 required by SPCS)
echo ""
echo "--- Step 2: Building image (linux/amd64) ---"
docker build --platform linux/amd64 -t "${IMAGE_PATH}:${TAG}" .

# Step 3: Push to Snowflake
echo ""
echo "--- Step 3: Pushing to Snowflake ---"
docker push "${IMAGE_PATH}:${TAG}"

echo ""
echo "=== Done ==="
echo "Image pushed: ${IMAGE_PATH}:${TAG}"
echo ""
echo "Next: Run sql/09_spcs_service.sql in Snowsight to create the service."
