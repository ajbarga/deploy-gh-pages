#!/bin/sh

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

# Create or edit AutoSync Pr
gh pr create \
    --repo ${REPO} \
    --head ${LOCAL} \
    --base ${DEPLOY}
    --title "${PR_TITLE}" \
    --body "Deployment PR created for @${ACTOR}." \
    --label "deploy" > /dev/null || \
gh pr edit ${LOCAL} \
    --repo ${REPO} \
    --title "${PR_TITLE}" > /dev/null

# Delete Sync-ed Repo, Sleep to avoid API call overload
cd ..
rm -rf ${SRC}
rm -rf ${DEST}
