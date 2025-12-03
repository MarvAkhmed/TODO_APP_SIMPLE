// MockTodoService.swift
// TODO_APPTests
//
// Created by Marwa Awad on 03.12.2025.
//

import XCTest
@testable import TODO_APP

final class MockTodoService: TodoServiceProtocol {
    var fetchAllTodosCalled = false
    var fetchTotalCountCalled = false
    var mockTodos: [Todo] = []
    var mockTotalCount = 0
    var shouldSucceed = true
    var errorToThrow: Error?
    
    func fetchAllTodos() async throws -> [Todo] {
        fetchAllTodosCalled = true
        
        if let error = errorToThrow {
            throw error
        }
        
        guard shouldSucceed else {
            throw NSError(domain: "Test", code: 500)
        }
        
        return mockTodos
    }
    
    func fetchTotalCount() async throws -> Int {
        fetchTotalCountCalled = true
        
        if let error = errorToThrow {
            throw error
        }
        
        guard shouldSucceed else {
            throw NSError(domain: "Test", code: 500)
        }
        
        return mockTotalCount
    }
}
