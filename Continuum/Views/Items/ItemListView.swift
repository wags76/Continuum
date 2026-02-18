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
    case recurringPayments = "Recurring Payments"
    case assets = "Assets"
    case warranties = "Warranties"

    var icon: String {
        switch self {
        case .subscriptions: return "arrow.triangle.2.circlepath"
        case .recurringPayments: return "repeat"
        case .assets: return "dollarsign"
        case .warranties: return "shield.checkered"
        }
    }
}

struct ItemListView: View {
    @Binding var selectedCategory: ItemCategory
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categorySwitcher
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 6)
                    .background(Color(.systemGroupedBackground))

                switch selectedCategory {
                case .subscriptions:
                    RecurringItemListViewContent(searchText: searchText, filter: .subscriptionsOnly)
                case .recurringPayments:
                    RecurringItemListViewContent(searchText: searchText, filter: .recurringPaymentsOnly)
                case .assets:
                    AssetListViewContent(searchText: searchText)
                case .warranties:
                    WarrantyListViewContent(searchText: searchText)
                }
            }
            .navigationTitle("Items")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search")
            .onChange(of: selectedCategory) { _, _ in
                searchText = ""
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    private var categorySwitcher: some View {
        HStack(spacing: 8) {
            ForEach(ItemCategory.allCases, id: \.self) { category in
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedCategory = category
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .font(.system(size: 14, weight: .semibold))
                        Text(category.rawValue)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundColor(selectedCategory == category ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Group {
                            if selectedCategory == category {
                                Capsule()
                                    .fill(Color.themeColor)
                                    .shadow(color: Color.themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
                            } else {
                                Capsule()
                                    .fill(Color.themeColor.opacity(0.08))
                                    .overlay(Capsule().stroke(Color.themeColor.opacity(0.2), lineWidth: 1))
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Recurring items list (subscriptions vs recurring payments)

private enum RecurringItemFilter {
    case subscriptionsOnly   // isSubscription == true
    case recurringPaymentsOnly // isSubscription == false
}

private struct RecurringItemListViewContent: View {
    var searchText: String
    var filter: RecurringItemFilter
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subscription.nextDueDate) private var subscriptions: [Subscription]

    private var matchingSubscriptions: [Subscription] {
        switch filter {
        case .subscriptionsOnly: return subscriptions.filter(\.isSubscription)
        case .recurringPaymentsOnly: return subscriptions.filter { !$0.isSubscription }
        }
    }

    private var filteredSubscriptions: [Subscription] {
        let base = matchingSubscriptions
        guard !searchText.isEmpty else { return base }
        let query = searchText.lowercased()
        return base.filter {
            $0.name.lowercased().contains(query) || $0.category.rawValue.lowercased().contains(query)
        }
    }

    private var emptyTitle: String {
        switch filter {
        case .subscriptionsOnly: return "No Subscriptions"
        case .recurringPaymentsOnly: return "No Recurring Payments"
        }
    }

    private var emptyDescription: String {
        switch filter {
        case .subscriptionsOnly: return "Add subscriptions (e.g. streaming, software) to track them here."
        case .recurringPaymentsOnly: return "Add recurring payments (e.g. rent, loans) to track them here."
        }
    }

    var body: some View {
        Group {
            if matchingSubscriptions.isEmpty {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: filter == .subscriptionsOnly ? "creditcard" : "repeat",
                    description: Text(emptyDescription)
                )
            } else if filteredSubscriptions.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List {
                    ForEach(filteredSubscriptions) { subscription in
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
                    SubscriptionEditView(initialIsSubscription: filter == .subscriptionsOnly)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

// MARK: - Asset List Content

private struct AssetListViewContent: View {
    var searchText: String
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PersonalAsset.name) private var assets: [PersonalAsset]

    private var filteredAssets: [PersonalAsset] {
        guard !searchText.isEmpty else { return assets }
        let query = searchText.lowercased()
        return assets.filter {
            $0.name.lowercased().contains(query) || $0.category.rawValue.lowercased().contains(query)
        }
    }

    var body: some View {
        Group {
            if assets.isEmpty {
                ContentUnavailableView(
                    "No Assets",
                    systemImage: "dollarsign",
                    description: Text("Add personal assets to track their value over time.")
                )
            } else if filteredAssets.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List {
                    ForEach(filteredAssets) { asset in
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
    var searchText: String
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Warranty.expiryDate) private var warranties: [Warranty]

    private var filteredWarranties: [Warranty] {
        guard !searchText.isEmpty else { return warranties }
        let query = searchText.lowercased()
        return warranties.filter {
            $0.productName.lowercased().contains(query) || $0.vendor.lowercased().contains(query)
        }
    }

    var body: some View {
        Group {
            if warranties.isEmpty {
                ContentUnavailableView(
                    "No Warranties",
                    systemImage: "shield.checkered",
                    description: Text("Add product warranties to track expiry dates.")
                )
            } else if filteredWarranties.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List {
                    ForEach(filteredWarranties) { warranty in
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
