//
//  SubscriptionDetailView.swift
//  Continuum
//
//  Created by Christopher Wagner on 2/17/26.
//

import SwiftUI
import SwiftData

struct SubscriptionDetailView: View {
    @Bindable var subscription: Subscription
    @Environment(\.modelContext) private var modelContext

    private var nextRenewalDate: Date {
        subscription.billingCycle.nextDueDateFrom(subscription.nextDueDate)
    }

    var body: some View {
        Form {
            Section("Details") {
                LabeledContent("Name", value: subscription.name)
                LabeledContent("Amount", value: formatCurrency(subscription.amount))
                LabeledContent("Billing Cycle", value: subscription.billingCycle.rawValue)
                LabeledContent("Category", value: subscription.category.rawValue)
                LabeledContent("Next Due") {
                    HStack(spacing: 6) {
                        Text(subscription.nextDueDate.formatted(date: .abbreviated, time: .omitted))
                        if subscription.isPastDue {
                            Text("Past due")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            if !subscription.notes.isEmpty {
                Section("Notes") {
                    Text(subscription.notes)
                }
            }
            Section {
                Button {
                    subscription.nextDueDate = nextRenewalDate
                    try? modelContext.save()
                } label: {
                    Label("Mark as renewed", systemImage: "arrow.clockwise.circle.fill")
                }
            } footer: {
                Text("Sets next due to \(nextRenewalDate.formatted(date: .abbreviated, time: .omitted)).")
            }
        }
        .navigationTitle(subscription.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    SubscriptionEditView(subscription: subscription)
                } label: {
                    Text("Edit")
                }
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
