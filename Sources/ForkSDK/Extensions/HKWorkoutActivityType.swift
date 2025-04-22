//
//  HKWorkoutActivityType+Descriptions.swift
//  stats
//
//  Created by Aleksandras Gaidamauskas on 2022-09-16.
//

// https://github.com/georgegreenoflondon/HKWorkoutActivityType-Descriptions/blob/master/HKWorkoutActivityType%2BDescriptions.swift

import Foundation
import HealthKit

extension HKWorkoutActivityType {
    
    /*
     Simple mapping of available workout types to a human readable name.
     */
    var name: String {
        switch self {
        case .americanFootball:             return "American Football"
        case .archery:                      return "Archery"
        case .australianFootball:           return "Australian Football"
        case .badminton:                    return "Badminton"
        case .baseball:                     return "Baseball"
        case .basketball:                   return "Basketball"
        case .bowling:                      return "Bowling"
        case .boxing:                       return "Boxing"
        case .climbing:                     return "Climbing"
        case .crossTraining:                return "Cross Training"
        case .curling:                      return "Curling"
        case .cycling:                      return "Cycling"
        case .dance:                        return "Dance"
        case .danceInspiredTraining:        return "Dance Inspired Training"
        case .elliptical:                   return "Elliptical"
        case .equestrianSports:             return "Equestrian Sports"
        case .fencing:                      return "Fencing"
        case .fishing:                      return "Fishing"
        case .functionalStrengthTraining:   return "Functional Strength Training"
        case .golf:                         return "Golf"
        case .gymnastics:                   return "Gymnastics"
        case .handball:                     return "Handball"
        case .hiking:                       return "Hiking"
        case .hockey:                       return "Hockey"
        case .hunting:                      return "Hunting"
        case .lacrosse:                     return "Lacrosse"
        case .martialArts:                  return "Martial Arts"
        case .mindAndBody:                  return "Mind and Body"
        case .mixedMetabolicCardioTraining: return "Mixed Metabolic Cardio Training"
        case .paddleSports:                 return "Paddle Sports"
        case .play:                         return "Play"
        case .preparationAndRecovery:       return "Preparation and Recovery"
        case .racquetball:                  return "Racquetball"
        case .rowing:                       return "Rowing"
        case .rugby:                        return "Rugby"
        case .running:                      return "Running"
        case .sailing:                      return "Sailing"
        case .skatingSports:                return "Skating Sports"
        case .snowSports:                   return "Snow Sports"
        case .soccer:                       return "Soccer"
        case .softball:                     return "Softball"
        case .squash:                       return "Squash"
        case .stairClimbing:                return "Stair Climbing"
        case .surfingSports:                return "Surfing Sports"
        case .swimming:                     return "Swimming"
        case .tableTennis:                  return "Table Tennis"
        case .tennis:                       return "Tennis"
        case .trackAndField:                return "Track and Field"
        case .traditionalStrengthTraining:  return "Traditional Strength Training"
        case .volleyball:                   return "Volleyball"
        case .walking:                      return "Walking"
        case .waterFitness:                 return "Water Fitness"
        case .waterPolo:                    return "Water Polo"
        case .waterSports:                  return "Water Sports"
        case .wrestling:                    return "Wrestling"
        case .yoga:                         return "Yoga"
        
        // iOS 10
        case .barre:                        return "Barre"
        case .coreTraining:                 return "Core Training"
        case .crossCountrySkiing:           return "Cross Country Skiing"
        case .downhillSkiing:               return "Downhill Skiing"
        case .flexibility:                  return "Flexibility"
        case .highIntensityIntervalTraining:    return "High Intensity Interval Training"
        case .jumpRope:                     return "Jump Rope"
        case .kickboxing:                   return "Kickboxing"
        case .pilates:                      return "Pilates"
        case .snowboarding:                 return "Snowboarding"
        case .stairs:                       return "Stairs"
        case .stepTraining:                 return "Step Training"
        case .wheelchairWalkPace:           return "Wheelchair Walk Pace"
        case .wheelchairRunPace:            return "Wheelchair Run Pace"
        
        // iOS 11
        case .taiChi:                       return "Tai Chi"
        case .mixedCardio:                  return "Mixed Cardio"
        case .handCycling:                  return "Hand Cycling"
        
        // iOS 13
        case .discSports:                   return "Disc Sports"
        case .fitnessGaming:                return "Fitness Gaming"
        
        // Catch-all
        default:                            return "Other"
        }
    }
    
