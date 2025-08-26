// entrypoint.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import Logging
import NIOCore
import NIOPosix
import Vapor

@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)

        let app = try await Application.make(env)

        // This attempts to install NIO as the Swift Concurrency global executor.
        // You can enable it if you'd like to reduce the amount of context switching between NIO and Swift Concurrency.
        // Note: this has caused issues with some libraries that use `.wait()` and cleanly shutting down.
        // If enabled, you should be careful about calling async functions before this point as it can cause assertion
        // failures.
        // let executorTakeoverSuccess =
        // NIOSingletons.unsafeTryInstallSingletonPosixEventLoopGroupAsConcurrencyGlobalExecutor()
        // app.logger.debug("Tried to install SwiftNIO's EventLoopGroup as Swift's global concurrency executor",
        // metadata: ["success": .stringConvertible(executorTakeoverSuccess)])

        do {
            try await configure(app)
            // try await app.execute()

            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    let autoscaler = try SeleniumGridNodeAutoscaler(client: app.client, logger: app.logger)
                    try await autoscaler.autoscale(cyclePauseDuration: 10)
                }

                group.addTask {
                    let autoDestroyer = try SeleniumGridNodeAutoDestroyer(client: app.client, logger: app.logger)
                    try await autoDestroyer.autoDestroyAllOffNodeMachines(cyclePauseDuration: 10)
                }

                group.addTask {
                    let autoDestroyer = try SeleniumGridNodeAutoDestroyer(client: app.client, logger: app.logger)
                    try await autoDestroyer.autoDestroyAllOldNodeMachines(cyclePauseDuration: 10)
                }

                try await group.waitForAll()
            }

        } catch {
            app.logger.report(error: error)
            try? await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
}
