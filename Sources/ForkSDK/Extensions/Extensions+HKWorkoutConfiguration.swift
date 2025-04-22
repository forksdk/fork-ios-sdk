//
//  Extensions+HKWorkoutConfiguration.swift
//  HealthKitReporter
//
//  Created by Victor on 25.09.20.
//

import HealthKit

@available(iOS 10.0, *)
extension HKWorkoutConfiguration: Serializable {
    typealias Serialized = WorkoutConfiguration.Serialized

    func serialize() throws -> Serialized {
        let unit = HKUnit.meter()
        guard let value = lapLength?.doubleValue(for: unit) else {
            throw ForkError.invalidValue("Value for HKWorkoutConfiguration is invalid")
        }
        return Serialized(
            value: value,
            unit: unit.unitString
        )
    }
}
