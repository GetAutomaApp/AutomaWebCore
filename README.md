1. Deploy Selenium Grid Hub Machine: `fly launch --ha=false --org <org-name> --config ./infra/seleniumgrid-hub.toml`
2. Deploy Selenium Grid Node Machine: `fly launch --ha=false --org <org-name> --config ./infra/seleniumgrid-node.toml`
