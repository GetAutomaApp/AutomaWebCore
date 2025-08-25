// SeleniumGridNodeAutoscaler.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

internal struct SeleniumGridNodeAutoscaler {
    let seleniumGridHubBase: String
    let seleniumGridNodeBase: String

    let client: any Client
    let logger: Logger

    init(client: any Client, logger: Logger) throws {
        self.client = client
        self.logger = logger
        guard let hubBase = Environment.get("SELENIUM_GRID_HUB_BASE")
        else {
            throw Abort(.internalServerError)
        }
        seleniumGridHubBase = hubBase

        guard
            let nodeBase = Environment.get("SELENIUM_GRID_NODE_BASE")
        else {
            throw Abort(.internalServerError)
        }

        seleniumGridNodeBase = nodeBase
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

    private func getGridSessionQueueReponse() async throws -> SessionQueueResponse {
        let url = "http://\(seleniumGridHubBase):4444/graphql"
        logger.info(
            "Session Queue URL: \(url).",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
            ]
        )
        let res = try await client.post(.init(stringLiteral: url)) { req in
            try req.content
                .encode(SeleniumGridGraphQLQuery(query: "query SessionsInfo { sessionsInfo { sessionQueueRequests }}"))
        }
        return try res.content.decode(SessionQueueResponse.self)
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

    private func createNewSeleniumGridNodeFlyMachine() async throws {
        logger.info(
            "Creating new node machine.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
            ]
        )
        guard
            let urlString = Environment.get("FLY_API_URL"),
            let flyAPIURL = URL(string: urlString)
        else {
            throw Abort(.internalServerError)
        }
        guard
            let flyAPIToken = Environment.get("SELENIUM_GRID_NODE_FLY_APP_API_TOKEN")
        else {
            throw Abort(.internalServerError)
        }

        let url = "\(flyAPIURL.absoluteString)/v1/apps/automa-web-core-seleniumgrid-node/machines"

        let machineConfiguration = MachinePropertyConfiguration(
            region: "jnb",
            config: .init(
                image: "selenium/node-chrome:latest",
                skipLaunch: true,
                env: [:],
                autoDestroy: false,
                restart: [
                    "policy": "always"
                ],
                guest: .init(cpuKind: "shared", cpus: 1, memoryMb: 2_048)
            )
        )

        let res = try await client.post(.init(stringLiteral: url)) { req in
            req.headers = .init([("Authorization", "Bearer \(flyAPIToken)")])
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
            flyAPIToken: flyAPIToken,
            machineAPIURL: url
        )

        try await Task.sleep(for: .seconds(20))
    }

    private func updateMachineNodeHostURLEnvironmentVariable(
        machineIdentifier: String,
        machineConfiguration: MachinePropertyConfiguration,
        flyAPIToken: String,
        machineAPIURL url: String
    ) async throws {
        var updatedConfiguration = machineConfiguration

        updatedConfiguration.config.env = [
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

        let res = try await client.post(.init(stringLiteral: "\(url)/\(machineIdentifier)")) { req in
            req.headers = .init([("Authorization", "Bearer \(flyAPIToken)")])
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

    public func autoscale() async throws {
        logger.info(
            "Node autoscaler started.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)")
            ]
        )
        var count = 1
        while true {
            logger.info(
                "Looking for sessions in queue... (count: \(count))",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                ]
            )
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
            try await Task.sleep(for: .seconds(10))
            count += 1
        }
    }
}
