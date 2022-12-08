#!/bin/sh

# Setup cUrl
apt-get update > /dev/null
apt-get upgrade > /dev/null
apt-get install curl > /dev/null


# type -p curl >/dev/null || apt install curl -y
# curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
# && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
# && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
# && apt update \
# && apt install gh -y

# apt update
# apt install gh


SRC="SRC-BRANCH"
DEST="DEPLOY-BRANCH"
LOCAL="${ACTOR}/deploy"

git config --global user.name "${ACTOR}"
git config --global user.email "${ACTOR}@no-reply.github.com"

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

HEADERS="-H \"Authorization:token ${TOKEN}\" -H \"Content-Type:application/json\""

PR_BODY="Deployment PR created for @${ACTOR} at ${COMMIT}"

PAYLOAD="{\"title\": \"${PR_TITLE}\", \"body\": \"${PR_BODY}\", \"base\": \"${DEPLOY}\", \"head\": \"${LOCAL}\"}"

curl ${HEADERS} -X POST -d "${PAYLOAD}" ${API_ENDPOINT}
# curl ${HEADERS} -X PATCH -d "${PAYLOAD}" ${API_ENDPOINT}


# curl -X POST \
#   -H "Authorization: token ${TOKEN}" \
#   -H "Content-Type: application/json" \
#   -d "{\"title\":\"${PR_TITLE}\",\"body\":\"Deployment PR created for @${ACTOR} at ${COMMIT}\",\"head\":\"${LOCAL}\",\"base\":\"${DEPLOY}\"}" \
#   "https://api.github.com/repos/${REPO}/pulls"

# # Create or edit AutoSync Pr
# gh pr create \
#     --repo ${REPO} \
#     --head ${LOCAL} \
#     --base ${DEPLOY} \
#     --body "Deployment PR created for @${ACTOR} at ${COMMIT}" \
#     --label "deploy" \
#     --reviewer ${ACTOR} \
#     --title "${PR_TITLE}" \
# || gh pr edit ${LOCAL} \
#     --repo ${REPO} \
#     --title "${PR_TITLE}" \
#     --body "Deployment PR created for @${ACTOR} at ${COMMIT}"

# Delete Sync-ed Repo, Sleep to avoid API call overload
cd ..
rm -rf ${SRC}
rm -rf ${DEST}
