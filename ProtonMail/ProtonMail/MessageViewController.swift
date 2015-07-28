//
//  MessageViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/27/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class MessageViewController: ProtonMailViewController {
    
    var message: Message!
    var bodyText : String!
    @IBOutlet weak var detailWebView: UIWebView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let font = UIFont.robotoLight(size: UIFont.Size.h6)
        let cssColorString = UIColor.ProtonMail.Gray_383A3B.cssString
        
        let w = UIScreen.mainScreen().applicationFrame.width;
        
        var error: NSError?
        bodyText = self.message.decryptBodyIfNeeded(&error) ?? NSLocalizedString("Unable to decrypt message.")
        
        let bundle = NSBundle.mainBundle()
        let path = bundle.pathForResource("editor", ofType: "css")
        let css = String(contentsOfFile: path!, encoding: NSUTF8StringEncoding)!
        let htmlString = "<style>\(css)</style><div class='inbox-body'>\(bodyText)</div>"
        
        self.detailWebView.loadHTMLString(htmlString, baseURL: nil)
        
        var myButton = UIView(frame: CGRect(x: 0, y: 0, width: w, height: 100))
        myButton.backgroundColor = UIColor.redColor()
        self.detailWebView.scrollView.addSubview(myButton )
        self.detailWebView.scrollView.delegate = self
        
        for subview in self.detailWebView.scrollView.subviews {
            let sub = subview as! UIView
            if sub == myButton {
                continue
            } else if subview is UIImageView {
                sub.hidden = true
            } else {
                sub.frame = CGRect(x: sub.frame.origin.x, y: sub.frame.origin.y + myButton.frame.height, width: sub.frame.width, height: sub.frame.height);
            }
        }
    }
    
    override func shouldShowSideMenu() -> Bool {
        return false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
}


extension MessageViewController : UIScrollViewDelegate {
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
//        var x : Float = 0;
//        if(scrollView.contentOffset.x < 0) {
//            x = 0;
//        } else if((scrollView.contentOffset.x + customView.Frame.Size.Width) > scrollView.ContentSize.Width) {
//            x = scrollView.ContentSize.Width - customView.Frame.Size.Width;
//        } else {
//            x = scrollView.ContentOffset.X;
//            customView.Frame = new RectangleF(new PointF(x, customView.Frame.Y), customView.Frame.Size);
//        }
        //println("")
    }
    
//    override func scrollViewDidScroll(scrollView: UIScrollView) {
//        
//        super.scrollviewd
//        println("")
//    }
}
