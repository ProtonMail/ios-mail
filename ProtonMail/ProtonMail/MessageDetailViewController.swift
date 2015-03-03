//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import UIKit

class MessageDetailViewController: ProtonMailViewController {
    
    var message: Message! {
        didSet {
            message.fetchDetailIfNeeded() { _, _, error in
                if error != nil {
                    NSLog("\(__FUNCTION__) error: \(error)")
                }
            }
        }
    }
    
    @IBOutlet var messageDetailView: MessageDetailView!
    
    override func loadView() {
        messageDetailView = MessageDetailView(message: message)
        messageDetailView.delegate = self
        
        self.view = messageDetailView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupRightButtons()
    }
    
    override func shouldShowSideMenu() -> Bool {
        return false
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        message.isRead = true
    }
    
    private func setupRightButtons() {
        var rightButtons: [UIBarButtonItem]
        
        let removeBarButtonItem = UIBarButtonItem(image: UIImage(named: "trash_selected"), style: UIBarButtonItemStyle.Plain, target: self, action: "removeButtonTapped")
        let spamBarButtonItem = UIBarButtonItem(image: UIImage(named: "spam_selected"), style: UIBarButtonItemStyle.Plain, target: self, action: "spamButtonTapped")
        let moreBarButtonItem = UIBarButtonItem(image: UIImage(named: "arrow_down"), style: UIBarButtonItemStyle.Plain, target: self, action: "moreButtonTapped")
        
        rightButtons = [moreBarButtonItem, spamBarButtonItem, removeBarButtonItem]
        self.navigationItem.setRightBarButtonItems(rightButtons, animated: true)
    }
    
    func removeButtonTapped() {
        println("removeButtonTapped: \(message.title)")
    }
    
    func spamButtonTapped() {
        println("spamButtonTapped: \(message.title)")
    }
    
    func moreButtonTapped() {
        println("moreButtonTapped: \(message.title)")
    }
}

extension MessageDetailViewController: MessageDetailViewDelegate {
    
    func messageDetailViewDidTapForwardMessage(messageView: MessageDetailView, message: Message) {
        println("messageDetailViewDidTapForwardMessage: \(message.title)")
    }
    
    func messageDetailViewDidTapReplyAllMessage(messageView: MessageDetailView, message: Message) {
        println("messageDetailViewDidTapReplyAllMessage: \(message.title)")
    }
    
    func messageDetailViewDidTapReplyMessage(messageView: MessageDetailView, message: Message) {
        println("messageDetailViewDidTapReplyMessage: \(message.title)")
    }
}