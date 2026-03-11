import SwiftUI
import VisionKit

struct ImageScanner: UIViewControllerRepresentable {
    
    @Binding var scannedImages: [UIImage]
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        
        let parent: ImageScanner
        
        init(_ parent: ImageScanner) {
            self.parent = parent
        }
        
        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            
            for page in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: page)
                parent.scannedImages.append(image)
            }
            
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }
    }
}
