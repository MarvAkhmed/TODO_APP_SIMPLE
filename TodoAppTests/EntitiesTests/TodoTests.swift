//
//  TodoTests.swift
//  TodoAppTests
//
//  Created by Marwa Awad on 03.12.2025.
//

import XCTest
@testable import TODO_APP

final class TodoTests: XCTestCase {
    
    // MARK: - Core Functionality Tests
    func testTodo_BasicPropertiesWork() {
        let todo = Todo(id: 1, todo: "Test", completed: false, userId: 1)
        
        XCTAssertEqual(todo.id, 1)
        XCTAssertEqual(todo.todo, "Test")
        XCTAssertFalse(todo.completed)
        XCTAssertEqual(todo.userId, 1)
    }
    
    func testTodo_CanConvertToTask() {
        let todo = Todo(id: 99, todo: "Convert", completed: true, userId: 5)
        let task = todo.task
        
        XCTAssertEqual(task.title, "Convert")
        XCTAssertTrue(task.isCompleted)
        XCTAssertEqual(task.userId, 5)
        XCTAssertEqual(task.remoteId, 99)
    }
    
    func testTodosResponse_CanCountCompleted() {
        let todos = [
            Todo(id: 1, todo: "Done", completed: true, userId: 1),
            Todo(id: 2, todo: "Not done", completed: false, userId: 1)
        ]
        
        let response = TodosResponse(todos: todos, total: 2, skip: 0, limit: 2)
        
        XCTAssertEqual(response.completedCount, 1)
        XCTAssertEqual(response.todos.count, 2)
    }
    
    // MARK: - JSON Decoding Test
    @MainActor
    func testTodo_CanDecodeFromJSON() throws {
        let json = """
        {
            "id": 42,
            "todo": "Decode me",
            "completed": true,
            "userId": 7
        }
        """
        
        let data = json.data(using: .utf8)!
        let todo = try JSONDecoder().decode(Todo.self, from: data)
        
        XCTAssertEqual(todo.id, 42)
        XCTAssertEqual(todo.todo, "Decode me")
        XCTAssertTrue(todo.completed)
    }
    
    // MARK: - Integration Test
    func testTodo_CompleteFlow() {
        // Create Todo
        let todo = Todo(id: 123, todo: "Complete flow", completed: true, userId: 456)
        
        // Convert to Task
        let task = todo.task
        
        // Verify
        XCTAssertEqual(task.title, "Complete flow")
        XCTAssertTrue(task.isCompleted)
        XCTAssertEqual(task.userId, 456)
        XCTAssertEqual(task.remoteId, 123)
    }
}
