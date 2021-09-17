/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Datadog (https://www.datadoghq.com/).
* Copyright 2019-2020 Datadog, Inc.
*/

import XCTest
import Datadog

/// A base class for all E2E test cases.
class E2ETests: XCTestCase {
    /// If enabled, the SDK will not be initialized before each test.
    var skipSDKInitialization = false

    // MARK: - Before & After Each Test

    override func setUp() {
        super.setUp()
        deleteAllSDKData()
        if !skipSDKInitialization {
            initializeSDK()
        }
    }

    override func tearDown() {
        sendAllDataAndDeinitializeSDK()
        super.tearDown()
    }

    // MARK: - Common Monitors

    /// - common performance monitor - measures `Datadog.initialize(...)` performance:
    /// ```apm
    /// $feature = core
    /// $monitor_id = sdk_initialize_performance
    /// $monitor_name = "[RUM] [iOS] Nightly Performance - sdk_initialize: has a high average execution time"
    /// $monitor_query = "avg(last_1d):avg:trace.sdk_initialize{env:instrumentation,resource_name:sdk_initialize,service:com.datadog.ios.nightly} > 0.016"
    /// $monitor_threshold = 0.016
    /// ```

    // MARK: - Measuring Performance with APM

    /// Measures time of execution for given `block` - sends it as a `Span` with a given name.
    func measure(spanName: String, _ block: () -> Void) {
        let start = Date()
        block()
        let stop = Date()

        Global.sharedTracer
            .startRootSpan(operationName: spanName, startTime: start)
            .finish(at: stop)
    }

    // MARK: - SDK Lifecycle

    func initializeSDK(
        trackingConsent: TrackingConsent = .granted,
        configuration: Datadog.Configuration = Datadog.Configuration.builderUsingE2EConfig().build()
    ) {
        Datadog.initialize(
            appContext: .init(),
            trackingConsent: trackingConsent,
            configuration: configuration
        )

        Global.sharedTracer = Tracer.initialize(configuration: .init())
        Global.rum = RUMMonitor.initialize()
    }

    /// Sends all collected data and deinitializes the SDK. It is executed synchronously.
    private func sendAllDataAndDeinitializeSDK() {
        Datadog.flushAndDeinitialize()
    }

    // MARK: - Helpers

    /// Deletes persisted data for all SDK features. Ensures clean start for each test.
    private func deleteAllSDKData() {
        PersistenceHelpers.deleteAllSDKData()
    }
}
