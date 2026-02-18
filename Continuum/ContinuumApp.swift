//
//  ContinuumApp.swift
//  Continuum
//
//  Created by Christopher Wagner on 2/17/26.
//

import SwiftUI
import SwiftData

@main
struct ContinuumApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Subscription.self,
            PersonalAsset.self,
            AssetValueChange.self,
            Warranty.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
