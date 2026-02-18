//
//  AssetListView.swift
//  Continuum
//
//  Created by Christopher Wagner on 2/17/26.
//

import SwiftUI
import SwiftData

struct AssetListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PersonalAsset.name) private var assets: [PersonalAsset]

    var body: some View {
        NavigationStack {
            Group {
                if assets.isEmpty {
                    ContentUnavailableView(
                        "No Assets",
                        systemImage: "dollarsign",
                        description: Text("Add personal assets to track their value over time.")
                    )
                } else {
                    List {
                        ForEach(assets) { asset in
                            NavigationLink {
                                AssetDetailView(asset: asset)
                            } label: {
                                AssetRowView(asset: asset)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    modelContext.delete(asset)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Assets")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        AssetEditView()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

private struct AssetRowView: View {
    let asset: PersonalAsset

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(asset.name)
                    .font(.headline)
                Text(asset.category.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(formatCurrency(asset.currentValue))
                .font(.subheadline.weight(.medium))
        }
        .padding(.vertical, 4)
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0"
    }
}

#Preview {
    AssetListView()
        .modelContainer(for: PersonalAsset.self, inMemory: true)
}
