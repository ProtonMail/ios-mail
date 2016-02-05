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
    
    private var emailShortTime: UILabel!
    
    private var emailDetailButton: UIButton!
    
    private var emailDetailView: UIView!
    
    private var emailDetailDateLabel: UILabel!
    
    private var LabelOne: UILabel!
    private var LabelTwo: UILabel!
    private var LabelThree: UILabel!
    private var LabelFour: UILabel!
    private var LabelFive: UILabel!
    
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
    private let kEmailFavoriteButtonHeight: CGFloat = 44
    private let kEmailFavoriteButtonWidth: CGFloat = 52
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
    private var labels : [Label]?
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
            var count = (toList?.count ?? 0)
            if count > 0 {
                count += (ccList?.count ?? 0) + (bccList?.count ?? 0)
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
    
    private var showLabels : Bool {
        get {
            return (self.labels?.count ?? 0) > 0 ? true : false
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
    func updateHeaderData (title : String, sender : ContactVO, to : [ContactVO]?, cc : [ContactVO]?, bcc : [ContactVO]?, isStarred : Bool, time : NSDate?, encType : EncryptTypes, labels : [Label]?) {
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
        
        self.emailFavoriteButton.selected = self.starred;
        
        self.emailShortTime.text = "at \(self.date.stringWithFormat(self.kHourMinuteFormat))".lowercaseString
        
        let tm = self.date.formattedWith("'On' EE, MMM d, yyyy 'at' h:mm a") ?? "";
        self.emailDetailDateLabel.text = "Date: \(tm)"
        
        var lockType : LockTypes = encType.lockType
        switch (lockType) {
        case .PlainTextLock:
            self.emailIsEncryptedImageView.image = UIImage(named: "mail_lock");
            self.emailIsEncryptedImageView.highlighted = true;
            break
        case .EncryptLock:
            self.emailIsEncryptedImageView.image = UIImage(named: "mail_lock");
            self.emailIsEncryptedImageView.highlighted = false;
            break
        case .PGPLock:
            self.emailIsEncryptedImageView.image = UIImage(named: "mail_lock-pgpmime");
            self.emailIsEncryptedImageView.highlighted = false;
            break;
        }
        
        self.labels = labels;
        if let labels = labels {
            let lc = labels.count - 1;
            for i in 0 ... 4 {
                switch i {
                case 0:
                    var label : Label? = nil
                    if i <= lc {
                        label = labels[i] as Label
                    }
                    self.updateLablesDetails(LabelOne, label: label)
                case 1:
                    var label : Label? = nil
                    if i <= lc {
                        label = labels[i] as Label
                    }
                    self.updateLablesDetails(LabelTwo, label: label)
                case 2:
                    var label : Label? = nil
                    if i <= lc {
                        label = labels[i] as Label
                    }
                    self.updateLablesDetails(LabelThree, label: label)
                case 3:
                    var label : Label? = nil
                    if i <= lc {
                        label = labels[i] as Label
                    }
                    self.updateLablesDetails(LabelFour, label: label)
                case 4:
                    var label : Label? = nil
                    if i <= lc {
                        label = labels[i] as Label
                    }
                    self.updateLablesDetails(LabelFive, label: label)
                default:
                    break;
                }
            }
        }
        
    }
    
    private func updateLablesDetails (labelView : UILabel, label:Label?) {
        if let label = label {
            if label.name.isEmpty || label.color.isEmpty {
                labelView.text = ""
            } else {
                labelView.text = "  \(label.name)  "
                labelView.textColor = UIColor(hexString: label.color, alpha: 1.0)
                labelView.layer.borderColor = UIColor(hexString: label.color, alpha: 1.0).CGColor
            }
        } else {
            labelView.text = ""
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
        self.emailFavoriteButton.contentVerticalAlignment = UIControlContentVerticalAlignment.Center
        self.emailFavoriteButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Center
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
        
        self.emailShortTime = UILabel()
        self.emailShortTime.font = UIFont.robotoMedium(size: UIFont.Size.h6)
        self.emailShortTime.numberOfLines = 1
        self.emailShortTime.text = "at \(self.date.stringWithFormat(self.kHourMinuteFormat))".lowercaseString
        self.emailShortTime.textColor = UIColor(RRGGBB: UInt(0x838897))
        self.emailShortTime.sizeToFit()
        self.emailHeaderView.addSubview(emailShortTime)
        
        self.emailDetailButton = UIButton()
        self.emailDetailButton.addTarget(self, action: "detailsButtonTapped", forControlEvents: UIControlEvents.TouchUpInside)
        self.emailDetailButton.contentEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
        self.emailDetailButton.titleLabel?.font = UIFont.robotoMedium(size: UIFont.Size.h6)
        self.emailDetailButton.setTitle(NSLocalizedString("Details"), forState: UIControlState.Normal)
        self.emailDetailButton.setTitleColor(UIColor(RRGGBB: UInt(0x9397CD)), forState: UIControlState.Normal)
        self.emailDetailButton.sizeToFit()
        self.emailHeaderView.addSubview(emailDetailButton)
        
        self.configureEmailDetailDateLabel()
        
        self.emailIsEncryptedImageView = UIImageView(image: UIImage(named: "mail_lock"))
        self.emailIsEncryptedImageView.highlightedImage = UIImage(named: "mail_lock-outside")
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
            make.top.equalTo()(self.LabelOne.mas_bottom).with().offset()(self.kSeparatorBetweenHeaderAndBodyMarginTop)
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
                make.right.equalTo()(self.emailHeaderView).offset()(-16)
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
    
    private func configureEmailDetailDateLabel() {
        self.emailDetailDateLabel = UILabel()
        self.emailDetailDateLabel.font = UIFont.robotoMedium(size: UIFont.Size.h6)
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
        
        self.LabelOne = UILabel()
        self.LabelOne.sizeToFit()
        self.LabelOne.clipsToBounds = true
        self.LabelOne.layer.borderWidth = 1
        self.LabelOne.layer.cornerRadius = 2
        self.LabelOne.font = UIFont.robotoLight(size: 9)
        self.addSubview(LabelOne)
        
        self.LabelTwo = UILabel()
        self.LabelTwo.sizeToFit()
        self.LabelTwo.clipsToBounds = true
        self.LabelTwo.layer.borderWidth = 1
        self.LabelTwo.layer.cornerRadius = 2
        self.LabelTwo.font = UIFont.robotoLight(size: 9)
        self.addSubview(LabelTwo)
        
        self.LabelThree = UILabel()
        self.LabelThree.sizeToFit()
        self.LabelThree.clipsToBounds = true
        self.LabelThree.layer.borderWidth = 1
        self.LabelThree.layer.cornerRadius = 2
        self.LabelThree.font = UIFont.robotoLight(size: 9)
        self.addSubview(LabelThree)
        
        self.LabelFour = UILabel()
        self.LabelFour.sizeToFit()
        self.LabelFour.clipsToBounds = true
        self.LabelFour.layer.borderWidth = 1
        self.LabelFour.layer.cornerRadius = 2
        self.LabelFour.font = UIFont.robotoLight(size: 9)
        self.addSubview(LabelFour)
        
        self.LabelFive = UILabel()
        self.LabelFive.sizeToFit()
        self.LabelFive.clipsToBounds = true
        self.LabelFive.layer.borderWidth = 1
        self.LabelFive.layer.cornerRadius = 2
        self.LabelFive.font = UIFont.robotoLight(size: 9)
        self.addSubview(LabelFive)
        
    }
    
    private func makeHeaderConstraints() {
        emailHeaderView.mas_updateConstraints { (make) -> Void in
            make.removeExisting = true
            make.top.equalTo()(self).with().offset()(0)
            make.left.equalTo()(self).with().offset()(self.kEmailHeaderViewMarginLeft)
            make.right.equalTo()(self).with().offset()(0)
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
            make.top.equalTo()(self.emailHeaderView).offset()(self.kEmailHeaderViewMarginTop)
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
            make.right.equalTo()(self.emailHeaderView)
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
            make.right.equalTo()(self.emailHeaderView)
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
            make.right.equalTo()(self.emailHeaderView)
            make.top.equalTo()(self.emailTo.mas_bottom).with().offset()(ccOffset)
            make.height.equalTo()(self.emailCc)
        }
        
        emailShortTime.sizeToFit()
        emailShortTime.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.emailHeaderView)
            make.width.equalTo()(self.emailShortTime.frame.size.width)
            make.height.equalTo()(self.emailShortTime.frame.size.height)
            make.top.equalTo()(self.emailTo.mas_bottom).with().offset()(self.kEmailTimeViewMarginTop)
        }
        
        emailDetailButton.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.emailShortTime.mas_right).with().offset()(self.kEmailDetailButtonMarginLeft)
            make.bottom.equalTo()(self.emailShortTime)
            make.top.equalTo()(self.emailShortTime)
            make.width.equalTo()(self.emailDetailButton)
        }
        
        emailDetailView.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.emailTitle)
            make.right.equalTo()(self.emailHeaderView)
            make.top.equalTo()(self.emailDetailButton.mas_bottom)
            make.height.equalTo()(0)
        }
        
        emailDetailDateLabel.sizeToFit()
        emailDetailDateLabel.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.emailDetailView)
            make.top.equalTo()(self.emailDetailView)
            make.width.equalTo()(self.emailDetailDateLabel.frame.size.width)
            make.height.equalTo()(self.emailDetailDateLabel.frame.size.height)
        }
        
        LabelOne.sizeToFit()
        let lbOffset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
        let lbHeight = self.showLabels ? self.LabelOne.frame.size.height : 0
        LabelOne.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.emailHeaderView)
            make.top.equalTo()(self.emailDetailView.mas_bottom).with().offset()(lbOffset)
            make.width.equalTo()(self.LabelOne.frame.size.width)
            make.height.equalTo()(lbHeight)
        }
        
        LabelTwo.sizeToFit()
        let lb2Offset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
        let lb2Height = self.showLabels ? self.LabelTwo.frame.size.height : 0
        LabelTwo.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.LabelOne.mas_right).with().offset()(2)
            make.top.equalTo()(self.emailDetailView.mas_bottom).with().offset()(lb2Offset)
            make.width.equalTo()(self.LabelTwo.frame.size.width)
            make.height.equalTo()(lb2Height)
        }
        
        LabelThree.sizeToFit()
        let lb3Offset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
        let lb3Height = self.showLabels ? self.LabelThree.frame.size.height : 0
        LabelThree.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.LabelTwo.mas_right).with().offset()(2)
            make.top.equalTo()(self.emailDetailView.mas_bottom).with().offset()(lb3Offset)
            make.width.equalTo()(self.LabelThree.frame.size.width)
            make.height.equalTo()(lb3Height)
        }
        
        LabelFour.sizeToFit()
        let lb4Offset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
        let lb4Height = self.showLabels ? self.LabelFour.frame.size.height : 0
        LabelFour.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.LabelThree.mas_right).with().offset()(2)
            make.top.equalTo()(self.emailDetailView.mas_bottom).with().offset()(lb4Offset)
            make.width.equalTo()(self.LabelFour.frame.size.width)
            make.height.equalTo()(lb4Height)
        }
        
        LabelFive.sizeToFit()
        let lb5Offset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
        let lb5Height = self.showLabels ? self.LabelFive.frame.size.height : 0
        LabelFive.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.LabelFour.mas_right).with().offset()(2)
            make.top.equalTo()(self.emailDetailView.mas_bottom).with().offset()(lb5Offset)
            make.width.equalTo()(self.LabelFive.frame.size.width)
            make.height.equalTo()(lb5Height)
        }
        
        emailAttachmentsAmount.mas_makeConstraints { (make) -> Void in
            make.right.equalTo()(self.emailHeaderView).offset()(-16)
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
                
                }, completion: nil)
            
            let efh = emailFromTable.getContentSize().height;
            emailFromTable.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(36)
                make.right.equalTo()(self.emailHeaderView)
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
                make.right.equalTo()(self.emailHeaderView)
                make.top.equalTo()(self.emailFromTable.mas_bottom).with().offset()(toOffset)
                make.height.equalTo()(eth)
            }
            
            let ccOffset = self.showCc ? kEmailRecipientsViewMarginTop : 0
            let ccHeight = self.showCc ? 16 : 0
            emailCc.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailHeaderView)
                make.right.equalTo()(self.emailTitle)
                make.top.equalTo()(self.emailToTable.mas_bottom).with().offset()(ccOffset)
                make.height.equalTo()(ccHeight)
            }
            let ecch = emailCcTable.getContentSize().height;
            emailCcTable.mas_makeConstraints { (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(36)
                make.right.equalTo()(self.emailHeaderView)
                make.top.equalTo()(self.emailToTable.mas_bottom).with().offset()(ccOffset)
                make.height.equalTo()(ecch)
            }
            
            self.emailShortTime.mas_updateConstraints({ (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailHeaderView)
                make.width.equalTo()(0)
                make.height.equalTo()(self.emailShortTime.frame.size.height)
                make.top.equalTo()(self.emailCcTable.mas_bottom).with().offset()(self.kEmailTimeViewMarginTop)
            })
            
            self.emailDetailButton.setTitle(NSLocalizedString("Hide Details"), forState: UIControlState.Normal)
            self.emailDetailButton.mas_updateConstraints({ (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailShortTime)
                make.bottom.equalTo()(self.emailShortTime)
                make.top.equalTo()(self.emailShortTime)
                make.width.equalTo()(self.emailDetailButton)
            })
            
            emailDetailDateLabel.sizeToFit()
            emailDetailDateLabel.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailDetailView)
                make.top.equalTo()(self.emailDetailView)
                make.width.equalTo()(self.emailDetailDateLabel.frame.size.width)
                make.height.equalTo()(self.emailDetailDateLabel.frame.size.height)
            }
            
            LabelOne.sizeToFit()
            let lbOffset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
            let lbHeight = self.showLabels ? self.LabelOne.frame.size.height : 0
            LabelOne.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailDetailView)
                make.top.equalTo()(self.emailDetailView.mas_bottom).with().offset()(lbOffset)
                make.width.equalTo()(self.LabelOne.frame.size.width)
                make.height.equalTo()(lbHeight)
            }
            
            LabelTwo.sizeToFit()
            let lb2Offset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
            let lb2Height = self.showLabels ? self.LabelTwo.frame.size.height : 0
            LabelTwo.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.LabelOne.mas_right).with().offset()(2)
                make.top.equalTo()(self.emailDetailView.mas_bottom).with().offset()(lb2Offset)
                make.width.equalTo()(self.LabelTwo.frame.size.width)
                make.height.equalTo()(lb2Height)
            }
            
            LabelThree.sizeToFit()
            let lb3Offset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
            let lb3Height = self.showLabels ? self.LabelThree.frame.size.height : 0
            LabelThree.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.LabelTwo.mas_right).with().offset()(2)
                make.top.equalTo()(self.emailDetailView.mas_bottom).with().offset()(lb3Offset)
                make.width.equalTo()(self.LabelThree.frame.size.width)
                make.height.equalTo()(lb3Height)
            }
            
            LabelFour.sizeToFit()
            let lb4Offset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
            let lb4Height = self.showLabels ? self.LabelFour.frame.size.height : 0
            LabelFour.mas_updateConstraints { (make) -> Void in
                make.left.equalTo()(self.LabelThree.mas_right).with().offset()(2)
                make.top.equalTo()(self.emailDetailView.mas_bottom).with().offset()(lb4Offset)
                make.width.equalTo()(self.LabelFour.frame.size.width)
                make.height.equalTo()(lb4Height)
            }
            
            LabelFive.sizeToFit()
            let lb5Offset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
            let lb5Height = self.showLabels ? self.LabelFive.frame.size.height : 0
            LabelFive.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.LabelFour.mas_right).with().offset()(2)
                make.top.equalTo()(self.emailDetailView.mas_bottom).with().offset()(lb5Offset)
                make.width.equalTo()(self.LabelFive.frame.size.width)
                make.height.equalTo()(lb5Height)
            }
            
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
                make.right.equalTo()(self.emailHeaderView)
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
                make.right.equalTo()(self.emailHeaderView)
                make.top.equalTo()(self.emailTo)
                make.height.equalTo()(toHeight)
            }
            
            emailCc.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailHeaderView)
                make.right.equalTo()(self.emailTitle)
                make.top.equalTo()(self.emailToTable.mas_bottom).with().offset()(0)
                make.height.equalTo()(0)
            }
            emailCcTable.mas_makeConstraints { (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(36)
                make.right.equalTo()(self.emailHeaderView)
                make.top.equalTo()(self.emailCc).with().offset()(self.kEmailRecipientsViewMarginTop)
                make.height.equalTo()(0)
            }
            
            self.emailDetailButton.setTitle(NSLocalizedString("Details"), forState: UIControlState.Normal)
            self.emailDetailButton.mas_updateConstraints({ (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailShortTime.mas_right).with().offset()(self.kEmailDetailButtonMarginLeft)
                make.bottom.equalTo()(self.emailShortTime)
                make.top.equalTo()(self.emailShortTime)
                make.width.equalTo()(self.emailDetailButton)
            })
            
            self.emailFrom.sizeToFit();
            emailFrom.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailHeaderView)
                make.width.equalTo()(self.emailFrom.frame.size.width)
                make.height.equalTo()(self.emailFrom.frame.size.height)
                make.top.equalTo()(self.emailTitle.mas_bottom).with().offset()(self.kEmailRecipientsViewMarginTop)
            }
            
            self.emailTo.sizeToFit();
            emailTo.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailHeaderView)
                make.width.equalTo()(self.emailTo.frame.size.width)
                make.height.equalTo()(self.emailTo.frame.size.height)
                make.top.equalTo()(self.emailFrom.mas_bottom).with().offset()(toOffset)
            }
            
            self.emailShortTime.sizeToFit()
            self.emailShortTime.mas_updateConstraints { (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.emailHeaderView)
                make.width.equalTo()(self.emailShortTime.frame.size.width)
                make.height.equalTo()(self.emailShortTime.frame.size.height)
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
        cell.setFilename(attachment.fileName, fileSize: Int(attachment.fileSize))
        cell.configAttachmentIcon(attachment.mimeType)
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  attachments.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 34;
    }
}

