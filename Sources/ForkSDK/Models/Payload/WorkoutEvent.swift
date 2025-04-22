//
//  WorkoutEvent.swift
//  HealthKitReporter
//
//  Created by Victor on 25.09.20.
//

import HealthKit

public struct WorkoutEvent: Sample {
    public struct Serialized: Codable {
        public let value: Int
        public let description: String
        public let metadata: ForkMetadata?

        public init(value: Int, description: String, metadata: ForkMetadata?) {
            self.value = value
            self.description = description
            self.metadata = metadata
        }

        public func copyWith(
            value: Int? = nil,
            description: String? = nil,
            metadata: ForkMetadata? = nil
        ) -> Serialized {
            return Serialized(
                value: value ?? self.value,
                description: description ?? self.description,
                metadata: metadata ?? self.metadata
            )
        }
    }

    public let startTimestamp: Double
    public let endTimestamp: Double
    public let duration: Double
    public let serialized: Serialized

    @available(iOS 11.0, *)
    init(workoutEvent: HKWorkoutEvent) throws {
        self.startTimestamp = workoutEvent
            .dateInterval
            .start
            .timeIntervalSince1970
        self.endTimestamp = workoutEvent
            .dateInterval
            .end
            .timeIntervalSince1970
        self.duration = workoutEvent.dateInterval.duration
        self.serialized = try workoutEvent.serialize()
    }

    public init(
        startTimestamp: Double,
        endTimestamp: Double,
        duration: Double,
        serialized: Serialized
    ) {
        self.startTimestamp = startTimestamp
        self.endTimestamp = endTimestamp
        self.duration = duration
        self.serialized = serialized
    }

    public func copyWith(
        startTimestamp: Double? = nil,
        endTimestamp: Double? = nil,
        duration: Double? = nil,
        serialized: Serialized? = nil
    ) -> WorkoutEvent {
        return WorkoutEvent(
            startTimestamp: startTimestamp ?? self.startTimestamp,
            endTimestamp: endTimestamp ?? self.endTimestamp,
            duration: duration ?? self.duration,
            serialized: serialized ?? self.serialized
        )
    }
}
// MARK: - ForkOriginal
extension WorkoutEvent: ForkOriginal {
    func asOriginal() throws -> HKWorkoutEvent {
        guard #available(iOS 11.0, *) else {
            throw ForkError.notAvailable(
                "HKWorkoutEvent DateInterval is not available for the current iOS"
            )
        }
        guard let type = HKWorkoutEventType(rawValue: serialized.value) else {
            throw ForkError.invalidType(
                "WorkoutEvent type: \(serialized.value) could not be formatted"
            )
        }
        return HKWorkoutEvent(
            type: type,
            dateInterval: DateInterval(
                start: startTimestamp.asDate,
                end: endTimestamp.asDate
            ),
            metadata: serialized.metadata?.original
        )
    }
}
// MARK: - Payload
extension WorkoutEvent.Serialized: ForkPayload {
    public static func make(
        from dictionary: [String: Any]
    ) throws ->  WorkoutEvent.Serialized {
        guard
            let value = dictionary["value"] as? Int,
            let description = dictionary["description"] as? String
        else {
            throw ForkError.invalidValue("Invalid dictionary: \(dictionary)")
        }
        let metadata = dictionary["metadata"] as? [String: Any]
        return WorkoutEvent.Serialized(
            value: value,
            description: description,
            metadata: metadata?.asMetadata
        )
    }
}
// MARK: - Payload
extension WorkoutEvent: ForkPayload {
    public static func make(
        from dictionary: [String: Any]
    ) throws -> WorkoutEvent {
        guard
            let startTimestamp = dictionary["startTimestamp"] as? NSNumber,
            let endTimestamp = dictionary["endTimestamp"] as? NSNumber,
            let duration = dictionary["duration"] as? NSNumber,
            let serialized = dictionary["serialized"] as? [String: Any]
        else {
            throw ForkError.invalidValue("Invalid dictionary: \(dictionary)")
        }
        return WorkoutEvent(
            startTimestamp: Double(truncating: startTimestamp),
            endTimestamp: Double(truncating: endTimestamp),
            duration: Double(truncating: duration),
            serialized: try WorkoutEvent.Serialized.make(from: serialized)
        )
    }
}
