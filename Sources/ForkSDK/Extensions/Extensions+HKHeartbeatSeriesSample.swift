//
//  Extensions+HKHeartbeatSeriesSample.swift
//  HealthKitReporter
//
//  Created by Kachalov, Victor on 12.10.21.
//

import HealthKit

@available(iOS 13.0, *)
extension HKHeartbeatSeriesSample {
    typealias Serialized = HeartbeatSeries.Serialized
    
    func serialize(measurements: [HeartbeatSeries.Measurement]) -> Serialized {
        Serialized(
            count: count,
            measurements: measurements,
            metadata: metadata?.asMetadata
        )
    }
}
