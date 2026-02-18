//
//  WarrantyListView.swift
//  Continuum
//
//  Created by Christopher Wagner on 2/17/26.
//

import SwiftUI
import SwiftData

struct WarrantyListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Warranty.expiryDate) private var warranties: [Warranty]

    var body: some View {
        NavigationStack {
            Group {
                if warranties.isEmpty {
                    ContentUnavailableView(
                        "No Warranties",
                        systemImage: "shield.checkered",
                        description: Text("Add product warranties to track expiry dates.")
                    )
                } else {
                    List {
                        ForEach(warranties) { warranty in
                            NavigationLink {
                                WarrantyDetailView(warranty: warranty)
                            } label: {
                                WarrantyRowView(warranty: warranty)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    modelContext.delete(warranty)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Warranties")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        WarrantyEditView()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

private struct WarrantyRowView: View {
    let warranty: Warranty

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(warranty.productName)
                    .font(.headline)
                Text(warranty.vendor)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(warranty.expiryDate, format: .dateTime.month().day().year())
                    .font(.subheadline)
                statusBadge
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusBadge: some View {
        if warranty.isExpired {
            Text("Expired")
                .font(.caption2)
                .foregroundStyle(.red)
        } else if warranty.daysUntilExpiry <= 30 {
            Text("\(warranty.daysUntilExpiry)d left")
                .font(.caption2)
                .foregroundStyle(.orange)
        } else {
            Text("Valid")
                .font(.caption2)
                .foregroundStyle(.green)
        }
    }
}

#Preview {
    WarrantyListView()
        .modelContainer(for: Warranty.self, inMemory: true)
}
