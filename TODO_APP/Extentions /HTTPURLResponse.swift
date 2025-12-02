//
//  HTTPURLResponse.swift
//  TODO_APP
//
//  Created by Marwa Awad on 01.12.2025.
//

import Foundation

extension HTTPURLResponse {
    var isSuccessful: Bool {
        (200...299).contains(statusCode)
    }
}
