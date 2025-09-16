// SeleniumGridNodeAutoDestroyer.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

internal class SeleniumGridNodeAutoDestroyer: SeleniumGridNodeMachineAutoscalerBase {
    /// Auto-destroy all old node machines in Selenium Grid Node app hosted on fly.io
    /// - Throws: An error if auto-destroying all old node machines failed
    public func autoDestroyAllOldNodeMachines() async throws {
        try await SeleniumGridNodeAutoOldMachineDestroyer(
            logger: logger,
            client: client,
            cyclePauseDurationSeconds: cyclePauseDurationSeconds
        ).autoDestroyAllOldNodeMachines()
    }

    /// Auto-destroy all off node machines in Selenium Grid Node app hosted on fly.io
    /// - Throws: An error if auto-destroying all off node machines failed
    public func autoDestroyAllOffNodeMachines() async throws {
        try await SeleniumGridNodeAutoOffMachineDestroyer(
            logger: logger,
            client: client,
            cyclePauseDurationSeconds: cyclePauseDurationSeconds
        ).autoDestroyAllOffNodeMachines()
    }

    deinit {}
}
