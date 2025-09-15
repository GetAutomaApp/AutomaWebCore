// SeleniumGridSessionQueueRequestsHandler.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

internal struct SeleniumGridSessionQueueRequestsHandler: SeleniumGridInteractor {
    var client: any Client
    var logger: Logger
    var seleniumGridHubBase: String

    public func getTotalRequests() async throws -> Int {
        let response = try await getGridSessionQueueReponse()
        return getTotalSessionQueueRequestsFromResponse(response)
    }

    private func getGridSessionQueueReponse() async throws -> SessionQueueResponse {
        logGetGridSessionQueueResponseStarted()
        let response = try await querySeleniumGridHubForSessionQueueRequests()
        return try decodeSessionQueueResponseFromClientResponse(response)
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

    private func logGetGridSessionQueueResponseStarted() {
        logger.info(
            "Looking for sessions in queue.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
            ]
        )
    }

    private func querySeleniumGridHubForSessionQueueRequests() async throws -> ClientResponse {
        let uri = getSeleniumGridGraphQLURI()
        let query = getSessionQueueRequestsGraphQLQuery()
        return try await client.post(uri) { req in
            try req.content.encode(query)
        }
    }

    private func getSeleniumGridGraphQLURI() -> URI {
        URI(stringLiteral: "http://\(seleniumGridHubBase):4444/graphql")
    }

    private func getSessionQueueRequestsGraphQLQuery() -> SeleniumGridGraphQLQuery {
        SeleniumGridGraphQLQuery(query: "query SessionsInfo { sessionsInfo { sessionQueueRequests }}")
    }

    internal struct SeleniumGridGraphQLQuery: Content {
        let query: String
    }

    private func decodeSessionQueueResponseFromClientResponse(_ response: ClientResponse) throws
        -> SessionQueueResponse
    {
        return try response.content.decode(SessionQueueResponse.self)
    }

    private func getTotalSessionQueueRequestsFromResponse(_ response: SessionQueueResponse)
        -> Int
    {
        response.data.sessionsInfo.sessionQueueRequests.count
    }
}
