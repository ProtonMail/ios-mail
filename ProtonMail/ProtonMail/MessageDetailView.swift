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

class MessageDetailView: UIView,  MessageDetailBottomViewProtocol {
    
    var delegate: MessageDetailViewDelegate?
    var message: Message
    private var attachments: [Attachment] = []
    private var isShowingDetail: Bool = false
    private var isViewingMoreOptions: Bool = false
    
    // MARK: - Private constants
    
    private let kAnimationDuration: NSTimeInterval = 0.1
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
    private let kEmailBodyTextViewMarginLeft: CGFloat = 16.0
    private let kEmailBodyTextViewMarginRight: CGFloat = -16.0
    private let kEmailBodyTextViewMarginTop: CGFloat = 16.0
    private let kButtonsViewHeight: CGFloat = 68.0
    private let kMoreOptionsViewHeight: CGFloat = 123.0
    
    
    // MARK: - Views
    
    private var moreOptionsView: MoreOptionsView!
    
    
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
    
    private var tableView: UITableView!
    private var contentView: UIView!
    private var emailBodyWebView: FullHeightWebView!
    
    
    // MARK: - Email footer views
    private var buttonsView: MessageDetailBottomView!


    
    // MARK: - Init methods
    
    required init(message: Message, delegate: MessageDetailViewDelegate?) {
        self.message = message
        self.delegate = delegate
        
        super.init(frame: CGRectZero)
        
        message.addObserver(self, forKeyPath: Message.Attributes.isDetailDownloaded, options: .New, context: &kKVOContext)
        
        self.backgroundColor = UIColor.whiteColor()
        self.addSubviews()
        self.makeConstraints()
        
        updateAttachments()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        message.removeObserver(self, forKeyPath: Message.Attributes.isDetailDownloaded, context: &kKVOContext)
    }
    
    
    // MARK: - Public methods
    
