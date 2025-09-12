// NodeMachineDeleter.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

// TODO: Use logger.error instead of logger.info in places where errors occur. Create custom errors instead of using internalServerError everywhere.
// add more and better logs

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

    private func getAndValidateDeleteNodeMachineResponse() async throws {
        let response = try await getDeleteNodeMachineResponse()
        try validateDeleteNodeMachineResponseStatus(response: response)
    }

    private func validateDeleteNodeMachineResponseStatus(response: ClientResponse) throws {
        if isInvalidHTTPResponseStatus(status: response.status) {
            try handleInvalidDeleteNodeMachineResponse(response: response)
        }
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

    private func handleInvalidDeleteNodeMachineResponse(response: ClientResponse) throws {
        let error = try decodeErrorFromResponse(response)
        logDeleteNodeMachineFailed(error: error)
        try throwInvalidDeleteNodeMachineResponseError(error: error)
    }

    private func logDeleteNodeMachineFailed(error: FlyAPIError) {
        logger.error(
            "Failed to delete machine.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "error": .string("\(error)"),
                "node_machine_id_to_delete": .string(machineID)
            ]
        )
    }

    private func throwInvalidDeleteNodeMachineResponseError(error: FlyAPIError) throws {
        throw SeleniumGridNodeMachineAutoscalerError.flyMachinesAPIError(error: error)
    }

    private func getDeleteNodeMachineResponse() async throws -> ClientResponse {
        try await client.delete(
            .init(stringLiteral: "\(payload.nodesAppMachineAPIURL)/\(machineID)?force=true"),
            headers: .init(flyAPIHTTPRequestAuthenticationHeader)
        )
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
}
