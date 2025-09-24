// HTMLGetterPayload.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Vapor

internal struct HTMLGetterPayload: Content {
    let websiteURL: String

    public enum CodingKeys: String, CodingKey {
        case websiteURL = "website_url"
    }
}
