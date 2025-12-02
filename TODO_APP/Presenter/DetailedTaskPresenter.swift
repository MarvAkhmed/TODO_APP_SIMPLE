//
//  DetailedTaskPresenter.swift
//  TODO_APP
//

import Foundation

protocol DetailedTaskPresenterInputProtocol: AnyObject {
    func viewDidLoad()
    func didTapBack()
    func didUpdateDescription(_ description: String)
}

protocol DetailedTaskPresenterOutputProtocol: AnyObject {
    func displayTaskDetails(_ task: TodoTask)
    func showLoading(_ isLoading: Bool)
    func displayError(_ message: String)
    func navigateBack()
}

final class DetailedTaskPresenter: DetailedTaskPresenterInputProtocol, DetailedTaskInteractorOutputProtocol {
    
    weak var view: DetailedTaskPresenterOutputProtocol?
    var interactor: DetailedTaskInteractorInputProtocol?
    var router: DetailedTaskRouterProtocol?
    
    private let taskId: String
    private var task: TodoTask?
    
    init(taskId: String) {
        self.taskId = taskId
    }
    
    // MARK: - Input Protocol
    func viewDidLoad() {
        view?.showLoading(true)
        interactor?.fetchTask(by: taskId)
    }
    
    func didTapBack() {
        router?.navigateBack()
    }
    
    func didUpdateDescription(_ description: String) {
        guard let task = task else { return }
        interactor?.updateDescription(for: task, description: description)
    }
    
    // MARK: - Interactor Output
    func taskFetched(_ task: TodoTask) {
        self.task = task
        DispatchQueue.main.async { [weak self] in
            self?.view?.displayTaskDetails(task)
            self?.view?.showLoading(false)
        }
    }
    
    func taskFetchFailed(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.view?.displayError(error.localizedDescription)
            self?.view?.showLoading(false)
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
