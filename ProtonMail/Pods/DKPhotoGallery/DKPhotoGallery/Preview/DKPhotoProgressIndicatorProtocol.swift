//
//  DKPhotoProgressIndicatorProtocol.swift
//  DKPhotoGallery
//
//  Created by ZhangAo on 08/09/2017.
//  Copyright © 2017 ZhangAo. All rights reserved.
//

import Foundation
import UIKit

public protocol DKPhotoProgressIndicatorProtocol : NSObjectProtocol {
    
    init(with view: UIView)
    
    func startIndicator()
    
    func stopIndicator()
    
    func setIndicatorProgress(_ progress: Float)
}

