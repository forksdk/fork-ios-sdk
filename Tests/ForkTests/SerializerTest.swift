//
//  SerializerTest.swift
//
//
//  Created by Aleksandras Gaidamauskas on 25/04/2024.
//

import Foundation
import HealthKit


func recordSleep() {
    let now = Date()
    let startBed = Calendar.current.date(byAdding: .hour, value: -8, to: now)
    let startSleep = Calendar.current.date(byAdding: .minute, value: -470, to: now)
    let endSleep = Calendar.current.date(byAdding: .minute, value: -5, to: now)

    let sleepType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)
    let inBed = HKCategorySample.init(type: sleepType!, value: HKCategoryValueSleepAnalysis.inBed.rawValue, start: startBed!, end: now)
    let asleep = HKCategorySample.init(type: sleepType!, value: HKCategoryValueSleepAnalysis.asleep.rawValue, start: startSleep!, end: endSleep!)
//    healthStore.save([inBed, asleep]) { (success, error) in
//        if !success {
//            // Handle the error here.
//        } else {
//            print("Saved")
//        }
//    }
}

func getAverageHeartRate(forDate date: Date) {
    let cal = Calendar.current
    let startDate = cal.startOfDay(for: date)
    var comps = DateComponents()
    comps.day = 1
    comps.second = -1
    let endDate = cal.date(byAdding: comps, to: startDate)
    
    let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    let heartRateQuantity = HKQuantity(
        unit: HKUnit(from: "count/min"),
        doubleValue: Double(arc4random_uniform(80) + 100)
    )
    let heartSample = HKQuantitySample(
        type: heartRateType,
        quantity: heartRateQuantity,
        start: startDate,
        end: endDate!
    )
}


final class SerializerTest: XCTestCase {
    func testSerializeDiscreteQuantitySamples() throws {
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
        
//        func serializeDiscreteQuantitySamples(
//            fromDate: Date,
//            toDate: Date,
//            options: HKStatisticsOptions = [],
//            samples: [HKSample]?
//        ) -> [ForkDataItem] {
        
        
//        let sample = HKDiscreteQuantitySample(type: <#T##HKQuantityType#>, quantity: <#T##HKQuantity#>, start: <#T##Date#>, end: <#T##Date#>)
        
        XCTAssertEqual(table.rowCount, 0, "Row count was not zero.")
    }
}
