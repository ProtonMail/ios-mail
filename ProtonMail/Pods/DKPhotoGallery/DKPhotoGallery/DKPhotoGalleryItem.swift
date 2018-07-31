//
//  DKPhotoGalleryItem.swift
//  DKPhotoGallery
//
//  Created by ZhangAo on 08/09/2017.
//  Copyright © 2017 ZhangAo. All rights reserved.
//

import UIKit
import Photos

public let DKPhotoGalleryItemExtraInfoKeyRemoteImageOriginalURL: String = "DKPhotoGalleryItemExtraInfoKeyRemoteImageOriginalURL"    // URL.
public let DKPhotoGalleryItemExtraInfoKeyRemoteImageOriginalSize: String = "DKPhotoGalleryItemExtraInfoKeyRemoteImageOriginalSize"  // (Optional)UInt. The number of bytes of the image.

@objc
public class DKPhotoGalleryItemConstant: NSObject {
    
    @objc public class func extraInfoKeyRemoteImageOriginalURL() -> String {
        return DKPhotoGalleryItemExtraInfoKeyRemoteImageOriginalURL
    }
    
    @objc public class func extraInfoKeyRemoteImageOriginalSize() -> String {
        return DKPhotoGalleryItemExtraInfoKeyRemoteImageOriginalSize
    }
    
}

//////////////////////////////////////////////////////////////////

@objc
open class DKPhotoGalleryItem: NSObject {
    
    /// The image to be set initially, until the image request finishes.
    @objc open var thumbnail: UIImage?
    
    @objc open var image: UIImage?
    @objc open var imageURL: URL?
    
    @objc open var videoURL: URL?
    
    /// iOS 11 or higher required.
    @objc open var pdfURL: URL?

    /**
     DKPhotoGallery will automatically decide whether to create ImagePreview or PlayerPreview via the mediaType of the asset.
     
     See more: DKPhotoPreviewFactory.swift
     */
    @objc open var asset: PHAsset?
    @objc open var assetLocalIdentifier: String?
    
    /**
     Used for some optional features.
     
     For ImagePreview, you can enable the original image download feature with a key named DKPhotoGalleryItemExtraInfoKeyRemoteImageOriginalURL.
     */
    @objc open var extraInfo: [String: Any]?
    
    @objc convenience public init(image: UIImage) {
        self.init()
        
        self.image = image
    }
    
    @objc convenience public init(imageURL: URL) {
        self.init()
        
        self.imageURL = imageURL
    }
    
    @objc convenience public init(videoURL: URL) {
        self.init()
        
        self.videoURL = videoURL
    }
    
    @available(iOS 11.0, *)
    @objc convenience public init(pdfURL: URL) {
        self.init()
        
        self.pdfURL = pdfURL
    }

    @objc convenience public init(asset: PHAsset) {
        self.init()
        
        self.asset = asset
    }
    
    @objc public class func items(withImageURLs URLs: [URL]) -> [DKPhotoGalleryItem] {
        var items: [DKPhotoGalleryItem] = []
        for URL in URLs {
            let item = DKPhotoGalleryItem()
            item.imageURL = URL
            
            items.append(item)
        }
        
        return items
    }
    
    @objc public class func items(withImageURLStrings URLStrings: [String]) -> [DKPhotoGalleryItem] {
        var items: [DKPhotoGalleryItem] = []
        for URLString in URLStrings {
            let item = DKPhotoGalleryItem()
            item.imageURL = URL(string: URLString)
            
            items.append(item)
        }
        
        return items
    }

}

