#!/bin/sh

# Setup cUrl
apt-get update > /dev/null
apt-get upgrade > /dev/null
apt-get install curl > /dev/null


source="main-local"
destination="deploy-local"
local="${GITHUB_ACTOR}/deploy"

git config --global user.name "actions-bot"
git config --global user.email "actions-bot@no-reply.github.com"

git_base="https://${INPUT_TOKEN}@github.com"

# Clone src repo
git clone ${git_base}/${INPUT_REPOSITORY}.git ${source}

# Checkout main branch
cd ${source}
git checkout -q -f ${INPUT_MAIN}

# Build deployment
npm ci
npm run build

cd ..

# Clone sync-ing repository
git clone ${git_base}/${INPUT_REPOSITORY}.git ${destination}

# Checkout branch
cd ${destination}
git checkout -q -f ${INPUT_DEPLOY}
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



API_ENDPOINT="https://api.github.com/repos/${INPUT_REPOSITORY}/pulls"

AUTH="Authorization: token ${INPUT_TOKEN}"
ACCEPT="Accept: application/vnd.github+json"

PR_BODY="Deployment PR created for @${GITHUB_ACTOR} at ${INPUT_COMMIT}"

POST_PAYLOAD="{\"title\": \"${INPUT_PRTITLE}\", \"body\": \"${PR_BODY}\", \"base\": \"${INPUT_DEPLOY}\", \"head\": \"${local}\"}"

curl -s -H "${AUTH}" -H "${ACCEPT}" -X POST -d "${POST_PAYLOAD}" ${API_ENDPOINT} || \
true > /dev/null
# curl ${HEADERS} -X PATCH -d "${PAYLOAD}" ${API_ENDPOINT}

cd ..
rm -rf ${source}
rm -rf ${destination}
