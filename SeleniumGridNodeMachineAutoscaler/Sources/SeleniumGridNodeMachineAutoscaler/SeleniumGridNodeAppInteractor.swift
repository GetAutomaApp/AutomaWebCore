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
    let logger: Logger
    let client: any Client

    init(logger: Logger, client: any Client) throws {
        guard
            let flyAPIURL = try URL(string: Environment.getOrThrow("FLY_API_URL"))
        else {
            throw Abort(.internalServerError)
        }

        self.logger = logger
        self.client = client
        nodesAppMachineAPIURL = "\(flyAPIURL.absoluteString)/v1/apps/automa-web-core-seleniumgrid-node/machines"
        flyAPIToken = try Environment.getOrThrow("SELENIUM_GRID_NODE_FLY_APP_API_TOKEN")
        authHeader = [("Authorization", "Bearer \(flyAPIToken)")]
    }

    internal struct NodeMachine: Content {
        let id: String
        let state: String
        let createdAt: Date

        public enum CodingKeys: String, CodingKey {
            case id
            case state
            case createdAt = "created_at"
        }
    }

    internal func getListOfAllNodeMachines() async throws -> [NodeMachine] {
        logger.info(
            "Getting a list of all machines.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
            ]
        )
        let res = try await client.get(
            .init(stringLiteral: nodesAppMachineAPIURL),
            headers: .init(authHeader)
        )

        if res.status != .ok {
            let responseContent = try res.content.decode([String: String].self)
            logger.info(
                "Failed to get a list of all machines in nodes app",
                metadata: [
                    "to": .string("\(String(describing: Self.self)).\(#function)"),
                    "response_content": .string("\(responseContent)"),
                ]
            )
            throw Abort(.internalServerError)
        }

        let allMachines = try res.content.decode([NodeMachine].self)

        logger.info(
            "Got list of all machines.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "total_machines": .string(String(allMachines.count))
            ]
        )

        return allMachines
    }
}
