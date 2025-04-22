//
//  ForkData.swift
//
//
//  Created by Aleksandras Gaidamauskas on 18/04/2024.
//

import Foundation

public protocol ForkNormalizedData: Codable {
    var date: String? { get }
//    var provider: ForkDataProvider? { get }
    var source: String? { get }
    // var dataType: String? { get }
    var dataType: ForkDataTypes { get }
    
    func getData() -> Data?
}


public class ForkNormalizedCharacteristicData: ForkNormalizedData, Codable {

    
    public let dataType: ForkDataTypes
    public let date: String?
    public let source: String?
    public let value: String?
    
    public func getData() -> Data? {
        let encoder = JSONEncoder()
        let encoderData = try? encoder.encode(self)
        return encoderData
    }
}

public class ForkNormalizedECGData: ForkNormalizedData, Codable {
    public let frequency: Double?
    public let avgHR: Int?
    public let classification: String?
    public let lead: String?
    public let timeStart: String?
    public let timeEnd: String?
    public let timezoneOffset: Int?
    public let unit: String?
    public let samples: [Double]?

    public let date: String?
    public let source: String?
    public let dataType: ForkDataTypes
    
    public func getData() -> Data? {
        let encoder = JSONEncoder()
        let encoderData = try? encoder.encode(self)
        return encoderData
    }
    
//    enum CodingKeys: CodingKey {
//        case frequency
//        case avgHR
//        case classification
//        case lead
//        case timeStart
//        case timeEnd
//        case timezoneOffset
//        case unit
//        case samples
//        
//        case date
//        case source
//        case dataType
//    }
//    
//    public required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.frequency = try container.decodeIfPresent(Double.self, forKey: .frequency)
//        self.avgHR = try container.decodeIfPresent(Int.self, forKey: .avgHR)
//        self.classification = try container.decodeIfPresent(String.self, forKey: .classification)
//        self.lead = try container.decodeIfPresent(String.self, forKey: .lead)
//        self.timeStart = try container.decodeIfPresent(String.self, forKey: .timeStart)
//        self.timeEnd = try container.decodeIfPresent(String.self, forKey: .timeEnd)
//        self.timezoneOffset = try container.decodeIfPresent(Int.self, forKey: .timezoneOffset)
//        self.unit = try container.decodeIfPresent(String.self, forKey: .unit)
//        self.samples = try container.decodeIfPresent([Double].self, forKey: .samples)
//        
//        self.date = try container.decodeIfPresent(String.self, forKey: .date)
//        self.source = try container.decodeIfPresent(String.self, forKey: .source)
//        self.dataType = try container.decodeIfPresent(ForkDataTypes.self, forKey: .dataType)!
//    }
//    
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(frequency, forKey: .frequency)
//        try container.encode(avgHR, forKey: .avgHR)
//        try container.encode(classification, forKey: .classification)
//        try container.encode(lead, forKey: .lead)
//        try container.encode(timeStart, forKey: .timeStart)
//        try container.encode(timeEnd, forKey: .timeEnd)
//        try container.encode(timezoneOffset, forKey: .timezoneOffset)
//        try container.encode(unit, forKey: .unit)
//        try container.encode(samples, forKey: .samples)
//        
//        try container.encode(date, forKey: .date)
//        try container.encode(source, forKey: .source)
//        try container.encode(dataType, forKey: .dataType)
//    }
}

//public struct ForkNormalizedHeartData: ForkNormalizedData {
//    public let date: String?
//    public let source: String?
//    public let dataType: ForkDataTypes
//
//    public let restingHeartRate: Double?
//    public let minHeartRate: Double?
//    public let avgHeartRate: Double?
//    public let maxHeartRate: Double?
//    public let heartRateSamples: [ForkNormalizedHeartData.Sample]?
//    public let heartRateVariability: ForkNormalizedHeartData.Variability?
//    public let intradayHRV: [ForkNormalizedHeartData.IntradayHrv]?
//
//    public struct Sample: Codable {
//        public let time: String
//        public let value: Double?
//    }
//    public struct Variability: Codable {
//        public let dayHRV: Double?
//        public let sleepHRV: Double?
//    }
//    public struct IntradayHrv: Codable {
//        public let time: String
//        public let value: ForkNormalizedHeartData.IntradayHrv.Value?
//        public struct Value: Codable {
//            public let rmssd: Double?
//            public let coverage: Double?
//            public let hf: Double?
//            public let lf: Double?
//        }
//    }
//}

