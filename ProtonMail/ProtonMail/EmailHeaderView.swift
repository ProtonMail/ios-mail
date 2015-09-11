//
//  EmailHeaderView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/27/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//


import UIKit

protocol EmailHeaderViewProtocol {
    func updateSize()
}

protocol EmailHeaderActionsProtocol {
    func starredChanged(isStarred : Bool)
    
    func quickLookAttachment (tempfile : NSURL, keyPackage:NSData, fileName:String)
}

class EmailHeaderView: UIView {
    
    var viewDelegate: EmailHeaderViewProtocol?
    var actionsDelegate: EmailHeaderActionsProtocol?
    
    
    /// Header Content View
    private var emailHeaderView: UIView!
    
    private var emailTitle: UILabel!
    
    private var emailFrom: UILabel!    //from or sender
    private var emailFromTable: RecipientView!
    
    private var emailTo: UILabel!    //to
    private var emailToTable: RecipientView!
    
    private var emailCc: UILabel!    //cc
    private var emailCcTable: RecipientView!
    
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
    private var separatorBetweenHeaderAndAttView: UIView!
    
    private var attachmentView : UITableView?
    
    
    // const header view
    private let kEmailHeaderViewMarginTop: CGFloat = 12.0
    private let kEmailHeaderViewMarginLeft: CGFloat = 16.0
    private let kEmailHeaderViewMarginRight: CGFloat = -16.0
    
    private let kEmailHeaderViewHeight: CGFloat = 70.0
    private let kEmailTitleViewMarginRight: CGFloat = -8.0
    private let kEmailFavoriteButtonHeight: CGFloat = 40
    private let kEmailFavoriteButtonWidth: CGFloat = 40
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
    private let kHourMinuteFormat = "h:mma"
    
    
    private var tempFileUri : NSURL?
    
    func getHeight () -> CGFloat {
        
        let y = (self.attachmentView != nil) ? self.attachmentView!.frame.origin.y : 0;
        
        let h = (self.attachmentView != nil) ? self.attachmentView!.frame.height : 0;
        
        return y + h + 10;
        //return separatorBetweenHeaderAndBodyView.frame.origin.y + 10;
    }
    
    private var title : String!
    private var sender : ContactVO?
    private var toList : [ContactVO]?
    private var ccList : [ContactVO]?
    private var bccList : [ContactVO]?
    private var attachmentCount : Int!
    private var attachments : [Attachment] = []
    
    private var date : NSDate!
    private var starred : Bool!
    
    private var fromSinglelineAttr : NSMutableAttributedString! {
        get {
            let n = self.sender?.name ?? ""
            let e = self.sender?.email ?? ""
            let from = "From: \((n.isEmpty ? e : n))"
            let formRange = NSRange (location: 0, length: 6)
            let attributedString = NSMutableAttributedString(string: from, attributes: [NSFontAttributeName : UIFont.robotoMedium(size: 12), NSForegroundColorAttributeName : UIColor(hexColorCode: "#838897")])
            attributedString.setAttributes([NSFontAttributeName : UIFont.robotoMedium(size: 12), NSForegroundColorAttributeName : UIColor(hexColorCode: "#C0C4CE")], range: formRange)
            
            return attributedString
        }
    }
    
    private var fromShortAttr : NSMutableAttributedString! {
        get {
            let from = "From: "
            let formRange = NSRange (location: 0, length: 6)
            let attributedString = NSMutableAttributedString(string: from, attributes: [NSFontAttributeName : UIFont.robotoMedium(size: 12), NSForegroundColorAttributeName : UIColor(hexColorCode: "#838897")])
            attributedString.setAttributes([NSFontAttributeName : UIFont.robotoMedium(size: 12), NSForegroundColorAttributeName : UIColor(hexColorCode: "#C0C4CE")], range: formRange)
            return attributedString
        }
    }
    
    private var toSinglelineAttr : NSMutableAttributedString! {
        get {
            var strTo : String = ""
            var count = toList?.count ?? 0
            if count > 0 {
                if let contact = toList?[0] {
                    let n = (contact.name ?? "")
                    let e = (contact.email ?? "")
                    strTo = n.isEmpty ? e : n
                }
            }
            
            if count > 1 {
                strTo += " +\(count - 1)"
            }
            
            let to = "To: \(strTo)"
            let formRange = NSRange (location: 0, length: 4)
            let attributedString = NSMutableAttributedString(string: to, attributes: [NSFontAttributeName : UIFont.robotoMedium(size: 12), NSForegroundColorAttributeName : UIColor(hexColorCode: "#838897")])
            attributedString.setAttributes([NSFontAttributeName : UIFont.robotoMedium(size: 12), NSForegroundColorAttributeName : UIColor(hexColorCode: "#C0C4CE")], range: formRange)
            return attributedString
        }
    }
    
