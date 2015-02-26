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

class MessageDetailView: UIView {
    
    var delegate: MessageDetailViewDelegate?
    let message: Message
    private var isShowingDetail: Bool = false
    
    // MARK: - Private constants
    
    private let kAnimationDuration: NSTimeInterval = 0.3
    private let kAnimationOption: UIViewAnimationOptions = .TransitionCrossDissolve
    private var kKVOContext = 0
    private let kScrollViewDistanceToBottom: CGFloat = -69.0
    private let kSeparatorBetweenHeaderAndBodyMarginTop: CGFloat = 16.0
    private let kSeparatorBetweenHeaderAndBodyMarginHeight: CGFloat = 1.0
    private let kSeparatorBetweenBodyViewAndFooterHeight: CGFloat = 1.0
    private let kEmailHeaderViewMarginTop: CGFloat = 12.0
    private let kEmailHeaderViewMarginLeft: CGFloat = 16.0
    private let kEmailHeaderViewMarginRight: CGFloat = -16.0
    private let kEmailHeaderViewHeight: CGFloat = 70.0
    private let kEmailTitleViewMarginRight: CGFloat = -8.0
    private let kEmailRecipientsViewMarginTop: CGFloat = 6.0
    private let kEmailTimeViewMarginTop: CGFloat = 6.0
    private let kEmailDetailToWidth: CGFloat = 40.0
    private let kEmailDetailCCLabelMarginTop: CGFloat = 10.0
    private let kEmailDetailDateLabelMarginTop: CGFloat = 10.0
    private let kEmailTimeLongFormat: String = "MMMM d, yyyy, h:mm a"
    private let kEmailDetailButtonMarginLeft: CGFloat = 5.0
    private let kEmailHasAttachmentsImageViewMarginRight: CGFloat = -4.0
    private let kEmailIsEncryptedImageViewMarginRight: CGFloat = -8.0
    private let kEmailBodyTextViewMarginLeft: CGFloat = 16.0
    private let kEmailBodyTextViewMarginRight: CGFloat = -16.0
    private let kEmailBodyTextViewMarginTop: CGFloat = 16.0
    private let kEmailBodyLineSpacing: CGFloat = 8.0
    private let kButtonsViewHeight: CGFloat = 68.0
    private let kReplyButtonMarginLeft: CGFloat = 50.0
    private let kReplyButtonMarginTop: CGFloat = 10.0
    private let kReplyButtonLabelMarginTop: CGFloat = 4.0
    private let kReplyAllButtonLabelMarginTop: CGFloat = 4.0
    private let kForwardButtonMarginRight: CGFloat = -50.0
    private let kForwardButtonLabelMarginTop: CGFloat = 4.0
    
    
    // MARK: - Email header views
    
    private var emailHeaderView: UIView!
    private var emailTitle: UILabel!
    private var emailRecipients: UILabel!
    private var emailTime: UILabel!
    private var emailDetailButton: UIButton!
    private var emailDetailView: UIView!
    private var emailDetailToLabel: UILabel!
    private var emailDetailToContentLabel: UILabel!
    private var emailDetailCCLabel: UILabel!
    private var emailDetailCCContentLabel: UILabel!
    private var emailDetailDateLabel: UILabel!
    private var emailDetailDateContentLabel: UILabel!
    private var emailFavoriteButton: UIButton!
    private var emailIsEncryptedImageView: UIImageView!
    private var emailHasAttachmentsImageView: UIImageView!
    private var emailAttachmentsAmount: UILabel!
    private var separatorBetweenHeaderAndBodyView: UIView!
    private var separatorBetweenBodyViewAndFooter: UIView!
    
    
    // MARK: - Email body views
    
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var emailBodyTextView: UILabel!
    
    
    // MARK: - Email footer views
    
    private var buttonsView: UIView!
    private var replyButton: UIButton!
    private var replyButtonLabel: UILabel!
    private var replyAllButton: UIButton!
    private var replyAllButtonLabel: UILabel!
    private var forwardButton: UIButton!
    private var forwardButtonLabel: UILabel!

    
    // MARK: - Init methods
    
