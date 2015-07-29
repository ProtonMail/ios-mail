//
//  EmailHeaderView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/27/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

protocol EmailHeaderViewProtocol {
    func updateSize()
}


class EmailHeaderView: UIView {
    
    var delegate: EmailHeaderViewProtocol?
    
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
    private var emailDetailBCCLabel: UILabel!
    private var emailDetailBCCContentLabel: UILabel!
    
    private var emailDetailDateLabel: UILabel!
    private var emailDetailDateContentLabel: UILabel!
    private var emailFavoriteButton: UIButton!
    private var emailIsEncryptedImageView: UIImageView!
    private var emailHasAttachmentsImageView: UIImageView!
    private var emailAttachmentsAmount: UILabel!
    private var separatorBetweenHeaderAndBodyView: UIView!
    private var separatorBetweenBodyViewAndFooter: UIView!
    
    
    //
    private let kEmailHeaderViewMarginTop: CGFloat = 12.0
    private let kEmailHeaderViewMarginLeft: CGFloat = 16.0
    private let kEmailHeaderViewMarginRight: CGFloat = -16.0
    private let kEmailHeaderViewHeight: CGFloat = 70.0
    private let kEmailTitleViewMarginRight: CGFloat = -8.0
    private let kEmailFavoriteButtonHeight: CGFloat = 24.5
    private let kEmailFavoriteButtonWidth: CGFloat = 26
    private let kEmailRecipientsViewMarginTop: CGFloat = 6.0
    private let kEmailTimeViewMarginTop: CGFloat = 6.0
    private let kEmailDetailToWidth: CGFloat = 40.0
    private let kEmailDetailCCLabelMarginTop: CGFloat = 10.0
    private let kEmailDetailDateLabelMarginTop: CGFloat = 10.0
    private let kEmailTimeLongFormat: String = "MMMM d, yyyy, h:mm a"
    private let kEmailDetailButtonMarginLeft: CGFloat = 5.0
    private let kEmailHasAttachmentsImageViewMarginRight: CGFloat = -4.0
    private let kEmailIsEncryptedImageViewMarginRight: CGFloat = -8.0
    private let kEmailBodyTextViewMarginLeft: CGFloat = 0//-16.0
    private let kEmailBodyTextViewMarginRight: CGFloat = 0//-16.0
    private let kEmailBodyTextViewMarginTop: CGFloat = 16.0
    private let kSeparatorBetweenHeaderAndBodyMarginTop: CGFloat = 16.0
    
    func getHeight () -> CGFloat {
        //return 100
        return separatorBetweenHeaderAndBodyView.frame.origin.y + 1;
    }
    
    required init() {
        super.init(frame: CGRectZero)
        self.backgroundColor = UIColor.whiteColor()

        self.addSubviews()
        self.makeConstraints()
        
       // updateAttachments()
        
        self.layoutIfNeeded()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Subviews
    func addSubviews() {

        self.createHeaderView()
        self.createSeparator()
        //self.createEmailBodyWebView()
        //self.createFooterView()
    }
    
    private func createSeparator() {
        self.separatorBetweenHeaderAndBodyView = UIView()
        self.separatorBetweenHeaderAndBodyView.backgroundColor = UIColor.ProtonMail.Gray_C9CED4
        self.addSubview(separatorBetweenHeaderAndBodyView)

//        self.separatorBetweenBodyViewAndFooter = UIView()
//        self.separatorBetweenBodyViewAndFooter.backgroundColor = UIColor.ProtonMail.Gray_C9CED4
//        self.addSubview(separatorBetweenBodyViewAndFooter)
    }
    
    private func createHeaderView() {
        self.emailHeaderView = UIView()
        self.addSubview(emailHeaderView)
        
        self.emailTitle = UILabel()
        self.emailTitle.font = UIFont.robotoLight(size: UIFont.Size.h1)
        self.emailTitle.numberOfLines = 0
        self.emailTitle.lineBreakMode = .ByWordWrapping
        self.emailTitle.text = "test title lakjfkla"
        self.emailTitle.textColor = UIColor.ProtonMail.Gray_383A3B
        self.emailHeaderView.addSubview(emailTitle)
        
        self.emailRecipients = UILabel()
        self.emailRecipients.font = UIFont.robotoRegular(size: UIFont.Size.h6)
        self.emailRecipients.numberOfLines = 1
        self.emailRecipients.text = "To alsdflasjfkljlkj"
        self.emailRecipients.textColor = UIColor.ProtonMail.Gray_999DA1
        self.emailHeaderView.addSubview(emailRecipients)
        
        self.emailTime = UILabel()
        self.emailTime.font = UIFont.robotoMediumItalic(size: UIFont.Size.h6)
        self.emailTime.numberOfLines = 1
        
        let hourMinuteFormat = "h:mma"
        
        //if let messageTime = self.message.time {
            self.emailTime.text = "at 11pm)".lowercaseString
//        } else {
//            self.emailTime.text = ""
//        }
        
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
        self.configureEmailDetailBCCLabel()
        self.configureEmailDetailDateLabel()
        
        self.emailFavoriteButton = UIButton()
        self.emailFavoriteButton.addTarget(self, action: "emailFavoriteButtonTapped", forControlEvents: .TouchUpInside)
        self.emailFavoriteButton.setImage(UIImage(named: "favorite")!, forState: .Normal)
        self.emailFavoriteButton.setImage(UIImage(named: "favorite_selected")!, forState: .Selected)
        self.emailFavoriteButton.selected = true//self.message.isStarred
        
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
        self.emailAttachmentsAmount.text = "3"
        self.emailAttachmentsAmount.textColor = UIColor.ProtonMail.Gray_999DA1
        self.emailAttachmentsAmount.sizeToFit()
        self.emailHeaderView.addSubview(emailAttachmentsAmount)
    }
    
    // MARK: - Subview constraints
    
    func makeConstraints() {
        
        self.makeHeaderConstraints()
        //self.makeEmailBodyConstraints()
        //self.makeFooterConstraints()
        
        separatorBetweenHeaderAndBodyView.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.top.equalTo()(self.emailHeaderView.mas_bottom).with().offset()(self.kSeparatorBetweenHeaderAndBodyMarginTop)
            make.height.equalTo()(1)
            
            
        }
//
//        separatorBetweenBodyViewAndFooter.mas_makeConstraints { (make) -> Void in
//            make.left.equalTo()(self)
//            make.right.equalTo()(self)
//            make.bottom.equalTo()(self.buttonsView.mas_top)
//            make.height.equalTo()(self.kSeparatorBetweenBodyViewAndFooterHeight)
//        }
    }
    
