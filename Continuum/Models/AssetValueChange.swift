//
//  AssetValueChange.swift
//  Continuum
//
//  Created by Christopher Wagner on 2/17/26.
//

import Foundation
import SwiftData

@Model
final class AssetValueChange {
    var date: Date
    var previousValue: Decimal
    var newValue: Decimal
    var note: String?

    var asset: PersonalAsset?

    init(
        previousValue: Decimal,
        newValue: Decimal,
        note: String? = nil
    ) {
        self.date = Date()
        self.previousValue = previousValue
        self.newValue = newValue
        self.note = note
    }

    var changeAmount: Decimal {
        newValue - previousValue
    }

    var changePercent: Double? {
        guard previousValue != 0 else { return nil }
        return NSDecimalNumber(decimal: (newValue - previousValue) / previousValue).doubleValue
    }
}
