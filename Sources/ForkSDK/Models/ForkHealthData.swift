//
//  File.swift
//  
//
//  Created by Aleksandras Gaidamauskas on 23/08/2024.
//

import Foundation
import HealthKit
import CoreLocation

public protocol ForkHealthData {}

public struct ForkHealthDataActivitySummary: ForkHealthData {
    let appleMoveTime: Double?
    let appleMoveTimeGoal: Double?
    let appleExerciseTime: Double?
    let appleExerciseTimeGoal: Double?
    let appleStandHours: Double?
    let appleStandHoursGoal: Double?
}

public struct ForkHealthDataCharacteristic: ForkHealthData {
    let characteristic: [ForkCharacteristicTypes: String]
}

public struct ForkHealthDataWorkouts: ForkHealthData {
    let items: [HKWorkout]
}

public struct ForkHealthDataCategorySamples: ForkHealthData {
    let items: [HKCategorySample]
}

public struct ForkHealthDataSamples: ForkHealthData {
    let items: [HKSample]
}

public struct ForkHealthDataQuantitySamples: ForkHealthData {
    let items: [HKQuantitySample]
}

public struct ForkHealthDataDiscreteQuantitySamples: ForkHealthData {
    let items: [HKDiscreteQuantitySample]
}

public struct ForkHealthDataStatistics: ForkHealthData {
    let collection: HKStatisticsCollection
}

public struct ForkHealthDataLLocation: ForkHealthData {
    let items: [CLLocation]
}
