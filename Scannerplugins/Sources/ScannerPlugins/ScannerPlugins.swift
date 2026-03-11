import Foundation

public actor ScannerPlugins {
    
    public static let shared = ScannerPlugins()
    
    private var uploadService: S3UploadService?
    private var blockchainService: BlockchainService?
    
    public init() {}
    
    // MARK: Configure Storage
    
    public func configure(provider: StorageProvider) {
        uploadService = S3UploadService(provider: provider)
    }
    
    // MARK: Configure Blockchain
    
    public func configureBlockchain(endpoint: URL) {
        blockchainService = DefaultBlockchainService(endpoint: endpoint)
    }
    
    // MARK: Upload Delegate
    
    public func setDelegate(_ delegate: UploadProgressDelegate) {
        uploadService?.delegate = delegate
    }
    
    // MARK: Upload Scan
    
    public func uploadScan(fileURL: URL) async throws -> URL {
        
        guard let uploadService else {
            throw ScannerPluginsError.notConfigured
        }
        
        let ext = fileURL.pathExtension.lowercased()
        
        // Skip compression for 3D files
        let processedURL: URL
        
        if ext == "ply" {
            processedURL = fileURL
        } else {
            processedURL = try await CompressionService.compressIfNeeded(fileURL)
        }
        
        let size = try FileManager.default
            .attributesOfItem(atPath: processedURL.path)[.size] as? Int64 ?? 0
        
        guard size > 10000 else {
            print("⚠️ Skipping tiny file:", processedURL.lastPathComponent)
            throw ScannerPluginsError.invalidFile
        }
        
        return try await uploadService.upload(fileURL: processedURL)
    }
    
    // MARK: Upload + Blockchain
    
    public func uploadAndRegisterScan(fileURL: URL) async throws -> (URL, String) {
        
        guard let uploadService else {
            throw ScannerPluginsError.notConfigured
        }
        
        guard let blockchainService else {
            throw ScannerPluginsError.blockchainNotConfigured
        }
        
        let ext = fileURL.pathExtension.lowercased()
        
        let processedURL: URL
        
        if ext == "ply" {
            processedURL = fileURL
        } else {
            processedURL = try await CompressionService.compressIfNeeded(fileURL)
        }
        
        let size = try FileManager.default
            .attributesOfItem(atPath: processedURL.path)[.size] as? Int64 ?? 0
        
        guard size > 10000 else {
            throw ScannerPluginsError.invalidFile
        }
        
        let remoteURL = try await uploadService.upload(fileURL: processedURL)
        
        let hash = try FileHasher.sha256(for: processedURL)
        
        let receipt = try await blockchainService.register(hash: hash)
        
        return (remoteURL, receipt.transactionHash)
    }
}
