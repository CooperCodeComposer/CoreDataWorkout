//
//  ContentView.swift
//  CoreDataWorkout
//
//  Created by Alistair Cooper on 7/9/24.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Triggered on view load and changed on songs in the moc
    @FetchRequest(
        entity: Song.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Song.dateRecorded, ascending: false)],
        predicate: NSPredicate(format: "user.username == %@", "MusicLover123")
    ) var songs: FetchedResults<Song>

    @State private var isUpdating = false

    var body: some View {
        ZStack {
            NavigationView {
                List {
                    ForEach(songs) { song in
                        VStack(alignment: .leading) {
                            Text(song.title ?? "Unknown Title")
                            Text("Recorded on: \(song.dateRecorded ?? Date(), formatter: dateFormatter)")
                            Text("Duration: \(song.duration) seconds")
                        }
                    }
                    .onDelete(perform: deleteSongs)
                }
                .navigationTitle("Songs")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Button(action: addSong) {
                                Label("Add Song", systemImage: "plus")
                            }
                            Button(action: {
                                isUpdating = true
                                
                                // Example on main thread
                                DataController.shared.deleteAllSongsAndUsers {
                                    isUpdating = false
                                }
                                
                                // Example using background thread
//                                DataController.shared.deleteAllSongsUsingBackground {
//                                    isUpdating = false
//                                }
                            }) {
                                Label("Delete All", systemImage: "trash")
                            }
                            .disabled(isUpdating)
                        }
                    }
                }
            }

            if isUpdating {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView("Deleting...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - adding Song to test Core Data functionality
    
    private func addSong() {
        let dataController = DataController.shared
        let user = dataController.fetchUser(username: "MusicLover123") ?? dataController.createUser(username: "MusicLover123")

        _ = dataController.createSong(title: "New Song",
                                  dateRecorded: Date(),
                                  duration: 180.0,
                                  for: user,
                                  isFavorite: false)
    }

    private func deleteSongs(offsets: IndexSet) {
        withAnimation {
            offsets.map { songs[$0] }.forEach(viewContext.delete)
            DataController.shared.saveContext()
        }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let context = DataController.shared.viewContext

        // Add sample data
        let sampleUser = User(context: context)
        sampleUser.username = "MusicLover123"

        let sampleSong = Song(context: context)
        sampleSong.title = "Sample Song"
        sampleSong.dateRecorded = Date()
        sampleSong.duration = 180.0
        sampleSong.isFavorite = true // Set isFavorite attribute
        sampleSong.user = sampleUser

        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }

        return ContentView()
            .environment(\.managedObjectContext, context)
    }
}


