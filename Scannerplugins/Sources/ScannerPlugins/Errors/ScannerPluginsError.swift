import Foundation

public enum ScannerPluginsError: LocalizedError {
    
    case notConfigured
    case blockchainNotConfigured
    case invalidFile   // ← ADD THIS
    
    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Upload service not configured."
            
        case .blockchainNotConfigured:
            return "Blockchain service not configured."
            
        case .invalidFile:   // ← ADD THIS
            return "Invalid or corrupted file."
        }
    }
}
