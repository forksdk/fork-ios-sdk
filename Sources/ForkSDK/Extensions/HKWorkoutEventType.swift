//
//  HKWorkoutEventType.swift
//  
//
//  Created by Aleksandras Gaidamauskas on 20/04/2024.
//

import Foundation
import HealthKit


extension HKWorkoutEventType {
    
    var stringRepresentation: String {
        switch self {
        case .pause: return "Pause"
        case .resume: return "Resume"
        case .motionPaused: return "Motion Paused"
        case .motionResumed: return "Motion Resumed"
        case .pauseOrResumeRequest: return "Pause Or Resume Request"
        case .lap: return "Lap"
        case .segment: return "Segment"
        case .marker: return "Marker"
        default: return "\(self.rawValue)"
        }
    }
}
