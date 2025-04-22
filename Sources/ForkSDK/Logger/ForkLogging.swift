//
//  ForkLogging.swift
//
//
//  Created by Aleksandras Gaidamauskas on 21/04/2024.
//

import Foundation

public protocol ForkLogging {
    var levels: [ForkLoggerLevel] { get set }

    func configure()
    
    func log(_ message: String, onLevel level: ForkLoggerLevel)
}

extension ForkLogging {
    
    public func configure() {}
    
    public func messageHeader(forLevel level: ForkLoggerLevel) -> String {
        "[\(level.rawValue) \(Date().toFullDateTimeString())]"
    }

    func doesLog(forLevel level: ForkLoggerLevel) -> Bool {
        levels.contains(level)
    }
}
