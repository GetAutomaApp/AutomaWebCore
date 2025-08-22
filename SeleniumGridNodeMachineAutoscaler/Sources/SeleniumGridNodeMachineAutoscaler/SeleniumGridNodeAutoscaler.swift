// SeleniumGridNodeAutoscaler.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

internal struct SeleniumGridNodeAutoscaler {
    let seleniumGridHubBase: String

    let client: any Client

    init(client: any Client) throws {
        self.client = client
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
        let res = try await client.post(.init(path: "http://\(seleniumGridHubBase)/graphql")) { req in
            try req.content
                .encode(SeleniumGridGraphQLQuery(query: "query SessionsInfo { sessionsInfo { sessionQueueRequests }}"))
        }
        return try res.content.decode(SessionQueueResponse.self)
    }

    private func createNewSeleniumGridNodeFlyMachine() async throws {
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

        let res = try await client.post(.init(path: url)) { req in
            req.headers = .init([("Authorization", "Bearer \(flyAPIToken)")])
            try req.content.encode(createMachineContentEncoded, as: .json)
        }
        if res.status != .ok {
            throw Abort(.internalServerError)
        }
    }

    public func autoscale() async throws {
        while true {
            let response = try await getGridSessionQueueReponse()
            let totalSessionsInQueue = response.data.sessionsInfo.sessionQueueRequests.count
            if totalSessionsInQueue > 0 {
                // create a selenium node fly machine for every session
                for _ in 1 ... totalSessionsInQueue {
                    try await createNewSeleniumGridNodeFlyMachine()
                }
            }
        }
    }
}
