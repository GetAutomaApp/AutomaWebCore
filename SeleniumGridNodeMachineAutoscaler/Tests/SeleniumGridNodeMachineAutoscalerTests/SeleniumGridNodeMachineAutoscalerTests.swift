// SeleniumGridNodeMachineAutoscalerTests.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

@testable import SeleniumGridNodeMachineAutoscaler
import Testing
import VaporTesting

@Suite("App Tests")
internal struct SeleniumGridNodeMachineAutoscalerTests {
    /// Example Test
    @Test("Test Hello World Route")
    public func helloWorld() async throws {
        try await withApp(configure: configure) { app in
            try await app.testing().test(.GET, "hello") { res async in
                #expect(res.status == .ok)
                #expect(res.body.string == "Hello, world!")
            }
        }
    }
}
