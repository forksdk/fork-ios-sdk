//
//  Extensions+HKElectrocardiogram.swift
//  HealthKitReporter
//
//  Created by Victor on 24.09.20.
//

import HealthKit

@available(iOS 14.0, *)
extension HKElectrocardiogram {
    typealias Serialized = Electrocardiogram.Serialized

    func serialize(voltageMeasurements: [Electrocardiogram.VoltageMeasurement]) throws -> Serialized {
        let averageHeartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        let averageHeartRate = averageHeartRate?.doubleValue(for: averageHeartRateUnit)
        let samplingFrequencyUnit = HKUnit.hertz()
        guard
            let samplingFrequency = samplingFrequency?.doubleValue(for: samplingFrequencyUnit)
        else {
            throw ForkError.invalidValue(
                "Invalid samplingFrequency value for HKElectrocardiogram"
            )
        }
        return Serialized(
            averageHeartRate: averageHeartRate,
            averageHeartRateUnit: averageHeartRateUnit.unitString,
            samplingFrequency: samplingFrequency,
            samplingFrequencyUnit: samplingFrequencyUnit.unitString,
            classification: classification.description,
            symptomsStatus: symptomsStatus.description,
            count: numberOfVoltageMeasurements,
            voltageMeasurements: voltageMeasurements,
            metadata: metadata?.asMetadata
        )
    }
}

@available(iOS 14.0, *)
extension HKElectrocardiogram.VoltageMeasurement: Serializable {
    typealias Serialized = Electrocardiogram.VoltageMeasurement.Serialized

    func serialize() throws -> Serialized {
        guard
            let quantitiy = quantity(for: .appleWatchSimilarToLeadI)
        else {
            throw ForkError.invalidValue(
                "Invalid averageHeartRate value for HKElectrocardiogram"
            )
        }
        let unit = HKUnit.volt()
        let voltage = quantitiy.doubleValue(for: unit)
        return Serialized(value: voltage, unit: unit.unitString)
    }
}
// MARK: - CustomStringConvertible
@available(iOS 14.0, *)
extension HKElectrocardiogram.Classification: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notSet:
            return "na"
        case .sinusRhythm:
            return "Sinus rhytm"
        case .atrialFibrillation:
            return "Atrial fibrillation"
        case .inconclusiveLowHeartRate:
            return "Inconclusive low heart rate"
        case .inconclusiveHighHeartRate:
            return "Inconclusive high heart rate"
        case .inconclusivePoorReading:
            return "Inconclusive poor reading"
        case .inconclusiveOther:
            return "Inconclusive other"
        case .unrecognized:
            return "Unrecognized"
        @unknown default:
            fatalError()
        }
    }
}
// MARK: - CustomStringConvertible
@available(iOS 14.0, *)
extension HKElectrocardiogram.SymptomsStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notSet:
            return "na"
        case .none:
            return "None"
        case .present:
            return "Present"
        @unknown default:
            fatalError()
        }
    }
}
