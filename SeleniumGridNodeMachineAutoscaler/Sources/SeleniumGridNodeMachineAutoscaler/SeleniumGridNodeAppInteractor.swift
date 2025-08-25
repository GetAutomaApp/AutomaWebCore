// SeleniumGridNodeAppInteractor.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

internal protocol SeleniumGridNodeAppInteractorBase {
    var nodesAppMachineAPIURL: String { get }
    var flyAPIToken: String { get }
    var authHeader: [(String, String)] { get }
}

internal class SeleniumGridNodeAppInteractor: SeleniumGridNodeAppInteractorBase {
    let nodesAppMachineAPIURL: String
    let flyAPIToken: String
    let authHeader: [(String, String)]

    init() throws {
        guard
            let flyAPIURL = try URL(string: Environment.getOrThrow("FLY_API_URL"))
        else {
            throw Abort(.internalServerError)
        }

        nodesAppMachineAPIURL = "\(flyAPIURL.absoluteString)/v1/apps/automa-web-core-seleniumgrid-node/machines"
        flyAPIToken = try Environment.getOrThrow("SELENIUM_GRID_NODE_FLY_APP_API_TOKEN")
        authHeader = [("Authorization", "Bearer \(flyAPIToken)")]
    }
}
