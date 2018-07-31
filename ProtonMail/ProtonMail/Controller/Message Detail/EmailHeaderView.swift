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

protocol EmailHeaderActionsProtocol: RecipientViewDelegate, ShowImageViewProtocol {
    func quickLook(attachment tempfile : URL, keyPackage:Data, fileName:String, type: String)
    
    func star(changed isStarred : Bool)
    
    func showImage()
}

class EmailHeaderView: UIView {
    
    var viewDelegate: EmailHeaderViewProtocol?
    private var _delegate: EmailHeaderActionsProtocol?
    
    var delegate :EmailHeaderActionsProtocol? {
        get {
            return self._delegate
        }
        set {
            self._delegate = newValue
            //set delegate here
            self.emailFromTable.delegate = self._delegate
            self.emailToTable.delegate = self._delegate
            self.emailCcTable.delegate = self._delegate
            self.showImageView.delegate = self._delegate
        }
    }
    
    /// Header Content View
    fileprivate var emailHeaderView: UIView!
    
    fileprivate var emailTitle: UILabel!
    
    fileprivate var emailFrom: UILabel!    //from or sender
    fileprivate var emailFromTable: RecipientView!
    
    fileprivate var emailTo: UILabel!    //to
    fileprivate var emailToTable: RecipientView!
    
    fileprivate var emailCc: UILabel!    //cc
    fileprivate var emailCcTable: RecipientView!
    
    fileprivate var emailShortTime: UILabel!
    
    fileprivate var emailDetailButton: UIButton!
    
    fileprivate var emailDetailView: UIView!
    
    fileprivate var emailDetailDateLabel: UILabel!
    
    fileprivate var LabelOne: UILabel!
    fileprivate var LabelTwo: UILabel!
    fileprivate var LabelThree: UILabel!
    fileprivate var LabelFour: UILabel!
    fileprivate var LabelFive: UILabel!
    
    fileprivate var emailFavoriteButton: UIButton!
//    fileprivate var emailIsEncryptedImageView: UIImageView!
    fileprivate var emailHasAttachmentsImageView: UIImageView!
    fileprivate var emailAttachmentsAmount: UILabel!
    
    fileprivate var attachmentView : UITableView?
    
    fileprivate var expirationView : ExpirationView!
    fileprivate var showImageView : ShowImageView!
    fileprivate var spamScoreView : SpamScoreWarningView!
    
    //separators
    fileprivate var separatorHeader : UIView!
    fileprivate var separatorExpiration : UIView!
    fileprivate var separatorAttachment : UIView!
    fileprivate var separatorShowImage : UIView!
    
    // const header view
    fileprivate let kEmailHeaderViewMarginTop: CGFloat = 12.0
    fileprivate let kEmailHeaderViewMarginLeft: CGFloat = 16.0
    fileprivate let kEmailHeaderViewMarginRight: CGFloat = -16.0
    
    fileprivate let kEmailHeaderViewHeight: CGFloat = 70.0
    fileprivate let kEmailTitleViewMarginRight: CGFloat = -8.0
    fileprivate let kEmailFavoriteButtonHeight: CGFloat = 44
    fileprivate let kEmailFavoriteButtonWidth: CGFloat = 52
    fileprivate let kEmailRecipientsViewMarginTop: CGFloat = 6.0
    fileprivate let kEmailTimeViewMarginTop: CGFloat = 6.0
    fileprivate let kEmailDetailToWidth: CGFloat = 40.0
    fileprivate let kEmailDetailCCLabelMarginTop: CGFloat = 10.0
    fileprivate let kEmailDetailDateLabelMarginTop: CGFloat = 10.0
    fileprivate let kEmailDetailButtonMarginLeft: CGFloat = 5.0
    fileprivate let kEmailHasAttachmentsImageViewMarginRight: CGFloat = -4.0
//    fileprivate let kEmailIsEncryptedImageViewMarginRight: CGFloat = -8.0
    fileprivate let kEmailBodyTextViewMarginLeft: CGFloat = 0//-16.0
    fileprivate let kEmailBodyTextViewMarginRight: CGFloat = 0//-16.0
    fileprivate let kEmailBodyTextViewMarginTop: CGFloat = 16.0
    fileprivate let kSeparatorBetweenHeaderAndBodyMarginTop: CGFloat = 16.0
    
    fileprivate let k12HourMinuteFormat = "h:mm a"
    fileprivate let k24HourMinuteFormat = "HH:mm"

    fileprivate var tempFileUri : URL?
    
    fileprivate var isSentFolder : Bool = false
    
    func getHeight () -> CGFloat {
        return separatorShowImage.frame.origin.y + 6;
    }
    
    fileprivate var visible : Bool = false
    
    fileprivate var title : String!
    fileprivate var sender : ContactVO?
    fileprivate var toList : [ContactVO]?
    fileprivate var ccList : [ContactVO]?
    fileprivate var bccList : [ContactVO]?
    fileprivate var labels : [Label]?
    fileprivate var attachmentCount : Int = 0
    fileprivate var attachments : [Attachment] = []
    
    fileprivate var date : Date!
    fileprivate var starred : Bool!
    
    fileprivate var hasExpiration : Bool = false
    fileprivate var hasShowImageCheck : Bool = true
    
    fileprivate var spamScore: MessageSpamScore = .others
    
    
    var isShowingDetail: Bool = true
    
    
    fileprivate var fromSinglelineAttr : NSMutableAttributedString! {
        get {
            let n = self.sender?.name ?? ""
            let e = self.sender?.email ?? ""
            let f = LocalString._general_from_label
            let from = "\(f) \((n.isEmpty ? e : n))"
            let formRange = NSRange (location: 0, length: from.count)
            let attributedString = NSMutableAttributedString(string: from,
                                                             attributes: [NSAttributedStringKey.font : Fonts.h6.medium,
                                                                          NSAttributedStringKey.foregroundColor : UIColor(hexColorCode: "#838897")])
            attributedString.setAttributes([NSAttributedStringKey.font : Fonts.h6.medium,
                                            NSAttributedStringKey.foregroundColor : UIColor(hexColorCode: "#C0C4CE")],
                                           range: formRange)
            
            return attributedString
        }
    }
    
    fileprivate var fromShortAttr : NSMutableAttributedString! {
        get {
            let f = LocalString._general_from_label
            let from = "\(f) "
            let formRange = NSRange (location: 0, length: from.count)
            let attributedString = NSMutableAttributedString(string: from,
                                                             attributes: [NSAttributedStringKey.font : Fonts.h6.medium,
                                                                          NSAttributedStringKey.foregroundColor : UIColor(hexColorCode: "#838897")])
            attributedString.setAttributes([NSAttributedStringKey.font : Fonts.h6.medium,
                                            NSAttributedStringKey.foregroundColor : UIColor(hexColorCode: "#C0C4CE")],
                                           range: formRange)
            return attributedString
        }
    }
    
