//
//  TodoNetworkServiceTests.swift
//  TodoAppTests
//
//  Created by Marwa Awad on 03.12.2025.
//

import XCTest
@testable import TODO_APP

@MainActor
final class TodoNetworkServiceDecodingTests: XCTestCase {
    
    func testDecodeTodoResponse() throws {
        let json = """
        {
            "todos": [
                {"id": 1, "todo": "Task 1", "completed": false, "userId": 1},
                {"id": 2, "todo": "Task 2", "completed": true, "userId": 2}
            ],
            "total": 150,
            "skip": 0,
            "limit": 30
        }
        """
        
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(TodosResponse.self, from: data)
        
        XCTAssertEqual(response.todos.count, 2)
        XCTAssertEqual(response.total, 150)
        XCTAssertEqual(response.skip, 0)
        XCTAssertEqual(response.limit, 30)
        XCTAssertEqual(response.completedCount, 1)
    }
    
    func testDecodeTodo() throws {
        let json = """
        {"id": 42, "todo": "Test task", "completed": true, "userId": 7}
        """
        
        let data = json.data(using: .utf8)!
        let todo = try JSONDecoder().decode(Todo.self, from: data)
        
        XCTAssertEqual(todo.id, 42)
        XCTAssertEqual(todo.todo, "Test task")
        XCTAssertTrue(todo.completed)
        XCTAssertEqual(todo.userId, 7)
    }
}
