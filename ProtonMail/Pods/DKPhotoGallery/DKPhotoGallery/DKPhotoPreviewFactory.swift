//
//  DKPhotoPreviewFactory.swift
//  DKPhotoGallery
//
//  Created by ZhangAo on 15/09/2017.
//  Copyright © 2017 ZhangAo. All rights reserved.
//

import Foundation
import Photos

@objc
extension DKPhotoBasePreviewVC {
    
    @objc public class func photoPreviewClass(with item: DKPhotoGalleryItem) -> DKPhotoBasePreviewVC.Type {
        if item.image != nil {
            return DKPhotoImagePreviewVC.self
            
        } else if item.imageURL != nil {
            return DKPhotoImagePreviewVC.self
            
        } else if let asset = item.asset {
            if asset.mediaType == .video {
                return DKPhotoPlayerPreviewVC.self
            } else {
                return DKPhotoImagePreviewVC.self
            }
            
        } else if let assetLocalIdentifier = item.assetLocalIdentifier {
            item.asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetLocalIdentifier], options: nil).firstObject
            item.assetLocalIdentifier = nil
            return self.photoPreviewClass(with: item)
            
        } else if item.videoURL != nil {
            return DKPhotoPlayerPreviewVC.self
            
        } else if #available(iOS 11.0, *), item.pdfURL != nil {
            return DKPhotoPDFPreviewVC.self

        } else {
            assertionFailure()
            return DKPhotoBasePreviewVC.self
        }
    }
    
    @objc public class func photoPreviewVC(with item: DKPhotoGalleryItem) -> DKPhotoBasePreviewVC {
        let previewVC = self.photoPreviewClass(with: item).init()
        previewVC.item = item
        
        return previewVC
    }
    
}
