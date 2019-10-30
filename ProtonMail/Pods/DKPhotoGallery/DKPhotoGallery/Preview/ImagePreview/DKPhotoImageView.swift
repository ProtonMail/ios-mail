//
//  DKPhotoImageView.swift
//  DKPhotoGallery
//
//  Created by ZhangAo on 13/12/2017.
//  Copyright © 2017 ZhangAo. All rights reserved.
//

#if canImport(FLAnimatedImage)
import FLAnimatedImage
#elseif canImport(SDWebImage)
import SDWebImage
#endif

open class DKPhotoImageView: FLAnimatedImageView {
    
    public override init(image: UIImage? = nil, highlightedImage: UIImage? = nil) {
        super.init(image: image, highlightedImage: highlightedImage)
        
        self.contentMode = .scaleAspectFit
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
