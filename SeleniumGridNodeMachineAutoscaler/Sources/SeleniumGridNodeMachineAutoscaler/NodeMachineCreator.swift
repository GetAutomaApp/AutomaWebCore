// NodeMachineCreator.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import AutomaUtilities
import Vapor

internal class NodeMachineCreationBase: SeleniumGridNodeAppInteractor, SeleniumGridInteractor {
    let machineConfiguration: MachinePropertyConfiguration
    let seleniumGridNodeBase: String
    let seleniumGridHubBase: String

    internal struct MachinePropertyConfiguration: Content {
        let region: String
        var config: MachineConfiguration
    }

    internal struct MachineConfiguration: Content {
        let image: String
        var skipLaunch: Bool
        var env: [String: String]
        let autoDestroy: Bool
        let restart: [String: String]
        let guest: MachineGuessConfiguration

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
        let cpuKind: String
        let cpus: Int
        let memoryMb: Int

        public enum CodingKeys: String, CodingKey {
            case cpuKind = "cpu_kind"
            case cpus
            case memoryMb = "memory_mb"
        }
    }

    typealias MachineIdentifier = String

    init(
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
}

internal class NodeMachineCreator: NodeMachineCreationBase {
    public func create() async throws {
        try await createImpl()
    }

    private func createImpl() async throws {
        logCreateNodeMachineStarted()
        let machineID = try await createNodeMachine()
        try await updateAndStartMachine(machineID: machineID)
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
        let response = try await getCreateNodeMachineResponse()
        try handleInvalidCreateNodeMachineResponse(response: response)
        let machineID = try getMachineIDFromCreateMachineResponse(response)
        logNodeMachineCreationSuccess(machineID: machineID)
        return machineID
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
}
