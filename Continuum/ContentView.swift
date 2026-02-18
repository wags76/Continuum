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
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            ItemListView()
                .tabItem {
                    Label("Items", systemImage: "list.bullet.rectangle")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Subscription.self, PersonalAsset.self, Warranty.self], inMemory: true)
}