public struct ForkNormalizedSamplesData: ForkNormalizedData, Codable {
    public let date: String?
    public let source: String?
    public let dataType: ForkDataTypes

    public let total: Double?
    public let avg: Double?
    public let min: Double?
    public let max: Double?

    public let unit: String?

    public let samples: [ForkNormalizedSamplesData.Sample]?

    public init(
        date: String?, source: String?, dataType: ForkDataTypes, total: Double?, avg: Double?,
        min: Double?, max: Double?, unit: String?, samples: [ForkNormalizedSamplesData.Sample]?
    ) {
        self.date = date
        self.source = source
        self.dataType = dataType
        self.total = total
        self.avg = avg
        self.min = min
        self.max = max
        self.unit = unit
        self.samples = samples
        
        // super.init()
    }

    public init(
        date: String?, source: String?, dataType: ForkDataTypes, total: Double?,
        samples: [ForkNormalizedSamplesData.Sample]?
    ) {
        self.date = date
        self.source = source
        self.dataType = dataType
        self.total = total
        self.avg = nil
        self.min = nil
        self.max = nil
        self.unit = nil
        self.samples = samples
    }

    public init(
        date: String?, source: String?, dataType: ForkDataTypes,
        samples: [ForkNormalizedSamplesData.Sample]?
    ) {
        self.date = date
        self.source = source
        self.dataType = dataType
        self.total = nil
        self.avg = nil
        self.min = nil
        self.max = nil
        self.unit = nil
        self.samples = samples
    }
    
    public func getData() -> Data? {
        let encoder = JSONEncoder()
        let encoderData = try? encoder.encode(self)
        return encoderData
    }

    /// Creates Sample data object
    ///
    /// - Parameters:
    ///   - timeStart: The Sample start time
    ///   - timeEnd: The Sample end time
    ///   - value: The Sample value
    ///   - value2: Optional value param. Can be used when there are more than two values available. Such as vo2max_ml_kg_div_min and vo2max_ml_kg_times_min for VO2Max
    ///   - condition: The condition under which the dependency is exercised.
    public struct Sample: Codable {
        public let timeStart: String?
        public let timeEnd: String?
        public let value: Double?
        public let value2: Double?  // some sample will have min and max or another second value which can be useful

        public init(timeStart: String?, timeEnd: String?, value: Double?, value2: Double?) {
            self.timeStart = timeStart
            self.timeEnd = timeEnd
            self.value = value
            self.value2 = value2
        }

        public init(timeStart: String?, timeEnd: String?, value: Double?) {
            self.timeStart = timeStart
            self.timeEnd = timeEnd
            self.value = value
            self.value2 = nil
        }
    }
}

public typealias ForkNormalizedDistanceData = ForkNormalizedSamplesData
public typealias ForkNormalizedStepsData = ForkNormalizedSamplesData
public typealias ForkNormalizedFlightsClimbedData = ForkNormalizedSamplesData
public typealias ForkNormalizedHeartData = ForkNormalizedSamplesData
public typealias ForkNormalizedVO2MaxData = ForkNormalizedSamplesData

public typealias ForkNormalizedOxygenSaturationData = ForkNormalizedSamplesData
public typealias ForkNormalizedBreathingData = ForkNormalizedSamplesData

public typealias ForkNormalizedCaloriesData = ForkNormalizedSamplesData

