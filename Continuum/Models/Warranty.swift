//
//  Warranty.swift
//  Continuum
//
//  Created by Christopher Wagner on 2/17/26.
//

import Foundation
import SwiftData

@Model
final class Warranty {
    var productName: String
    var purchaseDate: Date
    var expiryDate: Date
    var vendor: String
    var notes: String
    var createdAt: Date

    init(
        productName: String = "",
        purchaseDate: Date = Date(),
        expiryDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date(),
        vendor: String = "",
        notes: String = ""
    ) {
        self.productName = productName
        self.purchaseDate = purchaseDate
        self.expiryDate = expiryDate
        self.vendor = vendor
        self.notes = notes
        self.createdAt = Date()
    }

    var isExpired: Bool {
        expiryDate < Date()
    }

    var daysUntilExpiry: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
    }
}
