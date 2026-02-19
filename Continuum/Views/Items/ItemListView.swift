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

/// Active filter for the items list. Cleared when switching categories.
enum ItemListFilter: Equatable {
    case subscriptionCategory(SubscriptionCategory)
    case pastDueOnly
    case assetCategory(AssetCategory)
    case warrantyStatus(WarrantyFilterStatus)

    var label: String {
        switch self {
        case .subscriptionCategory(let cat): return cat.rawValue
        case .pastDueOnly: return "Past due"
        case .assetCategory(let cat): return cat.rawValue
        case .warrantyStatus(let status): return status.label
        }
    }
}

enum WarrantyFilterStatus: String, CaseIterable, Equatable {
    case valid = "Valid"
    case expiringSoon = "Expiring soon"
    case expired = "Expired"

    var label: String { rawValue }
}

struct ItemListView: View {
    @Binding var selectedCategory: ItemCategory
    @State private var searchText = ""
    @State private var activeFilter: ItemListFilter?

    var body: some View {
        NavigationStack {
            Group {
                switch selectedCategory {
                case .subscriptions:
                    RecurringItemListViewContent(searchText: searchText, filter: .subscriptionsOnly, activeFilter: activeFilter)
                case .recurringPayments:
                    RecurringItemListViewContent(searchText: searchText, filter: .recurringPaymentsOnly, activeFilter: activeFilter)
                case .assets:
                    AssetListViewContent(searchText: searchText, activeFilter: activeFilter)
                case .warranties:
                    WarrantyListViewContent(searchText: searchText, activeFilter: activeFilter)
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(spacing: 0) {
                    categoryPicker
                    filterPillsSection
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    filterMenu
                }
            }
            .onChange(of: selectedCategory) { _, _ in
                searchText = ""
                activeFilter = nil
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    /// List type picker: tap to switch without opening a sheet.
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ItemCategory.allCases, id: \.self) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedCategory = category }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.system(size: 12))
                            Text(category.rawValue)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(selectedCategory == category ? .white : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(selectedCategory == category ? Color.accentColor : Color(.tertiarySystemFill))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
    }

    /// Sub-filter menu: one tap to open, one tap to pick option (no sheet).
    @ViewBuilder
    private var filterMenu: some View {
        Menu {
            switch selectedCategory {
            case .subscriptions, .recurringPayments:
                Button {
                    activeFilter = nil
                } label: {
                    Label("All", systemImage: activeFilter == nil ? "checkmark.circle.fill" : "circle")
                }
                ForEach(SubscriptionCategory.allCases, id: \.self) { cat in
                    let filter: ItemListFilter = .subscriptionCategory(cat)
                    Button {
                        activeFilter = activeFilter == filter ? nil : filter
                    } label: {
                        Label(cat.rawValue, systemImage: activeFilter == filter ? "checkmark.circle.fill" : "circle")
                    }
                }
                Divider()
                Button {
                    activeFilter = activeFilter == .pastDueOnly ? nil : .pastDueOnly
                } label: {
                    Label("Past due only", systemImage: activeFilter == .pastDueOnly ? "checkmark.circle.fill" : "circle")
                }
            case .assets:
                Button {
                    activeFilter = nil
                } label: {
                    Label("All", systemImage: activeFilter == nil ? "checkmark.circle.fill" : "circle")
                }
                ForEach(AssetCategory.allCases, id: \.self) { cat in
                    let filter: ItemListFilter = .assetCategory(cat)
                    Button {
                        activeFilter = activeFilter == filter ? nil : filter
                    } label: {
                        Label(cat.rawValue, systemImage: activeFilter == filter ? "checkmark.circle.fill" : "circle")
                    }
                }
            case .warranties:
                Button {
                    activeFilter = nil
                } label: {
                    Label("All", systemImage: activeFilter == nil ? "checkmark.circle.fill" : "circle")
                }
                ForEach(WarrantyFilterStatus.allCases, id: \.self) { status in
                    let filter: ItemListFilter = .warrantyStatus(status)
                    Button {
                        activeFilter = activeFilter == filter ? nil : filter
                    } label: {
                        Label(status.label, systemImage: activeFilter == filter ? "checkmark.circle.fill" : "circle")
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
    }

    private func filterAppliesToCurrentCategory(_ filter: ItemListFilter) -> Bool {
        switch (selectedCategory, filter) {
        case (.subscriptions, .subscriptionCategory), (.subscriptions, .pastDueOnly): return true
        case (.recurringPayments, .subscriptionCategory), (.recurringPayments, .pastDueOnly): return true
        case (.assets, .assetCategory): return true
        case (.warranties, .warrantyStatus): return true
        default: return false
        }
    }

    private var filterPillsSection: some View {
        let hasSubFilter = activeFilter != nil && filterAppliesToCurrentCategory(activeFilter!)
        return Group {
            if hasSubFilter, let filter = activeFilter {
                HStack(alignment: .center, spacing: 8) {
                    filterPill(filter.label, removable: true) {
                        withAnimation(.easeInOut(duration: 0.2)) { activeFilter = nil }
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    private func filterPill(_ label: String, removable: Bool, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
            if removable {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color(.tertiarySystemFill)))
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
    var activeFilter: ItemListFilter?
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subscription.nextDueDate) private var subscriptions: [Subscription]

    private var matchingSubscriptions: [Subscription] {
        var result: [Subscription]
        switch filter {
        case .subscriptionsOnly: result = subscriptions.filter(\.isSubscription)
        case .recurringPaymentsOnly: result = subscriptions.filter { !$0.isSubscription }
        }
        if let activeFilter {
            switch activeFilter {
            case .subscriptionCategory(let cat):
                result = result.filter { $0.category == cat }
            case .pastDueOnly:
                result = result.filter(\.isPastDue)
            default: break
            }
        }
        return result
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

    private var baseMatchingSubscriptions: [Subscription] {
        switch filter {
        case .subscriptionsOnly: return subscriptions.filter(\.isSubscription)
        case .recurringPaymentsOnly: return subscriptions.filter { !$0.isSubscription }
        }
    }

    var body: some View {
        Group {
            if baseMatchingSubscriptions.isEmpty {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: filter == .subscriptionsOnly ? "creditcard" : "repeat",
                    description: Text(emptyDescription)
                )
            } else if matchingSubscriptions.isEmpty {
                ContentUnavailableView(
                    "No Matching Items",
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: Text("No items match the current filter.")
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
    var activeFilter: ItemListFilter?
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PersonalAsset.name) private var assets: [PersonalAsset]

    private var matchingAssets: [PersonalAsset] {
        guard let activeFilter, case .assetCategory(let cat) = activeFilter else { return assets }
        return assets.filter { $0.category == cat }
    }

    private var filteredAssets: [PersonalAsset] {
        let base = matchingAssets
        guard !searchText.isEmpty else { return base }
        let query = searchText.lowercased()
        return base.filter {
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
            } else if matchingAssets.isEmpty {
                ContentUnavailableView(
                    "No Matching Assets",
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: Text("No assets match the current filter.")
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
    var activeFilter: ItemListFilter?
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Warranty.expiryDate) private var warranties: [Warranty]

    private var matchingWarranties: [Warranty] {
        guard let activeFilter, case .warrantyStatus(let status) = activeFilter else { return warranties }
        switch status {
        case .valid: return warranties.filter { !$0.isExpired && $0.daysUntilExpiry > 30 }
        case .expiringSoon: return warranties.filter { !$0.isExpired && $0.daysUntilExpiry <= 30 }
        case .expired: return warranties.filter(\.isExpired)
        }
    }

    private var filteredWarranties: [Warranty] {
        let base = matchingWarranties
        guard !searchText.isEmpty else { return base }
        let query = searchText.lowercased()
        return base.filter {
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
            } else if matchingWarranties.isEmpty {
                ContentUnavailableView(
                    "No Matching Warranties",
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: Text("No warranties match the current filter.")
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
