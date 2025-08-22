// SeleniumGridNodeAutoscaler.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

internal struct SeleniumGridNodeAutoscaler {
    let seleniumGridHubBaseURL: URL
    let client: any Client

    init(client: any Client) throws {
        self.client = client
        guard let
            urlString = Environment.get("SELENIUM_GRID_HUB_BASE_URL")
        else {
            throw Abort(.internalServerError)
        }
        guard let url = URL(string: urlString)
        else {
            throw Abort(.internalServerError)
        }

        seleniumGridHubBaseURL = url
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
        let res = try await client.post(.init(path: "\(seleniumGridHubBaseURL.absoluteString)/graphql")) { req in
            try req.content.encode(SeleniumGridGraphQLQuery(query: "Bob"))
        }
        return try res.content.decode(SessionQueueResponse.self)
    }

    private func createNewSeleniumGridNodeFlyMachine() async throws {
        guard
            let flyMachineAPIBaseURL = URL(string: "https://api.machines.dev")
        else {
            throw Abort(.internalServerError)
        }
        guard
            let seleniumGridHubAppFlyAPIToken = Environment.get("SELENIUM_GRID_HUB_APP_FLY_API_TOKEN")
        else {
            throw Abort(.internalServerError)
        }
    }

    public func autoscale() async throws {
        while true {
            let response = try await getGridSessionQueueReponse()
            let totalSessionsInQueue = response.data.sessionsInfo.sessionQueueRequests.count
            if totalSessionsInQueue > 0 {
                // create a selenium node fly machine for every session
                for i in 1 ... totalSessionsInQueue {
                    try await createNewSeleniumGridNodeFlyMachine()
                }
            }
        }
    }
}
