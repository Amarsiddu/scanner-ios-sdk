//
//  DocumentPickerDelegate.swift
//  ScannerPluginsDemo
//
//  Created by Siddesh M on 02/03/26.
//
import UIKit

class DocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
    
    let onPick: (URL) -> Void
    
    init(onPick: @escaping (URL) -> Void) {
        self.onPick = onPick
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController,
                        didPickDocumentsAt urls: [URL]) {
        
        print("📂 Picked URLs:", urls)
        
        guard let url = urls.first else { return }
        onPick(url)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("❌ Picker cancelled")
    }
}
