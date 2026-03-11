//
//  UploadProgressDelegate.swift
//  ScannerPlugins
//
//  Created by Siddesh M on 02/03/26.
//
import Foundation

public protocol UploadProgressDelegate: AnyObject {
    
    func uploadDidUpdateProgress(fileURL: URL, progress: Double)
    
    func uploadDidComplete(fileURL: URL, remoteURL: URL)
    
    func uploadDidFail(fileURL: URL, error: Error)
}

