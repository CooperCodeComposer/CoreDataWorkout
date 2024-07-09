//
//  CoreDataWorkoutApp.swift
//  CoreDataWorkout
//
//  Created by Alistair Cooper on 7/9/24.
//

import SwiftUI

@main
struct CoreDataWorkoutApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
