// NodeMachineDeleter.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

internal class NodeMachineDeleter: SeleniumGridNodeAppInteractor {
    internal let machineID: String

    internal init(logger: Logger, client: any Client, machineID: String) throws {
        self.machineID = machineID
        try super.init(logger: logger, client: client)
    }

    /// Delete node machine using fly.io machines API
    /// - Throws: An error if deletion of machine failed
    public func delete() async throws {
        sendTelemetryDataOnDeleteNodeMachineStarted()
        try await getAndValidateDeleteNodeMachineResponse()
    }

    private func sendTelemetryDataOnDeleteNodeMachineStarted() {
        AutoscalerMetric.deleteSeleniumGridNodeAppFlyMachine(machineID: machineID, status: .start).increment()
        logDeleteNodeMachineStarted()
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

    private func sendTelemetryDataOnDeleteNodeMachineSuccess() {
        logDeleteNodeMachineSuccess()
        AutoscalerMetric.deleteSeleniumGridNodeAppFlyMachine(machineID: machineID, status: .success).increment()
    }

    private func getAndValidateDeleteNodeMachineResponse() async throws {
        do {
            let response = try await getDeleteNodeMachineResponse()
            try validateDeleteNodeMachineResponseStatus(response: response)
        } catch {
            sendTelemetryDataOnGetAndValidateDeleteNodeMachineResponseFail(error: error)
            throw error
        }
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

    private func sendTelemetryDataOnGetAndValidateDeleteNodeMachineResponseFail(error: any Error) {
        logGetAndValidateDeleteNodeMachineResponseFail(error: error)
        AutoscalerMetric.deleteSeleniumGridNodeAppFlyMachine(machineID: machineID, status: .fail).increment()
    }

    private func logGetAndValidateDeleteNodeMachineResponseFail(error: any Error) {
        logger.error(
            "Failed to delete node machine.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "machine_id": .string(machineID),
                "error": .string(error.localizedDescription),
            ]
        )
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

    deinit {}
}
