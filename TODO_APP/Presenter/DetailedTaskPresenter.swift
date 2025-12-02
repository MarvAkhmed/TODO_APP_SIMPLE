//
//  DetailedTaskPresenter.swift
//  TODO_APP
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
 
    weak var view: DetailedTaskPresenterOutputProtocol?
    var interactor: DetailedTaskInteractorInputProtocol?
    var router: DetailedTaskRouterProtocol?
    weak var taskUpdateDelegate: TaskUpdateDelegate?
    private let taskId: String
    private var task: TodoTask?
    
    init(taskId: String) {
        self.taskId = taskId
    }
    
    // MARK: - Input Protocol
    func viewDidLoad() {
        interactor?.fetchTask(by: taskId)
    }
    
    
    func didUpdateDescription(_ description: String) {
        guard let task = task else { return }
        interactor?.updateDescription(for: task, description: description)
        
        if let taskId = UUID(uuidString: taskId) {
            taskUpdateDelegate?.didUpdateTaskDescription(for: taskId, newDescription: description)
        }
    }
    
    // MARK: - Interactor Output
    func taskFetched(_ task: TodoTask) {
        self.task = task
        DispatchQueue.main.async { [weak self] in
            self?.view?.displayTaskDetails(task)
        }
    }
    
    func taskFetchFailed(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.view?.displayError(error.localizedDescription)
        }
    }
    
    func taskDescriptionUpdated(_ task: TodoTask) {
        self.task = task
        print("Description updated: \(task.title)")
    }
    
    func taskUpdateFailed(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.view?.displayError("Failed to update: \(error.localizedDescription)")
        }
    }
}