    /*
     Additional mapping for common name for activity types where appropriate.
     */
    var commonName: String {
        switch self {
        case .highIntensityIntervalTraining: return "HIIT"
        default: return name
        }
    }
    
    var associatedIcon: String? {
        switch self {
            
        case .americanFootball:     return "figure.american.football"
        case .archery:              return "figure.archery"
        case .badminton:                    return "figure.badminton"
        case .baseball:                     return "figure.baseball"
        case .basketball:                   return "figure.basketball"
        case .bowling:                      return "figure.bowling"
        case .boxing:                       return "figure.boxing"
        case .curling:                      return "figure.curling"
        case .cycling:      return "figure.outdoor.cycle" // figure.indoor.cycle
        case .equestrianSports:             return "figure.equestrian.sports"
        case .fencing:                      return "figure.fencing"
        case .fishing:                      return "figure.fishing"
        case .functionalStrengthTraining:   return "figure.strengthtraining.functional"
        case .golf:                         return "figure.golf"
        case .hiking:       return "figure.hiking"
        case .hockey:       return "figure.hockey"
        case .lacrosse:                     return "figure.lacrosse"
        case .martialArts:                  return "figure.martial.arts"
        case .mixedMetabolicCardioTraining: return "figure.mixed.cardio"
//        case .paddleSports:                 return "🛶"
//        case .rowing:                       return "🛶"
        case .rugby:                        return "figure.rugby"
        case .sailing:                      return "figure.sailing"
        case .skatingSports:                return "figure.skating"
        case .snowSports:                   return "figure.snowboarding"
        case .soccer:                       return "figure.soccer"
        case .softball:                     return "figure.softball"
        
        case .traditionalStrengthTraining:  return "figure.strengthtraining.traditional"
        
        
            
        case .running:      return "figure.run"
        case .climbing:     return "figure.climbing"
        
        
        
            
            ///

        
        case .australianFootball:           return "figure.australian.football"
        case .crossTraining:                return "figure.cross.training"
    
        case .dance:                        return "figure.dance"
        case .danceInspiredTraining:        return "figure.dance"
        case .elliptical:                   return "figure.elliptical"

        case .gymnastics:                   return "figure.gymnastics"
        case .handball:                     return "figure.handball"

        case .hunting:                      return "figure.hunting"
        case .mindAndBody:                  return "figure.mind.and.body"
        case .play:                         return "figure.play"
//        case .preparationAndRecovery:       return "Preparation and Recovery"
        case .racquetball:                  return "figure.racquetball"

        case .squash:                       return "figure.squash"
        case .stairClimbing:                return "figure.stairs"
        case .surfingSports:                return "figure.surfing"
        case .swimming:                     return "figure.pool.swim" // figure.open.water.swim
        case .tableTennis:                  return "figure.table.tennis"
        case .tennis:                       return "figure.tennis"
        case .trackAndField:                return "Track and Field"
        case .volleyball:                   return "figure.volleyball"
        case .walking:                      return "figure.walk"
        case .waterFitness, .waterSports:   return "figure.water.fitness"
        case .waterPolo:                    return "Water Polo"
        case .wrestling:                    return "Wrestling"
        case .yoga :        return "figure.yoga"
            ///
        
        
        
        
            
            // iOS 10
            case .barre:                        return "figure.barre"
        case .coreTraining: return "figure.core.training"
            case .crossCountrySkiing:           return "figure.skiing.crosscountry"
            case .downhillSkiing:               return "figure.skiing.downhill"
            case .flexibility:                  return "figure.flexibility"
            case .highIntensityIntervalTraining:    return "figure.highintensity.intervaltraining"
        case .jumpRope:     return "figure.jumprope"
            case .kickboxing:                   return "figure.kickboxing"
            case .pilates:                      return "figure.pilates"
            case .snowboarding:                 return "figure.snowboarding"
            case .stairs:                       return "figure.stairs"
            case .stepTraining:                 return "figure.step.training"
            case .wheelchairWalkPace:           return "figure.roll.runningpace"
            case .wheelchairRunPace:            return "figure.roll"
            
            // iOS 11
            case .taiChi:                       return "figure.taichi"
            case .mixedCardio:                  return "figure.mixed.cardio"
            case .handCycling:                  return "figure.hand.cycling"
            
            // iOS 13
            case .discSports:                   return "figure.disc.sports"
//            case .fitnessGaming:                return "Fitness Gaming"
        
        // Catch-all
        default:                            return "questionmark"
        }
    }
    
