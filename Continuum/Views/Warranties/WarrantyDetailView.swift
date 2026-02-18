//
//  WarrantyDetailView.swift
//  Continuum
//
//  Created by Christopher Wagner on 2/17/26.
//

import SwiftUI
import SwiftData

struct WarrantyDetailView: View {
    @Bindable var warranty: Warranty

    var body: some View {
        Form {
            Section("Details") {
                LabeledContent("Product", value: warranty.productName)
                LabeledContent("Vendor", value: warranty.vendor.isEmpty ? "—" : warranty.vendor)
                LabeledContent("Purchase Date", value: warranty.purchaseDate.formatted(date: .abbreviated, time: .omitted))
                LabeledContent("Expiry Date", value: warranty.expiryDate.formatted(date: .abbreviated, time: .omitted))
                LabeledContent("Status", value: statusText)
            }
            if !warranty.notes.isEmpty {
                Section("Notes") {
                    Text(warranty.notes)
                }
            }
        }
        .navigationTitle(warranty.productName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    WarrantyEditView(warranty: warranty)
                } label: {
                    Text("Edit")
                }
            }
        }
    }

    private var statusText: String {
        if warranty.isExpired {
            return "Expired"
        } else if warranty.daysUntilExpiry <= 30 {
            return "Expires in \(warranty.daysUntilExpiry) days"
        } else {
            return "Valid"
        }
    }
}
