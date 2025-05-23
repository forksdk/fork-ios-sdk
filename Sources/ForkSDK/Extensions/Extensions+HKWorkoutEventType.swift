//
//  File.swift
//  
//
//  Created by Kachalov, Victor on 04.09.21.
//

import HealthKit

extension HKWorkoutEventType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .pause:
            return "Pause"
        case .resume:
            return "Resume"
        case .lap:
            return "Lap"
        case .marker:
            return "Marker"
        case .motionPaused:
            return "Motion paused"
        case .motionResumed:
            return "Motion Resumed"
        case .segment:
            return "Segment"
        case .pauseOrResumeRequest:
            return "Pause on resume request"
        @unknown default:
            fatalError()
        }
    }
}


extension HKWorkoutSwimmingLocationType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .openWater:
            return "openWater"
        case .pool:
            return "Pool"
        @unknown default:
            return "Unknown"
        }
    }
}
