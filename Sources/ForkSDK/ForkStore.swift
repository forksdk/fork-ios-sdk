//
//  ForkStore.swift
//  
//
//  Created by Aleksandras Gaidamauskas on 15/04/2024.
//

import Foundation
import HealthKit
import MapKit


class ForkStore {
    
    var healthStore: HKHealthStore?
    
    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }
    
    public static func isHealthDataAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    
    /// - Parameters:
    ///   - readSet: The list of required data types
    func requestAuthorization(for readSet: Set<HKObjectType>, completion: @escaping (Bool) -> Void) {
        guard let healthStore = self.healthStore else { return completion(false) }
        healthStore.requestAuthorization(toShare: [], read: readSet) { (success, error) in
            completion(success)
        }
    }
    
    func requestWriteAuthorization(for writeSet: Set<HKSampleType>, completion: @escaping (Bool) -> Void) {
        guard let healthStore = self.healthStore else { return completion(false) }
        healthStore.requestAuthorization(toShare: writeSet, read: []) { (success, error) in
            completion(success)
        }
    }
    
    func getRequestStatusForAuthorization(for readSet: Set<HKObjectType>, completion: @escaping (Bool) -> Void) {
        guard let healthStore = self.healthStore else { return completion(false) }
        healthStore.getRequestStatusForAuthorization(toShare: [], read: readSet) { (authorizationRequestStatus, error) in
            completion(authorizationRequestStatus == .unnecessary)
        }
    }
    
    
    // If you plan on supporting background delivery, set up all your observer queries
    // in your app delegate’s application(_:didFinishLaunchingWithOptions:) method
    // https://developer.apple.com/documentation/healthkit/hkobserverquery/executing_observer_queries#1676781
    func setUpBackgroundDeliveryForDataTypes(for sampleTypes: Set<HKObjectType>) {
        for type in sampleTypes {
            guard let sampleType = type as? HKSampleType else {
                Log("ERROR: \(type) is not an HKSampleType", onLevel: .error)
                continue
            }
//            let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { [weak self] (query, completionHandler, error) in
            let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { (query, completionHandler, error) in
                guard error == nil else {
                    Log("Error: \(error!.localizedDescription)", onLevel: .error)
                    return
                }
//                guard let strongSelf = self else { return }
                // strongSelf.queryForUpdates(type)
                completionHandler()
            }
            if let healthStore = healthStore {
                healthStore.execute(query)
                healthStore.enableBackgroundDelivery(for: type, frequency: .immediate) { success, error in
                    guard error == nil else {
                        Log("Error: \(error!.localizedDescription)", onLevel: .error)
                        return
                    }
                    Log("enableBackgroundDeliveryForType handler called for \(type) ", onLevel: .info)
                }
            }
        }
    }
    
    
    func getWorkoutFor(uuidString: String?, completion: @escaping (Result<HKWorkout, ForkError>) -> Void) {
        guard let uuidString = uuidString,  let udid = UUID(uuidString: uuidString) else {
            Log("Error: UDID object cannot be created from \(uuidString ?? "")", onLevel: .error)
            completion(.failure(.generalError))
            return
        }
        
        let uuidPredicate = HKQuery.predicateForObject(with: udid)
        let query = HKSampleQuery(sampleType: .workoutType(),
                                  predicate: uuidPredicate,
                                  limit:  1,
                                  sortDescriptors: []
        ) { query, workoutSamples, error in
            
            guard error == nil else {
                Log("Error: \(error!.localizedDescription)", onLevel: .error)
                completion(.failure(.healthDataError))
                return
            }
            
            guard let workouts = workoutSamples as? [HKWorkout], let workout = workouts.first else {
                Log("Error: Cannt find workout by UDID \(uuidString)", onLevel: .error)
                completion(.failure(.healthDataError))
                return
            }
            
            completion(.success(workout))
        }
        
        if let healthStore = healthStore {
            healthStore.execute(query)
            //            self.runningQueries.updateValue(query, forKey: "workouts")
        }
    }
    
    
    // Async await versions
    /// - Throws: `SlothError.tooMuchFood` if the quantity is more than 100.
    func getWorkoutFor(uuidString: String?) async throws -> HKWorkout {
        return try await withCheckedThrowingContinuation { continuation in
            self.getWorkoutFor(uuidString: uuidString) { result in
                switch result {
                case .success(let workout):
                    continuation.resume(returning: workout)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func getActivitySummaryQuery(from: Date, to: Date, completion: @escaping ([HKActivitySummary]?) -> Void) {

        // HKQuery.predicateForActivitySummary(with: dateComponents)
        // HKQuery.predicate(forActivitySummariesBetweenStart: start, end: end)
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to, options: [.strictStartDate, .strictEndDate])
//        let predicate = HKQuery.predicate(forActivitySummariesBetweenStart: from, end: to)
        let query = HKActivitySummaryQuery.init(predicate: predicate) { (query, summaries, error) in
            
            guard error == nil else {
                Log("Error: \(error!.localizedDescription)", onLevel: .error)
                completion([])
                return
            }
            
            guard let summaries = summaries else {
                completion([])
                return
            }
            completion(summaries)
        }
        if let healthStore = healthStore {
            healthStore.execute(query)
        }
    }
    
    func getCharacteristics(characteristics: [ForkCharacteristicTypes],
                            completion: @escaping (Result<[ForkCharacteristicTypes: String], ForkError>) -> Void) {
        
        guard let healthStore = healthStore else {
            print("*** unable to get healthStore. ***")
            completion(.failure(.generalError))
            return
        }

        do {
            var result: [ForkCharacteristicTypes: String] = [:]
            
            for characteristic in characteristics {
                switch characteristic {
                case .dateOfBirth:
                    // This method throws an error if these data are not available.
                    let birthdayComponents = try healthStore.dateOfBirthComponents()
                    
                    if let dateOfBirth = birthdayComponents.date {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        result[.dateOfBirth] = dateFormatter.string(from: dateOfBirth)
                    }
                case .ageYears:
                    // This method throws an error if these data are not available.
                    let birthdayComponents = try healthStore.dateOfBirthComponents()
                    
                    // Use Calendar to calculate age.
                    let today = Date()
                    let calendar = Calendar.current
                    let todayDateComponents = calendar.dateComponents([.year],
                                                                      from: today)
                    let thisYear = todayDateComponents.year!
                    let age = thisYear - birthdayComponents.year!
                    result[.ageYears] = "\(age)"

                case .biologicalSex:
                    let biologicalSex = try healthStore.biologicalSex()
                    result[.biologicalSex] = "\(biologicalSex.biologicalSex)"
                case .bloodType:
                    let bloodType = try healthStore.bloodType()
                    result[.bloodType] = "\(bloodType.bloodType)"
                case .skinType:
                    let skinType = try healthStore.fitzpatrickSkinType()
                    result[.skinType] = "\(skinType.skinType)"
                case .weelchairUse:
                    let wheelchairUse = try healthStore.wheelchairUse()
                    result[.weelchairUse] = "\(wheelchairUse.wheelchairUse)"
                }
            }
            
            completion(.success(result))
            
        } catch {
            completion(.failure(.generalError))
            return
        }
    }
    
    func getWorkoutEvents(uuidString: String, completion: @escaping ([HKWorkoutEvent]?, [HKWorkoutActivity]?) -> Void) {
        
        getWorkoutFor(uuidString: uuidString) { workoutResult in
            
            let workout: HKWorkout
            do {
                workout = try workoutResult.get()
                completion(workout.workoutEvents, workout.workoutActivities)
                return
            } catch {
                Log("Error: Cannot get workout by UDID \(uuidString)", onLevel: .error)
                completion(nil, nil)
                return
            }
        }
    }
    
    func getWorkoutRoute(uuidString: String, completion: @escaping ([HKWorkoutRoute]?) -> Void) {
        
        getWorkoutFor(uuidString: uuidString) { workoutResult in
            
            let workout: HKWorkout
            do {
                workout = try workoutResult.get()
            } catch {
                Log("Error: Cannot get workout by UDID \(uuidString)", onLevel: .error)
                completion([])
                return
            }
            
            
            let workoutPredicate = HKQuery.predicateForObjects(from: workout)
            
            let query = HKAnchoredObjectQuery(
                type: HKSeriesType.workoutRoute(),
                predicate: workoutPredicate,
                anchor: nil,
                limit: HKObjectQueryNoLimit,
                resultsHandler: { (query, samples, deletedObjects, anchor, error) in
                
                
                guard error == nil else {
                    Log("Error: \(error!.localizedDescription)", onLevel: .error)
                    completion([])
                    return
                }
                
                guard let samples = samples else {
                    completion([])
                    return
                }
                
                if (samples.count == 0) {
                    completion([])
                }
                
                guard let routes = samples as? [HKWorkoutRoute] else {
                    completion([])
                    return
                }
                
                completion(routes)
            })
            
            if let healthStore = self.healthStore {
                healthStore.execute(query)
            }
        }
    }

    // Our route doesn't contain a lot of information yet, so we need to load the locations associated with it.
    // Because a route may contain multiple thousands of locations, we load those in batches and return only once we have a complete list of locations.
    // Depending on the activities your application will interact with, you should really test this for performance hits.
    //
    // An app must save a workout before associating route data with it.
    // This means there is a brief period when the workout exists in the HealthKit store, but it doesn’t yet have a route sample associated with it.
    func getLocationDataForRoute(givenRoute: HKWorkoutRoute, completion: @escaping ([CLLocation]?) -> Void) {
        var allLocations: [CLLocation] = []
        
        let query = HKWorkoutRouteQuery(route: givenRoute) { query, locations, done, error in
            guard error == nil else {
                Log("Error: \(error!.localizedDescription)", onLevel: .error)
                completion([])
                return
            }
            
            if let locations = locations {
                allLocations.append(contentsOf: locations)
            }

            if done {
                // The query returned all the location data associated with the route.
                // Do something with the complete data set.
                completion(allLocations)
            }
        }
        
        if let healthStore = healthStore {
            healthStore.execute(query)
        }
    }
    
    /// - Throws: `ForkError.healthDataError` if the healthStore is not available.
    func getSleepAnalysisAsync(from: Date, to: Date) async throws -> [HKSample] {
        
        let stagePredicate = HKCategoryValueSleepAnalysis.predicateForSamples(equalTo: HKCategoryValueSleepAnalysis.allAsleepValues)
//        let stagePredicate = HKCategoryValueSleepAnalysis.predicateForSamples(.equalTo, value: HKCategoryValueSleepAnalysis.allAsleepValues)
        let queryPredicate = HKSamplePredicate.sample(
            type: HKCategoryType(.sleepAnalysis),
            predicate: stagePredicate
        )
        
        let query = HKSampleQueryDescriptor(predicates: [queryPredicate], sortDescriptors: [])
        
        if let healthStore = self.healthStore {
            let samples = try await query.result(for: healthStore)
            return samples
        }
        throw ForkError.healthDataError
    }
    
    func getSleepAnalysis<T: Codable>(
        from: Date, to: Date,
        serialize: @escaping ([HKSample]?) -> T?,
        completion: @escaping (T?) -> Void
    ) {
        Log("Retrieving Sleep Analysis", onLevel: .info)
        let dateRangePredicate = HKQuery.predicateForSamples(withStart: from, end: to, options: [.strictStartDate, .strictEndDate])
        let stagePredicate = HKCategoryValueSleepAnalysis.predicateForSamples(equalTo: HKCategoryValueSleepAnalysis.allAsleepValues)
        
        let combinedPredicate = NSCompoundPredicate(type: .and, subpredicates: [stagePredicate, dateRangePredicate])
        
        let sortByDate = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: HKCategoryType(.sleepAnalysis),
                              predicate: combinedPredicate,
                              limit:  Int(HKObjectQueryNoLimit),
                              sortDescriptors: [sortByDate]
        ) { query, samples, error in
            
            guard error == nil else {
                Log("Error: \(error!.localizedDescription)", onLevel: .error)
                completion(nil)
                return
            }
            
            completion(serialize(samples))
        }
        
        if let healthStore = healthStore {
            healthStore.execute(query)
            // self.runningQueries.updateValue(query, forKey: "workouts")
        }
    }
    
    
    func calculateSteps(completion: @escaping (HKStatisticsCollection?) -> Void) {
        let stepType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        let anchorDate = Date.mondayAt12AM()
        let daily = DateComponents(day: 1)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)

        let query = HKStatisticsCollectionQuery(quantityType: stepType,
                                            quantitySamplePredicate: predicate,
                                            options: .cumulativeSum,
                                            anchorDate: anchorDate,
                                            intervalComponents: daily)
        query.initialResultsHandler = { query, statsCollection, error in
            completion(statsCollection)
        }

        if let healthStore = healthStore {
            healthStore.execute(query)
        }
        
//        let query = HKStatisticsCollectionQuery(
//            quantityType: quantityType,
//            quantitySamplePredicate: predicate,
//            options: options,
//            anchorDate: anchorDateParam, // anchorDate
//            intervalComponents: intervalComponents
//        )
    }

    func calculateLastWeeksSteps(completion: @escaping (HKStatisticsCollection?) -> Void) {
        let stepType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        let startDate = Calendar.current.date(byAdding: .weekOfYear, value: -6, to: Date())
        let anchorDate = Date.mondayAt12AM()
        let week = DateComponents(day: 1)

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)

        let query = HKStatisticsCollectionQuery(quantityType: stepType,
                                            quantitySamplePredicate: predicate,
                                            options: .cumulativeSum,
                                            anchorDate: anchorDate,
                                            intervalComponents: week)
        query.initialResultsHandler = { query, statsCollection, error in
            completion(statsCollection)
        }

        if let healthStore = healthStore {
            healthStore.execute(query)
        }
    }

    func calculateMonthSteps(completion: @escaping (HKStatisticsCollection?) -> Void) {
        let stepType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())
        let anchorDate = Date.mondayAt12AM()
        let month = DateComponents(day: 1)

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)

        let query = HKStatisticsCollectionQuery(quantityType: stepType,
                                            quantitySamplePredicate: predicate,
                                            options: .cumulativeSum,
                                            anchorDate: anchorDate,
                                            intervalComponents: month)
        query.initialResultsHandler = { query, statsCollection, error in
            completion(statsCollection)
        }

        if let healthStore = healthStore {
            healthStore.execute(query)
        }
    }

    func calculateCalories(completion: @escaping (HKStatisticsCollection?) -> Void) {
        let calories = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        let anchorDate = Date.mondayAt12AM()
        let daily = DateComponents(day: 1)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)

        let query = HKStatisticsCollectionQuery(quantityType: calories,
                                            quantitySamplePredicate: predicate,
                                            options: .cumulativeSum,
                                            anchorDate: anchorDate,
                                            intervalComponents: daily)
        query.initialResultsHandler = { query, statsCollection, error in
            completion(statsCollection)
        }
        
        if let healthStore = healthStore {
            healthStore.execute(query)
        }
    }

    func calculateDistance(completion: @escaping (HKStatisticsCollection?) -> Void) {

        let distance = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        let anchorDate = Date.mondayAt12AM()
        let daily = DateComponents(day: 1)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)

        let query = HKStatisticsCollectionQuery(quantityType: distance,
                                            quantitySamplePredicate: predicate,
                                            options: .cumulativeSum,
                                            anchorDate: anchorDate,
                                            intervalComponents: daily)

        query.initialResultsHandler = { query, statsCollection, error in
            completion(statsCollection)
        }

        if let healthStore = healthStore {
            healthStore.execute(query)
        }
    }
    
    
    func fetchQuantitySamplesByType(
        sampleType: HKSampleType,
        from: Date,
        to: Date,
        uuidString: String? = nil,
        subpredicate: NSPredicate? = nil,
        completion: @escaping ([HKQuantitySample]?) -> Void
    ) {
        
        guard let healthStore = healthStore else {
            Log("HealthStore is not available", onLevel: .error)
            return completion(nil)
        }
        
        if let uuidString = uuidString {
            getWorkoutFor(uuidString: uuidString) { workoutResult in
                let workout: HKWorkout
                do {
                    workout = try workoutResult.get()
                } catch {
                    Log("Error: Cannot get workout by UDID \(uuidString)", onLevel: .error)
                    completion(nil)
                    return
                }
                
                let byWorkout = HKQuery.predicateForObjects(from: workout)
                
                return self.fetchQuantitySamplesByType(
                    sampleType: sampleType,
                    from: workout.startDate,
                    to: workout.endDate,
                    uuidString: nil,
                    subpredicate: byWorkout,
                    completion: completion
                )
            }
        } else {
            // Sort by startDate to get the most recent data first
            let sortByDate = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            
            Log("Retrieving sample for: \(sampleType.identifier)", onLevel: .info)
            let typePredicate = HKQuery.predicateForSamples(withStart: from, end: to, options: [.strictStartDate, .strictEndDate])
            let predicate: NSPredicate
            if let subpredicate = subpredicate {
                predicate = NSCompoundPredicate(type: .and, subpredicates: [typePredicate, subpredicate])
            } else {
                predicate = typePredicate
            }
            
            // Create the sample query
            let query = HKSampleQuery(sampleType: sampleType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: [sortByDate]
            ) { query, results, error in
                
                guard error == nil else {
                    Log("Error: \(error!.localizedDescription)", onLevel: .error)
                    completion(nil)
                    return
                }
                print("results \(results?.count ?? 0)")
                guard let samples = results as? [HKQuantitySample] else {
                    completion(nil)
                    return
                }
                
                completion(samples)
            }
            
            // Execute the query
            healthStore.execute(query)
        }
    }
    
    func fetchSamplesByType(
        sampleType: HKSampleType,
        from: Date,
        to: Date,
        subpredicate: NSPredicate? = nil,
        completion: @escaping ([HKSample]?) -> Void
    ) {
        
        guard let healthStore = healthStore else {
            Log("HealthStore is not available", onLevel: .error)
            return completion(nil)
        }
        
        let sortByDate = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query: HKSampleQuery
        
        
        Log("Retrieving sample for: \(sampleType.identifier)", onLevel: .info)
        let typePredicate = HKQuery.predicateForSamples(withStart: from, end: to, options: [.strictStartDate, .strictEndDate])
        
        let predicate: NSPredicate
        if let subpredicate = subpredicate {
            predicate = NSCompoundPredicate(type: .and, subpredicates: [typePredicate, subpredicate])
            
            //                let queryDescriptor = HKQueryDescriptor(
            //                    sampleType: sampleType,
            //                    predicate: subpredicate
            //                )
            //                query = HKSampleQuery(queryDescriptors: [queryDescriptor],
            //                                      limit:  Int(HKObjectQueryNoLimit),
            //                                      sortDescriptors: [sortByDate]
            //                ) { query, samples, error in
        } else {
            predicate = typePredicate
        }
        
        query = HKSampleQuery(sampleType: sampleType,
                              predicate: predicate,
                              limit:  Int(HKObjectQueryNoLimit),
                              sortDescriptors: [sortByDate]
        ) { query, samples, error in
            
            guard error == nil else {
                Log("Error: \(error!.localizedDescription)", onLevel: .error)
                completion(nil)
                return
            }

            completion(samples)
        }
        
        healthStore.execute(query)
    }
    
