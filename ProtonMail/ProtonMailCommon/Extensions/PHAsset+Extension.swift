//
//  PHAssertExtension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/29/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation

import Photos

@available(*, deprecated)
extension PHAsset {
    var originalFilename: String? {
        
        var fname:String?
        
        if #available(iOS 9.0, *) {
            let resources = PHAssetResource.assetResources(for: self)
            if let resource = resources.first {
                fname = resource.originalFilename
            }
        }
        
        if fname == nil {
            // this is an undocumented workaround that works as of iOS 9.1
            fname = self.value(forKey: "filename") as? String
        }
        
        return fname
    }
}
