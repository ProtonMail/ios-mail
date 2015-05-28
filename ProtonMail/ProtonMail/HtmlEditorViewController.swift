//
//  HtmlEditorViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/21/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

protocol HtmlEditorViewControllerDelegate {
    func editorSizeChanged(size: CGSize)
    
}

class HtmlEditorViewController: ZSSRichTextEditor {

    var delegate: HtmlEditorViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.baseURL = NSURL( fileURLWithPath: "https://protonmail.ch")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func editorDidScrollWithPosition(position: Int) {
        super.editorDidScrollWithPosition(position)
        self.delegate?.editorSizeChanged(self.getContentSize())
    }

}
