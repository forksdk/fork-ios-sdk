//
//  ForkBackgroundDeliveriesLogger.swift
//  
//
//  Created by Aleksandras Gaidamauskas on 22/04/2024.
//

import Foundation


public protocol ForkBackgroundDeliveriesLogger {
    func onBackgroundLog(log: String)
    
}
