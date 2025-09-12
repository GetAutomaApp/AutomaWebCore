// SeleniumGridNodeAutoOffMachineDestroyer.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

internal class SeleniumGridNodeAutoOffMachineDestroyer: SeleniumGridNodeMachineAutoscaler {
    public func autoDestroyAllOffNodeMachines() async throws {
        try await autoDestroyAllOffNodeMachinesImpl()
    }

    private func autoDestroyAllOffNodeMachinesImpl() async throws {
        try await destroyAllCurrentlyOffNodeMachines()

        try await recursivelyAutoDestroyAllOffNodeMachines()
    }

    private func recursivelyAutoDestroyAllOffNodeMachines() async throws {
        try await sleepBetweenCycle()
        cycleCount += 1
        try await autoDestroyAllOffNodeMachines()
    }

    private func destroyAllCurrentlyOffNodeMachines() async throws {
        logAutoDestroyAllOffNodeMachinesStarted()
        let allMachines = try await getListOfAllNodeMachines()
        try await destroyAllOffNodeMachines(allMachines)
    }

    private func logAutoDestroyAllOffNodeMachinesStarted() {
        logger.info(
            "Auto destroy all off node machines cycle started (cycle: \(cycleCount))",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
            ]
        )
    }

    private func destroyAllOffNodeMachines(_ allMachines: [SeleniumGridNodeAppNodeMachinesFinder
            .NodeMachine]) async throws
    {
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
}
