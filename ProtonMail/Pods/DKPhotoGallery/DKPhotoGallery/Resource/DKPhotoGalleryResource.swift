//
//  DKPhotoGalleryResource.swift
//  DKPhotoGallery
//
//  Created by ZhangAo on 15/8/11.
//  Copyright (c) 2015年 ZhangAo. All rights reserved.
//

import UIKit

/// Manage all resource files and internationalization support for DKPhotoGallery.
public class DKPhotoGalleryResource {
    
    // MARK: - Internationalization
    
    public class func localizedStringWithKey(_ key: String, value: String? = nil) -> String {
        let string = customLocalizationBlock?(key)
        return string ?? NSLocalizedString(key, tableName: "DKPhotoGallery",
                                           bundle:Bundle.photoGalleryResourceBundle(),
                                           value: value ?? "",
                                           comment: "")
    }
    
    @objc public static var customLocalizationBlock: ((_ title: String) -> String?)?

    // MARK: - Images
    
    public class func downloadFailedImage() -> UIImage {
        return imageForResource("ImageFailed")
    }
    
    public class func closeVideoImage() -> UIImage {
        return imageForResource("VideoClose")
    }
    
    public class func videoPlayImage() -> UIImage {
        return imageForResource("VideoPlay")
    }
    
    public class func videoToolbarPlayImage() -> UIImage {
        return imageForResource("ToolbarPlay")
    }
    
    public class func videoToolbarPauseImage() -> UIImage {
        return imageForResource("ToolbarPause")
    }
    
    public class func videoPlayControlBackgroundImage() -> UIImage {
        return stretchImgFromMiddle(imageForResource("VideoPlayControlBackground"))
    }
    
    public class func videoTimeSliderImage() -> UIImage {
        return imageForResource("VideoTimeSlider")
    }
    
    // MARK: - Private
    
    private class func imageForResource(_ name: String) -> UIImage {
        let bundle = Bundle.photoGalleryResourceBundle()
        let image = UIImage(named: name, in: bundle, compatibleWith: nil) ?? UIImage()

        return image
    }
    
    private class func stretchImgFromMiddle(_ image: UIImage) -> UIImage {
        let centerX = image.size.width / 2
        let centerY = image.size.height / 2
        return image.resizableImage(withCapInsets: UIEdgeInsets(top: centerY, left: centerX, bottom: centerY, right: centerX))
    }
    
}

private extension Bundle {
    
    class func photoGalleryResourceBundle() -> Bundle {
        let assetPath = Bundle(for: DKPhotoGalleryResource.self).resourcePath!
        return Bundle(path: (assetPath as NSString).appendingPathComponent("DKPhotoGallery.bundle"))!
    }
    
}

