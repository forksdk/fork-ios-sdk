//
//  ForkWebservice.swift
//  
//
//  Created by Aleksandras Gaidamauskas on 16/04/2024.
//

import Foundation


//load { [weak self] result in
//    do {
//        let user = try result.decoded() as ForkData
//        self?.userDidLoad(user)
//    } catch {
//        self?.handle(error)
//    }
//}

//extension Result where Success == Data {
//    func decoded<T: Decodable>(
//        using decoder: JSONDecoder = .init()
//    ) throws -> T {
//        let data = try get()
//        return try decoder.decode(T.self, from: data)
//    }
//}

class ForkWebservice {
    
    static func fetch<T: Codable>(url: String, parse: @escaping (Data) -> T?, completion: @escaping (Result<T?, ForkError>) -> Void) {
        
        guard let url = URL(string: url) else {
            completion(.failure(.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil,
                  (response as? HTTPURLResponse)?.statusCode == 200
            else {
                completion(.failure(.decodingError))
                return
            }
            let result = parse(data)
            completion(.success(result))
        }.resume()
    }
    
    static func post<T: Codable>(url: String, object: T, completion: @escaping (Result<Bool, ForkError>) -> Void) {
    
        guard let url = URL(string: url) else {
            completion(.failure(.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        do {
//            let jsonData = try JSONEncoder().encode(object)
//            let jsonString = String(data: jsonData, encoding: .utf8)!
            let encoder = JSONEncoder()
            let data = try encoder.encode(object)
            request.httpBody = data
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let _ = data, error == nil,
                      (response as? HTTPURLResponse)?.statusCode == 200
                else {
                    completion(.failure(.badRequest))
                    return
                }
                completion(.success(true))
            }.resume()
        } catch {
            completion(.failure(.encodingError))
            return
        }
    }
    
    static func post(url: String, data: Data, completion: @escaping (Result<Bool, ForkError>) -> Void) {
        
        guard let url = URL(string: url) else {
            completion(.failure(.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        request.httpBody = data
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let _ = data, error == nil,
                  (response as? HTTPURLResponse)?.statusCode == 200
            else {
                completion(.failure(.badRequest))
                return
            }
            completion(.success(true))
        }.resume()
    }
}
