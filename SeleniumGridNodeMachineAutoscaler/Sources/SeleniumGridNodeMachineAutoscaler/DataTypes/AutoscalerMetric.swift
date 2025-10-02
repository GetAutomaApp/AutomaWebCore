// AutoscalerMetric.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import AutomaUtilities
import Foundation
import Prometheus

internal enum AutoscalerMetric {
    public static func deleteSeleniumGridNodeAppFlyMachine(
        machineID _: String,
        status: MetricStatus,
    ) -> Prometheus.Counter {
        MetricsService.global.makeCounter(
            name: "delete_seleniumgrid_node_app_fly_machine_call",
            labels: [
                "machine_id": machineID,
                "status": status.rawValue
            ]
        )
    }

    public static func createSeleniumGridNodeAppFlyMachine(
        status: MetricStatus
    ) -> Prometheus.Counter {
        MetricsService.global.makeCounter(
            name: "create_seleniumgrid_node_app_fly_machine_call",
            labels: [
                "status": status.rawValue
            ]
        )
    }
}
