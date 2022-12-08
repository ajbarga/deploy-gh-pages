#!/bin/sh

# Setup cUrl
apt-get update > /dev/null
apt-get upgrade > /dev/null
apt-get install curl > /dev/null


SRC="main-local"
DEST="deploy-local"
LOCAL="${ACTOR}/deploy"

git config --global user.name "actions-bot"
git config --global user.email "actions-bot@no-reply.github.com"

git_base="https://${GITHUB_TOKEN}@github.com"

# Clone src repo
git clone ${git_base}/${REPO}.git ${SRC}

# Checkout main branch
cd ${SRC}
git checkout -q -f ${MAIN}

# Build deployment
npm ci
npm run build

cd ..

# Clone sync-ing repository
git clone ${git_base}/${REPO}.git ${DEST}

# Checkout branch
cd ${DEST}
git checkout -q -f ${DEPLOY}
git checkout -q -f -b ${LOCAL}

# Delete old contents
rm -rf ./*
cd ..

# Copy files from template repo
cp -rf ${SRC}/${BUILD}/* ${DEST} || true

# Navigate to sync-ing repo
cd ${DEST}
git add -f --all > /dev/null
git commit -q -m "Deploy files from ${MAIN} branch to ${DEPLOY} branch"

# Push changes to remote repository
git push -f -q -u origin ${LOCAL}



API_ENDPOINT="https://api.github.com/repos/${REPO}/pulls"

AUTH="Authorization: token ${GITHUB_TOKEN}"
ACCEPT="Accept: application/vnd.github+json"

PR_BODY="Deployment PR created for @${ACTOR} at ${COMMIT}"

POST_PAYLOAD="{\"title\": \"${PR_TITLE}\", \"body\": \"${PR_BODY}\", \"base\": \"${DEPLOY}\", \"head\": \"${LOCAL}\"}"

curl -s -H "${AUTH}" -H "${ACCEPT}" -X POST -d "${POST_PAYLOAD}" ${API_ENDPOINT} > /dev/null || \
true > /dev/null
# curl ${HEADERS} -X PATCH -d "${PAYLOAD}" ${API_ENDPOINT}

cd ..
rm -rf ${SRC}
rm -rf ${DEST}
