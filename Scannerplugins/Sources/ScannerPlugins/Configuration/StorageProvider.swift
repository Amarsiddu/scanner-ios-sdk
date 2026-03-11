//
//  Untitled.swift
//  ScannerPlugins
//
//  Created by Siddesh M on 02/03/26.
//
import Foundation

public enum StorageProvider {
    
    case s3(
        bucket: String,
        region: String,
        presignedURLProvider: @Sendable (String) async throws -> URL
    )
}

