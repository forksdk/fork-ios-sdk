// The Swift Programming Language
// https://docs.swift.org/swift-book

import BackgroundTasks
import Foundation
import HealthKit

/// Fork Swift SDK is a library on top of HealthKit that helps with the data extraction and normalisation.
/// It provides a unified single schema across all source datasets
public class ForkSDK {

    public static let shared = ForkSDK()

    private var networkManger: ForkNetworkManager?
    private var forkStore: ForkStore?
    private var appId: String?
    private var authToken: String?
    private var customerEndUserId: String?
    private var region: ForkRegion?
    private var transformer: ForkTransformerProtocol

    private init() {
        self.transformer = ForkTypeTransofmer()
    }

    /// Allow SDK to setup background deliveries handlers.
    ///
    /// - Parameters:
    ///     - appId: The unique application identifier
    ///     - authToken: The authentification token from ForkSDK console.
    ///     - region: ForkRegion.EU or ForkRegion.US
    ///     - loggers:  Optional, Provides a way to pass a class which conforms to ForkLogging interface
    ///     - transformer:  Optional, Provides a way to pass a class which conforms to ForkTransformerProtocol interface
    public func configure(
        appId: String,
        authToken: String,
        region: ForkRegion? = ForkRegion.EU,
        loggers: [ForkLogging]? = nil,
        transformer: ForkTransformerProtocol? = nil
    ) {
        self.appId = appId
        self.authToken = authToken
        self.region = region
        if let loggers = loggers {
            for logger in loggers {
                ForkLogManager.shared.add(logger)
            }
        }

        self.forkStore = ForkStore()
        self.networkManger = ForkNetworkManager()
        if let transformer = transformer {
            self.transformer = transformer
        } else {
            self.transformer = ForkTypeTransofmer()
        }

        Log(
            "ForkSDK.configure called with appId: \(appId) and authToken: \(authToken)",
            onLevel: .info)
    }

    /// Retrieves the unique application identifier.
    public func getAppId() -> String? {
        return self.appId
    }

    /// Retrieves the authentication token
    public func getAuthToken() -> String? {
        return self.authToken
    }

    /// Sets The unique identifier assigned to the end-user by the customer.
    public func setCustomerEndUserId(customerEndUserId: String) {
        self.customerEndUserId = customerEndUserId
        Log("ForkSDK.setCustomerEndUserId customerEndUserId: \(customerEndUserId)", onLevel: .info)
    }

    /// Retrieves the unique identifier assigned to the end-user by the customer.
    public func getCustomerEndUserId() -> String? {
        return self.customerEndUserId
    }

