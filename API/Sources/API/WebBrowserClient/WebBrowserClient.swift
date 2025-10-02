// WebBrowserClient.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import AutomaUtilities
import SwiftWebDriver
import Vapor

// TODO: update Autoscaler NodeMachineDeleter and NodeMachineCreator to send a custom error log message on every
// location where an error could be thrown, instead of wrapping multiple try statements with one block.

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
        sendTelemetryDataOnGetHTMLStarted()
        try await navigateDriverToURL()
        if payload.scrollToBottom {
            try await scrollDriverWindowToBottom()
        }
        let html = try await getActiveWindowOuterHTML()
        sendTelemetryDataOnGetHTMLSuccess()
        return html
    }

    private func sendTelemetryDataOnGetHTMLStarted() {
        APIMetric.getWebsiteHTMLCall(websiteUrl: payload.url, jsRender: true, status: .start).increment()
        logGetHTMLStarted()
    }

    private func logGetHTMLStarted() {
        logger.info(
            "Getting HTML of a website started.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "api_payload": .string(String(reflecting: payload))
            ]
        )
    }

    private func navigateDriverToURL() async throws {
        logNavigateToURLStarted()
        do {
            try await driver.navigateTo(url: payload.url)
        } catch {
            sendTelemetryDataOnNavigateDriverToURLFail(error: error)
        }
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

    private func sendTelemetryDataOnNavigateDriverToURLFail(error: any Error) {
        sendTelemetryDataOnGetHTMLFail(
            reason: "Navigating web driver to URL failed.",
            error: error
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

    private func scrollDriverWindowToBottom() async throws {
        logScrollDriverWindowToBottomStarted()
        do {
            try await driver.execute("window.scrollBy(0, document.querySelector(\"html\").scrollHeight)")
        } catch {
            sendTelemetryDataOnScrollDriverWindowToBottomFail(error: error)
        }
        logScrollDriverWindowToBottomCompleted()
    }

    private func logScrollDriverWindowToBottomStarted() {
        logger.info(
            "Scrolling to bottom of page document started.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "url": .string(payload.url.absoluteString),
            ]
        )
    }

    private func sendTelemetryDataOnScrollDriverWindowToBottomFail(error: any Error) {
        sendTelemetryDataOnGetHTMLFail(reason: "Failed to scroll driver window to bottom.", error: error)
    }

    private func logScrollDriverWindowToBottomCompleted() {
        logger.info(
            "Scrolling to bottom of page document completed.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "url": .string(payload.url.absoluteString),
            ]
        )
    }

    private func getActiveWindowOuterHTML() async throws -> String {
        let response = try await getActiveDriverWindowOuterHTMLProperty()
        return try unwrapDriverActiveWindowOuterHTMLPropertyResponse(response)
    }

    private func getActiveDriverWindowOuterHTMLProperty() async throws -> PostExecuteResponse {
        do {
            return try await driver.getProperty(
                element: driver.findElement(.tagName("html")),
                propertyName: "outerHTML"
            )
        } catch {
            sendTelemetryDataOnGetDriverWindowOuterHTMLPropertyFailed(error: error)
            // TODO: refactor throwing direct error to custom `SeleniumGridNodeMachineAutoscalerError`
            throw error
        }
    }

    private func sendTelemetryDataOnGetDriverWindowOuterHTMLPropertyFailed(error: any Error) {
        sendTelemetryDataOnGetHTMLFail(
            reason: "Failed to get 'outerHTML' property on <html> tag",
            error: error
        )
    }

    private func unwrapDriverActiveWindowOuterHTMLPropertyResponse(_ response: PostExecuteResponse) throws -> String {
        guard let outerHTMLString = response.value?.stringValue
        else {
            let reason = """
            'html' element of URL '\(payload.url.absoluteString)' 'outerHTML' property contains an empty value.
            """
            let error = AutomaGenericErrors.notFound(
                message: reason
            )
            sendTelemetryDataOnGetHTMLFail(reason: reason, error: error)
            throw error
        }
        return outerHTMLString
    }

    private func sendTelemetryDataOnGetHTMLSuccess() {
        APIMetric.getWebsiteHTMLCall(websiteUrl: payload.url, jsRender: true, status: .success).increment()
        logGetHTMLSuccess()
    }

    private func logGetHTMLSuccess() {
        logger.info(
            "Successfully scraped HTML from website.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "website_url": .string(payload.url.absoluteString)
            ]
        )
    }

    private func sendTelemetryDataOnGetHTMLFail(reason: String, error: any Error) {
        APIMetric.getWebsiteHTMLCall(websiteUrl: payload.url, jsRender: true, status: .fail).increment()
        logGetHTMLFail(reason: reason, error: error)
    }

    private func logGetHTMLFail(reason: String, error: any Error) {
        logger.error(
            "Failed to get website HTML.",
            metadata: [
                "to": .string("\(String(describing: Self.self)).\(#function)"),
                "reason": .string(reason),
                "error": .string(error.localizedDescription),
                "payload": .string(String(describing: payload))
            ]
        )
    }
}
