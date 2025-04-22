//
//  ForkLogManager.swift
//
//
//  Created by Aleksandras Gaidamauskas on 21/04/2024.
//

// Inspired by https://github.com/Qase/swift-logger/tree/master

import Foundation

/// :nodoc:
/// Global method that handles logging. Once the LogManager is set and all necessary loggers are registered somewhere
/// at the beginning of the application, this method can be called throughout the whole project in order to log.
///
/// - Parameters:
///   - message: String logging message
///   - level: Level of the logging message
//   swiftlint:disable:next identifier_name
public func Log(
    _ message: String,
    onLevel level: ForkLoggerLevel,
    inFile file: String = #file,
    inFunction function: String = #function,
    onLine line: Int = #line
) {
    let theFileName = (file as NSString).lastPathComponent
    ForkLogManager.shared.log(
        "\(theFileName) - \(function) - line \(line): \(message)", onLevel: level)
}

class ForkLogManager {
    public static let shared = ForkLogManager()
    private var loggers: [ForkLogging]

    private let serialLoggingQueue = DispatchQueue(label: "com.fork.loggerSerial", qos: .background)

    private init() {
        loggers = [ForkLogging]()
    }

    /// Method to register a new custom or pre-build logger.
    ///
    /// - Parameter logger: Logger to be registered
    public func add<T: ForkLogging>(_ logger: T) {
        if loggers.contains(where: { $0 is T }) {
            Log(
                "ForkLogManager does not support having multiple logger of the same type, such as two instances of FileLogger.",
                onLevel: .error
            )
            return
        }

        logger.configure()
        loggers.append(logger)
    }

    /// Method to remove a specific logger registered to the Log manager.
    ///
    /// - Parameter logger: to be removed
    public func remove<T: ForkLogging>(_ logger: T) {
        loggers.removeAll { $0 is T }
    }

    /// Method to remove all existing loggers registered to the Log manager.
    public func removeAllLoggers() {
        loggers = [ForkLogging]()
    }

    /// Method to handle logging, it is called internaly via global method Log(_, _) and thus its not visible outside
    /// of the module.
    ///
    /// - Parameters:
    ///   - message: String logging message
    ///   - level: Level of the logging message
    func log(_ message: String, onLevel level: ForkLoggerLevel) {
        logSyncSerially(message, onLevel: level)
    }

    /// Method to log synchronously towards the main thread. All loggers log serially one by one within a dedicated queue.
    ///
    /// - Parameters:
    ///   - message: to be logged
    ///   - level: to be logged on
    private func logSyncSerially(_ message: String, onLevel level: ForkLoggerLevel) {
        serialLoggingQueue.sync {
            dispatchPrecondition(condition: .onQueue(self.serialLoggingQueue))

            guard !loggers.isEmpty else {
                return
            }

            self.loggers
                .filter { $0.doesLog(forLevel: level) }
                .forEach { $0.log(message, onLevel: level) }
        }
    }

}
