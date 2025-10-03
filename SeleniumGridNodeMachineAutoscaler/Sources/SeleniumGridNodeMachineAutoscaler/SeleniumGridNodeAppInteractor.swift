// SeleniumGridNodeAppInteractor.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import AutomaUtilities
import Vapor

internal protocol SeleniumGridNodeAppInteractorBase {
    var client: any Client { get }
    var logger: Logger { get }
    var payload: SeleniumGridNodeAppInteractorPayload { get }
    var flyAPIHTTPRequestAuthenticationHeader: [(String, String)] { get }
}

internal struct SeleniumGridNodeAppInteractorPayload: Content {
    internal let nodesAppMachineAPIURL: String
    internal let flyAPIToken: String
}

internal extension SeleniumGridNodeAppInteractorBase {
    typealias FlyAPIError = [String: String]

    func decodeErrorFromResponse(_ response: ClientResponse) throws -> FlyAPIError {
        do {
            return try response.content.decode(FlyAPIError.self)
        } catch {
            throw AutomaGenericErrors.decodeResponseContentFailed(
                contentType: "FlyAPIError",
                error: error.localizedDescription
            )
        }
    }

    func isInvalidHTTPResponseStatus(status: HTTPStatus) -> Bool {
        return status != .ok
    }

    func handleFlyMachinesAPIError(payload: FlyMachinesAPIErrorHandlerPayload) throws {
        try FlyMachinesAPIErrorHandler(payload: payload, logger: logger).handle()
    }
}

internal struct FlyMachinesAPIErrorHandlerPayload {
    internal let message: String
    internal let metadata: Logger.Metadata = [:]
    internal let error: SeleniumGridNodeAppInteractorBase.FlyAPIError
}

internal class SeleniumGridNodeAppInteractor: SeleniumGridNodeAppInteractorBase {
    internal let payload: SeleniumGridNodeAppInteractorPayload
    internal let flyAPIHTTPRequestAuthenticationHeader: [(String, String)]
    internal let logger: Logger
    internal let client: any Client

    internal init(logger: Logger, client: any Client) throws {
        self.logger = logger
        self.client = client

        let flyAPIURL = try URL.fromString(payload: .init(string: Environment.getOrThrow("FLY_API_URL")))
        let flyAPIToken = try Environment.getOrThrow("SELENIUM_GRID_NODE_FLY_APP_API_TOKEN")

        flyAPIHTTPRequestAuthenticationHeader = [("Authorization", "Bearer \(flyAPIToken)")]

        payload = .init(
            nodesAppMachineAPIURL: "\(flyAPIURL.absoluteString)/v1/apps/automa-web-core-seleniumgrid-node/machines",
            flyAPIToken: flyAPIToken
        )
    }

    internal func getListOfAllNodeMachines() async throws -> NodeMachines {
        try await SeleniumGridNodeAppNodeMachinesFinder(
            logger: logger,
            client: client,
            payload: payload,
            flyAPIHTTPRequestAuthenticationHeader: flyAPIHTTPRequestAuthenticationHeader,
        )
        .getListOfAllNodeMachines()
    }

    internal func sleepBetweenCycle(config: CycleSleeper.CycleSleeperConfig) async throws {
        try await CycleSleeper(config, logger: logger).sleep()
    }

    internal func getClientResponseBodyAsString(
        response: ClientResponse,
    ) -> String {
        String(buffer: response.body ?? .init(string: "<<response_body_empty>>"))
    }

    deinit {}
}

internal struct NodeMachine: Content {
    internal let id: String
    internal let state: String
    internal let createdAt: Date

    /// Coding keys for `NodeMachine`
    public enum CodingKeys: String, CodingKey {
        case id
        case state
        case createdAt = "created_at"
    }
}

internal typealias NodeMachines = [NodeMachine]
