//
//  CoreDataWorkoutApp.swift
//  CoreDataWorkout
//
//  Created by Alistair Cooper on 7/9/24.
//

import SwiftUI

@main
struct CoreDataWorkoutApp: App {
    let dataController = DataController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.viewContext)
        }
    }
}
