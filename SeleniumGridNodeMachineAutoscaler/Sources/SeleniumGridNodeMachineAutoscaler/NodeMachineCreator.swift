// NodeMachineCreator.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import AutomaUtilities
import Vapor

internal class NodeMachineCreationBase: SeleniumGridNodeAppInteractor, SeleniumGridInteractor {
    internal let machineConfiguration: MachinePropertyConfiguration
    internal let seleniumGridNodeBase: String
    internal let seleniumGridHubBase: String

    internal struct MachinePropertyConfiguration: Content {
        internal let region: String
        internal var config: MachineConfiguration
    }

    internal struct MachineConfiguration: Content {
        internal let image: String
        internal var skipLaunch: Bool
        internal var env: [String: String]
        internal let autoDestroy: Bool
        internal let restart: [String: String]
        internal let guest: MachineGuessConfiguration

        /// Coding keys for `NodeMachineCreationBase`
        public enum CodingKeys: String, CodingKey {
            case image
            case skipLaunch = "skip_launch"
            case env
            case autoDestroy = "auto_destroy"
            case restart
            case guest
        }
    }

    internal struct MachineGuessConfiguration: Content {
        internal let cpuKind: String
        internal let cpus: Int
        internal let memoryMb: Int

        /// Coding keys for `MachineGuessConfiguration`
        public enum CodingKeys: String, CodingKey {
            case cpuKind = "cpu_kind"
            case cpus
            case memoryMb = "memory_mb"
        }
    }

    internal typealias MachineIdentifier = String

    internal init(
        logger: Logger,
        client: any Client,
        seleniumGridHubBase: String
    ) throws {
        seleniumGridNodeBase = try Environment.getOrThrow("SELENIUM_GRID_NODE_BASE")
        self.seleniumGridHubBase = seleniumGridHubBase
        machineConfiguration = Self.getCreateNodeMachineConfiguration()
        try super.init(logger: logger, client: client)
    }

    private static func getCreateNodeMachineConfiguration() -> MachinePropertyConfiguration {
        MachinePropertyConfiguration(
            region: "jnb",
            config: .init(
                image: "selenium/node-chrome:latest",
                skipLaunch: true,
                env: ["SE_OPTS": "--drain-after-session-count 1"],
                autoDestroy: false,
                restart: [
                    "policy": "always"
                ],
                guest: .init(cpuKind: "shared", cpus: 1, memoryMb: 2_048)
            )
        )
    }

    deinit {}
}

internal class NodeMachineCreator: NodeMachineCreationBase {
    /// Create new node machine for Selenium Grid Node app on fly.io
    /// - Throws: An error if creating machine fails
    public func create() async throws {
        try await createImpl()
    }

    private func createImpl() async throws {
        sendTelemetryDataOnCreateNodeMachineStarted()
        let machineID = try await createNodeMachine()
        try await updateAndStartMachine(machineID: machineID)
    }

    private func sendTelemetryDataOnCreateNodeMachineStarted() {
        AutoscalerMetric.createSeleniumGridNodeAppFlyMachine(status: .start).increment()
        logCreateNodeMachineStarted()
    }

    private func logCreateNodeMachineStarted() {
        logger.info(
            "Creating new node machine.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
            ]
        )
    }

    private func createNodeMachine() async throws -> MachineIdentifier {
        let machineID: MachineIdentifier
        do {
            let response = try await getCreateNodeMachineResponse()
            try handleInvalidCreateNodeMachineResponse(response: response)
            machineID = try getMachineIDFromCreateMachineResponse(response)
        } catch {
            sendTelemetryDataOnCreateNodeMachineFail(error: error)
            // TODO: refactor throwing direct error to custom `SeleniumGridNodeMachineAutoscalerError`
            throw error
        }
        sendTelemetryDataOnCreateNodeMachineSuccess(machineID: machineID)
        return machineID
    }

    private func sendTelemetryDataOnCreateNodeMachineSuccess(machineID: MachineIdentifier) {
        AutoscalerMetric.createSeleniumGridNodeAppFlyMachine(status: .success).increment()
        logNodeMachineCreationSuccess(machineID: machineID)
    }

    private func getCreateNodeMachineResponse() async throws
        -> ClientResponse
    {
        return try await client.post(.init(stringLiteral: payload.nodesAppMachineAPIURL)) { req in
            req.headers = .init(flyAPIHTTPRequestAuthenticationHeader)
            try req.content.encode(machineConfiguration)
        }
    }

    private func handleInvalidCreateNodeMachineResponse(response: ClientResponse) throws {
        if isInvalidHTTPResponseStatus(status: response.status) {
            let error = try decodeErrorFromResponse(response)
            try handleFlyMachinesAPIError(payload: .init(message: "Node machine creation failed", error: error))
        }
    }

    private func getMachineIDFromCreateMachineResponse(_ response: ClientResponse) throws -> MachineIdentifier {
        struct CreateMachineResponseContent: Content {
            let id: String
        }
        return try response.content.decode(CreateMachineResponseContent.self).id
    }

    private func sendTelemetryDataOnCreateNodeMachineFail(error: any Error) {
        AutoscalerMetric.createSeleniumGridNodeAppFlyMachine(status: .fail).increment()
        logNodeMachineCreationFail(error: error)
    }

    private func logNodeMachineCreationFail(error: any Error) {
        logger.info(
            "Node machine creation failed.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "error": .string(error.localizedDescription),
            ]
        )
    }

    private func logNodeMachineCreationSuccess(machineID: MachineIdentifier) {
        logger.info(
            "Node machine creation success.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "machine_id": .string(machineID),
            ]
        )
    }

    private func updateAndStartMachine(machineID: MachineIdentifier) async throws {
        try await NodeMachineUpdater(
            logger: logger,
            client: client,
            seleniumGridHubBase: seleniumGridHubBase,
            machineID: machineID
        )
        .updateNodeHostURLEnvironmentVariable()

        try await sleepBetweenCycle(config: .init(duration: 20))
    }

    deinit {}
}
