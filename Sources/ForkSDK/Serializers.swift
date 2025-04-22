// :nodoc:
//  Serializers.swift
//  kingstinct-react-native-healthkit
//
//  Created by Robert Herber on 2023-05-31.
//

import Foundation
import HealthKit

let _dateFormatter = ISO8601DateFormatter()

func serialezeCategorySamples(from: Date, to: Date, samples: [HKSample]?) -> [ForkDataItem] {

    func valueToString(value: Int) -> String {
        switch value {
        case HKCategoryValueSleepAnalysis.inBed.rawValue:
            return "InBed"
        case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
            return "Asleep"
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

    var data: [ForkDataQuantity] = []
    var startDate = from
    var endDate = to

    var device: [String: String?]?

    if let samples = samples {
        for sample in samples as? [HKCategorySample] ?? [] {
            device = serializeDevice(_device: sample.device)
            if startDate < sample.startDate {
                startDate = sample.startDate
            }
            if endDate > sample.endDate {
                endDate = sample.endDate
            }
            data.append(
                ForkDataQuantity(
                    startDate: sample.startDate,
                    endDate: sample.endDate,
                    value: ForkDataQuantityValue(
                        quantity: Double(sample.value), unit: valueToString(value: sample.value)),
                    type: "\(sample.categoryType)"
                )
            )
        }
    }

    return [
        ForkDataItem(
            name: "sleep",
            startDate: startDate,
            endDate: endDate,
            data: ["sleep": data],
            metaData: [:],
            nestedData: [:],
            device: device
        )
    ]
}

func serialezeSamples(samples: [HKSample]?) -> [ForkDataItem] {

    let durationFormatter = DateComponentsFormatter()
    durationFormatter.unitsStyle = .positional  // .abbreviated
    durationFormatter.allowedUnits = [.hour, .minute, .second]
    durationFormatter.zeroFormattingBehavior = [.pad]

    var items = [ForkDataItem]()
    if let workouts = samples {
        for workout in workouts as? [HKWorkout] ?? [] {

            let startDate = workout.startDate
            let endDate = workout.endDate
            var data: [String: [ForkDataQuantity]] = [:]
            var nestedData: [String: [ForkDataItem]] = [:]
            var metaData: [String: ForkDataQuantityValue] = [:]
            metaData["duration"] = ForkDataQuantityValue(
                quantity: workout.duration, unit: "TimeInterval")  //  durationFormatter.string(from: workout.duration)

            for workoutActivity in workout.workoutActivities {
                let activityData = serializeStatisticsDictionary(
                    startDate: workoutActivity.startDate,
                    endDate: workoutActivity.endDate ?? workoutActivity.startDate,
                    allStatistics: workoutActivity.allStatistics
                )
                let acitvityMetaData = serializeQuantityToForkQuantity(
                    metadata: workoutActivity.metadata)
                var acitvityNestedData: [String: [ForkDataItem]] = [:]

                nestedData["workoutActivity_\(workoutActivity.uuid)"] = []
                var workoutEventsItems: [ForkDataItem] = []
                for workoutEvent in workoutActivity.workoutEvents {
                    workoutEventsItems.append(
                        ForkDataItem(
                            name: workoutEvent.type.stringRepresentation,
                            startDate: workoutEvent.dateInterval.start,
                            endDate: workoutEvent.dateInterval.end,
                            data: [:],
                            metaData: serializeQuantityToForkQuantity(
                                metadata: workoutEvent.metadata),
                            nestedData: nil,
                            source: nil
                        )
                    )
                }
                acitvityNestedData["workoutEvents"] = workoutEventsItems

                nestedData["workoutActivity_\(workoutActivity.uuid)"]?.append(
                    ForkDataItem(
                        name: "workoutActivity_\(workoutActivity.uuid)",
                        startDate: workoutActivity.startDate,
                        endDate: workoutActivity.endDate ?? workoutActivity.startDate,
                        data: activityData,
                        metaData: acitvityMetaData,
                        nestedData: acitvityNestedData,
                        source: nil
                    )
                )
            }

            let workoutMetadata = serializeQuantityToForkQuantity(metadata: workout.metadata)
            metaData.merge(workoutMetadata) { (current, _) in current }

            let workoutData = serializeStatisticsDictionary(
                startDate: startDate, endDate: endDate, allStatistics: workout.allStatistics)
            data.merge(workoutData) { (current, _) in current }

            items.append(
                ForkDataItem(
                    id: workout.uuid,
                    name: workout.workoutActivityType.commonName,
                    startDate: startDate,
                    endDate: endDate,
                    data: data,
                    metaData: metaData,
                    nestedData: nestedData,
                    device: serializeDevice(_device: workout.device)
                )
            )
        }
    }
    return items
}

func serializeQuantitySamples(
    fromDate: Date,
    toDate: Date,
    options: HKStatisticsOptions = [],
    samples: [HKSample]?
) -> [ForkDataItem] {
    var dataItems = [ForkDataItem]()

    Log("serializeQuantitySamples", onLevel: .debug)

    if let samples = samples as? [HKQuantitySample] {
        for sample in samples {
            var statisticsData: [String: [ForkDataQuantity]] = [:]
            statisticsData["sample_\(sample.hashValue)"] = [
                ForkDataQuantity(
                    startDate: sample.startDate,
                    endDate: sample.endDate,
                    value: serializeQuantity(
                        unit: HKUnit(from: "count/min"), quantity: sample.quantity),
                    type: "quantity"
                )
            ]

            dataItems.append(
                ForkDataItem(
                    name: "statistics_\(sample.hashValue)",
                    startDate: sample.startDate,
                    endDate: sample.endDate,
                    data: statisticsData,
                    metaData: [:],
                    device: serializeDevice(_device: sample.device)
                )
            )
        }
    }
    return dataItems
}

func serializeDiscreteQuantitySamples(
    fromDate: Date,
    toDate: Date,
    options: HKStatisticsOptions = [],
    samples: [HKSample]?
) -> [ForkDataItem] {
    var dataItems = [ForkDataItem]()

    Log("serializeDiscreteQuantitySamples", onLevel: .debug)

    if let samples = samples as? [HKDiscreteQuantitySample] {
        for sample in samples {

            // This is a series. We need a single sample
            if sample.count > 1 {
                Log("This is a series.. skipping", onLevel: .debug)
                continue
            }

            var statisticsData: [String: [ForkDataQuantity]] = [:]
            var quantities: [ForkDataQuantity] = []

            if options.contains(.discreteAverage) {
                Log(
                    "serializeDiscreteQuantitySamples enumerateStatistics options contain avg",
                    onLevel: .debug)
                let quantityData = ForkDataQuantity(
                    startDate: sample.startDate,
                    endDate: sample.endDate,
                    value: serializeQuantity(
                        unit: HKUnit(from: "count/min"), quantity: sample.averageQuantity),
                    type: "avg"
                )
                quantities.append(quantityData)
                Log(
                    "serializeStatisticsCollection enumerateStatistics options avg", onLevel: .debug
                )

            }
            if options.contains(.discreteMin) {
                Log(
                    "serializeDiscreteQuantitySamples enumerateStatistics options contain min",
                    onLevel: .debug)
                let quantityData = ForkDataQuantity(
                    startDate: sample.startDate,
                    endDate: sample.endDate,
                    value: serializeQuantity(
                        unit: HKUnit(from: "count/min"), quantity: sample.minimumQuantity),
                    type: "min"
                )
                quantities.append(quantityData)
                Log(
                    "serializeStatisticsCollection enumerateStatistics options min \(sample.minimumQuantity)",
                    onLevel: .debug)
            }
            if options.contains(.discreteMax) {
                Log(
                    "serializeDiscreteQuantitySamples enumerateStatistics options contain max",
                    onLevel: .debug)
                let quantityData = ForkDataQuantity(
                    startDate: sample.startDate,
                    endDate: sample.endDate,
                    value: serializeQuantity(
                        unit: HKUnit(from: "count/min"), quantity: sample.maximumQuantity),
                    type: "max"
                )
                quantities.append(quantityData)
                Log(
                    "serializeStatisticsCollection enumerateStatistics options max \(sample.maximumQuantity)",
                    onLevel: .debug)
            }
            if options.contains(.duration) {
                Log(
                    "serializeDiscreteQuantitySamples enumerateStatistics options contain duration",
                    onLevel: .debug)
                let quantityData = ForkDataQuantity(
                    startDate: sample.startDate,
                    endDate: sample.endDate,
                    value: serializeQuantity(
                        unit: HKUnit(from: "count/min"), quantity: sample.quantity),  // HKUnit.minute()
                    type: "duration"
                )
                quantities.append(quantityData)
                Log(
                    "serializeStatisticsCollection enumerateStatistics options duration",
                    onLevel: .debug)

            }
            statisticsData["sample_\(sample.hashValue)"] = quantities

            Log("sample \(sample.hashValue) has \(quantities.count) quantities", onLevel: .debug)

            dataItems.append(
                ForkDataItem(
                    name: "statistics_\(sample.hashValue)",
                    startDate: sample.startDate,
                    endDate: sample.endDate,
                    data: statisticsData,
                    metaData: [:],
                    nestedData: nil,
                    source: nil
                )
            )
        }
    }

    return dataItems

}

// Statistics are classified as discrete or cumulative.  If a discrete statistics option is specified for a
// cumulative HKQuantityType, an exception will be thrown.  If a cumulative statistics options is specified
// for a discrete HKQuantityType, an exception will also be thrown.
func serializeStatisticsCollection(
    fromDate: Date,
    toDate: Date,
    options: HKStatisticsOptions = [],
    unit: HKUnit = .count(),
    statisticsCollection: HKStatisticsCollection?
) -> [ForkDataItem] {
    var dataItems = [ForkDataItem]()

    if let statisticsCollection = statisticsCollection {

        statisticsCollection.enumerateStatistics(from: fromDate, to: toDate) { (statistics, stop) in
            Log("serializeStatisticsCollection enumerateStatistics", onLevel: .debug)

            // It is possible to switch (statistics.quantityType) to understand what kind of statistic should be available
            // Example for statistics.quantityType: HKQuantityTypeIdentifierStepCount - "cumulativeSum" should be available

            var statisticsData: [String: [ForkDataQuantity]]
            if options.isEmpty {
                Log(
                    "serializeStatisticsCollection enumerateStatistics serializeStatisticsDictionary",
                    onLevel: .debug)
                statisticsData = serializeStatisticsDictionary(
                    startDate: statistics.startDate,
                    endDate: statistics.endDate,
                    allStatistics: [statistics.quantityType: statistics]
                )
            } else {
                Log("serializeStatisticsCollection enumerateStatistics options", onLevel: .debug)

                statisticsData = [:]
                var quantities: [ForkDataQuantity] = []
                if options.contains(.cumulativeSum) {
                    Log(
                        "serializeStatisticsCollection enumerateStatistics options contain sum",
                        onLevel: .debug)
                    if let sumQuantity = statistics.sumQuantity() {
                        let quantityData = ForkDataQuantity(
                            startDate: statistics.startDate,
                            endDate: statistics.endDate,
                            value: serializeQuantity(unit: unit, quantity: sumQuantity),
                            type: "sum"
                        )
                        quantities.append(quantityData)
                        Log(
                            "serializeStatisticsCollection enumerateStatistics options sum",
                            onLevel: .debug)
                    }
                }
                if options.contains(.discreteAverage) {
                    Log(
                        "serializeStatisticsCollection enumerateStatistics options contain avg",
                        onLevel: .debug)
                    if let averageQuantity = statistics.averageQuantity() {
                        let quantityData = ForkDataQuantity(
                            startDate: statistics.startDate,
                            endDate: statistics.endDate,
                            value: serializeQuantity(unit: unit, quantity: averageQuantity),
                            type: "avg"
                        )
                        quantities.append(quantityData)
                        Log(
                            "serializeStatisticsCollection enumerateStatistics options avg",
                            onLevel: .debug)
                    }
                }
                if options.contains(.discreteMax) {
                    Log(
                        "serializeStatisticsCollection enumerateStatistics options contain mmax",
                        onLevel: .debug)
                    if let maximumQuantity = statistics.maximumQuantity() {
                        let quantityData = ForkDataQuantity(
                            startDate: statistics.startDate,
                            endDate: statistics.endDate,
                            value: serializeQuantity(unit: unit, quantity: maximumQuantity),
                            type: "max"
                        )
                        quantities.append(quantityData)
                        Log(
                            "serializeStatisticsCollection enumerateStatistics options max",
                            onLevel: .debug)
                    }
                }
                if options.contains(.discreteMin) {
                    Log(
                        "serializeStatisticsCollection enumerateStatistics options contain min",
                        onLevel: .debug)
                    if let minimumQuantity = statistics.minimumQuantity() {
                        let quantityData = ForkDataQuantity(
                            startDate: statistics.startDate,
                            endDate: statistics.endDate,
                            value: serializeQuantity(unit: unit, quantity: minimumQuantity),
                            type: "min"
                        )
                        quantities.append(quantityData)
                        Log(
                            "serializeStatisticsCollection enumerateStatistics options min",
                            onLevel: .debug)
                    }
                }
                if options.contains(.duration) {
                    Log(
                        "serializeStatisticsCollection enumerateStatistics options contain duration",
                        onLevel: .debug)
                    if let duration = statistics.duration() {
                        let quantityData = ForkDataQuantity(
                            startDate: statistics.startDate,
                            endDate: statistics.endDate,
                            value: serializeQuantity(unit: HKUnit.minute(), quantity: duration),
                            type: "duration"
                        )
                        quantities.append(quantityData)
                        Log(
                            "serializeStatisticsCollection enumerateStatistics options duration",
                            onLevel: .debug)
                    }
                }
                statisticsData["statistics_\(statistics.hashValue)"] = quantities
            }

            dataItems.append(
                ForkDataItem(
                    name: "statistics_\(statistics.hashValue)",
                    startDate: statistics.startDate,
                    endDate: statistics.endDate,
                    data: statisticsData,
                    metaData: [:],
                    nestedData: nil,
                    source: serializeSources(sources: statistics.sources)
                )
            )
        }
    }

    return dataItems

}

func serializeStatisticsDictionary(
    startDate: Date, endDate: Date, allStatistics: [HKQuantityType: HKStatistics]
) -> [String: [ForkDataQuantity]] {
    var data: [String: [ForkDataQuantity]] = [:]
    for (type, statistics) in allStatistics {

        if let sumQuantity = statistics.sumQuantity(),
            let value = serializeUnknownQuantity(quantity: sumQuantity)
        {
            data[type.identifier] = [
                ForkDataQuantity(startDate: startDate, endDate: endDate, value: value)
            ]
        }
        if let averageQuantity = statistics.averageQuantity(),
            let value = serializeUnknownQuantity(quantity: averageQuantity)
        {
            data[type.identifier] = [
                ForkDataQuantity(startDate: startDate, endDate: endDate, value: value)
            ]
        }
        if let minimumQuantity = statistics.minimumQuantity(),
            let value = serializeUnknownQuantity(quantity: minimumQuantity)
        {
            data[type.identifier] = [
                ForkDataQuantity(startDate: startDate, endDate: endDate, value: value)
            ]
        }
        if let maximumQuantity = statistics.maximumQuantity(),
            let value = serializeUnknownQuantity(quantity: maximumQuantity)
        {
            data[type.identifier] = [
                ForkDataQuantity(startDate: startDate, endDate: endDate, value: value)
            ]
        }
        if let duration = statistics.duration(),
            let value = serializeUnknownQuantity(quantity: duration)
        {
            data[type.identifier] = [
                ForkDataQuantity(startDate: startDate, endDate: endDate, value: value)
            ]
        }
    }
    return data
}

func serializeQuantity(unit: HKUnit, quantity: HKQuantity) -> ForkDataQuantityValue {
    return ForkDataQuantityValue(quantity: quantity.doubleValue(for: unit), unit: unit.unitString)
}

func serializeSources(sources: [HKSource]?) -> [ForkDataSource]? {
    guard let sources = sources else {
        return nil
    }
    return sources.map({ source in
        ForkDataSource(name: source.name, bundleIdentifier: source.bundleIdentifier)
    })
}

func serializeQuantityToForkQuantity(metadata: [String: Any]?) -> [String: ForkDataQuantityValue] {
    var serialized: [String: ForkDataQuantityValue] = [:]
    if let m = metadata {
        for item in m {
            if let bool = item.value as? Bool {
                serialized[item.key] = ForkDataQuantityValue(quantity: bool ? 1 : 0, unit: "bool")
            } else if let value = item.value as? Int {
                serialized[item.key] = ForkDataQuantityValue(quantity: Double(value), unit: "int")
            } else if let double = item.value as? Double {
                serialized[item.key] = ForkDataQuantityValue(quantity: double, unit: "double")
            } else if let str = item.value as? String {
                serialized[item.key] = ForkDataQuantityValue(quantity: 0, unit: str)
            } else if let value = item.value as? TimeInterval {
                serialized[item.key] = ForkDataQuantityValue(quantity: value, unit: "TimeInterval")
            }

            if let quantity = item.value as? HKQuantity {
                if let s = serializeUnknownQuantity(quantity: quantity) {
                    serialized[item.key] = s
                }
            }
        }
    }
    return serialized
}

func serializeQuantitySample(sample: HKQuantitySample, unit: HKUnit) -> NSDictionary {
    let endDate = _dateFormatter.string(from: sample.endDate)
    let startDate = _dateFormatter.string(from: sample.startDate)

    let quantity = sample.quantity.doubleValue(for: unit)

    return [
        "uuid": sample.uuid.uuidString,
        "device": serializeDevice(_device: sample.device) as Any,
        "quantityType": sample.quantityType.identifier,
        "endDate": endDate,
        "startDate": startDate,
        "quantity": quantity,
        "unit": unit.unitString,
        "metadata": serializeMetadata(metadata: sample.metadata),
        "sourceRevision": serializeSourceRevision(_sourceRevision: sample.sourceRevision) as Any,
    ]
}

func serializeDeletedSample(sample: HKDeletedObject) -> NSDictionary {
    return [
        "uuid": sample.uuid.uuidString,
        "metadata": serializeMetadata(metadata: sample.metadata),
    ]
}

func serializeCategorySample(sample: HKCategorySample) -> NSDictionary {
    let endDate = _dateFormatter.string(from: sample.endDate)
    let startDate = _dateFormatter.string(from: sample.startDate)

    return [
        "uuid": sample.uuid.uuidString,
        "device": serializeDevice(_device: sample.device) as Any,
        "categoryType": sample.categoryType.identifier,
        "endDate": endDate,
        "startDate": startDate,
        "value": sample.value,
        "metadata": serializeMetadata(metadata: sample.metadata),
        "sourceRevision": serializeSourceRevision(_sourceRevision: sample.sourceRevision) as Any,
    ]
}

func serializeSource(source: HKSource) -> NSDictionary {

    return [
        "bundleIdentifier": source.bundleIdentifier,
        "name": source.name,
    ]
}

func serializeUnknownQuantity(quantity: HKQuantity) -> ForkDataQuantityValue? {
    if quantity.is(compatibleWith: HKUnit.percent()) {
        return serializeQuantity(unit: HKUnit.percent(), quantity: quantity)
    }

    if quantity.is(compatibleWith: HKUnit.second()) {
        return serializeQuantity(unit: HKUnit.second(), quantity: quantity)
    }

    if quantity.is(compatibleWith: HKUnit.kilocalorie()) {
        return serializeQuantity(unit: HKUnit.kilocalorie(), quantity: quantity)
    }

    if quantity.is(compatibleWith: HKUnit.count()) {
        return serializeQuantity(unit: HKUnit.count(), quantity: quantity)
    }

    if quantity.is(compatibleWith: HKUnit.meter()) {
        return serializeQuantity(unit: HKUnit.meter(), quantity: quantity)
    }

    if #available(iOS 11, *) {
        if quantity.is(compatibleWith: HKUnit.internationalUnit()) {
            return serializeQuantity(unit: HKUnit.internationalUnit(), quantity: quantity)
        }
    }

    if #available(iOS 13, watchOS 6.0, *) {
        if quantity.is(compatibleWith: HKUnit.hertz()) {
            return serializeQuantity(unit: HKUnit.hertz(), quantity: quantity)
        }

        if quantity.is(compatibleWith: HKUnit.decibelHearingLevel()) {
            return serializeQuantity(unit: HKUnit.decibelHearingLevel(), quantity: quantity)
        }
    }

    if quantity.is(compatibleWith: HKUnit(from: "m/s")) {  // HKUnit.meter().unitDivided(by: HKUnit.second())
        return serializeQuantity(unit: HKUnit(from: "m/s"), quantity: quantity)
    }

    if quantity.is(compatibleWith: HKUnit(from: "kcal/hr·kg")) {  // MET data: HKAverageMETs 8.24046 kcal/hr·kg
        return serializeQuantity(unit: HKUnit(from: "kcal/hr·kg"), quantity: quantity)
    }

    return nil
}

