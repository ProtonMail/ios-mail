//
//  PixelBufferFactory.swift
//
//  ProtonMail - Created on 26.01.22.
//
//  The MIT License
//
//  Copyright (c) 2020 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit
import AVFoundation

final class PixelBufferFactory {

    // MARK: - Public

    static func pixelBufferFromImage(image: UIImage,
                                     pixelBufferPool: CVPixelBufferPool,
                                     renderSettings: VideoGenerationConfiguration) -> CVPixelBuffer? {
        guard let pixelBuffer = createPixelBuffer(for: pixelBufferPool) else {
            return nil
        }
        let size = renderSettings.size
        let lockFlags = CVPixelBufferLockFlags(rawValue: 0)
        CVPixelBufferLockBaseAddress(pixelBuffer, lockFlags)

        if let context = createCGContext(size: size, pixelBuffer: pixelBuffer),
           let cgImage = image.cgImage {
            context.clear(.init(origin: .zero, size: size))
            let imageRect = calculateImageRect(image: image, contextSize: size)
            context.draw(cgImage, in: imageRect)
            CVPixelBufferUnlockBaseAddress(pixelBuffer, lockFlags)
            return pixelBuffer
        } else {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, lockFlags)
            return nil
        }
    }

    // MARK: - Private

    private static func createPixelBuffer(for pool: CVPixelBufferPool) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer)
        if status != kCVReturnSuccess {
            return nil
        }
        return pixelBuffer
    }

    private static func createCGContext(size: CGSize, pixelBuffer: CVPixelBuffer) -> CGContext? {
        .init(data: CVPixelBufferGetBaseAddress(pixelBuffer),
              width: Int(size.width),
              height: Int(size.height),
              bitsPerComponent: 8,
              bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
              space: CGColorSpaceCreateDeviceRGB(),
              bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
    }

    private static func calculateImageRect(image: UIImage, contextSize: CGSize) -> CGRect {
        let horizontalRatio = contextSize.width / image.size.width
        let verticalRatio = contextSize.height / image.size.height
        let aspectRatio = min(horizontalRatio, verticalRatio)
        let newSize = CGSize(width: image.size.width * aspectRatio, height: image.size.height * aspectRatio)

        let originX = newSize.width < contextSize.width ? (contextSize.width - newSize.width) / 2 : 0
        let originY = newSize.height < contextSize.height ? (contextSize.height - newSize.height) / 2 : 0

        return .init(origin: .init(x: originX, y: originY), size: newSize)
    }
}