    /*
     Mapping of available activity types to emojis, where an appropriate gender-agnostic emoji is available.
     */
    var associatedEmoji: String? {
        switch self {
        case .americanFootball:             return "🏈"
        case .archery:                      return "🏹"
        case .badminton:                    return "🏸"
        case .baseball:                     return "⚾️"
        case .basketball:                   return "🏀"
        case .bowling:                      return "🎳"
        case .boxing:                       return "🥊"
        case .curling:                      return "🥌"
        case .cycling:                      return "🚲"
        case .equestrianSports:             return "🏇"
        case .fencing:                      return "🤺"
        case .fishing:                      return "🎣"
        case .functionalStrengthTraining:   return "💪"
        case .golf:                         return "⛳️"
        case .hiking:                       return "🥾"
        case .hockey:                       return "🏒"
        case .lacrosse:                     return "🥍"
        case .martialArts:                  return "🥋"
        case .mixedMetabolicCardioTraining: return "❤️"
        case .paddleSports:                 return "🛶"
        case .rowing:                       return "🛶"
        case .rugby:                        return "🏉"
        case .sailing:                      return "⛵️"
        case .skatingSports:                return "⛸"
        case .snowSports:                   return "🛷"
        case .soccer:                       return "⚽️"
        case .softball:                     return "🥎"
        case .tableTennis:                  return "🏓"
        case .tennis:                       return "🎾"
        case .traditionalStrengthTraining:  return "🏋️‍♂️"
        case .volleyball:                   return "🏐"
        case .waterFitness, .waterSports:   return "💧"
        
        // iOS 10
        case .barre:                        return "🥿"
        case .crossCountrySkiing:           return "⛷"
        case .downhillSkiing:               return "⛷"
        case .kickboxing:                   return "🥋"
        case .snowboarding:                 return "🏂"
        
        // iOS 11
        case .mixedCardio:                  return "❤️"
        
        // iOS 13
        case .discSports:                   return "🥏"
        case .fitnessGaming:                return "🎮"
        
        // Catch-all
        default:                            return nil
        }
    }
    
    enum EmojiGender {
        case male
        case female
    }
    
    /*
     Mapping of available activity types to appropriate gender specific emojies.
     
     If a gender neutral symbol is available this simply returns the value of `associatedEmoji`.
     */
    func associatedEmoji(for gender: EmojiGender) -> String? {
        switch self {
        case .climbing:
            switch gender {
            case .female:                   return "🧗‍♀️"
            case .male:                     return "🧗🏻‍♂️"
            }
        case .dance, .danceInspiredTraining:
            switch gender {
            case .female:                   return "💃"
            case .male:                     return "🕺🏿"
            }
        case .gymnastics:
            switch gender {
            case .female:                   return "🤸‍♀️"
            case .male:                     return "🤸‍♂️"
            }
        case .handball:
            switch gender {
            case .female:                   return "🤾‍♀️"
            case .male:                     return "🤾‍♂️"
            }
        case .mindAndBody, .yoga, .flexibility:
            switch gender {
            case .female:                   return "🧘‍♀️"
            case .male:                     return "🧘‍♂️"
            }
        case .preparationAndRecovery:
            switch gender {
            case .female:                   return "🙆‍♀️"
            case .male:                     return "🙆‍♂️"
            }
        case .running:
            switch gender {
            case .female:                   return "🏃‍♀️"
            case .male:                     return "🏃‍♂️"
            }
        case .surfingSports:
            switch gender {
            case .female:                   return "🏄‍♀️"
            case .male:                     return "🏄‍♂️"
            }
        case .swimming:
            switch gender {
            case .female:                   return "🏊‍♀️"
            case .male:                     return "🏊‍♂️"
            }
        case .walking:
            switch gender {
            case .female:                   return "🚶‍♀️"
            case .male:                     return "🚶‍♂️"
            }
        case .waterPolo:
            switch gender {
            case .female:                   return "🤽‍♀️"
            case .male:                     return "🤽‍♂️"
            }
        case .wrestling:
            switch gender {
            case .female:                   return "🤼‍♀️"
            case .male:                     return "🤼‍♂️"
            }

        // Catch-all
        default:                            return associatedEmoji
        }
    }
    
}
