// NodeMachineUpdater.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import AutomaUtilities
import Vapor

internal class NodeMachineUpdater: NodeMachineCreationBase {
    let machineID: MachineIdentifier

    init(
        logger: Logger,
        client: any Client,
        seleniumGridHubBase: String,
        machineID: MachineIdentifier
    ) throws {
        self.machineID = machineID
        try super.init(logger: logger, client: client, seleniumGridHubBase: seleniumGridHubBase)
    }

    public func updateNodeHostURLEnvironmentVariable() async throws {
        logUpdateMachineStarted()
        let updatedConfig = updateMachineConfiguation()

        let response = try await getUpdateNodeMachineResponse(updatedConfig: updatedConfig)
        try handleInvalidUpdateMachineResponse(response: response)

        let updateResponseBody = try getResponseBodyFromUpdateNodeMachineResponse(response)

        logUpdateMachineSuccess(updateResponseBody: updateResponseBody)
    }

    private func logUpdateMachineStarted() {
        logger.info(
            "Updating node machine SE_NODE_HOST url.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "machine_id": .string(machineID)
            ]
        )
    }

    private func updateMachineConfiguation() -> MachinePropertyConfiguration {
        var updatedConfiguration = machineConfiguration
        updatedConfiguration.config.env = [
            "SE_OPTS": "--drain-after-session-count 1",
            "SE_EVENT_BUS_HOST": seleniumGridHubBase,
            "SE_NODE_HOST": "\(machineID).vm.\(seleniumGridNodeBase)"
        ]
        updatedConfiguration.config.skipLaunch = false

        return updatedConfiguration
    }

    private func getUpdateNodeMachineResponse(
        updatedConfig: MachinePropertyConfiguration
    ) async throws -> ClientResponse {
        let uri = getUpdateMachineURI()

        return try await client
            .post(uri) { req in
                req.headers = .init(flyAPIHTTPRequestAuthenticationHeader)
                try req.content.encode(["config": updatedConfig.config])
            }
    }

    private func getUpdateMachineURI() -> URI {
        URI(stringLiteral: "\(payload.nodesAppMachineAPIURL)/\(machineID)")
    }

    private func handleInvalidUpdateMachineResponse(response: ClientResponse) throws {
        if isInvalidHTTPResponseStatus(status: response.status) {
            try handleFlyMachinesAPIError(payload: .init(
                message: "Failed to updated machine node 'SE_NODE_HOST' environment variable to URL of the machine",
                error: decodeErrorFromResponse(response)
            ))
        }
    }

    private func logUpdateMachineSuccess(updateResponseBody: ByteBuffer) {
        logger.info(
            "Updating node 'SE_NODE_HOST' environment variable success. Machine will start automatically.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "machine_identifier": .string(machineID),
                "update_machine_response": .string(String(buffer: updateResponseBody))
            ]
        )
    }

    private func getResponseBodyFromUpdateNodeMachineResponse(_ response: ClientResponse) throws -> ByteBuffer {
        try response
            .unwrapBodyOrThrow(
                errorMessage: "Failed to get update node machine response for machine with ID '\(machineID)'"
            )
    }
}
