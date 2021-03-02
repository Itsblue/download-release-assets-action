#!/bin/bash

if [[ -z "$INPUT_FILE" ]]; then
  echo "Missing file input in the action"
  exit 1
fi

if [[ -z "$INPUT_PATH" ]]; then
  echo "Missing file output path in the action"
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
API_URL="https://api.github.com/repos/$REPO"
RELEASE_URL="$API_URL/releases/$INPUT_VERSION"
RELEASE_DATA=$(curl -H "Authorization: token ${TOKEN}" $RELEASE_URL)

MESSAGE=$(echo $RELEASE_DATA | jq -r ".message")

if [[ "$MESSAGE" != "null" ]]; then
  echo "[!] Error: $MESSAGE"
  echo "Release data: $RELEASE_DATA"
  echo "-----"
  echo "repo: $REPO"
  echo "url: $RELEASE_URL"
  echo "asset: $INPUT_FILE"
  echo "target: $TARGET"
  echo "version: $INPUT_VERSION"
  exit 1
fi

ASSETS=$(echo $RELEASE_DATA |  jq --raw-output ".assets | map(select(.name | match(\"${INPUT_FILE}\")))[] |[ .id, .name ] | @csv" )
TAG_VERSION=$(echo $RELEASE_DATA | jq -r ".tag_name" | sed -e "s/^v//" | sed -e "s/^v.//")
echo "::set-output name=version::$TAG_VERSION"

if [[ -z "$ASSETS" ]]; then
  echo "[!] Warning: No assets were found"
  echo "Release data: $RELEASE_DATA"
  echo "-----"
  echo "repo: $REPO"
  echo "url: $RELEASE_URL"
  echo "asset: $INPUT_FILE"
  echo "path: $INPUT_PATH"
  echo "version: $INPUT_VERSION"
  exit 2
fi

mkdir -p $INPUT_PATH

while IFS= read -r ASSET; do
  ASSET_ID=$(echo $ASSET | awk -F, '{print $1}')
  ASSET_NAME=$(echo $ASSET | awk -F, '{print $2}' | tr -d '",')

  echo ""
  echo "Downloading asset: \"$ASSET_NAME\" with ID: $ASSET_ID"

  curl \
  -J \
  -L \
  -H "Accept: application/octet-stream" \
  -H "Authorization: token ${TOKEN}" \
  "$API_URL/releases/assets/$ASSET_ID" \
  -o "$INPUT_PATH/$ASSET_NAME"
  
done <<< "$ASSETS"
