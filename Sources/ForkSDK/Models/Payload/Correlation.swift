//
//  Correlation.swift
//  HealthKitReporter
//
//  Created by Victor on 25.09.20.
//

import HealthKit

public struct Correlation: Identifiable, Sample {
    public struct Serialized: Codable {
        public let quantitySamples: [Quantity]
        public let categorySamples: [Category]
        public let metadata: ForkMetadata?

        public init(
            quantitySamples: [Quantity],
            categorySamples: [Category],
            metadata: ForkMetadata?
        ) {
            self.quantitySamples = quantitySamples
            self.categorySamples = categorySamples
            self.metadata = metadata
        }

        public func copyWith(
            quantitySamples: [Quantity]? = nil,
            categorySamples: [Category]? = nil,
            metadata: ForkMetadata? = nil
        ) -> Correlation.Serialized {
            return Correlation.Serialized(
                quantitySamples: quantitySamples ?? self.quantitySamples,
                categorySamples: categorySamples ?? self.categorySamples,
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

    init(correlation: HKCorrelation) throws {
        self.sourceRevision = SourceRevision(
            sourceRevision: correlation.sourceRevision
        )
        self.uuid = correlation.uuid.uuidString
        self.identifier = correlation.correlationType.identifier
        self.startTimestamp = correlation.startDate.timeIntervalSince1970
        self.endTimestamp = correlation.endDate.timeIntervalSince1970
        self.device = Device(device: correlation.device)
        self.serialized = try correlation.serialize()
    }

    public init(
        identifier: String,
        startTimestamp: Double,
        endTimestamp: Double,
        device: Device?,
        sourceRevision: SourceRevision,
        serialized: Correlation.Serialized
    ) {
        self.uuid = UUID().uuidString
        self.identifier = identifier
        self.startTimestamp = startTimestamp
        self.endTimestamp = endTimestamp
        self.device = device
        self.sourceRevision = sourceRevision
        self.serialized = serialized
    }

    public func copyWith(
        identifier: String? = nil,
        startTimestamp: Double? = nil,
        endTimestamp: Double? = nil,
        device: Device? = nil,
        sourceRevision: SourceRevision? = nil,
        serialized: Serialized? = nil
    ) -> Correlation {
        return Correlation(
            identifier: identifier ?? self.identifier,
            startTimestamp: startTimestamp ?? self.startTimestamp,
            endTimestamp: endTimestamp ?? self.endTimestamp,
            device: device ?? self.device,
            sourceRevision: sourceRevision ?? self.sourceRevision,
            serialized: serialized ?? self.serialized
        )
    }
}
// MARK: - Factory
extension Correlation {
    public static func collect(
        results: [HKSample]
    ) -> [Correlation] {
        var samples = [Correlation]()
        if let correlations = results as? [HKCorrelation] {
            for correlation in correlations {
                do {
                    let sample = try Correlation(
                        correlation: correlation
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
extension Correlation: ForkPayload {
    public static func make(from dictionary: [String: Any]) throws -> Correlation {
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
        return Correlation(
            identifier: identifier,
            startTimestamp: Double(truncating: startTimestamp),
            endTimestamp: Double(truncating: endTimestamp),
            device: device != nil
                ? try Device.make(from: device!)
                : nil,
            sourceRevision: try SourceRevision.make(from: sourceRevision),
            serialized: try Correlation.Serialized.make(from: serialized)
        )
    }
}
// MARK: - Payload
extension Correlation.Serialized: ForkPayload {
    public static func make(from dictionary: [String: Any]) throws -> Correlation.Serialized {
        guard
            let quantitySamples = dictionary["quantitySamples"] as? [Any],
            let categorySamples = dictionary["categorySamples"] as? [Any]
        else {
            throw ForkError.invalidValue("Invalid dictionary: \(dictionary)")
        }
        let metadata = dictionary["metadata"] as? [String: Any]

        return Correlation.Serialized(
            quantitySamples: try Quantity.collect(from: quantitySamples),
            categorySamples: try Category.collect(from: categorySamples),
            metadata: metadata?.asMetadata
        )
    }
}
// MARK: - ForkOriginal
extension Correlation: ForkOriginal {
    func asOriginal() throws -> HKCorrelation {
        guard let type = identifier.objectType?.original as? HKCorrelationType else {
            throw ForkError.invalidType(
                "Correlation type identifier: \(identifier) could not be formatted"
            )
        }
        var set = Set<HKSample>()
        for element in serialized.categorySamples {
            if let category = try? element.asOriginal() {
                set.insert(category)
            }
        }
        for element in serialized.quantitySamples {
            if let quantity = try? element.asOriginal() {
                set.insert(quantity)
            }
        }
        return HKCorrelation(
            type: type,
            start: startTimestamp.asDate,
            end: endTimestamp.asDate,
            objects: set,
            device: device?.asOriginal(),
            metadata: serialized.metadata?.original
        )
    }
}
