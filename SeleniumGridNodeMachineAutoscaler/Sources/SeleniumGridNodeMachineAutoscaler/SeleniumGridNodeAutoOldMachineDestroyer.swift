// SeleniumGridNodeAutoOldMachineDestroyer.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

internal class SeleniumGridNodeAutoOldMachineDestroyer: SeleniumGridNodeMachineAutoscaler {
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

    private func destroyAllOldNodeMachines(_ allMachines: [SeleniumGridNodeAppNodeMachinesFinder
            .NodeMachine]) async throws
    {
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
}
