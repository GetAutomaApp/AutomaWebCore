// SeleniumGridNodeMachineAutoscaler.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

internal class SeleniumGridNodeMachineAutoscalerBase: SeleniumGridNodeAppInteractor {
    internal let cyclePauseDurationSeconds: Int
    internal var cycleCount: Int = 1

    internal init(logger: Logger, client: any Client, cyclePauseDurationSeconds: Int) throws {
        self.cyclePauseDurationSeconds = cyclePauseDurationSeconds
        try super.init(logger: logger, client: client)
    }

    deinit {}
}

internal class SeleniumGridNodeMachineAutoscaler: SeleniumGridNodeMachineAutoscalerBase {
    internal func deleteNodeMachine(id: String) async throws {
        try await NodeMachineDeleter(logger: logger, client: client, machineID: id).delete()
    }

    deinit {}
}
