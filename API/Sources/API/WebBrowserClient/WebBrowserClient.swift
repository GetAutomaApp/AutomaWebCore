// WebBrowserClient.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import AutomaUtilities
import SwiftWebDriver
import Vapor

internal struct WebBrowserClient {
    let logger: Logger
    let payload: APIEndpointPayload
    let seleniumGridHubBase: URL
    let driver: WebDriver<ChromeDriver>

    init(logger: Logger, payload: APIEndpointPayload) async throws {
        self.logger = logger
        self.payload = payload
        seleniumGridHubBase = try URL
            .fromString(payload: .init(string: Environment.getOrThrow("SELENIUM_GRID_HUB_BASE")))
        driver = Self.getWebDriver(seleniumGridHubBase: seleniumGridHubBase, logger: logger)
        try await driver.start()
    }

    private static func getWebDriver(seleniumGridHubBase: URL, logger: Logger) -> WebDriver<ChromeDriver> {
        logGetWebDriverStarted(logger: logger)

        let chromeOption = ChromeOptions(
            args: [
                Args(.headless)
            ]
        )

        return WebDriver(
            driver: ChromeDriver(
                driverURL: seleniumGridHubBase,
                browserObject: chromeOption
            )
        )
    }

    private static func logGetWebDriverStarted(logger: Logger) {
        logger.info(
            "Getting new webdriver instance started.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
            ]
        )
    }

    public func getHTML() async throws -> String {
        try await navigateDriverToURL()
        logger.info(
            "API Endpoint Payload: \(payload).",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
            ]
        )
        if payload.scrollToBottom {
            try await scrollToBottom()
        }
        return try await getActiveWindowOuterHTML()
    }

    private func navigateDriverToURL() async throws {
        logNavigateToURLStarted()
        try await driver.navigateTo(url: payload.url)
        logNavigateToURLSuccess()
    }

    private func logNavigateToURLStarted() {
        logger.info(
            "Navigating WebDriver to URL to get HTML content as string.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "url": .string(payload.url.absoluteString),
            ]
        )
    }

    private func logNavigateToURLSuccess() {
        logger.info(
            "Navigating WebDriver to URL to get HTML content as string success.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "url": .string(payload.url.absoluteString),
            ]
        )
    }

    private func scrollToBottom() async throws {
        logScrollToBottomStarted()
        try await driver.execute("window.scrollBy(0, document.querySelector(\"html\").scrollHeight)")
        logScrollToBottomCompleted()
    }

    private func logScrollToBottomStarted() {
        logger.info(
            "Scrolling to bottom of page document started.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "url": .string(payload.url.absoluteString),
            ]
        )
    }

    private func logScrollToBottomCompleted() {
        logger.info(
            "Scrolling to bottom of page document completed.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "url": .string(payload.url.absoluteString),
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
                    message: "'html' element of URL '\(payload.url.absoluteString)' 'outerHTML' property contains an empty value."
                )
        }
        return outerHTMLString
    }
}
