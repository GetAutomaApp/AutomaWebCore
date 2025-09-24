// WebsiteHTMLGetter.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import AutomaUtilities
import SwiftWebDriver
import Vapor

internal struct WebsiteHTMLGetter {
    let logger: Logger
    let seleniumGridHubBase: URL
    let driver: WebDriver<ChromeDriver>

    init(logger: Logger) async throws {
        self.logger = logger
        seleniumGridHubBase = try URL
            .fromString(payload: .init(string: Environment.getOrThrow("SELENIUM_GRID_HUB_BASE")))
        driver = Self.getWebDriver(seleniumGridHubBase: seleniumGridHubBase)
        try await driver.start()
    }

    private static func getWebDriver(seleniumGridHubBase: URL) -> WebDriver<ChromeDriver> {
        let chromeOption = ChromeOptions(
            args: []
        )

        return WebDriver(
            driver: ChromeDriver(
                driverURL: seleniumGridHubBase,
                browserObject: chromeOption
            )
        )
    }

    public func get(url: URL) async throws -> String {
        try await navigateDriverToURL(url)
        return try await getActiveWindowOuterHTML()
    }

    private func navigateDriverToURL(_ url: URL) async throws {
        logNavigateToURLStarted(url)
        try await driver.navigateTo(url: url)
        logNavigateToURLSuccess(url)
    }

    private func logNavigateToURLStarted(_ url: URL) {
        logger.info(
            "Navigating WebDriver to URL to get HTML content as string.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "url": .string(url.absoluteString),
            ]
        )
    }

    private func logNavigateToURLSuccess(_ url: URL) {
        logger.info(
            "Navigating WebDriver to URL to get HTML content as string success.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "url": .string(url.absoluteString),
            ]
        )
    }

    private func getActiveWindowOuterHTML() async throws -> String {
        let response = try await getActiveWindowOuterHTMLProperty()
        return try unwrapActiveWindowOuterHTMLPropertyResponse(response)
    }

    private func getActiveWindowOuterHTMLProperty() async throws -> PostExecuteResponse {
        try await driver.getProperty(
            element: driver.findElement(.tagName("html")),
            propertyName: "outerHTML"
        )
    }

    private func unwrapActiveWindowOuterHTMLPropertyResponse(_ response: PostExecuteResponse) throws -> String {
        guard let outerHTMLString = response.value?.stringValue
        else {
            throw Abort(.internalServerError)
        }
        return outerHTMLString
    }
}
