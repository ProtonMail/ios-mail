//
//  DKPhotoImageUtility.swift
//  DKPhotoGallery
//
//  Created by ZhangAo on 2018/6/6.
//  Copyright © 2018 ZhangAo. All rights reserved.
//

import Foundation

extension UIImage {
    
    private struct Constant {
        static let bytesPerPixel: CGFloat = 4
        static let bytesPerMB: CGFloat = 1024 * 1024
        static let pixelsPerMB = bytesPerMB / bytesPerPixel
        
        ///  These constants are suggested initial values for iPad1, and iPhone 3GS
        static let destImageSizeMB: CGFloat = 60 // The resulting image will be (x)MB of uncompressed image data.
        static let sourceImageTileSizeMB: CGFloat = 20 // The tile size will be (x)MB of uncompressed image data.
        
        static let destTotalPixels = destImageSizeMB * pixelsPerMB
        static let tileTotalPixels = sourceImageTileSizeMB * pixelsPerMB
        static let destSeemOverlap: CGFloat = 2 // the numbers of pixels to overlap the seems where tiles meet.
    }

    func decompress() -> UIImage {
        guard let imageRef = self.cgImage else { return self }
        
        let resolution = self.resolution()
        
        if resolution.width == 0 || resolution.height == 0 { return self }
        
        let sourceTotalPixels = resolution.width * resolution.height
        let sourceTotalMB = CGFloat(sourceTotalPixels) / Constant.pixelsPerMB
        
        if sourceTotalMB > Constant.destImageSizeMB {
            return self.downsizing()
        } else {
            UIGraphicsBeginImageContextWithOptions(resolution, false, self.scale)
            
            guard let context = UIGraphicsGetCurrentContext() else { return self }
            
            defer {
                UIGraphicsEndImageContext()
            }
            
            context.scaleBy(x: 1, y: -1)
            context.translateBy(x: 0, y: CGFloat(-resolution.height))
            context.draw(imageRef, in: CGRect(x: 0, y: 0, width: resolution.width, height: resolution.height))
            
            guard let decompressedImageRef = context.makeImage() else { return self }
            
            return UIImage(cgImage: decompressedImageRef, scale: self.scale, orientation: self.imageOrientation)
        }
    }
    
    private func resolution() -> CGSize {
//        // Odd behavior. Occasionally get an incorrect(very small) value.
//        let width = imageRef.width
//        let height = imageRef.height
        return CGSize(width: self.size.width * self.scale, height: self.size.height * self.scale)
    }

