// SeleniumGridNodeAppNodeMachinesFinder.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

// TODO: Use logger.error instead of logger.info in places where errors occur. Create custom errors instead of using internalServerError everywhere.
// add more and better logs

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

    private func logInvalidFindAllNodeMachinesResponse(error: FlyAPIError) throws {
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
