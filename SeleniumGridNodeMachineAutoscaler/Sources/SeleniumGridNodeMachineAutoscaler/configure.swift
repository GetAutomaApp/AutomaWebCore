// configure.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

// configures your application
internal func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.asyncCommands.use(SeleniumGridNodeAutoCreatorCommand(), as: "autocreator")
    app.asyncCommands.use(SeleniumGridNodeAutoDestroyerCommand(), as: "autodestroyer")
}
