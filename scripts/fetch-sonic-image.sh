#!/usr/bin/env bash
# Imports a locally-downloaded docker-sonic-vs.gz artifact into Docker and
# tags it with a pinned version. Does NOT download the artifact — SONiC-VS
# has no stable scriptable download URL (see sonic.software or
# https://sonic-build.azurewebsites.net/ui/sonic/pipelines, "vs" platform,
# pick a branch, latest successful build, Artifacts -> target/docker-sonic-vs.gz).
set -euo pipefail

SONIC_VS_TAG="${SONIC_VS_TAG:-docker-sonic-vs:202511}"
ARTIFACT_PATH="${1:-}"

if [[ -z "$ARTIFACT_PATH" ]]; then
  echo "Usage: $0 <path-to-docker-sonic-vs.gz>"
  echo ""
  echo "Download the artifact first:"
  echo "  1. https://sonic-build.azurewebsites.net/ui/sonic/pipelines"
  echo "  2. Scroll to the 'vs' platform row, pick a branch (e.g. 202511), click 'Build History'"
  echo "  3. Pick the latest build with Result = succeeded, click 'Artifacts'"
  echo "  4. Find and download 'target/docker-sonic-vs.gz'"
  echo ""
  echo "If already imported, this script is a no-op:"
  if docker image inspect "$SONIC_VS_TAG" >/dev/null 2>&1; then
    echo "  '$SONIC_VS_TAG' already present."
    exit 0
  fi
  exit 1
fi

if docker image inspect "$SONIC_VS_TAG" >/dev/null 2>&1; then
  echo "'$SONIC_VS_TAG' already imported, skipping."
  exit 0
fi

echo "Importing $ARTIFACT_PATH as $SONIC_VS_TAG ..."
LOADED_TAG=$(docker load -i "$ARTIFACT_PATH" | sed -n 's/^Loaded image: //p' | tail -1)

if [[ "$LOADED_TAG" != "$SONIC_VS_TAG" ]]; then
  if [[ -z "$LOADED_TAG" ]]; then
    echo "Could not determine loaded image tag — check 'docker images' and retag manually to $SONIC_VS_TAG" >&2
    exit 1
  fi
  docker tag "$LOADED_TAG" "$SONIC_VS_TAG"
fi

echo "Done. Verify with: docker images | grep sonic-vs"