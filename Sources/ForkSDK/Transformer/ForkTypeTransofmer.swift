//
//  ForkTypeTransofmer.swift
//
//
//  Created by Aleksandras Gaidamauskas on 27/08/2024.
//

import CoreLocation
import Foundation
import HealthKit

//For reference, the following units can be used on the unit constants below
//This is from https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier
//and units come from https://developer.apple.com/documentation/healthkit/hkunit
//with unit strings defined at https://developer.apple.com/documentation/healthkit/hkunit/1615733-unitfromstring?language=objc
//
//const MASS_UNITS = ['g', 'oz', 'lb', 'st']; // gram, ounce, pound, stone
//const LENGTH_UNITS = ['m', 'in', 'ft', 'yd', 'mi']; // meter, inch, foot, yard, mile
//const TIME_UNITS = ['s', 'min', 'hour', 'day']; // second, minute, hour, day
//const ENERGY_UNITS = ['J', 'cal', 'Cal', 'kcal']; // joule, small calorie, large calorie, kilocalorie
//const TEMPERATURE_UNITS = ['K', 'degC', 'degF']; // kelvin, celsius, fahrenheit
//const VOLUME_UNITS = ['l', 'fl_oz_us', 'fl_oz_imp', 'cup_us', 'cup_imp', 'pt_us', 'pt_imp']; // litre, us fluid ounce, imperial fluid ounce, us cup, imperial cup, us pint, imperial pint
//
//Prefixes can take the following for for reference as well
//const prefixes = [
//  'p', // pico 0.000000000001
//  'n', // nano 0.000000001
//  'mc', // micro 0.000001
//  'm', // milli 0.001
//  'c', // centi 0.01
//  'd', // deci 0.1
//  'da', // deca 10
//  'h', // hecto 100
//  'k', // kilo 1000
//  'M', // mega 1000000
//  'G', // giga 1000000000
//  'T', // tera 1000000000000
//];

// https://ianbelcher.me/tech-blog/automated-exporting-of-health-kit-data

public protocol ForkTypeTransformerProtocol: ForkTransformerProtocol {

    associatedtype T

    func transformData(_ forType: ForkDataTypes, data: ForkHealthData, from: Date, to: Date) -> [T]?
}

public class ForkTypeTransofmer: ForkTypeTransformerProtocol {
    public func transformData(_ forType: ForkDataTypes, data: ForkHealthData, from: Date, to: Date)
        -> [ForkNormalizedData]?
    {
        switch forType {
        case .workouts:
            if let data = data as? ForkHealthDataWorkouts {
                return normalizeWorkoutData(workouts: data.items, startDate: from, endDate: to)
            } else {
                return nil
            }
        case .sleep:
            if let data = data as? ForkHealthDataCategorySamples {
                return normalizeSleepData(samples: data.items)
            } else {
                return nil
            }
        case .oxygenSaturation:
            if let data = data as? ForkHealthDataQuantitySamples {
                let normalized = normalizeOxygenSaturationData(samples: data.items)
                if let normalized = normalized {
                    return [
                        normalized
                    ]
                }
                print("Not normalized")
                return nil
            } else {
                return nil
            }
        case .distance:
            if let data = data as? ForkHealthDataStatistics {
                return [
                    normalizeDistanceData(
                        statisticsCollection: data.collection, startDate: from, endDate: to)
                ]
            } else {
                return nil
            }
        case .calories:
            if let data = data as? ForkHealthDataStatistics {
                return [
                    normalizeActiveEnergyData(
                        statisticsCollection: data.collection, startDate: from, endDate: to)
                ]
            } else {
                return nil
            }
        case .steps:
            if let data = data as? ForkHealthDataStatistics {
                return [
                    normalizeStepsData(
                        statisticsCollection: data.collection, startDate: from, endDate: to)
                ]
            } else {
                return nil
            }
        case .flightsClimbed:
            if let data = data as? ForkHealthDataStatistics {
                return [
                    normalizeFlightsClimbedData(
                        statisticsCollection: data.collection, startDate: from, endDate: to)
                ]
            } else {
                return nil
            }
        case .vo2Max:
            if let data = data as? ForkHealthDataQuantitySamples {
                let normalized = normalizeVO2Data(samples: data.items)
                if let normalized = normalized {
                    return [
                        normalized
                    ]
                }
                print("Not normalized")
                return nil
            } else {
                print("Not ForkHealthDataQuantitySamples")
                return nil
            }
        case .heart:
            //            if let data = data as? ForkHealthDataDiscreteQuantitySamples {
            //                let normalized = normalizeHeartRateData(samples: data.items)
            //                if let normalized = normalized {
            //                    return [
            //                        normalized
            //                    ]
            //                }
            //                return nil
            //            } else {
            //                return nil
            //            }

            if let data = data as? ForkHealthDataQuantitySamples {
                let normalized = normalizeHeartRateData(samples: data.items)
                if let normalized = normalized {
                    return [
                        normalized
                    ]
                }
                print("Not normalized")
                return nil
            } else {
                print("Not ForkHealthDataQuantitySamples")
                return nil
            }
        case .workoutRoute:
            if let data = data as? ForkHealthDataLLocation {
                let normalized = normalizeCoordinates(coordinates: data.items)
                if let normalized = normalized {
                    return [
                        normalized
                    ]
                }
                print("Not normalized")
                return nil
            } else {
                print("Not ForkHealthDataQuantitySamples")
                return nil
            }
        default:
            return nil
        }
    }

