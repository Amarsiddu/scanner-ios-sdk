//
//  BlockchainService.swift
//  ScannerPlugins
//
//  Created by Siddesh M on 02/03/26.
//
import Foundation

// MARK: - Receipt Model

public struct BlockchainReceipt: Decodable {
    public let transactionHash: String
}

// MARK: - Protocol

public protocol BlockchainService: Sendable {
    func register(hash: String) async throws -> BlockchainReceipt
}

// MARK: - Default Implementation

public final class DefaultBlockchainService: BlockchainService {
    
    private let endpoint: URL
    
    public init(endpoint: URL) {
        self.endpoint = endpoint
    }
    
    public func register(hash: String) async throws -> BlockchainReceipt {
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["hash": hash]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(BlockchainReceipt.self, from: data)
    }
}
