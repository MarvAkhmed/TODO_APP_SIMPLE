//
//  TodoTaskTests.swift
//  TodoAppTests
//
//  Created by Marwa Awad on 03.12.2025.
//

import XCTest
@testable import TODO_APP

final class TodoTaskTests: XCTestCase {
    
    // MARK: - Basic Tests
    func testTodoTask_CreatesWithDefaults() {
        let task = TodoTask(title: "Test Task")
        
        XCTAssertEqual(task.title, "Test Task")
        XCTAssertFalse(task.isCompleted)
        XCTAssertEqual(task.userId, 1)
        XCTAssertNil(task.description)
        XCTAssertNil(task.remoteId)
        XCTAssertNotNil(task.id)
        XCTAssertNotNil(task.createdAt)
    }
    
    func testTodoTask_CreatesWithAllProperties() {
        let testId = UUID()
        let testDate = Date()
        
        let task = TodoTask(
            id: testId,
            title: "Complete Task",
            description: "Description here",
            isCompleted: true,
            userId: 42,
            createdAt: testDate,
            remoteId: 999
        )
        
        XCTAssertEqual(task.id, testId)
        XCTAssertEqual(task.title, "Complete Task")
        XCTAssertEqual(task.description, "Description here")
        XCTAssertTrue(task.isCompleted)
        XCTAssertEqual(task.userId, 42)
        XCTAssertEqual(task.createdAt, testDate)
        XCTAssertEqual(task.remoteId, 999)
    }
    
    // MARK: - Business Logic Tests
    func testTodoTask_CanToggleCompletion() {
        var task = TodoTask(title: "Toggle me")
        XCTAssertFalse(task.isCompleted)
        
        task.isCompleted = true
        XCTAssertTrue(task.isCompleted)
        
        task.isCompleted = false
        XCTAssertFalse(task.isCompleted)
    }
    
    func testTodoTask_WithRemoteId() {
        let task = TodoTask(title: "RemoteTask", remoteId: 123)
        
        XCTAssertEqual(task.title, "RemoteTask")
        XCTAssertEqual(task.remoteId, 123)
    }
    
    func testTodoTask_WithoutRemoteId() {
        let task = TodoTask(title: "Local only")
        
        XCTAssertEqual(task.title, "Local only")
        XCTAssertNil(task.remoteId)
    }
    
    // MARK: - Validation Tests
    func testTodoTask_EmptyTitle() {
        let task = TodoTask(title: "")
        
        XCTAssertEqual(task.title, "")
        XCTAssertNotNil(task.id)
    }
    
    func testTodoTask_LongTitle() {
        let longTitle = String(repeating: "A", count: 1000)
        let task = TodoTask(title: longTitle)
        
        XCTAssertEqual(task.title, longTitle)
        XCTAssertEqual(task.title.count, 1000)
    }
}
