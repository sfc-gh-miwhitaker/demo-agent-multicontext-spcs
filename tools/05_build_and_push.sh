#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
IMAGE_NAME="agent-multicontext"
IMAGE_TAG="${1:-latest}"

# Source .env.local if it exists (enables 1Password / secret-manager injection)
if [[ -f "$PROJECT_ROOT/.env.local" ]]; then
  # shellcheck disable=SC1091
  source "$PROJECT_ROOT/.env.local"
fi

# Auto-detect container runtime: prefer podman (open-source), fall back to docker
if command -v podman &>/dev/null; then
  RUNTIME="podman"
elif command -v docker &>/dev/null; then
  RUNTIME="docker"
else
  echo "ERROR: No container runtime found."
  echo ""
  echo "Install one of:"
  echo "  macOS:   brew install podman"
  echo "  Windows: winget install RedHat.Podman"
  echo "  Linux:   sudo apt install podman  (or dnf install podman)"
  echo ""
  echo "Docker also works but requires a commercial license for business use."
  exit 1
fi

echo "Using container runtime: $RUNTIME"

# Prompt for repo URL if not set
if [[ -z "${SNOWFLAKE_IMAGE_REPO_URL:-}" ]]; then
  echo ""
  echo "Copy the image_repo_url from the last result of deploy_all.sql."
  echo "It looks like: <orgname>-<acctname>.registry.snowflakecomputing.com/snowflake_example/agent_multicontext/images"
  echo ""
  read -rp "Snowflake image repository URL: " SNOWFLAKE_IMAGE_REPO_URL
fi

# Extract the registry host (everything before the first /)
REGISTRY_HOST="${SNOWFLAKE_IMAGE_REPO_URL%%/*}"

# Prompt for username if not set
if [[ -z "${SNOWFLAKE_USERNAME:-}" ]]; then
  echo ""
  read -rp "Snowflake username: " SNOWFLAKE_USERNAME
fi

# Prompt for PAT if not set
if [[ -z "${SNOWFLAKE_REGISTRY_PAT:-}" ]]; then
  echo ""
  echo "Generate a PAT in Snowsight: User menu → Programmatic Access Tokens"
  echo ""
  read -rsp "Snowflake PAT: " SNOWFLAKE_REGISTRY_PAT
  echo ""
fi

FULL_IMAGE_TAG="${SNOWFLAKE_IMAGE_REPO_URL}/${IMAGE_NAME}:${IMAGE_TAG}"

echo ""
echo "Building image..."
$RUNTIME build -t "${IMAGE_NAME}:${IMAGE_TAG}" "$PROJECT_ROOT"

echo "Tagging as ${FULL_IMAGE_TAG}..."
$RUNTIME tag "${IMAGE_NAME}:${IMAGE_TAG}" "$FULL_IMAGE_TAG"

echo "Authenticating to ${REGISTRY_HOST}..."
echo "$SNOWFLAKE_REGISTRY_PAT" | $RUNTIME login "$REGISTRY_HOST" \
  --username "$SNOWFLAKE_USERNAME" \
  --password-stdin

echo "Pushing image..."
$RUNTIME push "$FULL_IMAGE_TAG"

echo ""
echo "Done. Image pushed to: ${FULL_IMAGE_TAG}"
echo "You can now run sql/09_spcs_service.sql in Snowsight."
