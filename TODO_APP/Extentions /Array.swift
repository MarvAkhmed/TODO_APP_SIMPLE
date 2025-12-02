//
//  Array.swift
//  TODO_APP
//
//  Created by Marwa Awad on 01.12.2025.
//

import Foundation

extension Array where Element == URLQueryItem {
    mutating func appendIfNotNil(_ name: String, value: Int?) {
        if let value = value {
            self.append(URLQueryItem(name: name, value: "\(value)"))
        }
    }
}
