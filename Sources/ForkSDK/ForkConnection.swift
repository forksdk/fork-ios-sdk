//
//  ForkConnection.swift
//
//
//  Created by Aleksandras Gaidamauskas on 16/04/2024.
//

import CoreLocation
import Foundation
import HealthKit

public enum ForkRegion {
    case US
    case EU
}

/// ForkConnection will fetch and extracts local device data or open permament connection to the backend  in case of using none local data provider and get reuested data from all available data sources and combine them.
// Or would it be an overkill and not possible without storing data from other provider what will make it way harder to be HIPAA compliant?
public class ForkConnection {

    private let forkStore: ForkStore
    private var isConnected: Bool

    private let appId: String
    private let authToken: String
    private let endUserId: String?
    private let callbackUrl: String?
    private let region: ForkRegion?
    private let transformer: ForkTransformerProtocol  // (any ForkTransformerProtocol)?

    private var backgroundDeliveryTypes: [ForkDataTypes]?
    private var backgroundDeliveriesLogger: ForkBackgroundDeliveriesLogger?

    // callbackUrl: Optional, provides functionality to send data to webhook and use background deliveries
    init(
        forkStore: ForkStore,
        appId: String,
        authToken: String,
        endUserId: String?,
        transformer: ForkTransformerProtocol,
        callbackUrl: String? = nil,
        region: ForkRegion? = ForkRegion.EU
    ) {
        self.forkStore = forkStore
        self.appId = appId
        self.authToken = authToken
        self.endUserId = endUserId
        self.transformer = transformer
        self.callbackUrl = callbackUrl
        self.region = region
        self.isConnected = true

        let logMessage =
            "New instance of ForkConnection has been create for endUserId: \(endUserId ?? "nil")"
        if let callbackUrl = callbackUrl {
            Log(
                "\(logMessage) with callbackUrl: \(callbackUrl)",
                onLevel: .info
            )
        } else {
            Log(
                "\(logMessage) without callbackUrl",
                onLevel: .info
            )
        }
    }

    /// Retrieves the unique application identifier.
    public func getAppId() -> String {
        return self.appId
    }

    /// Retrieves the authentication token
    public func getAuthToken() -> String {
        return self.authToken
    }

    /// Retrieves the unique identifier assigned to the end-user by the customer.
    public func getCustomerEndUserId() -> String? {
        return self.endUserId
    }

    /// Returns the URL that will receive webhook notifications.
    public func getCallbackUrl() -> String? {
        return self.callbackUrl
    }