//    private func calculateSteps() async {
//        
//        // To get the day's steps, start from midnight and end now
//        let dateEnd = Date.now
//        let dateStart = Calendar.current.startOfDay(for: .now)
//        
//        // To get daily steps data
//        let dayComponent = DateComponents(day: 1)
//        
//        let predicate = HKQuery.predicateForSamples(withStart: dateStart, end: dateEnd, options: .strictStartDate)
//        let samplePredicate = HKSamplePredicate.quantitySample(type: HKQuantityType(.stepCount), predicate: predicate)
//        
//        let descriptor = HKStatisticsCollectionQueryDescriptor(
//            predicate: samplePredicate, options: .cumulativeSum, anchorDate: dateStart, intervalComponents: dayComponent
//        )
//        
////        let query = HKStatisticsCollectionQuery(
////            quantityType: quantityType,
////            quantitySamplePredicate: predicate,
////            options: options,
////            anchorDate: anchorDateParam, // anchorDate
////            intervalComponents: intervalComponents
////        )
//        
//        if let healthStore = healthStore {
//            
//            let result = try? await descriptor.result(for: healthStore)
//            
//            // From the daily steps data, get today's step count samples
//            result?.enumerateStatistics(from: dateStart, to: dateEnd) { statistics, stop in
//                // Sum up all step samples for the day
//                let steps = Int(statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0)
//                DispatchQueue.main.async {
//                    //                self.steps = steps
//                }
//            }
//        }
//        
//    }
    
    func fetchStatisticsCollectionByType(
        quantityType: HKQuantityType,
        from: Date,
        to: Date,
        options: HKStatisticsOptions = [],
        uuidString: String? = nil,
        subpredicate: NSPredicate? = nil,
        anchorDate: Date = Date.mondayAt12AM(),
        intervalComponents: DateComponents = DateComponents(day: 1), // daily
        completion: @escaping (HKStatisticsCollection?) -> Void
    ) {
        
        
        
        if let uuidString = uuidString {
            
            getWorkoutFor(uuidString: uuidString) { workoutResult in
                
                let workout: HKWorkout
                do {
                    workout = try workoutResult.get()
                } catch {
                    Log("Error: Cannot get workout by UDID \(uuidString)", onLevel: .error)
                    completion(nil)
                    return
                }
                
                let byWorkout = HKQuery.predicateForObjects(from: workout)

                return self.fetchStatisticsCollectionByType(
                    quantityType: quantityType,
                    from: from,
                    to: to,
                    options: options,
                    subpredicate: byWorkout,
                    anchorDate: workout.endDate,
                    intervalComponents: intervalComponents,
                    completion: completion
                )
                
            }
        } else {
            
            let typePredicate = HKQuery.predicateForSamples(withStart: from, end: to, options: [.strictStartDate, .strictEndDate])
            
            let predicate: NSPredicate
            if let subpredicate = subpredicate {
                predicate = NSCompoundPredicate(type: .and, subpredicates: [typePredicate, subpredicate])
            } else {
                predicate = typePredicate
            }
            

            let calendar = Calendar.current
            let anchorInterval = DateComponents(
                calendar: calendar,
                timeZone: calendar.timeZone,
                minute: 0,
                second: 0
            )
            
            guard let anchorDateParam = calendar.nextDate(
                after: anchorDate,
                matching: anchorInterval,
                matchingPolicy: .nextTime,
                repeatedTimePolicy: .first,
                direction: .backward
            ) else {
                Log("Error: Unale to find date from achor", onLevel: .error)
                return
            }
            
            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: options,
                anchorDate: anchorDateParam, // anchorDate
                intervalComponents: intervalComponents
            )
            
            query.initialResultsHandler = { query, statisticsCollection, error in
                
                if let error = error as? HKError {
                    switch (error.code) {
                    case .errorDatabaseInaccessible:
                        // Absorb database inaccessible errors
                        Log("Absorb database inaccessible errors", onLevel: .warn)
                    default:
                        Log("Error: \(error.localizedDescription)", onLevel: .error)
                    }
                    return completion(nil)
                }
                completion(statisticsCollection)
            }
            
            if let healthStore = healthStore {
                healthStore.execute(query)
            }
        }
    }
    
    func fetchSleepAnalysis(
        from: Date, to: Date,
        completion: @escaping ([HKSample]?) -> Void
    ) {
        Log("Retrieving Sleep Analysis", onLevel: .info)
        let dateRangePredicate = HKQuery.predicateForSamples(withStart: from, end: to, options: [.strictStartDate, .strictEndDate])
        let stagePredicate = HKCategoryValueSleepAnalysis.predicateForSamples(equalTo: HKCategoryValueSleepAnalysis.allAsleepValues)
        
        let combinedPredicate = NSCompoundPredicate(type: .and, subpredicates: [stagePredicate, dateRangePredicate])
        
        let sortByDate = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: HKCategoryType(.sleepAnalysis),
                              predicate: combinedPredicate,
                              limit:  Int(HKObjectQueryNoLimit),
                              sortDescriptors: [sortByDate]
        ) { query, samples, error in
            
            guard error == nil else {
                Log("Error: \(error!.localizedDescription)", onLevel: .error)
                completion(nil)
                return
            }
            
            completion(samples)
        }
        
        if let healthStore = healthStore {
            healthStore.execute(query)
            // self.runningQueries.updateValue(query, forKey: "workouts")
        }
    }
    

    // The sample query returns sample objects that match the provided type and predicate.
    // You can provide a sort order for the returned samples, or limit the number of samples returned.
    func getSamplesByType<T: Codable>(
        sampleType: HKSampleType,
        from: Date,
        to: Date,
        subpredicate: NSPredicate? = nil,
        serialize: @escaping ([HKSample]?) -> T?,
        completion: @escaping (T?) -> Void
    ) {
        
        guard let healthStore = healthStore else {
            Log("HealthStore is not available", onLevel: .error)
            return completion(nil)
        }
        
        let sortByDate = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query: HKSampleQuery
        
        
        Log("Retrieving sample for: \(sampleType.identifier)", onLevel: .info)
        let typePredicate = HKQuery.predicateForSamples(withStart: from, end: to, options: [.strictStartDate, .strictEndDate])
        
        let predicate: NSPredicate
        if let subpredicate = subpredicate {
            predicate = NSCompoundPredicate(type: .and, subpredicates: [typePredicate, subpredicate])
            
            //                let queryDescriptor = HKQueryDescriptor(
            //                    sampleType: sampleType,
            //                    predicate: subpredicate
            //                )
            //                query = HKSampleQuery(queryDescriptors: [queryDescriptor],
            //                                      limit:  Int(HKObjectQueryNoLimit),
            //                                      sortDescriptors: [sortByDate]
            //                ) { query, samples, error in
        } else {
            predicate = typePredicate
        }
        
        query = HKSampleQuery(sampleType: sampleType,
                              predicate: predicate,
                              limit:  Int(HKObjectQueryNoLimit),
                              sortDescriptors: [sortByDate]
        ) { query, samples, error in
            
            guard error == nil else {
                Log("Error: \(error!.localizedDescription)", onLevel: .error)
                completion(nil)
                return
            }
            
//            var data: [[String: Any]] = []
//            
//            // A sample processed counter for data types that require a subquery like
//            // HeartbeatSeries and Electrocardiogram
//            var seriesSamplesProcessed = 0;
//            
//            // Add a flag to specify if the incoming data is/was handled by one of
//            // our data type handlers. Some of the data types have subqueries, so we
//            // need to know if we need to keep waiting for data before calling the
//            // completion handler, or if we simply don't have a handler for the incoming
//            // results.
//            var resultsHandled = false;
//            
//            // Quantity Samples
//            if let samples = samples as? [HKQuantitySample] {
//                Log("casting samples as HKQuantitySample", onLevel: .debug)
//                resultsHandled = true
//                for sample in samples {
//                    if let unit = self.getDefaultUnit(forSampleType: sampleType) {
//                        data.append([
//                            "uuid": sample.uuid.uuidString,
//                            "startAt": sample.startDate.timeIntervalSince1970,
//                            "endAt": sample.endDate.timeIntervalSince1970,
//                            "value": sample.quantity.doubleValue(for: unit),
//                            "unit": unit
//                        ])
//                    }
//                }
//            }
//            
//            // Category Samples
//            if let samples = samples as? [HKCategorySample] {
//                Log("casting samples as HKCategorySample", onLevel: .debug)
//                resultsHandled = true
//                for sample in samples {
//                    data.append([
//                        "uuid": sample.uuid.uuidString,
//                        "startAt": sample.startDate.timeIntervalSince1970,
//                        "endAt": sample.endDate.timeIntervalSince1970,
//                        "value": sample.value
//                    ])
//                }
//            }
//            
//            // Clinical Records
//            if #available(iOS 12.0, *) {
//                if let samples = samples as? [HKClinicalRecord] {
//                    Log("casting samples as HKClinicalRecord", onLevel: .debug)
//                    resultsHandled = true
//                    for sample in samples {
//                        var fhirRelease: String?;
//                        var fhirVersion: String?;
//                        var fhirData: Any?;
//                        
//                        if let fhirRecord = sample.fhirResource {
//                            if #available(iOS 14.0, *) {
//                                let fhirResourceVersion = fhirRecord.fhirVersion
//                                fhirRelease = fhirResourceVersion.fhirRelease.rawValue;
//                                fhirVersion = fhirResourceVersion.stringRepresentation;
//                            } else {
//                                // iOS < 14 uses DSTU2
//                                fhirRelease = "DSTU2";
//                                fhirVersion = "1.0.2";
//                            }
//                            
//                            do {
//                                fhirData = try JSONSerialization.jsonObject(with: fhirRecord.data, options: [])
//                            }
//                            catch {
//                                // TODO: Handle JSON error
//                            }
//                        }
//                        
//                        data.append([
//                            "uuid": sample.uuid.uuidString,
//                            "startAt": sample.startDate.timeIntervalSince1970,
//                            "endAt": sample.endDate.timeIntervalSince1970,
//                            "fhirRelease": fhirRelease!,
//                            "fhirVersion": fhirVersion!,
//                            "fhirData": fhirData!,
//                        ])
//                    }
//                }
//            }
//            
//            if #available(iOS 13.0, *) {
//                if let samples = samples as? [HKHeartbeatSeriesSample] {
//                    Log("casting samples as HKHeartbeatSeriesSample", onLevel: .debug)
//                    resultsHandled = true
//                    for sample in samples {
//                        var elem: [String: Any] = [
//                            "uuid": sample.uuid.uuidString,
//                            "startAt": sample.startDate.timeIntervalSince1970,
//                            "endAt": sample.endDate.timeIntervalSince1970
//                        ];
//                        var heartbeats: [[String: Any]] = []
//                        
//                        let subquery = HKHeartbeatSeriesQuery(heartbeatSeries: sample) { subquery, timeSinceSeriesStart, precededByGap, done, error in
//                            if error == nil {
//                                heartbeats.append([
//                                    "elapsed": timeSinceSeriesStart,
//                                    "precededByGap": precededByGap
//                                ])
//                            }
//                            if done {
//                                elem["heartbeats"] = heartbeats
//                                data.append(elem)
//                                seriesSamplesProcessed += 1
//                                //                                    if (seriesSamplesProcessed == samples.count) {
//                                //                                        return completion(data, nil)
//                                //                                    }
//                            }
//                        }
//                        healthStore.execute(subquery)
//                    }
//                }
//            }
//            
//            if #available(iOS 14.0, *) {
//                if let samples = samples as? [HKElectrocardiogram] {
//                    Log("casting samples as HKElectrocardiogram", onLevel: .debug)
//                    resultsHandled = true
//                    for sample in samples {
//                        var elem: [String: Any] = [
//                            "uuid": sample.uuid.uuidString,
//                            "startAt": sample.startDate.timeIntervalSince1970,
//                            "endAt": sample.endDate.timeIntervalSince1970,
//                            "classification": sample.classification.rawValue,
//                            "averageHeartRate": sample.averageHeartRate?.doubleValue(for: HKUnit.init(from: "count/min")) ?? 0,
//                            "samplingFrequency": sample.samplingFrequency?.doubleValue(for: HKUnit.hertz()) ?? 0,
//                            "algorithmVersion": sample.metadata?[HKMetadataKeyAppleECGAlgorithmVersion] as Any
//                        ];
//                        
//                        
//                        var voltages: [[Any]] = []
//                        
//                        let subquery = HKElectrocardiogramQuery(electrocardiogram: sample) {
//                            subq, voltageMeasurement, done, error in
//                            if (error == nil && voltageMeasurement !== nil) {
//                                // If no error exists for this data point, add the voltage measurement to the array.
//                                // I'm not sure if this technique of error handling is what we want. It could lead
//                                // to holes in the data. The alternative is to not write any of the voltage data to
//                                // the elem dictionary if an error occurs. I think holes are *probably* better?
//                                let value = voltageMeasurement!.quantity(for: HKElectrocardiogram.Lead.appleWatchSimilarToLeadI)?.doubleValue(for: HKUnit.voltUnit(with: HKMetricPrefix.micro))
//                                
//                                voltages.append([
//                                    voltageMeasurement!.timeSinceSampleStart,
//                                    value ?? 0
//                                ])
//                                
//                            }
//                            if done {
//                                elem["voltages"] = voltages
//                                data.append(elem)
//                                seriesSamplesProcessed += 1
//                                //                                    if (seriesSamplesProcessed == samples.count) {
//                                //                                        return completion(data, nil)
//                                //                                    }
//                            }
//                        }
//                        healthStore.execute(subquery)
//                    }
//                }
//            }
//            
//            // If we haven't yet built the handlers for the data type
//            // just call the completion handler with empty data.
//            if !resultsHandled {
//                Log("resultsHandled is not handled", onLevel: .debug)
//            } else {
//                Log("resultsHandled was handled", onLevel: .debug)
//                print(data)
//            }
            
            completion(serialize(samples))
        }
        
        healthStore.execute(query)
    }
    
    // Statistics queries calculate common statistics over the set of matching samples.
    // You can use statistical queries to calculate the minimum, maximum, or average value of a set of discrete quantities,
    // or use them to calculate the sum for cumulative quantities.
    // Keep in mind that you can use statistics queries with quantity samples only.
    // Example usage:
    // Read the total step count in last 24 hours. Note that we use statistics query since we want to get cumulative sum.
    // Similarly we can get Avg, Min and Max values for descrete types like heart rate, blood glucose etc.
    func getStatisticsByType<T: Codable>(
        quantityType: HKQuantityType,
        from: Date,
        to: Date,
        options: HKStatisticsOptions = [],
        uuidString: String? = nil,
        subpredicate: NSPredicate? = nil,
        anchorDate: Date = Date.mondayAt12AM(),
        intervalComponents: DateComponents = DateComponents(day: 1), // daily
        serialize: @escaping (HKStatistics?) -> T?,
        completion: @escaping (T?) -> Void
    ) {
        
        if let uuidString = uuidString {
            
            getWorkoutFor(uuidString: uuidString) { workoutResult in
                
                let workout: HKWorkout
                do {
                    workout = try workoutResult.get()
                } catch {
                    Log("Error: Cannot get workout by UDID \(uuidString)", onLevel: .error)
                    completion(nil)
                    return
                }
                
                let byWorkout = HKQuery.predicateForObjects(from: workout)
                
                return self.getStatisticsByType(
                    quantityType: quantityType,
                    from: from,
                    to: to,
                    options: options,
                    subpredicate: byWorkout,
                    anchorDate: anchorDate,
                    intervalComponents: intervalComponents,
                    serialize: serialize,
                    completion: completion
                )
                
            }
        } else {
            
            let typePredicate = HKQuery.predicateForSamples(withStart: from, end: to, options: [.strictStartDate, .strictEndDate])
            
            let predicate: NSPredicate
            if let subpredicate = subpredicate {
                predicate = NSCompoundPredicate(type: .and, subpredicates: [typePredicate, subpredicate])
            } else {
                predicate = typePredicate
            }
            
            let query = HKStatisticsQuery.init(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: options) { (query, results, error) in
                    guard error == nil else {
                        Log("Error: \(error!.localizedDescription)", onLevel: .error)
                        completion(nil)
                        return
                    }
                    completion(serialize(results))
                }
            
            if let healthStore = healthStore {
                healthStore.execute(query)
            }
        }
    }
    
    // Statistics collection queries are often used to produce data for graphs and charts.
    // For example, you might create a statistics collection query that calculates the total number of steps for each day or the average heart rate for each hour.
    func getStatisticsCollectionByType<T: Codable>(
        quantityType: HKQuantityType,
        from: Date,
        to: Date,
        options: HKStatisticsOptions = [],
        uuidString: String? = nil,
        subpredicate: NSPredicate? = nil,
        anchorDate: Date = Date.mondayAt12AM(),
        intervalComponents: DateComponents = DateComponents(day: 1), // daily
        serialize: @escaping (HKStatisticsCollection?) -> T?,
        completion: @escaping (T?) -> Void
    ) {
        
        
        
        if let uuidString = uuidString {
            
            getWorkoutFor(uuidString: uuidString) { workoutResult in
                
                let workout: HKWorkout
                do {
                    workout = try workoutResult.get()
                } catch {
                    Log("Error: Cannot get workout by UDID \(uuidString)", onLevel: .error)
                    completion(nil)
                    return
                }
                
                let byWorkout = HKQuery.predicateForObjects(from: workout)

                return self.getStatisticsCollectionByType(
                    quantityType: quantityType,
                    from: from,
                    to: to,
                    options: options,
                    subpredicate: byWorkout,
                    anchorDate: workout.endDate,
                    intervalComponents: intervalComponents,
                    serialize: serialize,
                    completion: completion
                )
                
            }
        } else {
            
            
//            let anchorDate = Date.mondayAt12AM()
//            let daily = DateComponents(day: 1)
//            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
            
            let typePredicate = HKQuery.predicateForSamples(withStart: from, end: to, options: [.strictStartDate, .strictEndDate])
            
            let predicate: NSPredicate
            if let subpredicate = subpredicate {
                predicate = NSCompoundPredicate(type: .and, subpredicates: [typePredicate, subpredicate])
            } else {
                predicate = typePredicate
            }
            

            let calendar = Calendar.current
            let anchorInterval = DateComponents(
                calendar: calendar,
                timeZone: calendar.timeZone,
                minute: 0,
                second: 0
            )
            
            guard let anchorDateParam = calendar.nextDate(
                after: anchorDate,
                matching: anchorInterval,
                matchingPolicy: .nextTime,
                repeatedTimePolicy: .first,
                direction: .backward
            ) else {
                Log("Error: Unale to find date from achor", onLevel: .error)
                return
            }
            
            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: options,
                anchorDate: anchorDateParam, // anchorDate
                intervalComponents: intervalComponents
            )
            
            query.initialResultsHandler = { query, statisticsCollection, error in
                
                if let error = error as? HKError {
                    switch (error.code) {
                    case .errorDatabaseInaccessible:
                        // Absorb database inaccessible errors
                        Log("Absorb database inaccessible errors", onLevel: .warn)
                    default:
                        Log("Error: \(error.localizedDescription)", onLevel: .error)
                    }
                    return completion(nil)
                }
                completion(serialize(statisticsCollection))
            }
            
            if let healthStore = healthStore {
                healthStore.execute(query)
            }
        }
    }

    
    func storeQuantityDataFor(type: HKQuantityType, date: Date, value: Double, unit: HKUnit) async throws -> Bool {
        let sample = HKQuantitySample.init(type: type,
                                           quantity: HKQuantity.init(unit: unit, doubleValue: value),
                                           start: date,
                                           end: date
        )
        
        if let healthStore = self.healthStore {
            try await healthStore.save(sample)
            return true
        }
        throw ForkError.healthDataError
    }
    
    func storeQuantityDataFor(type: HKQuantityType, date: Date, value: Double, unit: HKUnit, completion: @escaping (Result<Bool, ForkError>) -> Void) {
        let sample = HKQuantitySample.init(type: type,
                                           quantity: HKQuantity.init(unit: unit, doubleValue: value),
                                           start: date,
                                           end: date
        )
        
        if let healthStore = self.healthStore {
            healthStore.save(sample) { success, error in
                guard error == nil else {
                    Log("Error: \(error!.localizedDescription)", onLevel: .error)
                    completion(.failure(.healthDataError))
                    return
                }
                completion(.success(true))
            }
        }
    }
    
    func fetchVoltageMeasumentData(ecgSample: HKElectrocardiogram,
                                   completion: @escaping (Result<[(Double,Double)], ForkError>) -> Void) {
        
        var ecgSamples = [(Double,Double)] ()
        // Create a query for the voltage measurements
        let query = HKElectrocardiogramQuery(ecgSample) { (query, result) in
            switch(result) {
            
            case .measurement(let measurement):
                if let voltageQuantity = measurement.quantity(for: .appleWatchSimilarToLeadI) {
                    // Do something with the voltage quantity here.
                    ecgSamples.append((
                        voltageQuantity.doubleValue(for: HKUnit.voltUnit(with: HKMetricPrefix.micro)),
                        measurement.timeSinceSampleStart)
                    )
                }
            
            case .done:
                // No more voltage measurements. Finish processing the existing measurements.
                completion(.success(ecgSamples))

            case .error(let error):
                // Handle the error here.
                print("error: ", error)
                completion(.failure(.healthDataError))

            @unknown default:
                completion(.failure(.healthDataError))
            }
        }

        // Execute the query.
        if let healthStore = healthStore {
            healthStore.execute(query)
        }
    }

}


