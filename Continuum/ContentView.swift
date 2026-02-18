//
//  ContentView.swift
//  Continuum
//
//  Created by Christopher Wagner on 2/17/26.
//

import SwiftUI
import SwiftData
import Combine

private enum Tab: Int {
    case dashboard = 0
    case calendar = 1
    case items = 2
    case settings = 3
}

final class AppNavigation: ObservableObject {
    @Published var selectedTab: Int = Tab.dashboard.rawValue
    @Published var selectedItemCategory: ItemCategory = .subscriptions

    func switchToItems(category: ItemCategory) {
        selectedItemCategory = category
        selectedTab = Tab.items.rawValue
    }
}

struct ContentView: View {
    @StateObject private var appNavigation = AppNavigation()

    var body: some View {
        TabView(selection: $appNavigation.selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.doc.horizontal")
                }
                .tag(Tab.dashboard.rawValue)
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(Tab.calendar.rawValue)
            ItemListView(selectedCategory: $appNavigation.selectedItemCategory)
                .tabItem {
                    Label("Items", systemImage: "list.bullet.rectangle")
                }
                .tag(Tab.items.rawValue)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(Tab.settings.rawValue)
        }
        .environmentObject(appNavigation)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Subscription.self, PersonalAsset.self, Warranty.self], inMemory: true)
}
