//
//  MockCoreDataService.swift
//  TodoAppTests
//
//  Created by Marwa Awad on 03.12.2025.
//

// MockCoreDataService.swift
import CoreData
@testable import TODO_APP

class MockCoreDataService: CoreDataServiceProtocol {
    // Configuration for different test scenarios
    var isDetailedOnly = false  // Only fetch/update methods
    var shouldSucceed = true
    var customError: Error?
    
    // Track everything
    var callHistory: [String: Any] = [:]
    var storedTasks: [TodoTask] = []
    
    // Configurable results
    var createTaskResult = true
    var updateTaskResult = true
    var deleteTaskResult = true
    var taskExistsResult = false
    
    // Captured parameters
    var lastCreatedTask: TodoTask?
    var lastUpdatedTask: TodoTask?
    var lastDeletedTask: TodoTask?
    var lastSyncTasks: [TodoTask]?
    var lastFetchId: UUID?
    var lastUpdateTask: TodoTask?
    var lastUpdateDescription: String?
    var lastCheckTitle: String?
    var lastCheckDescription: String?
    
    // Callbacks
    var onSyncCompleted: (() -> Void)?
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = TestContextProvider.context) {
        self.context = context
    }
    
    // MARK: - Common Methods (always implemented)
    
    func fetchTask(by id: UUID, completion: @escaping (Result<TodoTask?, Error>) -> Void) {
        trackCall("fetchTask")
        lastFetchId = id
        
        if shouldSucceed {
            let task = storedTasks.first { $0.id == id }
            completion(.success(task))
        } else {
            completion(.failure(customError ?? NSError(domain: "Test", code: 404)))
        }
    }
    
    func updateTaskDescription(_ task: TodoTask, newDescription: String, completion: @escaping (Result<TodoTask, Error>) -> Void) {
        trackCall("updateTaskDescription")
        lastUpdateTask = task
        lastUpdateDescription = newDescription
        
        if shouldSucceed, let index = storedTasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = storedTasks[index]
            updatedTask.description = newDescription.isEmpty ? nil : newDescription
            storedTasks[index] = updatedTask
            completion(.success(updatedTask))
        } else {
            completion(.failure(customError ?? NSError(domain: "Test", code: 500)))
        }
    }
    
    // MARK: - Optional Methods (can be skipped for detailed-only mode)
    
    func fetchAllTasks() -> [TaskEntity] {
        trackCall("fetchAllTasks")
        
        if isDetailedOnly { return [] }
        
        return storedTasks.map { task in
            let entity = TaskEntity(context: context)
            entity.id = task.id
            entity.title = task.title
            entity.taskDescription = task.description
            entity.isCompleted = task.isCompleted
            entity.userId = Int64(task.userId)
            entity.createdAt = task.createdAt
            entity.remoteId = Int64(task.remoteId ?? 0)
            
            do {
                try context.save()
            } catch {
                print("Test save error: \(error)")
            }
            
            return entity
        }
    }
    
    func createTask(from task: TodoTask) -> Bool {
        trackCall("createTask")
        lastCreatedTask = task
        
        if isDetailedOnly { return false }
        
        if createTaskResult {
            storedTasks.insert(task, at: 0)
        }
        return createTaskResult
    }
    
    func updateTask(_ task: TodoTask) -> Bool {
        trackCall("updateTask")
        lastUpdatedTask = task
        
        if isDetailedOnly { return false }
        
        if updateTaskResult, let index = storedTasks.firstIndex(where: { $0.id == task.id }) {
            storedTasks[index] = task
        }
        return updateTaskResult
    }
    
    func deleteTask(_ task: TodoTask) -> Bool {
        trackCall("deleteTask")
        lastDeletedTask = task
        
        if isDetailedOnly { return false }
        
        if deleteTaskResult {
            storedTasks.removeAll { $0.id == task.id }
        }
        return deleteTaskResult
    }
    
    func syncTasksWithRemote(_ remoteTasks: [TodoTask]) -> (added: Int, updated: Int, unchanged: Int) {
        trackCall("syncTasksWithRemote")
        lastSyncTasks = remoteTasks
        
        if isDetailedOnly {
            onSyncCompleted?()
            return (0, 0, 0)
        }
        
        var added = 0
        var updated = 0
        
        for remoteTask in remoteTasks {
            if let index = storedTasks.firstIndex(where: { $0.id == remoteTask.id }) {
                storedTasks[index] = remoteTask
                updated += 1
            } else {
                storedTasks.append(remoteTask)
                added += 1
            }
        }
        
        onSyncCompleted?()
        return (added, updated, remoteTasks.count - added - updated)
    }
    
    func taskExists(title: String, description: String?) -> Bool {
        trackCall("taskExists")
        lastCheckTitle = title
        lastCheckDescription = description
        
        if isDetailedOnly { return taskExistsResult }
        
        let normalizedTitle = title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        let titleExists = storedTasks.contains { task in
            task.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalizedTitle
        }
        
        if titleExists { return true }
        
        if let description = description?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
           !description.isEmpty {
            return storedTasks.contains { task in
                task.description?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == description
            }
        }
        
        return taskExistsResult
    }
    
    // MARK: - Helper
    private func trackCall(_ method: String) {
        let count = callHistory[method] as? Int ?? 0
        callHistory[method] = count + 1
    }
}

