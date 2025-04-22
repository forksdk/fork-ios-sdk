//
//  File.swift
//  
//
//  Created by Aleksandras Gaidamauskas on 17/08/2024.
//

import Foundation

public class ForkConsoleLogger: ForkLogging {
    
    public var levels: [ForkLoggerLevel] = [.info, .debug, .warn, .error]
    
    public init(levels: [ForkLoggerLevel]?) {
        self.levels = levels ?? [.info, .warn, .error]
    }
    
    public init() {
        self.levels = [.info, .warn, .error]
    }

    public func log(_ message: String, onLevel level: ForkLoggerLevel) {
        print("\(messageHeader(forLevel: level)) \(message)")
    }
}
