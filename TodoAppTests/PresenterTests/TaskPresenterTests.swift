//
//  TaskPresenterTests.swift
//  TODO_APPTests
//
//  Created by Test on 03.12.2025.
//

import XCTest
@testable import TODO_APP

final class TaskPresenterTests: XCTestCase {

    // MARK: - Mocks
    final class MockView: TaskPresenterOutputProtocol {
        var displayedTasks: [TodoTask]?
        var footerCount: Int?
        var isLoadingShown: Bool?
        var errorMessage: String?
        
        func displayTasks(_ tasks: [TodoTask]) { displayedTasks = tasks }
        func updateFooter(_ total: Int) { footerCount = total }
        func showLoading(_ isLoading: Bool) { isLoadingShown = isLoading }
        func displayError(_ message: String) { errorMessage = message }
    }
    
    final class MockInteractor: TaskInteractorInputProtocol {
        var fetchAllTasksCalled = false
        var addTaskCalled = false
        var toggleTaskCalled = false
        var deleteTaskCalled = false
        var searchTaskCalled = false
        var updateTaskCalled = false
        
        var passedTitle: String?
        var passedDescription: String?
        var passedTask: TodoTask?
        var passedSearchText: String?
        var passedNewTitle: String?
        var passedNewDesc: String?
        
        func fetchAllTasks() { fetchAllTasksCalled = true }
        func addTask(title: String, description: String?) {
            addTaskCalled = true
            passedTitle = title
            passedDescription = description
        }
        func toggleTask(_ task: TodoTask) {
            toggleTaskCalled = true
            passedTask = task
        }
        func deleteTask(_ task: TodoTask) {
            deleteTaskCalled = true
            passedTask = task
        }
        func searchTasks(text: String) {
            searchTaskCalled = true
            passedSearchText = text
        }
        func updateTask(_ task: TodoTask, newTitle: String, newDescription: String?) {
            updateTaskCalled = true
            passedTask = task
            passedNewTitle = newTitle
            passedNewDesc = newDescription
        }
    }

    // MARK: - Properties
    var presenter: TaskPresenter!
    var view: MockView!
    var interactor: MockInteractor!

    override func setUp() {
        super.setUp()
        presenter = TaskPresenter()
        view = MockView()
        interactor = MockInteractor()

        presenter.view = view
        presenter.interactor = interactor
    }

    // MARK: - Tests

    func test_viewDidLoad_triggersFetchAndShowsLoading() {
        presenter.viewDidLoad()
        
        XCTAssertTrue(interactor.fetchAllTasksCalled)
        XCTAssertEqual(view.isLoadingShown, true)
    }
    
    func test_didTapAddTask_withEmptyTitle_showsError() {
        presenter.didTapAddTask(title: "", description: "desc")
        
        XCTAssertEqual(view.errorMessage, "Task title cannot be empty")
        XCTAssertFalse(interactor.addTaskCalled)
    }
    
    func test_didTapAddTask_callsInteractor() {
        presenter.didTapAddTask(title: "New Task", description: "desc")
        
        XCTAssertTrue(interactor.addTaskCalled)
        XCTAssertEqual(interactor.passedTitle, "New Task")
    }
    
    func test_didSelectTask_callsToggle() {
        let task = TodoTask(title: "Test")
        
        presenter.didSelectTask(task)
        
        XCTAssertTrue(interactor.toggleTaskCalled)
        XCTAssertEqual(interactor.passedTask?.id, task.id)
    }
    
    func test_didDeleteTask_callsDelete() {
        let task = TodoTask(title: "Test")
        
        presenter.didDeleteTask(task)
        
        XCTAssertTrue(interactor.deleteTaskCalled)
        XCTAssertEqual(interactor.passedTask?.id, task.id)
    }
    
    func test_didSearch_callsInteractor() {
        presenter.didSearch(text: "abc")
        
        XCTAssertTrue(interactor.searchTaskCalled)
        XCTAssertEqual(interactor.passedSearchText, "abc")
    }
    
    func test_didUpdateTask_callsInteractor() {
        let task = TodoTask(title: "Old")
        
        presenter.didUpdateTask(task, newTitle: "New", newDescription: "Updated")
        
        XCTAssertTrue(interactor.updateTaskCalled)
        XCTAssertEqual(interactor.passedNewTitle, "New")
    }
    
    func test_allTasksFetched_updatesView() {
        let tasks = [
          TodoTask(title: "Todo 1")
        ]
        
        presenter.allTasksFetched(tasks, totalCount: 1)
        
        // We dispatch to main, so async expectations:
        let expectation = XCTestExpectation(description: "Wait for async")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            XCTAssertEqual(self.view.displayedTasks?.count, 1)
            XCTAssertEqual(self.view.footerCount, 1)
            XCTAssertEqual(self.view.isLoadingShown, false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func test_tasksFetchFailed_showsError() {
        presenter.tasksFetchFailed(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error"]))
        
        let expectation = XCTestExpectation(description: "Wait for async")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            XCTAssertEqual(self.view.errorMessage, "Error")
            XCTAssertEqual(self.view.isLoadingShown, false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
}

