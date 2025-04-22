//
//  Electrocardiogram.swift
//  HealthKitReporter
//
//  Created by Victor on 25.09.20.
//

import HealthKit

@available(iOS 14.0, *)
public struct Electrocardiogram: Identifiable, Sample {
    public struct Serialized: Codable {
        public let averageHeartRate: Double?
        public let averageHeartRateUnit: String
        public let samplingFrequency: Double
        public let samplingFrequencyUnit: String
        public let classification: String
        public let symptomsStatus: String
        public let count: Int
        public let voltageMeasurements: [VoltageMeasurement]
        public let metadata: ForkMetadata?

        init(
            averageHeartRate: Double?,
            averageHeartRateUnit: String,
            samplingFrequency: Double,
            samplingFrequencyUnit: String,
            classification: String,
            symptomsStatus: String,
            count: Int,
            voltageMeasurements: [VoltageMeasurement],
            metadata: ForkMetadata?
        ) {
            self.averageHeartRate = averageHeartRate
            self.averageHeartRateUnit = averageHeartRateUnit
            self.samplingFrequency = samplingFrequency
            self.samplingFrequencyUnit = samplingFrequencyUnit
            self.classification = classification
            self.symptomsStatus = symptomsStatus
            self.count = count
            self.voltageMeasurements = voltageMeasurements
            self.metadata = metadata
        }
    }
    public struct VoltageMeasurement: Codable {
        public struct Serialized: Codable {
            public let value: Double
            public let unit: String
        }

        public let serialized: Serialized
        public let timeSinceSampleStart: Double

        init(serialized: Serialized, timeSinceSampleStart: Double) {
            self.serialized = serialized
            self.timeSinceSampleStart = timeSinceSampleStart
        }

        init(voltageMeasurement: HKElectrocardiogram.VoltageMeasurement) throws {
            self.serialized = try voltageMeasurement.serialize()
            self.timeSinceSampleStart = voltageMeasurement.timeSinceSampleStart
        }
    }

    public let uuid: String
    public let identifier: String
    public let startTimestamp: Double
    public let endTimestamp: Double
    public let device: Device?
    public let sourceRevision: SourceRevision
    public let numberOfMeasurements: Int
    public let serialized: Serialized

    init(
        identifier: String,
        startTimestamp: Double,
        endTimestamp: Double,
        device: Device?,
        sourceRevision: SourceRevision,
        numberOfMeasurements: Int,
        serialized: Serialized
    ) {
        self.uuid = UUID().uuidString
        self.identifier = identifier
        self.startTimestamp = startTimestamp
        self.endTimestamp = endTimestamp
        self.device = device
        self.sourceRevision = sourceRevision
        self.numberOfMeasurements = numberOfMeasurements
        self.serialized = serialized
    }

