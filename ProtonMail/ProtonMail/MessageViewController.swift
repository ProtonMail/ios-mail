//
//  MessageViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/27/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class MessageViewController: ProtonMailViewController {
    
    /// message info
    var message: Message!
    var bodyText : String!
    
    var emailView: EmailView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        emailView = EmailView(message: message)
        emailView.frame = self.view.frame
        
        
        self.view.addSubview(emailView)
        
        
        
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
