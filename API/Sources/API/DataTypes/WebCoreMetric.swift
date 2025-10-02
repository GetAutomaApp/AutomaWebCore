// WebCoreMetric.swift
// Copyright (c) 2025 GetAutomaApp
// All source code and related assets are the property of GetAutomaApp.
// All rights reserved.

import AutomaUtilities
import Foundation
import Prometheus

internal enum APIMetric {
    public static func getWebsiteHTMLCall(
        websiteUrl: URL,
        jsRender: Bool,
        status: MetricStatus
    ) -> Prometheus.Counter {
        MetricsService.global.makeCounter(
            name: "get_website_html_call",
            labels: [
                "status": status.rawValue,
                "website_url": websiteUrl,
                "js_render": jsRender,
            ]
        )
    }
}
