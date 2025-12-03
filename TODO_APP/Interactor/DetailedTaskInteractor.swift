//
//  DetailedTaskInteractor.swift
//  TODO_APP
//
//  Created by Marwa Awad on 01.12.2025.
//

import Foundation

protocol DetailedTaskInteractorInputProtocol: AnyObject {
    func fetchTask(by id: String)
    func updateDescription(for task: TodoTask, description: String)
}

protocol DetailedTaskInteractorOutputProtocol: AnyObject {
    func taskFetched(_ task: TodoTask)
    func taskFetchFailed(_ error: Error)
    func taskDescriptionUpdated(_ task: TodoTask)
    func taskUpdateFailed(_ error: Error)
}

final class DetailedTaskInteractor: DetailedTaskInteractorInputProtocol {
    
    // MARK: - Dependencies
    weak var detailedTaskInteractorOutputProtocol: DetailedTaskInteractorOutputProtocol?
    private let coreDataService: CoreDataServiceProtocol
    
    // MARK: - Initializer
    init(coreDataService: CoreDataServiceProtocol = CoreDataService.shared) {
        self.coreDataService = coreDataService
    }
    
    // MARK: -  DetailedTaskInteractorInputProtocol
    func fetchTask(by id: String) {
        guard let taskId = UUID(uuidString: id) else {
            detailedTaskInteractorOutputProtocol?.taskFetchFailed(NSError(domain: "TaskError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid ID"]))
            return
        }
        
        coreDataService.fetchTask(by: taskId) { [weak self] result in 
            switch result {
            case .success(let task):
                if let task = task {
                    self?.detailedTaskInteractorOutputProtocol?.taskFetched(task)
                } else {
                    self?.detailedTaskInteractorOutputProtocol?.taskFetchFailed(NSError(domain: "TaskError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Task not found"]))
                }
            case .failure(let error):
                self?.detailedTaskInteractorOutputProtocol?.taskFetchFailed(error)
            }
        }
    }
    
    func updateDescription(for task: TodoTask, description: String) {
        coreDataService.updateTaskDescription(task, newDescription: description) { [weak self] result in
            switch result {
            case .success(let updatedTask):
                self?.detailedTaskInteractorOutputProtocol?.taskDescriptionUpdated(updatedTask)
            case .failure(let error):
                self?.detailedTaskInteractorOutputProtocol?.taskUpdateFailed(error)
            }
        }
    }
}
