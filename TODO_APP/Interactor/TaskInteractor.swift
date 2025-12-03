//
//  TaskInteractor.swift
//  TODO_APP
//
//  Created by Marwa Awad on 01.12.2025.
//

import Foundation

protocol TaskInteractorInputProtocol: AnyObject {
    func fetchAllTasks()
    func addTask(title: String, description: String?)
    func toggleTask(_ task: TodoTask)
    func deleteTask(_ task: TodoTask)
    func searchTasks(text: String)
    func updateTask(_ task: TodoTask, newTitle: String, newDescription: String?)
}

protocol TaskInteractorOutputProtocol: AnyObject {
    func allTasksFetched(_ tasks: [TodoTask], totalCount: Int)
    func tasksFetchFailed(_ error: Error)
    func displayError(_ message: String)
}

final class TaskInteractor: TaskInteractorInputProtocol {
    
    weak var presenter: TaskInteractorOutputProtocol?
    private let todoService: TodoServiceProtocol
    private let coreDataManager: CoreDataServiceProtocol
    
    // MARK: - Data Storage
    private var allTasks: [TodoTask] = []
    private var searchText: String = ""
    
    // MARK: - Initializer
    init(todoService: TodoServiceProtocol = TodoNetworkService(),
         coreDataManager: CoreDataServiceProtocol = CoreDataService.shared) {
        self.todoService = todoService
        self.coreDataManager = coreDataManager
    }
    
    // MARK: - TaskInteractorInputProtocol
    func fetchAllTasks() {
        loadAndDisplayCachedTasks()
        
        Task { [weak self] in
            await self?.syncTasksWithRemote()
        }
    }
    
    func addTask(title: String, description: String?) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            notifyError("Task title cannot be empty")
            return
        }
        
        guard !isDuplicateTask(title: trimmedTitle, description: description) else {
            notifyError("This task already exists")
            return
        }
        
        let task = TodoTask(
            id: UUID(),
            title: trimmedTitle,
            description: description?.trimmingCharacters(in: .whitespacesAndNewlines),
            isCompleted: false,
            userId: 1,
            createdAt: Date(),
            remoteId: nil
        )
        
        if coreDataManager.createTask(from: task) {
            allTasks.insert(task, at: 0)
            updatePresenterWithCurrentTasks()
        } else {
            notifyError("Failed to save task")
        }
    }
    
    func updateTask(_ task: TodoTask, newTitle: String, newDescription: String?) {
        let trimmedTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        if let index = allTasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = allTasks[index]
            updatedTask.title = trimmedTitle
            updatedTask.description = newDescription?.trimmingCharacters(in: .whitespacesAndNewlines)
            _ = coreDataManager.updateTask(updatedTask)
            allTasks[index] = updatedTask
            updatePresenterWithCurrentTasks()
        }
    }
    
    func toggleTask(_ task: TodoTask) {
        if let index = allTasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = allTasks[index]
            updatedTask.isCompleted.toggle()
            _ = coreDataManager.updateTask(updatedTask)
            allTasks[index] = updatedTask
            
            updatePresenterWithCurrentTasks()
            
        } else {
            loadAndDisplayCachedTasks()
        }
    }
    
    func deleteTask(_ task: TodoTask) {
        _ = coreDataManager.deleteTask(task)
        allTasks.removeAll { $0.id == task.id }
        updatePresenterWithCurrentTasks()
    }
    
    func searchTasks(text: String) {
        searchText = text
        updatePresenterWithCurrentTasks()
    }
}

// MARK: - Private Helpers
private extension TaskInteractor {
    func loadAndDisplayCachedTasks() {
        let taskEntities = self.coreDataManager.fetchAllTasks()
        self.allTasks = taskEntities.compactMap { $0.toTask() }
        updatePresenterWithCurrentTasks()
    }
    
    func syncTasksWithRemote() async {
        do {
            let todos = try await self.todoService.fetchAllTodos()
            let remoteTasks = todos.map { $0.task }
            
            _ = self.coreDataManager.syncTasksWithRemote(remoteTasks)
            
            let updatedTaskEntities = self.coreDataManager.fetchAllTasks()
            self.allTasks = updatedTaskEntities.compactMap { $0.toTask() }
            
            await fetchAndUpdateTotalCount()
            
        } catch {
            print("Background sync failed: \(error)")
        }
    }
    
    func fetchAndUpdateTotalCount() async {
        do {
            let totalCount = try await self.todoService.fetchTotalCount()
            
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                let filtered = self.filteredTasks()
                self.presenter?.allTasksFetched(filtered, totalCount: totalCount)
            }
        } catch {
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                let filtered = self.filteredTasks()
                self.presenter?.allTasksFetched(filtered, totalCount: self.allTasks.count)
            }
        }
    }
    
    func updatePresenterWithCurrentTasks() {
        let filtered = filteredTasks()
        
        DispatchQueue.main.async { [weak self] in
            self?.presenter?.allTasksFetched(
                filtered,
                totalCount: self?.allTasks.count ?? 0
            )
        }
    }
    
    func isDuplicateTask(title: String, description: String?) -> Bool {
        let normalizedTitle = title.lowercased()
        
        let existsInCache = allTasks.contains { existingTask in
            existingTask.title.lowercased() == normalizedTitle
        }
        if existsInCache { return true }
        
        return coreDataManager.taskExists(title: title, description: description)
    }
    
    func filteredTasks() -> [TodoTask] {
        if searchText.isEmpty {
            return allTasks.sorted(by: { $0.createdAt > $1.createdAt })
        } else {
            return allTasks
                .filter { task in
                    let titleContains = task.title.localizedCaseInsensitiveContains(searchText)
                    let descriptionContains = task.description?.localizedCaseInsensitiveContains(searchText) ?? false
                    return titleContains || descriptionContains
                }
                .sorted(by: { $0.createdAt > $1.createdAt })
        }
    }
    
    func notifyError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.presenter?.displayError(message)
        }
    }
}
