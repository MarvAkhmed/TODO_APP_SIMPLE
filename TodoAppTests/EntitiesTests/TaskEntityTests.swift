//  TaskEntityTests.swift
//  TODO_APPTests
//
//  Created by Marwa Awad on 03.12.2025.
//

import XCTest
import CoreData
@testable import TODO_APP

final  class TaskEntityTests: XCTestCase {
    
    var context: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        // Simple in-memory Core Data
        let container = NSPersistentContainer(name: "TODO_APP")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        let expectation = self.expectation(description: "Load store")
        container.loadPersistentStores { _, error in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        context = container.viewContext
    }
    
    // MARK: - Core Tests
    func testTaskEntity_CanCreateAndSave() {
        let task = TaskEntity(context: context)
        task.id = UUID()
        task.title = "Test Task"
        task.createdAt = Date()
        
        XCTAssertNotNil(task.id)
        XCTAssertEqual(task.title, "Test Task")
        XCTAssertNotNil(task.createdAt)
    }
    
    func testTaskEntity_CanConvertToTodoTask() {
        let task = TaskEntity(context: context)
        task.id = UUID()
        task.title = "Title test"
        task.createdAt = Date()
        task.taskDescription = "Description"
        task.isCompleted = true
        task.userId = 123
        task.remoteId = 456
        
        let todoTask = task.toTask()
        
        XCTAssertNotNil(todoTask)
        XCTAssertEqual(todoTask?.title, "Title test")
        XCTAssertTrue(todoTask?.isCompleted ?? false)
        XCTAssertEqual(todoTask?.userId, 123)
        XCTAssertEqual(todoTask?.remoteId, 456)
    }
    
    func testTaskEntity_ToTaskReturnsNilWhenMissingData() {
        let task = TaskEntity(context: context)
      
        let todoTask = task.toTask()
        
        XCTAssertNil(todoTask)
    }
    
    func testTaskEntity_RemoteIdConversion() {
        let task = TaskEntity(context: context)
        task.id = UUID()
        task.title = "Test"
        task.createdAt = Date()
        task.remoteId = 0  // Zero remote ID
        
        let todoTask = task.toTask()
        
        XCTAssertNotNil(todoTask)
        XCTAssertNil(todoTask?.remoteId)  // Should be nil for zero
    }
    
    func testTaskEntity_FetchRequestExists() {
        let fetchRequest = TaskEntity.fetchRequest()
        
        XCTAssertEqual(fetchRequest.entityName, "TaskEntity")
    }
}
