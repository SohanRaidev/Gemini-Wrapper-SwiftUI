import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var selectedImage: UIImage?
    @Binding var filename: String?

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current // Use current to get the highest quality
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false

            guard let result = results.first else { return }
            
            // Try to load the original filename first
            let assetID = result.assetIdentifier
            var filename: String?
            
            if let assetID = assetID {
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
                if let asset = assets.firstObject {
                    // Get filename from asset resources
                    let resources = PHAssetResource.assetResources(for: asset)
                    if let resource = resources.first {
                        filename = resource.originalFilename
                        print("Filename from asset: \(String(describing: filename))")
                    }
                }
            }
            
            // Now load the image data - requesting both image and livePhoto data types
            let itemProvider = result.itemProvider
            
            // First try to load UIImage directly - this works for most formats
            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                    if let error = error {
                        print("Error loading image: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let image = object as? UIImage else {
                        print("Error: Failed to cast object to UIImage")
                        return
                    }
                    
                    // Set the image on the main thread
                    DispatchQueue.main.async {
                        self?.parent.selectedImage = image
                        self?.parent.filename = filename ?? self?.generateDefaultFilename()
                    }
                }
                return
            }
            
            // If we can't load as UIImage, try loading as data
            let dataTypes = [
                UTType.jpeg.identifier,
                UTType.png.identifier,
                UTType.heic.identifier,
                "public.heif", // Extra HEIC/HEIF identifier
                UTType.image.identifier // Generic image type as fallback
            ]
            
            // Try each data type
            for dataType in dataTypes {
                if itemProvider.hasItemConformingToTypeIdentifier(dataType) {
                    itemProvider.loadDataRepresentation(forTypeIdentifier: dataType) { [weak self] data, error in
                        guard let data = data, error == nil else {
                            print("Error loading data for type \(dataType): \(String(describing: error))")
                            return
                        }
                        
                        // Convert to UIImage
                        if let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                self?.parent.selectedImage = image
                                self?.parent.filename = filename ?? self?.generateDefaultFilename()
                            }
                        } else {
                            print("Error: Could not create UIImage from data for type \(dataType)")
                        }
                    }
                    return
                }
            }
            
            print("Error: No supported image type found in item provider")
        }
        
        private func generateDefaultFilename() -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            return "Image_\(dateFormatter.string(from: Date())).jpg"
        }
    }
}
