//
//  MockInteractorOutput.swift
//  TodoAppTests
//
//  Created by Marwa Awad on 03.12.2025.
//

import XCTest
@testable import TODO_APP

class MockInteractorOutput: TaskInteractorOutputProtocol, DetailedTaskInteractorOutputProtocol {
    
    // MARK: - Common Properties
    
    var didSucceed = false
    var didFail = false
    var lastError: Error?
    var callCount = 0
    
    // Async support
    var expectation: XCTestExpectation?
    var onSuccess: (() -> Void)?
    var onError: (() -> Void)?
    
    // MARK: - DetailedTaskInteractorOutputProtocol Tracking

    var didFetchTask = false
    var didFailFetch = false
    var didUpdateDescription = false
    var didFailUpdate = false
    var lastTask: TodoTask?
    
    // MARK: - TaskInteractorOutputProtocol Tracking
    
    var didReceiveTasks = false
    var didShowError = false
    var tasksFetchFailedCalled = false
    var lastTasks: [TodoTask] = []
    var lastTotalCount = 0
    var lastErrorMessage: String?
    
    var onTasksFetched: (() -> Void)?
    var onTasksFetchFailed: (() -> Void)?
    
    // MARK: - Reset
    
    func reset() {
        didSucceed = false
        didFail = false
        lastError = nil
        callCount = 0
        
        didFetchTask = false
        didFailFetch = false
        didUpdateDescription = false
        didFailUpdate = false
        lastTask = nil
        
        didReceiveTasks = false
        didShowError = false
        tasksFetchFailedCalled = false
        lastTasks = []
        lastTotalCount = 0
        lastErrorMessage = nil
    }
    
    // MARK: - DetailedTaskInteractorOutputProtocol Methods
    
    func taskFetched(_ task: TodoTask) {
        didSucceed = true
        didFetchTask = true
        lastTask = task
        callCount += 1
        onSuccess?()
        expectation?.fulfill()
    }
    
    func taskFetchFailed(_ error: Error) {
        didFail = true
        didFailFetch = true
        lastError = error
        callCount += 1
        onError?()
        expectation?.fulfill()
    }
    
    func taskDescriptionUpdated(_ task: TodoTask) {
        didSucceed = true
        didUpdateDescription = true
        lastTask = task
        callCount += 1
        onSuccess?()
        expectation?.fulfill()
    }
    
    func taskUpdateFailed(_ error: Error) {
        didFail = true
        didFailUpdate = true
        lastError = error
        callCount += 1
        onError?()
        expectation?.fulfill()
    }
    
    // MARK: - TaskInteractorOutputProtocol Methods
    
    func allTasksFetched(_ tasks: [TodoTask], totalCount: Int) {
        didSucceed = true
        didReceiveTasks = true
        lastTasks = tasks
        lastTotalCount = totalCount
        callCount += 1
        onTasksFetched?()
        expectation?.fulfill()
    }
    
    func tasksFetchFailed(_ error: Error) {
        didFail = true
        tasksFetchFailedCalled = true
        lastError = error
        callCount += 1
        onTasksFetchFailed?()
        expectation?.fulfill()
    }
    
    func displayError(_ message: String) {
        didFail = true
        didShowError = true
        lastErrorMessage = message
        callCount += 1
        onError?()
        expectation?.fulfill()
    }
    
    // MARK: - Convenience Properties
    var lastTasksCount: Int {
        return lastTasks.count
    }
}
