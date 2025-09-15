// MaxNodeMachinesReachedHandler.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

internal class MaxNodeMachinesReachedHandler: SeleniumGridNodeMachineAutoscaler {
    let maxNodeMachinesAllowed: Int = 10

    init(logger: Logger, client: any Client) throws {
        try super.init(logger: logger, client: client, cyclePauseDurationSeconds: 0)
    }

    public func reached() async throws -> Bool {
        let totalMachines = try await getTotalNodeMachines()
        let reached = reachedMaxNodeMachines(totalMachines: totalMachines)
        if reached {
            logReachedMaxNodeMachines(totalMachines: totalMachines)
        }
        return reached
    }

    private func getTotalNodeMachines() async throws -> Int {
        try await getListOfAllNodeMachines().count
    }

    private func reachedMaxNodeMachines(totalMachines: Int) -> Bool {
        return totalMachines >= maxNodeMachinesAllowed
    }

    private func logReachedMaxNodeMachines(totalMachines: Int) {
        logger.info(
            "The threshold of \(maxNodeMachinesAllowed) running node machines reached. No additional node machines will be created.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "total_node_machines": .string(String(totalMachines))
            ]
        )
    }
}
