//
//  VideoWriter.swift
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

final class VideoWriter {

    private let configuration: VideoGenerationConfiguration
    private let videoWriter: AVAssetWriter!
    private var videoWriterInput: AVAssetWriterInput!
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!

    var isReadyForData: Bool {
        return videoWriterInput.isReadyForMoreMediaData
    }

    // MARK: - Initialization

    init?(configuration: VideoGenerationConfiguration) {
        self.configuration = configuration
        if let videoWriter = try? AVAssetWriter(outputURL: configuration.outputUrl, fileType: configuration.fileType),
           videoWriter.canApply(outputSettings: configuration.avOutputSettings, forMediaType: AVMediaType.video) {
            self.videoWriter = videoWriter
        } else {
            return nil
        }
        self.videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: configuration.avOutputSettings)
        if videoWriter.canAdd(videoWriterInput) {
            videoWriter.add(videoWriterInput)
        } else {
            return nil
        }
        let attributes = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: NSNumber(value: Float(configuration.size.width)),
            kCVPixelBufferHeightKey as String: NSNumber(value: Float(configuration.size.height))
        ]
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput,
                                                                  sourcePixelBufferAttributes: attributes)
    }
    
    // MARK: - Public

    func start() -> Bool {
        guard videoWriter.startWriting() else {
            return false
        }
        videoWriter.startSession(atSourceTime: .zero)
        return pixelBufferAdaptor.pixelBufferPool != nil
    }

    func render(appendPixelBuffers: @escaping ((VideoWriter) -> (isFinished: Bool, success: Bool)),
                completion: @escaping (Bool) -> Void) {
        let queue = DispatchQueue(label: String(describing: VideoWriter.self))
        videoWriterInput.requestMediaDataWhenReady(on: queue) {
            let output = appendPixelBuffers(self)
            guard output.success else {
                completion(false)
                return
            }
            if output.isFinished {
                self.videoWriterInput.markAsFinished()
                self.videoWriter.finishWriting {
                    DispatchQueue.main.async {
                        completion(true)
                    }
                }
            }
        }
    }

    func addImage(image: UIImage, withPresentationTime presentationTime: CMTime) -> Bool {
        guard let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool else { return false }
        if let pixelBuffer = PixelBufferFactory.pixelBufferFromImage(image: image,
                                                                     pixelBufferPool: pixelBufferPool,
                                                                     renderSettings: configuration) {
            return pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
        }
        return false
    }
}
