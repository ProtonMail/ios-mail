//
//  DKPhotoQRCodeResultVC.swift
//  DKPhotoGallery
//
//  Created by ZhangAo on 08/09/2017.
//  Copyright © 2017 ZhangAo. All rights reserved.
//

import UIKit

class DKPhotoQRCodeResultVC: UIViewController {

    private var result: String = ""
    
    var textView = UITextView()
    
    convenience init(result: String) {
        self.init(nibName: nil, bundle: nil)
        
        self.result = result
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.white
        self.title = DKPhotoGalleryResource.localizedStringWithKey("preview.image.extractQRCode.result.text.title")
        
        self.textView.frame = self.view.bounds
        self.textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.textView.font = UIFont.systemFont(ofSize: 16)
        self.textView.textColor = UIColor.darkText
        self.textView.isEditable = false
        self.textView.isSelectable = true
        self.view.addSubview(self.textView)
        
        self.textView.text = self.result
    }

}
