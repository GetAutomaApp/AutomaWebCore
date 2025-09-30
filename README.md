**Launch all apps**

1. Launch Selenium Grid Hub: `fly launch --ha=false --org <org-name> --config ./infra/fly-configs/seleniumgrid-hub.toml`
2. Launch Selenium Grid Node App: `fly launch --ha=false --org <org-name> --config ./infra/fly-configs/seleniumgrid-node.toml`
3. Launch Selenium Grid Node Autoscaler: `cd ./SeleniumGridNodeMachineAutoscaler/ ; fly launch --org <org-name> --ha=false --config=./infra/autoscaler.toml --build-secret GITHUB_SSH_AUTHENTICATION_TOKEN=$(cat ./infra/docker-secrets/GITHUB_SSH_AUTHENTICATION_TOKEN)`
    - Redeploy: `npm run deploy:autoscaler`
    - Set all secrets with `cd ./SeleniumGridNodeMachineAutoscaler/ ; fly secrets import < ./.env.production --app automa-web-core-seleniumgrid-node-autoscaler`
4. Launch AutomaWebCore main API: `cd ./API/ ; fly launch --org <org-name> --ha=false --config=./infra/api.toml`
    - Redeploy: `npm run deploy:api`
    - Set all secrets with `cd ./API/ ; fly secrets import < ./.env.production --app automa-web-core-api`

**files to create**
1. All `.env` files in all packages that require environment variables (not in root path, inside packages)
1. Create `./infra/docker-secrets/` directory with the following files and secrets:
    1. "GITHUB_SSH_AUTHENTICATION_TOKEN": A Github fine-grained token that allows cloning AutomaUtilities repository (private)
