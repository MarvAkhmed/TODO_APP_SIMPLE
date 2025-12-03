//
//  DetailedTaskInteractor.swift
//  TODO_APP
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
    
    weak var output: DetailedTaskInteractorOutputProtocol?
    private let coreDataService: CoreDataServiceProtocol
    
    init(coreDataService: CoreDataServiceProtocol = CoreDataService.shared) {
        self.coreDataService = coreDataService
    }
    
    func fetchTask(by id: String) {
        guard let taskId = UUID(uuidString: id) else {
            output?.taskFetchFailed(NSError(domain: "TaskError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid ID"]))
            return
        }
        
        coreDataService.fetchTask(by: taskId) { [weak self] result in 
            switch result {
            case .success(let task):
                if let task = task {
                    self?.output?.taskFetched(task)
                } else {
                    self?.output?.taskFetchFailed(NSError(domain: "TaskError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Task not found"]))
                }
            case .failure(let error):
                self?.output?.taskFetchFailed(error)
            }
        }
    }
    
    func updateDescription(for task: TodoTask, description: String) {
        coreDataService.updateTaskDescription(task, newDescription: description) { [weak self] result in
            switch result {
            case .success(let updatedTask):
                self?.output?.taskDescriptionUpdated(updatedTask)
            case .failure(let error):
                self?.output?.taskUpdateFailed(error)
            }
        }
    }
}
