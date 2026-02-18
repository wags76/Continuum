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
    @Query private var subscriptions: [Subscription]
    @Query private var assets: [PersonalAsset]
    @Query private var warranties: [Warranty]

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
                            color: .blue
                        )
                        SummaryCard(
                            title: "Total Assets",
                            value: formatCurrency(totalAssetsValue),
                            icon: "dollarsign",
                            color: .green
                        )
                        SummaryCard(
                            title: "Subscriptions",
                            value: "\(subscriptions.filter(\.isSubscription).count)",
                            icon: "creditcard",
                            color: .orange
                        )
                        SummaryCard(
                            title: "Warranties",
                            value: "\(warranties.count)",
                            icon: "shield.checkered",
                            color: .purple
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
                                        Text(sub.nextDueDate, format: .dateTime.month().day())
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
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
        }
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0"
    }
}

private struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

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
        .modelContainer(for: [Subscription.self, PersonalAsset.self, Warranty.self], inMemory: true)
}
