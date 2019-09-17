//
//  ImageProcessor.swift
//  ProtonMail - Created on 28/06/2018.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
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

import Foundation
import Photos

protocol ImageProcessor {
    func process(original originalImage: UIImage)
    func process(asset: PHAsset)
}
extension ImageProcessor where Self: AttachmentProvider {
    
    private func writeItemToTempDirectory(_ item: Data, filename: String) throws -> URL {
        let tempFileUrl = try FileManager.default.createTempURL(forCopyOfFileNamed: filename)
        try item.write(to: tempFileUrl)
        return tempFileUrl
    }
    
    internal func process(original originalImage: UIImage) {
        let fileName = "\(NSUUID().uuidString).PNG"
        let ext = "image/png"
        var fileData: FileData!

        #if APP_EXTENSION
            guard let data = originalImage.pngData(),
                let newUrl = try? self.writeItemToTempDirectory(data, filename: fileName) else
            {
                self.controller.error(NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil).description)
                return
            }
            fileData = ConcreteFileData<URL>(name: fileName, ext: ext, contents: newUrl)
        #else
            fileData = ConcreteFileData<UIImage>(name: fileName, ext: ext, contents: originalImage)
        #endif
        
        self.controller.fileSuccessfullyImported(as: fileData)
    }
    
    internal func process(asset: PHAsset) {
        switch asset.mediaType {
        case .video:
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.progressHandler = { progress, error, pointer, info in
                DispatchQueue.main.async {
                    (LocalString._importing + " \(Int(progress * 100))%").alertToastBottom()
                }
            }
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options, resultHandler: { asset, audioMix, info in
                if let error = info?[PHImageErrorKey] as? NSError {
                    self.controller?.error(error.debugDescription)
                    return
                }
                guard let asset = asset as? AVURLAsset, let image_data = try? Data(contentsOf: asset.url) else {
                    self.controller?.error(LocalString._cant_open_the_file)
                    return
                }
                
                let fileName = asset.url.lastPathComponent
                let fileData = ConcreteFileData<Data>(name: fileName, ext: fileName.mimeType(), contents: image_data)
                self.controller?.fileSuccessfullyImported(as: fileData)
            })
            
        case .image:
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.progressHandler = { progress, error, pointer, info in
                DispatchQueue.main.async {
                    (LocalString._importing + " \(Int(progress * 100))%").alertToastBottom()
                }
            }
            PHImageManager.default().requestImageData(for: asset, options: options) { imagedata, dataUTI, orientation, info in
                guard var image_data = imagedata, /* let _ = dataUTI,*/ let info = info, image_data.count > 0 else {
                    self.controller?.error(LocalString._cant_open_the_file)
                    return
                }
                var fileName = "\(NSUUID().uuidString).jpg"
                if let url = info["PHImageFileURLKey"] as? NSURL, let url_filename = url.lastPathComponent {
                    fileName = url_filename
                }
                
                if fileName.preg_match(".(heif|heic)") {
                    if let rawImage = UIImage(data: image_data) {
                        if let newData = rawImage.jpegData(compressionQuality: 1.0), newData.count > 0 {
                            image_data =  newData
                            fileName = fileName.preg_replace(".(heif|heic)", replaceto: ".jpeg")
                        }
                    }
                }
                let fileData = ConcreteFileData<Data>(name: fileName, ext: fileName.mimeType(), contents: image_data)
                self.controller?.fileSuccessfullyImported(as: fileData)
            }
            
        default:
            self.controller.error(LocalString._cant_open_the_file)
        }
    }
}