//public struct ForkNormalizedCaloriesData: ForkNormalizedData, Codable {
//
//    public let value: Double?
//    public let intradayData: [ForkNormalizedCaloriesData.IntradayData]?
//
//    public let date: String?
//    public let source: String?
//    public let dataType: ForkDataTypes
//
//    public struct IntradayData: Codable {
//        public let level: Int?
//        public let mets: Int?
//        public let time: String
//        public let value: Double?
//    }
//}

public struct ForkNormalizedWorkoutData: ForkNormalizedData, Codable {

    //    public let providerActivityName: String?
    //    public let providerActivityTypeId: Int?
    //    public let providerActivityId: String?
    //    public let providerUserId: String?
    //    public let activityName: String?
    //    public let activityTypeId: Int?

    public let id: String
    public let workoutName: String

    public let workoutTypeId: Int?

    public let timeStart: String?
    public let timeEnd: String?
    public let timezoneOffset: Int?
    public let timezone: String?
    public let avgHr: Double?
    public let maxHr: Double?
    public let minHr: Double?
    public let avgHrVariability: Double?
    public let totalEnergyBurned: Double?
    public let activeEnergyBurned: Double?
    public let hrZones: [ForkNormalizedWorkoutData.HRZone]?
    public let duration: Int?
    public let elevationAscended: Double?
    public let elevationDescended: Double?
    public let distance: Double?
    public let steps: Double?
    public let avgSpeed: Double?
    public let maxSpeed: Double?
    public let averageWatts: Double?
    public let deviceWatts: Bool?
    public let maxWatts: Double?
    public let weightedAverageWatts: Double?
    public let maxPaceInMinutesPerKilometer: Double?
    public let weatherHumidity: Double?
    public let weatherTemperature: Double?
    public let weatherCondition: String?
    public let avgMETs: Double?
    public let map: String?
    public let samples: [ForkNormalizedWorkoutData.Sample]?
    public let laps: [ForkNormalizedWorkoutData.Lap]?
    public let events: [ForkNormalizedWorkoutData.Event]?
    public let manual: Bool?
    public let activities: Int?

    public let date: String?
    public let source: String?
    public let dataType: ForkDataTypes
    
    public func getData() -> Data? {
        let encoder = JSONEncoder()
        let encoderData = try? encoder.encode(self)
        return encoderData
    }

    public struct HRZone: Codable {
        public let max: Double?
        public let min: Double?
        public let minutes: Double?
        public let name: String?

    }
    public struct Sample: Codable {
        public let timeStart: String?
        public let timeEnd: String?
        public let timerDuration: Int?
        public let movingTime: Int?
        public let latitudeInDegree: Double?
        public let longitudeInDegree: Double?
        public let elevation: Double?
        public let airTemperature: Double?
        public let heartrate: Int?
        public let speed: Double?
        public let stepsPerMinute: Double?
        public let distance: Double?
        public let powerInWatts: Double?
        public let bikeCadenceRpm: Double?
        public let swimCadenceStrokesPerMinute: Double?

    }
    public struct Lap: Codable {
        public let timeStart: String?
    }

    public struct Event: Codable {
        public let type: String
        public let timeStart: String
        public let timeEnd: String?
        public let timerDuration: Double?
    }
}

public struct ForkNormalizedSleepData: ForkNormalizedData, Codable {
    public let bedtimeStart: String?
    public let bedtimeEnd: String?
    public let timezoneOffset: Double?
    public let bedtimeDuration: Double?
    public let totalSleep: Double?
    public let inBed: Double?
    public let awake: Double?
    public let light: Double?
    public let rem: Double?
    public let deep: Double?
    public let hrLowest: Double?
    public let hrAverage: Double?
    public let efficiency: Double?
    public let awakenings: Int?
    public let latency: Double?
    public let temperatureDelta: Double?
    public let averageHrv: Double?
    public let respiratoryRate: Double?
    public let standardizedSleepScore: Double?
    public let sourceSpecificSleepScore: Double?
    public let levels: [ForkNormalizedSleepData.Levels]?

