//
//  ForkMetadata.swift
//
//
//  Created by Aleksandras Gaidamauskas on 30/04/2024.
//

import Foundation


import Foundation

public enum ForkMetadata: Codable {
    case string(dictionary: [String: String]?)
    case date(dictionary: [String: Date]?)
    case double(dictionary: [String: Double]?)

    public var original: [String: Any]? {
        switch self {
        case .string(dictionary: let dictionary):
            return dictionary
        case .date(dictionary: let dictionary):
            return dictionary
        case .double(dictionary: let dictionary):
            return dictionary
        }
    }
}
// MARK: - Metadata: ExpressibleByDictionaryLiteral, Equatable
extension ForkMetadata: ExpressibleByDictionaryLiteral, Equatable {
    public typealias Key = String
    public typealias Value = Any

    public init(dictionaryLiteral elements: (Key, Value)...) {
        var dictionary = [String: Any]()
        for pair in elements {
            dictionary[pair.0] = pair.1
        }
        do {
            self = try ForkMetadata.make(from: dictionary)
        } catch {
            self = [:]
        }
    }
}
// MARK: - Metadata: ForkPayload
extension ForkMetadata: ForkPayload {
    public static func make(from dictionary: [String : Any]) throws -> ForkMetadata {
        if let stringDictionary = dictionary as? [String: String] {
            return ForkMetadata.string(dictionary: stringDictionary)
        }
        if let dateDictionary = dictionary as? [String: Date] {
            return ForkMetadata.date(dictionary: dateDictionary)
        }
        if let doubleDictionary = dictionary as? [String: Double] {
            return ForkMetadata.double(dictionary: doubleDictionary)
        }
        throw ForkError.invalidValue("Invalid dictionary: \(dictionary)")
    }
}
