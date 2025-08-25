// SeleniumGridNodeAutoDestroyer.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

internal class SeleniumGridNodeAutoDestroyer: SeleniumGridNodeAppInteractor {
    let client: any Client
    let logger: Logger

    init(client: any Client, logger: Logger) throws {
        self.client = client
        self.logger = logger
    }

    public func start(cyclePauseDuration: Int) async throws {
        try await autoDestroyAllOffNodeMachines(cyclePauseDuration: cyclePauseDuration)
    }

    private func autoDestroyAllOffNodeMachines(cyclePauseDuration: Int, cycleCount: Int = 1) async throws {
        logger.info(
            "Auto destroy all off node machines cycle started (cycle: \(cycleCount))",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
            ]
        )

        let allMachines = try await getListOfAllNodeMachines()
        try await destroyAllOffNodeMachines(allMachines)

        try await Task.sleep(for: .seconds(cyclePauseDuration))
        try await autoDestroyAllOffNodeMachines(cyclePauseDuration: cyclePauseDuration, cycleCount: cycleCount + 1)
    }

    private func getListOfAllNodeMachines() async throws -> [NodeMachine] {
        logger.info(
            "Getting a list of all machines.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
            ]
        )
        let res = try await client.get(
            .init(stringLiteral: nodesAppMachineAPIURL),
            headers: .init(authHeader)
        )

        if res.status != .ok {
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

        let allMachines = try res.content.decode([NodeMachine].self)

        logger.info(
            "Got list of all machines.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "total_machines": .string(String(allMachines.count))
            ]
        )

        return allMachines
    }

    internal struct NodeMachine: Content {
        let id: String
        let state: String
    }

    private func destroyAllOffNodeMachines(_ allMachines: [NodeMachine]) async throws {
        if allMachines.count == 0 {
            return
        }

        logger.info(
            "Destroying all off node machines started.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
            ]
        )
        for machine in allMachines {
            if ["stopped", "suspended"].contains(machine.state) {
                try await deleteNodeMachine(id: machine.id)
            }
        }
    }

    private func deleteNodeMachine(id: String) async throws {
        logger.info(
            "Deleting off node machine started.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "node_machine_id_to_delete": .string(id)
            ]
        )

        let res = try await client.delete(
            .init(stringLiteral: "\(nodesAppMachineAPIURL)/\(id)?force=true"),
            headers: .init(authHeader)
        )

        if res.status != .ok {
            let responseContent = try res.content.decode([String: String].self)
            logger.info(
                "Failed to delete off machine.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "response_content": .string("\(responseContent)"),
                    "node_machine_id_to_delete": .string(id)
                ]
            )
            throw Abort(.internalServerError)
        }

        logger.info(
            "Successfully deleted off node machine.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "deletd_node_machine_id": .string(id)
            ]
        )
    }
}
