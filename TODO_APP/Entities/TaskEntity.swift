//
//  TaskEntity+CoreDataProperties.swift
//  TODO_APP
//
//  Created by Marwa Awad on 01.12.2025.
//
//

import Foundation
import CoreData


@objc(TaskEntity)
public class TaskEntity: NSManagedObject {

}


extension TaskEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskEntity> {
        return NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var remoteId: Int64
    @NSManaged public var isCompleted: Bool
    @NSManaged public var taskDescription: String?
    @NSManaged public var userId: Int64

}

extension TaskEntity : Identifiable {

}

extension TaskEntity {
    func toTask() -> TodoTask? {
        guard let id = self.id,
              let title = self.title,
              let createdAt = self.createdAt else {
            return nil
        }
        
        return TodoTask(
            id: id,
            title: title,
            description: self.taskDescription,
            isCompleted: self.isCompleted,
            userId: Int(self.userId),
            createdAt: createdAt,
            remoteId: self.remoteId > 0 ? Int(self.remoteId) : nil
        )
    }
}
