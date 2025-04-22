//
//  ForkData.swift
//
//
//  Created by Aleksandras Gaidamauskas on 18/04/2024.
//

import Foundation

public struct ForkDataQuantityValue: Codable {
    public let quantity: Double
    public let unit: String
    
    public init(quantity: Double, unit: String){
        self.quantity = quantity
        self.unit = unit
    }
}

public struct ForkDataQuantity : Identifiable, Codable {
    public var id = UUID()
    public let startDate: Date
    public let endDate: Date?
    public let value: ForkDataQuantityValue
    public let type: String?
    
    public init(startDate: Date, endDate: Date?, value: ForkDataQuantityValue, type: String? = nil){
        self.startDate = startDate
        self.endDate = endDate
        self.value = value
        self.type = type
    }
    
    public var quantity: Double {
        return value.quantity
    }
    
    public var identifier: String {
        return id.uuidString
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, startDate = "start_date", endDate = "end_date", value, type
    }
}


public struct ForkDataSource: Codable {
    public let name: String // Should it be narowed to enum instead?
    public let bundleIdentifier: String?
}

public struct ForkDataItem: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let startDate: Date
    public let endDate: Date
    public let data: [String: [ForkDataQuantity]]
    public let metaData: [String: ForkDataQuantityValue]
    public let nestedData: [String: [ForkDataItem]]?
    public let source: [ForkDataSource]? // [String: String?]?
    public let device:  [String: String?]?
    
    public init(
        id: UUID = UUID(),
        name: String,
        startDate: Date,
        endDate: Date,
        data: [String : [ForkDataQuantity]],
        metaData: [String : ForkDataQuantityValue],
        nestedData: [String : [ForkDataItem]]? = nil,
        source: [ForkDataSource]? = nil,
        device: [String: String?]? = nil
    ) {

        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.data = data
        self.metaData = metaData
        self.nestedData = nestedData
        self.source = source
        self.device = device
    }
    
    public var identifier: String {
        return id.uuidString
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, startDate = "start_date", endDate = "end_date", data, metaData = "meta_data", nestedData = "nested_data", source, device
    }
}

public protocol ForkDataType {
    associatedtype DataEntryType : Decodable, Encodable
}

public struct ForkData: Codable {
    public let userId: String?
    public let startDate: Date
    public let endDate: Date
    public let collectedAt: Date?
    public let type: String
    public let source: [ForkDataSource]?
    public let device:  [String: String?]?
    // public let entries: [ForkDataDataEntry]
    
    public let data: [ForkDataItem]
    public let metaData: [String: ForkDataQuantityValue]?
    
    private enum CodingKeys: String, CodingKey {
        case userId = "user_id", startDate = "start_date", endDate = "end_date", collectedAt = "collected_at", type, source, device, data, metaData = "meta_data"
    }
}