//
//  WarrantyEditView.swift
//  Continuum
//
//  Created by Christopher Wagner on 2/17/26.
//

import SwiftUI
import SwiftData

struct WarrantyEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var productName: String = ""
    @State private var purchaseDate: Date = Date()
    @State private var expiryDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var vendor: String = ""
    @State private var notes: String = ""

    var warranty: Warranty?

    private var isEditing: Bool { warranty != nil }

    var body: some View {
        Form {
            Section("Product") {
                TextField("Product Name", text: $productName)
                TextField("Vendor", text: $vendor)
            }
            Section("Dates") {
                DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
            }
            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
            }
        }
        .navigationTitle(isEditing ? "Edit Warranty" : "New Warranty")
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
                .disabled(productName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            if let w = warranty {
                productName = w.productName
                purchaseDate = w.purchaseDate
                expiryDate = w.expiryDate
                vendor = w.vendor
                notes = w.notes
            }
        }
    }

    private func save() {
        if let w = warranty {
            w.productName = productName.trimmingCharacters(in: .whitespaces)
            w.purchaseDate = purchaseDate
            w.expiryDate = expiryDate
            w.vendor = vendor.trimmingCharacters(in: .whitespaces)
            w.notes = notes
        } else {
            let newWarranty = Warranty(
                productName: productName.trimmingCharacters(in: .whitespaces),
                purchaseDate: purchaseDate,
                expiryDate: expiryDate,
                vendor: vendor.trimmingCharacters(in: .whitespaces),
                notes: notes
            )
            modelContext.insert(newWarranty)
        }
        dismiss()
    }
}
