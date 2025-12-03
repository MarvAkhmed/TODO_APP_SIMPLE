//
//  CoreDataService.swift
//  TODO_APP
//
//  Created by Marwa Awad on 01.12.2025.
//

import Foundation
import CoreData

protocol CoreDataServiceProtocol {
    func fetchAllTasks() -> [TaskEntity]
    func createTask(from task: TodoTask) -> Bool
    func updateTask(_ task: TodoTask) -> Bool
    func deleteTask(_ task: TodoTask) -> Bool
    
    func syncTasksWithRemote(_ remoteTasks: [TodoTask]) -> (added: Int, updated: Int, unchanged: Int)
    func taskExists(title: String, description: String?) -> Bool
    
    /// for detailed task
    func fetchTask(by id: UUID, completion: @escaping (Result<TodoTask?, Error>) -> Void)
    func updateTaskDescription(_ task: TodoTask, newDescription: String, completion: @escaping (Result<TodoTask, Error>) -> Void)
}

final class CoreDataService: CoreDataServiceProtocol {
    
    // MARK: - Singleton
    static let shared = CoreDataService()
    
    // MARK: - Properties
    private let persistentContainer: NSPersistentContainer
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // MARK: - Initialization
    init() {
        self.persistentContainer = NSPersistentContainer(name: "TODO_APP")
        
        // Load persistent stores
        self.persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data: \(error)")
            }
        }
    }
    
    // MARK: - Context Management
    func saveContext() {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
            context.rollback()
        }
    }
    
    // MARK: - CRUD
    func fetchAllTasks() -> [TaskEntity] {
        let fetchRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "createdAt", ascending: false)  ]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print(" Failed to fetch tasks: \(error)")
            return []
        }
    }
    
    func createTask(from task: TodoTask) -> Bool {
        if isDuplicateTask(task) { return false}
        
        let taskEntity = TaskEntity(context: context)
        configure(taskEntity, with: task)
        
        return saveEntity(taskEntity)
    }
    
    func updateTask(_ task: TodoTask) -> Bool {
        guard let entity = fetchTaskEntity(by: task.id) else {  return false }
        guard hasChanges(entity, comparedTo: task) else { return false }
        configure(entity, with: task)
        return saveEntity(entity)
    }
    
    func deleteTask(_ task: TodoTask) -> Bool {
        guard let entity = fetchTaskEntity(by: task.id) else { return false}
        context.delete(entity)
        return saveEntity(entity)
    }
    
    // MARK: - Sync with remote id
    func syncTasksWithRemote(_ remoteTasks: [TodoTask]) -> (added: Int, updated: Int, unchanged: Int) {
        
        var added = 0, updated = 0, unchanged = 0
        let localTasks = fetchAllTasks()
        
        // Create lookup dictionaries
        let localByRemoteId = Dictionary(grouping: localTasks.filter { $0.remoteId > 0 }) { $0.remoteId }
        let localById = Dictionary(uniqueKeysWithValues: localTasks.compactMap { entity in
            entity.id.map { ($0, entity) }
        })
        
        // Process remote tasks
        remoteTasks.forEach { remoteTask in
            let changeType = processRemoteTask(remoteTask,
                                               localByRemoteId: localByRemoteId,
                                               localById: localById)
            switch changeType {
            case .added: added += 1
            case .updated: updated += 1
            case .unchanged: unchanged += 1
            }
        }
        
        saveContext()
        
        return (added, updated, unchanged)
    }
    
    // MARK: - for detailed task
    func fetchTask(by id: UUID, completion: @escaping (Result<TodoTask?, Error>) -> Void) {
        let fetchRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let entity = try context.fetch(fetchRequest).first
            let todoTask = entity?.toTask()
            completion(.success(todoTask))
        } catch {
            completion(.failure(error))
        }
    }
    
    func updateTaskDescription(_ task: TodoTask, newDescription: String, completion: @escaping (Result<TodoTask, Error>) -> Void) {
        guard let entity = fetchTaskEntity(by: task.id) else {
            completion(.failure(NSError(domain: "CoreDataError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Task not found"])))
            return
        }
        entity.taskDescription = newDescription.isEmpty ? nil : newDescription
        
        do {
            try context.save()
            if let updatedTask = entity.toTask() {
                completion(.success(updatedTask))
            } else {
                completion(.failure(NSError(domain: "CoreDataError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to convert updated task"])))
            }
        } catch {
            context.rollback()
            completion(.failure(error))
        }
    }
    
    // MARK: - Duplicate Check
    func taskExists(title: String, description: String?) -> Bool {
        let normalizedTitle = title.trimmedAndLowercased()
        
        let fetchRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "title CONTAINS[cd] %@",
            normalizedTitle
        )
        
        do {
            let results = try context.fetch(fetchRequest)
            
            let hasExactTitleMatch = results.contains { entity in
                entity.title?.trimmedAndLowercased() == normalizedTitle
            }
            
            if hasExactTitleMatch { return true }
            
            if let description = description?.trimmedAndLowercased(),
               !description.isEmpty {
                return results.contains { entity in
                    entity.taskDescription?.trimmedAndLowercased() == description
                }
            }
            
            return false
        } catch {
            print(" Failed to check for duplicate task: \(error)")
            return false
        }
    }
}

