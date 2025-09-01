// configure.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.asyncCommands.use(SeleniumGridNodeAutoScalerCommand(), as: "autoscaler")
    app.asyncCommands.use(SeleniumGridNodeAutoDestroyerCommand(), as: "autodestroyer")
}
