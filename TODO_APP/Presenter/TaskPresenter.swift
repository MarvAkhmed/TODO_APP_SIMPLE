//
//  TaskPresenter.swift
//  TODO_APP
//
//  Created by Marwa Awad on 01.12.2025.
//


import Foundation

protocol TaskPresenterInputProtocol: AnyObject {
    func viewDidLoad()
    func didTapAddTask(title: String, description: String?)
    func didSelectTask(_ task: TodoTask)
    func didDeleteTask(_ task: TodoTask)
    func didSearch(text: String)
    func didUpdateTask(_ task: TodoTask, newTitle: String, newDescription: String?)
}

protocol TaskPresenterOutputProtocol: AnyObject {
    func displayTasks(_ tasks: [TodoTask])
    func updateFooter(_ total: Int)
    func showLoading(_ isLoading: Bool)
    func displayError(_ message: String)
}

final class TaskPresenter: TaskPresenterInputProtocol, TaskInteractorOutputProtocol {
    
    //MARK: -  Dependencies & Properties
    weak var view: TaskPresenterOutputProtocol?
    var interactor: TaskInteractorInputProtocol?
    var router: TaskRouterProtocol?
    
    private var displayedTasks: [TodoTask] = []
    
    //MARK: - TaskPresenterInputProtocol
    func viewDidLoad() {
        view?.showLoading(true)
        interactor?.fetchAllTasks()
    }
    
    func didTapAddTask(title: String, description: String?) {
        guard !title.isEmpty else {
            view?.displayError("Task title cannot be empty")
            return
        }
        interactor?.addTask(title: title, description: description)
    }
    
    func didSelectTask(_ task: TodoTask) {
        interactor?.toggleTask(task)
    }
    
    func didDeleteTask(_ task: TodoTask) {
        interactor?.deleteTask(task)
    }
    
    func didSearch(text: String) {
        interactor?.searchTasks(text: text)
    }
    
    func didUpdateTask(_ task: TodoTask, newTitle: String, newDescription: String?) {
        interactor?.updateTask(task, newTitle: newTitle, newDescription: newDescription)
    }
    
    // MARK: - TaskInteractorOutputProtocol
    func allTasksFetched(_ tasks: [TodoTask], totalCount: Int) {
        displayedTasks = tasks
        
        DispatchQueue.main.async { [weak self] in
            self?.view?.displayTasks(tasks)
            self?.view?.updateFooter(totalCount)
            self?.view?.showLoading(false)
        }
    }
    
    func tasksFetchFailed(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.view?.displayError(error.localizedDescription)
            self?.view?.showLoading(false)
        }
    }
    
    func taskAdded(_ task: TodoTask) {
        print(" Presenter: Task added - \(task.title)")
    }
    
    func taskUpdated(_ task: TodoTask) {
        print(" Presenter: Task updated - \(task.title)")
    }
    
    func taskDeleted(_ task: TodoTask) {
        print(" Presenter: Task deleted - \(task.title)")
    }
    
    func displayError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.view?.displayError(message)
        }
    }
}
