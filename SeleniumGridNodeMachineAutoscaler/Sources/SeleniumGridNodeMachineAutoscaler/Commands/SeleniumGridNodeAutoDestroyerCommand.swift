// SeleniumGridNodeAutoDestroyerCommand.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

internal enum SeleniumGridNodeAutoDestroyerType: String, Codable {
    case offMachines
    case oldMachines
}

internal struct SeleniumGridNodeAutoDestroyerCommand: AsyncCommand {
    internal struct Signature: CommandSignature {
        @Argument(name: "type")
        internal var type: SeleniumGridNodeAutoDestroyerType.RawValue
    }

    internal var help: String {
        "Auto destroys fly.io SeleniumGrid Node App machines"
    }

    /// Run auto-destroyer command
    /// - Throws: An eror if there was a problem destroying machines
    public func run(using context: CommandContext, signature: Signature) async throws {
        let destroyer = try SeleniumGridNodeAutoDestroyer(
            logger: context.application.logger,
            client: context.application.client,
            cyclePauseDurationSeconds: 30
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
