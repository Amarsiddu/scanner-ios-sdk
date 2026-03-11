//
//  FileHasher.swift
//  ScannerPlugins
//
//  Created by Siddesh M on 02/03/26.
//
import Foundation
import CryptoKit

public struct FileHasher {
    
    public static func sha256(for fileURL: URL) throws -> String {
        
        let data = try Data(contentsOf: fileURL)
        let hash = SHA256.hash(data: data)
        
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
