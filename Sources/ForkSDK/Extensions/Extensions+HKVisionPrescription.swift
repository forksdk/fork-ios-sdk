//
//  Extensions+HKVisionPrescription.swift
//  HealthKitReporter
//
//  Created by Victor Kachalov on 04.10.22.
//

import HealthKit

@available(iOS 16.0, *)
extension HKVisionPrescription: Serializable {
    typealias Serialized = VisionPrescription.Serialized

    func serialize() throws -> Serialized {
        return Serialized(
            dateIssuedTimestamp: dateIssued.millisecondsSince1970,
            expirationDateTimestamp: expirationDate?.millisecondsSince1970,
            prescriptionType: VisionPrescription.PrescriptionType(prescriptionType: prescriptionType),
            metadata: metadata?.asMetadata
        )
    }
}
