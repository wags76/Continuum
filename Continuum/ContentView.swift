//
//  ContentView.swift
//  Continuum
//
//  Created by Christopher Wagner on 2/17/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.doc.horizontal")
                }
            SubscriptionListView()
                .tabItem {
                    Label("Subscriptions", systemImage: "arrow.triangle.2.circlepath")
                }
            AssetListView()
                .tabItem {
                    Label("Assets", systemImage: "dollarsign")
                }
            WarrantyListView()
                .tabItem {
                    Label("Warranties", systemImage: "shield.checkered")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Subscription.self, PersonalAsset.self, Warranty.self], inMemory: true)
}
