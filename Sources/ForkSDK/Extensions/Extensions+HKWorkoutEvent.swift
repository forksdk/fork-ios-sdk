//
//  Extensions+HKWorkoutEvent.swift
//  HealthKitReporter
//
//  Created by Victor on 25.09.20.
//

import HealthKit

extension HKWorkoutEvent: Serializable {
    typealias Serialized = WorkoutEvent.Serialized

    func serialize() throws -> Serialized {
        if #available(iOS 10.0, *) {
            return Serialized(
                value: type.rawValue,
                description: type.description,
                metadata: metadata?.asMetadata
            )
        } else {
            throw ForkError.notAvailable(
                "Metadata is not available for the current iOS"
            )
        }
    }
}