    private var toShortAttr : NSMutableAttributedString! {
        get {
            let to = "To: "
            let formRange = NSRange (location: 0, length: 4)
            let attributedString = NSMutableAttributedString(string: to, attributes: [NSFontAttributeName : UIFont.robotoMedium(size: 12), NSForegroundColorAttributeName : UIColor(hexColorCode: "#838897")])
            attributedString.setAttributes([NSFontAttributeName : UIFont.robotoMedium(size: 12), NSForegroundColorAttributeName : UIColor(hexColorCode: "#C0C4CE")], range: formRange)
            return attributedString
        }
    }
    
    private var ccShortAttr : NSMutableAttributedString! {
        get {
            let to = "Cc: "
            let formRange = NSRange (location: 0, length: 4)
            let attributedString = NSMutableAttributedString(string: to, attributes: [NSFontAttributeName : UIFont.robotoMedium(size: 12), NSForegroundColorAttributeName : UIColor(hexColorCode: "#838897")])
            attributedString.setAttributes([NSFontAttributeName : UIFont.robotoMedium(size: 12), NSForegroundColorAttributeName : UIColor(hexColorCode: "#C0C4CE")], range: formRange)
            return attributedString
        }
    }
    
    private var showTo : Bool {
        get {
            return  (self.toList?.count ?? 0) > 0 ? true : false
        }
    }
    private var ccText : String! {
        get {
            return "Cc: \(self.ccList)"
        }
    }
    private var showCc : Bool {
        get {
            return (self.ccList?.count ?? 0) > 0 ? true : false
        }
    }
    private var showBcc : Bool {
        get {
            return (self.bccList?.count ?? 0) > 0 ? true : false
        }
    }
    private var bccText : String! {
        get {
            return "Bcc: \(self.bccList)"
        }
    }
    
