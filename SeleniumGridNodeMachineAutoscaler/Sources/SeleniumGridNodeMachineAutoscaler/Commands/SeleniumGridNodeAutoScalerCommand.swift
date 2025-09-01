// SeleniumGridNodeAutoScalerCommand.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

struct SeleniumGridNodeAutoScalerCommand: AsyncCommand {
    struct Signature: CommandSignature {}

    var help: String {
        "Autoscales fly.io SeleniumGrid Node App machines"
    }

    func run(using context: CommandContext, signature _: Signature) async throws {
        let autoscaler = try SeleniumGridNodeAutoscaler(
            client: context.application.client,
            logger: context.application.logger
        )
        try await autoscaler.autoscale(cyclePauseDuration: 10)
    }
}
