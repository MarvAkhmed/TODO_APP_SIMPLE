//
//  String.swift
//  TODO_APP
//
//  Created by Marwa Awad on 02.12.2025.
//

import Foundation

extension String {
    func trimmedAndLowercased() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
