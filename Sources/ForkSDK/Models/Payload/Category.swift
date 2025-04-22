//
//  Category.swift
//  HealthKitReporter
//
//  Created by Victor on 25.09.20.
//

import HealthKit

public struct Category: Identifiable, Sample {
    public struct Serialized: Codable {
        public let value: Int
        public let description: String
        public let detail: String
        public let metadata: ForkMetadata?

        public init(
            value: Int,
            description: String,
            detail: String,
            metadata: ForkMetadata?
        ) {
            self.value = value
            self.description = description
            self.detail = detail
            self.metadata = metadata 
        }

        public func copyWith(
            value: Int? = nil,
            description: String? = nil,
            detail: String? = nil,
            metadata: ForkMetadata? = nil
        ) -> Serialized {
            return Serialized(
                value: value ?? self.value,
                description: description ?? self.description,
                detail: detail ?? self.detail,
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

    init(categorySample: HKCategorySample) throws {
        self.uuid = categorySample.uuid.uuidString
        self.identifier = categorySample.categoryType.identifier
        self.startTimestamp = categorySample.startDate.timeIntervalSince1970
        self.endTimestamp = categorySample.endDate.timeIntervalSince1970
        self.device = Device(device: categorySample.device)
        self.sourceRevision = SourceRevision(sourceRevision: categorySample.sourceRevision)
        self.serialized = try categorySample.serialize()
    }

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

    public func copyWith(
        identifier: String? = nil,
        startTimestamp: Double? = nil,
        endTimestamp: Double? = nil,
        device: Device? = nil,
        sourceRevision: SourceRevision? = nil,
        serialized: Serialized? = nil
    ) -> Category {
        return Category(
            identifier: identifier ?? self.identifier,
            startTimestamp: startTimestamp ?? self.startTimestamp,
            endTimestamp: endTimestamp ?? self.endTimestamp,
            device: device ?? self.device,
            sourceRevision: sourceRevision ?? self.sourceRevision,
            serialized: serialized ?? self.serialized
        )
    }
}
// MARK: - ForkOriginal
extension Category: ForkOriginal {
    func asOriginal() throws -> HKCategorySample {
        guard let type = identifier.objectType?.original as? HKCategoryType else {
            throw ForkError.invalidType(
                "Category type identifier: \(identifier) could not be formatted"
            )
        }
        return HKCategorySample(
            type: type,
            value: serialized.value,
            start: startTimestamp.asDate,
            end: endTimestamp.asDate,
            device: device?.asOriginal(),
            metadata: serialized.metadata?.original
        )
    }
}

// MARK: - Payload
extension Category: ForkPayload {
    public static func make(from dictionary: [String: Any]) throws -> Category {
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
        return Category(
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
    public static func collect(from array: [Any]) throws -> [Category] {
        var results = [Category]()
        for element in array {
            if let dictionary = element as? [String: Any] {
                let serialized = try Category.make(from: dictionary)
                results.append(serialized)
            }
        }
        return results
    }
}
// MARK: - Factory
extension Category {
    public static func collect(results: [HKSample]) -> [Category] {
        var samples = [Category]()
        if let categorySamples = results as? [HKCategorySample] {
            for categorySample in categorySamples {
                do {
                    let sample = try Category(
                        categorySample: categorySample
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
extension Category.Serialized: ForkPayload {
    public static func make(from dictionary: [String: Any]) throws -> Category.Serialized {
        guard
            let value = dictionary["value"] as? Int,
            let description = dictionary["description"] as? String,
            let detail = dictionary["detail"] as? String
        else {
            throw ForkError.invalidValue("Invalid dictionary: \(dictionary)")
        }
        let metadata = dictionary["metadata"] as? [String: Any]
        return Category.Serialized(
            value: value,
            description: description,
            detail: detail,
            metadata: metadata?.asMetadata
        )
    }
}
