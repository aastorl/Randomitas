import UIKit

extension UIImage {
    func resized(toMaxDimension maxDimension: CGFloat) -> UIImage {
        let originalSize = self.size
        let aspectRatio = originalSize.width / originalSize.height
        
        var newSize: CGSize
        if originalSize.width > originalSize.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        // Don't scale up if the image is already smaller
        if originalSize.width <= maxDimension && originalSize.height <= maxDimension {
            return self
        }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
