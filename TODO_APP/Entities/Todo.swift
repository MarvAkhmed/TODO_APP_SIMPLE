//
//  Todo.swift
//  TODO_APP
//
//  Created by Marwa Awad on 01.12.2025.
//

//MARK: - Networking model

import Foundation

struct TodosResponse: Decodable {
    let todos: [Todo]
    let total: Int
    let skip: Int
    let limit: Int
    
    var completedCount: Int {
        todos.filter { $0.completed }.count
    }
}

struct Todo: Decodable {
    let id: Int
    let todo: String
    let completed: Bool
    let userId: Int
    
    var task: TodoTask {
        TodoTask(
            id: UUID(),
            title: self.todo,
            description: nil,
            isCompleted: self.completed,
            userId: self.userId,
            createdAt: Date(),
            remoteId: self.id
        )
    }
}
