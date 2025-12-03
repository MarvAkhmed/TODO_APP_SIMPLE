//
//  AlertManager.swift
//  TODO_APP
//
//  Created by Marwa Awad on 02.12.2025.
//

import Foundation
import UIKit

class AlertManager {
    
    enum AlertType {
        case add(onSave: (String, String?) -> Void)
        case edit(task: TodoTask, onSave: (String, String?) -> Void)
        case error(message: String)
    }
    
    static func createAlert(for type: AlertType) -> UIAlertController {
        switch type {
        case .add(let onSave):
            return createAddAlert(onSave: onSave)
        case .edit(let task, let onSave):
            return createEditAlert(for: task, onSave: onSave)
        case .error(let message):
            return createErrorAlert(message: message)
        }
    }
    
    private static func createAddAlert(onSave: @escaping (String, String?) -> Void) -> UIAlertController {
        createTaskAlert(
            title: "New Task",
            actionTitle: "Add",
            taskTitle: nil,
            taskDescription: nil,
            onSave: onSave
        )
    }
    
    private static func createEditAlert(for task: TodoTask, onSave: @escaping (String, String?) -> Void) -> UIAlertController {
        createTaskAlert(
            title: "Edit Task",
            actionTitle: "Save",
            taskTitle: task.title,
            taskDescription: task.description,
            onSave: onSave
        )
    }
    
    private static func createErrorAlert(message: String) -> UIAlertController {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "OK", style: .default)
        okAction.setValue(Colors.counterColor, forKey: "titleTextColor")
        alert.addAction(okAction)
        
        return alert
    }
    
    private static func createTaskAlert(
        title: String,
        actionTitle: String,
        taskTitle: String?,
        taskDescription: String?,
        onSave: @escaping (String, String?) -> Void
    ) -> UIAlertController {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.text = taskTitle
            textField.placeholder = "Task title"
            textField.autocapitalizationType = .sentences
            textField.tintColor = Colors.counterColor
            textField.accessibilityIdentifier = "titleTextField"
        }
        
        alert.addTextField { textField in
            textField.text = taskDescription
            textField.placeholder = "Description (optional)"
            textField.autocapitalizationType = .sentences
            textField.tintColor = Colors.counterColor
            textField.accessibilityIdentifier = "descriptionTextField"
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        cancelAction.setValue(UIColor.lightGray, forKey: "titleTextColor")
        alert.addAction(cancelAction)
        
        let saveAction = UIAlertAction(title: actionTitle, style: .default) { _ in
            guard let title = alert.textFields?.first?.text,
                  !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return
            }
            let description = alert.textFields?.last?.text
            onSave(title, description)
        }
        saveAction.setValue(Colors.counterColor
                            , forKey: "titleTextColor")
        alert.addAction(saveAction)
        
        return alert
    }
}
