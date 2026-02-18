//
//  ContinuumExport.swift
//  Continuum
//
//  Created by Christopher Wagner on 2/17/26.
//

import Foundation
import SwiftData

// MARK: - Export container

struct ContinuumExport: Codable {
    let exportDate: Date
    let version: Int
    let subscriptions: [SubscriptionExport]
    let assets: [AssetExport]
    let warranties: [WarrantyExport]

    static let currentVersion = 1
}

// MARK: - Subscription

struct SubscriptionExport: Codable {
    let name: String
    let amount: String
    let billingCycle: String
    let nextDueDate: Date
    let category: String
    let notes: String
    let isSubscription: Bool
    let createdAt: Date

    @MainActor init(from subscription: Subscription) {
        name = subscription.name
        amount = "\(subscription.amount)"
        billingCycle = subscription.billingCycle.rawValue
        nextDueDate = subscription.nextDueDate
        category = subscription.category.rawValue
        notes = subscription.notes
        isSubscription = subscription.isSubscription
        createdAt = subscription.createdAt
    }
}

// MARK: - Asset & value changes

struct AssetExport: Codable {
    let name: String
    let currentValue: String
    let purchaseDate: Date?
    let category: String
    let notes: String
    let createdAt: Date
    let updatedAt: Date
    let valueChanges: [AssetValueChangeExport]

    @MainActor init(from asset: PersonalAsset) {
        name = asset.name
        currentValue = "\(asset.currentValue)"
        purchaseDate = asset.purchaseDate
        category = asset.category.rawValue
        notes = asset.notes
        createdAt = asset.createdAt
        updatedAt = asset.updatedAt
        valueChanges = asset.valueChanges.map(AssetValueChangeExport.init)
    }
}

struct AssetValueChangeExport: Codable {
    let date: Date
    let previousValue: String
    let newValue: String
    let note: String?

    @MainActor init(from change: AssetValueChange) {
        date = change.date
        previousValue = "\(change.previousValue)"
        newValue = "\(change.newValue)"
        note = change.note
    }
}

// MARK: - Warranty

struct WarrantyExport: Codable {
    let productName: String
    let purchaseDate: Date
    let expiryDate: Date
    let vendor: String
    let notes: String
    let createdAt: Date

    @MainActor init(from warranty: Warranty) {
        productName = warranty.productName
        purchaseDate = warranty.purchaseDate
        expiryDate = warranty.expiryDate
        vendor = warranty.vendor
        notes = warranty.notes
        createdAt = warranty.createdAt
    }
}

// MARK: - Build from model context

extension ContinuumExport {
    @MainActor static func build(from modelContext: ModelContext) throws -> ContinuumExport {
        let subDescriptor = FetchDescriptor<Subscription>(sortBy: [SortDescriptor(\.createdAt)])
        let assetDescriptor = FetchDescriptor<PersonalAsset>(sortBy: [SortDescriptor(\.createdAt)])
        let warrantyDescriptor = FetchDescriptor<Warranty>(sortBy: [SortDescriptor(\.createdAt)])

        let subscriptions = try modelContext.fetch(subDescriptor)
        let assets = try modelContext.fetch(assetDescriptor)
        let warranties = try modelContext.fetch(warrantyDescriptor)

        return ContinuumExport(
            exportDate: Date(),
            version: Self.currentVersion,
            subscriptions: subscriptions.map(SubscriptionExport.init),
            assets: assets.map(AssetExport.init),
            warranties: warranties.map(WarrantyExport.init)
        )
    }
}

// MARK: - Import into model context

extension ContinuumExport {
    func importInto(_ modelContext: ModelContext) throws {
        for s in subscriptions {
            let amount = Decimal(string: s.amount) ?? 0
            let cycle = BillingCycle(rawValue: s.billingCycle) ?? .monthly
            let category = SubscriptionCategory(rawValue: s.category) ?? .other
            let sub = Subscription(
                name: s.name,
                amount: amount,
                billingCycle: cycle,
                nextDueDate: s.nextDueDate,
                category: category,
                notes: s.notes,
                isSubscription: s.isSubscription
            )
            sub.createdAt = s.createdAt
            modelContext.insert(sub)
        }

        for a in assets {
            let currentValue = Decimal(string: a.currentValue) ?? 0
            let category = AssetCategory(rawValue: a.category) ?? .other
            let asset = PersonalAsset(
                name: a.name,
                currentValue: currentValue,
                purchaseDate: a.purchaseDate,
                category: category,
                notes: a.notes
            )
            asset.createdAt = a.createdAt
            asset.updatedAt = a.updatedAt
            modelContext.insert(asset)

            for v in a.valueChanges {
                let prev = Decimal(string: v.previousValue) ?? 0
                let new = Decimal(string: v.newValue) ?? 0
                let change = AssetValueChange(previousValue: prev, newValue: new, note: v.note)
                change.date = v.date
                change.asset = asset
                modelContext.insert(change)
            }
        }

        for w in warranties {
            let warranty = Warranty(
                productName: w.productName,
                purchaseDate: w.purchaseDate,
                expiryDate: w.expiryDate,
                vendor: w.vendor,
                notes: w.notes
            )
            warranty.createdAt = w.createdAt
            modelContext.insert(warranty)
        }

        try modelContext.save()
    }
}
