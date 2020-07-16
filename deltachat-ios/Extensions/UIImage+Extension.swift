import UIKit
import DcCore

extension UIImage {

    func invert() -> UIImage {
        let beginImage = CIImage(image: self)
        if let filter = CIFilter(name: "CIColorInvert") {
            filter.setValue(beginImage, forKey: kCIInputImageKey)
            return UIImage(ciImage: filter.outputImage!)
        }
        return self
    }

     func maskWithColor(color: UIColor) -> UIImage? {
         let maskImage = cgImage!

         let width = size.width
         let height = size.height
         let bounds = CGRect(x: 0, y: 0, width: width, height: height)

         let colorSpace = CGColorSpaceCreateDeviceRGB()
         let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
         let context = CGContext(
            data: nil,
            width: Int(width),
            height: Int(height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )!

         context.clip(to: bounds, mask: maskImage)
         context.setFillColor(color.cgColor)
         context.fill(bounds)

         if let cgImage = context.makeImage() {
             let coloredImage = UIImage(cgImage: cgImage)
             return coloredImage
         } else {
             return nil
         }
     }

    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}

public enum ImageType: String {
    case play
    case pause
    case disclouser
}
