//
//  ImageProcessor.swift
//  ProtonMail - Created on 28/06/2018.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import Photos
import PromiseKit

protocol ImageProcessor {
    func process(original originalImage: UIImage) -> Promise<Void>
    func process(asset: PHAsset)
}
extension ImageProcessor where Self: AttachmentProvider {
    
    private func writeItemToTempDirectory(_ item: Data, filename: String) throws -> URL {
        let tempFileUrl = try FileManager.default.createTempURL(forCopyOfFileNamed: filename)
        try item.write(to: tempFileUrl)
        return tempFileUrl
    }
    
    internal func process(original originalImage: UIImage) -> Promise<Void> {
        let fileName = "\(NSUUID().uuidString).PNG"
        let ext = "image/png"
        var fileData: FileData!

        #if APP_EXTENSION
            guard let data = originalImage.pngData(),
                let newUrl = try? self.writeItemToTempDirectory(data, filename: fileName) else
            {
                self.controller?.error(NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil).description)
                return Promise()
            }
            fileData = ConcreteFileData<URL>(name: fileName, ext: ext, contents: newUrl)
        #else
            fileData = ConcreteFileData<UIImage>(name: fileName, ext: ext, contents: originalImage)
        #endif
        
        return self.controller?.fileSuccessfullyImported(as: fileData) ?? Promise()
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
                self.controller?.fileSuccessfullyImported(as: fileData).cauterize()
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
                
                let UTIstr = dataUTI ?? ""
                
                if fileName.preg_match(".(heif|heic)") || UTIstr.preg_match(".(heif|heic)") {
                    if let rawImage = UIImage(data: image_data) {
                        if let newData = rawImage.jpegData(compressionQuality: 1.0), newData.count > 0 {
                            image_data =  newData
                            fileName = fileName.preg_replace(".(heif|heic)", replaceto: ".jpeg")
                        }
                    }
                }
                let fileData = ConcreteFileData<Data>(name: fileName, ext: fileName.mimeType(), contents: image_data)
                self.controller?.fileSuccessfullyImported(as: fileData).cauterize()
            }
            
        default:
            self.controller?.error(LocalString._cant_open_the_file)
        }
    }
}

