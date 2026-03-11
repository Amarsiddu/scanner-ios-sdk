import SwiftUI
import UniformTypeIdentifiers
import ScannerPlugins
import UIKit
import VisionKit

struct StoredPhoto: Identifiable {
    let id = UUID()
    let url: URL
}

struct ContentView: View {
    
    @EnvironmentObject var auth: AuthManager
    
    @State private var isUploading = false
    @State private var message = ""
    @State private var txHash = ""
    
    @State private var documentDelegate: DocumentPickerDelegate?
    
    // Scanner
    @State private var showScanner = false
    @State private var scannedImages: [UIImage] = []
    
    // Camera
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    
    @State private var storedPhotos: [StoredPhoto] = []
    
    var body: some View {
        
        ZStack {
            
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                
                // Logout
                HStack {
                    Spacer()
                    
                    Button("Logout") {
                        auth.logout()
                    }
                    .font(.footnote)
                }
                
                // Header
                VStack(spacing: 8) {
                    
                    Image(systemName: "cube.transparent.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Scan Upload")
                        .font(.title2)
                        .bold()
                    
                    Text("Scan and Upload file with Blockchain proof")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                // Upload Card
                VStack(spacing: 15) {
                    
                    if isUploading {
                        
                        ProgressView("Uploading...")
                        
                    } else {
                        
                        Button(action: pickFile) {
                            
                            HStack {
                                Image(systemName: "arrow.up.doc.fill")
                                Text("Select .ply File").bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        Button {
                            showScanner = true
                        } label: {
                            
                            HStack {
                                Image(systemName: "doc.text.viewfinder")
                                Text("Scan Document").bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        Button {
                            showCamera = true
                        } label: {
                            
                            HStack {
                                Image(systemName: "camera")
                                Text("Take Photo").bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                
                
                // Stored Files
                if !storedPhotos.isEmpty {
                    
                    ScrollView {
                        
                        VStack(alignment: .leading, spacing: 10) {
                            
                            Text("Stored Scans")
                                .font(.headline)
                            
                            ForEach(storedPhotos) { photo in
                                
                                HStack {
                                    
                                    if photo.url.pathExtension == "ply" {
                                        
                                        Image(systemName: "cube.fill")
                                            .foregroundColor(.blue)
                                            .font(.title2)
                                        
                                    } else if let img = UIImage(contentsOfFile: photo.url.path) {
                                        
                                        Image(uiImage: img)
                                            .resizable()
                                            .frame(width: 60, height: 60)
                                            .cornerRadius(8)
                                    }
                                    
                                    Text(photo.url.lastPathComponent)
                                        .font(.footnote)
                                    
                                    Spacer()
                                    
                                    Button {
                                        deletePhoto(photo)
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Success / Error
                if !message.isEmpty {
                    
                    VStack(alignment: .leading) {
                        
                        Text(message)
                        
                        if !txHash.isEmpty {
                            
                            if let url = URL(string: "https://amoy.polygonscan.com/tx/\(txHash)") {
                                
                                Link("View Transaction", destination: url)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
        }
        
        .sheet(isPresented: $showCamera) {
            CameraView(image: $capturedImage)
        }
        
        .sheet(isPresented: $showScanner) {
            ImageScanner(scannedImages: $scannedImages)
        }
        
        .onChange(of: capturedImage) { _, newImage in
            
            guard let image = newImage else { return }
            
            do {
                
                let fileURL = try savePhoto(image)
                
                storedPhotos.append(StoredPhoto(url: fileURL))
                
                uploadFile(fileURL)
                
            } catch {
                
                message = "Save failed ❌"
            }
        }
        
        .onAppear {
            configurePlugin()
        }
    }
    
    // MARK: Save Photo
    
    func savePhoto(_ image: UIImage) throws -> URL {
        
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw NSError(domain: "ImageError", code: 0)
        }
        
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let username = auth.username
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateFolder = dateFormatter.string(from: Date())
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH-mm-ss"
        let timeStamp = timeFormatter.string(from: Date())
        
        let folder = documents
            .appendingPathComponent(username)
            .appendingPathComponent(dateFolder)
        
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        
        let fileURL = folder.appendingPathComponent("scan_\(timeStamp).jpg")
        
        try data.write(to: fileURL)
        
        return fileURL
    }
    
    // MARK: Save PLY
    
    func savePLYFile(_ sourceURL: URL) throws -> URL {
        
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let username = auth.username
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateFolder = dateFormatter.string(from: Date())
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH-mm-ss"
        let timeStamp = timeFormatter.string(from: Date())
        
        let folder = documents
            .appendingPathComponent(username)
            .appendingPathComponent(dateFolder)
        
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        
        let newURL = folder.appendingPathComponent("scan_\(timeStamp).ply")
        
        try fileManager.copyItem(at: sourceURL, to: newURL)
        
        return newURL
    }
    
    // MARK: Delete
    
    func deletePhoto(_ photo: StoredPhoto) {
        
        do {
            try FileManager.default.removeItem(at: photo.url)
            storedPhotos.removeAll { $0.id == photo.id }
        } catch {
            print("Delete failed")
        }
    }
    
    // MARK: Configure S3
    
    private func configurePlugin() {
        
        Task {
            await ScannerPlugins.shared.configure(
                provider: .s3(
                    bucket: "scan-s3-demo-bucket",
                    region: "eu-north-1"
                ) { fileName in
                    
                    try await fetchPresignedURL(for: fileName)
                }
            )
        }
    }
    
    // MARK: File Picker
    
    private func pickFile() {
        
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [UTType(filenameExtension: "ply") ?? .data],
            asCopy: true
        )
        
        picker.allowsMultipleSelection = false
        
        let delegate = DocumentPickerDelegate { url in
            
            do {
                
                let savedURL = try savePLYFile(url)
                
                storedPhotos.append(StoredPhoto(url: savedURL))
                
                uploadFile(savedURL)
                
            } catch {
                
                message = "PLY save failed ❌"
            }
        }
        
        picker.delegate = delegate
        self.documentDelegate = delegate
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            
            rootVC.present(picker, animated: true)
        }
    }
    
    // MARK: Upload
    
    private func uploadFile(_ url: URL) {
        
        isUploading = true
        message = ""
        txHash = ""
        
        Task {
            
            do {
                
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(url.lastPathComponent)
                
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }
                
                try FileManager.default.copyItem(at: url, to: tempURL)
                
                _ = try await ScannerPlugins.shared.uploadScan(fileURL: tempURL)
                
                let returnedTxHash = try await notifyBackendUploadComplete(fileURL: tempURL)
                
                await MainActor.run {
                    
                    isUploading = false
                    txHash = returnedTxHash
                    message = "Uploaded Successfully ✅"
                }
                
            } catch {
                
                await MainActor.run {
                    isUploading = false
                    message = "Upload Failed ❌"
                }
            }
        }
    }
    
    // MARK: Presign
    
    private func fetchPresignedURL(for fileName: String) async throws -> URL {
        
        guard let url = URL(string: "https://scanner-backend-k4ag.onrender.com/presign") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: ["fileName": fileName])
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let decoded = try JSONDecoder().decode(PresignResponse.self, from: data)
        
        return URL(string: decoded.url)!
    }
    
    struct PresignResponse: Decodable {
        let url: String
    }
    
    // MARK: Blockchain
    
    private func notifyBackendUploadComplete(fileURL: URL) async throws -> String {
        
        let fileData = try Data(contentsOf: fileURL)
        let base64 = fileData.base64EncodedString()
        
        guard let url = URL(string: "https://scanner-backend-k4ag.onrender.com/upload-complete") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "s3Url": "scan-s3-demo-bucket/\(fileURL.lastPathComponent)",
            "fileBufferBase64": base64
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let decoded = try JSONDecoder().decode(UploadResponse.self, from: data)
        
        return decoded.txHash
    }
    
    struct UploadResponse: Decodable {
        let success: Bool
        let txHash: String
    }
}
