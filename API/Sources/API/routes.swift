// routes.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

func routes(_ app: Application) throws {
    app.get { _ async in
        "It works!"
    }
}