    /// Saves the provided value to the HealthKit store
    ///
    /// - Parameters:
    ///   - forType: The data type to store value for.
    ///   - value: The value to store.
    ///   - date: The date of measurement.
    ///   - completion: Callback.
    public func storeData(
        _ forType: ForkStoreDataTypes,
        value: Double,
        date: Date? = nil,
        completion: @escaping (Result<Bool, ForkError>) -> Void
    ) {
        Log("ForkConnection.storeData for type \(forType.rawValue) has been called", onLevel: .info)

        switch forType {
        case .bodyMass:
            let bodyMassType = HKQuantityType.quantityType(
                forIdentifier: HKQuantityTypeIdentifier.bodyMass)!

            self.forkStore.storeQuantityDataFor(
                type: bodyMassType,
                date: date ?? Date.now,
                value: value / 1000,
                unit: .gram()
            ) { result in

                var success: Bool
                do {
                    success = try result.get()
                } catch {
                    Log("Error: Cannot storeData forType \(forType.rawValue)", onLevel: .error)
                    completion(.failure(.generalError))
                    return
                }

                completion(.success(success))
            }
            return completion(.failure(.generalError))
        default:
            return completion(.failure(.notImplemented))
        }
    }

    
    /// Saves the provided value to the HealthKit store
    ///
    /// - Parameters:
    ///   - forType: The data type to store value for.
    ///   - value: The value to store.
    ///   - date: The date of measurement
    func storeData(
        _ forType: ForkStoreDataTypes,
        value: Double,
        date: Date? = nil
    ) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            self.storeData(forType, value: value, date: date) { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Fetch and extracts local device data for the current date in the end-user’s time zone. Optionally time range can be provided.
    ///
    /// - Parameter forType: The data type to make extraction for
    /// - Parameter uuidString: Optional ID of activity
    /// - Parameter from: Date, Extraction time range start date
    /// - Parameter to: Date, Extraction time range end date
    /// - Parameter filter: ForkQueryFilter
    /// - Parameter completion: Callback
    public func fetchRawData(
        _ forType: ForkDataTypes,
        uuidString: String? = nil,
        from: Date? = nil,
        to: Date? = nil,
        filter: ForkQueryFilter? = nil,
        completion: @escaping (Result<ForkHealthData, ForkError>) -> Void
    ) {
        if !self.isConnected {
            Log(
                "ForkConnection.extractData has been called after connection was closed",
                onLevel: .error)
            return completion(.failure(.connectionIsClosed))
        }

        Log(
            "ForkConnection.fetchRawData for type \(forType.rawValue) has been called",
            onLevel: .info
        )

        //            guard let _ = uuidString,  let udid = UUID(uuidString: uuidString!) else {
        //                Log("Error: UDID object cannot be created from \(uuidString)", onLevel: .error)
        //                completion(.failure(.notFound))
        //                return
        //            }

        // fallback to last week period if no from/to provided
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: today)!
        let fromDate: Date = from ?? today
        let toDate: Date = to ?? weekAgo

        switch forType {
        case .characteristic:
            if let characteristicFilter = filter?.characteristics {
                self.forkStore.getCharacteristics(characteristics: characteristicFilter) { result in
                    switch result {
                    case .success(let characteristics):
                        completion(.success(ForkHealthDataCharacteristic(characteristic: characteristics)))
                    case .failure(let error):
                        Log("Error: \(error)", onLevel: .error)
                    }
                }
            } else {
                Log("Error: Characteristic must be provided to search for data", onLevel: .error)
            }
        case .activitiesSummary:
            self.forkStore.getActivitySummaryQuery(from: fromDate, to: toDate) { summaries in
                if let summaries = summaries {
                    for summary in summaries {

                        // summary.activityMoveMode  The move mode of an activity summary determines if activeEnergyBurned or appleMoveTime are used for the move ring.

                        let appleMoveTimeGoal = summary.appleMoveTimeGoal.doubleValue(
                            for: HKUnit.minute())
                        let appleMoveTime = summary.appleMoveTime.doubleValue(for: HKUnit.minute())
                        let standHours = summary.appleStandHours.doubleValue(for: HKUnit.hour())
                        let standHoursGoal = summary.standHoursGoal?.doubleValue(for: HKUnit.hour())

                        let exerciseMinutes = summary.appleExerciseTime.doubleValue(
                            for: HKUnit.minute())
                        let exerciseTimeGoal = summary.exerciseTimeGoal?.doubleValue(
                            for: HKUnit.minute())

                        let activeEnergyBurned = summary.activeEnergyBurned.doubleValue(
                            for: HKUnit.kilocalorie())
                        let activeEnergyBurnedGoal = summary.activeEnergyBurnedGoal.doubleValue(
                            for: HKUnit.kilocalorie())

                        let data = ForkHealthDataActivitySummary(
                            appleMoveTime: summary.activityMoveMode == .activeEnergy
                                ? activeEnergyBurned : appleMoveTime,
                            appleMoveTimeGoal: summary.activityMoveMode == .activeEnergy
                                ? activeEnergyBurnedGoal : appleMoveTimeGoal,
                            appleExerciseTime: exerciseMinutes,
                            appleExerciseTimeGoal: exerciseTimeGoal,
                            appleStandHours: standHours,
                            appleStandHoursGoal: standHoursGoal
                        )
                        //                            debugPrint("activeEnergyBurned", activeEnergyBurned)
                        //                            debugPrint("exerciseMinutes", exerciseMinutes)
                        //                            debugPrint("standHours", standHours)
                        completion(.success(data))
                    }
                } else {
                    completion(.failure(.generalError))
                }
                completion(.failure(.generalError))
            }
        case .workouts:

            let sampleType: HKSampleType = HKQuantityType.workoutType()
            self.forkStore.fetchSamplesByType(
                sampleType: sampleType,
                from: fromDate,
                to: toDate
            ) { result in
                if let result = result {
                    let data = ForkHealthDataWorkouts(items: result as? [HKWorkout] ?? [])
                    completion(.success(data))
                } else {
                    completion(.failure(.generalError))
                }
            }
        case .workoutRoute:
            if let uuidString = uuidString {
                self.forkStore.getWorkoutRoute(uuidString: uuidString) { result in
                    if let result = result {
                        for route in result {
                            self.forkStore.getLocationDataForRoute(givenRoute: route) { items in
//                                print("location \(items?.count)")
                                let data = ForkHealthDataLLocation(
                                    items: items ?? [])
                                completion(.success(data))
                            }
                        }
                    } else {
                        completion(.failure(.generalError))
                    }
                }
            } else {
                completion(.failure(.invalidIdentifier("uuid")))
            }
        case .sleep:
            self.forkStore.fetchSleepAnalysis(from: yesterday, to: today) { result in
                if let result = result {
                    let data = ForkHealthDataCategorySamples(
                        items: result as? [HKCategorySample] ?? [])
                    completion(.success(data))
                } else {
                    completion(.failure(.generalError))
                }
            }
        case .oxygenSaturation:
            // Oxygen Saturation (SP02)
            let sampleType: HKQuantityType = HKQuantityType.quantityType(
                forIdentifier: .oxygenSaturation)!

            //                self.forkStore.fetchSamplesByType(
            //                    sampleType: sampleType,
            //                    from: fromDate,
            //                    to: toDate
            //                ) { result in
            //                    if let result = result {
            //                        let data = ForkHealthDataCategorySamples(items: result as? [HKCategorySample] ?? [])
            //                        completion(.success(data))
            //                    } else {
            //                        completion(.failure(.generalError))
            //                    }
            //                }
            self.forkStore.fetchQuantitySamplesByType(
                sampleType: sampleType,
                from: fromDate,
                to: toDate,
                uuidString: uuidString,
                subpredicate: nil
            ) { result in
                if let samples = result {
                    let data = ForkHealthDataQuantitySamples(items: samples)
                    completion(.success(data))
                } else {
                    completion(.failure(.generalError))
                }
            }
        case .vo2Max:
            let sampleType: HKQuantityType = HKQuantityType.quantityType(forIdentifier: .vo2Max)!

            self.forkStore.fetchQuantitySamplesByType(
                sampleType: sampleType,
                from: fromDate,
                to: toDate,
                uuidString: uuidString,
                subpredicate: nil
            ) { result in
                if let samples = result {
                    let data = ForkHealthDataQuantitySamples(items: samples)
                    completion(.success(data))
                } else {
                    completion(.failure(.generalError))
                }
            }
        case .calories:
            let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!

            self.forkStore.fetchStatisticsCollectionByType(
                quantityType: activeEnergyType,
                from: fromDate,
                to: toDate,
                options: .cumulativeSum,
                uuidString: nil,
                subpredicate: nil
            ) { result in
                if let result = result {
                    let data = ForkHealthDataStatistics(collection: result)
                    completion(.success(data))
                } else {
                    completion(.failure(.generalError))
                }
            }
        case .steps:

            let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

            self.forkStore.fetchStatisticsCollectionByType(
                quantityType: stepType,
                from: fromDate,
                to: toDate,
                options: .cumulativeSum,
                uuidString: nil,
                subpredicate: nil
            ) { result in
                if let result = result {
                    let data = ForkHealthDataStatistics(collection: result)
                    completion(.success(data))
                } else {
                    completion(.failure(.generalError))
                }
            }
        case .flightsClimbed:

            let flightsClimbedType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed)!

            self.forkStore.fetchStatisticsCollectionByType(
                quantityType: flightsClimbedType,
                from: fromDate,
                to: toDate,
                options: .cumulativeSum,
                uuidString: nil,
                subpredicate: nil
            ) { result in
                if let result = result {
                    let data = ForkHealthDataStatistics(collection: result)
                    completion(.success(data))
                } else {
                    completion(.failure(.generalError))
                }
            }

        case .distance:

            let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!  //distancePaddleSports // distanceRowing // sixMinuteWalkTestDistance

            self.forkStore.fetchStatisticsCollectionByType(
                quantityType: distanceType,
                from: fromDate,
                to: toDate,
                options: .cumulativeSum,
                uuidString: nil,
                subpredicate: nil
            ) { result in
                if let result = result {
                    let data = ForkHealthDataStatistics(collection: result)
                    completion(.success(data))
                } else {
                    completion(.failure(.generalError))
                }
            }
            
        case .electrocardiogram:
            
            // https://developer.apple.com/documentation/healthkit/hkelectrocardiogram
            let ecgType = HKObjectType.electrocardiogramType()
            
            self.forkStore.fetchQuantitySamplesByType(sampleType: ecgType, from: fromDate, to: toDate) { result in
                if let samples = result {
                    
                    // After retrieving an HKElectrocardiogram sample, you can access the voltage measurements associated with the sample use an HKElectrocardiogramQuery query.
                    // fetchVoltageMeasumentData
                    
                    let data = ForkHealthDataQuantitySamples(items: samples)
                    completion(.success(data))
                } else {
                    completion(.failure(.generalError))
                }
            }

        case .heart:

            let quantityType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
            //                let quantityType = HKObjectType.quantityType(forIdentifier: .heartRate)!

//            let options: HKStatisticsOptions = [.discreteMax, .discreteMin]

            // https://developer.apple.com/documentation/healthkit/workouts_and_activity_rings/accessing_condensed_workout_samples

            // You can manually view the actual data available in the Apple Health app under
            // the Browse Tab -> Heart -> Heart Rate -> Show All Data (At the Bottom)

            // Apple Watch will only generate a Heart Rate measurement every 4 - 5 minutes when the user is wearing their watch.
            // If they start a workout, this increases to about 12 measurements per minute.
            // This is where the HKQuantitySeriesSample comes in useful for efficiently querying this high intensity data

            // Get all heart rate values recorded from "fromDate" to "toDate"
            self.forkStore.fetchQuantitySamplesByType(
                sampleType: quantityType,
                from: fromDate,
                to: toDate,
                uuidString: uuidString,
                subpredicate: nil
            ) { result in
                // if let result = result, let samples = result as [HKDiscreteQuantitySample]  {
                // let data = ForkHealthDataDiscreteQuantitySamples(items: samples)
                //      completion(.success(data))
                // } else {
                //      completion(.failure(.generalError))
                // }
                if let samples = result {  // HKQuantityTypeIdentifierHeartRate
                    let data = ForkHealthDataQuantitySamples(items: samples)
                    completion(.success(data))
                } else {
                    completion(.failure(.generalError))
                }
            }

        //            case .heart:
        //                if let uuidString = uuidString {
        //
        //                    self.forkStore.getWorkoutFor(uuidString: uuidString) { workoutResult in
        //
        //                        let workout: HKWorkout
        //                        do {
        //                            workout = try workoutResult.get()
        //                        } catch {
        //                            Log("Error: Cannot get workout by UDID \(uuidString)", onLevel: .error)
        //                            completion(.failure(.notFound))
        //                            return
        //                        }
        //
        //                        let forWorkout = HKQuery.predicateForObjects(from: workout)
        //
        //                        let quantityType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        //
        //                        let options: HKStatisticsOptions = [.discreteMax, .discreteMin]
        //
        //                        // https://developer.apple.com/documentation/healthkit/workouts_and_activity_rings/accessing_condensed_workout_samples
        //
        //                        // You can manually view the actual data available in the Apple Health app under
        //                        // the Browse Tab -> Heart -> Heart Rate -> Show All Data (At the Bottom)
        //
        //                        // Apple Watch will only generate a Heart Rate measurement every 4 - 5 minutes when the user is wearing their watch.
        //                        // If they start a workout, this increases to about 12 measurements per minute.
        //                        // This is where the HKQuantitySeriesSample comes in useful for efficiently querying this high intensity data
        //
        //
        //                        // Get all heart rate values recorded from "fromDate" to "toDate"
        //                        self.forkStore.fetchSamplesByType(
        //                            sampleType: quantityType,
        //                            from: fromDate,
        //                            to: toDate,
        //                            subpredicate: forWorkout
        //                        ) { result in
        //                            if let result = result, let samples = result as [HKDiscreteQuantitySample]  {
        //                                let data = ForkHealthDataDiscreteQuantitySamples(items: samples)
        //                                completion(.success(data))
        //                            } else {
        //                                completion(.failure(.generalError))
        //                            }
        //                        }
        //                    }
        //                } else {
        //                    return completion(.failure(.notImplemented))
        //                }
        default:
            return completion(.failure(.notImplemented))
        }
    }

    /// Fetch and extracts local device normalized data for the given time range.
    ///
    /// - Parameters:
    ///     - forType: The data type to make extraction for
    ///     - uuidString: Optional ID of activity
    ///     - from: Date, Extraction time range start date
    ///     - to: Date, Extraction time range end date
    ///     - completion: Callback
    public func fetchNormalizedData(
        _ forType: ForkDataTypes,
        uuidString: String? = nil,
        from: Date? = nil,
        to: Date? = nil,
        filter: ForkQueryFilter? = nil,
        completion: @escaping (Result<[ForkNormalizedData], ForkError>) -> Void
    ) {
        if !self.isConnected {
            Log(
                "ForkConnection.extractData has been called after connection was closed",
                onLevel: .error
            )
            return completion(.failure(.connectionIsClosed))
        }

        Log(
            "ForkConnection.fetchNormalizedData for type \(forType.rawValue) has been called",
            onLevel: .info
        )

        let today = Date()
        // let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: today)!
        let fromDate: Date = from ?? today
        let toDate: Date = to ?? weekAgo

        self.fetchRawData(
            forType,
            uuidString: uuidString,
            from: fromDate,
            to: toDate,
            filter: filter
        ) { result in
            switch result {
            case .success(let data):

                if let transformer = self.transformer as? ForkTypeTransofmer {  // (any ForkTypeTransformerProtocol)
                    if let transformed = transformer.transformData(
                        forType, data: data, from: fromDate, to: toDate)
                    {
                        return completion(.success(transformed))
                    } else {
                        return completion(.failure(.encodingError))
                    }
                }
                return completion(.failure(.notImplemented))
            case .failure(let error):
                return completion(.failure(error))
            }
        }
    }
    
    /// Fetch Normalized data  and send the restult to a webhook
    /// callbackUrl has to be provided to ForkConnection
    ///
    /// - Parameters:
    ///     - forType: The data type to make extraction for
    ///     - from: Date, Extraction time range start date
    ///     - to: Date, Extraction time range end date
    ///     - completion: Callback
    public func fetchAndPostNormalizedData(
        _ forType: ForkDataTypes,
        from: Date? = nil,
        to: Date? = nil,
        filter: ForkQueryFilter? = nil,
        completion: @escaping (Result<[ForkNormalizedData], ForkError>) -> Void
    ) {
        Log("ForkConnection.fetchAndPostNormalizedData has been called", onLevel: .info)
        
        guard let callbackUrl = self.callbackUrl else {
            completion(.failure(.callbackUrlNotProvided))
            return
        }
        
        self.fetchNormalizedData(
            forType,
            from: from,
            to: to,
            filter: filter
        ) { result in
            switch result {
            case .success(let data):

                // TODO: find a way to pass ForkNormalizedData instead of converting every supported type
                let encoder = JSONEncoder()
                var encoderData: Data?
                if let data = data as? [ForkNormalizedECGData] {
                    encoderData = try? encoder.encode(data)
                }
                if let data = data as? [ForkNormalizedSamplesData] {
                    encoderData = try? encoder.encode(data)
                }
                if let data = data as? [ForkNormalizedWorkoutData] {
                    encoderData = try? encoder.encode(data)
                }
                if let data = data as? [ForkNormalizedSleepData] {
                    encoderData = try? encoder.encode(data)
                }
                if let data = data as? [ForkNormalizedBodyData] {
                    encoderData = try? encoder.encode(data)
                }
                if let data = data as? [ForkNormalizedActivitiesSummaryData] {
                    encoderData = try? encoder.encode(data)
                }
                if let data = data as? [ForkNormalizedGlucoseData] {
                    encoderData = try? encoder.encode(data)
                }
                if let data = data as? [ForkNormalizedRouteData] {
                    encoderData = try? encoder.encode(data)
                }
                
                if let encoderData = encoderData {
                    ForkWebservice.post(url: callbackUrl, data: encoderData) { postResult in
                        switch postResult {
                        case .success(let isSuccess):
                            if isSuccess {
                                Log(
                                    "ForkConnection.fetchNormalizedData has been called successfuly",
                                    onLevel: .info
                                )
                            } else {
                                Log(
                                    "ForkConnection.fetchNormalizedData has been called and unsuccessfuly",
                                    onLevel: .error
                                )
                            }
                        case .failure(let postError):
                            Log(
                                "ForkConnection.fetchNormalizedData POST Request to \(callbackUrl) failed with error: \(postError)",
                                onLevel: .error
                            )
                        }
                    }
                    completion(.success(data))
                } else {
                    Log(
                        "ForkConnection.fetchNormalizedData failed to encode data",
                        onLevel: .error
                    )
                }
                
            case .failure(let error):
                Log("ForkConnection.fetchNormalizedData has failed", onLevel: .error)
                completion(.failure(error))
            }
        }
    }
    
    // Async await versions

    /// - Throws: `ForkError.connectionIsClosed` if connection was closed before
    /// - Throws: `ForkError.encodingError` if it can't encode data
    /// - Throws: `ForkError.generalError` in case of other error
    func fetchNormalizedData(
        _ forType: ForkDataTypes,
        uuidString: String? = nil,
        from: Date? = nil,
        to: Date? = nil,
        filter: ForkQueryFilter? = nil
    ) async throws -> [ForkNormalizedData] {
        return try await withCheckedThrowingContinuation { continuation in
            self.fetchNormalizedData(forType, uuidString: uuidString, from: from, to: to, filter: filter) { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func fetchAndPostNormalizedData(
        _ forType: ForkDataTypes,
        from: Date? = nil,
        to: Date? = nil,
        filter: ForkQueryFilter? = nil
    ) async throws -> [ForkNormalizedData] {
        return try await withCheckedThrowingContinuation { continuation in
            self.fetchAndPostNormalizedData(forType, from: from, to: to, filter: filter) { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Register connection for background deliveries
    /// - If `forTypes` is not empty, then a daemon task is started which will listen for data updates coming from the platform and send them via webhooks in the background; the operation is not compound and each method call will override enabled background data types list;
    /// - If `forTypes` parameter is empty or null, then background data delivery is stopped for this connection if it was enabled;
    public func enableBackgroundDelivery(_ forTypes: [ForkDataTypes]) {
        self.backgroundDeliveryTypes = forTypes
        Log("ForkConnection.enableBackgroundDelivery has been called", onLevel: .info)
    }

    /// Sets a listener that is to handle notifications from the background delivery process
    public func setBackgroundDeliveryLogger(_ logger: ForkBackgroundDeliveriesLogger) {
        self.backgroundDeliveriesLogger = logger
        Log("ForkConnection.setBackgroundDeliveryLogger has been called", onLevel: .info)
    }

    public func getBackgroundDeliveryDataTypes() -> [ForkDataTypes]? {
        return self.backgroundDeliveryTypes
    }

    /// Terminates any ongoing connections with Fork’s backend servers,
    /// clears any caches, and removes provided user details and tokens from the memory.
    /// Once the connection is closed, it cannot be used,
    /// and any method other than close() will throw an exception.
    public func close() {
        Log("ForkConnection.close has been called", onLevel: .info)
        self.isConnected = false
    }
}
