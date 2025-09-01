**Launch all apps**

1. Launch Selenium Grid Hub: `fly launch --ha=false --org <org-name> --config ./infra/seleniumgrid-hub.toml`
2. Launch Selenium Grid Node App: `fly launch --ha=false --org <org-name> --config ./infra/seleniumgrid-node.toml`
3. Launch Selenium Grid Node Autoscaler: `fly launch --ha=false --org <org-name> --config ./SeleniumGridNodeMachineAutoscaler/infra/autoscaler.toml`
    - Set all secrets with `fly secrets import < ./.env.development --app automa-web-core-seleniumgrid-node-autoscaler`
4. Launch Selenium Grid Node Off Machine Auto Destroyer: `fly launch --ha=false --org <org-name> --config ./SeleniumGridNodeMachineAutoscaler/infra/offMachinesAutoDestroyer.toml`
5. Launch Selenium Grid Node Old Machine Auto Destroyer: `fly launch --ha=false --org <org-name> --config ./SeleniumGridNodeMachineAutoscaler/infra/oldMachinesAutoDestroyer.toml`