    // ForkNormalizedActivitiesSummaryData
    // ForkNormalizedCaloriesData

    func normalizeCoordinates(coordinates: [CLLocation]) -> ForkNormalizedRouteData? {
        //        var items = [ForkNormalizedRouteData.Coordinate]()
        return ForkNormalizedRouteData(
            coordinates: coordinates.map {
                ForkNormalizedRouteData.Coordinate(
                    time: $0.timestamp.ISO8601Format(),
                    altitude: $0.altitude,
                    latitude: Double($0.coordinate.latitude),
                    longitude: Double($0.coordinate.longitude)
                )
            },
            date: Date.now.ISO8601Format(),
            source: "HealthKit",
            dataType: .workoutRoute
        )
    }

    // VO2 max is typically measured in milliliters of oxygen consumed in a minute per kilogram of body weight (mL/kg/min)
    func normalizeVO2Data(samples: [HKQuantitySample]) -> ForkNormalizedVO2MaxData? {
        guard !samples.isEmpty else {
            print("no samples")
            return nil
        }
        // Prepare containers for heart rate samples and stats
        var items = [ForkNormalizedVO2MaxData.Sample]()

        // Loop through the samples to extract the data
        for sample in samples {

            let value_per_min = sample.quantity.doubleValue(for: HKUnit(from: "ml/kg/min"))
            let value_times_min = sample.quantity.doubleValue(for: HKUnit(from: "ml/kg*min"))

            print("value_per_min \(value_per_min)")
            print("value_times_min \(value_times_min)")

            items.append(
                ForkNormalizedVO2MaxData.Sample(
                    timeStart: sample.startDate.ISO8601Format(),
                    timeEnd: sample.endDate.ISO8601Format(),
                    value: value_per_min,  // vo2max_ml_kg_div_min
                    value2: value_times_min  // vo2max_ml_kg_times_min
                ))
        }

        let normalizedData = ForkNormalizedVO2MaxData(
            date: items.first?.timeStart ?? Date.now.ISO8601Format(),
            source: "healthkit",  // Get source name from the first sample
            dataType: .vo2Max,
            samples: items
        )

        return normalizedData
    }

    // motion_context
    func normalizeHeartRateData(samples: [HKQuantitySample]) -> ForkNormalizedHeartData? {
        guard !samples.isEmpty else {
            print("no samples")
            return nil
        }

        // Prepare containers for heart rate samples and stats
        var heartRateSamples = [ForkNormalizedHeartData.Sample]()
        var minHeartRate: Double = Double.greatestFiniteMagnitude
        var maxHeartRate: Double = 0.0
        var totalHeartRate: Double = 0.0

        // Date formatter for converting date to string format
        let dateFormatter = ISO8601DateFormatter()
        //        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Loop through the samples to extract the heart rate data
        for sample in samples {
            let heartRateValue = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))

            let motionContext = sample.metadata?[HKMetadataKeyHeartRateMotionContext] as? NSNumber

            // Create a ForkNormalizedHeartData.Sample entry
            let heartRateSample = ForkNormalizedHeartData.Sample(
                timeStart: sample.startDate.ISO8601Format(),
                timeEnd: sample.endDate.ISO8601Format(),
                value: heartRateValue,
                value2: motionContext?.doubleValue ?? nil
            )

            heartRateSamples.append(heartRateSample)

