// SeleniumGridNodeAutoscaler.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

internal struct SeleniumGridNodeAutoscaler {
    let seleniumGridHubBase: String

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

        guard
            let seleniumGridNodeBase = Environment.get("SELENIUM_GRID_NODE_BASE")
        else {
            throw Abort(.internalServerError)
        }

        let createMachineContent: [String: Any] = [
            "config": [
                "image": "selenium/node-chrome:latest",
                "region": "jnb",
                "env": [
                    "SE_EVENT_BUS_HOST": seleniumGridHubBase,
                    "SE_NODE_HOST": seleniumGridNodeBase
                ],
                "auto_destroy": true,
                "restart": [
                    "policy": "always"
                ],
                "guest": [
                    "cpu_kind": "shared",
                    "cpus": 1,
                    "memory_mb": 2_048
                ]
            ]
        ]

        let createMachineContentEncoded = AnyEncodable(createMachineContent)

        let res = try await client.post(.init(stringLiteral: url)) { req in
            req.headers = .init([("Authorization", "Bearer \(flyAPIToken)")])
            try req.content.encode(createMachineContentEncoded, as: .json)
        }
        if res.status != .ok {
            logger.info(
                "Node machine creation failed.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
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
        try await Task.sleep(for: .seconds(20))
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