extension ForkStore {
    
    private func get24hPredicate() -> NSPredicate{
        let today = Date()
        let startDate = Calendar.current.date(byAdding: .hour, value: -24, to: today)
        let predicate = HKQuery.predicateForSamples(withStart: startDate,end: today,options: [])
        return predicate
    }
    
}


extension ForkStore {
    func getDefaultUnit(forSampleType: HKSampleType) -> HKUnit? {
//        typealias TypeIdentifier = RNHealthierObjectTypeIdentifier;
        
        // HKUnit.init(from: unit)

        switch forSampleType {
        case HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!:
            return HKUnit(from: "%")
        case HKQuantityType.quantityType(forIdentifier: .heartRate)!:
            return HKUnit(from: "count/min")
        default:
            return nil
        }

//        switch forIdentifier {
//        case TypeIdentifier.AppleWalkingSteadiness,
//            TypeIdentifier.AtrialFibrillationBurden,
//            TypeIdentifier.BloodAlcoholContent,
//            TypeIdentifier.BodyFatPercentage,
//            TypeIdentifier.OxygenSaturation,
//            TypeIdentifier.PeripheralPerfusionIndex,
//            TypeIdentifier.WalkingDoubleSupportPercentage,
//            TypeIdentifier.WalkingAsymmetryPercentage:
//            return "%"
//        case TypeIdentifier.BodyMass,
//            TypeIdentifier.LeanBodyMass:
//            return "kg"
//        case TypeIdentifier.DietaryCarbohydrates,
//            TypeIdentifier.DietaryFatMonounsaturated,
//            TypeIdentifier.DietaryFatPolyunsaturated,
//            TypeIdentifier.DietaryFatSaturated,
//            TypeIdentifier.DietaryFatTotal,
//            TypeIdentifier.DietaryFiber,
//            TypeIdentifier.DietaryProtein,
//            TypeIdentifier.DietarySugar:
//            return "g"
//        case TypeIdentifier.DietaryCaffeine,
//            TypeIdentifier.DietaryCalcium,
//            TypeIdentifier.DietaryChloride,
//            TypeIdentifier.DietaryCholesterol,
//            TypeIdentifier.DietaryCopper,
//            TypeIdentifier.DietaryIron,
//            TypeIdentifier.DietaryManganese,
//            TypeIdentifier.DietaryPotassium,
//            TypeIdentifier.DietaryZinc,
//            TypeIdentifier.DietaryMagnesium,
//            TypeIdentifier.DietaryNiacin,
//            TypeIdentifier.DietaryPhosphorus,
//            TypeIdentifier.DietaryPantothenicAcid,
//            TypeIdentifier.DietaryRiboflavin,
//            TypeIdentifier.DietarySodium,
//            TypeIdentifier.DietaryThiamin,
//            TypeIdentifier.DietaryVitaminB6,
//            TypeIdentifier.DietaryVitaminC,
//            TypeIdentifier.DietaryVitaminE:
//            return "mg"
//        case TypeIdentifier.DietaryBiotin,
//            TypeIdentifier.DietaryChromium,
//            TypeIdentifier.DietaryFolate,
//            TypeIdentifier.DietaryMolybdenum,
//            TypeIdentifier.DietarySelenium,
//            TypeIdentifier.DietaryIodine,
//            TypeIdentifier.DietaryVitaminA,
//            TypeIdentifier.DietaryVitaminB12,
//            TypeIdentifier.DietaryVitaminD,
//            TypeIdentifier.DietaryVitaminK:
//            return "mcg"
//        case TypeIdentifier.ForcedExpiratoryVolume1,
//            TypeIdentifier.ForcedVitalCapacity:
//            return "L"
//        case TypeIdentifier.DietaryWater:
//            return "mL"
//        case TypeIdentifier.BodyMassIndex,
//            TypeIdentifier.InhalerUsage,
//            TypeIdentifier.NikeFuel,
//            TypeIdentifier.StepCount,
//            TypeIdentifier.FlightsClimbed,
//            TypeIdentifier.NumberOfAlcoholicBeverages,
//            TypeIdentifier.NumberOfTimesFallen,
//            TypeIdentifier.PushCount,
//            TypeIdentifier.SwimmingStrokeCount,
//            TypeIdentifier.UvExposure:
//            return "count"
//        case TypeIdentifier.DistanceWalkingRunning,
//            TypeIdentifier.DistanceCycling,
//            TypeIdentifier.DistanceWheelchair,
//            TypeIdentifier.DistanceDownhillSnowSports:
//            return "km"
//        case TypeIdentifier.DistanceSwimming,
//            TypeIdentifier.RunningStrideLength,
//            TypeIdentifier.SixMinuteWalkTestDistance,
//            TypeIdentifier.UnderwaterDepth:
//            return "m"
//        case TypeIdentifier.Height,
//            TypeIdentifier.RunningVerticalOscillation,
//            TypeIdentifier.WalkingStepLength,
//            TypeIdentifier.WaistCircumference:
//            return "cm"
//        case TypeIdentifier.ActiveEnergyBurned,
//            TypeIdentifier.BasalEnergyBurned,
//            TypeIdentifier.DietaryEnergyConsumed:
//            return "kcal"
//        case TypeIdentifier.PhysicalEffort:
//            return "kcal/(kg.hr)"
//        case TypeIdentifier.AppleExerciseTime,
//            TypeIdentifier.AppleStandTime,
//            TypeIdentifier.AppleMoveTime:
//            return "min"
//        case TypeIdentifier.HeartRateVariabilitySDNN,
//            TypeIdentifier.RunningGroundContactTime:
//            return "ms"
//        case TypeIdentifier.ElectrodermalActivity:
//            return "mcS"
//        case TypeIdentifier.Vo2Max:
//            return "mL/(kg.min)"
//        case TypeIdentifier.BloodGlucose:
//            return "mg/dL"
//        case TypeIdentifier.WalkingSpeed:
//            return "km/hr"
//        case TypeIdentifier.CyclingSpeed,
//            TypeIdentifier.RunningSpeed,
//            TypeIdentifier.StairAscentSpeed,
//            TypeIdentifier.StairDescentSpeed:
//            return "m/s"
//        case TypeIdentifier.CyclingCadence,
//            TypeIdentifier.HeartRate,
//            TypeIdentifier.HeartRateRecoveryOneMinute,
//            TypeIdentifier.RestingHeartRate,
//            TypeIdentifier.WalkingHeartRateAverage,
//            TypeIdentifier.RespiratoryRate:
//            return "count/min"
//        case TypeIdentifier.PeakExpiratoryFlowRate:
//            return "L/min"
//        case TypeIdentifier.AppleSleepingWristTemperature,
//            TypeIdentifier.BodyTemperature,
//            TypeIdentifier.WaterTemperature,
//            TypeIdentifier.BasalBodyTemperature:
//            return "degC"
//        case TypeIdentifier.BloodPressureSystolic,
//            TypeIdentifier.BloodPressureDiastolic:
//            return "mmHg"
//        case TypeIdentifier.EnvironmentalAudioExposure,
//            TypeIdentifier.HeadphoneAudioExposure,
//            TypeIdentifier.EnvironmentalSoundReduction:
//            return "dBASPL"
//        case TypeIdentifier.InsulinDelivery:
//            return "IU"
//        case TypeIdentifier.CyclingFunctionalThresholdPower,
//            TypeIdentifier.CyclingPower,
//            TypeIdentifier.RunningPower:
//            return "W"
//        default:
//            return nil;
//        }
    }
}
