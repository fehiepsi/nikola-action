#!/bin/bash

: "${INPUT_DRY_RUN:=false}"

set -e

echo "REPO: $GITHUB_REPOSITORY"
echo "ACTOR: $GITHUB_ACTOR"

echo "==> Preparing..."
if ! $INPUT_DRY_RUN; then
    cd site
    src_branch="$(python -c 'import conf; print(conf.GITHUB_SOURCE_BRANCH)')"
    dest_branch="$(python -c 'import conf; print(conf.GITHUB_DEPLOY_BRANCH)')"
    cd ..
    
    git config --global --add safe.directory /github/workspace
    git remote add ghpages "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
    git fetch ghpages $dest_branch
    git checkout -b $dest_branch --track ghpages/$dest_branch || true
    git pull ghpages $dest_branch || true
    git checkout $src_branch
    
    # Override config so that ghp-import does the right thing.
    printf '\n\nGITHUB_REMOTE_NAME = "ghpages"\nGITHUB_COMMIT_SOURCE = False\n' >> site/conf.py
else
    echo "Dry-run, skipping..."
fi

echo "==> Installing requirements..."
if [[ -f "requirements.txt" ]]; then
    # Since people might type just 'nikola', we force ghp-import to be installed.
    pip install -r requirements.txt ghp-import
else
    pip install "Nikola[extras]"
fi

if [[ "x${INPUT_APT_INSTALL}" != "x" ]]; then
    apt-get update
    apt-get install -y ${INPUT_APT_INSTALL}
    apt-get clean
fi

cd site
echo "==> Building site..."
nikola build

echo "==> Publishing..."
if ! $INPUT_DRY_RUN; then
    nikola github_deploy
else
    echo "Dry-run, skipping..."
fi

echo "==> Done!"