    public let date: String?
    public let source: String?
    public let dataType: ForkDataTypes
    
    public func getData() -> Data? {
        let encoder = JSONEncoder()
        let encoderData = try? encoder.encode(self)
        return encoderData
    }

    public struct Levels: Codable {
        public let dateTime: String?
        public let level: String?
        public let seconds: Double?

        public init(dateTime: String?, level: String?, seconds: Double?) {
            self.dateTime = dateTime
            self.level = level
            self.seconds = seconds
        }
    }

    public init(
        bedtimeStart: String?,
        bedtimeEnd: String?,
        timezoneOffset: Double?,
        bedtimeDuration: Double?,
        totalSleep: Double?,
        inBed: Double?,
        awake: Double?,
        light: Double?,
        rem: Double?,
        deep: Double?,
        hrLowest: Double?,
        hrAverage: Double?,
        efficiency: Double?,
        awakenings: Int?,
        latency: Double?,
        temperatureDelta: Double?,
        averageHrv: Double?,
        respiratoryRate: Double?,
        standardizedSleepScore: Double?,
        sourceSpecificSleepScore: Double?,
        levels: [ForkNormalizedSleepData.Levels]?,
        date: String?,
        source: String?,
        dataType: ForkDataTypes
    ) {
        self.bedtimeStart = bedtimeStart
        self.bedtimeEnd = bedtimeEnd
        self.timezoneOffset = timezoneOffset
        self.bedtimeDuration = bedtimeDuration
        self.totalSleep = totalSleep
        self.inBed = inBed
        self.awake = awake
        self.light = light
        self.rem = rem
        self.deep = deep
        self.hrLowest = hrLowest
        self.hrAverage = hrAverage
        self.efficiency = efficiency
        self.awakenings = awakenings
        self.latency = latency
        self.temperatureDelta = temperatureDelta
        self.averageHrv = averageHrv
        self.respiratoryRate = respiratoryRate
        self.standardizedSleepScore = standardizedSleepScore
        self.sourceSpecificSleepScore = sourceSpecificSleepScore
        self.levels = levels
        self.date = date
        self.source = source
        self.dataType = dataType
    }
}

public struct ForkNormalizedBodyData: ForkNormalizedData, Codable {

    public let bodyData: ForkNormalizedBodyData.BodyData?
    public let temperatureData: ForkNormalizedBodyData.TemperatureData?
    public let bloodPressureData: [ForkNormalizedBodyData.BloodPressureDataObject]?

    public let date: String?
    public let source: String?
    public let dataType: ForkDataTypes
    
    public func getData() -> Data? {
        let encoder = JSONEncoder()
        let encoderData = try? encoder.encode(self)
        return encoderData
    }

    public struct BodyData: Codable {
        public let weightKg: ForkNormalizedBodyData.BodyData.DataObject?
        public let heightCm: ForkNormalizedBodyData.BodyData.DataObject?
        public let bmi: ForkNormalizedBodyData.BodyData.DataObject?
        public let bodyFatPercentage: ForkNormalizedBodyData.BodyData.DataObject?
        public let boneMassG: ForkNormalizedBodyData.BodyData.DataObject?
        public let muscleMassG: ForkNormalizedBodyData.BodyData.DataObject?
        public let waterPercentage: ForkNormalizedBodyData.BodyData.DataObject?

        public struct DataObject: Codable {
            public let value: Double?
            public let timeseries: [ForkNormalizedBodyData.BodyData.DataObject.Item]?
            public struct Item: Codable {
                public let timestamp: String?
                public let value: Double?
            }
        }
    }

    public struct TemperatureData: Codable {
        public let skinTemperature: ForkNormalizedBodyData.TemperatureData.DataObject?
        public let coreTemperature: ForkNormalizedBodyData.TemperatureData.DataObject?
        public let baselineSkinTemperature: ForkNormalizedBodyData.TemperatureData.DataObject?
        public let baselineCoreTemperature: ForkNormalizedBodyData.TemperatureData.DataObject?
        public let diffFromBaselineTemperature:
            ForkNormalizedBodyData.TemperatureData.DiffDataObject?

