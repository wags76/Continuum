//
//  ItemListView.swift
//  Continuum
//
//  Created by Christopher Wagner on 2/18/26.
//

import SwiftUI
import SwiftData

enum ItemCategory: String, CaseIterable {
    case subscriptions = "Subscriptions"
    case assets = "Assets"
    case warranties = "Warranties"

    var icon: String {
        switch self {
        case .subscriptions: return "arrow.triangle.2.circlepath"
        case .assets: return "dollarsign"
        case .warranties: return "shield.checkered"
        }
    }
}

struct ItemListView: View {
    @Binding var selectedCategory: ItemCategory

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(ItemCategory.allCases, id: \.self) { category in
                        Label(category.rawValue, systemImage: category.icon)
                            .tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch selectedCategory {
                case .subscriptions:
                    SubscriptionListViewContent()
                case .assets:
                    AssetListViewContent()
                case .warranties:
                    WarrantyListViewContent()
                }
            }
            .navigationTitle("Items")
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - Subscription List Content (extracted for reuse in tab)

private struct SubscriptionListViewContent: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subscription.nextDueDate) private var subscriptions: [Subscription]

    var body: some View {
        Group {
            if subscriptions.isEmpty {
                ContentUnavailableView(
                    "No Subscriptions",
                    systemImage: "creditcard",
                    description: Text("Add subscriptions or recurring expenses to track them here.")
                )
            } else {
                List {
                    ForEach(subscriptions) { subscription in
                        NavigationLink {
                            SubscriptionDetailView(subscription: subscription)
                        } label: {
                            SubscriptionRowView(subscription: subscription)
                        }
                        .listRowBackground(subscription.isPastDue ? Color.red.opacity(0.08) : nil)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                modelContext.delete(subscription)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    SubscriptionEditView()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

// MARK: - Asset List Content

private struct AssetListViewContent: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PersonalAsset.name) private var assets: [PersonalAsset]

    var body: some View {
        Group {
            if assets.isEmpty {
                ContentUnavailableView(
                    "No Assets",
                    systemImage: "dollarsign",
                    description: Text("Add personal assets to track their value over time.")
                )
            } else {
                List {
                    ForEach(assets) { asset in
                        NavigationLink {
                            AssetDetailView(asset: asset)
                        } label: {
                            AssetRowView(asset: asset)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                modelContext.delete(asset)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    AssetEditView()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

// MARK: - Warranty List Content

private struct WarrantyListViewContent: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Warranty.expiryDate) private var warranties: [Warranty]

    var body: some View {
        Group {
            if warranties.isEmpty {
                ContentUnavailableView(
                    "No Warranties",
                    systemImage: "shield.checkered",
                    description: Text("Add product warranties to track expiry dates.")
                )
            } else {
                List {
                    ForEach(warranties) { warranty in
                        NavigationLink {
                            WarrantyDetailView(warranty: warranty)
                        } label: {
                            WarrantyRowView(warranty: warranty)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                modelContext.delete(warranty)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    WarrantyEditView()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

// MARK: - Row Views (reused from original list views)

private struct SubscriptionRowView: View {
    let subscription: Subscription

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.name)
                    .font(.headline)
                Text(subscription.category.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(subscription.amount))
                    .font(.subheadline.weight(.medium))
                Group {
                    if subscription.isPastDue {
                        Text("Past due")
                            .font(.caption2)
                            .foregroundStyle(.red)
                        Text(subscription.nextDueDate, format: .dateTime.month().day())
                            .font(.caption)
                            .foregroundStyle(.red.opacity(0.9))
                    } else {
                        Text(subscription.nextDueDate, format: .dateTime.month().day())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0"
    }
}

private struct AssetRowView: View {
    let asset: PersonalAsset

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(asset.name)
                    .font(.headline)
                Text(asset.category.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(formatCurrency(asset.currentValue))
                .font(.subheadline.weight(.medium))
        }
        .padding(.vertical, 4)
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0"
    }
}

private struct WarrantyRowView: View {
    let warranty: Warranty

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(warranty.productName)
                    .font(.headline)
                Text(warranty.vendor)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(warranty.expiryDate, format: .dateTime.month().day().year())
                    .font(.subheadline)
                if warranty.isExpired {
                    Text("Expired")
                        .font(.caption2)
                        .foregroundStyle(.red)
                } else if warranty.daysUntilExpiry <= 30 {
                    Text("\(warranty.daysUntilExpiry)d left")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                } else {
                    Text("Valid")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ItemListView(selectedCategory: .constant(.subscriptions))
        .modelContainer(for: [Subscription.self, PersonalAsset.self, Warranty.self], inMemory: true)
}
