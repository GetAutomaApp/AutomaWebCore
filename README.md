# AutomaWebCore

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg?style=flat&logo=swift)](https://swift.org/)
[![Vapor](https://img.shields.io/badge/Vapor-4-2D68F7.svg?logo=vapor)](https://vapor.codes/)
[![Docker](https://img.shields.io/badge/Docker-2CA5E0?logo=docker&logoColor=white)](https://www.docker.com/)
[![Fly.io](https://img.shields.io/badge/Deploy%20on-Fly.io-8A2BE2)](https://fly.io/)

AutomaWebCore is the core infrastructure powering the web automation capabilities of the Automa platform. This repository contains the backend services and infrastructure code needed to run scalable web automation workflows, including a Selenium Grid node autoscaler and a high-performance API service.

## 📦 Project Structure

The repository is organized into several main components:

### API (`/API`)
A high-performance web service built with Vapor 4 that provides:
- RESTful API endpoints for web automation tasks
- Integration with WebDriver for browser automation

### SeleniumGridNodeMachineAutoscaler (`/SeleniumGridNodeMachineAutoscaler`)
A specialized service that manages the dynamic scaling of Selenium Grid nodes:
- Automatic creation of new Selenium nodes based on demand
- Cleanup of idle or outdated nodes
- Integration with cloud providers for node provisioning

### Infrastructure (`/infra`)
Contains infrastructure-as-code and deployment configurations:
- Docker configurations for local development
- Deployment scripts for different environments
- Fly.io configuration files
- Secrets management

## 🚀 Features

- **Dynamic Resource Allocation**: Automatic scaling of Selenium Grid nodes based on workload
- **Containerized Deployment**: Easy deployment using Docker and container orchestration
- **Multi-Environment Support**: Sandbox, staging, and production environments
- **Monitoring**: Built-in metrics and health checks

## 🛠️ Technical Stack

- **Backend**: Swift 6.0, Vapor 4
- **Web Automation**: SwiftWebDriver
- **Containerization**: Docker, Docker Compose
- **Deployment**: Fly.io
- **CI/CD**: GitHub Actions
- **Dependencies**:
  - Vapor ecosystem
  - Custom Automa utilities

## 🔧 Setup (Coming Soon)

A comprehensive setup guide for self-hosting AutomaWebCore or running it locally will be provided in the future. This will include:

1. Prerequisites and system requirements
2. Environment variables and secrets
3. Building and running the autoscaler and API
4. Deployment options

## 🤝 Contributing

Contributions are welcome!

## 📄 License

This project is open source and available under the MIT License.

## 📬 Contact

For inquiries, contact the Automa team at [william@getautoma.app](mailto:william@getautoma.app) or [ceo@getautoma.app](mailto:ceo@getautoma.app).