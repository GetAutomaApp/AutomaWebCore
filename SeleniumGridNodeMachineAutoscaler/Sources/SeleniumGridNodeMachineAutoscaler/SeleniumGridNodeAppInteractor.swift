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
            let urlString = Environment.get("FLY_API_URL"),
            let flyAPIURL = URL(string: urlString)
        else {
            throw Abort(.internalServerError)
        }
        nodesAppMachineAPIURL = "\(flyAPIURL.absoluteString)/v1/apps/automa-web-core-seleniumgrid-node/machines"

        guard
            let flyAPIToken = Environment.get("SELENIUM_GRID_NODE_FLY_APP_API_TOKEN")
        else {
            throw Abort(.internalServerError)
        }
        self.flyAPIToken = flyAPIToken

        authHeader = [("Authorization", "Bearer \(flyAPIToken)")]
    }
}