    required init(message: Message) {
        self.message = message
        
        super.init(frame: CGRectZero)
        
        message.addObserver(self, forKeyPath: Message.Attributes.isDetailDownloaded, options: .New, context: &kKVOContext)
        
        self.backgroundColor = UIColor.whiteColor()
        self.addSubviews()
        self.makeConstraints()
        
        if (!message.hasAttachments) {
            self.emailHasAttachmentsImageView.hidden = true
            self.emailAttachmentsAmount.hidden = true
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        message.removeObserver(self, forKeyPath: Message.Attributes.isDetailDownloaded, context: &kKVOContext)
    }
    
    // MARK: - Public methods
    
    func updateEmailBodyView(animated: Bool) {
        let completion: ((Bool) -> Void) = { finished in
            if self.message.isDetailDownloaded {
                self.emailBodyTextView.text = self.message.body
            } else {
                self.emailBodyTextView.text = NSLocalizedString("Loading...")
            }
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = self.kEmailBodyLineSpacing
            
            let attributedString = NSMutableAttributedString(string: self.emailBodyTextView.text!)
            attributedString.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, countElements(self.emailBodyTextView.text!)))
            
            self.emailBodyTextView.attributedText = attributedString
            self.emailBodyTextView.sizeToFit()
            
            if animated {
                UIView.animateWithDuration(self.kAnimationDuration, animations: { () -> Void in
                    self.emailBodyTextView.alpha = 1.0
                })
            }
        }
        
