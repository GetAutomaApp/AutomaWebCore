// CycleSleeper.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

internal struct CycleSleeper {
    let config: CycleSleeperConfig
    let logger: Logger

    init(_ config: CycleSleeperConfig, logger: Logger) {
        self.config = config
        self.logger = logger
    }

    internal struct CycleSleeperConfig {
        let duration: Int
        let message: String? = nil
    }

    public func sleep() async throws {
        logSleepBetweenCycleStarted()
        try await Task.sleep(for: .seconds(config.duration))
    }

    private func logSleepBetweenCycleStarted() {
        logger.info(
            Logger.Message(stringLiteral: config.message ?? "Pausing for \(config.duration) before next cycle starts."),
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
            ]
        )
    }
}