    func animateMoreViewOptions() {
        self.bringSubviewToFront(self.moreOptionsView)
        if (self.isViewingMoreOptions) {
            self.moreOptionsView.mas_updateConstraints({ (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self)
                make.right.equalTo()(self)
                make.height.equalTo()(self.kMoreOptionsViewHeight)
                make.bottom.equalTo()(self.mas_top)
            })
        } else {
            self.moreOptionsView.mas_updateConstraints({ (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self)
                make.right.equalTo()(self)
                make.height.equalTo()(self.kMoreOptionsViewHeight)
                
                make.top.equalTo()(self.mas_top)
            })
        }
        
        self.isViewingMoreOptions = !self.isViewingMoreOptions
        
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.layoutIfNeeded()
        }, completion: nil)
    }
    
    func attachmentForIndexPath(indexPath: NSIndexPath) -> Attachment {
        return self.attachments[indexPath.row]
    }
    
    func updateAttachments() {
        if !self.message.hasAttachments {
            self.emailHasAttachmentsImageView.hidden = true
        }
        
        if !self.message.hasAttachments || !self.message.isDetailDownloaded {
            self.emailAttachmentsAmount.hidden = true
        } else if (message.hasAttachments && message.isDetailDownloaded) {
            self.emailAttachmentsAmount.alpha = 0
            self.emailAttachmentsAmount.text = "\(self.message.attachments.count)"
            
            UIView.animateWithDuration(self.kAnimationDuration, animations: { () -> Void in
                self.emailAttachmentsAmount.hidden = false
                self.emailAttachmentsAmount.alpha = 1.0
            })
        }
    }
    
    func updateEmailBodyWebView(animated: Bool) {
        let completion: ((Bool) -> Void) = { finished in
            var bodyText = NSLocalizedString("Loading...")
            
            if self.message.isDetailDownloaded {
                var error: NSError?
                bodyText = self.message.decryptBodyIfNeeded(&error) ?? NSLocalizedString("Unable to decrypt message.")
                            println(bodyText)

                if let error = error {
                    self.delegate?.messageDetailView(self, didFailDecodeWithError: error)
                }
                self.updateFromToField()
            }
            
            let font = UIFont.robotoLight(size: UIFont.Size.h6)
            let cssColorString = UIColor.ProtonMail.Gray_383A3B.cssString
            
            
            
            let css : String  = "article,aside,details,figcaption,figure,footer,header,hgroup,nav,section,summary{display:block}audio,canvas,video{display:inline-block}audio:not([controls]){display:none;height:0}[hidden]{display:none}html{font-size:80%;-webkit-text-size-adjust:80%;-ms-text-size-adjust:80%}button,html,input,select,textarea{font-family:sans-serif}body{font:15px/1.4rem normal \"Helvetica Neue\",Arial,Helvetica,sans-serif;font-weight:400;margin:0;width:100%;box-sizing:border-box;padding:1rem;word-break:break-word}a:focus{outline:dotted thin}a:active,a:hover{outline:0}h1{font-size:2em;margin:.67em 0}h2{font-size:1.5em;margin:.83em 0}h3{font-size:1.17em;margin:1em 0}h4{font-size:1em;margin:1.33em 0}h5{font-size:.83em;margin:1.67em 0}h6{font-size:.75em;margin:2.33em 0}abbr[title]{border-bottom:1px dotted}b,strong{font-weight:700}blockquote{padding:0 0 0 2rem;margin:1rem 0}blockquote blockquote{padding:0 0 0 1rem}dfn{font-style:italic}mark{background:#ff0;color:#000}p,pre{margin:1em 0}code,kbd,pre,samp{font-family:monospace,serif;font-size:1em}pre{white-space:pre;white-space:pre-wrap;word-wrap:break-word}q{quotes:none}q:after,q:before{content:\"\";content:none}small{font-size:80%}sub,sup{font-size:75%;line-height:0;position:relative;vertical-align:baseline}sup{top:-.5em}sub{bottom:-.25em}dl,menu,ol,ul{margin:1em 0}dd{margin:0 0 0 40px}menu,ol,ul{padding:0 0 0 40px}nav ol,nav ul{list-style:none}img{border:0;-ms-interpolation-mode:bicubic;max-width:100%}table img{max-width:none}svg:not(:root){overflow:hidden}figure,form{margin:0}fieldset{border:1px solid silver;margin:0 2px;padding:.35em .625em .75em}legend{border:0;padding:0;white-space:normal}button,input,select,textarea{font-size:100%;margin:0;vertical-align:baseline}button,input{line-height:normal}button,html input[type=button],input[type=reset],input[type=submit]{-webkit-appearance:button;cursor:pointer}button[disabled],input[disabled]{cursor:default}input[type=checkbox],input[type=radio]{box-sizing:border-box;padding:0}input[type=search]{-webkit-appearance:textfield;-moz-box-sizing:content-box;-webkit-box-sizing:content-box;box-sizing:content-box}input[type=search]::-webkit-search-cancel-button,input[type=search]::-webkit-search-decoration{-webkit-appearance:none}button::-moz-focus-inner,input::-moz-focus-inner{border:0;padding:0}textarea{overflow:auto;vertical-align:top}table{border-collapse:collapse;border-spacing:0}"

            
//            let messageCSS: String = "html, body { font-family: sans-serif; font-size:0.9em; margin:0; border:0;width:375px;-webkit-text-size-adjust: auto;word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space;}.inbox-body {padding-top:5px;padding-left:1px; padding-bottom:5px;padding-right:1px;} a { color:rgb(0,153,204); } div { max-width:100%%; } .gmail_extra {  display:none; } blockquote, img { max-width: 100%; height:auto; }"
            
            
           // let htmlString = "<span style=\"font-family: \(font.fontName); font-size: \(font.pointSize); color: \(cssColorString)\">\(bodyText)</span>"
            
            let htmlString = "<style>\(css)</style><meta name=\"viewport\" content=\"width=375\">\n<div class='inbox-body'>\(bodyText)</div>"
            
            self.emailBodyWebView.loadHTMLString(htmlString, baseURL: nil)
        }
        
        if animated {
            UIView.animateWithDuration(kAnimationDuration, animations: { () -> Void in
                self.emailBodyWebView.alpha = 0
                }, completion: completion)
        } else {
            completion(true)
        }
    }
    
    func updateFromToField()
    {
        self.emailDetailToLabel.text = "To: \(self.message.recipientList)"
        self.emailDetailToContentLabel.text = "\(message.recipientNameList)"
        
        self.emailDetailCCLabel.text = "Cc: \(self.message.ccList)"
        self.emailDetailCCLabel.sizeToFit()
        self.emailDetailCCContentLabel.text = message.ccNameList

        self.makeConstraints()
    }
    
    
    // MARK: - Subviews
    
    func addSubviews() {
        self.tableView = UITableView()
        self.tableView.alwaysBounceVertical = false
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.registerNib(UINib(nibName: "AttachmentTableViewCell", bundle: nil), forCellReuseIdentifier: AttachmentTableViewCell.Constant.identifier)
        self.tableView.separatorStyle = .None
        self.addSubview(tableView)
        
        self.contentView = UIView()
        self.contentView.backgroundColor = UIColor.whiteColor()
        self.tableView.tableHeaderView = contentView
        self.tableView.tableFooterView = UIView()
        
        self.createMoreOptionsView()
        self.createHeaderView()
        self.createSeparator()
        self.createEmailBodyWebView()
        self.createFooterView()
    }
    
    private func createMoreOptionsView() {
        self.moreOptionsView = MoreOptionsView()
        self.moreOptionsView.delegate = self
        self.addSubview(moreOptionsView)
    }
    
    private func createHeaderView() {
        self.emailHeaderView = UIView()
        self.contentView.addSubview(emailHeaderView)
        
        self.emailTitle = UILabel()
        self.emailTitle.font = UIFont.robotoLight(size: UIFont.Size.h1)
        self.emailTitle.numberOfLines = 0
        self.emailTitle.lineBreakMode = .ByWordWrapping
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
        self.emailFavoriteButton.addTarget(self, action: "emailFavoriteButtonTapped", forControlEvents: .TouchUpInside)
        self.emailFavoriteButton.setImage(UIImage(named: "favorite")!, forState: .Normal)
        self.emailFavoriteButton.setImage(UIImage(named: "favorite_selected")!, forState: .Selected)
        self.emailFavoriteButton.selected = self.message.isStarred

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
    
    private func createEmailBodyWebView() {
        self.emailBodyWebView = FullHeightWebView(frame: CGRect(x: 0,y: 0,width: 375,height: 5))
        self.emailBodyWebView.delegate = self
        self.contentView.addSubview(emailBodyWebView)        
    }

    private func createFooterView() {
        var v = NSBundle.mainBundle().loadNibNamed("MessageDetailBottomView", owner: 0, options: nil)[0] as? UIView
        self.buttonsView = v as! MessageDetailBottomView
        self.buttonsView.delegate = self
        self.buttonsView.backgroundColor = UIColor.ProtonMail.Gray_E8EBED
        self.addSubview(buttonsView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        tableView.tableHeaderView = contentView
    }
        
    
    // MARK: - Subview constraints
    
    func makeConstraints() {
        tableView.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self)
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.bottom.equalTo()(self).with().offset()(self.kScrollViewDistanceToBottom)
        }
        
        moreOptionsView.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.height.equalTo()(self.kMoreOptionsViewHeight)
            make.bottom.equalTo()(self.mas_top)
        }
        
        contentView.mas_makeConstraints { (make) -> Void in
            make.edges.equalTo()(self.tableView)
            make.width.equalTo()(self.tableView)
            make.bottom.equalTo()(self.emailBodyWebView)
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
        println(self.emailDetailCCLabel.frame.size.height )
        println(self.message.ccList)
        let ccHeight = !self.message.ccList.isEmpty ? self.emailDetailCCLabel.frame.size.height : 0
        emailDetailCCLabel.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.emailDetailToLabel)
            make.top.equalTo()(self.emailDetailToLabel.mas_bottom).with().offset()(self.kEmailDetailCCLabelMarginTop)
            make.width.equalTo()(self.emailDetailToLabel)
            make.height.equalTo()(ccHeight)
        }//
        
        println(emailDetailCCLabel.frame.height)
        
        emailDetailView.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.emailTitle)
            make.right.equalTo()(self.emailHeaderView)
            make.top.equalTo()(self.emailDetailButton.mas_bottom)
            make.height.equalTo()(0)
        }
        
        
        emailDetailCCContentLabel.mas_makeConstraints { (make) -> Void in
            make.centerY.equalTo()(self.emailDetailCCLabel)
            make.left.equalTo()(self.emailDetailCCLabel.mas_right)
            make.right.equalTo()(self.emailDetailView)
            make.height.equalTo()(ccHeight)//!self.message.ccList.isEmpty ? self.emailDetailCCContentLabel.frame.size.height : 0)
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
        emailBodyWebView.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.contentView).with().offset()(self.kEmailBodyTextViewMarginLeft)
            make.right.equalTo()(self.contentView).with().offset()(self.kEmailBodyTextViewMarginRight)
            make.top.equalTo()(self.separatorBetweenHeaderAndBodyView.mas_bottom).with().offset()(self.kEmailBodyTextViewMarginTop)
            make.bottom.equalTo()(self.contentView)
        }
    }
    
    private func makeFooterConstraints() {
        buttonsView.mas_makeConstraints { (make) -> Void in
            make.bottom.equalTo()(self)
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.height.equalTo()(self.kButtonsViewHeight)
        }
    }
    
    
    // MARK: - Button actions
    
    internal func detailsButtonTapped() {
        self.isShowingDetail = !self.isShowingDetail
        if (isShowingDetail) {
            UIView.transitionWithView(self.emailRecipients, duration: kAnimationDuration, options: kAnimationOption, animations: { () -> Void in
                self.emailRecipients.text = "From: \(self.message.sender)"
                self.emailDetailToLabel.text = "To: \(self.message.recipientList)"
                self.emailDetailCCLabel.text = "To: \(self.message.ccList)"
                self.emailDetailToLabel.sizeToFit()
                self.emailDetailCCLabel.sizeToFit()
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
    
    internal func emailFavoriteButtonTapped() {
        message.isStarred = !message.isStarred
        
        if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
            NSLog("\(__FUNCTION__) error: \(error)")
        }

        self.emailFavoriteButton.selected = self.message.isStarred
    }
    
    func replyClicked()
    {
        self.delegate?.messageDetailViewDidTapReplyMessage(self, message: message)
    }
    func replyAllClicked()
    {
        self.delegate?.messageDetailViewDidTapReplyAllMessage(self, message: message)
    }
    func forwardClicked()
    {
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
        self.emailDetailToLabel.text = "To: \(self.message.recipientList)"
        self.emailDetailToLabel.textColor = UIColor.ProtonMail.Gray_999DA1
        self.emailDetailToLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailToLabel)
        
        self.emailDetailToContentLabel = UILabel()
        self.emailDetailToContentLabel.font = UIFont.robotoRegular(size: UIFont.Size.h5)
        self.emailDetailToContentLabel.numberOfLines = 1
        self.emailDetailToContentLabel.text = "\(message.recipientNameList)"
        println("\(message.recipientNameList)")
        self.emailDetailToContentLabel.textColor = UIColor.ProtonMail.Blue_85B1DE
        self.emailDetailToContentLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailToContentLabel)
    }
    
    private func configureEmailDetailCCLabel() {
        self.emailDetailCCLabel = UILabel()
        self.emailDetailCCLabel.font = UIFont.robotoLight(size: UIFont.Size.h5)
        self.emailDetailCCLabel.numberOfLines = 1
        self.emailDetailCCLabel.text = "Cc: \(self.message.ccList)"
        println("\(self.message.ccList)")
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
        if let messageTime = self.message.time {
            let tm = messageTime.formattedWith("'On' EE, MMM d, yyyy 'at' h:mm a") ?? "";
            self.emailDetailDateLabel.text = "Date: \(tm)"
        } else {
            self.emailDetailDateLabel.text = "Date: "
        }
        self.emailDetailDateLabel.textColor = UIColor.ProtonMail.Gray_999DA1
        self.emailDetailDateLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailDateLabel)
        
        self.emailDetailDateContentLabel = UILabel()
        self.emailDetailDateContentLabel.font = UIFont.robotoRegular(size: UIFont.Size.h5)
        self.emailDetailDateContentLabel.numberOfLines = 1
        self.emailDetailDateContentLabel.text = message.time?.stringWithFormat(kEmailTimeLongFormat)
        self.emailDetailDateContentLabel.textColor = UIColor.ProtonMail.Gray_383A3B
        self.emailDetailDateContentLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailDateContentLabel)
    }
    
    // MARK: - KVO
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if context != &kKVOContext {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        } else if object as! NSObject == message && keyPath == Message.Attributes.isDetailDownloaded {
            updateEmailBodyWebView(true)
            updateAttachments()
        }
    }
}