    required init() {
        super.init(frame: CGRectZero)
        self.backgroundColor = UIColor(RRGGBB: UInt(0xDADEE8))
        
        // init data
        self.title = ""
        self.date = NSDate()
        self.starred = false
        self.attachmentCount = 0
        
        self.addSubviews()
        
        self.layoutIfNeeded()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK : Private functions
    func updateHeaderData (title : String, sender : ContactVO, to : [ContactVO]?, cc : [ContactVO]?, bcc : [ContactVO]?, isStarred : Bool, time : NSDate?, encType : EncryptTypes) {
        self.title = title
        self.sender = sender
        self.toList = to
        self.ccList = cc
        self.bccList = bcc
        if time != nil {
            self.date = time
        } else {
            self.date = NSDate()
        }
        
        self.starred = isStarred
        
        self.emailTitle.text = title
        
        self.emailFrom.attributedText = fromSinglelineAttr
        
        self.emailFromTable.contacts = [sender]
        self.emailToTable.contacts = toList
        self.emailCcTable.contacts = ccList
        
        self.emailTo.attributedText = toSinglelineAttr
        self.emailCc.attributedText = ccShortAttr
        
        self.emailDetailCCLabel.text = ccText
        self.emailDetailBCCLabel.text = bccText
        self.emailFavoriteButton.selected = self.starred;
        self.emailTime.text = "at \(self.date.stringWithFormat(self.kHourMinuteFormat))".lowercaseString
        let tm = self.date.formattedWith("'On' EE, MMM d, yyyy 'at' h:mm a") ?? "";
        self.emailDetailDateLabel.text = "Date: \(tm)"
        
        if encType == EncryptTypes.Internal {
            self.emailIsEncryptedImageView.highlighted = false;
        } else {
            self.emailIsEncryptedImageView.highlighted = true;
        }
    }
    
    func updateAttachmentData (atts : [Attachment]?) {
        self.attachmentCount = atts?.count
        self.attachments = atts!
        if (self.attachmentCount > 0) {
            self.emailAttachmentsAmount.text = "\(self.attachmentCount)"
            self.emailAttachmentsAmount.hidden = false
            self.emailHasAttachmentsImageView.hidden = false
        } else {
            self.emailAttachmentsAmount.hidden = true
            self.emailHasAttachmentsImageView.hidden = true
        }
        
    }
    
    func updateHeaderLayout () {
        self.updateDetailsView(self.isShowingDetail)
    }
    
    func attachmentForIndexPath(indexPath: NSIndexPath) -> Attachment {
        return self.attachments[indexPath.row]
    }
    
    
    // MARK: - Subviews
    func addSubviews() {
        self.createHeaderView()
        self.createAttachmentView()
        self.createSeparator()
    }
    
    private func createAttachmentView() {
        self.attachmentView = UITableView()
        self.attachmentView!.alwaysBounceVertical = false
        self.attachmentView!.dataSource = self
        self.attachmentView!.delegate = self
        self.attachmentView!.registerNib(UINib(nibName: "AttachmentTableViewCell", bundle: nil), forCellReuseIdentifier: AttachmentTableViewCell.Constant.identifier)
        self.attachmentView!.separatorStyle = .None
        self.addSubview(attachmentView!)
    }
    
    private func createSeparator() {
        self.separatorBetweenHeaderAndBodyView = UIView()
        self.separatorBetweenHeaderAndBodyView.backgroundColor = UIColor.ProtonMail.Gray_C9CED4
        self.addSubview(separatorBetweenHeaderAndBodyView)
        
        self.separatorBetweenHeaderAndAttView = UIView()
        self.separatorBetweenHeaderAndAttView.backgroundColor = UIColor.ProtonMail.Gray_C9CED4
        self.addSubview(separatorBetweenHeaderAndAttView)
    }
    
    private func createHeaderView() {
        
        // create header container
        self.emailHeaderView = UIView()
        self.addSubview(emailHeaderView)
        
        // create title
        self.emailTitle = UILabel()
        self.emailTitle.font = UIFont.robotoMedium(size: UIFont.Size.h4)
        self.emailTitle.numberOfLines = 0
        self.emailTitle.lineBreakMode = .ByWordWrapping
        self.emailTitle.text = self.title
        self.emailTitle.textColor = UIColor(RRGGBB: UInt(0x505061))
        self.emailTitle.sizeToFit()
        self.emailHeaderView.addSubview(emailTitle)
        
        // favorite button
        self.emailFavoriteButton = UIButton()
        self.emailFavoriteButton.addTarget(self, action: "emailFavoriteButtonTapped", forControlEvents: .TouchUpInside)
        self.emailFavoriteButton.setImage(UIImage(named: "mail_starred")!, forState: .Normal)
        self.emailFavoriteButton.setImage(UIImage(named: "mail_starred-active")!, forState: .Selected)
        self.emailFavoriteButton.selected = self.starred
        self.emailFavoriteButton.contentVerticalAlignment = UIControlContentVerticalAlignment.Top
        self.emailFavoriteButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Right
        self.emailHeaderView.addSubview(emailFavoriteButton)
        
        // details view
        self.emailDetailView = UIView()
        self.emailDetailView.clipsToBounds = true
        self.emailHeaderView.addSubview(emailDetailView)
        
        self.emailFrom = UILabel()
        self.emailFrom.numberOfLines = 1
        self.emailHeaderView.addSubview(emailFrom)
        
        self.emailFromTable = RecipientView()
        self.emailFromTable.alpha = 0.0;
        self.emailHeaderView.addSubview(emailFromTable)
        
        self.emailTo = UILabel()
        self.emailTo.numberOfLines = 1
        self.emailHeaderView.addSubview(emailTo)
        
        self.emailToTable = RecipientView()
        self.emailToTable.alpha = 0.0;
        self.emailHeaderView.addSubview(emailToTable)
        
        self.emailCc = UILabel()
        self.emailCc.alpha = 0.0;
        self.emailCc.numberOfLines = 1
        self.emailHeaderView.addSubview(emailCc)
        
        self.emailCcTable = RecipientView()
        self.emailCcTable.alpha = 0.0;
        self.emailHeaderView.addSubview(emailCcTable)

        
        
        self.emailTime = UILabel()
        self.emailTime.font = UIFont.robotoMediumItalic(size: UIFont.Size.h6)
        self.emailTime.numberOfLines = 1
        self.emailTime.text = "at \(self.date.stringWithFormat(self.kHourMinuteFormat))".lowercaseString
        self.emailTime.textColor = UIColor(RRGGBB: UInt(0x838897)) //UIColor.ProtonMail.Gray_999DA1
        self.emailTime.sizeToFit()
        self.emailHeaderView.addSubview(emailTime)
        
        self.emailDetailButton = UIButton()
        self.emailDetailButton.addTarget(self, action: "detailsButtonTapped", forControlEvents: UIControlEvents.TouchUpInside)
        self.emailDetailButton.contentEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
        self.emailDetailButton.titleLabel?.font = UIFont.robotoRegular(size: UIFont.Size.h6)
        self.emailDetailButton.setTitle(NSLocalizedString("Details"), forState: UIControlState.Normal)
        self.emailDetailButton.setTitleColor(UIColor(RRGGBB: UInt(0x9397CD)), forState: UIControlState.Normal) //UIColor.ProtonMail.Blue_85B1DE
        self.emailDetailButton.sizeToFit()
        self.emailHeaderView.addSubview(emailDetailButton)
        
        self.configureEmailDetailToLabel()
        self.configureEmailDetailCCLabel()
        self.configureEmailDetailBCCLabel()
        self.configureEmailDetailDateLabel()
        
        self.emailIsEncryptedImageView = UIImageView(image: UIImage(named: "mail_lock"))
        self.emailIsEncryptedImageView.highlightedImage = UIImage(named: "mail_lock_dark")
        self.emailIsEncryptedImageView.contentMode = UIViewContentMode.Center
        self.emailIsEncryptedImageView.sizeToFit()
        self.emailHeaderView.addSubview(emailIsEncryptedImageView)
        
        self.emailHasAttachmentsImageView = UIImageView(image: UIImage(named: "mail_attachment"))
        self.emailHasAttachmentsImageView.contentMode = UIViewContentMode.Center
        self.emailHasAttachmentsImageView.sizeToFit()
        self.emailHeaderView.addSubview(emailHasAttachmentsImageView)
        
        self.emailAttachmentsAmount = UILabel()
        self.emailAttachmentsAmount.font = UIFont.robotoRegular(size: UIFont.Size.h4)
        self.emailAttachmentsAmount.numberOfLines = 1
        self.emailAttachmentsAmount.text = "\(self.attachmentCount)"
        self.emailAttachmentsAmount.textColor = UIColor.ProtonMail.Gray_999DA1
        self.emailAttachmentsAmount.sizeToFit()
        self.emailHeaderView.addSubview(emailAttachmentsAmount)
        
        if (self.attachmentCount > 0) {
            self.emailAttachmentsAmount.hidden = false
            self.emailHasAttachmentsImageView.hidden = false
        } else {
            self.emailAttachmentsAmount.hidden = true
            self.emailHasAttachmentsImageView.hidden = true
        }
    }
    
    // MARK: - Subview constraints
    
    func makeConstraints() {
        
        self.makeHeaderConstraints()
        
        self.updateAttConstraints(false)
    }
    
    func updateAttConstraints (animition : Bool) {
        attachmentView!.reloadData()
        attachmentView!.layoutIfNeeded();
        
        let h = self.attachmentCount > 0 ? attachmentView!.contentSize.height : 0;
        self.separatorBetweenHeaderAndAttView.hidden = self.attachmentCount == 0
        
        separatorBetweenHeaderAndBodyView.mas_updateConstraints { (make) -> Void in
            make.removeExisting = true
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.top.equalTo()(self.emailHeaderView.mas_bottom).with().offset()(self.kSeparatorBetweenHeaderAndBodyMarginTop)
            make.height.equalTo()(1)
        }
        self.attachmentView!.mas_updateConstraints { (make) -> Void in
            make.removeExisting = true
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.top.equalTo()(self.separatorBetweenHeaderAndBodyView.mas_bottom)
            make.height.equalTo()(h)
        }
        
        emailIsEncryptedImageView.mas_updateConstraints { (make) -> Void in
            make.removeExisting = true
            if (self.attachmentCount > 0) {
                make.right.equalTo()(self.emailHasAttachmentsImageView.mas_left).with().offset()(self.kEmailIsEncryptedImageViewMarginRight)
            } else {
                make.right.equalTo()(self.emailHeaderView)
            }
            
            make.bottom.equalTo()(self.emailAttachmentsAmount)
            make.height.equalTo()(self.emailIsEncryptedImageView.frame.height)
            make.width.equalTo()(self.emailIsEncryptedImageView.frame.width)
        }
        
        separatorBetweenHeaderAndAttView.mas_updateConstraints { (make) -> Void in
            make.removeExisting = true
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.top.equalTo()(self.attachmentView!.mas_bottom)//.with().offset()(self.kSeparatorBetweenHeaderAndBodyMarginTop)
            make.height.equalTo()(1)
        }
        
        self.updateSelf(animition)
    }
    
    private func configureEmailDetailToLabel() {
        
        self.emailDetailToLabel = UILabel()
        self.emailDetailToLabel.font = UIFont.robotoLight(size: UIFont.Size.h6)
        self.emailDetailToLabel.lineBreakMode = NSLineBreakMode.ByCharWrapping
        self.emailDetailToLabel.numberOfLines = 0;
        self.emailDetailToLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailToLabel)
        
        self.emailDetailToContentLabel = UILabel()
        self.emailDetailToContentLabel.font = UIFont.robotoRegular(size: UIFont.Size.h6)
        self.emailDetailToContentLabel.numberOfLines = 1
        self.emailDetailToContentLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailToContentLabel)
    }
    
    private func configureEmailDetailCCLabel() {
        self.emailDetailCCLabel = UILabel()
        self.emailDetailCCLabel.font = UIFont.robotoLight(size: UIFont.Size.h6)
        self.emailDetailCCLabel.lineBreakMode = NSLineBreakMode.ByCharWrapping
        self.emailDetailCCLabel.numberOfLines = 0;
        self.emailDetailCCLabel.text = self.ccText;
        self.emailDetailCCLabel.textColor = UIColor(RRGGBB: UInt(0x838897))// UIColor.ProtonMail.Gray_999DA1
        self.emailDetailCCLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailCCLabel)
        
        self.emailDetailCCContentLabel = UILabel()
        self.emailDetailCCContentLabel.font = UIFont.robotoRegular(size: UIFont.Size.h6)
        self.emailDetailCCContentLabel.numberOfLines = 1
        self.emailDetailCCContentLabel.text = self.ccText;
        self.emailDetailCCContentLabel.textColor = UIColor(RRGGBB: UInt(0x838897)) //UIColor.ProtonMail.Blue_85B1DE
        self.emailDetailCCContentLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailCCContentLabel)
    }
    
    private func configureEmailDetailBCCLabel() {
        self.emailDetailBCCLabel = UILabel()
        self.emailDetailBCCLabel.font = UIFont.robotoLight(size: UIFont.Size.h6)
        self.emailDetailBCCLabel.lineBreakMode = NSLineBreakMode.ByCharWrapping
        self.emailDetailBCCLabel.numberOfLines = 0;
        //self.emailDetailBCCLabel.text = self.bccList
        self.emailDetailBCCLabel.textColor = UIColor(RRGGBB: UInt(0x838897)) //UIColor.ProtonMail.Gray_999DA1
        self.emailDetailBCCLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailBCCLabel)
        
        self.emailDetailBCCContentLabel = UILabel()
        self.emailDetailBCCContentLabel.font = UIFont.robotoRegular(size: UIFont.Size.h6)
        self.emailDetailBCCContentLabel.numberOfLines = 1
        //self.emailDetailBCCContentLabel.text = self.bccList
        self.emailDetailBCCContentLabel.textColor = UIColor(RRGGBB: UInt(0x838897)) //UIColor.ProtonMail.Blue_85B1DE
        self.emailDetailBCCContentLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailBCCContentLabel)
    }
    
    private func configureEmailDetailDateLabel() {
        self.emailDetailDateLabel = UILabel()
        self.emailDetailDateLabel.font = UIFont.robotoLight(size: UIFont.Size.h6)
        self.emailDetailDateLabel.numberOfLines = 1
        if let messageTime = self.date {
            let tm = messageTime.formattedWith("'On' EE, MMM d, yyyy 'at' h:mm a") ?? "";
            self.emailDetailDateLabel.text = "Date: \(tm)"
        } else {
            self.emailDetailDateLabel.text = "Date: "
        }
        self.emailDetailDateLabel.textColor = UIColor(RRGGBB: UInt(0x838897)) //UIColor.ProtonMail.Gray_999DA1
        self.emailDetailDateLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailDateLabel)
        
        self.emailDetailDateContentLabel = UILabel()
        self.emailDetailDateContentLabel.font = UIFont.robotoRegular(size: UIFont.Size.h6)
        self.emailDetailDateContentLabel.numberOfLines = 1
        self.emailDetailDateContentLabel.text = self.date.stringWithFormat(kEmailTimeLongFormat)
        self.emailDetailDateContentLabel.textColor = UIColor(RRGGBB: UInt(0x838897)) //UIColor.ProtonMail.Gray_383A3B
        self.emailDetailDateContentLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailDateContentLabel)
    }
    
    private func makeHeaderConstraints() {
        emailHeaderView.mas_updateConstraints { (make) -> Void in
            make.removeExisting = true
            make.top.equalTo()(self).with().offset()(self.kEmailHeaderViewMarginTop)
            make.left.equalTo()(self).with().offset()(self.kEmailHeaderViewMarginLeft)
            make.right.equalTo()(self).with().offset()(self.kEmailHeaderViewMarginRight)
            make.bottom.equalTo()(self.emailDetailView)
        }
        emailFavoriteButton.mas_updateConstraints { (make) -> Void in
            make.removeExisting = true
            make.top.equalTo()(self.emailHeaderView)
            make.right.equalTo()(self.emailHeaderView)
            make.height.equalTo()(self.kEmailFavoriteButtonHeight)
            make.width.equalTo()(self.kEmailFavoriteButtonWidth)
        }
        
        emailTitle.mas_updateConstraints { (make) -> Void in
            make.removeExisting = true
            make.left.equalTo()(self.emailHeaderView)
            make.top.equalTo()(self.emailHeaderView)
            make.right.equalTo()(self.emailFavoriteButton.mas_left).with().offset()(self.kEmailTitleViewMarginRight)
        }
        
        emailDetailView.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.emailTitle)
            make.right.equalTo()(self.emailHeaderView)
            make.top.equalTo()(self.emailDetailButton.mas_bottom)
            make.height.equalTo()(0)
        }
        
        emailFrom.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.emailHeaderView)
            make.right.equalTo()(self.emailTitle)
            make.top.equalTo()(self.emailTitle.mas_bottom).with().offset()(self.kEmailRecipientsViewMarginTop)
        }
        
        emailFromTable.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(36)
            make.right.equalTo()(self.emailTitle)
            make.top.equalTo()(self.emailTitle.mas_bottom).with().offset()(self.kEmailRecipientsViewMarginTop)
            make.height.equalTo()(self.emailFrom)
        }
        
        let toOffset = self.showTo ? kEmailRecipientsViewMarginTop : 0
        let toHeight = self.showTo ? 16 : 0
        emailTo.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.emailHeaderView)
            make.right.equalTo()(self.emailTitle)
            make.top.equalTo()(self.emailFrom.mas_bottom).with().offset()(toOffset)
            make.height.equalTo()(toHeight)
        }
        emailToTable.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(36)
            make.right.equalTo()(self.emailTitle)
            make.top.equalTo()(self.emailFrom.mas_bottom).with().offset()(toOffset)
            make.height.equalTo()(self.emailTo)
        }
        
        let ccOffset = self.showCc ? kEmailRecipientsViewMarginTop : 0
        emailCc.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.emailHeaderView)
            make.right.equalTo()(self.emailTitle)
            make.top.equalTo()(self.emailTo.mas_bottom).with().offset()(ccOffset)
        }
        emailCcTable.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(36)
            make.right.equalTo()(self.emailTitle)
            make.top.equalTo()(self.emailTo.mas_bottom).with().offset()(ccOffset)
            make.height.equalTo()(self.emailCc)
        }
        
        emailTime.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.emailHeaderView)
            make.width.equalTo()(self.emailTime.frame.size.width)
            make.height.equalTo()(self.emailTime.frame.size.height)
            make.top.equalTo()(self.emailTo.mas_bottom).with().offset()(self.kEmailTimeViewMarginTop)
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
            if (self.attachmentCount > 0) {
                make.right.equalTo()(self.emailHasAttachmentsImageView.mas_left).with().offset()(self.kEmailIsEncryptedImageViewMarginRight)
            } else {
                make.right.equalTo()(self.emailHeaderView)
            }
            
            make.bottom.equalTo()(self.emailAttachmentsAmount)
            make.height.equalTo()(self.emailIsEncryptedImageView.frame.height)
            make.width.equalTo()(self.emailIsEncryptedImageView.frame.width)
        }
    }
    
    private var isShowingDetail: Bool = false
    
    internal func detailsButtonTapped() {
        self.isShowingDetail = !self.isShowingDetail
        self.updateDetailsView(self.isShowingDetail)
    }
    
    internal func emailFavoriteButtonTapped() {
        self.starred = !self.starred
        self.actionsDelegate?.starredChanged(self.starred)
        self.emailFavoriteButton.selected = self.starred
    }
    
    
    private func updateSelf(anim : Bool) {
        UIView.animateWithDuration(anim == true ? 0.3 : 0.0, animations: { () -> Void in
            self.layoutIfNeeded()
            var f = self.frame;
            f.size.height = self.getHeight();
            self.frame = f;
            self.viewDelegate?.updateSize()
        })
    }
    
    private let kAnimationOption: UIViewAnimationOptions = .TransitionCrossDissolve
    private func updateDetailsView(needsShow : Bool) {
        if (needsShow) {
            
            // update views value
            UIView.transitionWithView(self.emailFrom, duration: 0.3, options: kAnimationOption, animations: { () -> Void in
                self.emailFrom.attributedText = self.fromShortAttr
                self.emailTo.attributedText = self.toShortAttr
                self.emailCc.attributedText = self.ccShortAttr
                self.emailFromTable.alpha = 1.0;
                
                self.emailTo.alpha = self.showTo ? 1.0 : 0.0
                self.emailToTable.alpha = self.showTo ? 1.0 : 0.0;
                self.emailCc.alpha = self.showCc ? 1.0 : 0.0
                self.emailCcTable.alpha = self.showCc ? 1.0 : 0.0;
                
                //self.emailDetailToLabel.text = self.toText
                self.emailDetailCCLabel.text = self.ccText
                self.emailDetailBCCLabel.text = self.bccText
                self.emailDetailToLabel.sizeToFit()
                self.emailDetailCCLabel.sizeToFit()
                self.emailDetailBCCLabel.sizeToFit()
                
                
                }, completion: nil)
            
            let efh = emailFromTable.getContentSize().height;
            emailFromTable.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(36)
                make.right.equalTo()(self.emailTitle)
                make.top.equalTo()(self.emailTitle.mas_bottom).with().offset()(self.kEmailRecipientsViewMarginTop)
                make.height.equalTo()(efh)
            }
            
            let toOffset = self.showTo ? kEmailRecipientsViewMarginTop : 0
            let toHeight = self.showTo ? 16 : 0
            emailTo.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailHeaderView)
                make.right.equalTo()(self.emailTitle)
                make.top.equalTo()(self.emailFromTable.mas_bottom).with().offset()(toOffset)
                make.height.equalTo()(toHeight)
            }
            let eth = emailToTable.getContentSize().height;
            emailToTable.mas_makeConstraints { (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(36)
                make.right.equalTo()(self.emailTitle)
                make.top.equalTo()(self.emailFromTable.mas_bottom).with().offset()(toOffset)
                make.height.equalTo()(eth)
            }
            
            emailCc.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailHeaderView)
                make.right.equalTo()(self.emailTitle)
                make.top.equalTo()(self.emailToTable.mas_bottom).with().offset()(self.kEmailRecipientsViewMarginTop)
            }
            
            let ecch = emailCcTable.getContentSize().height;
            emailCcTable.mas_makeConstraints { (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(36)
                make.right.equalTo()(self.emailTitle)
                make.top.equalTo()(self.emailToTable.mas_bottom).with().offset()(self.kEmailRecipientsViewMarginTop)
                make.height.equalTo()(ecch)
            }
            
            self.emailDetailButton.setTitle(NSLocalizedString("Hide Details"), forState: UIControlState.Normal)
            self.emailDetailButton.mas_updateConstraints({ (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailTime)
                make.bottom.equalTo()(self.emailTime)
                make.top.equalTo()(self.emailTime)
                make.width.equalTo()(self.emailDetailButton)
            })
            
            let toHeight1 = self.showTo ? self.emailDetailToLabel.frame.height : 0;
            emailDetailToLabel.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.top.equalTo()(self.emailDetailView)
                make.left.equalTo()(self.emailDetailView)
                make.width.equalTo()(self.emailDetailView)
                make.height.equalTo()(toHeight1)
            }
            emailDetailToContentLabel.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.centerY.equalTo()(self.emailDetailToLabel)
                make.left.equalTo()(self.emailDetailToLabel.mas_right)
                make.right.equalTo()(self.emailDetailView)
                make.height.equalTo()(self.emailDetailToContentLabel.frame.size.height)
            }
            
            let ccHeight = self.showCc ? self.emailDetailCCLabel.frame.size.height : 0
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
            
            let bccHeight = self.showBcc ? self.emailDetailBCCLabel.frame.size.height : 0
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
            
            emailDetailDateLabel.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailDetailToLabel)
                make.top.equalTo()(self.emailDetailBCCLabel.mas_bottom).with().offset()(self.kEmailDetailDateLabelMarginTop)
                make.width.equalTo()(self.emailDetailToLabel)
                make.height.equalTo()(self.emailDetailBCCLabel.frame.size.height)
            }
            emailDetailDateContentLabel.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.centerY.equalTo()(self.emailDetailDateLabel)
                make.left.equalTo()(self.emailDetailDateLabel.mas_right)
                make.right.equalTo()(self.emailDetailView)
                make.height.equalTo()(self.emailDetailDateLabel.frame.size.height)
            }
            
            self.emailTime.mas_updateConstraints({ (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailHeaderView)
                make.width.equalTo()(0)
                make.height.equalTo()(self.emailTime.frame.size.height)
                make.top.equalTo()(self.emailCcTable.mas_bottom).with().offset()(self.kEmailTimeViewMarginTop)
            })
            
            self.emailDetailView.mas_updateConstraints({ (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailTitle)
                make.right.equalTo()(self.emailHeaderView)
                make.top.equalTo()(self.emailDetailButton.mas_bottom).with().offset()(10)
                make.bottom.equalTo()(self.emailDetailDateLabel)
            })
        } else {
            
            UIView.transitionWithView(self.emailFrom, duration: 0.3, options: kAnimationOption, animations: { () -> Void in
                self.emailFrom.attributedText = self.fromSinglelineAttr
                self.emailTo.attributedText = self.toSinglelineAttr
                self.emailFromTable.alpha = 0.0;
                self.emailToTable.alpha = 0.0;
                self.emailCc.alpha = 0.0;
                self.emailCcTable.alpha = 0.0
                }, completion: nil)
            
            emailFromTable.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(36)
                make.right.equalTo()(self.emailTitle)
                make.top.equalTo()(self.emailFrom)
                make.height.equalTo()(self.emailFrom)
            }
            
            let toOffset = self.showTo ? kEmailRecipientsViewMarginTop : 0
            let toHeight = self.showTo ? 16 : 0
            emailTo.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailHeaderView)
                make.right.equalTo()(self.emailTitle)
                make.top.equalTo()(self.emailFrom.mas_bottom).with().offset()(toOffset)
                make.height.equalTo()(toHeight)
            }
            emailToTable.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(36)
                make.right.equalTo()(self.emailTitle)
                make.top.equalTo()(self.emailTo)
                make.height.equalTo()(self.emailTo)
            }
            
                        emailCcTable.mas_makeConstraints { (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(36)
                make.right.equalTo()(self.emailTitle)
                make.top.equalTo()(self.emailCc).with().offset()(self.kEmailRecipientsViewMarginTop)
                make.height.equalTo()(self.emailCc)
            }

            
            
            self.emailDetailButton.setTitle(NSLocalizedString("Details"), forState: UIControlState.Normal)
            self.emailDetailButton.mas_updateConstraints({ (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailTime.mas_right).with().offset()(self.kEmailDetailButtonMarginLeft)
                make.bottom.equalTo()(self.emailTime)
                make.top.equalTo()(self.emailTime)
                make.width.equalTo()(self.emailDetailButton)
            })
            
            self.emailFrom.sizeToFit();
            emailFrom.mas_makeConstraints { (make) -> Void in
                make.left.equalTo()(self.emailHeaderView)
                make.width.equalTo()(self.emailFrom.frame.size.width)
                make.height.equalTo()(self.emailFrom.frame.size.height)
                make.top.equalTo()(self.emailTitle.mas_bottom).with().offset()(self.kEmailRecipientsViewMarginTop)
            }
            
            
            self.emailTo.sizeToFit();
            emailTo.mas_makeConstraints { (make) -> Void in
                make.left.equalTo()(self.emailHeaderView)
                make.width.equalTo()(self.emailTo.frame.size.width)
                make.height.equalTo()(self.emailTo.frame.size.height)
                make.top.equalTo()(self.emailFrom.mas_bottom).with().offset()(self.kEmailRecipientsViewMarginTop)
            }
            
            self.emailTime.sizeToFit()
            self.emailTime.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailHeaderView)
                make.width.equalTo()(self.emailTime.frame.size.width)
                make.height.equalTo()(self.emailTime.frame.size.height)
                make.top.equalTo()(self.emailToTable.mas_bottom).with().offset()(self.kEmailTimeViewMarginTop)
            }
            
            self.emailDetailView.mas_updateConstraints({ (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailTitle)
                make.right.equalTo()(self.emailHeaderView)
                make.top.equalTo()(self.emailDetailButton.mas_bottom)
                make.height.equalTo()(0)
            })
        }
        
        self.updateSelf(true)
    }
}



