//
//  Source.swift
//  HealthKitReporter
//
//  Created by Victor on 25.09.20.
//

import HealthKit

public struct Source: Codable {
    public let name: String
    public let bundleIdentifier: String

    init(source: HKSource) {
        self.name = source.name
        self.bundleIdentifier = source.bundleIdentifier
    }

    public init(name: String, bundleIdentifier: String) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
    }

    public func copyWith(
        name: String? = nil,
        bundleIdentifier: String? = nil
    ) -> Source {
        return Source(
            name: name ?? self.name,
            bundleIdentifier: bundleIdentifier ?? self.bundleIdentifier
        )
    }
}
// MARK: - ForkOriginal
extension Source: ForkOriginal {
    func asOriginal() throws -> HKSource {
        return HKSource.default()
    }
}

// MARK: - Payload
extension Source: ForkPayload {
    public static func make(from dictionary: [String: Any]) throws -> Source {
        guard
            let name = dictionary["name"] as? String,
            let bundleIdentifier = dictionary["bundleIdentifier"] as? String
        else {
            throw ForkError.invalidValue("Invalid dictionary: \(dictionary)")
        }
        return Source(name: name, bundleIdentifier: bundleIdentifier)
    }
}