// MARK: - Private Helper Methods
private extension CoreDataService {
    
    func saveEntity(_ entity: TaskEntity) -> Bool {
        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            return false
        }
    }
    
    func fetchTaskEntity(by id: UUID) -> TaskEntity? {
        let fetchRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            print("Failed to fetch task by ID: \(error)")
            return nil
        }
    }
    
    func fetchTaskEntity(by remoteId: Int64) -> TaskEntity? {
        let fetchRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "remoteId == %d", remoteId)
        fetchRequest.fetchLimit = 1
        
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            print(" Failed to fetch task by remoteId: \(error)")
            return nil
        }
    }
    
    func configure(_ entity: TaskEntity, with task: TodoTask) {
        entity.id = task.id
        entity.title = task.title.trimmingCharacters(in: .whitespacesAndNewlines)
        entity.taskDescription = task.description?.trimmingCharacters(in: .whitespacesAndNewlines)
        entity.isCompleted = task.isCompleted
        entity.userId = Int64(task.userId)
        entity.createdAt = task.createdAt
        entity.remoteId = Int64(task.remoteId ?? 0)
    }
    
    func isDuplicateTask(_ task: TodoTask) -> Bool {
        if let remoteId = task.remoteId,
           fetchTaskEntity(by: Int64(remoteId)) != nil {
            return true
        }
        return taskExists(title: task.title, description: task.description)
    }
    
    func hasChanges(_ entity: TaskEntity, comparedTo task: TodoTask) -> Bool {
        return entity.title != task.title ||
        entity.taskDescription != task.description ||
        entity.isCompleted != task.isCompleted ||
        entity.userId != Int64(task.userId) ||
        entity.remoteId != Int64(task.remoteId ?? 0)
    }
    
    enum ChangeType { case added, updated, unchanged }
    func processRemoteTask(_ remoteTask: TodoTask,
                           localByRemoteId: [Int64: [TaskEntity]],
                           localById: [UUID: TaskEntity]) -> ChangeType {
        // Try to find by remoteId first
        if let remoteId = remoteTask.remoteId {
            let remoteId64 = Int64(remoteId)
            
            if let existingTasks = localByRemoteId[remoteId64],
               let existingTask = existingTasks.first {
                
                if hasChanges(existingTask, comparedTo: remoteTask) {
                    configure(existingTask, with: remoteTask)
                    return .updated
                }
                return .unchanged
            }
        }
        
        // If no remoteId match, check by local id
        if let existingTask = localById[remoteTask.id] {
            existingTask.remoteId = Int64(remoteTask.remoteId ?? 0)
            if hasChanges(existingTask, comparedTo: remoteTask) {
                configure(existingTask, with: remoteTask)
                return .updated
            }
            return .unchanged
        }
        
        // new task
        let newTask = TaskEntity(context: context)
        configure(newTask, with: remoteTask)
        return .added
    }
}


