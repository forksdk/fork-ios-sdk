//
//  HKBiologicalSex.swift
//
//
//  Created by Aleksandras Gaidamauskas on 20/04/2024.
//

import Foundation
import HealthKit


extension HKBiologicalSex {
    
    var stringRepresentation: String {
        switch self {
        case .notSet: return "NotSet"
        case .female: return "Female"
        case .male: return "Male"
        case .other: return "Other"
        default: return "\(self.rawValue)"
        }
    }
}
