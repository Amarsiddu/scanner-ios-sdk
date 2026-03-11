import Foundation

final class S3UploadService {
    
    private let provider: StorageProvider
    private let retryPolicy = RetryPolicy()
    
    weak var delegate: UploadProgressDelegate?
    
    init(provider: StorageProvider) {
        self.provider = provider
    }
    
    func upload(fileURL: URL) async throws -> URL {
        
        // Ensure file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw URLError(.fileDoesNotExist)
        }
        
        // Get file size
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        // Prevent tiny temp files
        guard fileSize > 10000 else {
            print("⚠️ Skipping tiny file:", fileURL.lastPathComponent, "size:", fileSize)
            throw NSError(domain: "ScannerPlugins", code: 1001)
        }
        
        print("📦 Uploading file:", fileURL.lastPathComponent)
        print("📦 File size:", fileSize, "bytes")
        
        switch provider {
            
        case .s3(_, _, let presignedURLProvider):
            
            let uploadURL = try await presignedURLProvider(fileURL.lastPathComponent)
            
            return try await retryPolicy.execute {
                try await self.performUpload(
                    to: uploadURL,
                    fileURL: fileURL
                )
            }
        }
    }
    
    
    private func performUpload(
        to url: URL,
        fileURL: URL
    ) async throws -> URL {
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        // Detect content type
        let ext = fileURL.pathExtension.lowercased()
        
        switch ext {
        case "ply":
            request.setValue("model/ply", forHTTPHeaderField: "Content-Type")
            
        case "jpg", "jpeg":
            request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
            
        case "png":
            request.setValue("image/png", forHTTPHeaderField: "Content-Type")
            
        default:
            request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        }
        
        let (data, response) = try await URLSession.shared.upload(
            for: request,
            fromFile: fileURL
        )
        
        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 else {
            
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ S3 Upload Error:", errorString)
            throw URLError(.badServerResponse)
        }
        
        print("✅ Upload Completed:", fileURL.lastPathComponent)
        
        // Remove query params from presigned URL
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.query = nil
        
        return components?.url ?? url
    }
}