func serializeMetadata(metadata: [String: Any]?) -> NSDictionary {
    let serialized: NSMutableDictionary = [:]
    if let m = metadata {
        for item in m {
            if let bool = item.value as? Bool {
                serialized.setValue(bool, forKey: item.key)
            }
            if let str = item.value as? String {
                serialized.setValue(str, forKey: item.key)
            }

            if let double = item.value as? Double {
                serialized.setValue(double, forKey: item.key)
            }
            if let quantity = item.value as? HKQuantity {
                if let s = serializeUnknownQuantity(quantity: quantity) {
                    serialized.setValue(s, forKey: item.key)
                }
            }
        }
    }
    return serialized
}

func serializeDevice(_device: HKDevice?) -> [String: String?]? {
    guard let device = _device else {
        return nil
    }

    return [
        "name": device.name,
        "firmwareVersion": device.firmwareVersion,
        "hardwareVersion": device.hardwareVersion,
        "localIdentifier": device.localIdentifier,
        "manufacturer": device.manufacturer,
        "model": device.model,
        "softwareVersion": device.softwareVersion,
        "udiDeviceIdentifier": device.udiDeviceIdentifier,
    ]
}

func serializeOperatingSystemVersion(_version: OperatingSystemVersion?) -> String? {
    guard let version = _version else {
        return nil
    }

    let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

    return versionString
}

