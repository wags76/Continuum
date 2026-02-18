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

    private var monthlyRecurringTotal: Decimal {
        subscriptions.reduce(0) { $0 + $1.monthlyEquivalent }
    }

    private var totalAssetsValue: Decimal {
        assets.reduce(0) { $0 + $1.currentValue }
    }

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
                    // Summary cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        SummaryCard(
                            title: "Monthly Recurring",
                            value: formatCurrency(monthlyRecurringTotal),
                            icon: "arrow.triangle.2.circlepath",
                            color: .blue,
                            onTap: { showMonthlyBreakdown = true }
                        )
                        SummaryCard(
                            title: "Total Assets",
                            value: formatCurrency(totalAssetsValue),
                            icon: "dollarsign",
                            color: .green,
                            onTap: { appNavigation.switchToItems(category: .assets) }
                        )
                        SummaryCard(
                            title: "Subscriptions",
                            value: "\(subscriptions.filter(\.isSubscription).count)",
                            icon: "creditcard",
                            color: .orange,
                            onTap: { appNavigation.switchToItems(category: .subscriptions) }
                        )
                        SummaryCard(
                            title: "Warranties",
                            value: "\(warranties.count)",
                            icon: "shield.checkered",
                            color: .purple,
                            onTap: { appNavigation.switchToItems(category: .warranties) }
                        )
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
            .navigationTitle("Dashboard")
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

    private var sortedByMonthly: [Subscription] {
        subscriptions.sorted { $0.monthlyEquivalent > $1.monthlyEquivalent }
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
                        ForEach(sortedByMonthly) { sub in
                            HStack {
                                Text(sub.name)
                                    .font(.body)
                                Spacer()
                                Text(formatCurrency(sub.monthlyEquivalent))
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
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
