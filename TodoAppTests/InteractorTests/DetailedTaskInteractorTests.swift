//
//  DetailedTaskInteractorTests.swift
//  TodoAppTests
//
//  Created by Marwa Awad on 03.12.2025.
//

import XCTest
@testable import TODO_APP

final class DetailedTaskInteractorTests: XCTestCase {
    
    var interactor: DetailedTaskInteractor!
    var mockOutput: MockInteractorOutput!
    var mockCoreData: MockCoreDataService!
    
    override func setUp() {
        super.setUp()
        mockOutput = MockInteractorOutput()
        mockCoreData = MockCoreDataService()
        mockCoreData.isDetailedOnly = true  
        
        interactor = DetailedTaskInteractor(coreDataService: mockCoreData)
        interactor.detailedTaskInteractorOutputProtocol = mockOutput
    }
    
    override func tearDown() {
        interactor = nil
        mockOutput = nil
        mockCoreData = nil
        super.tearDown()
    }
    
    // MARK: - Fetch Task Tests
    
    func testFetchTask_ValidUUID_CallsCoreData() {
        // Given
        let taskId = UUID()
        
        // When
        interactor.fetchTask(by: taskId.uuidString)
        
        // Then
        XCTAssertEqual(mockCoreData.callHistory["fetchTask"] as? Int ?? 0, 1)
        XCTAssertEqual(mockCoreData.lastFetchId, taskId)
    }
    
    func testFetchTask_InvalidUUID_ReturnsError() {
        // Given
        let invalidId = "not-a-uuid"
        
        // When
        interactor.fetchTask(by: invalidId)
        
        // Then
        XCTAssertTrue(mockOutput.didFailFetch)
        XCTAssertEqual(mockCoreData.callHistory["fetchTask"] as? Int ?? 0, 0)
    }
    
    func testFetchTask_Success_ReturnsTask() {
        // Given
        let expectedTask = TodoTask(title: "Test")
        mockCoreData.storedTasks = [expectedTask]
        
        let expectation = XCTestExpectation(description: "Task fetched")
        mockOutput.onSuccess = { expectation.fulfill() }
        
        // When
        interactor.fetchTask(by: expectedTask.id.uuidString)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertTrue(mockOutput.didFetchTask)
        XCTAssertEqual(mockOutput.lastTask?.title, "Test")
    }
    
    func testFetchTask_NotFound_ReturnsError() {
        // Given
        mockCoreData.shouldSucceed = false
        mockCoreData.customError = NSError(domain: "Test", code: 404)
        
        let expectation = XCTestExpectation(description: "Fetch failed")
        mockOutput.onError = { expectation.fulfill() }
        
        // When
        interactor.fetchTask(by: UUID().uuidString)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertTrue(mockOutput.didFailFetch)
        XCTAssertNotNil(mockOutput.lastError)
    }
    
    // MARK: - Update Description Tests
    
    func testUpdateDescription_CallsCoreData() {
        // Given
        let task = TodoTask(title: "Task")
        mockCoreData.storedTasks = [task]
        
        let expectation = XCTestExpectation(description: "Update completed")
        mockOutput.onSuccess = { expectation.fulfill() }
        
        // When
        interactor.updateDescription(for: task, description: "New")
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(mockCoreData.callHistory["updateTaskDescription"] as? Int ?? 0, 1)
        XCTAssertEqual(mockCoreData.lastUpdateTask?.title, "Task")
        XCTAssertEqual(mockCoreData.lastUpdateDescription, "New")
    }
    
    func testUpdateDescription_Success_ReturnsUpdatedTask() {
        // Given
        let task = TodoTask(title: "Task")
        mockCoreData.storedTasks = [task]
        
        let expectation = XCTestExpectation(description: "Update success")
        mockOutput.onSuccess = { expectation.fulfill() }
        
        // When
        interactor.updateDescription(for: task, description: "Updated")
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertTrue(mockOutput.didUpdateDescription)
        XCTAssertEqual(mockOutput.lastTask?.description, "Updated")
    }
    
    func testUpdateDescription_Failure_ReturnsError() {
        // Given
        let task = TodoTask(title: "Task")
        mockCoreData.shouldSucceed = false
        mockCoreData.customError = NSError(domain: "Test", code: 500)
        
        let expectation = XCTestExpectation(description: "Update failed")
        mockOutput.onError = { expectation.fulfill() }
        
        // When
        interactor.updateDescription(for: task, description: "New")
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertTrue(mockOutput.didFailUpdate)
        XCTAssertNotNil(mockOutput.lastError)
    }
}