    private func configureEmailDetailToLabel() {
        self.emailDetailView = UIView()
        self.emailDetailView.clipsToBounds = true
        self.emailHeaderView.addSubview(emailDetailView)
        
        self.emailDetailToLabel = UILabel()
        self.emailDetailToLabel.font = UIFont.robotoLight(size: UIFont.Size.h5)
        //self.emailDetailToLabel.numberOfLines = 1
        self.emailDetailToLabel.lineBreakMode = NSLineBreakMode.ByCharWrapping //.lineBreakMode = UILineBreakModel. // UILineBreakModeWordWrap;
        self.emailDetailToLabel.numberOfLines = 0;
        self.emailDetailToLabel.text = "To: test"//"To: \(self.receipientlist)"
        self.emailDetailToLabel.textColor = UIColor.ProtonMail.Gray_999DA1
        self.emailDetailToLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailToLabel)
        
        self.emailDetailToContentLabel = UILabel()
        self.emailDetailToContentLabel.font = UIFont.robotoRegular(size: UIFont.Size.h5)
        self.emailDetailToContentLabel.numberOfLines = 1
        self.emailDetailToContentLabel.text = "Test"//"\(message.recipientNameList)"
        self.emailDetailToContentLabel.textColor = UIColor.ProtonMail.Blue_85B1DE
        self.emailDetailToContentLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailToContentLabel)
    }
    
    private func configureEmailDetailCCLabel() {
        self.emailDetailCCLabel = UILabel()
        self.emailDetailCCLabel.font = UIFont.robotoLight(size: UIFont.Size.h5)
        //self.emailDetailCCLabel.numberOfLines = 1
        self.emailDetailCCLabel.lineBreakMode = NSLineBreakMode.ByCharWrapping //.lineBreakMode = UILineBreakModel. // UILineBreakModeWordWrap;
        self.emailDetailCCLabel.numberOfLines = 0;
        self.emailDetailCCLabel.text = "Cc: test"//"Cc: \(self.ccList)"
        self.emailDetailCCLabel.textColor = UIColor.ProtonMail.Gray_999DA1
        self.emailDetailCCLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailCCLabel)
        
        self.emailDetailCCContentLabel = UILabel()
        self.emailDetailCCContentLabel.font = UIFont.robotoRegular(size: UIFont.Size.h5)
        self.emailDetailCCContentLabel.numberOfLines = 1
        self.emailDetailCCContentLabel.text = "Test"//message.ccNameList
        self.emailDetailCCContentLabel.textColor = UIColor.ProtonMail.Blue_85B1DE
        self.emailDetailCCContentLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailCCContentLabel)
    }
    
    private func configureEmailDetailBCCLabel() {
        self.emailDetailBCCLabel = UILabel()
        self.emailDetailBCCLabel.font = UIFont.robotoLight(size: UIFont.Size.h5)
        self.emailDetailBCCLabel.lineBreakMode = NSLineBreakMode.ByCharWrapping
        self.emailDetailBCCLabel.numberOfLines = 0;
        self.emailDetailBCCLabel.text = "Bcc: test"//"Bcc: \(self.ccList)"
        self.emailDetailBCCLabel.textColor = UIColor.ProtonMail.Gray_999DA1
        self.emailDetailBCCLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailBCCLabel)
        
        self.emailDetailBCCContentLabel = UILabel()
        self.emailDetailBCCContentLabel.font = UIFont.robotoRegular(size: UIFont.Size.h5)
        self.emailDetailBCCContentLabel.numberOfLines = 1
        self.emailDetailBCCContentLabel.text = "test"//message.ccNameList
        self.emailDetailBCCContentLabel.textColor = UIColor.ProtonMail.Blue_85B1DE
        self.emailDetailBCCContentLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailBCCContentLabel)
    }
    
    private func configureEmailDetailDateLabel() {
        self.emailDetailDateLabel = UILabel()
        self.emailDetailDateLabel.font = UIFont.robotoLight(size: UIFont.Size.h5)
        self.emailDetailDateLabel.numberOfLines = 1
//        if let messageTime = self.message.time {
//            let tm = messageTime.formattedWith("'On' EE, MMM d, yyyy 'at' h:mm a") ?? "";
//            self.emailDetailDateLabel.text = "Date: \(tm)"
//        } else {
            self.emailDetailDateLabel.text = "Date: "
//        }
        self.emailDetailDateLabel.textColor = UIColor.ProtonMail.Gray_999DA1
        self.emailDetailDateLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailDateLabel)
        
        self.emailDetailDateContentLabel = UILabel()
        self.emailDetailDateContentLabel.font = UIFont.robotoRegular(size: UIFont.Size.h5)
        self.emailDetailDateContentLabel.numberOfLines = 1
        self.emailDetailDateContentLabel.text = "asdf time" //message.time?.stringWithFormat(kEmailTimeLongFormat)
        self.emailDetailDateContentLabel.textColor = UIColor.ProtonMail.Gray_383A3B
        self.emailDetailDateContentLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailDateContentLabel)
    }
    
    private func makeHeaderConstraints() {
        emailHeaderView.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self).with().offset()(self.kEmailHeaderViewMarginTop)
            make.left.equalTo()(self).with().offset()(self.kEmailHeaderViewMarginLeft)
            make.right.equalTo()(self).with().offset()(self.kEmailHeaderViewMarginRight)
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
        
        emailDetailToLabel.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.emailDetailView)
            make.left.equalTo()(self.emailDetailView)
            make.width.equalTo()(self.emailDetailView)
            make.height.equalTo()(self.emailDetailToLabel.frame.size.height)
        }
        
        emailDetailToContentLabel.mas_makeConstraints { (make) -> Void in
            make.centerY.equalTo()(self.emailDetailToLabel)
            make.left.equalTo()(self.emailDetailToLabel.mas_right)
            make.right.equalTo()(self.emailDetailView)
            make.height.equalTo()(self.emailDetailToContentLabel.frame.size.height)
        }
        
        let ccHeight =  0
        emailDetailCCLabel.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.emailDetailToLabel)
            make.top.equalTo()(self.emailDetailToLabel.mas_bottom).with().offset()( ccHeight == 0 ? 0 : self.kEmailDetailCCLabelMarginTop)
            make.width.equalTo()(self.emailDetailToLabel)
            make.height.equalTo()(ccHeight)
        }
        emailDetailCCContentLabel.mas_makeConstraints { (make) -> Void in
            make.centerY.equalTo()(self.emailDetailCCLabel)
            make.left.equalTo()(self.emailDetailCCLabel.mas_right)
            make.right.equalTo()(self.emailDetailView)
            make.height.equalTo()(ccHeight)
        }
        
        let bccHeight = 0
        emailDetailBCCLabel.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.emailDetailCCLabel)
            make.top.equalTo()(self.emailDetailCCLabel.mas_bottom).with().offset()( ccHeight == 0 ? 0 : self.kEmailDetailCCLabelMarginTop)
            make.width.equalTo()(self.emailDetailCCLabel)
            make.height.equalTo()(bccHeight)
        }
        emailDetailBCCContentLabel.mas_makeConstraints { (make) -> Void in
            make.centerY.equalTo()(self.emailDetailBCCLabel)
            make.left.equalTo()(self.emailDetailBCCLabel.mas_right)
            make.right.equalTo()(self.emailDetailView)
            make.height.equalTo()(bccHeight)
        }
        
        emailDetailView.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.emailTitle)
            make.right.equalTo()(self.emailHeaderView)
            make.top.equalTo()(self.emailDetailButton.mas_bottom)
            make.height.equalTo()(0)
        }
        
        emailDetailDateLabel.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.emailDetailToLabel)
            make.top.equalTo()(self.emailDetailBCCLabel.mas_bottom).with().offset()(self.kEmailDetailDateLabelMarginTop)
            make.width.equalTo()(self.emailDetailToLabel)
            make.height.equalTo()(self.emailDetailBCCLabel.frame.size.height)
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
            make.height.equalTo()(self.kEmailFavoriteButtonHeight)
            make.width.equalTo()(self.kEmailFavoriteButtonWidth)
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
        