extension EmailHeaderView: UITableViewDataSource {
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let attachment = attachmentForIndexPath(indexPath)
        let cell = tableView.dequeueReusableCellWithIdentifier(AttachmentTableViewCell.Constant.identifier, forIndexPath: indexPath) as! AttachmentTableViewCell
        // cell.setFilename("test", fileSize: 1000)
        cell.setFilename(attachment.fileName, fileSize: Int(attachment.fileSize))
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  attachments.count
    }
}

extension EmailHeaderView: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let attachment = attachmentForIndexPath(indexPath)
        if !attachment.isDownloaded {
            downloadAttachment(attachment, forIndexPath: indexPath)
        } else if let localURL = attachment.localURL {
            if NSFileManager.defaultManager().fileExistsAtPath(attachment.localURL!.path!, isDirectory: nil) {
                let cell = tableView.cellForRowAtIndexPath(indexPath)
                let data: NSData = NSData(base64EncodedString: attachment.keyPacket!, options: NSDataBase64DecodingOptions(rawValue: 0))!
                openLocalURL(localURL, keyPackage: data, fileName: attachment.fileName, forCell: cell!)
            } else {
                attachment.localURL = nil
                let error = attachment.managedObjectContext?.saveUpstreamIfNeeded()
                if error != nil  {
                    NSLog("\(__FUNCTION__) error: \(error)")
                }
                
                downloadAttachment(attachment, forIndexPath: indexPath)
            }
        }
    }
    
    // MARK: Private methods
    
    private func downloadAttachment(attachment: Attachment, forIndexPath indexPath: NSIndexPath) {
        sharedMessageDataService.fetchAttachmentForAttachment(attachment, downloadTask: { (task) -> Void in
            if let cell = self.attachmentView!.cellForRowAtIndexPath(indexPath) as? AttachmentTableViewCell {
                cell.progressView.alpha = 1.0
                cell.progressView.setProgressWithDownloadProgressOfTask(task, animated: true)
            }
            }, completion: { (_, url, error) -> Void in
                if let cell = self.attachmentView!.cellForRowAtIndexPath(indexPath) as? AttachmentTableViewCell {
                    UIView.animateWithDuration(0.25, animations: { () -> Void in
                        cell.progressView.hidden = true
                        if let localURL = attachment.localURL {
                            if NSFileManager.defaultManager().fileExistsAtPath(attachment.localURL!.path!, isDirectory: nil) {
                                let cell = self.attachmentView!.cellForRowAtIndexPath(indexPath)
                                let data: NSData = NSData(base64EncodedString: attachment.keyPacket!, options: NSDataBase64DecodingOptions(rawValue: 0))!
                                self.openLocalURL(localURL, keyPackage: data, fileName: attachment.fileName, forCell: cell!)
                            }
                        }
                    })
                }
        })
    }
    
    private func openLocalURL(localURL: NSURL, keyPackage:NSData, fileName:String, forCell cell: UITableViewCell) {
        self.actionsDelegate?.quickLookAttachment(localURL, keyPackage: keyPackage, fileName: fileName)
    }
}