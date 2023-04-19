//
//  XCUITestCaseRecorder.swift
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

#if os(iOS)
import UIKit
import XCTest

class XCUITestCaseRecorder {

    struct Constants {
        static let minimumRequiredScreenshotSize: CGSize = .init(width: 10, height: 10)
        static let fallbackMp4Extension = "mp4"
        static let fallbackGifExtension = "gif"
    }

    private let testName: String
    private var screenshotTimer: Timer?
    private var screenshots = [UIImage]()
    var timeInterval: TimeInterval = 0.3

    // MARK: - Initialization

    init(testName: String) {
        self.testName = testName
    }

    // MARK: - Public

    func resumeRecording() {
        self.screenshotTimer = Timer.scheduledTimer(timeInterval: timeInterval,
                                                    target: self, selector: #selector(saveScreenshot),
                                                    userInfo: nil, repeats: true)
    }

    func pauseRecording() {
        self.screenshotTimer?.invalidate()
        self.screenshotTimer = nil
    }

    func generateGifAttachment() -> XCTAttachment? {
        pauseRecording()
        guard let directoryUrl = FileManagerUtils.createFolderInDocumentsDirectory(folderName: testName) else {
            self.screenshots.removeAll()
            return nil
        }
        let result = self.createGIF(from: self.screenshots, directoryPath: directoryUrl.path)
        self.screenshots.removeAll()
        if let fileURL = result.fileUrl, result.success {
            let attachment = XCTAttachment(contentsOfFile: fileURL)
            attachment.lifetime = .keepAlways
            return attachment
        } else {
            return nil
        }
    }

    func generateVideoAttachment(completion: @escaping (XCTAttachment?) -> Void) {
        pauseRecording()
        guard let directoryUrl = FileManagerUtils.createFolderInDocumentsDirectory(folderName: testName) else {
            self.screenshots.removeAll()
            completion(nil)
            return
        }
        self.createVideo(from: self.screenshots, directoryPath: directoryUrl.path) { success, fileURL in
            self.screenshots.removeAll()
            if let fileURL = fileURL, success {
                let attachment = XCTAttachment(contentsOfFile: fileURL)
                attachment.lifetime = .keepAlways
                completion(attachment)
            } else {
                completion(nil)
            }
        }
    }

    // MARK: - Private

    @objc private func saveScreenshot() {
        let screenshotImage = XCUIScreen.main.screenshot().image
        let imageSize = screenshotImage.size
        let minimumSize = Constants.minimumRequiredScreenshotSize
        if imageSize.height > minimumSize.height && imageSize.width > minimumSize.width {
            self.screenshots.append(screenshotImage)
        }
    }

    private func createGIF(from images: [UIImage], directoryPath: String) -> (success: Bool, fileUrl: URL?) {
        let utTypeGif = UTTypeProvider.provideGifUTTypeIdentifier()
        let fileExtension = FileExtensionProvider.provideFileExtension(utTypeIdentifier: utTypeGif) ?? Constants.fallbackGifExtension

        let fileUrl = URL(fileURLWithPath: "\(directoryPath)/\(testName).\(fileExtension)")
        try? FileManager.default.removeItem(atPath: fileUrl.path)

        let configuration = GifGenerationConfiguration(utType: utTypeGif as CFString, outputUrl: fileUrl)
        let gifGenerator = GifGenerator(configuration: configuration, images: images)
        return (gifGenerator.generate(), fileUrl)
    }

    private func createVideo(from images: [UIImage],
                             directoryPath: String,
                             completion: @escaping ((_ success: Bool, _ fileUrl: URL?) -> Void)) {
        let fileType = AVFileTypeProvider.provideMp4AVFileType()
        let fileExtension = FileExtensionProvider.provideFileExtension(avFileType: fileType) ?? Constants.fallbackMp4Extension

        let fileUrl = URL(fileURLWithPath: "\(directoryPath)/\(testName).\(fileExtension)")
        try? FileManager.default.removeItem(atPath: fileUrl.path)

        let configuration = VideoGenerationConfiguration(outputUrl: fileUrl, fileType: fileType)
        if let videoGenerator = VideoGenerator(configuration: configuration, images: images) {
            videoGenerator.generate(completion: { success in
                completion(success, fileUrl)
            })
        } else {
            completion(false, nil)
        }
    }
}
#endif
