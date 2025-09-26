// WebsiteHTMLGetter.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import AutomaUtilities
import SwiftWebDriver
import Vapor

// TODO: scroll down the page to load all javascript before getting content, some websites (especially blogs/articles)
// get the article content in chunks to have better performance and reduce web scraping success attempts

internal struct WebsiteHTMLGetter {
    let logger: Logger
    let url: URL
    let seleniumGridHubBase: URL
    let driver: WebDriver<ChromeDriver>

    init(logger: Logger, url: URL) async throws {
        self.logger = logger
        self.url = url
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

    public func get() async throws -> String {
        try await navigateDriverToURL()
        return try await getActiveWindowOuterHTML()
    }

    private func navigateDriverToURL() async throws {
        logNavigateToURLStarted()
        try await driver.navigateTo(url: url)
        logNavigateToURLSuccess()
    }

    private func logNavigateToURLStarted() {
        logger.info(
            "Navigating WebDriver to URL to get HTML content as string.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "url": .string(url.absoluteString),
            ]
        )
    }

    private func logNavigateToURLSuccess() {
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
            throw AutomaGenericErrors
                .notFound(
                    message: "'html' element of URL '\(url.absoluteString)' 'outerHTML' property contains an empty value."
                )
        }
        return outerHTMLString
    }
}
