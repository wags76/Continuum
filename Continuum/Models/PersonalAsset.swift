//
//  PersonalAsset.swift
//  Continuum
//
//  Created by Christopher Wagner on 2/17/26.
//

import Foundation
import SwiftData

/// Category for personal assets
enum AssetCategory: String, Codable, CaseIterable {
    case electronics = "Electronics"
    case vehicle = "Vehicle"
    case property = "Property"
    case jewelry = "Jewelry"
    case collectibles = "Collectibles"
    case furniture = "Furniture"
    case other = "Other"
}

@Model
final class PersonalAsset {
    var name: String
    var currentValue: Decimal
    var purchaseDate: Date?
    var category: AssetCategory
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \AssetValueChange.asset)
    var valueChanges: [AssetValueChange] = []

    init(
        name: String = "",
        currentValue: Decimal = 0,
        purchaseDate: Date? = nil,
        category: AssetCategory = .other,
        notes: String = ""
    ) {
        self.name = name
        self.currentValue = currentValue
        self.purchaseDate = purchaseDate
        self.category = category
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }

}