    /// Verifies that platform-specific permissions corresponding to the Fork data types provided are granted. In the event that some permissions are not granted, a platform-specific permissions dialogue will be presented to the end-user
    /// Provide permissions to access iOS HealthKit data.
    /// SDK methods will check required permissions and request them if needed.
    ///
    /// - Parameter dateTypes: Set of required read data types ForkDataTypes
    /// - Parameter completion: Callback
    public func ensurePermissionsAreGranted(
        for dateTypes: Set<ForkDataTypes>, completion: @escaping (Result<Bool, ForkError>) -> Void
    ) {
        guard let forkStore = self.forkStore else {
            Log("ForkSDK ForkStore is not available", onLevel: .error)
            return completion(.failure(ForkError.healthDataNotAvailable))
        }
        guard self.appId != nil, self.authToken != nil else {
            Log("ForkSDK.configure needs to be called first", onLevel: .error)
            return completion(.failure(.notConfigured))
        }

        var readSet = Set<HKObjectType>()
        for dateType in dateTypes {
            switch dateType {
            case .characteristic:
                readSet.insert(HKObjectType.characteristicType(
                    forIdentifier: HKCharacteristicTypeIdentifier.dateOfBirth)!)
                readSet.insert(HKObjectType.characteristicType(
                    forIdentifier: HKCharacteristicTypeIdentifier.biologicalSex)!)
                readSet.insert(HKObjectType.characteristicType(
                    forIdentifier: HKCharacteristicTypeIdentifier.bloodType)!)
                readSet.insert(HKObjectType.characteristicType(
                    forIdentifier: HKCharacteristicTypeIdentifier.fitzpatrickSkinType)!)
                readSet.insert(HKObjectType.characteristicType(
                    forIdentifier: HKCharacteristicTypeIdentifier.wheelchairUse)!)
                //                readSet.insert(HKObjectType.characteristicType(
                //                    forIdentifier: HKCharacteristicTypeIdentifier.activityMoveMode)!)
            case .characteristicDateOfBirth:
                readSet.insert(HKObjectType.characteristicType(
                    forIdentifier: HKCharacteristicTypeIdentifier.dateOfBirth)!)
            case .characteristicBiologicalSex:
                readSet.insert(HKObjectType.characteristicType(
                    forIdentifier: HKCharacteristicTypeIdentifier.biologicalSex)!)
            case .characteristicBloodType:
                readSet.insert(HKObjectType.characteristicType(
                    forIdentifier: HKCharacteristicTypeIdentifier.bloodType)!)
            case .characteristicFitzpatrickSkinType:
                readSet.insert(HKObjectType.characteristicType(
                    forIdentifier: HKCharacteristicTypeIdentifier.fitzpatrickSkinType)!)
            case .characteristicWheelchairUse:
                readSet.insert(HKObjectType.characteristicType(
                    forIdentifier: HKCharacteristicTypeIdentifier.wheelchairUse)!)
            case .workouts, .workoutRoute, .workoutSplits:
                readSet.insert(HKObjectType.workoutType())
                readSet.insert(HKSeriesType.workoutRoute())
                readSet.insert(HKSampleType.quantityType(forIdentifier: .appleExerciseTime)!)
                if #available(iOS 18.0, *) {
                    readSet.insert(HKObjectType.quantityType(forIdentifier: .workoutEffortScore)!)
                }
            case .activitiesSummary:
                readSet.insert(HKObjectType.activitySummaryType())
            case .distance:
                readSet.insert(HKObjectType.quantityType(forIdentifier: .distanceCycling)!)
                readSet.insert(HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!)
                if #available(iOS 18.0, *) {
                    readSet.insert(HKObjectType.quantityType(forIdentifier: .distanceRowing)!)
                    readSet.insert(HKObjectType.quantityType(forIdentifier: .distancePaddleSports)!)
                }
                readSet.insert(HKObjectType.quantityType(forIdentifier: .distanceSwimming)!)
            case .calories:
                readSet.insert(HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!)
                readSet.insert(HKSampleType.quantityType(forIdentifier: .basalEnergyBurned)!)  // resting energy
                //                readSet.insert(HKSampleType.quantityType(forIdentifier:. dietaryEnergyConsumed)!)
            case .steps:
                readSet.insert(HKObjectType.quantityType(forIdentifier: .stepCount)!)
            case .heart:
                readSet.insert(HKObjectType.quantityType(forIdentifier: .heartRate)!)
                readSet.insert(HKSampleType.quantityType(forIdentifier: .walkingHeartRateAverage)!)
                readSet.insert(HKSampleType.quantityType(forIdentifier: .restingHeartRate)!)
                readSet.insert(HKSampleType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!)
                readSet.insert(
                    HKSampleType.quantityType(forIdentifier: .heartRateRecoveryOneMinute)!)
            case .sleep:
                readSet.insert(HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!)
                readSet.insert(HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!)
            case .oxygenSaturation:
                readSet.insert(HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!)
            case .vo2Max:
                readSet.insert(HKQuantityType.quantityType(forIdentifier: .vo2Max)!)  // ml/(kg*min) Discrete
            case .flightsClimbed:
                readSet.insert(HKSampleType.quantityType(forIdentifier: .flightsClimbed)!)
            case .body:
                readSet.insert(HKQuantityType.quantityType(forIdentifier: .bodyMass)!)  // A quantity sample type that measures the user’s weight.
                readSet.insert(HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!)  // A quantity sample type that measures the user’s body fat percentage.
                readSet.insert(HKQuantityType.quantityType(forIdentifier: .bodyMassIndex)!)  // A quantity sample type that measures the user’s body mass index.
                readSet.insert(HKQuantityType.quantityType(forIdentifier: .leanBodyMass)!)  // A quantity sample type that measures the user’s lean body mass.
                readSet.insert(HKQuantityType.quantityType(forIdentifier: .bodyTemperature)!)
                readSet.insert(HKQuantityType.quantityType(forIdentifier: .basalBodyTemperature)!)
                readSet.insert(HKSampleType.quantityType(forIdentifier: .height)!)  // A quantity sample type that measures the user’s height.
                readSet.insert(HKSampleType.quantityType(forIdentifier: .waistCircumference)!)  // A quantity sample type that measures the user’s waist circumference.
                
                readSet.insert(HKSampleType.quantityType(forIdentifier: .appleSleepingWristTemperature)!)
            case .electrocardiogram:
                readSet.insert(
                    HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.electrodermalActivity)!)
            case .breathing:
                Log(
                    "ForkSDK.ensurePermissionsAreGranted called with unsupported data types",
                    onLevel: .error
                )
                return completion(.failure(ForkError.notImplemented))
            case .glucose:
                readSet.insert(HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!)
                
