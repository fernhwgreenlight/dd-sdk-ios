/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import XCTest
@testable import DatadogSessionReplay

// swiftlint:disable empty_xctest_method
class WriterTests: XCTestCase {
    func testWhenFeatureScopeIsConnected_itWritesRecordsToCore() {
        // TODO: RUMM-2690
        // Implementing this test requires creating mocks for `DatadogContext` (passed in `FeatureScope`),
        // which is yet not possible as we lack separate, shared module to facilitate tests.
    }

    func testWhenFeatureScopeIsNotConnected_itDoesNotWriteRecordsToCore() {
        // TODO: RUMM-2690
        // Implementing this test requires creating mocks for `DatadogContext` (passed in `FeatureScope`),
        // which is yet not possible as we lack separate, shared module to facilitate tests.
    }
}
// swiftlint:enable empty_xctest_method