func serializeSourceRevision(_sourceRevision: HKSourceRevision?) -> [String: Any?]? {
    guard let sourceRevision = _sourceRevision else {
        return nil
    }

    var dict =
        [
            "source": [
                "name": sourceRevision.source.name,
                "bundleIdentifier": sourceRevision.source.bundleIdentifier,
            ],
            "version": sourceRevision.version as Any,
        ] as [String: Any]

    if #available(iOS 11, *) {
        dict["operatingSystemVersion"] = serializeOperatingSystemVersion(
            _version: sourceRevision.operatingSystemVersion)
        dict["productType"] = sourceRevision.productType
    }

    return dict
}

func deserializeHKQueryAnchor(anchor: String) -> HKQueryAnchor? {
    return anchor.isEmpty ? nil : base64StringToHKQueryAnchor(base64String: anchor)
}

func serializeAnchor(anchor: HKQueryAnchor?) -> String? {
    guard let anch = anchor else {
        return nil
    }

    do {
        let data = try NSKeyedArchiver.archivedData(
            withRootObject: anch, requiringSecureCoding: true)
        let encoded = data.base64EncodedString()

        return encoded
    } catch {
        return nil
    }
}

func base64StringToHKQueryAnchor(base64String: String) -> HKQueryAnchor? {

    guard let data = Data(base64Encoded: base64String) else {
        Log("Error: Invalid base64 string", onLevel: .error)
        return nil
    }

    do {
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = true

        let anchor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)

        return anchor as? HKQueryAnchor
    } catch {
        Log("Error: Unable to unarchive HKQueryAnchor object: \(error)", onLevel: .error)
        return nil
    }
}
