// SeleniumGridNodeAutoDestroyer.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

internal class SeleniumGridNodeAutoDestroyerBase: SeleniumGridNodeAppInteractor {
    let cyclePauseDurationSeconds: Int
    internal var cycleCount: Int = 1

    internal init(logger: Logger, client: any Client, cyclePauseDurationSeconds: Int) throws {
        self.cyclePauseDurationSeconds = cyclePauseDurationSeconds
        try super.init(logger: logger, client: client)
    }

    internal func sleepBetweenCycle() async throws {
        logSleepBetweenCycleStarted()
        try await Task.sleep(for: .seconds(cyclePauseDurationSeconds))
    }

    private func logSleepBetweenCycleStarted() {
        logger.info(
            "Pausing for \(cyclePauseDurationSeconds) before next cycle starts.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
            ]
        )
    }

    internal func deleteNodeMachine(id: String) async throws {
        try await NodeMachineDeleter(logger: logger, client: client, machineID: id).delete()
    }
}

internal class SeleniumGridNodeAutoDestroyer: SeleniumGridNodeAutoDestroyerBase {
    public func autoDestroyAllOldNodeMachines() async throws {
        try await SeleniumGridNodeAutoOldMachineDestroyer(
            logger: logger,
            client: client,
            cyclePauseDurationSeconds: cyclePauseDurationSeconds
        ).autoDestroyAllOldNodeMachines()
    }

    public func autoDestroyAllOffNodeMachines() async throws {
        try await SeleniumGridNodeAutoOffMachineDestroyer(
            logger: logger,
            client: client,
            cyclePauseDurationSeconds: cyclePauseDurationSeconds
        ).autoDestroyAllOffNodeMachines()
    }
}
