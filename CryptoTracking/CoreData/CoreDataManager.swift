//
//  CoreDataManager.swift
//  CryptoTracking
//
//  Created by admin on 10/6/24.
//

import Foundation
import CoreData

class CoreDataManager {
    class func shared() -> CoreDataManager {
        struct Singleton {
            static var shared = CoreDataManager(modelName: "CryptoTracking")
        }
        return Singleton.shared
    }
    let persistentContainer: NSPersistentContainer
    
    var viewContext:NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    var fetchedData:NSFetchedResultsController<CoinData>?
    
    var backgroundContext:NSManagedObjectContext!
    
    init(modelName:String) {
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    func configureContexts() {
        backgroundContext = persistentContainer.newBackgroundContext()
        
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    
    func load(completeion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            self.autoSaveViewContext()
            self.configureContexts()
            completeion?()
        }
    }
    
    func fetchedData(_ id: Any) {
        let fetchRequest:NSFetchRequest<CoinData> = CoinData.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "uuid", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedData = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.viewContext, sectionNameKeyPath: nil, cacheName: "uuid")
        fetchedData?.delegate = id as? NSFetchedResultsControllerDelegate
        
        try? fetchedData?.performFetch()
    }
    
    func fetchedCoin(uuid: String, symbol: String) -> [CoinData] {
        let predicate = NSPredicate(format: "uuid == %@ AND symbol == %@", uuid, symbol)
        let fetchRequest:NSFetchRequest<CoinData> = CoinData.fetchRequest()
        fetchRequest.predicate = predicate
        if let coins = try? self.viewContext.fetch(fetchRequest) {
            return coins
        }
        return []
    }
    
    func save() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func delete(coin: CoinData) {
        viewContext.delete(coin)
    }
}

extension CoreDataManager {
    func autoSaveViewContext(interval:TimeInterval = 30) {
        print("autosaving")
        guard interval > 0 else {
            print("cannot set negative autsave interval")
            return
        }
        save()
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autoSaveViewContext(interval: interval)
        }
    }
}
