//
//  DKAssetGroupDetailCameraCell.swift
//  DKImagePickerController
//
//  Created by ZhangAo on 07/12/2016.
//  Copyright © 2016 ZhangAo. All rights reserved.
//

import UIKit

@objcMembers
public class DKAssetGroupDetailCameraCell: DKAssetGroupDetailBaseCell {
    
    public class override func cellReuseIdentifier() -> String {
        return "DKImageCameraIdentifier"
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let cameraImageView = UIImageView(frame: self.bounds)
        cameraImageView.contentMode = .center
        cameraImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cameraImageView.image = DKImagePickerControllerResource.cameraImage()
        self.contentView.addSubview(cameraImageView)
        
        self.contentView.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        self.contentView.accessibilityIdentifier = "DKImageCameraAccessibilityIdentifier"
        self.contentView.isAccessibilityElement = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
} /* DKAssetGroupDetailCameraCell */
