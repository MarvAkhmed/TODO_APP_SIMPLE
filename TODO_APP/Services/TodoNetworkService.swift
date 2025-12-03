//
//  TodoService.swift
//  TODO_APP
//
//  Created by Marwa Awad on 01.12.2025.
//

import Foundation

protocol TodoServiceProtocol {
    func fetchAllTodos() async throws -> [Todo]
    func fetchTotalCount() async throws -> Int
}

final class TodoNetworkService: TodoServiceProtocol {
    let baseURL = "https://dummyjson.com"
    
    func fetchAllTodos() async throws -> [Todo] {
        var allTodos: [Todo] = []
        let batchSize = 100
        var skip = 0
        var hasMore = true
        
        while hasMore {
            let response = try await fetchTodos(limit: batchSize, skip: skip)
            allTodos.append(contentsOf: response.todos)
            if response.todos.count < batchSize {
                hasMore = false
            } else {
                skip += batchSize
            }
        }
        return allTodos
    }
    
    func fetchTotalCount() async throws -> Int {
        let response = try await fetchTodos(limit: 1, skip: 0)
        return response.total
    }
}

private extension TodoNetworkService {
    
    enum TodoServiceError: Error {
        case invalidURL
        case invalidResponse
        case paginationFailed
    }

    func fetchTodos(limit: Int? = nil, skip: Int? = nil) async throws -> TodosResponse {
        var components = URLComponents(string: "\(baseURL)/todos")
        
        var queryItems: [URLQueryItem] = []
        queryItems.appendIfNotNil("limit", value: limit)
        queryItems.appendIfNotNil("skip", value: skip)
        
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        
        guard let url = components?.url else {
            throw TodoServiceError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.isSuccessful else {
            throw TodoServiceError.invalidResponse
        }
        return try JSONDecoder().decode(TodosResponse.self, from: data)
    }
}
