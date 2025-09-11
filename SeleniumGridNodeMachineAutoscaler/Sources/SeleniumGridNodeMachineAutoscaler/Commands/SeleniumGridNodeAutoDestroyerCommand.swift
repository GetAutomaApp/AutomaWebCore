// SeleniumGridNodeAutoDestroyerCommand.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

enum SeleniumGridNodeAutoDestroyerType: String, Codable {
    case offMachines
    case oldMachines
}

struct SeleniumGridNodeAutoDestroyerCommand: AsyncCommand {
    struct Signature: CommandSignature {
        @Argument(name: "type")
        var type: SeleniumGridNodeAutoDestroyerType.RawValue
    }

    var help: String {
        "Auto destroys fly.io SeleniumGrid Node App machines"
    }

    func run(using context: CommandContext, signature: Signature) async throws {
        let destroyer = try SeleniumGridNodeAutoDestroyer(
            logger: context.application.logger,
            client: context.application.client,
            cyclePauseDurationSeconds: 10
        )
        switch signature.type {
        case "offMachines":
            try await destroyer.autoDestroyAllOffNodeMachines()
        case "oldMachines":
            try await destroyer.autoDestroyAllOldNodeMachines()
        default:
            throw Abort(
                .internalServerError,
                reason: "Invalid type '\(signature.type)'. Expected 'offMachines' or 'oldMachines'"
            )
        }
    }
}
