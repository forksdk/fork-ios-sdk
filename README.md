# Fork SDK for iOS

Fork Swift SDK is a library on top of HealthKit that helps with the data extraction and normalisation.
It provides a unified single schema across all source datasets.


# Table of contents

- [Todo](#todo)
- [Requirements](#requirements)
- [Installation](#installation)
- [Setup](#setup)
- [SDK usage](#sdk_usage)
  1. [Configure ForkSDK](#configure)
  2. [Create connection](#create_connection)
  3. [Permissions](#permissions)
  4. [Extract data](#extract_data)
- [Background deliveries](#background_deliveries)
- [Logging](#logging)
- [Fork Data types](#Fork_data_types)
- [Classes](#classes)
- [Errors and Exceptions](#exceptions)
- [Testing](#testing)
- [Data Samples](#data_samples)
- [Links](#links)

## Todo <a name="todo"></a>

- [ ] Implement `characteristic`
- [ ] Add HKMetadataKeyIndoorBikeDistance, HKPhysicalEffortEstimationType, HKSWOLFScore, HKSwimmingStrokeStyle
- [ ] Add height, leanBodyMass, oxygenSaturation, vo2Max, walkingHeartRateAverage
- [ ] Serialize data to [Open mHealth compliant JSON](https://www.openmhealth.org), [Fast Healthcare Interoperability Resources (FHIR)](http://hl7.org/fhir/R4/) or [FSH (FHIR Shorthand)](https://hl7.org/fhir/uv/shorthand/)) formats rather than custom format
- [ ] Add a new `ForkDataTypes` type to allow retrieving Workouts by workout type rather than all workouts.
- [ ] Don't create a new connection if one with same the `appId`, `authToken` and `customerEndUserId` and `callBackUrl` already exists.
- [ ] Add BackgroundTask handler
- [ ] Add tests
- [ ] Add support for long running queries https://developer.apple.com/documentation/healthkit/reading_data_from_healthkit#2962445
- [ ] Add support for Saving data to HealthKit
- [ ] Send unknown data type to internal monitoring tool which will log data on private endpoint. What about HIIPA then?
- [ ] Do we really need to `Allow Clinical Health Records`?
- [ ] FHIR, HL7v2, and DICOM formats

## Requirements <a name="requirements"></a>

- iOS 13.0+
- Xcode 15+
- Swift 5+

## Instalation <a name="installation"></a>

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the swift compiler. To integrate SpikeSDK into your Xcode project using Swift Package Manager, add it in your `Package.swift` or through the Project's Package Dependencies tab:

```swift
dependencies: [
    .package(url: "https://github.com/forksdk/fork-ios-sdk", .upToNextMinor(from: "1.0.0"))
]
```

Alternatively, you can add a package dependency using [Xcode](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app).

### Signing & Capabilities

To add HealthKit support to your application's Capabilities.

- Open the folder of your project in Xcode
- Select the project name in the left sidebar
- Open `Signing & Capabilities` section
- In the main view select `+ Capability` and double click `HealthKit`
- Allow `Clinical Health Records` and `Background Delivery` if needed.

### Info.plist

Add Health Kit permissions descriptions to your Info.plist file.
For projects created using Xcode 13 or later, set the usage key in the Target Properties list on the app’s Info tab.
For projects created with Xcode 12 or earlier, set it in the apps Info.plist file.

```xml
<key>NSHealthShareUsageDescription</key>
<string>We will use your health information to better track workouts.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>We will update your health information to better track workouts.</string>

<key>NSHealthClinicalHealthRecordsShareUsageDescription</key>
<string>We will use your health information to better track  workouts.</string>
```

You can find more details [https://developer.apple.com/documentation/healthkit/setting_up_healthkit](https://developer.apple.com/documentation/healthkit/setting_up_healthkit).

## SDK usage <a name="sdk_usage"></a>

All Fork SDK async method calls should be wrapped into try catch block.

### 1. Configure ForkSDK <a name="configure"></a>

To set up the Fork SDK call `ForkSDK.shared.configure` with appId, authToken, region and optional param loggers.
The SDK automatically manages connection persistence and restore connection if it finds one with the same appId, authToken and customerEndUserId.
With each new connection creating a call `callbackUrl` could be overridden.
Provide one or list of ForkLogging implementations for logging purposes.

```swift
import ForkSDK

ForkSDK.shared.configure(appId: "fork-demo-app", authToken: "super-secret-auth-token", loggers: [ForkConsoleLogger()])
```

```swift
import ForkSDK

ForkSDK.shared.setCustomerEndUserId(customerEndUserId: "demoEndUserId")
```

### 2. Create connection <a name="create_connection"></a>

To set up the SDK create [ForkConnection](#class_ForkConnection) instance with `appId`, `authToken`, `customerEndUserId` set using [Fork](#class_Fork) and optional params `callbackUrl`.
You can find the application ID and authentication token in the Fork developer console.
Personal identifiable information, such as emails, should not be part of user IDs.`SDK automatically manages connection persistence and restore connection if it finds one with the same`appId`, `authToken`and`customerEndUserId`.
With each new connection creating a call `callbackUrl`.
Provide [ForkLogging](#class_ForkLogging) implementation to handle connection logs.

```swift
import ForkSDK

var forkConnection = ForkSDK.createConnection(
  callbackUrl: callbackUrl // Optional, provides functionality to send data to webhook and use background deliveries.
);
```

### 3. Permissions <a name="permissions"></a>

Provide permissions to access iOS HealthKit data. SDK method will check required permissions and request them if needed. Permission dialog may not be shown according on iOS permissions rules.

```swift
// conn was created in the previous step

// Method should be called on ForkSDK class
try await ForkSDK.ensurePermissionsAreGranted(permissions: [
    ForkDataTypes.workouts,
    ForkDataTypes.steps
]) // Provide required data types
```

### 4. Extract data <a name="extract_data"></a>

### Getting and using data

Once a connection has been created data can be retrieved using the `fetchNormalizedData` method. The below example shows how to retrieve daily steps for today which are returned as part of the activities summary (An instance of `ForkData`). The concrete type will depend on the data type requested.

```swift
// forkConnection was created in the previous step

forkConnection.fetchNormalizedData(
    ForkDataTypes.steps
) { result in
    switch result {
    case .success(let data):
        if let dataItem = data.data.first {
            self.steps = dataItem.data[ForkDataTypes.steps.rawValue]
        }
    case .failure(let error):
        print("Error: \(error.localizedDescription)")
    }
}
```

### Extracting data by time range

Params from and to enable the extraction of local device data for the given time range. The maximum allowed single-query time interval is 7 days. If required, data of any longer time period can be accessed by iterating multiple queries of 7 days.

```swift
let calendar = Calendar.current

let toDate = Date() // Today's date
let fromDate = calendar.date(byAdding: .day, value: -7, to: toDate)!

// forkConnection was created in the previous step

// Get Weekly Steps
forkConnection.fetchNormalizedData(
    ForkDataTypes.steps,
    from: fromDate,
    to: toDate
) { result in
    switch result {
    case .success(let data):
        if let dataItem = data.data.first {
            self.steps = dataItem.data[ForkDataTypes.steps.rawValue]
        }
    case .failure(let error):
        print("Error: \(error.localizedDescription)")
    }
}
```

## Background deliveries <a name="background_deliveries"></a>

Background delivery enables asynchronous data delivery to the customer backend by means of webhooks. It enables data updates to be sent to the backend even when the application is hidden or closed. Background delivery is only supported on iOS devices at the moment. Background deliveries will send whole day data to the webhook.

### Configure for background deliveries

Under your project `Signing & Capabilities` section enable `Background Delivery` for `HealthKit`.
Call `configure` methods on each app start to trigger background deliveries tasks.
Add Fork initialization code to your `AppDelegate` inside `application:didFinishLaunchingWithOptions:` method.

> If you plan on supporting background delivery, you need to set up all observer queries in your app delegate. The SDK will do it by calling the `configure()` method. Read more [Receive Background Updates](https://developer.apple.com/documentation/healthkit/hkhealthstore/1614175-enablebackgrounddelivery#3801028).

```swift
import Fork
...

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    ...
    ForkSDK.shared.configure(appId: "fork-demo-app", authToken: "super-secret-auth-token")
    ...
}
```

For SwiftUI based apps follow few steps:

1. Create a custom class that inherits from NSObject and conforms to the UIApplicationDelegate protocol, like this:

```swift
import Fork
...

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        ...
            ForkSDK.shared.configure(appId: "fork-demo-app", authToken: "super-secret-auth-token")
        ...
        return true
    }
}
```

2. And now in your App scene, use the UIApplicationDelegateAdaptor property wrapper to tell SwiftUI it should use your AppDelegate class for the application delegate.

```swift
@main
struct AppNameApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Register connection for background deliveries

Ensure `callbackUrl` was provided to [ForkConnection](#class_ForkConnection), otherwise you will get `ForkError.callbackUrlNotProvided` error.
Provide required [Fork Data types](#fork_data_types) to `enableBackgroundDelivery` method, it could be called after connection is created.

```swift
// forkConnection was created in the previous step

try await forkConnection.enableBackgroundDelivery(dataTypes: [
    ForkDataTypes.workouts,
    ForkDataTypes.steps
])
```

- If `forTypes` is not empty, then a daemon task is started which will listen for data updates coming from the platform and send them via webhooks in the background; the operation is not compound and each method call will override enabled background data types list;

- If `forTypes` parameter is empty or null, then background data delivery is stopped for this connection if it was enabled;

You can check if connection have active background deliveries listeners. If background delivery is not enabled, an empty set is returned.

```swift
let dataTypes = try await forkConnection.getBackgroundDeliveryDataTypes()
```

## Logging <a name="logging"></a>

Internally, the iOS SDK supports logging on various levels to assist with troubleshooting. However, to avoid imposing additional third-party dependencies on library users, the SDK expects a concrete logging implementation to be provided externally. This can be done by implementing the [ForkLogging](#class_ForkLogging) class and providing it when creating a connection.

Below is an example of how to implement a simple console logger.

```swift
import Fork

public class ForkConsoleLogger: ForkLogging {
    public var levels: [ForkLoggerLevel] = [.info, .debug, .warn, .error]

    public func log(_ message: String, onLevel level: ForkLoggerLevel) {
        print("\(messageHeader(forLevel: level)) \(message)")
    }
}
```

SDK provides background delivery process logs. This can be done by implementing the [ForkBackgroundDeliveriesLogger](#class_ForkBackgroundDeliveriesLogger) class and providing it though connection's `setBackgroundDeliveryLogger` method.

Below is an example of how to implement a simple console logger.

```swift
class BackgroundDeliveriesLogger: ForkBackgroundDeliveriesLogger {
    func onBackgroundLog(log: String) {
        print("[BACKGROUND_LOG] \(log)")
    }
}
```

## Fork Data types <a name="fork_data_types"></a>

- ForkDataTypes.workouts
- ForkDataTypes.activitiesSummary
- ForkDataTypes.breathing
- ForkDataTypes.calories
- ForkDataTypes.distance
- ForkDataTypes.glucose
- ForkDataTypes.heart
- ForkDataTypes.oxygenSaturation
- ForkDataTypes.sleep
- ForkDataTypes.steps

### Fork <a name="class_Fork"></a>

| Class | Method                      | Description                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| ----- | --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Fork  | configure                   | Allow SDK to setup background deliveries handlers.<br />**Parameters:** appId (String, The unique application identifier), authToken (String, The authentification token assigned by Fork)                                                                                                                                                                                                                                                         |
| Fork  | getAppId                    | Retrieves the unique application identifier.<br />**Returns:** appId (String)                                                                                                                                                                                                                                                                                                                                                                       |
| Fork  | getAuthToken                | Retrieves the authentication token.<br />**Returns:** authToken (String)                                                                                                                                                                                                                                                                                                                                                                            |
| Fork  | setCustomerEndUserId        | Sets The unique identifier assigned to the end-user by the customer.<br />**Parameters:** customerEndUserId (String).                                                                                                                                                                                                                                                                                                                               |
| Fork  | getCustomerEndUserId        | Retrieves the unique identifier assigned to the end-user by the customer.<br />**Returns:** customerEndUserId (String)                                                                                                                                                                                                                                                                                                                              |
| Fork  | isHealthDataAvailable       | Check if Health Store data available on the device.<br />**Returns:** isAvailable (Bool)                                                                                                                                                                                                                                                                                                                                                            |
| Fork  | createConnection            | Creates a new ForkConnection instance with the given user details.<br />**Parameters:** customerEndUserId (String, The unique identifier assigned to the end-user by the customer), callbackUrl? (String, URL that will receive webhook notifications), region ([ForkRegion](#type_ForkRegion)), logger? ([ForkLogging](#class_ForkLogging)) .<br />**Returns:** An instance of the ForkConnection class ([ForkConnection](#class_ForkConnection)). |
| Fork  | ensurePermissionsAreGranted | Verifies that platform-specific permissions corresponding to the Fork data types provided are granted. In the event that some permissions are not granted, a platform-specific permissions dialogue will be presented to the end-user.<br />**Parameters:** permissions (Array\<[ForkDataTypes](#fork_data_types)>)                                                                                                                                 |
| Fork  | isHealthDataAvailable       | Check if Health Store data available on the device.<br />**Returns:** isAvailable (Bool)                                                                                                                                                                                                                                                                                                                                                            |
| Fork  | getBackgroundConnections    | Returns all connections that are configured to deliver data in the background.<br />**Returns:** An array of ForkConnection instances with callbackUrl (Array\<[ForkConnection](#class_ForkConnection)>).                                                                                                                                                                                                                                           |

### ForkConnection <a name="class_ForkConnection"></a>

| Class          | Method                      | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| -------------- | --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --- |
| ForkConnection | getAppId                    | Retrieves the unique application identifier.<br />**Returns:** appId (String)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| ForkConnection | getCustomerEndUserId        | Retrieves the unique identifier assigned to the end-user by the customer.<br />**Returns:** customerEndUserId (String)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| ForkConnection | getCallbackUrl              | Retrieves the URL that will receive webhook notifications.<br />**Returns:** callbackUrl (String)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| ForkConnection | close                       | Terminates any ongoing connections with backend servers, clears any caches, and removes provided user details and tokens from the memory. Once the connection is closed, it cannot be used, and any method other than close() will throw a _connectionIsClosed_ exception.                                                                                                                                                                                                                                                                                                                               |
| ForkConnection | fetchNormalizedData        | Fetch and extracts local device data for the current date in the end-user’s time zone. Optionally time range can be provided.<br />**\*The maximum allowed single-query time interval is 30 days. If required, data of any longer time period can be accessed by iterating multiple queries of 30 days.**<br />**Parameters:** dataType ([ForkDataTypes](#fork_data_types), The data type to make extraction for), from? (Date, Extraction time range start date), to? (Date, Extraction time range end date) <br />**Returns:** An instance of ForkData. The concrete type will depend on the data type requested |
| ForkConnection | fetchAndPostNormalizedData  | Extracts local device data for the current date in the local user time zone and sends it as a webhook notification to the customer’s backend. Optionally time range can be provided.<br />**Parameters:** dataType ([ForkDataTypes](#fork_data_types), The Fork data type to make extraction for), from? (Date, Extraction time range start date), to? (Date, Extraction time range end date)                                                                                                                                                                                                            |
| ForkConnection | enableBackgroundDelivery    | Register connection for background deliveries.<br />**Parameters:** dataTypes (Array\<[ForkDataTypes](#fork_data_types)>, The Fork data type to make extraction for)                                                                                                                                                                                                                                                                                                                                                                                                                                     |     |
| ForkConnection | setBackgroundDeliveryLogger | Sets a listener that is to handle notifications from the background delivery process.<br />**Parameters:** listener ([ForkBackgroundDeliveriesLogger](#class_ForkBackgroundDeliveriesLogger))<br />**\*If listener is not null, then any existing listener is replaced**                                                                                                                                                                                                                                                                                                                                 |

### ForkLogging <a name="class_ForkLogging"></a>

Abstract class allowing to receive notifications from the SDK's processes.

| Class       | Method    | Description                                                                                                                         |
| ----------- | --------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| ForkLogging | levels    | Property to set and get a List of allowed logging level.<br />**Parameters**: connection ([ForkLoggerLevel](#type_ForkLoggerLevel)) |
| ForkLogging | configure | This method will be called when a logger will be added.                                                                             |
| ForkLogging | log       | **Parameters**: message (String), level: connection ([ForkLoggerLevel](#type_ForkLoggerLevel))                                      |

### ForkBackgroundDeliveriesLogger <a name="class_ForkBackgroundDeliveriesLogger"></a>

Abstract class allowing to receive notifications from the background data delivery process.

| Class                          | Method          | Description                                                                |
| ------------------------------ | --------------- | -------------------------------------------------------------------------- |
| ForkBackgroundDeliveriesLogger | onBackgroundLog | Invoked on background deliveries events.<br />**Parameters**: log (String) |

### ForkLoggerLevel <a name="type_ForkLoggerLevel"></a>

Type required to set Fork Logger level.

- ForkLoggerLevel.error
- ForkLoggerLevel.warn
- ForkLoggerLevel.info
- ForkLoggerLevel.debug
- ForkLoggerLevel.verbose

### ForkRegion <a name="type_ForkRegion"></a>

Type required to set region.

- ForkRegion.US
- ForkRegion.EU

## Errors and Exceptions <a name="exceptions"></a>

### ForkError

- ForkError.generalError
- ForkError.notConfigured
- ForkError.invalidURL
- ForkError.noData
- ForkError.decodingError
- ForkError.encodingError
- ForkError.badRequest
- ForkError.unauthorized
- ForkError.notFound
- ForkError.healthDataNotAvailable
- ForkError.healthDataError
- ForkError.callbackUrlNotProvided
- ForkError.connectionIsClosed

## Testing <a name="testing"></a>

There is a way to add sample data to simulator https://developer.apple.com/documentation/healthkit/samples/accessing_sample_data_in_the_simulator

## Data Samples <a name="data_samples"></a>

### Steps

```json
{
  "start_date": 734946736.721469,
  "end_date": 735465136.721469,
  "source": [],
  "meta_data": {},
  "type": "steps",
  "data": [
    {
      "name": "steps",
      "meta_data": {},
      "id": "3D1763C4-74E3-48B6-A2F4-1717A1CCEAA4",
      "start_date": 734946736.721469,
      "data": {
        "steps": [
          {
            "id": "C901465E-96CB-4B9F-A608-F19524A2373F",
            "end_date": 734994000,
            "value": { "unit": "count", "quantity": 2344.558345717989 },
            "start_date": 734907600
          },
          {
            "id": "153B48D2-917D-43C5-96A4-1704CB7B65A2",
            "value": { "quantity": 4294.453550610938, "unit": "count" },
            "end_date": 735080400,
            "start_date": 734994000
          },
          {
            "value": { "quantity": 8930, "unit": "count" },
            "id": "48F1FDCA-5445-473E-AAF4-C168A558D257",
            "end_date": 735166800,
            "start_date": 735080400
          },
          {
            "start_date": 735166800,
            "end_date": 735253200,
            "id": "0A777063-E86D-47F9-AAA1-A551F66EA87E",
            "value": { "quantity": 4892, "unit": "count" }
          },
          {
            "start_date": 735253200,
            "id": "DD8542FB-47D3-4677-A776-05CBB9702C9E",
            "value": { "quantity": 6376.525936660553, "unit": "count" },
            "end_date": 735339600
          },
          {
            "end_date": 735426000,
            "value": { "quantity": 7647, "unit": "count" },
            "id": "0EC90C44-5F34-4EAA-9DAA-1ADF953B3F4F",
            "start_date": 735339600
          },
          {
            "end_date": 735512400,
            "value": { "quantity": 984, "unit": "count" },
            "id": "34FACA12-3DFB-4DEC-9DEA-016AC2BBBDED",
            "start_date": 735426000
          }
        ]
      },
      "end_date": 735465136.721469
    }
  ],
  "user_id": "demoEndUserId",
  "collected_at": 735465136.778602
}
```

### Activities

```json
{
  "collected_at": 735480150.573357,
  "end_date": 735480150.549528,
  "type": "workouts",
  "data": [
    {
      "nested_data": {
        "workoutActivity_A3129EDF-E02F-4C95-A489-D4BF63729A1C": [
          {
            "data": {
              "HKQuantityTypeIdentifierBasalEnergyBurned": [
                {
                  "end_date": 735126820.286514,
                  "start_date": 735122925.921942,
                  "value": { "unit": "kcal", "quantity": 104.50254033979812 }
                }
              ],
              "HKQuantityTypeIdentifierHeartRate": [
                {
                  "start_date": 735122925.921942,
                  "value": { "unit": "Hz", "quantity": 2.183333333333333 },
                  "end_date": 735126820.286514
                }
              ],
              "HKQuantityTypeIdentifierDistanceWalkingRunning": [
                {
                  "value": { "quantity": 4009.039588627405, "unit": "m" },
                  "start_date": 735122925.921942,
                  "end_date": 735126820.286514
                }
              ],
              "HKQuantityTypeIdentifierActiveEnergyBurned": [
                {
                  "start_date": 735122925.921942,
                  "value": { "unit": "kcal", "quantity": 287.4444671286329 },
                  "end_date": 735126820.286514
                }
              ]
            },
            "nested_data": {
              "workoutEvents": [
                {
                  "end_date": 735123756.3896186,
                  "start_date": 735122925.921942,
                  "name": "Segment"
                },
                {
                  "start_date": 735122925.921942,
                  "name": "Segment",
                  "end_date": 735124274.3311791
                },
                {
                  "name": "Segment",
                  "start_date": 735123756.3896186,
                  "end_date": 735124625.1821542
                },
                {
                  "name": "Segment",
                  "start_date": 735124274.3311791,
                  "end_date": 735125994.5759654
                },
                {
                  "start_date": 735124625.1821542,
                  "name": "Segment",
                  "end_date": 735125822.8282287
                },
                {
                  "end_date": 735125115.952313,
                  "start_date": 735125115.952313,
                  "name": "Pause"
                },
                {
                  "end_date": 735125130.495051,
                  "name": "Resume",
                  "start_date": 735125130.495051
                },
                {
                  "name": "Segment",
                  "start_date": 735125822.8282287,
                  "end_date": 735126727.8450862
                },
                {
                  "start_date": 735125994.5759654,
                  "end_date": 735126799.7551417,
                  "name": "Segment"
                },
                {
                  "end_date": 735126799.7551417,
                  "start_date": 735126727.8450862,
                  "name": "Segment"
                }
              ]
            },
            "end_date": 735126820.286514,
            "name": "workoutActivity_A3129EDF-E02F-4C95-A489-D4BF63729A1C",
            "start_date": 735122925.921942,
            "id": "BC87CFA2-D778-4D90-BFF3-84CE0CA4AB1A"
          }
        ]
      },
      "end_date": 735126820.286514,
      "id": "54E23D18-6468-4953-A190-60D6529B76C3",
      "start_date": 735122925.921942,
      "meta_data": {
        "HKWeatherHumidity": { "quantity": 56.99999999999999, "unit": "%" },
        "duration": { "quantity": 3879.8218339681625, "unit": "TimeInterval" },
        "HKElevationAscended": { "quantity": 116, "unit": "m" },
        "HKTimeZone": { "quantity": 0, "unit": "Europe/Vilnius" },
        "HKIndoorWorkout": { "unit": "bool", "quantity": 0 },
        "HKAverageMETs": {
          "unit": "kcal/hr·kg",
          "quantity": 4.8850719059101735
        }
      },
      "name": "Walking",
      "data": {
        "HKQuantityTypeIdentifierBasalEnergyBurned": [
          {
            "end_date": 735126820.286514,
            "start_date": 735122925.921942,
            "value": { "quantity": 104.50254033979812, "unit": "kcal" },
            "id": "25A7DBB7-FACF-4DA9-A2CF-4980AE478D81"
          }
        ],
        "HKQuantityTypeIdentifierHeartRate": [
          {
            "start_date": 735122925.921942,
            "end_date": 735126820.286514,
            "value": { "quantity": 2.183333333333333, "unit": "Hz" },
            "id": "9C941C9D-8481-4467-B876-27EAB652C78A"
          }
        ],
        "HKQuantityTypeIdentifierActiveEnergyBurned": [
          {
            "start_date": 735122925.921942,
            "end_date": 735126820.286514,
            "value": { "unit": "kcal", "quantity": 287.4444671286329 },
            "id": "CC8E0A4C-46E5-49DB-954F-3F6343E07E13"
          }
        ],
        "HKQuantityTypeIdentifierDistanceWalkingRunning": [
          {
            "end_date": 735126820.286514,
            "start_date": 735122925.921942,
            "value": { "quantity": 4009.039588627405, "unit": "m" },
            "id": "7B67626E-58BD-436A-B6EE-422425F28D67"
          }
        ]
      }
    },
    {
      "start_date": 734700495.466622,
      "end_date": 734706529.034525,
      "source": {
        "firmwareVersion": null,
        "name": "Apple Watch",
        "localIdentifier": null,
        "softwareVersion": "10.4",
        "udiDeviceIdentifier": null,
        "manufacturer": "Apple Inc.",
        "model": "Watch",
        "hardwareVersion": "Watch6,9"
      },
      "nested_data": {
        "workoutActivity_D27A81E3-CDA7-46B5-A309-6485E587AF57": [
          {
            "data": {
              "HKQuantityTypeIdentifierBasalEnergyBurned": [
                {
                  "value": { "quantity": 53.81176251367591, "unit": "kcal" },
                  "end_date": 734706529.034525,
                  "start_date": 734700495.466622
                }
              ],
              "HKQuantityTypeIdentifierActiveEnergyBurned": [
                {
                  "value": { "quantity": 45.895534867857656, "unit": "kcal" },
                  "start_date": 734700495.466622,
                  "end_date": 734706529.034525
                }
              ],
              "HKQuantityTypeIdentifierDistanceCycling": [
                {
                  "value": { "quantity": 3079.4581422669125, "unit": "m" },
                  "end_date": 734706529.034525,
                  "start_date": 734700495.466622
                }
              ],
              "HKQuantityTypeIdentifierHeartRate": [
                {
                  "start_date": 734700495.466622,
                  "end_date": 734706529.034525,
                  "value": { "unit": "Hz", "quantity": 1.9666666666666666 }
                }
              ]
            },
            "end_date": 734706529.034525,
            "nested_data": {
              "workoutEvents": [
                {
                  "start_date": 734700495.466622,
                  "name": "Segment",
                  "end_date": 734700863.9786217
                },
                {
                  "end_date": 734703725.1573002,
                  "start_date": 734700495.466622,
                  "name": "Segment"
                },
                {
                  "end_date": 734703928.8184234,
                  "start_date": 734700863.9786217,
                  "name": "Segment"
                },
                {
                  "end_date": 734701267.580869,
                  "name": "Pause",
                  "start_date": 734701267.580869
                },
                {
                  "name": "Resume",
                  "end_date": 734703631.39965,
                  "start_date": 734703631.39965
                },
                {
                  "end_date": 734706527.9993576,
                  "start_date": 734703725.1573002,
                  "name": "Segment"
                },
                {
                  "start_date": 734703928.8184234,
                  "name": "Segment",
                  "end_date": 734706391.3093979
                },
                {
                  "start_date": 734704740.18987,
                  "end_date": 734704740.18987,
                  "name": "Pause"
                },
                {
                  "end_date": 734705227.415145,
                  "name": "Resume",
                  "start_date": 734705227.415145
                },
                {
                  "end_date": 734705296.174271,
                  "start_date": 734705296.174271,
                  "name": "Pause"
                },
                {
                  "end_date": 734706118.187363,
                  "start_date": 734706118.187363,
                  "name": "Resume"
                },
                {
                  "name": "Segment",
                  "start_date": 734706391.3093979,
                  "end_date": 734706527.9993576
                },
                {
                  "end_date": 734706529.034525,
                  "name": "Pause",
                  "start_date": 734706529.034525
                }
              ]
            },
            "start_date": 734700495.466622,
            "id": "F35A8EDE-DA94-40A6-929B-32C4C04133C2",
            "name": "workoutActivity_D27A81E3-CDA7-46B5-A309-6485E587AF57"
          }
        ]
      },
      "id": "3D8F2F02-2842-48DA-9897-F0890B20442B",
      "meta_data": {
        "HKElevationAscended": { "quantity": 15.76, "unit": "m" },
        "HKIndoorWorkout": { "quantity": 0, "unit": "bool" },
        "HKAverageMETs": {
          "unit": "kcal/hr·kg",
          "quantity": 2.5574292423172995
        },
        "duration": { "unit": "TimeInterval", "quantity": 2360.510754942894 },
        "HKTimeZone": { "quantity": 0, "unit": "Europe/Vilnius" },
        "HKWeatherHumidity": { "quantity": 74, "unit": "%" }
      },
      "name": "Cycling",
      "source": {
        "name": "Apple Watch",
        "softwareVersion": "10.4",
        "firmwareVersion": null,
        "localIdentifier": null,
        "udiDeviceIdentifier": null,
        "hardwareVersion": "Watch6,9",
        "manufacturer": "Apple Inc.",
        "model": "Watch"
      },
      "data": {
        "HKQuantityTypeIdentifierActiveEnergyBurned": [
          {
            "id": "37499B34-B397-46B7-BB90-22BA772D35C1",
            "start_date": 734700495.466622,
            "value": { "quantity": 45.895534867857656, "unit": "kcal" },
            "end_date": 734706529.034525
          }
        ],
        "HKQuantityTypeIdentifierDistanceCycling": [
          {
            "id": "528A7191-1F69-4824-9259-31FF023B484D",
            "end_date": 734706529.034525,
            "value": { "unit": "m", "quantity": 3079.4581422669125 },
            "start_date": 734700495.466622
          }
        ],
        "HKQuantityTypeIdentifierHeartRate": [
          {
            "start_date": 734700495.466622,
            "end_date": 734706529.034525,
            "id": "09BCFC04-1A64-4E15-B5EF-203D0C4557AB",
            "value": { "quantity": 1.9666666666666666, "unit": "Hz" }
          }
        ],
        "HKQuantityTypeIdentifierBasalEnergyBurned": [
          {
            "id": "F6AD294E-11FE-4525-99CB-73CC7D1AD925",
            "end_date": 734706529.034525,
            "start_date": 734700495.466622,
            "value": { "quantity": 53.81176251367591, "unit": "kcal" }
          }
        ]
      }
    }
  ],
  "start_date": 734529750.549528,
  "source": [],
  "user_id": "demoEndUserId"
}
```

### Sleep

```json
{
  "user_id": "demoEndUserId",
  "type": "sleep",
  "start_date": 734696841.670022,
  "end_date": 735820041.670022,
  "collected_at": 735820041.696961,
  "data": [
    {
      "data": {
        "sleep": [
          {
            "end_date": 735790811.3217533,
            "value": { "unit": "REM", "quantity": 5 },
            "type": "HKCategoryTypeIdentifierSleepAnalysis",
            "id": "3B560752-961E-4E14-9979-3F98D0A95FB5",
            "start_date": 735790721.3217533
          },
          {
            "type": "HKCategoryTypeIdentifierSleepAnalysis",
            "id": "1123B2F6-4FA9-47F5-A7C6-7A955A0A653A",
            "start_date": 735790241.3217533,
            "end_date": 735790691.3217533,
            "value": { "unit": "REM", "quantity": 5 }
          },
          {
            "id": "37D29ECE-0FA5-49F8-B1E6-D24D8823F19E",
            "start_date": 735788891.3217533,
            "end_date": 735790241.3217533,
            "type": "HKCategoryTypeIdentifierSleepAnalysis",
            "value": { "quantity": 3, "unit": "Deep" }
          },
          {
            "end_date": 735788861.3217533,
            "value": { "quantity": 3, "unit": "Deep" },
            "id": "F1B16D09-312F-4589-809C-8723017036AF",
            "type": "HKCategoryTypeIdentifierSleepAnalysis",
            "start_date": 735788831.3217533
          },
          {
            "type": "HKCategoryTypeIdentifierSleepAnalysis",
            "start_date": 735788081.3217533,
            "value": { "quantity": 4, "unit": "4" },
            "end_date": 735788831.3217533,
            "id": "131D11B2-C448-4728-9D8A-5AE74807C6DB"
          },
          {
            "start_date": 735786101.3217533,
            "value": { "quantity": 3, "unit": "Deep" },
            "end_date": 735788081.3217533,
            "type": "HKCategoryTypeIdentifierSleepAnalysis",
            "id": "5C17D2CD-0C84-4352-8585-0A598BFEB5EC"
          },
          {
            "start_date": 735784181.3217533,
            "end_date": 735786101.3217533,
            "value": { "quantity": 5, "unit": "REM" },
            "id": "CE360689-E275-4045-A8AE-D87DBB9AF090",
            "type": "HKCategoryTypeIdentifierSleepAnalysis"
          },
          {
            "id": "58995F3B-7539-4967-BDAA-9B5893B09183",
            "value": { "unit": "REM", "quantity": 5 },
            "type": "HKCategoryTypeIdentifierSleepAnalysis",
            "end_date": 735784091.3217533,
            "start_date": 735783581.3217533
          },
          {
            "end_date": 735783581.3217533,
            "value": { "unit": "Deep", "quantity": 3 },
            "id": "C829AD5D-BC7B-4286-B77C-A53FCC2EC1F6",
            "type": "HKCategoryTypeIdentifierSleepAnalysis",
            "start_date": 735780191.3217533
          },
          {
            "start_date": 735778991.3217533,
            "end_date": 735780071.3217533,
            "value": { "unit": "4", "quantity": 4 },
            "id": "CAD485D6-95A6-446E-BF63-74797DBB838D",
            "type": "HKCategoryTypeIdentifierSleepAnalysis"
          },
          {
            "value": { "unit": "Deep", "quantity": 3 },
            "type": "HKCategoryTypeIdentifierSleepAnalysis",
            "end_date": 735778991.3217533,
            "id": "8D227DFB-9313-4561-B9DE-2D950F74CFFC",
            "start_date": 735777581.3217533
          },
          {
            "value": { "unit": "REM", "quantity": 5 },
            "end_date": 735777581.3217533,
            "start_date": 735776471.3217533,
            "type": "HKCategoryTypeIdentifierSleepAnalysis",
            "id": "CEFFF563-9118-4AC7-B663-EF0CF7B61ED7"
          },
          {
            "end_date": 735776411.3217533,
            "id": "ACB58AB9-1A38-4A94-9F2A-1DFCD8D0E10C",
            "type": "HKCategoryTypeIdentifierSleepAnalysis",
            "start_date": 735776141.3217533,
            "value": { "quantity": 5, "unit": "REM" }
          },
          {
            "type": "HKCategoryTypeIdentifierSleepAnalysis",
            "start_date": 735775451.3217533,
            "end_date": 735776141.3217533,
            "id": "E42769D7-0F84-4EE4-A8C2-C9B6CDB1DEF7",
            "value": { "quantity": 3, "unit": "Deep" }
          },
          {
            "id": "0CEEFC5D-DA25-49B5-8F47-F381B904EBF3",
            "end_date": 735775451.3217533,
            "value": { "quantity": 4, "unit": "4" },
            "start_date": 735774941.3217533,
            "type": "HKCategoryTypeIdentifierSleepAnalysis"
          },
          {
            "end_date": 735774941.3217533,
            "id": "E9C0A18C-1C36-4159-BA7A-BE76E6FC93AC",
            "value": { "quantity": 3, "unit": "Deep" },
            "type": "HKCategoryTypeIdentifierSleepAnalysis",
            "start_date": 735772721.3217533
          },
          {
            "start_date": 735772391.3217533,
            "id": "526D81FF-EAF4-4E01-8BDB-E676621BD140",
            "value": { "quantity": 3, "unit": "Deep" },
            "end_date": 735772571.3217533,
            "type": "HKCategoryTypeIdentifierSleepAnalysis"
          },
          {
            "type": "HKCategoryTypeIdentifierSleepAnalysis",
            "end_date": 735772181.3217533,
            "start_date": 735772031.3217533,
            "value": { "unit": "Deep", "quantity": 3 },
            "id": "C0A6FFC1-0700-4E92-AAAD-FBD572F7196B"
          }
        ]
      },
      "id": "C610DBF7-B056-428A-80F5-A8FC8BF60FFA",
      "name": "sleep",
      "end_date": 735772181.3217533,
      "start_date": 735790721.3217533
    }
  ]
}
```

## Publishing application on the Play Store  <a name="play_store"></a>

The ForkSDK for Android devices integrates with Health Connect for data retrieval. Before publishing the application to the Play Store, application owners are required to complete the Developer Declaration Form available at the following link: [Developer Declaration Form](https://docs.google.com/forms/d/1LFjbq1MOCZySpP5eIVkoyzXTanpcGTYQH26lKcrQUJo/viewform?edit_requested=true)

## Links <a name="links"></a>

- https://developer.apple.com/documentation/healthkit/about_the_healthkit_framework
- https://github.com/CardinalKit/Granola/blob/main/Pod/Classes/OMHSerializer.m
- https://dmtopolog.com/healthkit-changes-observing/
- https://github.com/kingstinct/react-native-healthkit
- https://www.npmjs.com/package/@jonstuebe/react-native-healthkit
- https://www.npmjs.com/package/react-native-google-fit
- https://github.com/klandell/react-native-healthier
- https://gero.dev/blog/heart-rate-graphs-with-swift-charts
- https://gitlab.com/spike_api/spike-ios-sdk
- https://cloud.google.com/healthcare-api
- https://www.avanderlee.com/swift-charts/bar-chart-creation-using-swift-charts/?utm_campaign=This%2BWeek%2Bin%2BSwift&utm_medium=email&utm_source=This_Week_in_Swift_159
- https://github.com/realm/SwiftLint
- https://github.com/Quick/Quick
- https://www.swift.org/documentation/docc/
- https://github.com/stripe/stripe-ios
- https://github.com/ResearchKit/SageResearch
- https://github.com/openmhealth/Granola
- `xcodebuild -list -json`
- `xcodebuild -resolvePackageDependencies`

## Units [HKUnit](https://developer.apple.com/documentation/healthkit/hkunit))

Unit strings are composed of the following units:

### International System of Units (SI) units:

- g (grams) [Mass]
- m (meters) [Length]
- L,l (liters) [Volume]
- Pa (pascals) [Pressure]
- s (seconds) [Time]
- J (joules) [Energy]
- K (kelvin) [Temperature]
- S (siemens) [Electrical Conductance]
- Hz (hertz) [Frequency]
- mol<molar mass> (moles) [Mass] <molar mass> is the number of grams per mole. For example, mol<180.1558>

#### SI units can be prefixed as follows:

- da (deca-) = 10 d (deci-) = 1/10
- h (hecto-) = 100 c (centi-) = 1/100
- k (kilo-) = 1000 m (milli-) = 1/1000
- M (mega-) = 10^6 mc (micro-) = 10^-6
- G (giga-) = 10^9 n (nano-) = 10^-9
- T (tera-) = 10^12 p (pico-) = 10^-12

### Non-SI units:

#### [Mass]

- oz (ounces) = 28.3495 g
- lb (pounds) = 453.592 g
- st (stones) = 6350.0 g

#### [Length]

- in (inches) = 0.0254 m
- ft (feet) = 0.3048 m
- mi (miles) = 1609.34 m

#### [Pressure]

- mmHg (millimeters of mercury) = 133.3224 Pa
- cmAq (centimeters of water) = 98.06650 Pa
- atm (atmospheres) = 101325.0 Pa

#### [Volume]

- fl_oz_us (US customary fluid ounces)= 0.0295735295625 L
- fl_oz_imp (Imperial fluid ounces) = 0.0284130625 L
- pt_us (US customary pint) = 0.473176473 L
- pt_imp (Imperial pint) = 0.56826125 L
- cup_us (US customary cup) = 0.2365882365 L
- cup_imp (Imperial cup) = 0.284130625 L

#### [Time]

- min (minutes) = 60 s
- hr (hours) = 3600 s
- d (days) = 86400 s

#### [Energy]

- cal (calories) = 4.1840 J
- kcal (kilocalories) = 4184.0 J

#### [Temperature]

- degC (degrees Celsius) = 1.0 K - 273.15
- degF (degrees Fahrenheit) = 1.8 K - 459.67

#### [Conductance]

- S (siemens)

#### [Pharmacology]

- IU (international unit)

#### [Scalar]

- count = 1
- % = 1/100

Units can be combined using multiplication (. or \*) and division (/), and raised to integral powers (^).
For simplicity, only a single '/' is allowed in a unit string, and multiplication is evaluated first.
So "kg/m.s^2" is equivalent to "kg/(m.s^2)" and "kg.m^-1.s^-2".

#### VO₂ Max

```swift
// let kgmin = HKUnit.gramUnit(with: .kilo).unitMultiplied(by: .minute())
// let mL = HKUnit.literUnit(with: .milli)
// let VO₂Unit = mL.unitDivided(by: kgmin)

let VO₂Unit = HKUnit(from: "ml/kg*min")

let writeHKMetric = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.vo2Max)!
let writeHKQuantity = HKQuantity(unit: VO₂Unit, doubleValue: 1)
print(writeHKQuantity)
```