    fileprivate var toSinglelineAttr : NSMutableAttributedString! {
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
            
            let t = LocalString._general_to_label
            let to = "\(t) \(strTo)"
            let formRange = NSRange (location: 0, length: to.count)
            let attributedString = NSMutableAttributedString(string: to,
                                                             attributes: [NSAttributedStringKey.font : Fonts.h6.medium,
                                                                          NSAttributedStringKey.foregroundColor : UIColor(hexColorCode: "#838897")])
            attributedString.setAttributes([NSAttributedStringKey.font : Fonts.h6.medium,
                                            NSAttributedStringKey.foregroundColor : UIColor(hexColorCode: "#C0C4CE")],
                                           range: formRange)
            return attributedString
        }
    }
    
    fileprivate var toShortAttr : NSMutableAttributedString! {
        get {
            let t = LocalString._general_to_label
            let to = "\(t) "
            let formRange = NSRange (location: 0, length: to.count)
            let attributedString = NSMutableAttributedString(string: to,
                                                             attributes: [NSAttributedStringKey.font : Fonts.h6.medium,
                                                                          NSAttributedStringKey.foregroundColor : UIColor(hexColorCode: "#838897")])
            attributedString.setAttributes([NSAttributedStringKey.font : Fonts.h6.medium,
                                            NSAttributedStringKey.foregroundColor : UIColor(hexColorCode: "#C0C4CE")],
                                           range: formRange)
            return attributedString
        }
    }
    
    fileprivate var ccShortAttr : NSMutableAttributedString! {
        get {
            let c = LocalString._general_cc_label
            let cc = "\(c) "
            let formRange = NSRange (location: 0, length: cc.count)
            let attributedString = NSMutableAttributedString(string: cc,
                                                             attributes: [NSAttributedStringKey.font : Fonts.h6.medium,
                                                                          NSAttributedStringKey.foregroundColor : UIColor(hexColorCode: "#838897")])
            attributedString.setAttributes([NSAttributedStringKey.font : Fonts.h6.medium,
                                            NSAttributedStringKey.foregroundColor : UIColor(hexColorCode: "#C0C4CE")],
                                           range: formRange)
            return attributedString
        }
    }
    
    fileprivate var showTo : Bool {
        get {
            return  (self.toList?.count ?? 0) > 0 ? true : false
        }
    }
    
    fileprivate var showCc : Bool {
        get {
            return (self.ccList?.count ?? 0) > 0 ? true : false
        }
    }
    
    fileprivate var showBcc : Bool {
        get {
            return (self.bccList?.count ?? 0) > 0 ? true : false
        }
    }
    
    fileprivate var showLabels : Bool {
        get {
            return (self.labels?.count ?? 0) > 0 ? true : false
        }
    }
    
    required init() {
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor(RRGGBB: UInt(0xDADEE8))
        
        // init data
        self.title = ""
        self.date = Date()
        self.starred = false
        self.attachmentCount = 0
        
        self.addSubviews()
        
        self.layoutIfNeeded()
        
        
        self.visible = true
    }
    
    deinit {
        self.visible = false
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateExpirationDate ( _ expiration : Date? ) {
        if let expirTime = expiration {
            let offset : Int = Int(expirTime.timeIntervalSince(Date()))
            hasExpiration = true
            expirationView.setExpirationTime(offset)
        } else {
            hasExpiration = false
        }
    }
    
    func using12hClockFormat() -> Bool {
        
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        let dateString = formatter.string(from: Date())
        let amRange = dateString.range(of: formatter.amSymbol)
        let pmRange = dateString.range(of: formatter.pmSymbol)
        
        return !(pmRange == nil && amRange == nil)
    }
    
    // MARK : Private functions
    func updateHeaderData (_ title : String,
                           sender : ContactVO, to : [ContactVO]?, cc : [ContactVO]?, bcc : [ContactVO]?,
                           isStarred : Bool, time : Date?, encType : EncryptTypes, labels : [Label]?,
                           showShowImages: Bool, expiration : Date?,
                           score: MessageSpamScore, isSent: Bool) {
        self.isSentFolder = isSent
        self.title = title
        self.sender = sender
        self.toList = to
        self.ccList = cc
        self.bccList = bcc
        if time != nil {
            self.date = time
        } else {
            self.date = Date()
        }
        
        self.starred = isStarred
        
        self.emailTitle.text = title
        
        self.emailFrom.attributedText = fromSinglelineAttr
        
        self.emailFromTable.contacts = [sender]
        self.emailToTable.contacts = toList
        self.emailToTable.showLock(isShow: self.isSentFolder)
        self.emailCcTable.contacts = ccList
        self.emailCcTable.showLock(isShow: self.isSentFolder)
        
        self.emailTo.attributedText = toSinglelineAttr
        self.emailCc.attributedText = ccShortAttr
        
        self.emailFavoriteButton.isSelected = self.starred;
        
        let timeformat = using12hClockFormat() ? k12HourMinuteFormat : k24HourMinuteFormat
        let at = LocalString._general_at_label
        self.emailShortTime.text = "\(at) \(self.date.string(format:timeformat))".lowercased()
        let tm = self.date.formattedWith("'On' EE, MMM d, yyyy 'at' \(timeformat)") ;
        self.emailDetailDateLabel.text = String(format: LocalString._date, "\(tm)")

//        let lockType : LockTypes = encType.lockType
//        switch (lockType) {
//        case .plainTextLock:
//            self.emailIsEncryptedImageView.image = UIImage(named: "mail_lock");
//            self.emailIsEncryptedImageView.isHighlighted = true;
//            break
//        case .encryptLock:
//            self.emailIsEncryptedImageView.image = UIImage(named: "mail_lock");
//            self.emailIsEncryptedImageView.isHighlighted = false;
//            break
//        case .pgpLock:
//            self.emailIsEncryptedImageView.image = UIImage(named: "mail_lock-pgpmime");
//            self.emailIsEncryptedImageView.isHighlighted = false;
//            break;
//        }
        
        var tmplabels : [Label] = []
        if let alllabels = labels {
            for l in alllabels {
                if l.exclusive == false {
                    tmplabels.append(l)
                }
            }
        }
        self.labels = tmplabels;
        if let labels = self.labels {
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
        self.updateExpirationDate(expiration)
        hasShowImageCheck = showShowImages
        
        //update score information
        self.spamScore = score
        self.spamScoreView.setMessage(msg: self.spamScore.description)
        
        self.layoutIfNeeded()
    }
    
    fileprivate func updateLablesDetails (_ labelView : UILabel, label:Label?) {
        if let label = label {
            if label.name.isEmpty || label.color.isEmpty {
                labelView.text = ""
            } else {
                labelView.text = "  \(label.name)  "
                labelView.textColor = UIColor(hexString: label.color, alpha: 1.0)
                labelView.layer.borderColor = UIColor(hexString: label.color, alpha: 1.0).cgColor
            }
        } else {
            labelView.text = ""
        }
    }
    
    
    func updateAttachmentData (_ atts : [Attachment]?) {
        self.attachmentCount = atts?.count ?? 0
        self.attachments = atts ?? []
        if (self.attachmentCount > 0) {
            self.emailAttachmentsAmount.text = "\(self.attachmentCount)"
            self.emailAttachmentsAmount.isHidden = false
            self.emailHasAttachmentsImageView.isHidden = false
        } else {
            self.emailAttachmentsAmount.isHidden = true
            self.emailHasAttachmentsImageView.isHidden = true
        }
    }
    
    func updateHeaderLayout () {
        self.updateDetailsView(self.isShowingDetail)
    }
    
    func attachmentForIndexPath(_ indexPath: IndexPath) -> Attachment {
        return self.attachments[indexPath.row]
    }
    
    
    // MARK: - Subviews
    func addSubviews() {
        self.createHeaderView()
        self.createExpirationView()
        self.createAttachmentView()
        self.createShowImageView()
        self.createSpamScoreView()
        self.createSeparator()
    }
    
    fileprivate func createAttachmentView() {
        self.attachmentView = UITableView()
        self.attachmentView!.alwaysBounceVertical = false
        self.attachmentView!.dataSource = self
        self.attachmentView!.delegate = self
        self.attachmentView!.register(UINib(nibName: "AttachmentTableViewCell", bundle: nil), forCellReuseIdentifier: AttachmentTableViewCell.Constant.identifier)
        self.attachmentView!.separatorStyle = .none
        self.addSubview(attachmentView!)
    }
    
    fileprivate func createExpirationView() {
        self.expirationView = ExpirationView()
        self.addSubview(expirationView!)
    }
    
    fileprivate func createShowImageView() {
        self.showImageView = ShowImageView()
        self.addSubview(showImageView!)
    }
    
    fileprivate func createSpamScoreView() {
        self.spamScoreView = SpamScoreWarningView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 0))
        self.spamScoreView.alpha = 0.0
        self.addSubview(spamScoreView!)
    }
    
    fileprivate func createSeparator() {
        self.separatorHeader = UIView()
        self.separatorHeader.backgroundColor = UIColor.ProtonMail.Gray_C9CED4
        self.addSubview(separatorHeader)
        self.separatorExpiration = UIView()
        self.separatorExpiration.backgroundColor = UIColor.ProtonMail.Gray_C9CED4
        self.addSubview(separatorExpiration)
        self.separatorAttachment = UIView()
        self.separatorAttachment.backgroundColor = UIColor.ProtonMail.Gray_C9CED4
        self.addSubview(separatorAttachment)
        self.separatorShowImage = UIView()
        self.separatorShowImage.backgroundColor = UIColor.ProtonMail.Gray_C9CED4
        self.addSubview(separatorShowImage)
    }
    
    fileprivate func createHeaderView() {
        
        // create header container
        self.emailHeaderView = UIView()
        self.addSubview(emailHeaderView)
        
        // create title
        self.emailTitle = UILabel()
        self.emailTitle.font = Fonts.h4.medium
        self.emailTitle.numberOfLines = 0
        self.emailTitle.lineBreakMode = .byWordWrapping
        self.emailTitle.text = self.title
        self.emailTitle.textColor = UIColor(RRGGBB: UInt(0x505061))
        self.emailTitle.sizeToFit()
        self.emailHeaderView.addSubview(emailTitle)
        
        // favorite button
        self.emailFavoriteButton = UIButton()
        self.emailFavoriteButton.addTarget(self, action: #selector(EmailHeaderView.emailFavoriteButtonTapped), for: .touchUpInside)
        self.emailFavoriteButton.setImage(UIImage(named: "mail_starred")!, for: UIControlState())
        self.emailFavoriteButton.setImage(UIImage(named: "mail_starred-active")!, for: .selected)
        self.emailFavoriteButton.isSelected = self.starred
        self.emailFavoriteButton.contentVerticalAlignment = UIControlContentVerticalAlignment.center
        self.emailFavoriteButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.center
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
        self.emailShortTime.font = Fonts.h6.medium
        self.emailShortTime.numberOfLines = 1
        self.emailShortTime.text = "at \(self.date.string(format: self.k12HourMinuteFormat))".lowercased()
        self.emailShortTime.textColor = UIColor(RRGGBB: UInt(0x838897))
        self.emailShortTime.sizeToFit()
        self.emailHeaderView.addSubview(emailShortTime)
        
        self.emailDetailButton = UIButton()
        self.emailDetailButton.addTarget(self, action: #selector(EmailHeaderView.detailsButtonTapped), for: UIControlEvents.touchUpInside)
        self.emailDetailButton.contentEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
        self.emailDetailButton.titleLabel?.font = Fonts.h6.medium
        self.emailDetailButton.setTitle(LocalString._details, for: UIControlState())
        self.emailDetailButton.setTitleColor(UIColor(RRGGBB: UInt(0x9397CD)), for: UIControlState())
        self.emailDetailButton.sizeToFit()
        self.emailHeaderView.addSubview(emailDetailButton)
        
        self.configureEmailDetailDateLabel()
        
//        self.emailIsEncryptedImageView = UIImageView(image: UIImage(named: "mail_lock"))
//        self.emailIsEncryptedImageView.highlightedImage = UIImage(named: "mail_lock-outside")
//        self.emailIsEncryptedImageView.contentMode = UIViewContentMode.center
//        self.emailIsEncryptedImageView.sizeToFit()
//        self.emailHeaderView.addSubview(emailIsEncryptedImageView)
        
        self.emailHasAttachmentsImageView = UIImageView(image: UIImage(named: "mail_attachment"))
        self.emailHasAttachmentsImageView.contentMode = UIViewContentMode.center
        self.emailHasAttachmentsImageView.sizeToFit()
        self.emailHeaderView.addSubview(emailHasAttachmentsImageView)
        
        self.emailAttachmentsAmount = UILabel()
        self.emailAttachmentsAmount.font = Fonts.h4.regular
        self.emailAttachmentsAmount.numberOfLines = 1
        self.emailAttachmentsAmount.text = "\(self.attachmentCount)"
        self.emailAttachmentsAmount.textColor = UIColor.ProtonMail.Gray_999DA1
        self.emailAttachmentsAmount.sizeToFit()
        self.emailHeaderView.addSubview(emailAttachmentsAmount)
        
        if (self.attachmentCount > 0) {
            self.emailAttachmentsAmount.isHidden = false
            self.emailHasAttachmentsImageView.isHidden = false
        } else {
            self.emailAttachmentsAmount.isHidden = true
            self.emailHasAttachmentsImageView.isHidden = true
        }
    }
    
    // MARK: - Subview constraints
    
    func makeConstraints() {
        self.makeHeaderConstraints()
        self.updateExpirationConstraints()
        self.updateShowImageConstraints()
        self.updateSpamScoreConstraints()
        self.updateAttConstraints(false)
    }
    
    func updateExpirationConstraints() {
        separatorHeader.mas_updateConstraints { (make) -> Void in
            make?.removeExisting = true
            let _ = make?.left.equalTo()(self)
            let _ = make?.right.equalTo()(self)
            let _ = make?.top.equalTo()(self.LabelOne.mas_bottom)?.with().offset()(self.kSeparatorBetweenHeaderAndBodyMarginTop)
            let _ = make?.height.equalTo()(1)
        }
        
        let viewHeight = self.hasExpiration ? 26 : 0
        self.expirationView.mas_updateConstraints({ (make) -> Void in
            make?.removeExisting = true
            let _ = make?.left.equalTo()(self)
            let _ = make?.right.equalTo()(self)
            let _ = make?.top.equalTo()(self.separatorHeader.mas_bottom)
            let _ = make?.height.equalTo()(viewHeight)
        })
        
        let separatorHeight = self.hasExpiration ? 1 : 0
        separatorExpiration.mas_updateConstraints { (make) -> Void in
            make?.removeExisting = true
            let _ = make?.left.equalTo()(self)
            let _ = make?.right.equalTo()(self)
            let _ = make?.top.equalTo()(self.expirationView.mas_bottom)?.with()
            let _ = make?.height.equalTo()(separatorHeight)
        }
    }
    
    func updateSpamScoreConstraints() {
        let size = self.spamScore == .others ? 0.0 : self.spamScoreView.fitHeight()
        self.spamScoreView.alpha = self.spamScore == .others ? 0.0 : 1.0
        self.spamScoreView.mas_updateConstraints({ (make) -> Void in
            make?.removeExisting = true
            let _ = make?.left.equalTo()(self)
            let _ = make?.right.equalTo()(self)
            let _ = make?.top.equalTo()(self.separatorAttachment.mas_bottom)
            let _ = make?.height.equalTo()(size)
        })
    }
    
    func updateShowImageConstraints() {
        let viewHeight = self.hasShowImageCheck ? 36 : 0
        self.showImageView.mas_updateConstraints({ (make) -> Void in
            make?.removeExisting = true
            let _ = make?.left.equalTo()(self)
            let _ = make?.right.equalTo()(self)
            let _ = make?.top.equalTo()(self.spamScoreView.mas_bottom)
            let _ = make?.height.equalTo()(viewHeight)
        })
        
        self.separatorShowImage.mas_updateConstraints({ (make) -> Void in
            make?.removeExisting = true
            let _ = make?.left.equalTo()(self)
            let _ = make?.right.equalTo()(self)
            let _ = make?.top.equalTo()(self.showImageView!.mas_bottom)
            let _ = make?.height.equalTo()(0)
        })
    }
    
    func updateAttConstraints (_ animition : Bool) {
        guard self.visible == true else {
            return
        }
        attachmentView!.reloadData()
        attachmentView!.layoutIfNeeded();
        
        let viewHeight = self.attachmentCount > 0 ? attachmentView!.contentSize.height : 0
        self.attachmentView!.mas_updateConstraints { (make) -> Void in
            make?.removeExisting = true
            let _ = make?.left.equalTo()(self)
            let _ = make?.right.equalTo()(self)
            let _ = make?.top.equalTo()(self.separatorExpiration.mas_bottom)
            let _ = make?.height.equalTo()(viewHeight)
        }
        
        let separatorHeight = self.attachmentCount == 0 ? 0 : 1
        separatorAttachment.mas_updateConstraints { (make) -> Void in
            make?.removeExisting = true
            let _ = make?.left.equalTo()(self)
            let _ = make?.right.equalTo()(self)
            let _ = make?.top.equalTo()(self.attachmentView!.mas_bottom)
            let _ = make?.height.equalTo()(separatorHeight)
        }
        
//        emailIsEncryptedImageView.mas_updateConstraints { (make) -> Void in
//            make?.removeExisting = true
//            if (self.attachmentCount > 0) {
//                let _ = make?.right.equalTo()(self.emailHasAttachmentsImageView.mas_left)?.with().offset()(self.kEmailIsEncryptedImageViewMarginRight)
//            } else {
//                let _ = make?.right.equalTo()(self.emailHeaderView)?.offset()(-16)
//            }
//            let _ = make?.bottom.equalTo()(self.emailAttachmentsAmount)
//            let _ = make?.height.equalTo()(self.emailIsEncryptedImageView.frame.height)
//            let _ = make?.width.equalTo()(self.emailIsEncryptedImageView.frame.width)
//        }
        
        self.updateExpirationConstraints()
        self.updateShowImageConstraints()
        self.updateSpamScoreConstraints()
        
        self.updateSelf(animition)
    }
    
    fileprivate func configureEmailDetailDateLabel() {
        self.emailDetailDateLabel = UILabel()
        self.emailDetailDateLabel.font = Fonts.h6.medium
        self.emailDetailDateLabel.numberOfLines = 1
        if let messageTime = self.date {
            let timeformat = using12hClockFormat() ? k12HourMinuteFormat : k24HourMinuteFormat
            let tm = messageTime.formattedWith("'On' EE, MMM d, yyyy 'at' \(timeformat)");
            self.emailDetailDateLabel.text = String(format: LocalString._date, "\(tm)")
        } else {
            self.emailDetailDateLabel.text = String(format: LocalString._date, "")
        }
        self.emailDetailDateLabel.textColor = UIColor(RRGGBB: UInt(0x838897)) //UIColor.ProtonMail.Gray_999DA1
        self.emailDetailDateLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailDateLabel)
        
        self.LabelOne = UILabel()
        self.LabelOne.sizeToFit()
        self.LabelOne.clipsToBounds = true
        self.LabelOne.layer.borderWidth = 1
        self.LabelOne.layer.cornerRadius = 2
        self.LabelOne.font = Fonts.h7.light
        self.addSubview(LabelOne)
        
        self.LabelTwo = UILabel()
        self.LabelTwo.sizeToFit()
        self.LabelTwo.clipsToBounds = true
        self.LabelTwo.layer.borderWidth = 1
        self.LabelTwo.layer.cornerRadius = 2
        self.LabelTwo.font = Fonts.h7.light
        self.addSubview(LabelTwo)
        
        self.LabelThree = UILabel()
        self.LabelThree.sizeToFit()
        self.LabelThree.clipsToBounds = true
        self.LabelThree.layer.borderWidth = 1
        self.LabelThree.layer.cornerRadius = 2
        self.LabelThree.font = Fonts.h7.light
        self.addSubview(LabelThree)
        
        self.LabelFour = UILabel()
        self.LabelFour.sizeToFit()
        self.LabelFour.clipsToBounds = true
        self.LabelFour.layer.borderWidth = 1
        self.LabelFour.layer.cornerRadius = 2
        self.LabelFour.font = Fonts.h7.light
        self.addSubview(LabelFour)
        
        self.LabelFive = UILabel()
        self.LabelFive.sizeToFit()
        self.LabelFive.clipsToBounds = true
        self.LabelFive.layer.borderWidth = 1
        self.LabelFive.layer.cornerRadius = 2
        self.LabelFive.font = Fonts.h7.light
        self.addSubview(LabelFive)
        
    }
    
    fileprivate func makeHeaderConstraints() {
        emailHeaderView.mas_updateConstraints { (make) -> Void in
            make?.removeExisting = true
            let _ = make?.top.equalTo()(self)?.with().offset()(0)
            let _ = make?.left.equalTo()(self)?.with().offset()(self.kEmailHeaderViewMarginLeft)
            let _ = make?.right.equalTo()(self)?.with().offset()(0)
            let _ = make?.bottom.equalTo()(self.emailDetailView)
        }
        emailFavoriteButton.mas_updateConstraints { (make) -> Void in
            make?.removeExisting = true
            let _ = make?.top.equalTo()(self.emailHeaderView)
            let _ = make?.right.equalTo()(self.emailHeaderView)
            let _ = make?.height.equalTo()(self.kEmailFavoriteButtonHeight)
            let _ = make?.width.equalTo()(self.kEmailFavoriteButtonWidth)
        }
        
        emailTitle.mas_updateConstraints { (make) -> Void in
            make?.removeExisting = true
            let _ = make?.left.equalTo()(self.emailHeaderView)
            let _ = make?.top.equalTo()(self.emailHeaderView)?.offset()(self.kEmailHeaderViewMarginTop)
            let _ = make?.right.equalTo()(self.emailFavoriteButton.mas_left)?.with().offset()(self.kEmailTitleViewMarginRight)
        }
        
        emailDetailView.mas_makeConstraints { (make) -> Void in
            let _ = make?.left.equalTo()(self.emailTitle)
            let _ = make?.right.equalTo()(self.emailHeaderView)
            let _ = make?.top.equalTo()(self.emailDetailButton.mas_bottom)
            let _ = make?.height.equalTo()(0)
        }
        
        emailFrom.mas_makeConstraints { (make) -> Void in
            let _ = make?.left.equalTo()(self.emailHeaderView)
            let _ = make?.right.equalTo()(self.emailTitle)
            let _ = make?.top.equalTo()(self.emailTitle.mas_bottom)?.with().offset()(self.kEmailRecipientsViewMarginTop)
        }
        
        emailFromTable.mas_makeConstraints { (make) -> Void in
            let _ = make?.left.equalTo()(36)
            let _ = make?.right.equalTo()(self.emailHeaderView)
            let _ = make?.top.equalTo()(self.emailTitle.mas_bottom)?.with().offset()(self.kEmailRecipientsViewMarginTop)
            let _ = make?.height.equalTo()(self.emailFrom)
        }
        
        let toOffset = self.showTo ? kEmailRecipientsViewMarginTop : 0
        let toHeight = self.showTo ? 16 : 0
        emailTo.mas_makeConstraints { (make) -> Void in
            let _ = make?.left.equalTo()(self.emailHeaderView)
            let _ = make?.right.equalTo()(self.emailTitle)
            let _ = make?.top.equalTo()(self.emailFrom.mas_bottom)?.with().offset()(toOffset)
            let _ = make?.height.equalTo()(toHeight)
        }
        emailToTable.mas_makeConstraints { (make) -> Void in
            let _ = make?.left.equalTo()(36)
            let _ = make?.right.equalTo()(self.emailHeaderView)
            let _ = make?.top.equalTo()(self.emailFrom.mas_bottom)?.with().offset()(toOffset)
            let _ = make?.height.equalTo()(self.emailTo)
        }
        
        let ccOffset = self.showCc ? kEmailRecipientsViewMarginTop : 0
        emailCc.mas_makeConstraints { (make) -> Void in
            let _ = make?.left.equalTo()(self.emailHeaderView)
            let _ = make?.right.equalTo()(self.emailTitle)
            let _ = make?.top.equalTo()(self.emailTo.mas_bottom)?.with().offset()(ccOffset)
        }
        emailCcTable.mas_makeConstraints { (make) -> Void in
            let _ = make?.left.equalTo()(36)
            let _ = make?.right.equalTo()(self.emailHeaderView)
            let _ = make?.top.equalTo()(self.emailTo.mas_bottom)?.with().offset()(ccOffset)
            let _ = make?.height.equalTo()(self.emailCc)
        }
        
        emailShortTime.sizeToFit()
        emailShortTime.mas_makeConstraints { (make) -> Void in
            let _ = make?.left.equalTo()(self.emailHeaderView)
            let _ = make?.width.equalTo()(self.emailShortTime.frame.size.width)
            let _ = make?.height.equalTo()(self.emailShortTime.frame.size.height)
            let _ = make?.top.equalTo()(self.emailTo.mas_bottom)?.with().offset()(self.kEmailTimeViewMarginTop)
        }
        
        emailDetailButton.mas_makeConstraints { (make) -> Void in
            let _ = make?.left.equalTo()(self.emailShortTime.mas_right)?.with().offset()(self.kEmailDetailButtonMarginLeft)
            let _ = make?.bottom.equalTo()(self.emailShortTime)
            let _ = make?.top.equalTo()(self.emailShortTime)
            let _ = make?.width.equalTo()(self.emailDetailButton)
        }
        
        emailDetailView.mas_makeConstraints { (make) -> Void in
            let _ = make?.left.equalTo()(self.emailTitle)
            let _ = make?.right.equalTo()(self.emailHeaderView)
            let _ = make?.top.equalTo()(self.emailDetailButton.mas_bottom)
            let _ = make?.height.equalTo()(0)
        }
        
        emailDetailDateLabel.sizeToFit()
        emailDetailDateLabel.mas_makeConstraints { (make) -> Void in
            let _ = make?.left.equalTo()(self.emailDetailView)
            let _ = make?.top.equalTo()(self.emailDetailView)
            let _ = make?.width.equalTo()(self.emailDetailDateLabel.frame.size.width)
            let _ = make?.height.equalTo()(self.emailDetailDateLabel.frame.size.height)
        }
        
        LabelOne.sizeToFit()
        let lbOffset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
        let lbHeight = self.showLabels ? self.LabelOne.frame.size.height : 0
        LabelOne.mas_makeConstraints { (make) -> Void in
            let _ = make?.left.equalTo()(self.emailHeaderView)
            let _ = make?.top.equalTo()(self.emailDetailView.mas_bottom)?.with().offset()(lbOffset)
            let _ = make?.width.equalTo()(self.LabelOne.frame.size.width)
            let _ = make?.height.equalTo()(lbHeight)
        }
        
        LabelTwo.sizeToFit()
        let lb2Offset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
        let lb2Height = self.showLabels ? self.LabelTwo.frame.size.height : 0
        LabelTwo.mas_makeConstraints { (make) -> Void in
            let _ = make?.left.equalTo()(self.LabelOne.mas_right)?.with().offset()(2)
            let _ = make?.top.equalTo()(self.emailDetailView.mas_bottom)?.with().offset()(lb2Offset)
            let _ = make?.width.equalTo()(self.LabelTwo.frame.size.width)
            let _ = make?.height.equalTo()(lb2Height)
        }
        
        LabelThree.sizeToFit()
        let lb3Offset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
        let lb3Height = self.showLabels ? self.LabelThree.frame.size.height : 0
        LabelThree.mas_makeConstraints { (make) -> Void in
            let _ = make?.left.equalTo()(self.LabelTwo.mas_right)?.with().offset()(2)
            let _ = make?.top.equalTo()(self.emailDetailView.mas_bottom)?.with().offset()(lb3Offset)
            let _ = make?.width.equalTo()(self.LabelThree.frame.size.width)
            let _ = make?.height.equalTo()(lb3Height)
        }
        
        LabelFour.sizeToFit()
        let lb4Offset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
        let lb4Height = self.showLabels ? self.LabelFour.frame.size.height : 0
        LabelFour.mas_makeConstraints { (make) -> Void in
            let _ = make?.left.equalTo()(self.LabelThree.mas_right)?.with().offset()(2)
            let _ = make?.top.equalTo()(self.emailDetailView.mas_bottom)?.with().offset()(lb4Offset)
            let _ = make?.width.equalTo()(self.LabelFour.frame.size.width)
            let _ = make?.height.equalTo()(lb4Height)
        }
        
        LabelFive.sizeToFit()
        let lb5Offset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
        let lb5Height = self.showLabels ? self.LabelFive.frame.size.height : 0
        LabelFive.mas_makeConstraints { (make) -> Void in
            let _ = make?.left.equalTo()(self.LabelFour.mas_right)?.with().offset()(2)
            let _ = make?.top.equalTo()(self.emailDetailView.mas_bottom)?.with().offset()(lb5Offset)
            let _ = make?.width.equalTo()(self.LabelFive.frame.size.width)
            let _ = make?.height.equalTo()(lb5Height)
        }
        
        emailAttachmentsAmount.mas_makeConstraints { (make) -> Void in
            let _ = make?.right.equalTo()(self.emailHeaderView)?.offset()(-16)
            let _ = make?.bottom.equalTo()(self.emailDetailButton)
            let _ = make?.height.equalTo()(self.emailAttachmentsAmount.frame.height)
            let _ = make?.width.equalTo()(self.emailAttachmentsAmount.frame.width)
        }
        
        emailHasAttachmentsImageView.mas_makeConstraints { (make) -> Void in
            let _ = make?.right.equalTo()(self.emailAttachmentsAmount.mas_left)?.with().offset()(self.kEmailHasAttachmentsImageViewMarginRight)
            let _ = make?.bottom.equalTo()(self.emailAttachmentsAmount)
            let _ = make?.height.equalTo()(self.emailHasAttachmentsImageView.frame.height)
            let _ = make?.width.equalTo()(self.emailHasAttachmentsImageView.frame.width)
        }
        
//        emailIsEncryptedImageView.mas_makeConstraints { (make) -> Void in
//            if (self.attachmentCount > 0) {
//                let _ = make?.right.equalTo()(self.emailHasAttachmentsImageView.mas_left)?.with().offset()(self.kEmailIsEncryptedImageViewMarginRight)
//            } else {
//                let _ = make?.right.equalTo()(self.emailHeaderView)
//            }
//
//            let _ = make?.bottom.equalTo()(self.emailAttachmentsAmount)
//            let _ = make?.height.equalTo()(self.emailIsEncryptedImageView.frame.height)
//            let _ = make?.width.equalTo()(self.emailIsEncryptedImageView.frame.width)
//        }
    }
    
    @objc internal func detailsButtonTapped() {
        self.isShowingDetail = !self.isShowingDetail
        self.updateDetailsView(self.isShowingDetail)
    }
    
    @objc internal func emailFavoriteButtonTapped() {
        self.starred = !self.starred
        self.delegate?.star(changed: self.starred)
        self.emailFavoriteButton.isSelected = self.starred
    }
    
    fileprivate func updateSelf(_ anim : Bool) {
        guard self.visible == true else {
            return
        }
        DispatchQueue.main.async {
            UIView.animate(withDuration: anim == true ? 0.3 : 0.0, animations: { () -> Void in
                self.layoutIfNeeded()
                var f = self.frame;
                f.size.height = self.getHeight();
                self.frame = f;
                self.viewDelegate?.updateSize()
            })
        }
    }
    
    fileprivate let kAnimationOption: UIViewAnimationOptions = .transitionCrossDissolve
    fileprivate func updateDetailsView(_ needsShow : Bool) {
        guard self.visible == true else {
            return
        }
        if (needsShow) {
            // update views value
            UIView.transition(with: self.emailFrom, duration: 0.3, options: kAnimationOption, animations: { () -> Void in
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
                make?.removeExisting = true
                let _ = make?.left.equalTo()(36)
                let _ = make?.right.equalTo()(self.emailHeaderView)
                let _ = make?.top.equalTo()(self.emailTitle.mas_bottom)?.with().offset()(self.kEmailRecipientsViewMarginTop)
                let _ = make?.height.equalTo()(efh)
            }
            
            let toOffset = self.showTo ? kEmailRecipientsViewMarginTop : 0
            let toHeight = self.showTo ? 16 : 0
            emailTo.mas_updateConstraints { (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(self.emailHeaderView)
                let _ = make?.right.equalTo()(self.emailTitle)
                let _ = make?.top.equalTo()(self.emailFromTable.mas_bottom)?.with().offset()(toOffset)
                let _ = make?.height.equalTo()(toHeight)
            }
            
            let eth = emailToTable.getContentSize().height;
            emailToTable.mas_makeConstraints { (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(36)
                let _ = make?.right.equalTo()(self.emailHeaderView)
                let _ = make?.top.equalTo()(self.emailFromTable.mas_bottom)?.with().offset()(toOffset)
                let _ = make?.height.equalTo()(eth)
            }
            
            let ccOffset = self.showCc ? kEmailRecipientsViewMarginTop : 0
            let ccHeight = self.showCc ? 16 : 0
            emailCc.mas_updateConstraints { (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(self.emailHeaderView)
                let _ = make?.right.equalTo()(self.emailTitle)
                let _ = make?.top.equalTo()(self.emailToTable.mas_bottom)?.with().offset()(ccOffset)
                let _ = make?.height.equalTo()(ccHeight)
            }
            let ecch = emailCcTable.getContentSize().height;
            emailCcTable.mas_makeConstraints { (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(36)
                let _ = make?.right.equalTo()(self.emailHeaderView)
                let _ = make?.top.equalTo()(self.emailToTable.mas_bottom)?.with().offset()(ccOffset)
                let _ = make?.height.equalTo()(ecch)
            }
            
            self.emailShortTime.mas_updateConstraints({ (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(self.emailHeaderView)
                let _ = make?.width.equalTo()(0)
                let _ = make?.height.equalTo()(self.emailShortTime.frame.size.height)
                let _ = make?.top.equalTo()(self.emailCcTable.mas_bottom)?.with().offset()(self.kEmailTimeViewMarginTop)
            })
            
            self.emailDetailButton.setTitle(LocalString._hide_details, for: UIControlState())
            self.emailDetailButton.mas_updateConstraints({ (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(self.emailShortTime)
                let _ = make?.bottom.equalTo()(self.emailShortTime)
                let _ = make?.top.equalTo()(self.emailShortTime)
                let _ = make?.width.equalTo()(self.emailDetailButton)
            })
            
            emailDetailDateLabel.sizeToFit()
            emailDetailDateLabel.mas_updateConstraints { (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(self.emailDetailView)
                let _ = make?.top.equalTo()(self.emailDetailView)
                let _ = make?.width.equalTo()(self.emailDetailDateLabel.frame.size.width)
                let _ = make?.height.equalTo()(self.emailDetailDateLabel.frame.size.height)
            }
            
            LabelOne.sizeToFit()
            let lbOffset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
            let lbHeight = self.showLabels ? self.LabelOne.frame.size.height : 0
            LabelOne.mas_updateConstraints { (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(self.emailDetailView)
                let _ = make?.top.equalTo()(self.emailDetailView.mas_bottom)?.with().offset()(lbOffset)
                let _ = make?.width.equalTo()(self.LabelOne.frame.size.width)
                let _ = make?.height.equalTo()(lbHeight)
            }
            
            LabelTwo.sizeToFit()
            let lb2Offset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
            let lb2Height = self.showLabels ? self.LabelTwo.frame.size.height : 0
            LabelTwo.mas_updateConstraints { (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(self.LabelOne.mas_right)?.with().offset()(2)
                let _ = make?.top.equalTo()(self.emailDetailView.mas_bottom)?.with().offset()(lb2Offset)
                let _ = make?.width.equalTo()(self.LabelTwo.frame.size.width)
                let _ = make?.height.equalTo()(lb2Height)
            }
            
            LabelThree.sizeToFit()
            let lb3Offset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
            let lb3Height = self.showLabels ? self.LabelThree.frame.size.height : 0
            LabelThree.mas_updateConstraints { (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(self.LabelTwo.mas_right)?.with().offset()(2)
                let _ = make?.top.equalTo()(self.emailDetailView.mas_bottom)?.with().offset()(lb3Offset)
                let _ = make?.width.equalTo()(self.LabelThree.frame.size.width)
                let _ = make?.height.equalTo()(lb3Height)
            }
            
            LabelFour.sizeToFit()
            let lb4Offset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
            let lb4Height = self.showLabels ? self.LabelFour.frame.size.height : 0
            LabelFour.mas_updateConstraints { (make) -> Void in
                let _ = make?.left.equalTo()(self.LabelThree.mas_right)?.with().offset()(2)
                let _ = make?.top.equalTo()(self.emailDetailView.mas_bottom)?.with().offset()(lb4Offset)
                let _ = make?.width.equalTo()(self.LabelFour.frame.size.width)
                let _ = make?.height.equalTo()(lb4Height)
            }
            
            LabelFive.sizeToFit()
            let lb5Offset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
            let lb5Height = self.showLabels ? self.LabelFive.frame.size.height : 0
            LabelFive.mas_updateConstraints { (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(self.LabelFour.mas_right)?.with().offset()(2)
                let _ = make?.top.equalTo()(self.emailDetailView.mas_bottom)?.with().offset()(lb5Offset)
                let _ = make?.width.equalTo()(self.LabelFive.frame.size.width)
                let _ = make?.height.equalTo()(lb5Height)
            }
            
            self.emailDetailView.mas_updateConstraints({ (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(self.emailTitle)
                let _ = make?.right.equalTo()(self.emailHeaderView)
                let _ = make?.top.equalTo()(self.emailDetailButton.mas_bottom)?.with().offset()(10)
                let _ = make?.bottom.equalTo()(self.emailDetailDateLabel)
            })
        } else {
            
            UIView.transition(with: self.emailFrom, duration: 0.3, options: kAnimationOption, animations: { () -> Void in
                self.emailFrom.attributedText = self.fromShortAttr //self.fromSinglelineAttr
                self.emailTo.attributedText = self.toSinglelineAttr
                self.emailFromTable.alpha = 1.0
                self.emailTo.alpha = self.showTo ? 1.0 : 0.0
                self.emailToTable.alpha = 0.0;
                self.emailCc.alpha = 0.0;
                self.emailCcTable.alpha = 0.0
                }, completion: nil)
            
            let efh = emailFromTable.getContentSize().height;
            emailFromTable.mas_updateConstraints { (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(36)
                let _ = make?.right.equalTo()(self.emailHeaderView)
                let _ = make?.top.equalTo()(self.emailTitle.mas_bottom)?.with().offset()(self.kEmailRecipientsViewMarginTop)
                let _ = make?.height.equalTo()(efh)
            }
            //
            
            let toOffset = self.showTo ? kEmailRecipientsViewMarginTop : 0
            let toHeight = self.showTo ? 16 : 0
            emailTo.mas_updateConstraints { (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(self.emailHeaderView)
                let _ = make?.right.equalTo()(self.emailTitle)
                let _ = make?.top.equalTo()(self.emailFrom.mas_bottom)?.with().offset()(toOffset)
                let _ = make?.height.equalTo()(toHeight)
            }
            
            emailToTable.mas_updateConstraints { (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(36)
                let _ = make?.right.equalTo()(self.emailHeaderView)
                let _ = make?.top.equalTo()(self.emailTo)
                let _ = make?.height.equalTo()(toHeight)
            }
            
            emailCc.mas_updateConstraints { (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(self.emailHeaderView)
                let _ = make?.right.equalTo()(self.emailTitle)
                let _ = make?.top.equalTo()(self.emailToTable.mas_bottom)?.with().offset()(0)
                let _ = make?.height.equalTo()(0)
            }
            emailCcTable.mas_makeConstraints { (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(36)
                let _ = make?.right.equalTo()(self.emailHeaderView)
                let _ = make?.top.equalTo()(self.emailCc)?.with().offset()(self.kEmailRecipientsViewMarginTop)
                let _ = make?.height.equalTo()(0)
            }
            
            self.emailDetailButton.setTitle(LocalString._details, for: UIControlState())
            self.emailDetailButton.mas_updateConstraints({ (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(self.emailShortTime.mas_right)?.with().offset()(self.kEmailDetailButtonMarginLeft)
                let _ = make?.bottom.equalTo()(self.emailShortTime)
                let _ = make?.top.equalTo()(self.emailShortTime)
                let _ = make?.width.equalTo()(self.emailDetailButton)
            })

//            self.emailFrom.sizeToFit();
//            emailFrom.mas_updateConstraints { (make) -> Void in
//                make?.removeExisting = true
//                let _ = make?.left.equalTo()(self.emailHeaderView)
//                let _ = make?.width.equalTo()(self.emailFrom.frame.size.width)
//                let _ = make?.height.equalTo()(self.emailFrom.frame.size.height)
//                let _ = make?.top.equalTo()(self.emailTitle.mas_bottom)?.with().offset()(self.kEmailRecipientsViewMarginTop)
//            }
            
            self.emailTo.sizeToFit();
            emailTo.mas_updateConstraints { (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(self.emailHeaderView)
                let _ = make?.width.equalTo()(self.emailTo.frame.size.width)
                let _ = make?.height.equalTo()(self.emailTo.frame.size.height)
                //let _ = make?.top.equalTo()(self.emailFrom.mas_bottom)?.with().offset()(toOffset)
                let _ = make?.top.equalTo()(self.emailFromTable.mas_bottom)?.with().offset()(toOffset)
            }
            
            self.emailShortTime.sizeToFit()
            self.emailShortTime.mas_updateConstraints { (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(self.emailHeaderView)
                let _ = make?.width.equalTo()(self.emailShortTime.frame.size.width)
                let _ = make?.height.equalTo()(self.emailShortTime.frame.size.height)
                let _ = make?.top.equalTo()(self.emailToTable.mas_bottom)?.with().offset()(self.kEmailTimeViewMarginTop)
            }
            
            self.emailDetailView.mas_updateConstraints({ (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(self.emailTitle)
                let _ = make?.right.equalTo()(self.emailHeaderView)
                let _ = make?.top.equalTo()(self.emailDetailButton.mas_bottom)
                let _ = make?.height.equalTo()(0)
            })
            
            LabelOne.sizeToFit()
            let lbOffset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
            let lbHeight = self.showLabels ? self.LabelOne.frame.size.height : 0
            LabelOne.mas_updateConstraints { (make) -> Void in
                let _ = make?.left.equalTo()(self.emailHeaderView)
                let _ = make?.top.equalTo()(self.emailDetailView.mas_bottom)?.with().offset()(lbOffset)
                let _ = make?.width.equalTo()(self.LabelOne.frame.size.width)
                let _ = make?.height.equalTo()(lbHeight)
            }
            
            LabelTwo.sizeToFit()
            let lb2Offset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
            let lb2Height = self.showLabels ? self.LabelTwo.frame.size.height : 0
            LabelTwo.mas_updateConstraints { (make) -> Void in
                let _ = make?.left.equalTo()(self.LabelOne.mas_right)?.with().offset()(2)
                let _ = make?.top.equalTo()(self.emailDetailView.mas_bottom)?.with().offset()(lb2Offset)
                let _ = make?.width.equalTo()(self.LabelTwo.frame.size.width)
                let _ = make?.height.equalTo()(lb2Height)
            }
            
            LabelThree.sizeToFit()
            let lb3Offset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
            let lb3Height = self.showLabels ? self.LabelThree.frame.size.height : 0
            LabelThree.mas_updateConstraints { (make) -> Void in
                let _ = make?.left.equalTo()(self.LabelTwo.mas_right)?.with().offset()(2)
                let _ = make?.top.equalTo()(self.emailDetailView.mas_bottom)?.with().offset()(lb3Offset)
                let _ = make?.width.equalTo()(self.LabelThree.frame.size.width)
                let _ = make?.height.equalTo()(lb3Height)
            }
            
            LabelFour.sizeToFit()
            let lb4Offset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
            let lb4Height = self.showLabels ? self.LabelFour.frame.size.height : 0
            LabelFour.mas_updateConstraints { (make) -> Void in
                let _ = make?.left.equalTo()(self.LabelThree.mas_right)?.with().offset()(2)
                let _ = make?.top.equalTo()(self.emailDetailView.mas_bottom)?.with().offset()(lb4Offset)
                let _ = make?.width.equalTo()(self.LabelFour.frame.size.width)
                let _ = make?.height.equalTo()(lb4Height)
            }
            
            LabelFive.sizeToFit()
            let lb5Offset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
            let lb5Height = self.showLabels ? self.LabelFive.frame.size.height : 0
            LabelFive.mas_updateConstraints { (make) -> Void in
                let _ = make?.left.equalTo()(self.LabelFour.mas_right)?.with().offset()(2)
                let _ = make?.top.equalTo()(self.emailDetailView.mas_bottom)?.with().offset()(lb5Offset)
                let _ = make?.width.equalTo()(self.LabelFive.frame.size.width)
                let _ = make?.height.equalTo()(lb5Height)
            }

        }
        
        self.updateSelf(true)
    }
}

extension EmailHeaderView: UITableViewDataSource {
    
    @objc func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let attachment = attachmentForIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: AttachmentTableViewCell.Constant.identifier, for: indexPath) as! AttachmentTableViewCell
        if attachment.managedObjectContext != nil {
            cell.setFilename(attachment.fileName, fileSize: attachment.fileSize.intValue)
            cell.configAttachmentIcon(attachment.mimeType)
        }
        return cell
    }
    
    @objc func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  attachments.count
    }
    
    @objc func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 34;
    }
}

extension EmailHeaderView: UITableViewDelegate {
    
    @objc func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if attachments.count > indexPath.row {
            let attachment = attachmentForIndexPath(indexPath)
            if !attachment.downloaded {
                downloadAttachment(attachment, forIndexPath: indexPath)
            } else if let localURL = attachment.localURL {
                if FileManager.default.fileExists(atPath: localURL.path, isDirectory: nil) {
                    if let cell = tableView.cellForRow(at: indexPath) {
                        if let key_packet = attachment.keyPacket {
                            if let data: Data = Data(base64Encoded:key_packet, options: NSData.Base64DecodingOptions(rawValue: 0)) {
                                openLocalURL(localURL, keyPackage: data, fileName: attachment.fileName, type: attachment.mimeType, forCell: cell)
                            }
                        }
                    }
                } else {
                    attachment.localURL = nil
                    if let context = attachment.managedObjectContext {
                        let error = context.saveUpstreamIfNeeded()
                        if error != nil  {
                            PMLog.D(" error: \(String(describing: error))")
                        }
                    }
                    downloadAttachment(attachment, forIndexPath: indexPath)
                }
            }
        }
    }
    
    // MARK: Private methods
    
    fileprivate func downloadAttachment(_ attachment: Attachment, forIndexPath indexPath: IndexPath) {
        sharedMessageDataService.fetchAttachmentForAttachment(attachment, downloadTask: { (taskOne : URLSessionDownloadTask) -> Void in
            if let cell = self.attachmentView!.cellForRow(at: indexPath) as? AttachmentTableViewCell {
                //task.set
                //let session = AFHTTPSessionManager.manager .manager;
                cell.progressView.alpha = 1.0
                cell.progressView.progress = 0.0
                //cell.progressView.setProgressWithDownloadProgressOfTask(task, animated: true)

                let totalValue = attachment.fileSize.floatValue;
                sharedAPIService.getSession().setDownloadTaskDidWriteDataBlock({ (session, taskTwo, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) -> Void in
                    if taskOne == taskTwo {
                        //PMLog.D("\(totalValue)")
                        //PMLog.D("%lld  - %lld - %lld", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
                        var progressPercentage =  ( Float(totalBytesWritten) / totalValue )
                        //PMLog.D("\(progressPercentage)")
                        if progressPercentage >= 1.000000000 {
                            progressPercentage = 1.0
                        }
                        DispatchQueue.main.async(execute: {
                            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                                cell.progressView.progress = progressPercentage
                            })
                        });
                    }
                })
            }
            }, completion: { (_, url, error) -> Void in
                if let e = error {
                    e.alertErrorToast()
                } else {
                    if let cell = self.attachmentView!.cellForRow(at: indexPath) as? AttachmentTableViewCell {
                        UIView.animate(withDuration: 0.25, animations: { () -> Void in
                            cell.progressView.isHidden = true
                            if let localURL = attachment.localURL {
                                if FileManager.default.fileExists(atPath: localURL.path, isDirectory: nil) {
                                    if let cell = self.attachmentView!.cellForRow(at: indexPath) {
                                        if let key_packet = attachment.keyPacket {
                                            if let data: Data = Data(base64Encoded:key_packet, options: NSData.Base64DecodingOptions(rawValue: 0)) {
                                                self.openLocalURL(localURL, keyPackage: data, fileName: attachment.fileName, type: attachment.mimeType, forCell: cell)
                                            }
                                        }
                                    }
                                }
                            }
                        })
                    }
                }
        })
    }
    
    
    fileprivate func openLocalURL(_ localURL: URL, keyPackage:Data, fileName:String, type: String, forCell cell: UITableViewCell) {
        self.delegate?.quickLook(attachment: localURL, keyPackage: keyPackage, fileName: fileName, type: type)
    }
}
