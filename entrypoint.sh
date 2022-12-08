#!/bin/sh




echo "home: $HOME, github_job: $GITHUB_JOB, github_ref: $GITHUB_REF, github_sha: $GITHUB_SHA, github_repository: $GITHUB_REPOSITORY, github_repository_owner: $GITHUB_REPOSITORY_OWNER, github_run_id: $GITHUB_RUN_ID, github_run_number: $GITHUB_RUN_NUMBER, github_retention_days: $GITHUB_RETENTION_DAYS, github_run_attempt: $GITHUB_RUN_ATTEMPT, github_actor: $GITHUB_ACTOR, github_triggering_actor: $GITHUB_TRIGGERING_ACTOR, github_workflow: $GITHUB_WORKFLOW, github_head_ref: $GITHUB_HEAD_REF, github_base_ref: $GITHUB_BASE_REF, github_event_name: $GITHUB_EVENT_NAME, github_server_url: $GITHUB_SERVER_URL, github_api_url: $GITHUB_API_URL, github_graphql_url: $GITHUB_GRAPHQL_URL, github_ref_name: $GITHUB_REF_NAME, github_ref_protected: $GITHUB_REF_PROTECTED, github_ref_type: $GITHUB_REF_TYPE, github_workspace: $GITHUB_WORKSPACE, github_action: $GITHUB_ACTION, github_event_path: $GITHUB_EVENT_PATH, github_action_repository: $GITHUB_ACTION_REPOSITORY, github_action_ref: $GITHUB_ACTION_REF, github_path: $GITHUB_PATH, github_env: $GITHUB_ENV, github_step_summary: $GITHUB_STEP_SUMMARY, github_state: $GITHUB_STATE, github_output: $GITHUB_OUTPUT, runner_os: $RUNNER_OS, runner_arch: $RUNNER_ARCH, runner_name: $RUNNER_NAME, runner_tool_cache: $RUNNER_TOOL_CACHE, runner_temp: $RUNNER_TEMP, runner_workspace: $RUNNER_WORKSPACE, actions_runtime_url: $ACTIONS_RUNTIME_URL, actions_runtime_token: $ACTIONS_RUNTIME_TOKEN, actions_cache_url: $ACTIONS_CACHE_URL"





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
