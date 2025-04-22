//
//  Extensions+HKWorkoutRoute.swift
//  HealthKitReporter
//
//  Created by Victor Kachalov on 16.04.22.
//

import HealthKit

@available(iOS 11.0, *)
extension HKWorkoutRoute {
    typealias Serialized = WorkoutRoute.Serialized

    func serialize(routes: [WorkoutRoute.Route]) -> Serialized {
        Serialized(
            count: count,
            routes: routes,
            metadata: metadata?.asMetadata
        )
    }
}
