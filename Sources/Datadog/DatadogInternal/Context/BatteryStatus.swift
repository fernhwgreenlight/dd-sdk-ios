/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation

/// Describe the battery state for mobile devices.
internal struct BatteryStatus {
    enum State: Equatable {
        case unknown
        case unplugged
        case charging
        case full
    }

    /// The charging state of the battery.
    let state: State

    /// The battery power level, range between 0 and 1.
    let level: Float
}
