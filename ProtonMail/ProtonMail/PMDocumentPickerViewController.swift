//
//  PMDocumentPickerViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/31/16.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import Foundation


class PMDocumentPickerViewController : UIDocumentPickerViewController {
    
    
    
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue) | Int(UIInterfaceOrientationMask.Landscape.rawValue)
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
}