            case .cycling:
                if #available(iOS 17.0, *) {
                    readSet.insert(HKQuantityType.quantityType(forIdentifier: .cyclingCadence)!)
                    readSet.insert(
                        HKQuantityType.quantityType(
                            forIdentifier: .cyclingFunctionalThresholdPower)!)
                    readSet.insert(HKQuantityType.quantityType(forIdentifier: .cyclingPower)!)
                    readSet.insert(HKQuantityType.quantityType(forIdentifier: .cyclingSpeed)!)
                }
            case .walking:
                readSet.insert(
                    HKObjectType.quantityType(
                        forIdentifier: HKQuantityTypeIdentifier.appleWalkingSteadiness)!)
                readSet.insert(
                    HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.walkingSpeed)!
                )
                readSet.insert(
                    HKObjectType.quantityType(
                        forIdentifier: HKQuantityTypeIdentifier.walkingStepLength)!)
                readSet.insert(
                    HKObjectType.quantityType(
                        forIdentifier: HKQuantityTypeIdentifier.walkingAsymmetryPercentage)!)
                readSet.insert(
                    HKObjectType.quantityType(
                        forIdentifier: HKQuantityTypeIdentifier.walkingDoubleSupportPercentage)!)
                readSet.insert(
                    HKObjectType.quantityType(
                        forIdentifier: HKQuantityTypeIdentifier.walkingHeartRateAverage)!)
                
                readSet.insert(HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stairAscentSpeed)!)
                readSet.insert(HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stairDescentSpeed)!)
                
            case .running:
                readSet.insert(
                    HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.runningSpeed)!
                )
                readSet.insert(
                    HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.runningPower)!
                )
                readSet.insert(
                    HKObjectType.quantityType(
                        forIdentifier: HKQuantityTypeIdentifier.runningGroundContactTime)!)
                readSet.insert(
                    HKObjectType.quantityType(
                        forIdentifier: HKQuantityTypeIdentifier.runningStrideLength)!)
                readSet.insert(
                    HKObjectType.quantityType(
                        forIdentifier: HKQuantityTypeIdentifier.runningVerticalOscillation)!)
            case .swimming:
                readSet.insert(HKQuantityType.quantityType(forIdentifier: .distanceSwimming)!)
                readSet.insert(HKQuantityType.quantityType(forIdentifier: .swimmingStrokeCount)!)
                readSet.insert(HKQuantityType.quantityType(forIdentifier: .waterTemperature)!)
                readSet.insert(HKQuantityType.quantityType(forIdentifier: .underwaterDepth)!)
            case .paddle:
                if #available(iOS 18.0, *) {
                    readSet.insert(HKObjectType.quantityType(forIdentifier: .distancePaddleSports)!)
                    readSet.insert(HKObjectType.quantityType(forIdentifier: .paddleSportsSpeed)!)
                }
            case .rowing:
                if #available(iOS 18.0, *) {
                    readSet.insert(HKObjectType.quantityType(forIdentifier: .distanceRowing)!)
                }
