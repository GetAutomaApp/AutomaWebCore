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

    private func destroyAllOffNodeMachines(_ allMachines: NodeMachines) async throws {
        if allMachines.isEmpty {
            return
        }

        let machinesToStop = getAllOffNodeMachines(allMachines)
        let totalMachines = allMachines.count

        if machinesToStop.isEmpty {
            logNoOffMachines(totalMachines: totalMachines)
            return
        }

        logDestroyAllOffMachinesStarted(totalMachines: totalMachines)

        for machine in machinesToStop {
            try await deleteNodeMachine(id: machine.id)
        }
    }

    private func getAllOffNodeMachines(_ machines: NodeMachines) -> NodeMachines {
        machines.filter { machine in
            ["stopped", "suspended"].contains(machine.state)
        }
    }

    private func logNoOffMachines(totalMachines: Int) {
        logger.info(
            "None of the \(totalMachines) machines in a stopped or suspended state. No machines will be destroyed.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
            ]
        )
    }

    private func logDestroyAllOffMachinesStarted(totalMachines: Int) {
        logger.info(
            "Destroying all off node machines started.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "total_machines_to_destroy": .string(String(totalMachines))
            ]
        )
    }

    private func recursivelyAutoDestroyAllOffNodeMachines() async throws {
        try await sleepBetweenCycle(config: .init(duration: cyclePauseDurationSeconds))
        cycleCount += 1
        try await autoDestroyAllOffNodeMachines()
    }
}
