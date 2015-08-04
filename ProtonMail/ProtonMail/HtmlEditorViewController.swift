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
    func editorCaretPosition ( position : Int)
}

class HtmlEditorViewController: ZSSRichTextEditor {

    var delegate: HtmlEditorViewControllerDelegate?
    var emailHeader : UIView!
    var webView : UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.baseURL = NSURL( fileURLWithPath: "https://protonmail.ch")
        
        self.webView = self.getWebView()
        self.emailHeader = UIView()
        self.emailHeader.backgroundColor = UIColor.yellowColor()
        self.webView.scrollView.addSubview(self.emailHeader)
        let w = UIScreen.mainScreen().applicationFrame.width;
        self.emailHeader.frame = CGRect(x: 0, y: 0, width: w, height: 100)
        updateContentLayout(false)

    }
    
    func setBody (body : String ) {
        self.setHTML(body)
    }
    
    override func viewWillAppear(animated: Bool) {
       // updateContentLayout(false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func editorDidScrollWithPosition(position: Int) {
        super.editorDidScrollWithPosition(position)
        
        //let new_position = self.getCaretPosition().toInt() ?? 0
        
        //self.delegate?.editorSizeChanged(self.getContentSize())
        
        //self.delegate?.editorCaretPosition(new_position)
    }

    
    private func updateContentLayout(animation: Bool) {
      
        UIView.animateWithDuration(animation ? 0.3 : 0, animations: { () -> Void in
            for subview in self.webView.scrollView.subviews {
                let sub = subview as! UIView
                if sub == self.emailHeader {
                    continue
                } else if subview is UIImageView {
                    //sub.hidden = true
                    continue
                } else {

                    let h : CGFloat = 100
                    sub.frame = CGRect(x: sub.frame.origin.x, y: h, width: sub.frame.width, height: sub.frame.height);
                }
            }
        })
    }
}