//            default:
//                Log(
//                    "ForkSDK.ensurePermissionsAreGranted called with unsupported data types",
//                    onLevel: .error)
//                return completion(.failure(ForkError.notImplemented))
            }
        }

        forkStore.requestAuthorization(
            for: readSet,
            completion: { success in
                if success {
                    Log("ForkSDK.requestAuthorization called with status success", onLevel: .info)
                    // Need to be called when the app launches
                    // forkStore.setUpBackgroundDeliveryForDataTypes(for: [])
                } else {
                    Log("ForkSDK.requestAuthorization called with error", onLevel: .info)
                }
                completion(.success(success))
            })
    }

    /// Verifies that platform-specific permissions corresponding to the Fork data types provided are granted. In the event that some permissions are not granted, a platform-specific permissions dialogue will be presented to the end-user
    /// Provide permissions to access iOS HealthKit data.
    /// SDK methods will check required permissions and request them if needed.
    ///
    /// - Parameter dateTypes: Set of required write data types ForkDataTypes
    /// - Parameter completion: Callback
    public func ensureWritePermissionsAreGranted(
        for dateTypes: Set<ForkStoreDataTypes>,
        completion: @escaping (Result<Bool, ForkError>) -> Void
    ) {
        guard let forkStore = self.forkStore else {
            Log("ForkSDK ForkStore is not available", onLevel: .error)
            return completion(.failure(ForkError.healthDataNotAvailable))
        }
        guard self.appId != nil, self.authToken != nil else {
            Log("ForkSDK.configure needs to be called first", onLevel: .error)
            return completion(.failure(.notConfigured))
        }

        var writeSet = Set<HKSampleType>()
        for dateType in dateTypes {
            switch dateType {
            case .bodyMass:
                writeSet.insert(HKQuantityType.quantityType(forIdentifier: .bodyMass)!)
            default:
                Log(
                    "ForkSDK.ensurePermissionsAreGranted called with unsupported data types",
                    onLevel: .error)
                return completion(.failure(ForkError.notImplemented))
            }
        }

        forkStore.requestWriteAuthorization(
            for: writeSet,
            completion: { success in
                if success {
                    Log(
                        "ForkSDK.requestWriteAuthorization called with status success",
                        onLevel: .info)
                    // Need to be called when the app launches
                    // forkStore.setUpBackgroundDeliveryForDataTypes(for: [])
                } else {
                    Log("ForkSDK.requestWriteAuthorization called with error", onLevel: .info)
                }
                completion(.success(success))
            })
    }

    /// Check if Health Store data available on the device
    public static func isHealthDataAvailable() -> Bool {
        return ForkStore.isHealthDataAvailable()
    }

    /// Creates a new ForkConnection instance with the given user details
    ///
    /// - Parameters:
    ///     - callbackUrl: URL that will receive webhook notifications
    public func createConnection(callbackUrl: String? = nil) -> ForkConnection? {
        guard let forkStore = self.forkStore, let appId = self.appId, let authToken = self.authToken
        else {
            Log(
                "ForkSDK.configure needs to be called first or ForkStore is not available",
                onLevel: .error)
            return nil
        }
        //        guard let customerEndUserId = self.customerEndUserId else {
        //            Log("ForkSDK.setCustomerEndUserId needs to be called first", onLevel: .error)
        //            return nil
        //        }
        return ForkConnection(
            forkStore: forkStore,
            appId: appId,
            authToken: authToken,
            endUserId: customerEndUserId,
            transformer: self.transformer,
            callbackUrl: callbackUrl,
            region: self.region
        )
    }

    /// Returns all connections that are configured to deliver data in the background
    // TODO: implement support for background connections
    public func getBackgroundConnections() throws {
        throw ForkError.notImplemented
    }

}
