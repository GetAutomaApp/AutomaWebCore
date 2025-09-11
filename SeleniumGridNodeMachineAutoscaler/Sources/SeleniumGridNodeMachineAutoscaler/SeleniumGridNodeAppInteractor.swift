// SeleniumGridNodeAppInteractor.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import AutomaUtilities
import Vapor

internal protocol SeleniumGridNodeAppInteractorBase {
    var payload: SeleniumGridNodeAppInteractorPayload { get }
}

internal struct SeleniumGridNodeAppInteractorPayload: Content {
    let nodesAppMachineAPIURL: String
    let flyAPIToken: String
    let flyAPIHTTPRequestAuthenticationHeader: FlyAPIHTTPRequestAuthenticationHeader

    internal struct FlyAPIHTTPRequestAuthenticationHeader: Content {
        let Authorization: String

        func getHeaderList() -> [(String, String)] {
            return [("Authorization", Authorization)]
        }
    }
}

internal class SeleniumGridNodeAppInteractor: SeleniumGridNodeAppInteractorBase {
    let payload: SeleniumGridNodeAppInteractorPayload
    let logger: Logger
    let client: any Client

    init(logger: Logger, client: any Client) throws {
        self.logger = logger
        self.client = client

        let flyAPIURL = try URL.fromString(payload: .init(string: Environment.getOrThrow("FLY_API_URL")))
        let flyAPIToken = try Environment.getOrThrow("SELENIUM_GRID_NODE_FLY_APP_API_TOKEN")

        payload = .init(
            nodesAppMachineAPIURL: "\(flyAPIURL.absoluteString)/v1/apps/automa-web-core-seleniumgrid-node/machines",
            flyAPIToken: flyAPIToken,
            flyAPIHTTPRequestAuthenticationHeader: .init(Authorization: "Bearer \(flyAPIToken)")
        )
    }

    internal func getListOfAllNodeMachines() async throws -> [SeleniumGridNodeAppNodeMachinesFinder.NodeMachine] {
        try await SeleniumGridNodeAppNodeMachinesFinder(
            logger: logger,
            client: client,
            payload: payload
        )
        .getListOfAllNodeMachines()
    }
}

internal struct SeleniumGridNodeAppNodeMachinesFinder: SeleniumGridNodeAppInteractorBase {
    let payload: SeleniumGridNodeAppInteractorPayload
    let logger: Logger
    let client: any Client

    internal init(
        logger: Logger,
        client: any Client,
        payload: SeleniumGridNodeAppInteractorPayload
    ) {
        self.logger = logger
        self.client = client
        self.payload = payload
    }

    public func getListOfAllNodeMachines() async throws -> [NodeMachine] {
        return try await getAllNodeMachinesList()
    }

    private func getAllNodeMachinesList() async throws -> [NodeMachine] {
        logGetListOfAllMachinesStarted()
        let allMachines = try await validateAndGetAllMachines()
        logGetListOfAllMachinesSuccess(totalMachines: allMachines.count)
        return allMachines
    }

    private func validateAndGetAllMachines() async throws -> [NodeMachine] {
        let response = try await getAllNodeMachinesResponse()
        try validateAllNodeMachinesResponseStatus(response: response)

        return try getNodeMachineListFromAppNodeMachinesResponse(response)
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

    private func getNodeMachineListFromAppNodeMachinesResponse(_ response: ClientResponse) throws -> [NodeMachine] {
        try response.content.decode([NodeMachine].self)
    }

    private func validateAllNodeMachinesResponseStatus(response: ClientResponse) throws {
        if isInvalidAllNodeMachinesResponseStatus(status: response.status) {
            try handleInvalidAllNodeMachinesResponse(res: response)
        }
    }

    private func handleInvalidAllNodeMachinesResponse(res: ClientResponse) throws {
        let responseContent = try res.content.decode([String: String].self)
        logger.info(
            "Failed to get a list of all machines in nodes app",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "response_content": .string("\(responseContent)"),
            ]
        )
        throw Abort(.internalServerError)
    }

    private func isInvalidAllNodeMachinesResponseStatus(status: HTTPStatus) -> Bool {
        return status != .ok
    }

    private func getAllNodeMachinesResponse() async throws -> ClientResponse {
        return try await client.get(
            .init(stringLiteral: payload.nodesAppMachineAPIURL),
            headers: .init(payload.flyAPIHTTPRequestAuthenticationHeader.getHeaderList())
        )
    }

    private func logGetListOfAllMachinesStarted() {
        logger.info(
            "Getting a list of all machines.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
            ]
        )
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
}
