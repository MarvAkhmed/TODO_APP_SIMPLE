//
//  Task.swift
//  TODO_APP
//
//  Created by Marwa Awad on 01.12.2025.
//

//MARK: - Local model

import Foundation

struct TodoTask {
    let id: UUID
    var title: String
    var description: String?
    var isCompleted: Bool
    let userId: Int
    var createdAt: Date
    let remoteId: Int?
    
    init(id: UUID = UUID(),
         title: String,
         description: String? = nil,
         isCompleted: Bool = false,
         userId: Int = 1,
         createdAt: Date = Date(),
         remoteId: Int? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.userId = userId
        self.createdAt = createdAt
        self.remoteId = remoteId
    }
}
