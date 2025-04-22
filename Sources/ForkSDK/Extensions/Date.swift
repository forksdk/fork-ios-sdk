//
//  Date+Extension.swift
//  
//
//  Created by Aleksandras Gaidamauskas on 18/04/2024.
//

import Foundation


extension Date {
    // Get Date of start of a current week
    static func mondayAt12AM() -> Date {
        return Calendar(identifier: .iso8601).date(from: Calendar(identifier: .iso8601).dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
    }
    
//    static func sundayAt12AM() -> Date {
//        return Calendar(identifier: .iso8601).date(from: Calendar(identifier: .iso8601).dateComponents([.yearForWeekOfYear], from: Date()))!
//    }

    static func from(year: Int, month: Int, day: Int) -> Date {
        let components = DateComponents(year: year, month: month, day: day)
        return Calendar.current.date(from: components)!
    }
    
    /// Method to return String in format: "yyyy-MM-dd HH:mm:ss" from Date instance.
    ///
    /// - Returns: String
    func toFullDateTimeString() -> String {
        DateHelper.toFullDateTimeString(from: self)
    }

    /// Method to return String in format: "yyyy-MM-dd" from Date instance.
    ///
    /// - Returns: String
    func toFullDateString() -> String {
        DateHelper.toFullDateString(from: self)
    }
}


private struct DateHelper {
    static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()

        formatter.locale = Locale.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()

        formatter.locale = Locale.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func toFullDateTimeString(from date: Date) -> String {
        DateHelper.dateTimeFormatter.string(from: date)
    }

    static func toFullDateString(from date: Date) -> String {
        DateHelper.dateFormatter.string(from: date)
    }
}
