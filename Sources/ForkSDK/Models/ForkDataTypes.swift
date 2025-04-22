//
//  ForkDataTypes.swift
//  
//
//  Created by Aleksandras Gaidamauskas on 16/04/2024.
//

import Foundation

public enum ForkStoreDataTypes: String {
    case bodyMass // HKUnit.gramUnit(with: .kilo)
    case bodyMassIndex // HKUnit.count()
    case bodyTemperature // HKUnit.degreeCelsius()
    case distanceWalkingRunning // HKUnit.meter()
    case distanceCycling // HKUnit.meter()
    case calories
    case flightsClimbed
}

public enum ForkDataTypes: String, Codable {
    case characteristic
    case characteristicDateOfBirth
    case characteristicBiologicalSex
    case characteristicBloodType
    case characteristicFitzpatrickSkinType
    case characteristicWheelchairUse
    case body
    case workouts
    case workoutRoute
    case workoutSplits
    case activitiesSummary
    case breathing
    case calories
    case distance
    case glucose
    case heart
    case oxygenSaturation
    case vo2Max
    case sleep
    case steps
    case flightsClimbed
    case swimming
    case cycling
    case running
    case walking
    case rowing
    case paddle
    case electrocardiogram
    
    var metatype: ForkNormalizedData.Type {
        switch self {
        case .characteristic: return ForkNormalizedCharacteristicData.self
        case .characteristicDateOfBirth: return ForkNormalizedCharacteristicData.self
        case .characteristicBiologicalSex: return ForkNormalizedCharacteristicData.self
        case .characteristicBloodType: return ForkNormalizedCharacteristicData.self
        case .characteristicFitzpatrickSkinType: return ForkNormalizedCharacteristicData.self
        case .characteristicWheelchairUse: return ForkNormalizedCharacteristicData.self
        case .body: return ForkNormalizedBodyData.self
        case .workouts: return ForkNormalizedWorkoutData.self
        case .workoutRoute: return ForkNormalizedRouteData.self
        case .workoutSplits: return ForkNormalizedWorkoutSplitData.self
        case .activitiesSummary: return ForkNormalizedActivitiesSummaryData.self
        case .breathing: return ForkNormalizedBreathingData.self
        case .calories: return ForkNormalizedCaloriesData.self
        case .distance: return ForkNormalizedDistanceData.self
        case .glucose: return ForkNormalizedGlucoseData.self
        case .heart: return ForkNormalizedHeartData.self
        case .oxygenSaturation: return ForkNormalizedOxygenSaturationData.self
        case .vo2Max: return ForkNormalizedVO2MaxData.self
        case .sleep: return ForkNormalizedSleepData.self
        case .steps: return ForkNormalizedStepsData.self
        case .flightsClimbed: return ForkNormalizedFlightsClimbedData.self
        case .swimming: return ForkNormalizedWorkoutData.self
        case .cycling: return ForkNormalizedWorkoutData.self
        case .running: return ForkNormalizedWorkoutData.self
        case .walking: return ForkNormalizedWorkoutData.self
        case .rowing: return ForkNormalizedWorkoutData.self
        case .paddle: return ForkNormalizedWorkoutData.self
        case .electrocardiogram: return ForkNormalizedECGData.self
        }
    }
}


public enum ForkDataActivityTypes: String, Codable {
    case cycling
    case walking
    case paddle
    case running
    case swimming
}

public enum ForkCharacteristicTypes: String, Codable {
    case ageYears
    case dateOfBirth
    case biologicalSex
    case bloodType
    case skinType
    case weelchairUse
}

public struct ForkQueryFilter: Decodable {
    public var excludeManual: Bool
    public var activities: [ForkDataActivityTypes]?
    public var providers: [ForkDataProvider]?
    public var characteristics: [ForkCharacteristicTypes]?
    
    public init(excludeManual: Bool = false,
                activities: [ForkDataActivityTypes]? = nil,
                providers: [ForkDataProvider]? = nil,
                characteristics: [ForkCharacteristicTypes]? = nil) {
        self.excludeManual = excludeManual
        self.activities = activities
        self.providers = providers
        self.characteristics = characteristics
    }
    
    public init(characteristics: [ForkCharacteristicTypes]) {
        self.excludeManual = false
        self.characteristics = characteristics
    }
}
