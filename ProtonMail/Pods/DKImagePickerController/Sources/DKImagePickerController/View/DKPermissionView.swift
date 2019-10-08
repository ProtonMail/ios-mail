//
//  DKPermissionView.swift
//  DKImagePickerController
//
//  Created by ZhangAo on 15/12/17.
//  Copyright © 2015年 ZhangAo. All rights reserved.
//

import UIKit

@objc
open class DKPermissionView: UIView {
	
	private let titleLabel = UILabel()
	private let permitButton = UIButton()
	
	open class func permissionView(_ style: DKImagePickerControllerSourceType,
                                   withColors colors: DKPermissionViewColors = DKPermissionViewColors()) -> DKPermissionView {
		
		let permissionView = DKPermissionView()
		permissionView.addSubview(permissionView.titleLabel)
		permissionView.addSubview(permissionView.permitButton)
		
		if style == .photo {
			permissionView.titleLabel.text = DKImagePickerControllerResource.localizedStringWithKey("permission.photo.title")
			permissionView.titleLabel.textColor = colors.titlePhotoColor
		} else {
			permissionView.titleLabel.textColor = colors.titleCameraColor
			permissionView.titleLabel.text = DKImagePickerControllerResource.localizedStringWithKey("permission.camera.title")
		}
		permissionView.titleLabel.sizeToFit()
		
		permissionView.permitButton.setTitle(DKImagePickerControllerResource.localizedStringWithKey("permission.allow"), for: .normal)
		permissionView.permitButton.setTitleColor(colors.permitButtonColor, for: .normal)
		permissionView.permitButton.addTarget(permissionView, action: #selector(DKPermissionView.gotoSettings), for: .touchUpInside)
		permissionView.permitButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
		permissionView.permitButton.sizeToFit()
		permissionView.permitButton.center = CGPoint(x: permissionView.titleLabel.center.x,
			y: permissionView.titleLabel.bounds.height + 40)
		
		permissionView.frame.size = CGSize(width: max(permissionView.titleLabel.bounds.width, permissionView.permitButton.bounds.width),
			height: permissionView.permitButton.frame.maxY)
		
		return permissionView
	}
	
	open override func didMoveToWindow() {
        super.didMoveToWindow()
		
		self.center = self.superview!.center
	}
	
	@objc open func gotoSettings() {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(appSettings)
            }
        }
    }
	
}

@objc
public class DKPermissionViewColors: NSObject {
    let backgroundColor: UIColor
    let titlePhotoColor: UIColor
    let titleCameraColor: UIColor
    let permitButtonColor: UIColor

    public init(forBackground background: UIColor = UIColor.black,
                forPhotoTitle photoTitle: UIColor = UIColor.gray,
                forCameraTitle cameraTitle: UIColor = UIColor.white,
                forButton button: UIColor = UIColor(red: 0, green: 122.0 / 255, blue: 1, alpha: 1)) {
        self.backgroundColor = background
        self.titlePhotoColor = photoTitle
        self.titleCameraColor = cameraTitle
        self.permitButtonColor = button
    }
    
}