            // Update min, max, and total heart rate
            minHeartRate = min(minHeartRate, heartRateValue)
            maxHeartRate = max(maxHeartRate, heartRateValue)
            totalHeartRate += heartRateValue
        }

        // Calculate average heart rate
        let avgHeartRate = totalHeartRate / Double(samples.count)

        // Get the date for the normalized data (using the first sample's date)
        let firstSampleDate = dateFormatter.string(from: samples.first!.startDate)

        let normalizedData = ForkNormalizedHeartData(
            date: firstSampleDate,
            source: samples.first?.sourceRevision.source.name,
            dataType: .heart,
            total: nil,
            avg: avgHeartRate,
            min: minHeartRate,
            max: maxHeartRate,
            unit: "count/min",
            samples: heartRateSamples
        )

        return normalizedData
    }

    //    func normalizeHeartRateData(samples: [HKDiscreteQuantitySample]) -> ForkNormalizedHeartData? {
    //        let dateFormatter = ISO8601DateFormatter()
    //        var heartRateSamples = [ForkNormalizedHeartData.Sample]()
    //        var intradayHRV = [ForkNormalizedHeartData.IntradayHrv]()
    //
    //        var minHeartRate: Double? = nil
    //        var avgHeartRate: Double? = nil
    //        var maxHeartRate: Double? = nil
    //        var totalHeartRate: Double = 0
    //        var heartRateCount = 0
    //        var minHRV: Double? = nil
    //        var avgHRV: Double? = nil
    //        var maxHRV: Double? = nil
    //        var totalHRV: Double = 0
    //        var hrvCount = 0
    //
    //        for sample in samples {
    //            let value = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
    //            let time = dateFormatter.string(from: sample.startDate)
    //
    //            // Heart rate processing
    //            if sample.quantityType == HKQuantityType.quantityType(forIdentifier: .heartRate) {
    //                heartRateSamples.append(ForkNormalizedHeartData.Sample(time: time, value: value))
    //
    //                // Calculate min, avg, max heart rate
    //                if let minHR = minHeartRate {
    //                    minHeartRate = min(minHR, value)
    //                } else {
    //                    minHeartRate = value
    //                }
    //                if let maxHR = maxHeartRate {
    //                    maxHeartRate = max(maxHR, value)
    //                } else {
    //                    maxHeartRate = value
    //                }
    //                totalHeartRate += value
    //                heartRateCount += 1
    //            }
    //
    //            // HRV processing
    //            if sample.quantityType == HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
    //                let hrvValue = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
    //                let intradayHRVSample = ForkNormalizedHeartData.IntradayHrv(
    //                    time: time,
    //                    value: ForkNormalizedHeartData.IntradayHrv.Value(rmssd: hrvValue, coverage: nil, hf: nil, lf: nil)
    //                )
    //                intradayHRV.append(intradayHRVSample)
    //
    //                // Calculate min, avg, max HRV
    //                if let minHRVVal = minHRV {
    //                    minHRV = min(minHRVVal, hrvValue)
    //                } else {
    //                    minHRV = hrvValue
    //                }
    //                if let maxHRVVal = maxHRV {
    //                    maxHRV = max(maxHRVVal, hrvValue)
    //                } else {
    //                    maxHRV = hrvValue
    //                }
    //                totalHRV += hrvValue
    //                hrvCount += 1
    //            }
    //        }
    //
    //        // Calculate average heart rate and HRV
    //        if heartRateCount > 0 {
    //            avgHeartRate = totalHeartRate / Double(heartRateCount)
    //        }
    //        if hrvCount > 0 {
    //            avgHRV = totalHRV / Double(hrvCount)
    //        }
    //
    //        // Assuming all samples belong to the same day, take the date of the first sample as the reference date
    //        guard let firstSample = samples.first else { return nil }
    //        let date = dateFormatter.string(from: firstSample.startDate)
    //
    //        // Construct the heart rate variability data
    //        let heartRateVariability = ForkNormalizedHeartData.Variability(dayHRV: avgHRV, sleepHRV: nil)
    //
    //        // Create the final ForkNormalizedHeartData object
    //        let normalizedHeartData = ForkNormalizedHeartData(
    //            date: date,
    //            source: firstSample.sourceRevision.source.name,
    //            dataType: "heart_rate",
    //            restingHeartRate: nil, // You can calculate or set this based on additional data
    //            minHeartRate: minHeartRate,
    //            avgHeartRate: avgHeartRate,
    //            maxHeartRate: maxHeartRate,
    //            heartRateSamples: heartRateSamples,
    //            heartRateVariability: heartRateVariability,
    //            intradayHRV: intradayHRV
    //        )
    //
    //        return normalizedHeartData
    //    }

    func normalizeOxygenSaturationData(samples: [HKQuantitySample])
        -> ForkNormalizedOxygenSaturationData?
    {
        guard !samples.isEmpty else {
            print("no samples")
            return nil
        }
        // Prepare containers for heart rate samples and stats
        var items = [ForkNormalizedOxygenSaturationData.Sample]()

        // Loop through the samples to extract the data
        for sample in samples {

            let value = sample.quantity.doubleValue(for: HKUnit.percent())

            items.append(
                ForkNormalizedOxygenSaturationData.Sample(
                    timeStart: sample.startDate.ISO8601Format(),
                    timeEnd: sample.endDate.ISO8601Format(),
                    value: value
                ))
        }

        let normalizedData = ForkNormalizedOxygenSaturationData(
            date: items.first?.timeStart ?? Date.now.ISO8601Format(),
            source: "healthkit",  // Get source name from the first sample
            dataType: .oxygenSaturation,
            samples: items
        )

        print("oxygen")
        print(normalizedData)

        return normalizedData
    }

    // Function to convert HKCategorySample (sleep data) to ForkNormalizedSleepData
    func normalizeSleepData(samples: [HKCategorySample]) -> [ForkNormalizedSleepData] {

        func valueToString(value: Int) -> String {
            switch value {
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                return "InBed"
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                return "Core"
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                return "Awake"
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                return "Deep"
            case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                return "Asleep Unspecified"
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                return "REM"
            default:
                return "\(value)"
            }
        }

        func calculateSleepScore(sleepHours: Double) -> Double {
            let idealSleep = 8.0  // Ideal sleep hours (can be adjusted)

            // A simple linear score: 100 for perfect sleep, reduced for less/more sleep
            let score = max(0, min(100, (sleepHours / idealSleep) * 100))
            return score
        }

        func calculateWeightedSleepScore(
            sleepDuration: Double, sleepEfficiency: Double, sleepConsistency: Double
        ) -> Double {
            let durationWeight = 0.5  // 50% weight
            let efficiencyWeight = 0.3  // 30% weight
            let consistencyWeight = 0.2  // 20% weight

            // Normalize sleep duration score (e.g., 8 hours is ideal)
            let normalizedDurationScore = min(100, (sleepDuration / 8.0) * 100)

            // Weighted score
            let finalScore =
                (normalizedDurationScore * durationWeight) + (sleepEfficiency * efficiencyWeight)
                + (sleepConsistency * consistencyWeight)

            return min(100, finalScore)  // Ensure score is capped at 100
        }

        let dateFormatter = ISO8601DateFormatter()
        var sleepDataArray = [ForkNormalizedSleepData]()

        // Sort samples by start date to process sleep sessions in chronological order
        let sortedSamples = samples.sorted(by: { $0.startDate < $1.startDate })

        //        var currentSession: [HKCategorySample] = []

        // Function to finalize a session and convert it into ForkNormalizedSleepData
        //        func finalizeSession() {
        guard !samples.isEmpty else { return [] }

        var totalSleepDuration: TimeInterval = 0
        var totalSleepDuration2: TimeInterval = 0
        var inBedTimeInterval: TimeInterval = 0
        var totalSleep: Double = 0
        var inBed: Double = 0
        var awake: Double = 0
        var light: Double = 0
        var rem: Double = 0
        var deep: Double = 0
        var levels = [ForkNormalizedSleepData.Levels]()

        let inBedSamples = samples.filter { sample in
            //            if let sleepValue = HKCategoryValueSleepAnalysis(rawValue: sample.value) {
            //                return HKCategoryValueSleepAnalysis.inBed == sleepValue
            //            }
            //            return false
            return sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue
        }
        inBedSamples.forEach { sample in
            inBedTimeInterval += sample.endDate.timeIntervalSince(sample.startDate)
        }

        // Filter the samples for awake periods
        let awakeSamples = samples.filter { sample in
            return sample.value == HKCategoryValueSleepAnalysis.awake.rawValue
        }

        let asleepSamples = samples.filter { sample in
            if let sleepValue = HKCategoryValueSleepAnalysis(rawValue: sample.value) {
                return HKCategoryValueSleepAnalysis.allAsleepValues.contains(sleepValue)
            }
            return false
        }
        asleepSamples.forEach { sample in
            totalSleepDuration2 += sample.endDate.timeIntervalSince(sample.startDate)
        }

        // Process each sample in the current session
        for sample in samples {
            let startDate = sample.startDate
            let endDate = sample.endDate
            let duration = endDate.timeIntervalSince(startDate)
            let dateTime = dateFormatter.string(from: startDate)

            var level = valueToString(value: sample.value)
            switch sample.value {
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                inBed += duration
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                light += duration
                totalSleep += duration
                totalSleepDuration += duration
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                awake += duration
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                deep += duration
                totalSleep += duration
                totalSleepDuration += duration
            case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                totalSleep += duration
                totalSleepDuration += duration
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                rem += duration
                totalSleep += duration
                totalSleepDuration += duration
            default:
                level = "unknown"
            }

            levels.append(
                ForkNormalizedSleepData.Levels(
                    dateTime: dateTime,
                    level: level,
                    seconds: duration
                ))
        }

        print(
            "totalSleepDuration2: \(totalSleepDuration2), totalSleepDuration: \(totalSleepDuration), totalSleep: \(totalSleep)"
        )

        print("inBedTimeInterval: \(inBedTimeInterval)")
        print(
            "inBed: \(inBed), awake: \(awake/60), light: \(light/60), rem: \(rem/60), deep: \(deep/60)"
        )

        guard let firstSample = sortedSamples.first, let lastSample = sortedSamples.last else {
            return []
        }

        let bedtimeStart = dateFormatter.string(from: firstSample.startDate)
        let bedtimeEnd = dateFormatter.string(from: lastSample.endDate)
        let timezoneOffset = Double(TimeZone.current.secondsFromGMT()) / 3600
        let bedtimeDuration = lastSample.endDate.timeIntervalSince(firstSample.startDate)

        // Convert duration to hours
        let sleepDurationInHours = totalSleepDuration / 3600.0

        let sleepEfficiency = (totalSleep / inBed) * 100
        print("sleepEfficiency = \(sleepEfficiency) (\(totalSleep) / \(inBed)) * 100")

        var sleepStartTimes: [Date] = []
        asleepSamples.forEach { sample in
            sleepStartTimes.append(sample.startDate)
        }

        // Calculate the standard deviation of sleep start times
        // Calculate the total of the time intervals from 1970
        let totalInterval = sleepStartTimes.reduce(0.0) { $0 + $1.timeIntervalSince1970 }

        // Calculate the average of the time intervals
        let averageInterval = totalInterval / Double(sleepStartTimes.count)

        // Convert the average time interval back to a Date object
        let averageSleepStartTime = Date(timeIntervalSince1970: averageInterval)

        let variance = sleepStartTimes.reduce(0) {
            $0 + pow($1.timeIntervalSince1970 - averageSleepStartTime.timeIntervalSince1970, 2)
        }
        let stdDev = sqrt(variance / Double(sleepStartTimes.count))

        // Convert stdDev to consistency score (inverse relation)
        let consistencyScore = max(0, min(100, 100 - stdDev / 60))  // Assuming stdDev in minutes

        let finalSleepScore = calculateWeightedSleepScore(
            sleepDuration: sleepDurationInHours, sleepEfficiency: sleepEfficiency,
            sleepConsistency: consistencyScore)
        print(
            "sleepDurationInHours: \(sleepDurationInHours), sleepEfficiency: \(sleepEfficiency), consistencyScore: \(consistencyScore), Final Sleep Score: \(finalSleepScore)"
        )

        let sleepData = ForkNormalizedSleepData(
            bedtimeStart: bedtimeStart,
            bedtimeEnd: bedtimeEnd,
            timezoneOffset: timezoneOffset,
            bedtimeDuration: bedtimeDuration,
            totalSleep: totalSleep,
            inBed: inBed,
            awake: awake,
            light: light,
            rem: rem,
            deep: deep,
            hrLowest: nil,
            hrAverage: nil,
            efficiency: nil,
            awakenings: awakeSamples.count,
            latency: bedtimeDuration - totalSleep,
            temperatureDelta: nil,
            averageHrv: nil,
            respiratoryRate: nil,
            standardizedSleepScore: calculateSleepScore(sleepHours: sleepDurationInHours),
            sourceSpecificSleepScore: calculateSleepScore(sleepHours: sleepDurationInHours),
            levels: levels,
            date: bedtimeStart,
            source: firstSample.sourceRevision.source.name,
            dataType: .sleep
        )

        sleepDataArray.append(sleepData)
        //            currentSession.removeAll()
        //        }

        // Iterate over sorted samples to group them into sessions
        //        for sample in sortedSamples {
        //            if let lastSample = currentSession.last, sample.startDate.timeIntervalSince(lastSample.endDate) > 3600 {
        //                // Finalize the session if there is a gap greater than 1 hour between samples
        //                finalizeSession()
        //            }
        //
        //            // Add sample to the current session
        //            currentSession.append(sample)
        //        }

        //        currentSession.append(contentsOf: sortedSamples)

        // Finalize the last session
        //        finalizeSession()

        return sleepDataArray
    }

    func normalizeDistanceData(
        statisticsCollection: HKStatisticsCollection, startDate: Date, endDate: Date
    ) -> ForkNormalizedDistanceData {
        var total: Double = 0
        var samples = [ForkNormalizedDistanceData.Sample]()

        statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
            if let sum = statistics.sumQuantity() {
                let value = sum.doubleValue(for: .meter())
                total += value

                samples.append(
                    ForkNormalizedDistanceData.Sample(
                        timeStart: statistics.startDate.ISO8601Format(),
                        timeEnd: statistics.endDate.ISO8601Format(),
                        value: value
                    ))
            }
        }

        return ForkNormalizedDistanceData(
            date: startDate.ISO8601Format(),
            source: "HealthKit",
            dataType: .distance,
            total: total,
            samples: samples
        )
    }

    func normalizeStepsData(
        statisticsCollection: HKStatisticsCollection, startDate: Date, endDate: Date
    ) -> ForkNormalizedStepsData {
        var total: Double = 0
        var samples = [ForkNormalizedStepsData.Sample]()

        var source: String?

        statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
            source = statistics.sources?.first?.name
            if let sum = statistics.sumQuantity() {
                let value = sum.doubleValue(for: .count())
                total += value

                samples.append(
                    ForkNormalizedStepsData.Sample(
                        timeStart: statistics.startDate.ISO8601Format(),
                        timeEnd: statistics.endDate.ISO8601Format(),
                        value: value
                    ))
            }
        }

        print("total \(total)")

        return ForkNormalizedStepsData(
            date: startDate.ISO8601Format(),
            source: source ?? "HealthKit",
            dataType: .steps,
            total: total,
            samples: samples
        )
    }

    func normalizeFlightsClimbedData(
        statisticsCollection: HKStatisticsCollection, startDate: Date, endDate: Date
    ) -> ForkNormalizedFlightsClimbedData {
        var total: Double = 0
        var samples = [ForkNormalizedFlightsClimbedData.Sample]()

        var source: String?

        statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
            source = statistics.sources?.first?.name
            if let sum = statistics.sumQuantity() {
                let value = sum.doubleValue(for: .count())
                total += value

                samples.append(
                    ForkNormalizedFlightsClimbedData.Sample(
                        timeStart: statistics.startDate.ISO8601Format(),
                        timeEnd: statistics.endDate.ISO8601Format(),
                        value: value
                    ))
            }
        }

        print("total \(total)")

        return ForkNormalizedFlightsClimbedData(
            date: startDate.ISO8601Format(),
            source: source ?? "HealthKit",
            dataType: .flightsClimbed,
            total: total,
            samples: samples
        )
    }

    func normalizeActiveEnergyData(
        statisticsCollection: HKStatisticsCollection, startDate: Date, endDate: Date
    ) -> ForkNormalizedCaloriesData {
        var total: Double = 0
        var samples = [ForkNormalizedCaloriesData.Sample]()

        var source: String?

        statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
            source = statistics.sources?.first?.name
            if let sum = statistics.sumQuantity() {
                // UnitEnergy.kilocalories
                let value = sum.doubleValue(for: .kilocalorie())
                total += value

                samples.append(
                    ForkNormalizedCaloriesData.Sample(
                        timeStart: statistics.startDate.ISO8601Format(),
                        timeEnd: statistics.endDate.ISO8601Format(),
                        value: value
                    ))
            }
        }

        print("total \(total)")

        return ForkNormalizedCaloriesData(
            date: startDate.ISO8601Format(),
            source: source ?? "HealthKit",
            dataType: .calories,
            total: total,
            samples: samples
        )
    }

    func normalizeWorkoutData(workouts: [HKWorkout], startDate: Date, endDate: Date)
        -> [ForkNormalizedWorkoutData]
    {
        let dateFormatter = ISO8601DateFormatter()

        return workouts.map { workout in
            // Extract start and end time

            // Timezone offset in minutes
            let timezoneOffset = TimeZone.current.secondsFromGMT() / 60

            // Activity name
            let activityName = workout.workoutActivityType.name

            let distanceCycling = workout.statistics(
                for:
                    .quantityType(forIdentifier: .distanceCycling)!
            )
            let distanceWalkingRunning = workout.statistics(
                for:
                    .quantityType(forIdentifier: .distanceWalkingRunning)!
            )
            let distanceSwimming = workout.statistics(
                for:
                    .quantityType(forIdentifier: .distanceSwimming)!
            )
            if #available(iOS 18.0, *) {
                let distanceRowing = workout.statistics(
                    for:
                            .quantityType(forIdentifier: .distanceRowing)!
                )
                print("distanceRowing \(distanceRowing?.sumQuantity()?.doubleValue(for: .meter()) ?? 0.0)")
                let distancePaddleSports = workout.statistics(
                    for:
                            .quantityType(forIdentifier: .distancePaddleSports)!
                )
                print("distancePaddleSports \(distancePaddleSports?.sumQuantity()?.doubleValue(for: .meter()) ?? 0.0)")
            }
            let distance =
                distanceCycling != nil
                ? distanceCycling
                : distanceWalkingRunning != nil ? distanceWalkingRunning : distanceSwimming

            // distance?.sumQuantity()?.doubleValue(for: .meter())

            // Extract other relevant properties
            let totalDistance = workout.totalDistance?.doubleValue(for: .meter())

            print("totalDistance \(totalDistance ?? 0.0)")
            print("distance \(distance?.sumQuantity()?.doubleValue(for: .meter()) ?? 0.0)")

            let totalEnergyBurned = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie())

            let activeEnergyBurned = workout.statistics(
                for:
                    .quantityType(forIdentifier: .activeEnergyBurned)!
            )
            let basalEnergyBurned = workout.statistics(
                for:
                    .quantityType(forIdentifier: .basalEnergyBurned)!
            )

            print("totalEnergyBurned \(totalEnergyBurned ?? 0.0)")
            print(
                "activeEnergyBurned \(activeEnergyBurned?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0.0)"
            )
            print(
                "basalEnergyBurned \(basalEnergyBurned?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0.0)"
            )

            // activeEnergyBurned?.sumQuantity()?.doubleValue(for: .kilocalorie())
            let heartRate = workout.statistics(
                for:
                    .quantityType(forIdentifier: .heartRate)!
            )

            let heartRateAvg =
                heartRate?.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min")).rounded()
                ?? nil

            let heartRateMin =
                heartRate?.minimumQuantity()?.doubleValue(for: HKUnit(from: "count/min")).rounded()
                ?? nil

            let heartRateMax =
                heartRate?.maximumQuantity()?.doubleValue(for: HKUnit(from: "count/min")).rounded()
                ?? nil

            let swimmingStrokeCount = workout.statistics(
                for:
                    .quantityType(forIdentifier: .swimmingStrokeCount)!
            )

            let totalSwimmingStrokeCount =
                swimmingStrokeCount?.sumQuantity()?.doubleValue(for: HKUnit.count()).rounded()
                ?? nil

            print("totalSwimmingStrokeCount \(totalSwimmingStrokeCount ?? 0.0)")

            //            let sampleType = HKSampleType.quantityType(forIdentifier: .swimmingStrokeCount)

            print("metadata \(workout.metadata)")
            // metadata Optional(["HKLapLength": 25 m, "HKSwimmingLocationType": 1, "HKAverageMETs": 11.9119 kcal/hr·kg, "HKIndoorWorkout": 0, "HKTimeZone": Europe/Vilnius])

            // Set manual flag (if the workout was manually entered by the user)
            let manual = workout.metadata?[HKMetadataKeyWasUserEntered] as? Bool ?? false
            let timezone = workout.metadata?[HKMetadataKeyTimeZone] as? String ?? nil
            let lapLength = workout.metadata?[HKMetadataKeyLapLength] as? HKQuantity
            //            let swimmingLocationType = workout.metadata?[HKMetadataKeySwimmingLocationType] as? HKWorkoutSwimmingLocationType
            //            print("swimmingLocation \(String(describing: swimmingLocationType))")

            //            /**
            //             @constant      HKMetadataKeySWOLFScore
            //             @abstract      Represents sum of strokes per length and time for the length. Calculated for each lap event and segment event during swimming workout.
            //             @discussion    The expected value type is an NSNumber containing a score. This key may be set on an HKWorkout object to represent the SWOLF Score during the whole workout.
            //            public let HKMetadataKeySWOLFScore: String

            //            let type: HKWorkoutEventType = event.type
            //            let start_timestamp: Date = event.dateInterval.start
            //            let end_timestamp: Date = event.dateInterval.end
            //            let stroke_style = event.metadata?[HKMetadataKeySwimmingStrokeStyle] as? NSNumber
            //            var swolf: NSNumber?;
            //            if #available(iOS 16.0, *) {
            //                swolf = event.metadata?[HKMetadataKeySWOLFScore] as? NSNumber
            //            } else {
            //                swolf = nil
            //            }

            if let lapLength = lapLength {
                let lapLengthMeter = lapLength.doubleValue(for: HKUnit.meter())
                print("lapLengthMeter \(lapLengthMeter)")

                var eventLaps = [ForkNormalizedWorkoutData.Event]()

                let lapEvements = workout.workoutEvents!.filter {
                    $0.type == HKWorkoutEventType.lap
                }
                print("lapEvements \(lapEvements.count)")

                let segments = workout.workoutEvents!.filter {
                    $0.type == HKWorkoutEventType.segment
                }
                for segment in segments {

                    print("segment")

                    let laps = workout.workoutEvents!.filter {
                        $0.type == HKWorkoutEventType.lap
                            && $0.dateInterval.start >= segment.dateInterval.start
                            && $0.dateInterval.end <= segment.dateInterval.end
                    }

                    eventLaps.append(
                        ForkNormalizedWorkoutData.Event(
                            type: "Lap",
                            timeStart: dateFormatter.string(from: segment.dateInterval.start),
                            timeEnd: dateFormatter.string(from: segment.dateInterval.end),
                            timerDuration: segment.dateInterval.duration
                        )
                    )

                    //                                            file.write(
                    //                                                "<Lap StartTime=\"\(iso_formatter.string(from: segment.dateInterval.start))\"><TotalTimeSeconds>\(segment.dateInterval.duration)</TotalTimeSeconds><DistanceMeters>\(poolDistance.doubleValue(for: HKUnit.meter()) * Double(laps.count))</DistanceMeters><Calories>0</Calories><Intensity>Active</Intensity><TriggerMethod>Manual</TriggerMethod><Track>".data(using: .utf8)!
                    //                                            )
                }

                print("eventLaps \(eventLaps)")
            }

            // Map the workout into a ForkNormalizedWorkoutData object
            return ForkNormalizedWorkoutData(
                id: workout.uuid.uuidString,
                workoutName: activityName,
                workoutTypeId: Int(workout.workoutActivityType.rawValue),
                timeStart: workout.startDate.ISO8601Format(),
                timeEnd: workout.endDate.ISO8601Format(),
                timezoneOffset: timezoneOffset,
                timezone: timezone,
                avgHr: heartRateAvg,  // You need to query heart rate data separately if needed
                maxHr: heartRateMax,
                minHr: heartRateMin,
                avgHrVariability: nil,
                totalEnergyBurned: activeEnergyBurned?.sumQuantity()?.doubleValue(
                    for: .kilocalorie()) ?? nil,  // totalEnergyBurned
                activeEnergyBurned: basalEnergyBurned?.sumQuantity()?.doubleValue(
                    for: .kilocalorie()) ?? nil,
                hrZones: nil,  // You need to calculate this from heart rate data
                duration: Int(workout.duration),  // Workout duration in seconds
                elevationAscended: getWorkoutElevationAscended(workout: workout),
                elevationDescended: getWorkoutElevationDescended(workout: workout),
                distance: totalDistance,
                steps: nil,  // Could be gathered separately from step count samples
                avgSpeed: getWorkoutAverageSpeed(workout: workout),  //calculateAverageSpeed(distance: totalDistance, duration: workout.duration),
                maxSpeed: getWorkoutMaximumSpeed(workout: workout),  // Need to calculate max speed separately from samples
                averageWatts: nil,
                deviceWatts: false,  // Assuming no device watts unless explicitly provided
                maxWatts: nil,
                weightedAverageWatts: nil,
                maxPaceInMinutesPerKilometer: nil,  // You can calculate this based on speed data
                weatherHumidity: getWorkoutWeatherHumidity(workout: workout),
                weatherTemperature: getWorkoutWeather(workout: workout),
                weatherCondition: getWorkoutWeatherCondition(workout: workout),
                avgMETs: getWorkoutAverageMETs(workout: workout),
                map: nil,  // If available, you can map GPS data here
                samples: nil,  // You can fill this in with workout segment data if needed
                laps: nil,  // You can add laps if the workout was segmented
                events: workout.workoutEvents?.map {
                    ForkNormalizedWorkoutData.Event(
                        type: $0.type.stringRepresentation,
                        timeStart: $0.dateInterval.start.ISO8601Format(),
                        timeEnd: $0.dateInterval.end.ISO8601Format(),
                        timerDuration: $0.dateInterval.duration.rounded()
                    )
                },
                manual: manual,
                activities: workout.workoutActivities.count,  // the swim, bike, and running portions of a multisport event, like a triathlon
                date: workout.startDate.ISO8601Format(),
                source: workout.sourceRevision.source.name,
                dataType: .workouts
            )
        }
    }

    // Helper function to calculate average speed (meters/second)
    func calculateAverageSpeed(distance: Double?, duration: TimeInterval) -> Double? {
        guard let distance = distance else { return nil }
        return distance / duration
    }
}

