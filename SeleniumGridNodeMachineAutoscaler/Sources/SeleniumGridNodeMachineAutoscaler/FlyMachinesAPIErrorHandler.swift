// FlyMachinesAPIErrorHandler.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

internal struct FlyMachinesAPIErrorHandler {
    let payload: FlyMachinesAPIErrorHandlerPayload
    let logger: Logger

    func handle() throws {
        logFlyAPIError()
        try throwFlyMachinesAPIError()
    }

    private func logFlyAPIError() {
        let finalMetadata = getFlyAPIErrorLogFinalMetadata()
        logFlyAPIErrorWithFinalMetadata(finalMetadata: finalMetadata)
    }

    private func getFlyAPIErrorLogFinalMetadata() -> Logger.Metadata {
        let metadataBase = getFlyAPIErrorLogFinalMetadataBase()
        return mergeFlyAPIErrorLogMetadataBaseWithMetadata(base: metadataBase)
    }

    private func getFlyAPIErrorLogFinalMetadataBase() -> Logger.Metadata {
        [
            "to": .string("\(String(describing: Self.self)).\(#function)"),
            "error": .string("\(payload.error)")
        ]
    }

    private func mergeFlyAPIErrorLogMetadataBaseWithMetadata(base: Logger.Metadata) -> Logger
        .Metadata
    {
        payload.metadata.merging(base, uniquingKeysWith: { first, _ in first })
    }

    private func logFlyAPIErrorWithFinalMetadata(finalMetadata: Logger.Metadata) {
        logger.error(
            "\(payload.message).",
            metadata: finalMetadata
        )
    }

    private func throwFlyMachinesAPIError() throws {
        throw SeleniumGridNodeMachineAutoscalerError.flyMachinesAPIError(error: payload.error)
    }
}
