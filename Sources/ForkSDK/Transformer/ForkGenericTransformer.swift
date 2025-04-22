//
//  ForkGenericTransformer.swift
//
//
//  Created by Aleksandras Gaidamausas on 05/08/2024.
//

import Foundation
import HealthKit

public class ForkGenericTransformer: ForkGenericTransformerProtocol {

    public func transformSamples(samples: [HKSample]?) -> [[String: Any]] {
        return []
    }

    public func serialezeCategorySamples(from: Date, to: Date, samples: [HKSample]?) -> [[String:
        Any]]
    {
        return []
    }

    public func serializeStatisticsCollection(
        fromDate: Date,
        toDate: Date,
        options: HKStatisticsOptions,
        unit: HKUnit,
        statisticsCollection: HKStatisticsCollection?
    ) -> [[String: Any]] {
        return []
    }

    public func serializeDiscreteQuantitySamples(
        fromDate: Date,
        toDate: Date,
        options: HKStatisticsOptions,
        samples: [HKSample]?
    ) -> [[String: Any]] {
        return []
    }

    public func transformSamples(samples: [HKQuantitySample], for dataType: String) -> [[String:
        Any]]
    {
        return samples.map { sample in
            [
                "data_type": dataType,
                "value": sample.quantity.doubleValue(for: HKUnit.count()),
                "unit": "count",
                "timestamp": ISO8601DateFormatter().string(from: sample.startDate),
                "source": "HealthKit",
            ]
        }
    }

}