func getWorkoutWeather(workout: HKWorkout) -> Double? {
    if let metadata = workout.metadata {
        if let metaValue = metadata[HKMetadataKeyWeatherTemperature] {
            if let quantity = metaValue as? HKQuantity {
                let value = quantity.doubleValue(for: HKUnit.degreeCelsius())
                print(value)
                return value
            }
        }
    }
    return nil
}

func getWorkoutWeatherHumidity(workout: HKWorkout) -> Double? {
    if let metadata = workout.metadata {
        if let metaValue = metadata[HKMetadataKeyWeatherHumidity] {
            if let quantity = metaValue as? HKQuantity {
                let value = quantity.doubleValue(for: HKUnit.percent())
                print("getWorkoutWeatherHumidity \(value)")
                return value
            }
        }
    }
    return nil
}

func getWorkoutWeatherCondition(workout: HKWorkout) -> String? {
    if let metadata = workout.metadata {
        if let metaValue = metadata[HKMetadataKeyWeatherCondition] {
            print("mataCondition \(metaValue)")
            if let value = metaValue as? HKWeatherCondition {
                return "\(value)"
            }
        }
    }
    return nil
}

func getWorkoutAverageSpeed(workout: HKWorkout) -> Double? {
    if let metadata = workout.metadata {
        if let metaValue = metadata[HKMetadataKeyAverageSpeed] {
            if let quantity = metaValue as? HKQuantity {
                let value = quantity.doubleValue(for: .meter().unitDivided(by: .second()))
                print("getWorkoutAverageSpeed \(value)")
                return value
            }
        }
    }
    return nil
}

