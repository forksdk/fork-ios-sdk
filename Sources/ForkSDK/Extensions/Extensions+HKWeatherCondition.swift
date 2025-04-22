//
//  File.swift
//
//
//  Created by Aleksandras Gaidamauskas on 15/09/2024.
//

import Foundation
import HealthKit

extension HKWeatherCondition {
    
    var stringRepresentation: String {
        switch self {
        case .none: return ""
            
        case .clear: return "Clear"
            
        case .fair: return "Fair"
            
        case .partlyCloudy: return "Partly Cloudy"
            
        case .mostlyCloudy: return "Mostly Cloudy"
            
        case .cloudy: return "Cloudy"
            
        case .foggy: return "Foggy"
            
        case .haze: return "Haze"
            
        case .windy: return "Wind"
            
        case .blustery: return "Bluster"
            
        case .smoky: return "Smoky"
            
        case .dust: return "Dust"
            
        case .snow: return "Snow"
            
        case .hail: return "Hail"
            
        case .sleet: return "Sleet"
            
        case .freezingDrizzle: return "Freezing Drizzle"
            
        case .freezingRain: return "Freezing Rain"
            
        case .mixedRainAndHail: return "Mixed Rain And Hail"
            
        case .mixedRainAndSnow: return "Mixed Rain And Snow"
            
        case .mixedRainAndSleet: return "Mixed Rain And Sleet"
            
        case .mixedSnowAndSleet: return "Mixed Snow And Sleet"
            
        case .drizzle: return "Drizzle"
            
        case .scatteredShowers: return "ScatteredShowers"
            
        case .showers: return "Showers"
            
        case .thunderstorms: return "Thunderstorms"
            
        case .tropicalStorm: return "Tropical Storm"
            
        case .hurricane: return "Hurricane"
            
        case .tornado: return "Tornado"
        default: return "\(self.rawValue)"
        }
    }
}
