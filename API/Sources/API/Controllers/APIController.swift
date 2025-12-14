// APIController.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import AutomaUtilities
import Vapor

internal struct APIController: RouteCollection {
    public func boot(routes: any RoutesBuilder) throws {
        let twitterRoute = routes.grouped("api")
        twitterRoute.get(use: get)
        twitterRoute.post(use: post)
        twitterRoute.put(use: put)
        twitterRoute.patch(use: patch)
        twitterRoute.delete(use: delete)
    }

    @Sendable
    public func get(req: Request) async throws -> String {
        let payload = try req.content.decode(AutomaWebCoreAPIEndpointPayload.self)
        return try await WebBrowserClient(logger: req.logger, payload: payload).getHTML()
    }

    // Endpoints where implementation becomes required when making any type of request (GET, POST, etc)
    // with a body and headers becomes necessary for the next version of the app
    @Sendable
    public func post(req _: Request) async throws -> String {
        "hello world"
    }

    @Sendable
    public func put(req _: Request) async throws -> String {
        "hello world"
    }

    @Sendable
    public func patch(req _: Request) async throws -> String {
        "hello world"
    }

    @Sendable
    public func delete(req _: Request) async throws -> String {
        "hello world"
    }
}
