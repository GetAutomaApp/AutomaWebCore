// SeleniumGridNodeAutoScalerCommand.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

struct SeleniumGridNodeAutoCreatorCommand: AsyncCommand {
    struct Signature: CommandSignature {}

    var help: String {
        "Auto-creates fly.io SeleniumGrid Node App machines"
    }

    func run(using context: CommandContext, signature _: Signature) async throws {
        let autoCreator = try SeleniumGridNodeAutoCreator(
            client: context.application.client,
            logger: context.application.logger,
            cyclePauseDurationSeconds: 10
        )
        try await autoCreator.autoCreate()
    }
}
