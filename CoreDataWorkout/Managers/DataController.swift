//
//  DataController.swift
//  CoreDataWorkout
//
//  Created by Alistair Cooper on 7/9/24.
//

import CoreData

class DataController: ObservableObject {
    static let shared = DataController()

    let persistentContainer: NSPersistentContainer

    private init() {
        persistentContainer = NSPersistentContainer(name: "CoreDataWorkout")
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }

    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    @objc 
    private func contextDidSaveContext(_ notification: Notification) {
        let context = notification.object as! NSManagedObjectContext
        if context !== viewContext {
            viewContext.perform {
                self.viewContext.mergeChanges(fromContextDidSave: notification)
            }
        }
    }

    func saveContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        return context
    }
            

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }
}

// MARK: - CRUD operations
extension DataController {
    func createUser(username: String) -> User {
        let newUser = User(context: viewContext)
        newUser.username = username
        newUser.age = 18
        newUser.uniqueId = UUID()
        
        saveContext()
        return newUser
    }

    func createSong(title: String, dateRecorded: Date, duration: Double, for user: User, isFavorite: Bool = false) -> Song {
        let newSong = Song(context: viewContext)
        newSong.title = title
        newSong.dateRecorded = dateRecorded
        newSong.duration = duration
        newSong.isFavorite = isFavorite
        newSong.user = user
        user.addToSongs(newSong)   // Set user relationship
        
        saveContext()
        return newSong
    }
            
    func fetchUser(username: String) -> User? {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "username == %@", username)

        do {
            let users = try viewContext.fetch(fetchRequest)
            return users.first
        } catch {
            print("Failed to fetch user: \(error)")
            return nil
        }
    }

    func updateSongTitle(song: Song, newTitle: String) {
        song.title = newTitle
        saveContext()
    }

    func deleteSong(song: Song) {
        viewContext.delete(song)
        saveContext()
    }
    
    func deleteAllSongsAndUsers(completion: @escaping () -> Void) {
        let fetchRequestSongs: NSFetchRequest<NSFetchRequestResult> = Song.fetchRequest()
        let deleteRequestSongs = NSBatchDeleteRequest(fetchRequest: fetchRequestSongs)
        deleteRequestSongs.resultType = .resultTypeObjectIDs

        let fetchRequestUsers: NSFetchRequest<NSFetchRequestResult> = User.fetchRequest()
        let deleteRequestUsers = NSBatchDeleteRequest(fetchRequest: fetchRequestUsers)
        deleteRequestUsers.resultType = .resultTypeObjectIDs

        do {
            let resultSongs = try viewContext.execute(deleteRequestSongs) as! NSBatchDeleteResult
            let resultUsers = try viewContext.execute(deleteRequestUsers) as! NSBatchDeleteResult

            let changes: [AnyHashable: Any] = [
                NSDeletedObjectsKey: (resultSongs.result as! [NSManagedObjectID]) + (resultUsers.result as! [NSManagedObjectID])
            ]

            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [viewContext])
            saveContext()
            completion()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}
