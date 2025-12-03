// TaskInteractorTests.swift
// TODO_APPTests
//
// Created by Marwa Awad on 03.12.2025.
//

import XCTest
import CoreData
@testable import TODO_APP

final class TaskInteractorTests: XCTestCase {
    
    var interactor: TaskInteractor!
    var mockPresenter: MockInteractorOutput!
    var mockCoreData: MockCoreDataService!
    var mockTodoService: MockTodoService!
    var testContext: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        
        // Setup Core Data for tests
        testContext = TestContextProvider.context
        
        // Setup mocks
        mockPresenter = MockInteractorOutput()
        mockCoreData = MockCoreDataService(context: testContext)
        mockTodoService = MockTodoService()
        
        // Create interactor with mocks
        interactor = TaskInteractor(todoService: mockTodoService, coreDataManager: mockCoreData)
        interactor.presenter = mockPresenter
    }
    
    override func tearDown() {
        interactor = nil
        mockPresenter = nil
        mockCoreData = nil
        mockTodoService = nil
        testContext = nil
        super.tearDown()
    }
    
    // MARK: - Helper methods for callHistory
    
    private func wasCalled(_ method: String) -> Bool {
        return (mockCoreData.callHistory[method] as? Int ?? 0) > 0
    }
    
    private func callCount(_ method: String) -> Int {
        return mockCoreData.callHistory[method] as? Int ?? 0
    }
    
    // MARK: - TaskInteractorInputProtocol Tests
    
    func testFetchAllTasks_LoadsCachedTasksFirst() {
        // Given
        let task1 = TodoTask(title: "Task 1", createdAt: Date().addingTimeInterval(-100))
        let task2 = TodoTask(title: "Task 2", createdAt: Date())
        mockCoreData.storedTasks = [task1, task2]
        
        let expectation = XCTestExpectation(description: "Tasks loaded")
        mockPresenter.onTasksFetched = { expectation.fulfill() }
        
        // When
        interactor.fetchAllTasks()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertTrue(mockPresenter.didReceiveTasks)
        XCTAssertTrue(wasCalled("fetchAllTasks"))
        XCTAssertEqual(mockPresenter.lastTasksCount, 2)
        // Should be sorted by createdAt descending (newest first)
        XCTAssertEqual(mockPresenter.lastTasks.first?.title, "Task 2")
    }
    
    func testAddTask_Success() {
        // Given
        let expectation = XCTestExpectation(description: "Task added")
        mockPresenter.onTasksFetched = { expectation.fulfill() }
        
        // When
        interactor.addTask(title: "New Task", description: "Description")
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertTrue(mockPresenter.didReceiveTasks)
        XCTAssertTrue(wasCalled("createTask"))
        XCTAssertEqual(mockCoreData.lastCreatedTask?.title, "New Task")
        XCTAssertEqual(mockCoreData.lastCreatedTask?.description, "Description")
        XCTAssertFalse(mockCoreData.lastCreatedTask?.isCompleted ?? true)
    }
    
    func testAddTask_EmptyTitleError() {
        // Given
        let expectation = XCTestExpectation(description: "Error shown")
        mockPresenter.onError = { expectation.fulfill() }
        
        // When
        interactor.addTask(title: "", description: "Description")
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertTrue(mockPresenter.didShowError)
        XCTAssertEqual(mockPresenter.lastErrorMessage, "Task title cannot be empty")
        XCTAssertFalse(wasCalled("createTask"))
    }
    
    func testAddTask_DuplicateError() {
        // Given
        let existingTask = TodoTask(title: "Existing Task")
        mockCoreData.storedTasks = [existingTask]
        mockCoreData.taskExistsResult = true
        
        let expectation = XCTestExpectation(description: "Duplicate error")
        mockPresenter.onError = { expectation.fulfill() }
        
        // When
        interactor.addTask(title: "Existing Task", description: nil)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertTrue(mockPresenter.didShowError)
        XCTAssertEqual(mockPresenter.lastErrorMessage, "This task already exists")
        XCTAssertTrue(wasCalled("taskExists"))
    }
    
    func testAddTask_SaveFailedError() {
        // Given
        mockCoreData.createTaskResult = false
        
        let expectation = XCTestExpectation(description: "Save failed")
        mockPresenter.onError = { expectation.fulfill() }
        
        // When
        interactor.addTask(title: "Test Task", description: nil)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertTrue(mockPresenter.didShowError)
        XCTAssertEqual(mockPresenter.lastErrorMessage, "Failed to save task")
        XCTAssertTrue(wasCalled("createTask"))
    }
    
    func testToggleTask_TogglesCompletion() {
        // Given
        let task = TodoTask(title: "Test Task", isCompleted: false)
        mockCoreData.storedTasks = [task]
        
        let fetchExpectation = XCTestExpectation(description: "Initial fetch")
        let toggleExpectation = XCTestExpectation(description: "Toggle completed")
        var fetchCount = 0
        
        mockPresenter.onTasksFetched = {
            fetchCount += 1
            if fetchCount == 1 {
                fetchExpectation.fulfill()
            } else if fetchCount == 2 {
                toggleExpectation.fulfill()
            }
        }
        
        // Load tasks first
        interactor.fetchAllTasks()
        wait(for: [fetchExpectation], timeout: 1.0)
        
        // When
        interactor.toggleTask(task)
        
        // Then
        wait(for: [toggleExpectation], timeout: 1.0)
        
        XCTAssertTrue(wasCalled("updateTask"))
        XCTAssertEqual(mockCoreData.lastUpdatedTask?.title, "Test Task")
        XCTAssertEqual(mockCoreData.lastUpdatedTask?.isCompleted, true)
    }
    
    func testToggleTask_NotFoundReloadsTasks() {
        // Given
        let task = TodoTask(title: "Non-existent")
        
        let expectation = XCTestExpectation(description: "Tasks reloaded")
        mockPresenter.onTasksFetched = { expectation.fulfill() }
        
        // When
        interactor.toggleTask(task)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertTrue(mockPresenter.didReceiveTasks)
        XCTAssertTrue(wasCalled("fetchAllTasks"))
    }
    
    func testDeleteTask_Success() {
        // Given
        let task = TodoTask(title: "Delete Me")
        mockCoreData.storedTasks = [task]
        
        let fetchExpectation = XCTestExpectation(description: "Initial fetch")
        let deleteExpectation = XCTestExpectation(description: "Delete completed")
        var fetchCount = 0
        
        mockPresenter.onTasksFetched = {
            fetchCount += 1
            if fetchCount == 1 {
                fetchExpectation.fulfill()
            } else if fetchCount == 2 {
                deleteExpectation.fulfill()
            }
        }
        
        // Load tasks first
        interactor.fetchAllTasks()
        wait(for: [fetchExpectation], timeout: 1.0)
        
        // When
        interactor.deleteTask(task)
        
        // Then
        wait(for: [deleteExpectation], timeout: 1.0)
        
        XCTAssertTrue(wasCalled("deleteTask"))
        XCTAssertEqual(mockCoreData.lastDeletedTask?.title, "Delete Me")
    }
    
    func testSearchTasks_EmptySearch() {
        // Given
        let tasks = [
            TodoTask(title: "Task A"),
            TodoTask(title: "Task B")
        ]
        mockCoreData.storedTasks = tasks
        
        let fetchExpectation = XCTestExpectation(description: "Initial fetch")
        let searchExpectation = XCTestExpectation(description: "Search completed")
        var fetchCount = 0
        
        mockPresenter.onTasksFetched = {
            fetchCount += 1
            if fetchCount == 1 {
                fetchExpectation.fulfill()
            } else if fetchCount == 2 {
                searchExpectation.fulfill()
            }
        }
        
        interactor.fetchAllTasks()
        wait(for: [fetchExpectation], timeout: 1.0)
        
        // When
        interactor.searchTasks(text: "")
        
        // Then
        wait(for: [searchExpectation], timeout: 1.0)
        
        XCTAssertEqual(mockPresenter.lastTasksCount, 2)
    }
    
    func testSearchTasks_FiltersByTitle() {
        // Given
        let tasks = [
            TodoTask(title: "Buy groceries"),
            TodoTask(title: "Clean house"),
            TodoTask(title: "Fix car")
        ]
        mockCoreData.storedTasks = tasks
        
        let fetchExpectation = XCTestExpectation(description: "Initial fetch")
        let searchExpectation = XCTestExpectation(description: "Search completed")
        var fetchCount = 0
        
        mockPresenter.onTasksFetched = {
            fetchCount += 1
            if fetchCount == 1 {
                fetchExpectation.fulfill()
            } else if fetchCount == 2 {
                searchExpectation.fulfill()
            }
        }
        
        interactor.fetchAllTasks()
        wait(for: [fetchExpectation], timeout: 1.0)
        
        // When
        interactor.searchTasks(text: "groceries")
        
        // Then
        wait(for: [searchExpectation], timeout: 1.0)
        
        XCTAssertEqual(mockPresenter.lastTasksCount, 1)
        XCTAssertEqual(mockPresenter.lastTasks.first?.title, "Buy groceries")
    }
    
    func testSearchTasks_FiltersByDescription() {
        // Given
        let tasks = [
            TodoTask(title: "Task 1", description: "Important task"),
            TodoTask(title: "Task 2", description: "Urgent task"),
            TodoTask(title: "Task 3", description: "Normal task")
        ]
        mockCoreData.storedTasks = tasks
        
        let fetchExpectation = XCTestExpectation(description: "Initial fetch")
        let searchExpectation = XCTestExpectation(description: "Search completed")
        var fetchCount = 0
        
        mockPresenter.onTasksFetched = {
            fetchCount += 1
            if fetchCount == 1 {
                fetchExpectation.fulfill()
            } else if fetchCount == 2 {
                searchExpectation.fulfill()
            }
        }
        
        interactor.fetchAllTasks()
        wait(for: [fetchExpectation], timeout: 1.0)
        
        // When
        interactor.searchTasks(text: "urgent")
        
        // Then
        wait(for: [searchExpectation], timeout: 1.0)
        
        XCTAssertEqual(mockPresenter.lastTasksCount, 1)
        XCTAssertEqual(mockPresenter.lastTasks.first?.description, "Urgent task")
    }
    
    func testUpdateTask_Success() {
        // Given
        let task = TodoTask(title: "Old Title", description: "Old Desc")
        mockCoreData.storedTasks = [task]
        
        let fetchExpectation = XCTestExpectation(description: "Initial fetch")
        let updateExpectation = XCTestExpectation(description: "Update completed")
        var fetchCount = 0
        
        mockPresenter.onTasksFetched = {
            fetchCount += 1
            if fetchCount == 1 {
                fetchExpectation.fulfill()
            } else if fetchCount == 2 {
                updateExpectation.fulfill()
            }
        }
        
        interactor.fetchAllTasks()
        wait(for: [fetchExpectation], timeout: 1.0)
        
        // When
        interactor.updateTask(task, newTitle: "New Title", newDescription: "New Desc")
        
        // Then
        wait(for: [updateExpectation], timeout: 1.0)
        
        XCTAssertTrue(wasCalled("updateTask"))
        XCTAssertEqual(mockCoreData.lastUpdatedTask?.title, "New Title")
        XCTAssertEqual(mockCoreData.lastUpdatedTask?.description, "New Desc")
    }
    
    func testUpdateTask_EmptyTitleDoesNothing() {
        // Given
        let task = TodoTask(title: "Original")
        mockCoreData.storedTasks = [task]
        
        let expectation = XCTestExpectation(description: "Initial fetch")
        mockPresenter.onTasksFetched = { expectation.fulfill() }
        
        interactor.fetchAllTasks()
        wait(for: [expectation], timeout: 1.0)
        
        // When
        interactor.updateTask(task, newTitle: "", newDescription: nil)
        
        // Wait and check no update happened
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        
        XCTAssertFalse(wasCalled("updateTask"))
    }
    
    @MainActor
    func testFetchAllTasks_SyncsWithRemote() async {
        // Given
        let remoteTodos = [
            Todo(id: 1, todo: "Remote Task 1", completed: false, userId: 1),
            Todo(id: 2, todo: "Remote Task 2", completed: true, userId: 1)
        ]
        mockTodoService.mockTodos = remoteTodos
        mockTodoService.mockTotalCount = 100
        
        let expectation = XCTestExpectation(description: "Sync completed")
        mockCoreData.onSyncCompleted = { expectation.fulfill() }
        
        // When
        interactor.fetchAllTasks()
        
        // Wait for sync to complete
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Then
        XCTAssertTrue(mockTodoService.fetchAllTodosCalled)
        XCTAssertTrue(wasCalled("syncTasksWithRemote"))
        XCTAssertEqual(mockCoreData.lastSyncTasks?.count, 2)
    }
    
    func testTasksFetchFailed() {
        // Given
        let expectation = XCTestExpectation(description: "Fetch failed")
        mockPresenter.onTasksFetchFailed = { expectation.fulfill() }
        
        // When
        mockPresenter.tasksFetchFailed(NSError(domain: "Test", code: 500))
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertTrue(mockPresenter.tasksFetchFailedCalled)
        XCTAssertNotNil(mockPresenter.lastError)
    }
}

