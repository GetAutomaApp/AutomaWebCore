// SeleniumGridNodeAutoOldMachineDestroyer.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import AutomaUtilities
import Vapor

internal class SeleniumGridNodeAutoOldMachineDestroyer: SeleniumGridNodeMachineAutoscaler {
    /// Auto-destroy all old node machines on fly.io
    /// - Throws: An error if there was a problem auto-destroying all old node machines
    public func autoDestroyAllOldNodeMachines() async throws {
        try await autoDestroyAllOldNodeMachinesImpl()
    }

    private func autoDestroyAllOldNodeMachinesImpl() async throws {
        try await destroyAllCurrentlyOldNodeMachines()

        try await recursivelyAutoDestroyAllOldNodeMachines()
    }

    private func recursivelyAutoDestroyAllOldNodeMachines() async throws {
        try await sleepBetweenCycle(config: .init(duration: cyclePauseDurationSeconds))
        cycleCount += 1
        try await autoDestroyAllOldNodeMachinesImpl()
    }

    private func destroyAllCurrentlyOldNodeMachines() async throws {
        logAutoDestroyAllOldNodeMachinesStarted()
        let allMachines = try await getListOfAllNodeMachines()
        try await destroyAllOldNodeMachines(allMachines)
    }

    private func logAutoDestroyAllOldNodeMachinesStarted() {
        logger.info(
            "Auto destroy all old node machines cycle started (cycle: \(cycleCount))",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
            ]
        )
    }

    private func destroyAllOldNodeMachines(_ allMachines: [NodeMachine]) async throws {
        if allMachines.isEmpty {
            return
        }

        let nodeMachineExpirationMinutes = try getNodeMachineExpirationMinutes()

        let machinesToStop = allMachines.filter { machine in
            let identifyAsOldAt = machine.createdAt
                .addingTimeInterval(60 * nodeMachineExpirationMinutes)
            return Date() > identifyAsOldAt
        }

        if machinesToStop.isEmpty {
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

    private func getNodeMachineExpirationMinutes() throws -> TimeInterval {
        let nodeMachineExpirationMinutes = try Environment
            .getOrThrow("NODE_MACHINE_EXPIRATION_MINUTES")

        guard let nodeMachineExpirationMinutesDouble = TimeInterval(nodeMachineExpirationMinutes)
        else {
            throw AutomaGenericErrors
                .guardFailed(
                    message: """
                    Could not convert 'NODE_MACHINE_EXPIRATION_MINUTES' of value '\(nodeMachineExpirationMinutes)' to type `TimeInterval`"
                    """
                )
        }
        return nodeMachineExpirationMinutesDouble
    }

    deinit {}
}
