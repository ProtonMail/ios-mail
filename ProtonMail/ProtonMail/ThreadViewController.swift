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

class ThreadViewController: ProtonMailViewController {
    
    var emailThread: EmailThread!
    
    // header
    private var emailHeaderView: UIView!
    private var emailTitle: UILabel!
    private var emailRecipients: UILabel!
    private var emailTime: UILabel!
    private var emailFavoriteButton: UIButton!
    private var emailIsEncryptedImageView: UIImageView!
    private var emailHasAttachmentsImageView: UIImageView!
    private var emailAttachmentsAmount: UILabel!
    private var separatorBetweenHeaderAndBodyView: UIView!
    private var separatorBetweenBodyViewAndFooter: UIView!

    // body
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var emailBodyTextView: UILabel!
    
    // footer
    private var buttonsView: UIView!
    private var replyButton: UIButton!
    private var replyButtonLabel: UILabel!
    private var replyAllButton: UIButton!
    private var replyAllButtonLabel: UILabel!
    private var forwardButton: UIButton!
    private var forwardButtonLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupRightButtons()
        self.addSubviews()
        self.makeConstraints()
    }
    
    func addSubviews() {
        self.scrollView = UIScrollView()
        self.view.addSubview(scrollView)
        
        self.contentView = UIView()
        self.scrollView.addSubview(contentView)
        
        self.createHeaderView()
        self.createSeparator()
        self.createEmailBodyView()
        self.createFooterView()
    }
    
    private func createHeaderView() {
        self.emailHeaderView = UIView()
        self.contentView.addSubview(emailHeaderView)
        
        self.emailTitle = UILabel()
        self.emailTitle.font = UIFont.robotoLight(size: UIFont.Size.h1)
        self.emailTitle.numberOfLines = 1
        self.emailTitle.text = self.emailThread.title
        self.emailTitle.textColor = UIColor.ProtonMail.Gray_383A3B
        self.emailHeaderView.addSubview(emailTitle)
        
        self.emailRecipients = UILabel()
        self.emailRecipients.font = UIFont.robotoRegular(size: UIFont.Size.h6)
        self.emailRecipients.numberOfLines = 1
        self.emailRecipients.text = "To \(self.emailThread.sender)"
        self.emailRecipients.textColor = UIColor.ProtonMail.Gray_999DA1
        self.emailHeaderView.addSubview(emailRecipients)
        
        self.emailTime = UILabel()
        self.emailTime.font = UIFont.robotoLight(size: UIFont.Size.h6)
        self.emailTime.numberOfLines = 1
        self.emailTime.text = "at \(self.emailThread.time)"
        self.emailTime.textColor = UIColor.ProtonMail.Gray_999DA1
        self.emailTime.sizeToFit()
        self.emailHeaderView.addSubview(emailTime)
        
        self.emailFavoriteButton = UIButton()
        var favoriteImage: UIImage
        if (self.emailThread.isFavorite) {
            favoriteImage = UIImage(named: "favorite_main_selected")!
        } else {
            favoriteImage = UIImage(named: "favorite_main")!
        }
        
        self.emailFavoriteButton.setImage(favoriteImage, forState: UIControlState.Normal)
        self.emailFavoriteButton.sizeToFit()
        self.emailHeaderView.addSubview(emailFavoriteButton)
        
        self.emailIsEncryptedImageView = UIImageView(image: UIImage(named: "encrypted_main"))
        self.emailIsEncryptedImageView.contentMode = UIViewContentMode.Center
        self.emailIsEncryptedImageView.sizeToFit()
        self.emailHeaderView.addSubview(emailIsEncryptedImageView)
        
        self.emailHasAttachmentsImageView = UIImageView(image: UIImage(named: "attached_compose"))
        self.emailHasAttachmentsImageView.contentMode = UIViewContentMode.Center
        self.emailHasAttachmentsImageView.sizeToFit()
        self.emailHeaderView.addSubview(emailHasAttachmentsImageView)
        
        self.emailAttachmentsAmount = UILabel()
        self.emailAttachmentsAmount.font = UIFont.robotoRegular(size: UIFont.Size.h4)
        self.emailAttachmentsAmount.numberOfLines = 1
        self.emailAttachmentsAmount.text = "2"
        self.emailAttachmentsAmount.textColor = UIColor.ProtonMail.Gray_999DA1
        self.emailAttachmentsAmount.sizeToFit()
        self.emailHeaderView.addSubview(emailAttachmentsAmount)
    }
    
    private func createSeparator() {
        self.separatorBetweenHeaderAndBodyView = UIView()
        self.separatorBetweenHeaderAndBodyView.backgroundColor = UIColor.ProtonMail.Gray_C9CED4
        self.contentView.addSubview(separatorBetweenHeaderAndBodyView)
        
        self.separatorBetweenBodyViewAndFooter = UIView()
        self.separatorBetweenBodyViewAndFooter.backgroundColor = UIColor.ProtonMail.Gray_C9CED4
        self.view.addSubview(separatorBetweenBodyViewAndFooter)
    }
    
    private func createEmailBodyView() {
        self.emailBodyTextView = UILabel()
        self.emailBodyTextView.numberOfLines = 0
        self.contentView.addSubview(emailBodyTextView)
        
        self.emailBodyTextView.text = "BEGIN\n\nLorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.\nLorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum comes from sections 1.10.32 and 1.10.33 of 'de Finibus Bonorum et Malorum (The Extremes of Good and Evil) by Cicero, written in 45 BC. This book is a treatise on the theory of ethics, very popular during the Renaissance. The first line of Lorem Ipsum, 'Lorem ipsum dolor sit amet..', comes from a line in section 1.10.32. The standard chunk of Lorem Ipsum used since the 1500s is reproduced below for those interested. Sections 1.10.32 and 1.10.33 from 'de Finibus Bonorum et Malorum' by Cicero are also reproduced in their exact original form, accompanied by English versions from the 1914 translation by H. Rackham. It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout. The point of using Lorem Ipsum is that it has a more-or-less normal distribution of letters, as opposed to using 'Content here, content here', making it look like readable English. Many desktop publishing packages and web page editors now use Lorem Ipsum as their default model text, and a search for 'lorem ipsum' will uncover many web sites still in their infancy. Various versions have evolved over the years, sometimes by accident, sometimes on purpose (injected humour and the like). There are many variations of passages of Lorem Ipsum available, but the majority have suffered alteration in some form, by injected humour, or randomised words which don't look even slightly believable. If you are going to use a passage of Lorem Ipsum, you need to be sure there isn't anything embarrassing hidden in the middle of text. All the Lorem Ipsum generators on the Internet tend to repeat predefined chunks as necessary, making this the first true generator on the Internet. It uses a dictionary of over 200 Latin words, combined with a handful of model sentence structures, to generate Lorem Ipsum which looks reasonable. The generated Lorem Ipsum is therefore always free from repetition, injected humour, or non-characteristic words etc.\n\nEND"
        
        self.emailBodyTextView.sizeToFit()
    }
    
    private func createFooterView() {
        self.buttonsView = UIView()
        self.buttonsView.backgroundColor = UIColor.ProtonMail.Gray_E8EBED
        self.view.addSubview(buttonsView)
        
        self.replyButton = UIButton()
        self.replyButton.setImage(UIImage(named: "reply"), forState: UIControlState.Normal)
        self.replyButton.sizeToFit()
        self.buttonsView.addSubview(replyButton)
        
        self.replyButtonLabel = UILabel()
        self.replyButtonLabel.font = UIFont.robotoLight(size: UIFont.Size.h6)
        self.replyButtonLabel.numberOfLines = 1
        self.replyButtonLabel.text = NSLocalizedString("Reply")
        self.replyButtonLabel.textColor = UIColor.ProtonMail.Blue_6789AB
        self.replyButtonLabel.sizeToFit()
        self.buttonsView.addSubview(replyButtonLabel)

        self.replyAllButton = UIButton()
        self.replyAllButton.setImage(UIImage(named: "replyall"), forState: UIControlState.Normal)
        self.replyAllButton.sizeToFit()
        self.buttonsView.addSubview(replyAllButton)
        
        self.replyAllButtonLabel = UILabel()
        self.replyAllButtonLabel.font = UIFont.robotoLight(size: UIFont.Size.h6)
        self.replyAllButtonLabel.numberOfLines = 1
        self.replyAllButtonLabel.text = NSLocalizedString("Reply All")
        self.replyAllButtonLabel.textColor = UIColor.ProtonMail.Blue_6789AB
        self.replyAllButtonLabel.sizeToFit()
        self.buttonsView.addSubview(replyAllButtonLabel)
        
        self.forwardButton = UIButton()
        self.forwardButton.setImage(UIImage(named: "forward"), forState: UIControlState.Normal)
        self.forwardButton.sizeToFit()
        self.buttonsView.addSubview(forwardButton)
        
        self.forwardButtonLabel = UILabel()
        self.forwardButtonLabel.font = UIFont.robotoLight(size: UIFont.Size.h6)
        self.forwardButtonLabel.numberOfLines = 1
        self.forwardButtonLabel.text = NSLocalizedString("Forward")
        self.forwardButtonLabel.textColor = UIColor.ProtonMail.Blue_6789AB
        self.forwardButtonLabel.sizeToFit()
        self.buttonsView.addSubview(forwardButtonLabel)
        
        // to fix scroll view dynamic height
        var scrollWorkaroundView = UIView()
        self.scrollView.addSubview(scrollWorkaroundView)
        scrollWorkaroundView.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.emailBodyTextView.mas_bottom)
            make.bottom.equalTo()(self.contentView)
        }
    }
    
    func makeConstraints() {
        scrollView.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.view)
            make.left.equalTo()(self.view)
            make.right.equalTo()(self.view)
            make.bottom.equalTo()(self.view).with().offset()(-69)
        }
        
        contentView.mas_makeConstraints { (make) -> Void in
            make.edges.equalTo()(self.scrollView)
            make.width.equalTo()(self.scrollView)
        }
        
        self.makeHeaderConstraints()
        self.makeEmailBodyConstraints()
        self.makeFooterConstraints()
        
        
        separatorBetweenHeaderAndBodyView.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.contentView)
            make.right.equalTo()(self.contentView)
            make.top.equalTo()(self.emailHeaderView.mas_bottom).with().offset()(16)
            make.height.equalTo()(1)
        }
        
        separatorBetweenBodyViewAndFooter.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.view)
            make.right.equalTo()(self.view)
            make.bottom.equalTo()(self.buttonsView.mas_top)
            make.height.equalTo()(1)
        }
    }
    
    private func makeHeaderConstraints() {
        emailHeaderView.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.contentView).with().offset()(12)
            make.left.equalTo()(self.contentView).with().offset()(16)
            make.right.equalTo()(self.contentView).with().offset()(-16)
            make.height.equalTo()(70)
        }
        
        emailTitle.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.emailHeaderView)
            make.top.equalTo()(self.emailHeaderView)
            make.right.equalTo()(self.emailFavoriteButton.mas_left).with().offset()(-8)
        }
        
        emailRecipients.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.emailHeaderView)
            make.right.equalTo()(self.emailTitle)
            make.top.equalTo()(self.emailTitle.mas_bottom).with().offset()(6)
        }
        
        emailTime.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.emailHeaderView)
            make.width.equalTo()(self.emailTime.frame.size.width)
            make.top.equalTo()(self.emailRecipients.mas_bottom).with().offset()(6)
        }
        
        emailFavoriteButton.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.emailTitle)
            make.right.equalTo()(self.emailHeaderView)
            make.height.equalTo()(self.emailFavoriteButton.frame.size.height)
            make.width.equalTo()(self.emailFavoriteButton.frame.size.width)
        }
        
        emailAttachmentsAmount.mas_makeConstraints { (make) -> Void in
            make.right.equalTo()(self.emailHeaderView)
            make.bottom.equalTo()(self.separatorBetweenHeaderAndBodyView.mas_top).with().offset()(-16)
            make.height.equalTo()(self.emailAttachmentsAmount.frame.height)
            make.width.equalTo()(self.emailAttachmentsAmount.frame.width)
        }

        emailHasAttachmentsImageView.mas_makeConstraints { (make) -> Void in
            make.right.equalTo()(self.emailAttachmentsAmount.mas_left).with().offset()(-4)
            make.bottom.equalTo()(self.emailAttachmentsAmount)
            make.height.equalTo()(self.emailHasAttachmentsImageView.frame.height)
            make.width.equalTo()(self.emailHasAttachmentsImageView.frame.width)
        }
        
        emailIsEncryptedImageView.mas_makeConstraints { (make) -> Void in
            make.right.equalTo()(self.emailHasAttachmentsImageView.mas_left).with().offset()(-8)
            make.bottom.equalTo()(self.emailAttachmentsAmount)
            make.height.equalTo()(self.emailIsEncryptedImageView.frame.height)
            make.width.equalTo()(self.emailIsEncryptedImageView.frame.width)
        }
    }
    
    private func makeEmailBodyConstraints() {
        emailBodyTextView.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.contentView).with().offset()(16)
            make.right.equalTo()(self.contentView).with().offset()(-16)
            make.top.equalTo()(self.separatorBetweenHeaderAndBodyView.mas_bottom).with().offset()(16)
        }
    }
    
    private func makeFooterConstraints() {
        buttonsView.mas_makeConstraints { (make) -> Void in
            make.bottom.equalTo()(self.view)
            make.left.equalTo()(self.view)
            make.right.equalTo()(self.view)
            make.height.equalTo()(68)
        }
        
        replyButton.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.buttonsView).with().offset()(50)
            make.top.equalTo()(self.buttonsView).with().offset()(10)
            make.height.equalTo()(self.replyButton.frame.size.height)
            make.width.equalTo()(self.replyButton.frame.size.width)
        }
        
        replyButtonLabel.mas_makeConstraints { (make) -> Void in
            make.centerX.equalTo()(self.replyButton)
            make.top.equalTo()(self.replyButton.mas_bottom).with().offset()(4)
        }
        
        replyAllButton.mas_makeConstraints { (make) -> Void in
            make.centerX.equalTo()(self.view)
            make.top.equalTo()(self.replyButton)
            make.height.equalTo()(self.replyAllButton.frame.size.height)
            make.width.equalTo()(self.replyAllButton.frame.size.width)
        }
        
        replyAllButtonLabel.mas_makeConstraints { (make) -> Void in
            make.centerX.equalTo()(self.replyAllButton)
            make.top.equalTo()(self.replyAllButton.mas_bottom).with().offset()(4)
        }
        
        forwardButton.mas_makeConstraints { (make) -> Void in
            make.right.equalTo()(self.buttonsView).with().offset()(-50)
            make.top.equalTo()(self.replyButton)
            make.height.equalTo()(self.forwardButton.frame.size.height)
            make.width.equalTo()(self.forwardButton.frame.size.width)
        }
        
        forwardButtonLabel.mas_makeConstraints { (make) -> Void in
            make.centerX.equalTo()(self.forwardButton)
            make.top.equalTo()(self.forwardButton.mas_bottom).with().offset()(4)
        }
    }
    
    override func shouldShowSideMenu() -> Bool {
        return false
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
        
    }
    
    func spamButtonTapped() {
        
    }
    
    func moreButtonTapped() {
            
    }
}