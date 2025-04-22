//
//  ForkPayload.swift
//  
//
//  Created by Aleksandras Gaidamauskas on 30/04/2024.
//

import Foundation

public protocol ForkPayload {
    static func make(from dictionary: [String: Any]) throws -> Self
}
