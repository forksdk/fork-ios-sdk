//
//  WorkoutConfiguration.swift
//  HealthKitReporter
//
//  Created by Victor on 25.09.20.
//

import HealthKit

@available(iOS 10.0, *)
public struct WorkoutConfiguration: Codable {
    public struct Serialized: Codable {
        public let value: Double
        public let unit: String

        public init(
            value: Double,
            unit: String
        ) {
            self.value = value
            self.unit = unit
        }
    }

    public let activityValue: Int
    public let locationValue: Int
    public let swimmingValue: Int
    public let serialized: Serialized

    public static func make(
        from dictionary: [String: Any]
    ) throws -> WorkoutConfiguration {
        guard
            let activityValue = dictionary["activityValue"] as? Int,
            let locationValue = dictionary["locationValue"] as? Int,
            let swimmingValue = dictionary["swimmingValue"] as? Int,
            let serialized = dictionary["serialized"] as? [String: Any]
        else {
            throw ForkError.invalidValue(
                "Invalid dictionary: \(dictionary)"
            )
        }
        return WorkoutConfiguration(
            activityValue: activityValue,
            locationValue: locationValue,
            swimmingValue: swimmingValue,
            serialized: try Serialized.make(from: serialized)
        )
    }

    public init(
        activityValue: Int,
        locationValue: Int,
        swimmingValue: Int,
        serialized: Serialized
    ) {
        self.activityValue = activityValue
        self.locationValue = locationValue
        self.swimmingValue = swimmingValue
        self.serialized = serialized
    }

    init(workoutConfiguration: HKWorkoutConfiguration) throws {
        self.activityValue = Int(workoutConfiguration.activityType.rawValue)
        self.locationValue = workoutConfiguration.locationType.rawValue
        self.swimmingValue = workoutConfiguration.swimmingLocationType.rawValue
        self.serialized = try workoutConfiguration.serialize()
    }
}
// MARK: - ForkOriginal
@available(iOS 10.0, *)
extension WorkoutConfiguration: ForkOriginal {
    func asOriginal() throws -> HKWorkoutConfiguration {
        let configuration = HKWorkoutConfiguration()
        if let activityType = HKWorkoutActivityType(rawValue: UInt(activityValue)) {
            configuration.activityType = activityType
        }
        if let locationType = HKWorkoutSessionLocationType(rawValue: locationValue) {
            configuration.locationType = locationType
        }
        if let swimmingLocationType = HKWorkoutSwimmingLocationType(rawValue: swimmingValue) {
            configuration.swimmingLocationType = swimmingLocationType
        }
        configuration.lapLength = HKQuantity(
            unit: HKUnit.init(from: serialized.unit),
            doubleValue: serialized.value
        )
        return HKWorkoutConfiguration()
    }
}
// MARK: - Payload
@available(iOS 10.0, *)
extension WorkoutConfiguration.Serialized: ForkPayload {
    public static func make(
        from dictionary: [String: Any]
    ) throws -> WorkoutConfiguration.Serialized {
        guard
            let value = dictionary["value"] as? NSNumber,
            let unit = dictionary["unit"] as? String
        else {
            throw ForkError.invalidValue("Invalid dictionary: \(dictionary)")
        }
        return WorkoutConfiguration.Serialized(
            value: Double(truncating: value),
            unit: unit
        )
    }
}
