//
//  ForkOriginal.swift
//  
//
//  Created by Aleksandras Gaidamauskas on 30/04/2024.
//

import Foundation

protocol ForkOriginal {
    associatedtype Object: NSObject

    func asOriginal() throws -> Object
}
