#!/bin/bash
# deploy-app.sh

APP_PATH=$1
FLY_CONFIG_TEMPLATE_FILE_NAME=$2
ENV=$3

CONFIG_PATH=$(npm run fly:config -- "$FLY_CONFIG_TEMPLATE_FILE_NAME" "$ENV" | tail -n 1)
cp "$CONFIG_PATH" "$APP_PATH/.fly.toml"

cd "$APP_PATH" && flyctl deploy \
    --ha=false \
    --config=.fly.toml \
    --build-secret GITHUB_SSH_AUTHENTICATION_TOKEN="$(cat ../infra/docker-secrets/GITHUB_SSH_AUTHENTICATION_TOKEN)"
