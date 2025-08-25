// EnvironmentExtensions.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

public extension Environment {
    static func getOrThrow(_ key: String) throws -> String {
        guard
            let value = get(key)
        else {
            throw Abort(.internalServerError, reason: "Value for key \(key) not found")
        }
        return value
    }
}
