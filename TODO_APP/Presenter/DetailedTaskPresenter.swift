//
//  DetailedTaskPresenter.swift
//  TODO_APP
//
//  Created by Marwa Awad on 01.12.2025.
//

import Foundation

protocol DetailedTaskPresenterInputProtocol: AnyObject {
    func viewDidLoad()
    func didUpdateDescription(_ description: String)
}

protocol DetailedTaskPresenterOutputProtocol: AnyObject {
    func displayTaskDetails(_ task: TodoTask)
    func displayError(_ message: String)
}

final class DetailedTaskPresenter: DetailedTaskPresenterInputProtocol, DetailedTaskInteractorOutputProtocol {
 
    //MARK: -  Dependencies
    weak var detailedTaskPresenterOutputProtocol: DetailedTaskPresenterOutputProtocol?
    weak var detailedTaskInteractorInputProtocol: DetailedTaskInteractorInputProtocol?
    var router: DetailedTaskRouterProtocol?
    
    //MARK: - Properties
    private let taskId: String
    private var task: TodoTask?
    
    //MARK: -  Delegate
    weak var taskUpdateDelegate: TaskUpdateDelegate?
    
    // MARK: - Initializer for the taskId
    init(taskId: String) {
        self.taskId = taskId
    }
    
    // MARK: - DetailedTaskPresenterOutputProtocol
    func taskFetched(_ task: TodoTask) {
        self.task = task
        DispatchQueue.main.async { [weak self] in
            self?.detailedTaskPresenterOutputProtocol?.displayTaskDetails(task)
        }
    }
    
    func taskFetchFailed(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.detailedTaskPresenterOutputProtocol?.displayError(error.localizedDescription)
        }
    }
    
    func taskDescriptionUpdated(_ task: TodoTask) {
        self.task = task
        print("Description updated: \(task.title)")
    }
    
    func taskUpdateFailed(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.detailedTaskPresenterOutputProtocol?.displayError("Failed to update: \(error.localizedDescription)")
        }
    }
    
    // MARK: - DetailedTaskInteractorInputProtocol
    func viewDidLoad() {
        detailedTaskInteractorInputProtocol?.fetchTask(by: taskId)
    }
    
    func didUpdateDescription(_ description: String) {
        guard let task = task else { return }
        detailedTaskInteractorInputProtocol?.updateDescription(for: task, description: description)
        
        if let taskId = UUID(uuidString: taskId) {
            taskUpdateDelegate?.didUpdateTaskDescription(for: taskId, newDescription: description)
        }
    }
}
