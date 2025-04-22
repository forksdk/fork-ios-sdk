//
//  ForkTransformerProtocol.swift
//
//
//  Created by Aleksandras Gaidamausas on 30/07/2024.
//

import Foundation
import HealthKit

public protocol ForkTransformerProtocol {}

public protocol ForkGenericTransformerProtocol: ForkTransformerProtocol {

    associatedtype T

    func transformSamples(samples: [HKSample]?) -> T

    func serialezeCategorySamples(from: Date, to: Date, samples: [HKSample]?) -> T

    func serializeStatisticsCollection(
        fromDate: Date,
        toDate: Date,
        options: HKStatisticsOptions,
        unit: HKUnit,
        statisticsCollection: HKStatisticsCollection?
    ) -> T

    func serializeDiscreteQuantitySamples(
        fromDate: Date,
        toDate: Date,
        options: HKStatisticsOptions,
        samples: [HKSample]?
    ) -> T

    //    func transformQuantitySamples(samples: [HKQuantitySample], for dataType: String) -> [[String: Any]]
}
