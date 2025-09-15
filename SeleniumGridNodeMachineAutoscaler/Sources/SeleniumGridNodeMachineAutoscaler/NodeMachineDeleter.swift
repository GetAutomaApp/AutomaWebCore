// NodeMachineDeleter.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

internal class NodeMachineDeleter: SeleniumGridNodeAppInteractor {
    let machineID: String

    init(logger: Logger, client: any Client, machineID: String) throws {
        self.machineID = machineID
        try super.init(logger: logger, client: client)
    }

    public func delete() async throws {
        logDeleteNodeMachineStarted()
        try await getAndValidateDeleteNodeMachineResponse()
        logDeleteNodeMachineSuccess()
    }

    private func logDeleteNodeMachineStarted() {
        logger.info(
            "Deleting node machine started.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "node_machine_id_to_delete": .string(machineID)
            ]
        )
    }

    private func getAndValidateDeleteNodeMachineResponse() async throws {
        let response = try await getDeleteNodeMachineResponse()
        try validateDeleteNodeMachineResponseStatus(response: response)
    }

    private func getDeleteNodeMachineResponse() async throws -> ClientResponse {
        try await client.delete(
            .init(stringLiteral: "\(payload.nodesAppMachineAPIURL)/\(machineID)?force=true"),
            headers: .init(flyAPIHTTPRequestAuthenticationHeader)
        )
    }

    private func validateDeleteNodeMachineResponseStatus(response: ClientResponse) throws {
        if isInvalidHTTPResponseStatus(status: response.status) {
            try handleInvalidDeleteNodeMachineResponse(response: response)
        }
    }

    private func handleInvalidDeleteNodeMachineResponse(response: ClientResponse) throws {
        let error = try decodeErrorFromResponse(response)
        try handleFlyMachinesAPIError(payload: .init(message: "Failed to delete machine", error: error))
    }

    private func logDeleteNodeMachineSuccess() {
        logger.info(
            "Successfully deleted node machine.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "deletd_node_machine_id": .string(machineID)
            ]
        )
    }
}