        if animated {
            UIView.animateWithDuration(kAnimationDuration, animations: { () -> Void in
                self.emailBodyTextView.alpha = 0
            }, completion: completion)
        } else {
            completion(true)
        }
    }
    
    
    // MARK: - Subviews
    
    func addSubviews() {
        self.scrollView = UIScrollView()
        self.addSubview(scrollView)
        
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
        self.emailTitle.text = self.message.title
        self.emailTitle.textColor = UIColor.ProtonMail.Gray_383A3B
        self.emailHeaderView.addSubview(emailTitle)
        
        self.emailRecipients = UILabel()
        self.emailRecipients.font = UIFont.robotoRegular(size: UIFont.Size.h6)
        self.emailRecipients.numberOfLines = 1
        self.emailRecipients.text = "To \(self.message.recipientList)"
        self.emailRecipients.textColor = UIColor.ProtonMail.Gray_999DA1
        self.emailHeaderView.addSubview(emailRecipients)
        
        self.emailTime = UILabel()
        self.emailTime.font = UIFont.robotoMediumItalic(size: UIFont.Size.h6)
        self.emailTime.numberOfLines = 1
        
        let hourMinuteFormat = "h:mma"

        if let messageTime = self.message.time {
            self.emailTime.text = "at \(messageTime.stringWithFormat(hourMinuteFormat))".lowercaseString
        } else {
            self.emailTime.text = ""
        }
        
        self.emailTime.textColor = UIColor.ProtonMail.Gray_999DA1
        self.emailTime.sizeToFit()
        self.emailHeaderView.addSubview(emailTime)
        
        self.emailDetailButton = UIButton()
        self.emailDetailButton.addTarget(self, action: "detailsButtonTapped", forControlEvents: UIControlEvents.TouchUpInside)
        self.emailDetailButton.contentEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
        self.emailDetailButton.titleLabel?.font = UIFont.robotoRegular(size: UIFont.Size.h6)
        self.emailDetailButton.setTitle(NSLocalizedString("Details"), forState: UIControlState.Normal)
        self.emailDetailButton.setTitleColor(UIColor.ProtonMail.Blue_85B1DE, forState: UIControlState.Normal)
        self.emailDetailButton.sizeToFit()
        self.emailHeaderView.addSubview(emailDetailButton)
        
        self.configureEmailDetailToLabel()
        self.configureEmailDetailCCLabel()
        self.configureEmailDetailDateLabel()
        
        self.emailFavoriteButton = UIButton()
        var favoriteImage: UIImage
        if (self.message.isStarred) {
            favoriteImage = UIImage(named: "favorite_selected")!
        } else {
            favoriteImage = UIImage(named: "favorite")!
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
        self.emailAttachmentsAmount.text = "\(self.message.attachments.count)"
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
        self.addSubview(separatorBetweenBodyViewAndFooter)
    }
    
    private func createEmailBodyView() {
        self.emailBodyTextView = UILabel()
        self.contentView.addSubview(emailBodyTextView)
        self.emailBodyTextView.font = UIFont.robotoLight(size: UIFont.Size.h5)
        self.emailBodyTextView.numberOfLines = 0
        self.emailBodyTextView.textColor = UIColor.ProtonMail.Gray_383A3B
        
        updateEmailBodyView(false)
    }

    private func createFooterView() {
        self.buttonsView = UIView()
        self.buttonsView.backgroundColor = UIColor.ProtonMail.Gray_E8EBED
        self.addSubview(buttonsView)
        
        self.replyButton = UIButton()
        self.replyButton.addTarget(self, action: "replyButtonTapped", forControlEvents: UIControlEvents.TouchUpInside)
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
        self.replyAllButton.addTarget(self, action: "replyAllButtonTapped", forControlEvents: UIControlEvents.TouchUpInside)
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
        self.forwardButton.addTarget(self, action: "forwardButtonTapped", forControlEvents: UIControlEvents.TouchUpInside)
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
    
    
    // MARK: - Subview constraints
    
    func makeConstraints() {
        scrollView.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self)
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.bottom.equalTo()(self).with().offset()(self.kScrollViewDistanceToBottom)
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
            make.top.equalTo()(self.emailHeaderView.mas_bottom).with().offset()(self.kSeparatorBetweenHeaderAndBodyMarginTop)
            make.height.equalTo()(self.kSeparatorBetweenHeaderAndBodyMarginHeight)
        }
        
        separatorBetweenBodyViewAndFooter.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.bottom.equalTo()(self.buttonsView.mas_top)
            make.height.equalTo()(self.kSeparatorBetweenBodyViewAndFooterHeight)
        }
    }
    
    private func makeHeaderConstraints() {
        emailHeaderView.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.contentView).with().offset()(self.kEmailHeaderViewMarginTop)
            make.left.equalTo()(self.contentView).with().offset()(self.kEmailHeaderViewMarginLeft)
            make.right.equalTo()(self.contentView).with().offset()(self.kEmailHeaderViewMarginRight)
            make.bottom.equalTo()(self.emailDetailView)
        }
        
        emailTitle.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.emailHeaderView)
            make.top.equalTo()(self.emailHeaderView)
            make.right.equalTo()(self.emailFavoriteButton.mas_left).with().offset()(self.kEmailTitleViewMarginRight)
        }
        
        emailRecipients.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.emailHeaderView)
            make.right.equalTo()(self.emailTitle)
            make.top.equalTo()(self.emailTitle.mas_bottom).with().offset()(self.kEmailRecipientsViewMarginTop)
        }
        
        emailTime.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.emailHeaderView)
            make.width.equalTo()(self.emailTime.frame.size.width)
            make.height.equalTo()(self.emailTime.frame.size.height)
            make.top.equalTo()(self.emailRecipients.mas_bottom).with().offset()(self.kEmailTimeViewMarginTop)
        }
        
        emailDetailButton.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.emailTime.mas_right).with().offset()(self.kEmailDetailButtonMarginLeft)
            make.bottom.equalTo()(self.emailTime)
            make.top.equalTo()(self.emailTime)
            make.width.equalTo()(self.emailDetailButton)
        }
        
        emailDetailView.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.emailTitle)
            make.right.equalTo()(self.emailHeaderView)
            make.top.equalTo()(self.emailDetailButton.mas_bottom)
            make.height.equalTo()(0)
        }
        
        emailDetailToLabel.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.emailDetailView)
            make.left.equalTo()(self.emailDetailView)
            make.width.equalTo()(self.kEmailDetailToWidth)
            make.height.equalTo()(self.emailDetailToLabel.frame.size.height)
        }
        
        emailDetailToContentLabel.mas_makeConstraints { (make) -> Void in
            make.centerY.equalTo()(self.emailDetailToLabel)
            make.left.equalTo()(self.emailDetailToLabel.mas_right)
            make.right.equalTo()(self.emailDetailView)
            make.height.equalTo()(self.emailDetailToContentLabel.frame.size.height)
        }
        
        emailDetailCCLabel.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.emailDetailToLabel)
            make.top.equalTo()(self.emailDetailToLabel.mas_bottom).with().offset()(self.kEmailDetailCCLabelMarginTop)
            make.width.equalTo()(self.emailDetailToLabel)
            make.height.equalTo()(self.emailDetailCCLabel.frame.size.height)
        }
        
        emailDetailCCContentLabel.mas_makeConstraints { (make) -> Void in
            make.centerY.equalTo()(self.emailDetailCCLabel)
            make.left.equalTo()(self.emailDetailCCLabel.mas_right)
            make.right.equalTo()(self.emailDetailView)
            make.height.equalTo()(self.emailDetailCCContentLabel.frame.size.height)
        }
        
        emailDetailDateLabel.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.emailDetailToLabel)
            make.top.equalTo()(self.emailDetailCCLabel.mas_bottom).with().offset()(self.kEmailDetailDateLabelMarginTop)
            make.width.equalTo()(self.emailDetailToLabel)
            make.height.equalTo()(self.emailDetailCCLabel.frame.size.height)
        }
        
        emailDetailDateContentLabel.mas_makeConstraints { (make) -> Void in
            make.centerY.equalTo()(self.emailDetailDateLabel)
            make.left.equalTo()(self.emailDetailDateLabel.mas_right)
            make.right.equalTo()(self.emailDetailView)
            make.height.equalTo()(self.emailDetailDateLabel.frame.size.height)
        }
        
        emailFavoriteButton.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.emailTitle)
            make.right.equalTo()(self.emailHeaderView)
            make.height.equalTo()(self.emailFavoriteButton.frame.size.height)
            make.width.equalTo()(self.emailFavoriteButton.frame.size.width)
        }
        
        emailAttachmentsAmount.mas_makeConstraints { (make) -> Void in
            make.right.equalTo()(self.emailHeaderView)
            make.bottom.equalTo()(self.emailDetailButton)
            make.height.equalTo()(self.emailAttachmentsAmount.frame.height)
            make.width.equalTo()(self.emailAttachmentsAmount.frame.width)
        }
        
        emailHasAttachmentsImageView.mas_makeConstraints { (make) -> Void in
            make.right.equalTo()(self.emailAttachmentsAmount.mas_left).with().offset()(self.kEmailHasAttachmentsImageViewMarginRight)
            make.bottom.equalTo()(self.emailAttachmentsAmount)
            make.height.equalTo()(self.emailHasAttachmentsImageView.frame.height)
            make.width.equalTo()(self.emailHasAttachmentsImageView.frame.width)
        }
        
        emailIsEncryptedImageView.mas_makeConstraints { (make) -> Void in
            if (self.message.hasAttachments) {
                make.right.equalTo()(self.emailHasAttachmentsImageView.mas_left).with().offset()(self.kEmailIsEncryptedImageViewMarginRight)
            } else {
                make.right.equalTo()(self.emailHeaderView)
            }
            
            make.bottom.equalTo()(self.emailAttachmentsAmount)
            make.height.equalTo()(self.emailIsEncryptedImageView.frame.height)
            make.width.equalTo()(self.emailIsEncryptedImageView.frame.width)
        }
    }
    
    private func makeEmailBodyConstraints() {
        emailBodyTextView.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.contentView).with().offset()(self.kEmailBodyTextViewMarginLeft)
            make.right.equalTo()(self.contentView).with().offset()(self.kEmailBodyTextViewMarginRight)
            make.top.equalTo()(self.separatorBetweenHeaderAndBodyView.mas_bottom).with().offset()(self.kEmailBodyTextViewMarginTop)
        }
    }
    
    private func makeFooterConstraints() {
        buttonsView.mas_makeConstraints { (make) -> Void in
            make.bottom.equalTo()(self)
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.height.equalTo()(self.kButtonsViewHeight)
        }
        
        replyButton.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.buttonsView).with().offset()(self.kReplyButtonMarginLeft)
            make.top.equalTo()(self.buttonsView).with().offset()(self.kReplyButtonMarginTop)
            make.height.equalTo()(self.replyButton.frame.size.height)
            make.width.equalTo()(self.replyButton.frame.size.width)
        }
        
        replyButtonLabel.mas_makeConstraints { (make) -> Void in
            make.centerX.equalTo()(self.replyButton)
            make.top.equalTo()(self.replyButton.mas_bottom).with().offset()(self.kReplyButtonLabelMarginTop)
        }
        
        replyAllButton.mas_makeConstraints { (make) -> Void in
            make.centerX.equalTo()(self)
            make.top.equalTo()(self.replyButton)
            make.height.equalTo()(self.replyAllButton.frame.size.height)
            make.width.equalTo()(self.replyAllButton.frame.size.width)
        }
        
        replyAllButtonLabel.mas_makeConstraints { (make) -> Void in
            make.centerX.equalTo()(self.replyAllButton)
            make.top.equalTo()(self.replyAllButton.mas_bottom).with().offset()(self.kReplyAllButtonLabelMarginTop)
        }
        
        forwardButton.mas_makeConstraints { (make) -> Void in
            make.right.equalTo()(self.buttonsView).with().offset()(self.kForwardButtonMarginRight)
            make.top.equalTo()(self.replyButton)
            make.height.equalTo()(self.forwardButton.frame.size.height)
            make.width.equalTo()(self.forwardButton.frame.size.width)
        }
        
        forwardButtonLabel.mas_makeConstraints { (make) -> Void in
            make.centerX.equalTo()(self.forwardButton)
            make.top.equalTo()(self.forwardButton.mas_bottom).with().offset()(self.kForwardButtonLabelMarginTop)
        }
    }
    
    
    // MARK: - Button actions
    
    internal func detailsButtonTapped() {
        self.isShowingDetail = !self.isShowingDetail

        if (isShowingDetail) {
            UIView.transitionWithView(self.emailRecipients, duration: kAnimationDuration, options: kAnimationOption, animations: { () -> Void in
                self.emailRecipients.text = self.message.sender
            }, completion: nil)
            
            self.emailDetailButton.setTitle(NSLocalizedString("Hide Details"), forState: UIControlState.Normal)
            self.emailDetailButton.mas_updateConstraints({ (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailTime)
                make.bottom.equalTo()(self.emailTime)
                make.top.equalTo()(self.emailTime)
                make.width.equalTo()(self.emailDetailButton)
            })
            
            self.emailTime.mas_updateConstraints({ (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailHeaderView)
                make.width.equalTo()(0)
                make.height.equalTo()(self.emailTime.frame.size.height)
                make.top.equalTo()(self.emailRecipients.mas_bottom).with().offset()(self.kEmailTimeViewMarginTop)
            })
            
            self.emailDetailView.mas_updateConstraints({ (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailTitle)
                make.right.equalTo()(self.emailHeaderView)
                make.top.equalTo()(self.emailDetailButton.mas_bottom).with().offset()(10)
                make.bottom.equalTo()(self.emailDetailDateLabel)
            })
        } else {
            UIView.transitionWithView(self.emailRecipients, duration: kAnimationDuration, options: kAnimationOption, animations: { () -> Void in
                self.emailRecipients.text = "To \(self.message.recipientList)"
                }, completion: nil)
            
            self.emailDetailButton.setTitle(NSLocalizedString("Details"), forState: UIControlState.Normal)
            self.emailDetailButton.mas_updateConstraints({ (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailTime.mas_right).with().offset()(self.kEmailDetailButtonMarginLeft)
                make.bottom.equalTo()(self.emailTime)
                make.top.equalTo()(self.emailTime)
                make.width.equalTo()(self.emailDetailButton)
            })

            self.emailTime.sizeToFit()
            self.emailTime.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailHeaderView)
                make.width.equalTo()(self.emailTime.frame.size.width)
                make.height.equalTo()(self.emailTime.frame.size.height)
                make.top.equalTo()(self.emailRecipients.mas_bottom).with().offset()(self.kEmailTimeViewMarginTop)
            }
            
            self.emailDetailView.mas_updateConstraints({ (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailTitle)
                make.right.equalTo()(self.emailHeaderView)
                make.top.equalTo()(self.emailDetailButton.mas_bottom)
                make.height.equalTo()(0)
            })
        }
        
        UIView.animateWithDuration(kAnimationDuration, animations: { () -> Void in
            self.layoutIfNeeded()
        })
    }
    
    internal func replyButtonTapped() {
        self.delegate?.messageDetailViewDidTapReplyMessage(self, message: message)
    }
    
    internal func replyAllButtonTapped() {
        self.delegate?.messageDetailViewDidTapReplyAllMessage(self, message: message)
    }
    
    internal func forwardButtonTapped() {
        self.delegate?.messageDetailViewDidTapForwardMessage(self, message: message)
    }
    
    
    // MARK: - Private methods
    
    private func configureEmailDetailToLabel() {
        self.emailDetailView = UIView()
        self.emailDetailView.clipsToBounds = true
        self.emailHeaderView.addSubview(emailDetailView)
        
        self.emailDetailToLabel = UILabel()
        self.emailDetailToLabel.font = UIFont.robotoLight(size: UIFont.Size.h5)
        self.emailDetailToLabel.numberOfLines = 1
        self.emailDetailToLabel.text = "To:"
        self.emailDetailToLabel.textColor = UIColor.ProtonMail.Gray_999DA1
        self.emailDetailToLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailToLabel)
        
        self.emailDetailToContentLabel = UILabel()
        self.emailDetailToContentLabel.font = UIFont.robotoRegular(size: UIFont.Size.h5)
        self.emailDetailToContentLabel.numberOfLines = 1
        self.emailDetailToContentLabel.text = "\(message.recipientNameList)"
        self.emailDetailToContentLabel.textColor = UIColor.ProtonMail.Blue_85B1DE
        self.emailDetailToContentLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailToContentLabel)
    }
    
    private func configureEmailDetailCCLabel() {
        self.emailDetailCCLabel = UILabel()
        self.emailDetailCCLabel.font = UIFont.robotoLight(size: UIFont.Size.h5)
        self.emailDetailCCLabel.numberOfLines = 1
        self.emailDetailCCLabel.text = "Cc:"
        self.emailDetailCCLabel.textColor = UIColor.ProtonMail.Gray_999DA1
        self.emailDetailCCLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailCCLabel)
        
        self.emailDetailCCContentLabel = UILabel()
        self.emailDetailCCContentLabel.font = UIFont.robotoRegular(size: UIFont.Size.h5)
        self.emailDetailCCContentLabel.numberOfLines = 1
        self.emailDetailCCContentLabel.text = message.ccNameList
        self.emailDetailCCContentLabel.textColor = UIColor.ProtonMail.Blue_85B1DE
        self.emailDetailCCContentLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailCCContentLabel)
    }
    
    private func configureEmailDetailDateLabel() {
        self.emailDetailDateLabel = UILabel()
        self.emailDetailDateLabel.font = UIFont.robotoLight(size: UIFont.Size.h5)
        self.emailDetailDateLabel.numberOfLines = 1
        self.emailDetailDateLabel.text = "Date:"
        self.emailDetailDateLabel.textColor = UIColor.ProtonMail.Gray_999DA1
        self.emailDetailDateLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailDateLabel)
        
        self.emailDetailDateContentLabel = UILabel()
        self.emailDetailDateContentLabel.font = UIFont.robotoRegular(size: UIFont.Size.h5)
        self.emailDetailDateContentLabel.numberOfLines = 1
        self.emailDetailDateContentLabel.text = message.time!.stringWithFormat(kEmailTimeLongFormat)
        self.emailDetailDateContentLabel.textColor = UIColor.ProtonMail.Gray_383A3B
        self.emailDetailDateContentLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailDateContentLabel)
    }
    
    // MARK: - KVO
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if context != &kKVOContext {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        } else if object as NSObject == message && keyPath == Message.Attributes.isDetailDownloaded {
            updateEmailBodyView(true)
        }
    }
}

// MARK: - View Delegate

protocol MessageDetailViewDelegate {
    func messageDetailViewDidTapForwardMessage(messageDetailView: MessageDetailView, message: Message)
    func messageDetailViewDidTapReplyMessage(messageDetailView: MessageDetailView, message: Message)
    func messageDetailViewDidTapReplyAllMessage(messageDetailView: MessageDetailView, message: Message)
}