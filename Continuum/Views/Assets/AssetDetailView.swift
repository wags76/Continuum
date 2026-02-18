//
//  AssetDetailView.swift
//  Continuum
//
//  Created by Christopher Wagner on 2/17/26.
//

import SwiftUI
import SwiftData

struct AssetDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var asset: PersonalAsset

    var body: some View {
        Form {
            Section("Details") {
                LabeledContent("Name", value: asset.name)
                LabeledContent("Current Value", value: formatCurrency(asset.currentValue))
                LabeledContent("Category", value: asset.category.rawValue)
                if let date = asset.purchaseDate {
                    LabeledContent("Purchase Date", value: date.formatted(date: .abbreviated, time: .omitted))
                }
            }
            if !asset.valueChanges.isEmpty {
                Section("Value History") {
                    ForEach(asset.valueChanges.sorted(by: { $0.date > $1.date })) { change in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(change.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline)
                                if let note = change.note, !note.isEmpty {
                                    Text(note)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(formatCurrency(change.previousValue))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("→ \(formatCurrency(change.newValue))")
                                    .font(.subheadline.weight(.medium))
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            if !asset.notes.isEmpty {
                Section("Notes") {
                    Text(asset.notes)
                }
            }
        }
        .navigationTitle(asset.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    AssetEditView(asset: asset)
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
