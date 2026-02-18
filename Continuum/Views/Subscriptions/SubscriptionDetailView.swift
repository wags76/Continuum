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

    var body: some View {
        Form {
            Section("Details") {
                LabeledContent("Name", value: subscription.name)
                LabeledContent("Amount", value: formatCurrency(subscription.amount))
                LabeledContent("Billing Cycle", value: subscription.billingCycle.rawValue)
                LabeledContent("Category", value: subscription.category.rawValue)
                LabeledContent("Next Due", value: subscription.nextDueDate.formatted(date: .abbreviated, time: .omitted))
            }
            if !subscription.notes.isEmpty {
                Section("Notes") {
                    Text(subscription.notes)
                }
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
