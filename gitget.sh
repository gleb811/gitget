#!/usr/bin/env bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 <artifact_url>"
    exit 1
fi

ARTIFACT_URL="$1"
TOKEN="glpat-a-hJXdzx5QUieGWNZ4xlx286MQp1Ojh2CA.01.0y0bp6y4a"

# Extract components from URL
if [[ "$ARTIFACT_URL" =~ https://gitlab\.bwp\.dev/([^/]+/[^/]+)/-/jobs/([0-9]+)/artifacts/file/(.+)$ ]]; then
    GITLAB_PATH="${BASH_REMATCH[1]}"
    JOB_ID="${BASH_REMATCH[2]}"
    ARTIFACT_PATH="${BASH_REMATCH[3]}"
    FILENAME=$(basename "$ARTIFACT_URL")
else
    echo "Error: Invalid URL format" >&2
    exit 1
fi

echo "Extracted: project=$GITLAB_PATH, job=$JOB_ID, artifact=$ARTIFACT_PATH" >&2

# Get project ID
PROJECT_ID=$(curl --silent --header "PRIVATE-TOKEN: $TOKEN" \
    "https://gitlab.bwp.dev/api/v4/projects?per_page=100" | \
    grep -o "\"id\":[0-9]*[^}]*\"path_with_namespace\":\"$GITLAB_PATH\"" | \
    head -1 | \
    sed 's/"id"://' | \
    sed 's/,.*//')

if [ -z "$PROJECT_ID" ]; then
    echo "Error: Could not find project ID for $GITLAB_PATH" >&2
    exit 1
fi

echo "Project ID: $PROJECT_ID" >&2

# Download the file
DOWNLOAD_URL="https://gitlab.bwp.dev/api/v4/projects/$PROJECT_ID/jobs/$JOB_ID/artifacts/$ARTIFACT_PATH"
echo "Downloading $FILENAME..." >&2

if curl --header "PRIVATE-TOKEN: $TOKEN" -L "$DOWNLOAD_URL" -o "$FILENAME"; then
    echo "Successfully downloaded: $FILENAME"
else
    echo "Error: Download failed" >&2
    exit 1
fi
