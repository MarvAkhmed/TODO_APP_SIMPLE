//
//  DetailedTaskPresenterTests.swift
//  TODO_APPTests
//
//  Created by Test on 03.12.2025.
//

import XCTest
@testable import TODO_APP

final class DetailedTaskPresenterTests: XCTestCase {

    // MARK: - Mock View (Output)
    final class MockView: DetailedTaskPresenterOutputProtocol {
        var displayedTask: TodoTask?
        var displayedError: String?

        func displayTaskDetails(_ task: TodoTask) {
            displayedTask = task
        }

        func displayError(_ message: String) {
            displayedError = message
        }
    }

    // MARK: - Mock Interactor (Input)
    final class MockInteractor: DetailedTaskInteractorInputProtocol {
        var fetchTaskCalled = false
        var updateDescriptionCalled = false

        var receivedTaskId: String?
        var receivedTaskForUpdate: TodoTask?
        var receivedDescription: String?

        func fetchTask(by id: String) {
            fetchTaskCalled = true
            receivedTaskId = id
        }

        func updateDescription(for task: TodoTask, description: String) {
            updateDescriptionCalled = true
            receivedTaskForUpdate = task
            receivedDescription = description
        }
    }

    // MARK: - Mock Delegate
    final class MockDelegate: TaskUpdateDelegate {
        var updatedTaskId: UUID?
        var updatedDescription: String?

        func didUpdateTaskDescription(for id: UUID, newDescription: String?) {
            updatedTaskId = id
            updatedDescription = newDescription
        }
    }

    // MARK: - Properties
    var presenter: DetailedTaskPresenter!
    var mockView: MockView!
    var mockInteractor: MockInteractor!
    var mockDelegate: MockDelegate!

    // MARK: - Setup
    override func setUp() {
        super.setUp()

        presenter = DetailedTaskPresenter(taskId: UUID().uuidString)
        mockView = MockView()
        mockInteractor = MockInteractor()
        mockDelegate = MockDelegate()

        presenter.detailedTaskPresenterOutputProtocol = mockView
        presenter.detailedTaskInteractorInputProtocol = mockInteractor
        presenter.taskUpdateDelegate = mockDelegate
    }

    // MARK: - Tests

    func test_viewDidLoad_callsFetchTask() {
        presenter.viewDidLoad()

        XCTAssertTrue(mockInteractor.fetchTaskCalled)
        XCTAssertEqual(mockInteractor.receivedTaskId, presenter.taskIdentifierForTests)
    }

    func test_taskFetched_updatesView() {
        let exp = expectation(description: "async")
        let task = TodoTask(title: "Sample Task", description: "Test")

        presenter.taskFetched(task)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.mockView.displayedTask?.title, "Sample Task")
            XCTAssertEqual(self.mockView.displayedTask?.description, "Test")
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
    }

    func test_taskFetchFailed_showsError() {
        let exp = expectation(description: "async")
        let error = NSError(domain: "TEST", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch"])

        presenter.taskFetchFailed(error)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.mockView.displayedError, "Failed to fetch")
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
    }

    func test_didUpdateDescription_callsInteractor_andDelegate() {
        // Arrange: first fetch task to set presenter.task
        let task = TodoTask(title: "Old", description: "Old")
        presenter.taskFetched(task)

        // Act
        presenter.didUpdateDescription("New Description")

        // Assert interactor
        XCTAssertTrue(mockInteractor.updateDescriptionCalled)
        XCTAssertEqual(mockInteractor.receivedTaskForUpdate?.id, task.id)
        XCTAssertEqual(mockInteractor.receivedDescription, "New Description")

        // Assert delegate
        XCTAssertEqual(mockDelegate.updatedDescription, "New Description")
        XCTAssertEqual(mockDelegate.updatedTaskId, UUID(uuidString: presenter.taskIdentifierForTests))
    }

    func test_taskUpdateFailed_showsError() {
        let exp = expectation(description: "async")
        let error = NSError(domain: "TEST", code: 0, userInfo: [NSLocalizedDescriptionKey: "Update failed"])

        presenter.taskUpdateFailed(error)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.mockView.displayedError, "Failed to update: Update failed")
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
    }
}

