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

| Class           | Method                      | Description                                                                                                                         |
| --------------- | --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| ForkConnection  | getAppId                    | Retrieves the unique application identifier.<br />**Returns:** appId (String)                                                       |
| ForkConnection  | getCustomerEndUserId        | Retrieves the unique identifier assigned to the end-user by the customer.<br />**Returns:** customerEndUserId (String)              |
| ForkConnection  | getCallbackUrl              | Retrieves the URL that will receive webhook notifications.<br />**Returns:** callbackUrl (String)                                   |
| ForkConnection  | close                       | Terminates any ongoing connections with backend servers, clears any caches, and removes provided user details and tokens from the memory. Once the connection is closed, it cannot be used, and any method other than close() will throw a _connectionIsClosed_ exception.                                                      |
| ForkConnection  | fetchNormalizedData         | Fetch and extracts local device data for the current date in the end-user’s time zone. Optionally time range can be provided.<br />**\*The maximum allowed single-query time interval is 30 days. If required, data of any longer time period can be accessed by iterating multiple queries of 30 days.**<br />**Parameters:** dataType ([ForkDataTypes](#fork_data_types), The data type to make extraction for), from? (Date, Extraction time range start date), to? (Date, Extraction time range end date) <br />**Returns:** An instance of ForkData. The concrete type will depend on the data type requested.                                                                                                       |
| ForkConnection  | fetchAndPostNormalizedData  | Extracts local device data for the current date in the local user time zone and sends it as a webhook notification to the customer’s backend. Optionally time range can be provided.<br />**Parameters:** dataType ([ForkDataTypes](#fork_data_types), The Fork data type to make extraction for), from? (Date, Extraction time range start date), to? (Date, Extraction time range end date)                                                                                                                         |
| ForkConnection  | enableBackgroundDelivery    | Register connection for background deliveries.<br />**Parameters:** dataTypes (Array\<[ForkDataTypes](#fork_data_types)>, The Fork data type to make extraction for)                                                                                                                                                          |
| ForkConnection  | setBackgroundDeliveryLogger | Sets a listener that is to handle notifications from the background delivery process.<br />**Parameters:** listener ([ForkBackgroundDeliveriesLogger](#class_ForkBackgroundDeliveriesLogger))<br />**\*If listener is not null, then any existing listener is replaced**                                  |

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
