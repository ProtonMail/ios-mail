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
    var message: Message! {
        didSet {
            message.fetchDetailIfNeeded() { _, _, msg, error in
                println(self.message.isDetailDownloaded)
                println(self.message.ccList)
                NSLog("\(__FUNCTION__) error: \(self.message)")
                if error != nil {
                    NSLog("\(__FUNCTION__) error: \(error)")
                }
                else
                {
                    //self.messageDetailView?.updateHeaderView()
                    //self.messageDetailView?.updateEmailBodyWebView(true)
                }
            }
        }
    }
    
    var emailView: EmailView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.emailView.updateHeaderData(self.message.subject)
            
        self.emailView.initLayouts()
    }
    
    override func loadView() {
        emailView = EmailView(message: message)
        self.view = emailView
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
