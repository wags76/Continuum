//
//  AssetEditView.swift
//  Continuum
//
//  Created by Christopher Wagner on 2/17/26.
//

import SwiftUI
import SwiftData

struct AssetEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var currentValue: String = ""
    @State private var purchaseDate: Date = Date()
    @State private var hasPurchaseDate: Bool = false
    @State private var category: AssetCategory = .other
    @State private var notes: String = ""

    var asset: PersonalAsset?

    private var isEditing: Bool { asset != nil }

    var body: some View {
        Form {
            Section("Details") {
                TextField("Name", text: $name)
                TextField("Current Value", text: $currentValue)
                    .keyboardType(.decimalPad)
                Picker("Category", selection: $category) {
                    ForEach(AssetCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                Toggle("Set Purchase Date", isOn: $hasPurchaseDate)
                if hasPurchaseDate {
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                }
            }
            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
            }
        }
        .navigationTitle(isEditing ? "Edit Asset" : "New Asset")
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
            if let a = asset {
                name = a.name
                currentValue = "\(a.currentValue)"
                category = a.category
                notes = a.notes
                if let date = a.purchaseDate {
                    hasPurchaseDate = true
                    purchaseDate = date
                }
            }
        }
    }

    private func save() {
        let value = Decimal(string: currentValue) ?? 0

        if let a = asset {
            let previousValue = a.currentValue
            a.name = name.trimmingCharacters(in: .whitespaces)
            a.category = category
            a.notes = notes
            a.purchaseDate = hasPurchaseDate ? purchaseDate : nil
            a.updatedAt = Date()

            if value != previousValue {
                let change = AssetValueChange(previousValue: previousValue, newValue: value)
                change.asset = a
                a.valueChanges.append(change)
                a.currentValue = value
                modelContext.insert(change)
            } else {
                a.currentValue = value
            }
        } else {
            let newAsset = PersonalAsset(
                name: name.trimmingCharacters(in: .whitespaces),
                currentValue: value,
                purchaseDate: hasPurchaseDate ? purchaseDate : nil,
                category: category,
                notes: notes
            )
            modelContext.insert(newAsset)
        }
        dismiss()
    }
}
