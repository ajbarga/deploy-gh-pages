#!/bin/bash

source="main-local"
destination="deploy-local"
local="${GITHUB_ACTOR}/deploy"

git config --global user.name "actions-bot"
git config --global user.email "actions-bot@no-reply.github.com"

git_base="https://actions-bot:${INPUT_TOKEN}@github.com"

# Clone src repo
git clone --branch "${INPUT_MAIN}" "${git_base}/${INPUT_REPOSITORY}.git" ${source}

# Checkout main branch
cd ${source}

# Build deployment
npm ci
npm run build

cd ..

# Clone sync-ing repository
git clone --branch "${INPUT_DEPLOY}" "${git_base}/${INPUT_REPOSITORY}.git" ${destination}

# Checkout branch
cd ${destination}
git checkout -q -f -b ${local}

# Delete old contents
rm -rf ./*
cd ..

# Copy files from template repo
cp -rf ${source}/${INPUT_BUILDFOLDER}/* ${destination} || true

# Navigate to sync-ing repo
cd ${destination}
git add -f --all > /dev/null
git commit -q -m "Deploy files from ${INPUT_MAIN} branch to ${INPUT_DEPLOY} branch"

# Push changes to remote repository
git push -f -q -u origin ${local}


commit="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/commit/${GITHUB_SHA}"

API_ENDPOINT="${GITHUB_API_URL}/repos/${INPUT_REPOSITORY}/pulls"
AUTH="Authorization: token ${INPUT_TOKEN}"
ACCEPT="Accept: application/vnd.github+json"
PR_BODY="Deployment PR created for @${GITHUB_ACTOR} at ${commit}"

POST_PAYLOAD="{\"title\": \"${INPUT_PRTITLE}\", \"body\": \"${PR_BODY}\", \"base\": \"${INPUT_DEPLOY}\", \"head\": \"${local}\"}"

curl -s -H "${AUTH}" -H "${ACCEPT}" -X POST -d "${POST_PAYLOAD}" "${API_ENDPOINT}" > /dev/null

cd ..
rm -rf ${source}
rm -rf ${destination}
