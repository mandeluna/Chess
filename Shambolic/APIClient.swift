//
//  APIClient.swift
//  Shaman
//
//  Created by Steve Wart on 2025-09-24.
//

import Foundation

class APIClient {
    private let session: URLSession
    private let baseURL = "https://lichess.org"
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func post<T: Decodable>(_ endpoint: String, body: [String: Any]) async throws -> T {
        let url = URL(string: baseURL + endpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert body to JSON
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    func get<T: Decodable>(_ endpoint: String, queryParams: [String: String] = [:]) async throws -> T {
        var components = URLComponents(string: baseURL + endpoint)!
        
        if !queryParams.isEmpty {
            components.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        let request = URLRequest(url: components.url!)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}

enum APIError: Error {
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
    case networkError(Error)
}
