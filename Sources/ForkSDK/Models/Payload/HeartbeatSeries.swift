//
//  HeartbeatSeries.swift
//  HealthKitReporter
//
//  Created by Kachalov, Victor on 12.10.21.
//

import HealthKit

@available(iOS 13.0, *)
public struct HeartbeatSeries: Identifiable, Sample {
    public struct Measurement: Codable {
        public let timeSinceSeriesStart: Double
        public let precededByGap: Bool
        public let done: Bool

        public init(
            timeSinceSeriesStart: Double,
            precededByGap: Bool,
            done: Bool
        ) {
            self.timeSinceSeriesStart = timeSinceSeriesStart
            self.precededByGap = precededByGap
            self.done = done
        }
    }

    public struct Serialized: Codable {
        public let count: Int
        public let measurements: [Measurement]
        public let metadata: ForkMetadata?

        public init(
            count: Int,
            measurements: [Measurement],
            metadata: ForkMetadata?
        ) {
            self.count = count
            self.measurements = measurements
            self.metadata = metadata
        }

        public func copyWith(
            count: Int? = nil,
            measurements: [Measurement]? = nil,
            metadata: ForkMetadata? = nil
        ) -> Serialized {
            return Serialized(
                count: count ?? self.count,
                measurements: measurements ?? self.measurements,
                metadata: metadata ?? self.metadata
            )
        }
    }

    public let uuid: String
    public let identifier: String
    public let startTimestamp: Double
    public let endTimestamp: Double
    public let device: Device?
    public let sourceRevision: SourceRevision
    public let serialized: Serialized
    
    public init(
        identifier: String,
        startTimestamp: Double,
        endTimestamp: Double,
        device: Device?,
        sourceRevision: SourceRevision,
        serialized: Serialized
    ) {
        self.uuid = UUID().uuidString
        self.identifier = identifier
        self.startTimestamp = startTimestamp
        self.endTimestamp = endTimestamp
        self.device = device
        self.sourceRevision = sourceRevision
        self.serialized = serialized
    }

    init(sample: HKHeartbeatSeriesSample, measurements: [Measurement]) {
        self.uuid = sample.uuid.uuidString
        self.identifier = sample.sampleType.identifier
        self.startTimestamp = sample.startDate.timeIntervalSince1970
        self.endTimestamp = sample.endDate.timeIntervalSince1970
        self.device = Device(device: sample.device)
        self.sourceRevision = SourceRevision(sourceRevision: sample.sourceRevision)
        self.serialized = sample.serialize(measurements: measurements)
    }
}
// MARK: - Payload
@available(iOS 13.0, *)
extension HeartbeatSeries: ForkPayload {
    public static func make(from dictionary: [String: Any]) throws -> HeartbeatSeries {
        guard
            let identifier = dictionary["identifier"] as? String,
            let startTimestamp = dictionary["startTimestamp"] as? NSNumber,
            let endTimestamp = dictionary["endTimestamp"] as? NSNumber,
            let sourceRevision = dictionary["sourceRevision"] as? [String: Any],
            let serialized = dictionary["serialized"] as? [String: Any]
        else {
            throw ForkError.invalidValue("Invalid dictionary: \(dictionary)")
        }
        let device = dictionary["device"] as? [String: Any]
        return HeartbeatSeries(
            identifier: identifier,
            startTimestamp: Double(truncating: startTimestamp),
            endTimestamp: Double(truncating: endTimestamp),
            device: device != nil
                ? try Device.make(from: device!)
                : nil,
            sourceRevision: try SourceRevision.make(from: sourceRevision),
            serialized: try Serialized.make(from: serialized)
        )
    }
}
// MARK: - Payload
@available(iOS 13.0, *)
extension HeartbeatSeries.Serialized: ForkPayload {
    public static func make(from dictionary: [String: Any]) throws -> HeartbeatSeries.Serialized {
        guard
            let count = dictionary["count"] as? Int,
            let measurements = dictionary["measurements"] as? [Any]
        else {
            throw ForkError.invalidValue("Invalid dictionary: \(dictionary)")
        }
        let metadata = dictionary["metadata"] as? [String: Any]
        return HeartbeatSeries.Serialized(
            count: count,
            measurements: try HeartbeatSeries.Measurement.collect(from: measurements),
            metadata: metadata?.asMetadata
        )
    }
}
// MARK: - Payload
@available(iOS 13.0, *)
extension HeartbeatSeries.Measurement: ForkPayload {
    public static func make(from dictionary: [String: Any]) throws -> HeartbeatSeries.Measurement {
        guard
            let timeSinceSeriesStart = dictionary["timeSinceSeriesStart"] as? NSNumber,
            let precededByGap = dictionary["precededByGap"] as? Bool,
            let done = dictionary["done"] as? Bool
        else {
            throw ForkError.invalidValue("Invalid dictionary: \(dictionary)")
        }
        return HeartbeatSeries.Measurement(
            timeSinceSeriesStart: Double(truncating: timeSinceSeriesStart),
            precededByGap: precededByGap,
            done: done
        )
    }
    public static func collect(from array: [Any]) throws -> [HeartbeatSeries.Measurement] {
        var measurements = [HeartbeatSeries.Measurement]()
        for element in array {
            if let dictionary = element as? [String: Any] {
                let measurement = try HeartbeatSeries.Measurement.make(from: dictionary)
                measurements.append(measurement)
            }
        }
        return measurements
    }
}
