// SeleniumGridNodeAutoscaler.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

internal class SeleniumGridNodeAutoscaler: SeleniumGridNodeAppInteractor {
    let seleniumGridHubBase: String
    let seleniumGridNodeBase: String

    let maxNodeMachinesAllowed: Int = 10

    init(client: any Client, logger: Logger) throws {
        seleniumGridHubBase = try Environment.getOrThrow("SELENIUM_GRID_HUB_BASE")
        seleniumGridNodeBase = try Environment.getOrThrow("SELENIUM_GRID_NODE_BASE")
        try super.init(logger: logger, client: client)
    }

    public func autoscale(cyclePauseDuration: Int) async throws {
        try await autoscaleNodes(cyclePauseDuration: cyclePauseDuration)
    }

    private func autoscaleNodes(cyclePauseDuration: Int, cycleCount: Int = 1) async throws {
        logger.info(
            "Node autoscaler cycle started (cycle: \(cycleCount)).",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)")
            ]
        )

        if try await maxNodeMachinesReached() {
            return
        }

        let response = try await getGridSessionQueueReponse()
        let totalSessionsInQueue = response.data.sessionsInfo.sessionQueueRequests.count
        if totalSessionsInQueue > 0 {
            logger.info(
                "Found a total of \(totalSessionsInQueue) pending sessions in queue.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                ]
            )
            // create a selenium node fly machine for every session
            for _ in 1 ... totalSessionsInQueue {
                try await createNewSeleniumGridNodeFlyMachine()
            }
        }
        try await Task.sleep(for: .seconds(cyclePauseDuration))
        try await autoscaleNodes(cyclePauseDuration: cyclePauseDuration, cycleCount: cycleCount + 1)
    }

    private func maxNodeMachinesReached() async throws -> Bool {
        let totalNodeMachines = try await getListOfAllNodeMachines().count

        if totalNodeMachines < maxNodeMachinesAllowed {
            return false
        }

        logger.info(
            "The threshold of \(maxNodeMachinesAllowed) running node machines reached. No additional node machines will be created.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "total_node_machines": .string(String(totalNodeMachines))
            ]
        )
        return true
    }

    private func getGridSessionQueueReponse() async throws -> SessionQueueResponse {
        logger.info(
            "Looking for sessions in queue.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
            ]
        )
        let url = "http://\(seleniumGridHubBase):4444/graphql"
        let res = try await client.post(.init(stringLiteral: url)) { req in
            try req.content
                .encode(SeleniumGridGraphQLQuery(query: "query SessionsInfo { sessionsInfo { sessionQueueRequests }}"))
        }
        return try res.content.decode(SessionQueueResponse.self)
    }

    private func createNewSeleniumGridNodeFlyMachine() async throws {
        logger.info(
            "Creating new node machine.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
            ]
        )

        let machineConfiguration = MachinePropertyConfiguration(
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

        let res = try await client.post(.init(stringLiteral: nodesAppMachineAPIURL)) { req in
            req.headers = .init(authHeader)
            try req.content.encode(machineConfiguration)
        }

        if res.status != .ok {
            let responseContent = try res.content.decode([String: String].self)
            logger.info(
                "Node machine creation failed.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "response_content": .string("\(responseContent)")
                ]
            )
            throw Abort(.internalServerError)
        }

        logger.info(
            "Node machine creation success.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
            ]
        )

        struct CreateMachineResponseContent: Content {
            let id: String
        }

        let machineIdentifier = try res.content.decode(CreateMachineResponseContent.self).id
        try await updateMachineNodeHostURLEnvironmentVariable(
            machineIdentifier: machineIdentifier,
            machineConfiguration: machineConfiguration,
            flyAPIToken: flyAPIToken
        )

        try await Task.sleep(for: .seconds(20))
    }

    private func updateMachineNodeHostURLEnvironmentVariable(
        machineIdentifier: String,
        machineConfiguration: MachinePropertyConfiguration,
        flyAPIToken _: String
    ) async throws {
        var updatedConfiguration = machineConfiguration

        updatedConfiguration.config.env = [
            "SE_OPTS": "--drain-after-session-count 1",
            "SE_EVENT_BUS_HOST": seleniumGridHubBase,
            "SE_NODE_HOST": "\(machineIdentifier).vm.\(seleniumGridNodeBase)"
        ]

        updatedConfiguration.config.skipLaunch = false
        logger.info(
            "Machine updated environment.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "updated_configuration": .string("\(updatedConfiguration.config)")
            ]
        )

        let res = try await client.post(.init(stringLiteral: "\(nodesAppMachineAPIURL)/\(machineIdentifier)")) { req in
            req.headers = .init(authHeader)
            try req.content.encode(["config": updatedConfiguration.config])
        }

        if res.status != .ok {
            let responseContent = try res.content.decode([String: String].self)
            logger.info(
                "Failed to updated machine node 'SE_NODE_HOST' environment variable to URL of the machine",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "response_content": .string("\(responseContent)"),
                    "machine_identifier": .string(machineIdentifier)
                ]
            )
            throw Abort(.internalServerError)
        }

        guard
            let body = res.body
        else {
            throw Abort(.internalServerError)
        }

        logger.info(
            "Updating node 'SE_NODE_HOST' environment variable success. Machine will start automatically.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "machine_identifier": .string(machineIdentifier),
                "update_machine_response": .string(String(buffer: body))
            ]
        )
    }

    internal struct SeleniumGridGraphQLQuery: Content {
        let query: String
    }

    internal struct SessionQueueResponse: Content {
        let data: SessionQueueResponseData
    }

    internal struct SessionQueueResponseData: Content {
        let sessionsInfo: SessionsInfo
    }

    internal struct SessionsInfo: Content {
        let sessionQueueRequests: [String]
    }

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
}
