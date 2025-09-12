// SeleniumGridNodeAppInteractor.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import AutomaUtilities
import Vapor

internal class SeleniumGridNodeAppInteractor: SeleniumGridNodeAppInteractorBase {
    let payload: SeleniumGridNodeAppInteractorPayload
    let flyAPIHTTPRequestAuthenticationHeader: [(String, String)]
    let logger: Logger
    let client: any Client

    init(logger: Logger, client: any Client) throws {
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

    internal func getListOfAllNodeMachines() async throws -> [SeleniumGridNodeAppNodeMachinesFinder.NodeMachine] {
        try await SeleniumGridNodeAppNodeMachinesFinder(
            logger: logger,
            client: client,
            payload: payload,
            flyAPIHTTPRequestAuthenticationHeader: flyAPIHTTPRequestAuthenticationHeader,
        )
        .getListOfAllNodeMachines()
    }
}

internal struct SeleniumGridNodeAppNodeMachinesFinder: SeleniumGridNodeAppInteractorBase {
    let logger: Logger
    let client: any Client
    var payload: SeleniumGridNodeAppInteractorPayload
    var flyAPIHTTPRequestAuthenticationHeader: [(String, String)]

    public func getListOfAllNodeMachines() async throws -> [NodeMachine] {
        return try await getAllNodeMachinesList()
    }

    internal struct NodeMachine: Content {
        let id: String
        let state: String
        let createdAt: Date

        public enum CodingKeys: String, CodingKey {
            case id
            case state
            case createdAt = "created_at"
        }
    }

    private func getAllNodeMachinesList() async throws -> [NodeMachine] {
        logGetListOfAllMachinesStarted()
        let allMachines = try await validateAndGetAllMachines()
        logGetListOfAllMachinesSuccess(totalMachines: allMachines.count)
        return allMachines
    }

    private func logGetListOfAllMachinesStarted() {
        logger.info(
            "Getting a list of all machines.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
            ]
        )
    }

    private func validateAndGetAllMachines() async throws -> [NodeMachine] {
        let response = try await getAllNodeMachinesResponse()
        try validateFindAllNodeMachinesResponseStatus(response: response)

        return try findNodeMachineListFromResponse(response)
    }

    private func getAllNodeMachinesResponse() async throws -> ClientResponse {
        return try await client.get(
            .init(stringLiteral: payload.nodesAppMachineAPIURL),
            headers: .init(flyAPIHTTPRequestAuthenticationHeader)
        )
    }

    private func validateFindAllNodeMachinesResponseStatus(response: ClientResponse) throws {
        if isInvalidHTTPResponseStatus(status: response.status) {
            try handleInvalidFindAllNodeMachinesResponse(res: response)
        }
    }

    private func handleInvalidFindAllNodeMachinesResponse(res: ClientResponse) throws {
        let error = try decodeErrorFromResponse(res)
        try logInvalidFindAllNodeMachinesResponse(error: error)
    }

    private func logInvalidFindAllNodeMachinesResponse(error: [String: String]) throws {
        logger.error(
            "Failed to get a list of all machines in nodes app",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "error": .string("\(error)"),
            ]
        )

        throw Abort(.internalServerError)
    }

    private func findNodeMachineListFromResponse(_ response: ClientResponse) throws -> [NodeMachine] {
        try response.content.decode([NodeMachine].self)
    }

    private func logGetListOfAllMachinesSuccess(totalMachines: Int) {
        logger.info(
            "Got list of all machines.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "total_machines": .string(String(totalMachines))
            ]
        )
    }
}

internal protocol SeleniumGridNodeAppInteractorBase {
    var payload: SeleniumGridNodeAppInteractorPayload { get }
    var flyAPIHTTPRequestAuthenticationHeader: [(String, String)] { get }
}

extension SeleniumGridNodeAppInteractorBase {
    func decodeErrorFromResponse(_ response: ClientResponse) throws -> [String: String] {
        return try response.content.decode([String: String].self)
    }

    func isInvalidHTTPResponseStatus(status: HTTPStatus) -> Bool {
        return status != .ok
    }
}

internal struct SeleniumGridNodeAppInteractorPayload: Content {
    let nodesAppMachineAPIURL: String
    let flyAPIToken: String
}