// MARK: - MoreOptionsViewDelegate

extension MessageDetailView: MoreOptionsViewDelegate {
    func moreOptionsViewDidMarkAsUnread(moreOptionsView: MoreOptionsView) {
        delegate?.messageDetailView(self, didTapMarkAsUnreadForMessage: message)
        
        animateMoreViewOptions()
    }
    
    func moreOptionsViewDidSelectMoveTo(moreOptionsView: MoreOptionsView) {
        delegate?.messageDetailView(self, didTapMoveToForMessage: message)
        
        animateMoreViewOptions()
    }
}


// MARK: - UITableViewDataSource

extension MessageDetailView: UITableViewDataSource {
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let attachment = attachmentForIndexPath(indexPath)
        let cell = tableView.dequeueReusableCellWithIdentifier(AttachmentTableViewCell.Constant.identifier, forIndexPath: indexPath) as! AttachmentTableViewCell
        cell.setFilename(attachment.fileName, fileSize: Int(attachment.fileSize))
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attachments.count
    }
}


// MARK: - UITableViewDelegate

extension MessageDetailView: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let attachment = attachmentForIndexPath(indexPath)
        
        if !attachment.isDownloaded {
            downloadAttachment(attachment, forIndexPath: indexPath)
        } else if let localURL = attachment.localURL {
            let cell = tableView.cellForRowAtIndexPath(indexPath)
            openLocalURL(localURL, forCell: cell!)
        }
    }
    
    // MARK: Private methods
    
    private func downloadAttachment(attachment: Attachment, forIndexPath indexPath: NSIndexPath) {
        sharedMessageDataService.fetchAttachmentForAttachment(attachment, downloadTask: { (task) -> Void in
            if let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? AttachmentTableViewCell {
                cell.progressView.alpha = 1.0
                cell.progressView.setProgressWithDownloadProgressOfTask(task, animated: true)
            }
            }, completion: { (_, url, error) -> Void in
                if let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? AttachmentTableViewCell {
                    UIView.animateWithDuration(self.kAnimationDuration, animations: { () -> Void in
                        cell.progressView.hidden = true
                    })
                }
        })
    }
    
    private func openLocalURL(localURL: NSURL, forCell cell: UITableViewCell) {
        let documentInteractionController = UIDocumentInteractionController(URL: localURL)
        documentInteractionController.delegate = self
        
        if !documentInteractionController.presentOpenInMenuFromRect(cell.bounds, inView: cell, animated: true) {
            let alert = UIAlertController(title: NSLocalizedString("Unsupported file type"), message: NSLocalizedString("There are no installed apps that can open this file type."), preferredStyle: .Alert)
            alert.addAction((UIAlertAction.okAction()))
            
            if let viewController = delegate as? MessageDetailViewController {
                viewController.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
}


// MARK: - UIDocumentInteractionControllerDelegate

extension MessageDetailView: UIDocumentInteractionControllerDelegate {
}


// MARK: - UIWebViewDelegate

extension MessageDetailView: UIWebViewDelegate {
    
    func webViewDidFinishLoad(webView: UIWebView) {
        // triggers scrollView.contentSize update
        //let jsForTextSize = "document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '\(100)%'";
        //webView.stringByEvaluatingJavaScriptFromString(jsForTextSize)
        
//        var frame = webView.frame
//        frame.size.height = 1;
//        webView.frame = frame
        
        UIView.animateWithDuration(kAnimationDuration, animations: { () -> Void in
            self.emailBodyWebView.alpha = 1.0
            
            }, completion: { finished in
                
                var frame = self.emailBodyWebView.frame
                frame.size.height = self.emailBodyWebView.scrollView.contentSize.height
                self.emailBodyWebView.frame = frame
                
                self.emailBodyWebView.updateConstraints();
                self.emailBodyWebView.layoutIfNeeded();
                self.layoutIfNeeded();
                self.updateConstraints();

                if (self.message.hasAttachments) {
                    self.attachments = self.message.attachments.allObjects as! [Attachment]
                }
                
                self.tableView.reloadData()
                self.tableView.tableHeaderView = self.contentView
                
                var webframe = self.emailBodyWebView.scrollView.frame;
                webframe.size = CGSize(width: webframe.width,  height: self.emailBodyWebView.scrollView.contentSize.height)
                self.emailBodyWebView.scrollView.frame = webframe;
        })
    }

    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == .LinkClicked {
            UIApplication.sharedApplication().openURL(request.URL!)
            return false
        }
        
        return true
    }
}


// MARK: - View Delegate

protocol MessageDetailViewDelegate {
    func messageDetailView(messageDetailView: MessageDetailView, didFailDecodeWithError: NSError)
    func messageDetailView(messageDetailView: MessageDetailView, didTapMarkAsUnreadForMessage message: Message)
    func messageDetailView(messageDetailView: MessageDetailView, didTapMoveToForMessage message: Message)
    func messageDetailViewDidTapForwardMessage(messageDetailView: MessageDetailView, message: Message)
    func messageDetailViewDidTapReplyMessage(messageDetailView: MessageDetailView, message: Message)
    func messageDetailViewDidTapReplyAllMessage(messageDetailView: MessageDetailView, message: Message)
}
