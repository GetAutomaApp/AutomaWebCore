// CycleSleeper.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

internal struct CycleSleeper {
    internal let config: CycleSleeperConfig
    internal let logger: Logger

    internal init(_ config: CycleSleeperConfig, logger: Logger) {
        self.config = config
        self.logger = logger
    }

    internal struct CycleSleeperConfig {
        internal let duration: Int
        internal let startMessage: String? = nil
        internal let completionMessage: String? = nil
    }

    /// Sleep for a cycle
    /// - Throws: An error if `Task.sleep()` failed for some reason
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