        public struct DataObject: Codable {
            public let temperatureCelsius: Double?
            public let timeseries: [ForkNormalizedBodyData.TemperatureData.DataObject.Item]?

            public struct Item: Codable {
                public let timestamp: String?
                public let temperatureCelsius: Double?
            }
        }

        public struct DiffDataObject: Codable {
            public let diffTemperatureCelsius: Double?
            public let timeseries: [ForkNormalizedBodyData.TemperatureData.DiffDataObject.Item]?
            public struct Item: Codable {
                public let timestamp: String?
                public let diffTemperatureCelsius: Double?
            }
        }
    }
    public struct BloodPressureDataObject: Codable {
        public let timestamp: String
        public let systolicBloodPressure: Int
        public let diastolicBloodPressure: Int
    }
}

public struct ForkNormalizedActivitiesSummaryData: ForkNormalizedData, Codable {

    public let caloriesBmr: Int?
    public let caloriesTotal: Int?
    public let caloriesActive: Int?
    public let steps: Double?
    public let dailyMovement: Int?
    public let distance: Double?
    public let low: Int?
    public let medium: Int?
    public let high: Int?
    public let elevation: Int?
    public let restingHr: Int?
    public let floors: Int?
    public let sedentaryMinutes: Int?
    public let minHr: Double?
    public let avgHr: Double?
    public let maxHr: Double?
    public let avgStressLevel: Double?
    public let maxStressLevel: Double?
    public let stressDuration: Double?
    public let lowStressDuration: Double?
    public let mediumStressDuration: Double?
    public let highStressDuration: Double?
    public let providerTimestamp: String?

    public let date: String?
    public let source: String?
    public let dataType: ForkDataTypes
    
    public func getData() -> Data? {
        let encoder = JSONEncoder()
        let encoderData = try? encoder.encode(self)
        return encoderData
    }
}

public struct ForkNormalizedGlucoseData: ForkNormalizedData, Codable {

    public let avgValue: Double?
    public let minValue: Double?
    public let maxValue: Double?
    public let unit: String?
    public let intradayData: [ForkNormalizedGlucoseData.IntradayData]?

    public let date: String?
    public let source: String?
    public let dataType: ForkDataTypes

    public struct IntradayData: Codable {
        public let time: String
        public let value: Double?
        public let realtimeValue: Double?
        public let smoothedValue: Double?
        public let status: String?
        public let trend: String?
        public let trendRate: Double?
    }
    
    public func getData() -> Data? {
        let encoder = JSONEncoder()
        let encoderData = try? encoder.encode(self)
        return encoderData
    }
}

public struct ForkNormalizedWorkoutSplitData: ForkNormalizedData, Codable {
    public let splits: [ForkNormalizedWorkoutSplitData.Split]?

    public let date: String?
    public let source: String?
    public let dataType: ForkDataTypes

    public struct Split: Codable {
        public let time: String
    }
    
    public func getData() -> Data? {
        let encoder = JSONEncoder()
        let encoderData = try? encoder.encode(self)
        return encoderData
    }
}

public struct ForkNormalizedRouteData: ForkNormalizedData, Codable {
    public let coordinates: [ForkNormalizedRouteData.Coordinate]?

    public let date: String?
    public let source: String?
    public let dataType: ForkDataTypes

    public struct Coordinate: Codable {
        public let time: String
        public let altitude: Double
        public let latitude: Double
        public let longitude: Double
    }
    
    public func getData() -> Data? {
        let encoder = JSONEncoder()
        let encoderData = try? encoder.encode(self)
        return encoderData
    }
}

/// :nodoc:
public struct DeviceInformation: Codable {
    public let name: String?
    public let model: String?
    public let manufacturer: String?
    public let hardware_version: String?
    public let software_version: String?
}
