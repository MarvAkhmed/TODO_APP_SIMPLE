//
//  Date.swift
//  TODO_APP
//
//  Created by Marwa Awad on 02.12.2025.
//

import Foundation

extension Date {
    var formattedTaskDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter.string(from: self)
    }
}
