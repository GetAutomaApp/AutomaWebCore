// SeleniumGridNodeAutoDestroyer.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

internal class SeleniumGridNodeAutoDestroyer: SeleniumGridNodeMachineAutoscalerBase {
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
