//
//  ForkError.swift
//  
//
//  Created by Aleksandras Gaidamauskas on 17/04/2024.
//

import Foundation


public enum ForkError: Error {
    case generalError
    case notConfigured
    case invalidURL
    case noData
    case decodingError
    case encodingError
    case badRequest
    case unauthorized
    case notFound
    case healthDataNotAvailable
    case healthDataError
    case connectionIsClosed
    case callbackUrlNotProvided
    case notImplemented // should be removed before prod release
    case invalidValue(String = "Invalid value")
    case badEncoding(String = "Bad ecoding")
    case notAvailable(String = "HealthKit data is not available")
//    case unknown(String = "Unknown")
    case invalidType(String = "Invalid type")
    case invalidIdentifier(String = "Invalid identifier")
//    case invalidOption(String = "Invalid option")
    case parsingFailed(String = "Parsing failed")
}
