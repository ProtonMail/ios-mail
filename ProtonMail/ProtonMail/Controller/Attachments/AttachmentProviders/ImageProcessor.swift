//
//  ImageProcessor.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 28/06/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import Photos

protocol ImageProcessor {
    func process(original originalImage: UIImage)
    func process(asset: PHAsset)
}
extension ImageProcessor where Self: AttachmentProvider {
    internal func process(original originalImage: UIImage) {
        self.controller.finish(originalImage, filename: "\(NSUUID().uuidString).PNG", extension: "image/png")
    }
    
    internal func process(asset: PHAsset) {
        switch asset.mediaType {
        case .video:
            let options = PHVideoRequestOptions()
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options, resultHandler: { (asset: AVAsset?, audioMix: AVAudioMix?, info:[AnyHashable : Any]?) in
                
                if let error = info?[PHImageErrorKey] as? NSError {
                    self.controller.error(error.debugDescription)
                    return
                }
                guard let asset = asset as? AVURLAsset, let image_data = try? Data(contentsOf: asset.url) else {
                    self.controller.error(LocalString._cant_open_the_file)
                    return
                }
                
                let fileName = asset.url.lastPathComponent
                self.controller.finish(image_data, filename: fileName, extension: fileName.mimeType())
            })
            
        default:
            let options = PHImageRequestOptions()
            PHImageManager.default().requestImageData(for: asset, options: options) { imagedata, dataUTI, orientation, info in
                guard var image_data = imagedata, /* let _ = dataUTI,*/ let info = info, image_data.count > 0 else {
                    self.controller.error(LocalString._cant_open_the_file)
                    return
                }
                var fileName = "\(NSUUID().uuidString).jpg"
                if let url = info["PHImageFileURLKey"] as? NSURL, let url_filename = url.lastPathComponent {
                    fileName = url_filename
                }
                
                if fileName.preg_match(".(heif|heic)") {
                    if let rawImage = UIImage(data: image_data) {
                        if let newData = UIImageJPEGRepresentation(rawImage, 1.0), newData.count > 0 {
                            image_data =  newData
                            fileName = fileName.preg_replace(".(heif|heic)", replaceto: ".jpeg")
                        }
                    }
                }

                self.controller.finish(image_data, filename: fileName, extension: fileName.mimeType())
            }
        }
    }
}

