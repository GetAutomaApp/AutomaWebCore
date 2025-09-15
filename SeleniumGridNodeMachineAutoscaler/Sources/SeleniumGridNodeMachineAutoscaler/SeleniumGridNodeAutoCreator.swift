// SeleniumGridNodeAutoCreator.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import AutomaUtilities
import Vapor

// TODO:
// - [ ] add more logs
// - [ ] better error handling

internal protocol SeleniumGridInteractor {
    var client: any Client { get }
    var logger: Logger { get }
    var seleniumGridHubBase: String { get }
}

internal class SeleniumGridNodeAutoCreator: SeleniumGridNodeMachineAutoscaler, SeleniumGridInteractor {
    let seleniumGridHubBase: String
    init(client: any Client, logger: Logger, cyclePauseDurationSeconds: Int) throws {
        seleniumGridHubBase = try Environment.getOrThrow("SELENIUM_GRID_HUB_BASE")
        try super.init(logger: logger, client: client, cyclePauseDurationSeconds: cyclePauseDurationSeconds)
    }

    public func autoCreateNodeMachines() async throws {
        try await autoCreateNodeMachinesImpl()
    }

    private func autoCreateNodeMachinesImpl() async throws {
        try await autoCreateNodeMachinesBasedOnSessionsInQueue()
        try await recursivelyAutoCreateNodeMachines()
    }

    private func autoCreateNodeMachinesBasedOnSessionsInQueue() async throws {
        logAutoCreateNodeMachinesStarted()
        try await handleMaxNodeMachinesReached()

        let totalSessionQueueRequests = try await getTotalSessionQueueRequests()
        try await createNodeMachines(totalSessionsInQueue: totalSessionQueueRequests)
    }

    private func logAutoCreateNodeMachinesStarted() {
        logger.info(
            "Node auto-creator cycle started (cycle: \(cycleCount)).",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)")
            ]
        )
    }

    private func handleMaxNodeMachinesReached() async throws {
        if try await MaxNodeMachinesReachedHandler(logger: logger, client: client)
            .reached()
        {
            try await recursivelyAutoCreateNodeMachines()
        }
    }

    private func recursivelyAutoCreateNodeMachines() async throws {
        try await sleepBetweenCycle(config: .init(duration: cyclePauseDurationSeconds))
        cycleCount += 1
        try await autoCreateNodeMachinesImpl()
    }

    private func getTotalSessionQueueRequests() async throws -> Int {
        try await SeleniumGridSessionQueueRequestsHandler(
            client: client,
            logger: logger,
            seleniumGridHubBase: seleniumGridHubBase
        ).getTotalRequests()
    }

    private func createNodeMachines(totalSessionsInQueue: Int) async throws {
        if totalSessionsInQueue > 0 {
            logFoundPendingSessionsInQueue(totalSessions: totalSessionsInQueue)
            try await createNodeMachines(amount: totalSessionsInQueue)
        }
    }

    private func logFoundPendingSessionsInQueue(totalSessions: Int) {
        logger.info(
            "Found a total of \(totalSessions) pending sessions in queue.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
            ]
        )
    }

    private func createNodeMachines(amount: Int) async throws {
        for _ in 1 ... amount {
            try await createNodeMachine()
        }
    }

    private func createNodeMachine() async throws {
        try await NodeMachineCreator(logger: logger, client: client, seleniumGridHubBase: seleniumGridHubBase).create()
    }
}
