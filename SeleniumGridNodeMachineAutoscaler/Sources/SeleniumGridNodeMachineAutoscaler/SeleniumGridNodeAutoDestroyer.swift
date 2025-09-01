// SeleniumGridNodeAutoDestroyer.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

internal class SeleniumGridNodeAutoDestroyer: SeleniumGridNodeAppInteractor {
    public func autoDestroyAllOldNodeMachines(cyclePauseDuration: Int) async throws {
        try await autoDestroyAllOldNodeMachines(cycleCount: 1, cyclePauseDuration: cyclePauseDuration)
    }

    public func autoDestroyAllOffNodeMachines(cyclePauseDuration: Int) async throws {
        try await autoDestroyAllOffNodeMachines(cycleCount: 1, cyclePauseDuration: cyclePauseDuration)
    }

    private func autoDestroyAllOldNodeMachines(
        cycleCount: Int,
        cyclePauseDuration: Int
    ) async throws {
        logger.info(
            "Auto destroy all old node machines cycle started (cycle: \(cycleCount))",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
            ]
        )

        let allMachines = try await getListOfAllNodeMachines()
        try await destroyAllOldNodeMachines(allMachines)

        try await Task.sleep(for: .seconds(cyclePauseDuration))
        try await autoDestroyAllOldNodeMachines(
            cycleCount: cycleCount + 1,
            cyclePauseDuration: cyclePauseDuration
        )
    }

    private func autoDestroyAllOffNodeMachines(cycleCount: Int, cyclePauseDuration: Int) async throws {
        logger.info(
            "Auto destroy all off node machines cycle started (cycle: \(cycleCount))",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
            ]
        )

        let allMachines = try await getListOfAllNodeMachines()
        try await destroyAllOffNodeMachines(allMachines)

        try await Task.sleep(for: .seconds(cyclePauseDuration))
        try await autoDestroyAllOffNodeMachines(cycleCount: cycleCount + 1, cyclePauseDuration: cyclePauseDuration)
    }

    private func destroyAllOldNodeMachines(_ allMachines: [NodeMachine]) async throws {
        if allMachines.count == 0 {
            return
        }

        let machinesToStop = allMachines.filter { machine in
            let identifyAsOldAt = machine.createdAt.addingTimeInterval(60 * 60)
            return Date() > identifyAsOldAt
        }

        if machinesToStop.count == 0 {
            logger.info(
                "None of the \(allMachines.count) machines in a considered old. No machines will be destroyed.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                ]
            )
            return
        }

        logger.info(
            "Destroying all old node machines started.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "total_machines_to_destroy": .string(String(machinesToStop.count))
            ]
        )

        for machine in machinesToStop {
            try await deleteNodeMachine(id: machine.id)
        }
    }

    private func destroyAllOffNodeMachines(_ allMachines: [NodeMachine]) async throws {
        if allMachines.count == 0 {
            return
        }

        let machinesToStop = allMachines.filter { machine in
            ["stopped", "suspended"].contains(machine.state)
        }

        if machinesToStop.count == 0 {
            logger.info(
                "None of the \(allMachines.count) machines in a stopped or suspended state. No machines will be destroyed.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                ]
            )
            return
        }

        logger.info(
            "Destroying all off node machines started.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "total_machines_to_destroy": .string(String(machinesToStop.count))
            ]
        )

        for machine in machinesToStop {
            try await deleteNodeMachine(id: machine.id)
        }
    }

    private func deleteNodeMachine(id: String) async throws {
        logger.info(
            "Deleting node machine started.",
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
                "Failed to delete machine.",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "response_content": .string("\(responseContent)"),
                    "node_machine_id_to_delete": .string(id)
                ]
            )
            throw Abort(.internalServerError)
        }

        logger.info(
            "Successfully deleted node machine.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "deletd_node_machine_id": .string(id)
            ]
        )
    }
}
