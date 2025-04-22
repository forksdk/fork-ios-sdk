//
//  File.swift
//  
//
//  Created by Aleksandras Gaidamausas on 15/08/2024.
//

import Foundation

struct GpxWorkout {
    let name: String
    let startDate: Date
    let trackpoints: [TrackPoint]
}

struct TrackPoint {
    let longitude: Double
    let latitude: Double
    let elevation: Double
    let timeStamp: Date
    let heartRate: Double
    let cadence: Int
}
