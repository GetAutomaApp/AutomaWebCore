// APIController.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

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
        let payload = try req.content.decode(APIEndpointPayload.self)
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

public struct APIEndpointPayload: Content {
    let url: URL
    let scrollToBottom: Bool

    init(url: URL, scrollToBottom: Bool = false) {
        self.url = url
        self.scrollToBottom = scrollToBottom
    }

    // configuration options required to be implemented and handled in route handlers when
    // a service that needs to be able to make a request both with a browser (jsRender) and without a browser
    // (jsRender=false),
    //

    // let jsRender: Bool
    // let residentialProxy: Bool
    // let autoCaptchaSolving: Bool

    public enum CodingKeys: String, CodingKey {
        case url
        case scrollToBottom = "scroll_to_bottom"
        // case jsRender = "js_render"
        // case residentialProxy = "residential_proxy"
        // case autoCaptchaSolving = "auto_captcha_solving"
    }
}
