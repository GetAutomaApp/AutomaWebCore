// SeleniumGridNodeAppNodeMachinesFinder.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

internal struct SeleniumGridNodeAppNodeMachinesFinder: SeleniumGridNodeAppInteractorBase {
    let logger: Logger
    let client: any Client
    var payload: SeleniumGridNodeAppInteractorPayload
    var flyAPIHTTPRequestAuthenticationHeader: [(String, String)]

    public func getListOfAllNodeMachines() async throws -> NodeMachines {
        return try await getAllNodeMachinesList()
    }

    private func getAllNodeMachinesList() async throws -> NodeMachines {
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

    private func validateAndGetAllMachines() async throws -> NodeMachines {
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
            try handleInvalidFindAllNodeMachinesResponse(response: response)
        }
    }

    private func handleInvalidFindAllNodeMachinesResponse(response: ClientResponse) throws {
        let error = try decodeErrorFromResponse(response)
        try handleFlyMachinesAPIError(payload: .init(
            message: "Failed to get a list of all machines in nodes app",
            error: error
        ))
    }

    private func findNodeMachineListFromResponse(_ response: ClientResponse) throws -> NodeMachines {
        try response.content.decode(NodeMachines.self)
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
