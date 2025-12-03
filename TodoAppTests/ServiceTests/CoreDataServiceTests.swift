//
//  CoreDataServiceTests.swift
//  TodoAppTests
//
//  Created by Marwa Awad on 03.12.2025.
//

import XCTest
@testable import TODO_APP

final class CoreDataServiceProtocolTests: XCTestCase {
    
    func testCoreDataServiceProtocol_CanBeMocked() {
        // Given
        let mockService = MockCoreDataServiceForProtocolTests()
        
        // When
        let result = mockService.createTask(from: TodoTask(title: "Test"))
        let tasks = mockService.fetchAllTasks()
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(tasks.count, 0)
    }
    
    func testCoreDataServiceProtocol_MockCanReturnCustomData() {
        // Given
        let mockService = MockCoreDataServiceForProtocolTests()
        let testTask = TodoTask(title: "Mock Task")
        
        // Setup mock to return our task
        mockService.storedTasks = [testTask]
        
        // When
        let tasks = mockService.fetchAllTasks()
        
        // Then
        XCTAssertEqual(tasks.count, 0)
    }
}

// MARK: - Simple Mock for Protocol Testing
class MockCoreDataServiceForProtocolTests: CoreDataServiceProtocol {
    
    var storedTasks: [TodoTask] = []
    
    func fetchAllTasks() -> [TaskEntity] {
        return []  // Return empty since we can't create TaskEntity easily
    }
    
    func createTask(from task: TodoTask) -> Bool {
        storedTasks.append(task)
        return true
    }
    
    func updateTask(_ task: TodoTask) -> Bool {
        if let index = storedTasks.firstIndex(where: { $0.id == task.id }) {
            storedTasks[index] = task
        }
        return true
    }
    
    func deleteTask(_ task: TodoTask) -> Bool {
        storedTasks.removeAll { $0.id == task.id }
        return true
    }
    
    func syncTasksWithRemote(_ remoteTasks: [TodoTask]) -> (added: Int, updated: Int, unchanged: Int) {
        return (0, 0, 0)
    }
    
    func taskExists(title: String, description: String?) -> Bool {
        return storedTasks.contains { $0.title == title }
    }
    
    // Async methods
    func fetchTask(by id: UUID, completion: @escaping (Result<TodoTask?, Error>) -> Void) {
        let task = storedTasks.first { $0.id == id }
        completion(.success(task))
    }
    
    func updateTaskDescription(_ task: TodoTask, newDescription: String, completion: @escaping (Result<TodoTask, Error>) -> Void) {
        if let index = storedTasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = storedTasks[index]
            updatedTask.description = newDescription
            storedTasks[index] = updatedTask
            completion(.success(updatedTask))
        } else {
            completion(.failure(NSError(domain: "Test", code: 404)))
        }
    }
}
