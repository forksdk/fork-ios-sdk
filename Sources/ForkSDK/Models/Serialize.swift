//
//  Serialize.swift
//
//
//  Created by Aleksandras Gaidamauskas on 30/04/2024.
//

import Foundation

protocol Serializable {
    associatedtype Serialized: Codable

    func serialize() throws -> Serialized
}
