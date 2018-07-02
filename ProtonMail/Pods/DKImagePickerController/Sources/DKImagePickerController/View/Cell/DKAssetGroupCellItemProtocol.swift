//
//  DKAssetGroupCellItemProtocol.swift
//  DKImagePickerController
//
//  Created by ZhangAo on 03/01/2017.
//  Copyright © 2017 ZhangAo. All rights reserved.
//

import UIKit

@objc
public protocol DKAssetGroupCellItemProtocol {
    
    weak var asset: DKAsset! { get set }
    var selectedIndex: Int { get set }
    var thumbnailImage: UIImage? { get set }
    var thumbnailImageView: UIImageView { get }
}