    /// Supported formats are: PNG, TIFF, JPEG. Unsupported formats: GIF, BMP, interlaced images.
    /// See Apple's Large Image Downsizing Sample Code ( https://developer.apple.com/library/archive/samplecode/LargeImageDownsizing/ )
    private func downsizing() -> UIImage {        
        return autoreleasepool { () -> UIImage in
            guard let sourceImageRef = self.cgImage
                else { return self }
            
            // get the width and height of the input image using
            // core graphics image helper functions.
            let sourceResolution = self.resolution()
            
            // use the width and height to calculate the total number of pixels
            // in the input image.
            let sourceTotalPixels = sourceResolution.width * sourceResolution.height
                        
            // determine the scale ratio to apply to the input image
            // that results in an output image of the defined size.
            // see kDestImageSizeMB, and how it relates to destTotalPixels.
            let imageScale = Constant.destTotalPixels / sourceTotalPixels
            
            // use the image scale to calcualte the output image width, height
            let destResolution = CGSize(width: Int(sourceResolution.width * imageScale), height: Int(sourceResolution.height * imageScale))
            
            let bytesPerRow = Constant.bytesPerPixel * destResolution.width
            
            // create an offscreen bitmap context that will hold the output image
            // pixel data, as it becomes available by the downscaling routine.
            // allocate enough pixel data to hold the output image.
            let destBitmapData = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(bytesPerRow * destResolution.height))
            defer { destBitmapData.deallocate() }
            
            // create the output bitmap context
            guard let destContext = CGContext(data: destBitmapData,
                                              width: Int(destResolution.width),
                                              height: Int(destResolution.height),
                                              bitsPerComponent: 8,
                                              bytesPerRow: Int(bytesPerRow),
                                              space: CGColorSpaceCreateDeviceRGB(),
                                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
                else { return self }
            
            // flip the output graphics context so that it aligns with the
            // cocoa style orientation of the input document. this is needed
            // because we used cocoa's UIImage -imageNamed to open the input file.
            destContext.translateBy(x: 0, y: destResolution.height)
            destContext.scaleBy(x: 1, y: -1)
            
            // Now define the size of the rectangle to be used for the
            // incremental blits from the input image to the output image.
            // we use a source tile width equal to the width of the source
            // image due to the way that iOS retrieves image data from disk.
            // iOS must decode an image from disk in full width 'bands', even
            // if current graphics context is clipped to a subrect within that
            // band. Therefore we fully utilize all of the pixel data that results
            // from a decoding opertion by achnoring our tile size to the full
            // width of the input image.
            var sourceTile = CGRect.zero
            sourceTile.size.width = sourceResolution.width
            
            // The source tile height is dynamic. Since we specified the size
            // of the source tile in MB, see how many rows of pixels high it
            // can be given the input image width.
            sourceTile.size.height = Constant.tileTotalPixels / sourceTile.size.width
            
            // The output tile is the same proportions as the input tile, but
            // scaled to image scale.
            var destTile = CGRect.zero
            destTile.size.width = destResolution.width
            destTile.size.height = sourceTile.size.height * imageScale
            
            // The source seem overlap is proportionate to the destination seem overlap.
            // this is the amount of pixels to overlap each tile as we assemble the ouput image.
            let sourceSeemOverlap = (Constant.destSeemOverlap / destResolution.height) * sourceResolution.height
            var sourceTileImageRef: CGImage?
            
            // calculate the number of read/write operations required to assemble the
            // output image.
            var iterations = Int(sourceResolution.height / sourceTile.size.height)
            
            // If tile height doesn't divide the image height evenly, add another iteration
            // to account for the remaining pixels.
            let remainder = Int(sourceResolution.height) % Int(sourceTile.size.height)
            if remainder > 0 { iterations += 1 }
            
            // Add seem overlaps to the tiles, but save the original tile height for y coordinate calculations.
            let sourceTileHeightMinusOverlap = sourceTile.size.height
            sourceTile.size.height += sourceSeemOverlap
            destTile.size.height += Constant.destSeemOverlap
            
            for y in 0..<iterations {
                autoreleasepool {
                    sourceTile.origin.y = CGFloat(y) * sourceTileHeightMinusOverlap + sourceSeemOverlap
                    destTile.origin.y = destResolution.height - (CGFloat( y + 1) * sourceTileHeightMinusOverlap * imageScale + Constant.destSeemOverlap)
                    
                    // create a reference to the source image with its context clipped to the argument rect.
                    sourceTileImageRef = sourceImageRef.cropping(to: sourceTile)
                    
                    // if this is the last tile, it's size may be smaller than the source tile height.
                    // adjust the dest tile size to account for that difference.
                    if y == iterations - 1 && remainder > 0 {
                        var dify = destTile.size.height
                        destTile.size.height = CGFloat(sourceTileImageRef!.height) * imageScale
                        dify -= destTile.size.height
                        destTile.origin.y += dify
                    }
                    
                    // read and write a tile sized portion of pixels from the input image to the output image.
                    destContext.draw(sourceTileImageRef!, in: destTile)
                }
            }
            
            // create a CGImage from the offscreen image context
            guard let destImageRef = destContext.makeImage() else { return self }
            
            // wrap a UIImage around the CGImage
            let destImage = UIImage(cgImage: destImageRef, scale: 1.0, orientation: .downMirrored)
            return destImage
        }
    }
}
