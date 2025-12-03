//
//  TestContextProvider.swift
//  TodoAppTests
//
//  Created by Marwa Awad on 03.12.2025.
//

import XCTest
import CoreData
@testable import TODO_APP

class TestContextProvider {
    static let context: NSManagedObjectContext = {
        let container = NSPersistentContainer(name: "TODO_APP")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load test store: \(error)")
            }
        }
        return container.viewContext
    }()
}