//        emailIsEncryptedImageView.mas_makeConstraints { (make) -> Void in
//            if (self.message.hasAttachments) {
//                make.right.equalTo()(self.emailHasAttachmentsImageView.mas_left).with().offset()(self.kEmailIsEncryptedImageViewMarginRight)
//            } else {
//                make.right.equalTo()(self.emailHeaderView)
//            }
//            
//            make.bottom.equalTo()(self.emailAttachmentsAmount)
//            make.height.equalTo()(self.emailIsEncryptedImageView.frame.height)
//            make.width.equalTo()(self.emailIsEncryptedImageView.frame.width)
//        }
    }
    
    private var isShowingDetail: Bool = false
    internal func detailsButtonTapped() {
        self.isShowingDetail = !self.isShowingDetail
        self.updateDetailsView(self.isShowingDetail)
    }
    
    private let kAnimationOption: UIViewAnimationOptions = .TransitionCrossDissolve
    private func updateDetailsView(needsShow : Bool) {
        if (needsShow) {
            UIView.transitionWithView(self.emailRecipients, duration: 0.3, options: kAnimationOption, animations: { () -> Void in
                self.emailRecipients.text = "From: aklkjdfsklja"
                self.emailDetailToLabel.text = "To: aklkjdfsklja"
                self.emailDetailCCLabel.text = "CC: aklkjdfsklja"
                self.emailDetailBCCLabel.text = "BCC: aklkjdfsklja"
                self.emailDetailToLabel.sizeToFit()
                self.emailDetailCCLabel.sizeToFit()
                self.emailDetailBCCLabel.sizeToFit()
                }, completion: nil)
            
            self.emailDetailButton.setTitle(NSLocalizedString("Hide Details"), forState: UIControlState.Normal)
            self.emailDetailButton.mas_updateConstraints({ (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailTime)
                make.bottom.equalTo()(self.emailTime)
                make.top.equalTo()(self.emailTime)
                make.width.equalTo()(self.emailDetailButton)
            })
            
            let toHeight = self.emailDetailToLabel.frame.height;
            emailDetailToLabel.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.top.equalTo()(self.emailDetailView)
                make.left.equalTo()(self.emailDetailView)
                make.width.equalTo()(self.emailDetailView)
                make.height.equalTo()(self.emailDetailToLabel.frame.size.height)
            }
            emailDetailToContentLabel.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.centerY.equalTo()(self.emailDetailToLabel)
                make.left.equalTo()(self.emailDetailToLabel.mas_right)
                make.right.equalTo()(self.emailDetailView)
                make.height.equalTo()(self.emailDetailToContentLabel.frame.size.height)
            }
            
            let ccHeight = self.emailDetailCCLabel.frame.size.height //: 0
            emailDetailCCLabel.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailDetailToLabel)
                make.top.equalTo()(self.emailDetailToLabel.mas_bottom).with().offset()( ccHeight == 0 ? 0 : self.kEmailDetailCCLabelMarginTop)
                make.width.equalTo()(self.emailDetailToLabel)
                make.height.equalTo()(ccHeight)
            }
            emailDetailCCContentLabel.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.centerY.equalTo()(self.emailDetailCCLabel)
                make.left.equalTo()(self.emailDetailCCLabel.mas_right)
                make.right.equalTo()(self.emailDetailView)
                make.height.equalTo()(ccHeight)
            }
            
            let bccHeight = self.emailDetailBCCLabel.frame.size.height //: 0
            emailDetailBCCLabel.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailDetailCCLabel)
                make.top.equalTo()(self.emailDetailCCLabel.mas_bottom).with().offset()( bccHeight == 0 ? 0 : self.kEmailDetailCCLabelMarginTop)
                make.width.equalTo()(self.emailDetailCCLabel)
                make.height.equalTo()(bccHeight)
            }
            emailDetailBCCContentLabel.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.centerY.equalTo()(self.emailDetailBCCLabel)
                make.left.equalTo()(self.emailDetailBCCLabel.mas_right)
                make.right.equalTo()(self.emailDetailView)
                make.height.equalTo()(bccHeight)
            }
            
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
            UIView.transitionWithView(self.emailRecipients, duration: 0.3, options: kAnimationOption, animations: { () -> Void in
                self.emailRecipients.text = "To adsfasfasdfasdf"
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
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.layoutIfNeeded()
            
            self.delegate?.updateSize()
            
        })
    }

    
}