extension EmailHeaderView: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if attachments.count > indexPath.row {
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
    }
    
    // MARK: Private methods
    
    private func downloadAttachment(attachment: Attachment, forIndexPath indexPath: NSIndexPath) {
        sharedMessageDataService.fetchAttachmentForAttachment(attachment, downloadTask: { (taskOne : NSURLSessionDownloadTask) -> Void in
            if let cell = self.attachmentView!.cellForRowAtIndexPath(indexPath) as? AttachmentTableViewCell {
                //task.set
                //let session = AFHTTPSessionManager.manager .manager;
                cell.progressView.alpha = 1.0
                cell.progressView.progress = 0.0
                //cell.progressView.setProgressWithDownloadProgressOfTask(task, animated: true)

                let totalValue = attachment.fileSize.floatValue;
                sharedAPIService.getSession().setDownloadTaskDidWriteDataBlock({ (session, taskTwo, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) -> Void in
                    if taskOne == taskTwo {
                        NSLog("\(totalValue)")
                        NSLog("%lld  - %lld - %lld", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
                        
                        var progressPercentage =  ( Float(totalBytesWritten) / totalValue )
                        NSLog("\(progressPercentage)")
                        if progressPercentage >= 1.000000000 {
                            progressPercentage = 1.0
                        }
                        dispatch_async(dispatch_get_main_queue(), {
                            UIView.animateWithDuration(0.25, animations: { () -> Void in
                                cell.progressView.progress = progressPercentage
                            })
                        });
                    }
                })
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
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        
    }
    //    - (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
    //    {
    //    if ([keyPath isEqualToString:@"fractionCompleted"]) {
    //    NSProgress *progress = (NSProgress *)object;
    //    NSLog(@"Progress… %f", progress.fractionCompleted);
    //    } else {
    //    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    //    }
    //    }
    
    private func openLocalURL(localURL: NSURL, keyPackage:NSData, fileName:String, forCell cell: UITableViewCell) {
        self.actionsDelegate?.quickLookAttachment(localURL, keyPackage: keyPackage, fileName: fileName)
    }
}