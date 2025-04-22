//
//  ForkPreferredUnit.swift
//
//
//  Created by Aleksandras Gaidamauskas on 30/04/2024.
//

import HealthKit

public struct ForkPreferredUnit: Codable {
    public let identifier: String
    public let unit: String

    init(type: HKQuantityType, unit: HKUnit) {
        self.identifier = type.identifier
        self.unit = unit.unitString
    }

    public init(identifier: String, unit: String) {
        self.identifier = identifier
        self.unit = unit
    }
}

// MARK: - ForkPayload
public extension ForkPreferredUnit {
    static func collect(
        from dictionary: [HKQuantityType : HKUnit]
    ) -> [ForkPreferredUnit] {
        var preferredUnits: [ForkPreferredUnit] = []
        for (key, value) in dictionary {
            let preferredUnit = ForkPreferredUnit(
                type: key,
                unit: value
            )
            preferredUnits.append(preferredUnit)
        }
        return preferredUnits
    }
    static func collect(
        from dictionary: [QuantityType: String]
    ) -> [ForkPreferredUnit] {
        var preferredUnits: [ForkPreferredUnit] = []
        for (key, value) in dictionary {
            if let identifier = key.identifier {
                let preferredUnit = ForkPreferredUnit(
                    identifier: identifier,
                    unit: value
                )
                preferredUnits.append(preferredUnit)
            }
        }
        return preferredUnits
    }
}
// MARK: - Payload
extension ForkPreferredUnit: ForkPayload {
    public static func make(from dictionary: [String: Any]) throws -> ForkPreferredUnit {
        guard
            let identifier = dictionary["identifier"] as? String,
            let unit = dictionary["unit"] as? String
        else {
            throw ForkError.invalidValue("Invalid dictionary: \(dictionary)")
        }
        return ForkPreferredUnit(identifier: identifier, unit: unit)
    }
}
