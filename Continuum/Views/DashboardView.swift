//
//  DashboardView.swift
//  Continuum
//
//  Created by Christopher Wagner on 2/17/26.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appNavigation: AppNavigation
    @Query private var subscriptions: [Subscription]
    @Query private var assets: [PersonalAsset]
    @Query private var warranties: [Warranty]
    @State private var showMonthlyBreakdown = false

    private var subscriptionMonthlyTotal: Decimal {
        subscriptions.filter(\.isSubscription).reduce(0) { $0 + $1.monthlyEquivalent }
    }

    private var recurringPaymentsMonthlyTotal: Decimal {
        subscriptions.filter { !$0.isSubscription }.reduce(0) { $0 + $1.monthlyEquivalent }
    }

    private var monthlyRecurringTotal: Decimal {
        subscriptionMonthlyTotal + recurringPaymentsMonthlyTotal
    }

    private var totalAssetsValue: Decimal {
        assets.reduce(0) { $0 + $1.currentValue }
    }

    private var hasSubscriptions: Bool { subscriptions.contains(where: \.isSubscription) }
    private var hasRecurringPayments: Bool { subscriptions.contains(where: { !$0.isSubscription }) }
    private var hasAssets: Bool { !assets.isEmpty }

    private var expiringWarranties: [Warranty] {
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return warranties
            .filter { !$0.isExpired && $0.expiryDate <= thirtyDaysFromNow }
            .sorted { $0.expiryDate < $1.expiryDate }
    }

    private var upcomingRenewals: [Subscription] {
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return subscriptions
            .filter { $0.nextDueDate <= thirtyDaysFromNow }
            .sorted { $0.nextDueDate < $1.nextDueDate }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary: overview card (amounts) + row of count cards
                    VStack(spacing: 16) {
                        OverviewCard(
                            subscriptionMonthly: subscriptionMonthlyTotal,
                            recurringPaymentsMonthly: recurringPaymentsMonthlyTotal,
                            totalAssets: totalAssetsValue,
                            warrantyCount: warranties.count,
                            expiringWarrantyCount: expiringWarranties.count,
                            hasSubscriptions: hasSubscriptions,
                            hasRecurringPayments: hasRecurringPayments,
                            hasAssets: hasAssets,
                            formatCurrency: formatCurrency,
                            onTapBreakdown: { showMonthlyBreakdown = true },
                            onTapAssets: { appNavigation.switchToItems(category: .assets) },
                            onTapWarranties: { appNavigation.switchToItems(category: .warranties) }
                        )
                        HStack(spacing: 16) {
                            SummaryCard(
                                title: "Subscriptions",
                                value: "\(subscriptions.filter(\.isSubscription).count)",
                                icon: "creditcard",
                                color: .orange,
                                onTap: { appNavigation.switchToItems(category: .subscriptions) }
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 118)
                            SummaryCard(
                                title: "Recurring Payments",
                                value: "\(subscriptions.filter { !$0.isSubscription }.count)",
                                icon: "repeat",
                                color: .teal,
                                onTap: { appNavigation.switchToItems(category: .recurringPayments) }
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 118)
                            SummaryCard(
                                title: "Warranties",
                                value: "\(warranties.count)",
                                icon: "shield.checkered",
                                color: .purple,
                                onTap: { appNavigation.switchToItems(category: .warranties) }
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 118)
                        }
                    }

                    // Upcoming renewals
                    if !upcomingRenewals.isEmpty {
                        SectionCard(title: "Upcoming Renewals", icon: "calendar.badge.clock") {
                            ForEach(upcomingRenewals.prefix(5)) { sub in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(sub.name)
                                            .font(.subheadline.weight(.medium))
                                        if sub.isPastDue {
                                            Text("Past due")
                                                .font(.caption)
                                                .foregroundStyle(.red)
                                        } else {
                                            Text(sub.nextDueDate, format: .dateTime.month().day())
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Text(formatCurrency(sub.amount))
                                        .font(.subheadline.weight(.medium))
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }

                    // Expiring warranties
                    if !expiringWarranties.isEmpty {
                        SectionCard(title: "Expiring Soon", icon: "exclamationmark.triangle") {
                            ForEach(expiringWarranties.prefix(5)) { warranty in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(warranty.productName)
                                            .font(.subheadline.weight(.medium))
                                        Text(warranty.expiryDate, format: .dateTime.month().day().year())
                                            .font(.caption)
                                            .foregroundStyle(warranty.isExpired ? .red : .secondary)
                                    }
                                    Spacer()
                                    if warranty.daysUntilExpiry > 0 {
                                        Text("\(warranty.daysUntilExpiry)d left")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    } else {
                                        Text("Expired")
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Continuum")
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showMonthlyBreakdown) {
                MonthlyRecurringBreakdownSheet(
                    subscriptions: subscriptions,
                    total: monthlyRecurringTotal,
                    formatCurrency: formatCurrency,
                    onViewAll: {
                        showMonthlyBreakdown = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            appNavigation.switchToItems(category: .subscriptions)
                        }
                    }
                )
            }
        }
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0"
    }
}

// MARK: - Monthly recurring breakdown sheet

private struct MonthlyRecurringBreakdownSheet: View {
    @Environment(\.dismiss) private var dismiss
    let subscriptions: [Subscription]
    let total: Decimal
    let formatCurrency: (Decimal) -> String
    let onViewAll: () -> Void

    private var subscriptionItems: [Subscription] {
        subscriptions.filter(\.isSubscription).sorted { $0.monthlyEquivalent > $1.monthlyEquivalent }
    }

    private var recurringItems: [Subscription] {
        subscriptions.filter { !$0.isSubscription }.sorted { $0.monthlyEquivalent > $1.monthlyEquivalent }
    }

    private var subscriptionTotal: Decimal {
        subscriptionItems.reduce(0) { $0 + $1.monthlyEquivalent }
    }

    private var recurringTotal: Decimal {
        recurringItems.reduce(0) { $0 + $1.monthlyEquivalent }
    }

    var body: some View {
        NavigationStack {
            Group {
                if subscriptions.isEmpty {
                    ContentUnavailableView(
                        "No recurring items",
                        systemImage: "arrow.triangle.2.circlepath",
                        description: Text("Add subscriptions or recurring expenses to see a monthly breakdown.")
                    )
                } else {
                    List {
                        if !subscriptionItems.isEmpty {
                            Section {
                                ForEach(subscriptionItems) { sub in
                                    HStack {
                                        Text(sub.name)
                                            .font(.body)
                                        Spacer()
                                        Text(formatCurrency(sub.monthlyEquivalent))
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                HStack {
                                    Text("Subtotal")
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    Text(formatCurrency(subscriptionTotal))
                                        .font(.subheadline.weight(.medium))
                                }
                            } header: {
                                Text("Subscriptions")
                            }
                        }
                        if !recurringItems.isEmpty {
                            Section {
                                ForEach(recurringItems) { sub in
                                    HStack {
                                        Text(sub.name)
                                            .font(.body)
                                        Spacer()
                                        Text(formatCurrency(sub.monthlyEquivalent))
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                HStack {
                                    Text("Subtotal")
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    Text(formatCurrency(recurringTotal))
                                        .font(.subheadline.weight(.medium))
                                }
                            } header: {
                                Text("Recurring payments")
                            }
                        }
                        Section {
                            HStack {
                                Text("Total")
                                    .font(.headline)
                                Spacer()
                                Text(formatCurrency(total))
                                    .font(.headline)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Monthly Recurring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                if !subscriptions.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button("View all") {
                            onViewAll()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Overview card (subscriptions, recurring, assets, warranties)

private struct OverviewCard: View {
    let subscriptionMonthly: Decimal
    let recurringPaymentsMonthly: Decimal
    let totalAssets: Decimal
    let warrantyCount: Int
    let expiringWarrantyCount: Int
    let hasSubscriptions: Bool
    let hasRecurringPayments: Bool
    let hasAssets: Bool
    let formatCurrency: (Decimal) -> String
    let onTapBreakdown: () -> Void
    let onTapAssets: () -> Void
    let onTapWarranties: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Overview")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                if hasSubscriptions || subscriptionMonthly > 0 {
                    overviewRow(
                        label: "Subscriptions",
                        icon: "creditcard",
                        value: formatCurrency(subscriptionMonthly),
                        suffix: "/mo",
                        isMuted: !hasSubscriptions && subscriptionMonthly == 0,
                        action: onTapBreakdown
                    )
                }
                if hasRecurringPayments || recurringPaymentsMonthly > 0 {
                    overviewRow(
                        label: "Recurring payments",
                        icon: "repeat",
                        value: formatCurrency(recurringPaymentsMonthly),
                        suffix: "/mo",
                        isMuted: !hasRecurringPayments && recurringPaymentsMonthly == 0,
                        action: onTapBreakdown
                    )
                }
                if hasAssets || totalAssets > 0 {
                    overviewRow(
                        label: "Assets",
                        icon: "dollarsign",
                        value: formatCurrency(totalAssets),
                        suffix: nil,
                        isMuted: !hasAssets && totalAssets == 0,
                        action: onTapAssets
                    )
                }
                if warrantyCount > 0 {
                    overviewRow(
                        label: "Warranties",
                        icon: "shield.checkered",
                        value: "\(warrantyCount)",
                        suffix: expiringWarrantyCount > 0 ? " (\(expiringWarrantyCount) expiring soon)" : nil,
                        isMuted: false,
                        action: onTapWarranties
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func overviewRow(
        label: String,
        icon: String,
        value: String,
        suffix: String?,
        isMuted: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(label)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 12)
                HStack(spacing: 2) {
                    Text(value)
                        .font(.subheadline.weight(.medium))
                    if let suffix {
                        Text(suffix)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .foregroundStyle(isMuted ? .secondary : .primary)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var onTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.weight(.semibold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .frame(minHeight: 34)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            onTap?()
        }
    }
}

private struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppNavigation())
        .modelContainer(for: [Subscription.self, PersonalAsset.self, Warranty.self], inMemory: true)
}
