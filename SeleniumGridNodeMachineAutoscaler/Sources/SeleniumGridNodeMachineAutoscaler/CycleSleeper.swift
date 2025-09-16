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
        let startMessage: String? = nil
        let completionMessage: String? = nil
    }

    public func sleep() async throws {
        logSleepBetweenCycleStarted()
        try await Task.sleep(for: .seconds(config.duration))
        logSleepBetweenCycleCompleted()
    }

    private func logSleepBetweenCycleStarted() {
        logger.info(
            Logger
                .Message(stringLiteral: config
                    .startMessage ?? "Pausing for \(config.duration) before next cycle starts."),
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
            ]
        )
    }

    private func logSleepBetweenCycleCompleted() {
        logger.info(
            Logger
                .Message(stringLiteral: config
                    .completionMessage ?? "Pausing for \(config.duration) before completed."),
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
            ]
        )
    }
}
