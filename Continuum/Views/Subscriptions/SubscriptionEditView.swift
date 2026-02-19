//
//  SubscriptionEditView.swift
//  Continuum
//
//  Created by Christopher Wagner on 2/17/26.
//

import SwiftUI
import SwiftData

struct SubscriptionEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var amount: String = ""
    @State private var billingCycle: BillingCycle = .monthly
    @State private var nextDueDate: Date = Date()
    @State private var category: SubscriptionCategory = .other
    @State private var notes: String = ""
    @State private var isSubscription: Bool = true
    @State private var hasAppliedInitialSubscription: Bool = false

    var subscription: Subscription?
    /// When adding a new item, set to true for Subscriptions tab or false for Recurring Payments tab.
    var initialIsSubscription: Bool? = nil

    private var isEditing: Bool { subscription != nil }

    private var navigationTitle: String {
        if isEditing {
            return subscription!.isSubscription ? "Edit Subscription" : "Edit Recurring Payment"
        }
        let effectiveIsSubscription = initialIsSubscription ?? isSubscription
        return effectiveIsSubscription ? "New Subscription" : "New Recurring Payment"
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                Picker("Billing Cycle", selection: $billingCycle) {
                    ForEach(BillingCycle.allCases, id: \.self) { cycle in
                        Text(cycle.rawValue).tag(cycle)
                    }
                }
                DatePicker("Next Due Date", selection: $nextDueDate, displayedComponents: .date)
                Picker("Category", selection: $category) {
                    ForEach(SubscriptionCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                if isEditing {
                    Toggle("Subscription (vs Recurring Payment)", isOn: $isSubscription)
                }
            }
            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            if let sub = subscription {
                name = sub.name
                amount = "\(sub.amount)"
                billingCycle = sub.billingCycle
                nextDueDate = sub.nextDueDate
                category = sub.category
                notes = sub.notes
                isSubscription = sub.isSubscription
            } else if let initial = initialIsSubscription, !hasAppliedInitialSubscription {
                hasAppliedInitialSubscription = true
                isSubscription = initial
            }
        }
    }

    private func save() {
        let amountValue = Decimal(string: amount) ?? 0
        if let sub = subscription {
            sub.name = name.trimmingCharacters(in: .whitespaces)
            sub.amount = amountValue
            sub.billingCycle = billingCycle
            sub.nextDueDate = nextDueDate
            sub.category = category
            sub.notes = notes
            sub.isSubscription = isSubscription
        } else {
            let newSub = Subscription(
                name: name.trimmingCharacters(in: .whitespaces),
                amount: amountValue,
                billingCycle: billingCycle,
                nextDueDate: nextDueDate,
                category: category,
                notes: notes,
                isSubscription: isSubscription
            )
            modelContext.insert(newSub)
        }
        dismiss()
    }
}
