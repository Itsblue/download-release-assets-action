#!/bin/bash

if [[ -z "$INPUT_FILE" ]]; then
  echo "Missing file input in the action"
  exit 1
fi

if [[ -z "$GITHUB_REPOSITORY" ]]; then
  echo "Missing GITHUB_REPOSITORY env variable"
  exit 1
fi

REPO=$GITHUB_REPOSITORY
if ! [[ -z ${INPUT_REPO} ]]; then
  REPO=$INPUT_REPO ;
fi

# Optional personal access token for external repository
TOKEN=$GITHUB_TOKEN
if ! [[ -z ${INPUT_TOKEN} ]]; then
  TOKEN=$INPUT_TOKEN
fi

# Fetch all available assets from GitHub API
API_URL="https://$TOKEN:@api.github.com/repos/$REPO"
RELEASE_DATA=$(curl $API_URL/releases/${INPUT_VERSION})
ASSETS=$(echo $RELEASE_DATA |  jq --raw-output ".assets | map(select(.name | match(\"${INPUT_FILE}\")))[] |[ .id, .name ] | @csv" )
TAG_VERSION=$(echo $RELEASE_DATA | jq -r ".tag_name" | sed -e "s/^v//" | sed -e "s/^v.//")
echo "::set-output name=version::$TAG_VERSION"

if [[ -z "$ASSETS" ]]; then
  echo "Could not find asset id(s)"
  exit 1
fi

mkdir -p $INPUT_PATH

while IFS= read -r ASSET; do
  ASSET_ID=$(echo $ASSET | awk -F, '{print $1}')
  ASSET_NAME=$(echo $ASSET | awk -F, '{print $2}' | tr -d '",')

  echo "Downloading asset: \"$ASSET_NAME\" with ID: $ASSET_ID"

  curl \
  -J \
  -L \
  -H "Accept: application/octet-stream" \
  "$API_URL/releases/assets/$ASSET_ID" \
  -o "$INPUT_PATH/$ASSET_NAME"
  
done <<< "$ASSETS"