    init(
        electrocardiogram: HKElectrocardiogram,
        voltageMeasurements: [Electrocardiogram.VoltageMeasurement]
    ) throws {
        self.uuid = electrocardiogram.uuid.uuidString
        self.identifier = ElectrocardiogramType
            .electrocardiogramType
            .original?
            .identifier ?? "HKDataTypeIdentifierElectrocardiogram"
        self.startTimestamp = electrocardiogram.startDate.timeIntervalSince1970
        self.endTimestamp = electrocardiogram.endDate.timeIntervalSince1970
        self.device = Device(device: electrocardiogram.device)
        self.numberOfMeasurements = electrocardiogram.numberOfVoltageMeasurements
        self.sourceRevision = SourceRevision(sourceRevision: electrocardiogram.sourceRevision)
        self.serialized = try electrocardiogram.serialize(voltageMeasurements: voltageMeasurements)
    }
}
// MARK: - Payload
@available(iOS 14.0, *)
extension Electrocardiogram.Serialized: ForkPayload {
    public static func make(from dictionary: [String: Any]) throws -> Electrocardiogram.Serialized {
        guard
            let averageHeartRateUnit = dictionary["averageHeartRateUnit"] as? String,
            let samplingFrequency = dictionary["samplingFrequency"] as? NSNumber,
            let samplingFrequencyUnit = dictionary["samplingFrequencyUnit"] as? String,
            let classification = dictionary["classification"] as? String,
            let symptomsStatus = dictionary["symptomsStatus"] as? String,
            let count = dictionary["count"] as? Int
        else {
            throw ForkError.invalidValue("Invalid dictionary: \(dictionary)")
        }
        let averageHeartRate = dictionary["averageHeartRate"] as? NSNumber
        let voltageMeasurements = dictionary["voltageMeasurements"] as? [Any]
        let metadata = dictionary["metadata"] as? [String: Any]
        return Electrocardiogram.Serialized(
            averageHeartRate: averageHeartRate != nil
                ? Double(truncating: averageHeartRate!)
                : nil,
            averageHeartRateUnit: averageHeartRateUnit,
            samplingFrequency: Double(truncating: samplingFrequency),
            samplingFrequencyUnit: samplingFrequencyUnit,
            classification: classification,
            symptomsStatus: symptomsStatus,
            count: count,
            voltageMeasurements: voltageMeasurements != nil
                ? try Electrocardiogram.VoltageMeasurement.collect(from: voltageMeasurements!)
                : [],
            metadata: metadata?.asMetadata
        )
    }
}
// MARK: - Factory
@available(iOS 14.0, *)
extension Electrocardiogram {
    static func collect(results: [HKSample]) -> [Electrocardiogram] {
        var samples = [Electrocardiogram]()
        if let electrocardiograms = results as? [HKElectrocardiogram] {
            for electrocardiogram in electrocardiograms {
                do {
                    let sample = try Electrocardiogram(
                        electrocardiogram: electrocardiogram,
                        voltageMeasurements: []
                    )
                    samples.append(sample)
                } catch {
                    continue
                }
            }
        }
        return samples
    }
}
// MARK: - Payload
@available(iOS 14.0, *)
extension Electrocardiogram: ForkPayload {
    public static func make(from dictionary: [String: Any]) throws -> Electrocardiogram {
        guard
            let identifier = dictionary["identifier"] as? String,
            let startTimestamp = dictionary["startTimestamp"] as? NSNumber,
            let endTimestamp = dictionary["endTimestamp"] as? NSNumber,
            let sourceRevision = dictionary["sourceRevision"] as? [String: Any],
            let numberOfMeasurements = dictionary["numberOfMeasurements"] as? Int,
            let serialized = dictionary["serialized"] as? [String: Any]
        else {
            throw ForkError.invalidValue("Invalid dictionary: \(dictionary)")
        }
        let device = dictionary["device"] as? [String: Any]
        return Electrocardiogram(
            identifier: identifier,
            startTimestamp: Double(truncating: startTimestamp),
            endTimestamp: Double(truncating: endTimestamp),
            device: device != nil
                ? try Device.make(from: device!)
                : nil,
            sourceRevision: try SourceRevision.make(from: sourceRevision),
            numberOfMeasurements: numberOfMeasurements,
            serialized: try Serialized.make(from: serialized)
        )
    }
}
// MARK: - Payload
@available(iOS 14.0, *)
extension Electrocardiogram.VoltageMeasurement: ForkPayload {
    public static func make(from dictionary: [String: Any]) throws -> Electrocardiogram.VoltageMeasurement {
        guard
            let serialized = dictionary["serialized"] as? [String: Any],
            let timeSinceSampleStart = dictionary["timeSinceSampleStart"] as? NSNumber
        else {
            throw ForkError.invalidValue("Invalid dictionary: \(dictionary)")
        }
        return Electrocardiogram.VoltageMeasurement(
            serialized: try Electrocardiogram.VoltageMeasurement.Serialized.make(from: serialized),
            timeSinceSampleStart: Double(truncating: timeSinceSampleStart)
        )
    }
    static func collect(from array: [Any]) throws -> [Electrocardiogram.VoltageMeasurement] {
        var measurements = [Electrocardiogram.VoltageMeasurement]()
        for element in array {
            if let dictionary = element as? [String: Any] {
                let measurement = try Electrocardiogram.VoltageMeasurement.make(from: dictionary)
                measurements.append(measurement)
            }
        }
        return measurements
    }
}
// MARK: - Payload
@available(iOS 14.0, *)
extension Electrocardiogram.VoltageMeasurement.Serialized: ForkPayload {
    public static func make(
        from dictionary: [String: Any]
    ) throws -> Electrocardiogram.VoltageMeasurement.Serialized {
        guard
            let value = dictionary["value"] as? NSNumber,
            let unit = dictionary["unit"] as? String
        else {
            throw ForkError.invalidValue("Invalid dictionary: \(dictionary)")
        }
        return Electrocardiogram.VoltageMeasurement.Serialized(
            value: Double(truncating: value),
            unit: unit
        )
    }
}
