//
//  Subscription.swift
//  Continuum
//
//  Created by Christopher Wagner on 2/17/26.
//

import Foundation
import SwiftData

/// Billing cycle for subscriptions and recurring expenses
enum BillingCycle: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"

    var nextDueDateFrom: (Date) -> Date {
        switch self {
        case .weekly: return { Calendar.current.date(byAdding: .day, value: 7, to: $0) ?? $0 }
        case .biweekly: return { Calendar.current.date(byAdding: .day, value: 14, to: $0) ?? $0 }
        case .monthly: return { Calendar.current.date(byAdding: .month, value: 1, to: $0) ?? $0 }
        case .quarterly: return { Calendar.current.date(byAdding: .month, value: 3, to: $0) ?? $0 }
        case .yearly: return { Calendar.current.date(byAdding: .year, value: 1, to: $0) ?? $0 }
        }
    }
}

/// Category for subscriptions and recurring expenses
enum SubscriptionCategory: String, Codable, CaseIterable {
    case streaming = "Streaming"
    case software = "Software"
    case utilities = "Utilities"
    case insurance = "Insurance"
    case rent = "Rent"
    case loan = "Loan"
    case membership = "Membership"
    case other = "Other"
}

@Model
final class Subscription {
    var name: String
    var amount: Decimal
    var billingCycle: BillingCycle
    var nextDueDate: Date
    var category: SubscriptionCategory
    var notes: String
    var isSubscription: Bool // true = subscription (Netflix), false = recurring expense (rent)
    var createdAt: Date

    init(
        name: String = "",
        amount: Decimal = 0,
        billingCycle: BillingCycle = .monthly,
        nextDueDate: Date = Date(),
        category: SubscriptionCategory = .other,
        notes: String = "",
        isSubscription: Bool = true
    ) {
        self.name = name
        self.amount = amount
        self.billingCycle = billingCycle
        self.nextDueDate = nextDueDate
        self.category = category
        self.notes = notes
        self.isSubscription = isSubscription
        self.createdAt = Date()
    }

    /// True when nextDueDate is in the past (renewal overdue)
    var isPastDue: Bool {
        nextDueDate < Date()
    }

    /// Monthly equivalent cost for comparison
    var monthlyEquivalent: Decimal {
        switch billingCycle {
        case .weekly: return amount * 52 / 12
        case .biweekly: return amount * 26 / 12
        case .monthly: return amount
        case .quarterly: return amount / 3
        case .yearly: return amount / 12
        }
    }
}