func getWorkoutMaximumSpeed(workout: HKWorkout) -> Double? {
    if let metadata = workout.metadata {
        if let metaValue = metadata[HKMetadataKeyMaximumSpeed] {
            if let quantity = metaValue as? HKQuantity {
                let value = quantity.doubleValue(for: .meter().unitDivided(by: .second()))
                print("getWorkoutMaximumSpeed \(value)")
                return value
            }
        }
    }
    return nil
}

func getWorkoutElevationAscended(workout: HKWorkout) -> Double? {
    if let metadata = workout.metadata {
        if let metaValue = metadata[HKMetadataKeyElevationAscended] {
            if let quantity = metaValue as? HKQuantity {
                let value = quantity.doubleValue(for: .meter())
                print("getWorkoutElevationAscended \(value)")
                return value
            }
        }
    }
    return nil
}

func getWorkoutElevationDescended(workout: HKWorkout) -> Double? {
    if let metadata = workout.metadata {
        if let metaValue = metadata[HKMetadataKeyElevationDescended] {
            if let quantity = metaValue as? HKQuantity {
                let value = quantity.doubleValue(for: .meter())
                print("getWorkoutElevationDescended \(value)")
                return value
            }
        }
    }
    return nil
}

//func getWorkoutAlpineSlopeGrade(workout: HKWorkout) -> Double? {
//    if let metadata = workout.metadata {
//        if let  metaValue = metadata[HKMetadataKeyAlpineSlopeGrade] {
//            if let quantity = metaValue as? HKQuantity {
//                let value = quantity.doubleValue(for: .meter())
//                print("getWorkoutAlpineSlopeGrade \(value)")
//                return value
//            }
//        }
//    }
//    return nil
//}

func getWorkoutHeartRateEventThreshold(workout: HKWorkout) -> Double? {
    if let metadata = workout.metadata {
        print("metadata")
        print(metadata)
        if let metaValue = metadata[HKMetadataKeyHeartRateEventThreshold] {
            if let quantity = metaValue as? HKQuantity {
                let value = quantity.doubleValue(for: .count().unitDivided(by: .minute()))
                print("getWorkoutHeartRateEventThreshold \(value)")
                print(value)
                return value
            }
        }
    }
    return nil
}

func getWorkoutAverageMETs(workout: HKWorkout) -> Double? {

    if let metadata = workout.metadata {
        if let metaValue = metadata[HKMetadataKeyAverageMETs] {  // HKAverageMETs
            if let quantity = metaValue as? HKQuantity {
                let value = quantity.doubleValue(
                    for: .kilocalorie().unitDivided(
                        by: .hour().unitMultiplied(by: .gramUnit(with: .kilo)))
                )  // kcal/hr·k // HKUnit(from: "kcal/(hr*k)")
                print("getWorkoutAverageMETs \(value)")  // kcal/hr·kg
                return value
            }
        }
    }
    return nil
}
