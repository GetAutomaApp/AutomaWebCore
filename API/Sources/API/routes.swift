// routes.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

func routes(_ app: Application) throws {
    app.get { _ async in
        "It works!"
    }

    app.get("get-html") { req async throws -> String in
        let content = try req.content.decode(HTMLGetterPayload.self)
        return try await WebsiteHTMLGetter(logger: req.logger)
            .get(url: URL.fromString(payload: .init(string: content.websiteURL)))
    }
}
