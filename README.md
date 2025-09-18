**Launch all apps**

1. Launch Selenium Grid Hub: `fly launch --ha=false --org <org-name> --config ./infra/seleniumgrid-hub.toml`
2. Launch Selenium Grid Node App: `fly launch --ha=false --org <org-name> --config ./infra/seleniumgrid-node.toml`
3. Launch Selenium Grid Node Autoscaler: `fly launch --org <org-name> --ha=false --config=./infra/autoscaler.toml --build-secret GITHUB_SSH_AUTHENTICATION_TOKEN=$(cat ./infra/GITHUB_SSH_AUTHENTICATION_TOKEN)`
    - Redeploy: `fly deploy --ha=false --config=./infra/autoscaler.toml --build-secret GITHUB_SSH_AUTHENTICATION_TOKEN=$(cat ./infra/GITHUB_SSH_AUTHENTICATION_TOKEN)` # TODO: Turn `SeleniumGridNodeMachineAutoscaler` to npm package and add deploy script
    (
        "deploy": "fly deploy --ha=false",
        "deploy:autoscaler": "npm run deploy -- --config=./SeleniumGridNodeMachineAutoscaler/infra/autoscaler.toml --build-secret GITHUB_SSH_AUTHENTICATION_TOKEN=$(cat ./SeleniumGridNodeMachineAutoscaler/infra/GITHUB_SSH_AUTHENTICATION_TOKEN)"
    )
    - Set all secrets with `fly secrets import < ./SeleniumGridNodeMachineAutoscaler/.env.development --app automa-web-core-seleniumgrid-node-autoscaler`


**TODO**
1. Create `.env.sample`
