//
//  Poltek_Visit_AppApp.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 27/6/25.
//

import SwiftUI
import SwiftData

@main
struct Poltek_Visit_AppApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
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
