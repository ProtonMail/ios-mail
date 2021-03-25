//
//  EmailHeaderView.swift
//  ProtonMail - Created on 7/27/15.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import UIKit

protocol EmailHeaderViewProtocol: AnyObject {
    func updateSize()
}

protocol EmailHeaderActionsProtocol: RecipientViewDelegate, ShowImageViewDelegate {
    func quickLook(attachment tempfile : URL, keyPackage:Data, fileName:String, type: String)
    
    func quickLook(file : URL, fileName:String, type: String)
    
    func star(changed isStarred : Bool)
    
    func downloadFailed(error: NSError)
}

// for new MessageHeaderViewController
extension EmailHeaderView {
    func inject(recepientDelegate: RecipientViewDelegate) {
        self.emailFromTable.delegate = recepientDelegate
        self.emailToTable.delegate = recepientDelegate
        self.emailCcTable.delegate = recepientDelegate
        self.emailBccTable.delegate = recepientDelegate
    }
    
    func inject(delegate: EmailHeaderActionsProtocol) {
        self._delegate = delegate
    }
    
    override func prepareForInterfaceBuilder() {
        self.backgroundColor = .orange
    }
    
    func prepareForPrinting(_ beforePrinting: Bool) {
        self.emailDetailButton.clipsToBounds = beforePrinting
        
        // zero height constraints, first four copied from makeHeaderConstraints()
        self.emailDetailButton.mas_makeConstraints { (make) -> Void in
            make?.removeExisting = true
            let _ = make?.left.equalTo()(self.emailShortTime.mas_right)?.with().offset()(self.kEmailDetailButtonMarginLeft)
            let _ = make?.bottom.equalTo()(self.emailShortTime)
            let _ = make?.top.equalTo()(self.emailShortTime)
            let _ = make?.width.equalTo()(self.emailDetailButton)
            if beforePrinting {
                let _ = make?.height.equalTo()(0)
            }
        }
        
        self.emailFavoriteButton.isHidden = beforePrinting
    }
}

class EmailHeaderView: UIView, AccessibleView {
    
    weak var viewDelegate: EmailHeaderViewProtocol?
    private weak var _delegate: EmailHeaderActionsProtocol?
    
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
            self.emailBccTable.delegate = self._delegate
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
    
    fileprivate var emailBcc: UILabel!    //bcc
    fileprivate var emailBccTable: RecipientView!
    
    fileprivate var emailShortTime: UILabel!
    
    fileprivate var emailDetailButton: UIButton!
    
    fileprivate var emailDetailView: UIView!
    
    fileprivate var emailDetailDateLabel: UILabel!
    
    /// support mutiple labels
    private var labelsView: LabelsCollectionView!
    
    fileprivate var emailFavoriteButton: UIButton!
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
    fileprivate let kEmailBodyTextViewMarginLeft: CGFloat = 0//-16.0
    fileprivate let kEmailBodyTextViewMarginRight: CGFloat = 0//-16.0
    fileprivate let kEmailBodyTextViewMarginTop: CGFloat = 16.0
    fileprivate let kSeparatorBetweenHeaderAndBodyMarginTop: CGFloat = 16.0
    
    fileprivate let k12HourMinuteFormat = "h:mm a"
    fileprivate let k24HourMinuteFormat = "HH:mm"

    fileprivate var tempFileUri : URL?
    
    fileprivate var isSentFolder : Bool = false
    
    func getHeight () -> CGFloat {
        return separatorShowImage.frame.origin.y + 6
    }
    
    fileprivate var visible : Bool = false
    
    fileprivate var title : String!
    fileprivate var sender : ContactVO?
    fileprivate var toList : [ContactVO]?
    fileprivate var ccList : [ContactVO]?
    fileprivate var bccList : [ContactVO]?
    fileprivate var labels : [Label]?
    fileprivate var attachmentCount : Int = 0
    
    fileprivate var attachments : [AttachmentInfo] = []
    internal let section : Int = 1
    
    fileprivate var date : Date!
    fileprivate var starred : Bool!
    
    fileprivate var hasExpiration : Bool = false
    fileprivate var hasShowImageCheck : Bool = true
    
    fileprivate var spamScore: Message.SpamScore = .others
    
    var isShowingDetail: Bool = true
    fileprivate var expend : Bool = false
    
    fileprivate var fromSinglelineAttr : NSMutableAttributedString! {
        get {
            let n = self.sender?.name ?? ""
            let e = self.sender?.email ?? ""
            let f = LocalString._general_from_label
            let from = "\(f) \((n.isEmpty ? e : n))"
            let formRange = NSRange (location: 0, length: from.count)
            let attributedString = NSMutableAttributedString(string: from,
                                                             attributes: [NSAttributedString.Key.font : Fonts.h6.medium,
                                                                          NSAttributedString.Key.foregroundColor : UIColor(hexColorCode: "#838897")])
            attributedString.setAttributes([NSAttributedString.Key.font : Fonts.h6.medium,
                                            NSAttributedString.Key.foregroundColor : UIColor(hexColorCode: "#C0C4CE")],
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
                                                             attributes: [NSAttributedString.Key.font : Fonts.h6.medium,
                                                                          NSAttributedString.Key.foregroundColor : UIColor(hexColorCode: "#838897")])
            attributedString.setAttributes([NSAttributedString.Key.font : Fonts.h6.medium,
                                            NSAttributedString.Key.foregroundColor : UIColor(hexColorCode: "#C0C4CE")],
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
                    let n = contact.name
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
                                                             attributes: [NSAttributedString.Key.font : Fonts.h6.medium,
                                                                          NSAttributedString.Key.foregroundColor : UIColor(hexColorCode: "#838897")])
            attributedString.setAttributes([NSAttributedString.Key.font : Fonts.h6.medium,
                                            NSAttributedString.Key.foregroundColor : UIColor(hexColorCode: "#C0C4CE")],
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
                                                             attributes: [NSAttributedString.Key.font : Fonts.h6.medium,
                                                                          NSAttributedString.Key.foregroundColor : UIColor(hexColorCode: "#838897")])
            attributedString.setAttributes([NSAttributedString.Key.font : Fonts.h6.medium,
                                            NSAttributedString.Key.foregroundColor : UIColor(hexColorCode: "#C0C4CE")],
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
                                                             attributes: [NSAttributedString.Key.font : Fonts.h6.medium,
                                                                          NSAttributedString.Key.foregroundColor : UIColor(hexColorCode: "#838897")])
            attributedString.setAttributes([NSAttributedString.Key.font : Fonts.h6.medium,
                                            NSAttributedString.Key.foregroundColor : UIColor(hexColorCode: "#C0C4CE")],
                                           range: formRange)
            return attributedString
        }
    }
    
    fileprivate var bccShortAttr : NSMutableAttributedString! {
        get {
            let bc = LocalString._general_bcc_label
            let bcc = "\(bc) "
            let formRange = NSRange (location: 0, length: bcc.count)
            let attributedString = NSMutableAttributedString(string: bcc,
                                                             attributes: [NSAttributedString.Key.font : Fonts.h6.medium,
                                                                          NSAttributedString.Key.foregroundColor : UIColor(hexColorCode: "#838897")])
            attributedString.setAttributes([NSAttributedString.Key.font : Fonts.h6.medium,
                                            NSAttributedString.Key.foregroundColor : UIColor(hexColorCode: "#C0C4CE")],
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    private func setup() {
        self.backgroundColor = UIColor(RRGGBB: UInt(0xDADEE8))
        
        // init data
        self.title = ""
        self.date = Date()
        self.starred = false
        self.attachmentCount = 0

        self.addSubviews()
        self.layoutIfNeeded()
        self.visible = true
        
        // accessibility
        self.emailToTable.accessibilityLabel = LocalString._general_to_label
        self.emailFromTable.accessibilityLabel = LocalString._general_from_label
        self.emailCcTable.accessibilityLabel = LocalString._general_cc_label
        self.emailBccTable.accessibilityLabel = LocalString._general_bcc_label
        self.accessibilityElements = [self.emailTitle!,
                                      self.emailFrom!, self.emailFromTable!,
                                      self.emailTo!, self.emailToTable!,
                                      self.emailCc!, self.emailCcTable!,
                                      self.emailBcc!, self.emailBccTable!,
                                      self.emailShortTime!,
                                      self.date!,
                                      self.emailFavoriteButton!,
                                      self.emailDetailButton!]
        generateAccessibilityIdentifiers()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    deinit {
        self.visible = false
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
                           isStarred : Bool, time : Date?, labels : [Label]?,
                           showShowImages: Bool, expiration : Date?,
                           score: Message.SpamScore, isSent: Bool) {
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
        self.emailBccTable.contacts = bccList
        self.emailBccTable.showLock(isShow: self.isSentFolder)
        
        self.emailTo.attributedText = toSinglelineAttr
        self.emailCc.attributedText = ccShortAttr
        self.emailBcc.attributedText = bccShortAttr
        
        self.emailFavoriteButton.isSelected = self.starred
        self.emailFavoriteButton.accessibilityLabel = self.starred ? LocalString._starred : LocalString._locations_add_star_action
        
        let timeformat = using12hClockFormat() ? k12HourMinuteFormat : k24HourMinuteFormat
        let isToday = Calendar.current.isDateInToday(self.date)
        let at = LocalString._general_at_label
        let on = LocalString._composer_on
        self.emailShortTime.text = "\(isToday ? at : on) \(self.date.string(format: isToday ? timeformat : "MMM d"))"
        let tm = self.date.formattedWith("'\(on)' EE, MMM d, yyyy '\(at)' \(timeformat)")
        self.emailDetailDateLabel.text = String(format: LocalString._date, "\(tm)")

        var tmplabels : [Label] = []
        if let alllabels = labels {
            for l in alllabels {
                if l.exclusive == false {
                    if l.name.isEmpty || l.color.isEmpty { //will also check the lable id
                    } else {
                        tmplabels.append(l)
                    }
                }
            }
        }
        self.labels = tmplabels
        //update labels
        self.labelsView.update(tmplabels)
        
        self.updateExpirationDate(expiration)
        hasShowImageCheck = showShowImages
        
        //update score information
        self.spamScore = score
        self.spamScoreView.setMessage(msg: self.spamScore.description)
        
        self.layoutIfNeeded()
    }
    
    func update(attachments : [AttachmentInfo]) {
        self.attachmentCount = attachments.count
        self.attachments = attachments
        if (self.attachmentCount > 0) {
            self.emailAttachmentsAmount.text = "\(self.attachmentCount)"
            self.emailAttachmentsAmount.isHidden = false
            self.emailHasAttachmentsImageView.isHidden = false
        } else {
            self.emailAttachmentsAmount.isHidden = true
            self.emailHasAttachmentsImageView.isHidden = true
        }
        self.emailAttachmentsAmount.sizeToFit()
    }
    
    func updateHeaderLayout () {
        self.updateDetailsView(self.isShowingDetail)
    }
    
    func attachmentForIndexPath(_ indexPath: IndexPath) -> AttachmentInfo {
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
        self.attachmentView!.register(UINib(nibName: "AttachmentTableViewCell", bundle: nil),
                                      forCellReuseIdentifier: AttachmentTableViewCell.Constant.identifier)
        
        let nib = UINib(nibName: "ExpirationWarningHeaderCell", bundle: nil)
        self.attachmentView!.register(nib, forHeaderFooterViewReuseIdentifier: "expiration_warning_header_cell")
        
        self.attachmentView!.separatorStyle = .none
        self.attachmentView?.estimatedRowHeight = UITableView.automaticDimension
        self.addSubview(attachmentView!)
    }
    
    fileprivate func createExpirationView() {
        self.expirationView = ExpirationView(frame : CGRect(x: 0, y: 0, width: self.frame.width, height: 0))
        self.addSubview(expirationView!)
    }
    
    fileprivate func createShowImageView() {
        self.showImageView = ShowImageView(frame : CGRect(x: 0, y: 0, width: self.frame.width, height: 0))
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
        self.emailHeaderView = UIView(frame : CGRect(x: 0, y: 0, width: self.frame.width, height: 0))
        self.addSubview(emailHeaderView)
        
        // create title
        self.emailTitle = ActionLabel()
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
        self.emailFavoriteButton.setImage(UIImage(named: "mail_starred")!, for: UIControl.State())
        self.emailFavoriteButton.setImage(UIImage(named: "mail_starred-active")!, for: .selected)
        self.emailFavoriteButton.isSelected = self.starred
        self.emailFavoriteButton.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        self.emailFavoriteButton.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.center
        self.emailHeaderView.addSubview(emailFavoriteButton)
        
        
        // details view
        self.emailDetailView = UIView()
        self.emailDetailView.clipsToBounds = true
        self.emailHeaderView.addSubview(emailDetailView)
        
        self.emailFrom = UILabel()
        self.emailFrom.numberOfLines = 1
        self.emailHeaderView.addSubview(emailFrom)
        
        self.emailFromTable = RecipientView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 0))
        self.emailFromTable.alpha = 0.0
        self.emailHeaderView.addSubview(emailFromTable)
        
        self.emailTo = UILabel()
        self.emailTo.numberOfLines = 1
        self.emailHeaderView.addSubview(emailTo)
        
        self.emailToTable = RecipientView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 0))
        self.emailToTable.alpha = 0.0
        self.emailHeaderView.addSubview(emailToTable)
        
        self.emailCc = UILabel()
        self.emailCc.alpha = 0.0
        self.emailCc.numberOfLines = 1
        self.emailHeaderView.addSubview(emailCc)
        
        self.emailCcTable = RecipientView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 0))
        self.emailCcTable.alpha = 0.0
        self.emailHeaderView.addSubview(emailCcTable)
        
        self.emailBcc = UILabel()
        self.emailBcc.alpha = 0.0
        self.emailBcc.numberOfLines = 1
        self.emailHeaderView.addSubview(emailBcc)
        
        self.emailBccTable = RecipientView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 0))
        self.emailBccTable.alpha = 0.0
        self.emailHeaderView.addSubview(emailBccTable)
        
        self.emailShortTime = UILabel()
        self.emailShortTime.font = Fonts.h6.medium
        self.emailShortTime.numberOfLines = 1
        self.emailShortTime.text = "at \(self.date.string(format: self.k12HourMinuteFormat))".lowercased()
        self.emailShortTime.textColor = UIColor(RRGGBB: UInt(0x838897))
        self.emailShortTime.sizeToFit()
        self.emailHeaderView.addSubview(emailShortTime)
        
        self.emailDetailButton = UIButton()
        self.emailDetailButton.addTarget(self, action: #selector(EmailHeaderView.detailsButtonTapped), for: UIControl.Event.touchUpInside)
        self.emailDetailButton.contentEdgeInsets = UIEdgeInsets.init(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        self.emailDetailButton.titleLabel?.font = Fonts.h6.medium
        self.emailDetailButton.setTitle(LocalString._details, for: UIControl.State())
        self.emailDetailButton.setTitleColor(UIColor(RRGGBB: UInt(0x9397CD)), for: UIControl.State())
        self.emailDetailButton.sizeToFit()
        self.emailHeaderView.addSubview(emailDetailButton)
        
        self.configureEmailDetailDateLabel()
        
        self.emailHasAttachmentsImageView = UIImageView(image: UIImage(named: "mail_attachment"))
        self.emailHasAttachmentsImageView.contentMode = UIView.ContentMode.center
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
            let _ = make?.top.equalTo()(self.labelsView.mas_bottom)?.offset()(self.kSeparatorBetweenHeaderAndBodyMarginTop)
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
        attachmentView!.layoutIfNeeded()
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
            let tm = messageTime.formattedWith("'\(LocalString._composer_on)' EE, MMM d, yyyy '\(LocalString._general_at_label)' \(timeformat)")
            self.emailDetailDateLabel.text = String(format: LocalString._date, "\(tm)")
        } else {
            self.emailDetailDateLabel.text = String(format: LocalString._date, "")
        }
        self.emailDetailDateLabel.textColor = UIColor(RRGGBB: UInt(0x838897)) //UIColor.ProtonMail.Gray_999DA1
        self.emailDetailDateLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailDateLabel)
        
        self.labelsView = LabelsCollectionView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 0))
        labelsView.backgroundColor = UIColor.red
        self.addSubview(labelsView)
    }
    
    fileprivate func makeHeaderConstraints() {
        emailHeaderView.mas_updateConstraints { (make) -> Void in
            make?.removeExisting = true
            make?.top.equalTo()(self)
            make?.left.equalTo()(self)?.offset()(self.kEmailHeaderViewMarginLeft)
            make?.right.equalTo()(self)
            make?.bottom.equalTo()(self.emailDetailView)
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
            make?.removeExisting = true
            let _ = make?.left.equalTo()(self.emailTitle)
            let _ = make?.right.equalTo()(self.emailHeaderView)
            let _ = make?.top.equalTo()(self.emailDetailButton.mas_bottom)
            let _ = make?.height.equalTo()(0)
        }
        
        emailFrom.mas_makeConstraints { (make) -> Void in
            make?.removeExisting = true
            let _ = make?.left.equalTo()(self.emailHeaderView)
            let _ = make?.right.equalTo()(self.emailTitle)
            let _ = make?.top.equalTo()(self.emailTitle.mas_bottom)?.with().offset()(self.kEmailRecipientsViewMarginTop)
        }
        
        emailFromTable.mas_makeConstraints { (make) -> Void in
            make?.removeExisting = true
            let _ = make?.left.equalTo()(36)
            let _ = make?.right.equalTo()(self.emailHeaderView)
            let _ = make?.top.equalTo()(self.emailTitle.mas_bottom)?.with().offset()(self.kEmailRecipientsViewMarginTop)
            let _ = make?.height.equalTo()(self.emailFrom)
        }
        
        let toOffset = self.showTo ? kEmailRecipientsViewMarginTop : 0
        let toHeight = self.showTo ? 16 : 0
        emailTo.mas_makeConstraints { (make) -> Void in
            make?.removeExisting = true
            let _ = make?.left.equalTo()(self.emailHeaderView)
            let _ = make?.right.equalTo()(self.emailTitle)
            let _ = make?.top.equalTo()(self.emailFrom.mas_bottom)?.with().offset()(toOffset)
            let _ = make?.height.equalTo()(toHeight)
        }
        emailToTable.mas_makeConstraints { (make) -> Void in
            make?.removeExisting = true
            let _ = make?.left.equalTo()(36)
            let _ = make?.right.equalTo()(self.emailHeaderView)
            let _ = make?.top.equalTo()(self.emailFrom.mas_bottom)?.with().offset()(toOffset)
            let _ = make?.height.equalTo()(self.emailTo)
        }
        
        let ccOffset = self.showCc ? kEmailRecipientsViewMarginTop : 0
        emailCc.mas_makeConstraints { (make) -> Void in
            make?.removeExisting = true
            let _ = make?.left.equalTo()(self.emailHeaderView)
            let _ = make?.right.equalTo()(self.emailTitle)
            let _ = make?.top.equalTo()(self.emailTo.mas_bottom)?.with().offset()(ccOffset)
        }
        emailCcTable.mas_makeConstraints { (make) -> Void in
            make?.removeExisting = true
            let _ = make?.left.equalTo()(36)
            let _ = make?.right.equalTo()(self.emailHeaderView)
            let _ = make?.top.equalTo()(self.emailTo.mas_bottom)?.with().offset()(ccOffset)
            let _ = make?.height.equalTo()(self.emailCc)
        }

        let bccOffset = self.showBcc ? kEmailRecipientsViewMarginTop : 0
        emailBcc.mas_makeConstraints { (make) -> Void in
            make?.removeExisting = true
            let _ = make?.left.equalTo()(self.emailHeaderView)
            let _ = make?.right.equalTo()(self.emailTitle)
            let _ = make?.top.equalTo()(self.emailCc.mas_bottom)?.with().offset()(bccOffset)
        }
        emailBccTable.mas_makeConstraints { (make) -> Void in
            make?.removeExisting = true
            let _ = make?.left.equalTo()(36)
            let _ = make?.right.equalTo()(self.emailHeaderView)
            let _ = make?.top.equalTo()(self.emailCc.mas_bottom)?.with().offset()(bccOffset)
            let _ = make?.height.equalTo()(self.emailBcc)
        }
        
        emailShortTime.sizeToFit()
        emailShortTime.mas_makeConstraints { (make) -> Void in
            make?.removeExisting = true
            let _ = make?.left.equalTo()(self.emailHeaderView)
            let _ = make?.width.equalTo()(self.emailShortTime.frame.size.width)
            let _ = make?.height.equalTo()(self.emailShortTime.frame.size.height)
            let _ = make?.top.equalTo()(self.emailTo.mas_bottom)?.with().offset()(self.kEmailTimeViewMarginTop)
        }
        
        emailDetailButton.mas_makeConstraints { (make) -> Void in
            make?.removeExisting = true
            let _ = make?.left.equalTo()(self.emailShortTime.mas_right)?.with().offset()(self.kEmailDetailButtonMarginLeft)
            let _ = make?.bottom.equalTo()(self.emailShortTime)
            let _ = make?.top.equalTo()(self.emailShortTime)
            let _ = make?.width.equalTo()(self.emailDetailButton)
        }
        
        emailDetailView.mas_makeConstraints { (make) -> Void in
            make?.removeExisting = true
            let _ = make?.left.equalTo()(self.emailTitle)
            let _ = make?.right.equalTo()(self.emailHeaderView)
            let _ = make?.top.equalTo()(self.emailDetailButton.mas_bottom)
            let _ = make?.height.equalTo()(0)
        }
        
        emailDetailDateLabel.sizeToFit()
        emailDetailDateLabel.mas_makeConstraints { (make) -> Void in
            make?.removeExisting = true
            let _ = make?.left.equalTo()(self.emailDetailView)
            let _ = make?.top.equalTo()(self.emailDetailView)
            let _ = make?.width.equalTo()(self.emailDetailDateLabel.frame.size.width)
            let _ = make?.height.equalTo()(self.emailDetailDateLabel.frame.size.height)
        }
        
        let lbOffset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
        let labelViewHeight = labelsView.getContentSize().height
        self.labelsView.mas_makeConstraints { (make) -> Void in
            make?.removeExisting = true
            make?.left.equalTo()(self.emailHeaderView)
            make?.top.equalTo()(self.emailDetailView.mas_bottom)?.with().offset()(lbOffset)
            make?.right.equalTo()(self)?.with()?.offset()(kEmailHeaderViewMarginRight)
            make?.height.equalTo()(labelViewHeight)
        }
        
        emailAttachmentsAmount.sizeToFit()
        emailAttachmentsAmount.mas_makeConstraints { (make) -> Void in
            make?.removeExisting = true
            let _ = make?.right.equalTo()(self.emailHeaderView)?.offset()(-16)
            let _ = make?.bottom.equalTo()(self.emailDetailButton)
            let _ = make?.height.equalTo()(self.emailAttachmentsAmount.frame.height)
            let _ = make?.width.equalTo()(self.emailAttachmentsAmount.frame.width)
        }
        
        emailHasAttachmentsImageView.mas_makeConstraints { (make) -> Void in
            make?.removeExisting = true
            let _ = make?.right.equalTo()(self.emailAttachmentsAmount.mas_left)?.with().offset()(self.kEmailHasAttachmentsImageViewMarginRight)
            let _ = make?.bottom.equalTo()(self.emailAttachmentsAmount)
            let _ = make?.height.equalTo()(self.emailHasAttachmentsImageView.frame.height)
            let _ = make?.width.equalTo()(self.emailHasAttachmentsImageView.frame.width)
        }
    }
    
    @objc internal func detailsButtonTapped() {
        self.isShowingDetail = !self.isShowingDetail
        self.updateDetailsView(self.isShowingDetail)
        
        // accessibility
        UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged,
                             argument: self.isShowingDetail ? self.emailCc : self.emailDetailButton);
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
                var f = self.frame
                f.size.height = self.getHeight()
                self.frame = f
                self.viewDelegate?.updateSize()
            })
        }
    }
    
    fileprivate let kAnimationOption: UIView.AnimationOptions = .transitionCrossDissolve
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
                self.emailBcc.attributedText = self.bccShortAttr
                self.emailFromTable.alpha = 1.0
                self.emailTo.alpha = self.showTo ? 1.0 : 0.0
                self.emailToTable.alpha = self.showTo ? 1.0 : 0.0
                self.emailCc.alpha = self.showCc ? 1.0 : 0.0
                self.emailCcTable.alpha = self.showCc ? 1.0 : 0.0
                self.emailBcc.alpha = self.showBcc ? 1.0 : 0.0
                self.emailBccTable.alpha = self.showBcc ? 1.0 : 0.0
                
                }, completion: nil)
            
            let efh = emailFromTable.getContentSize().height
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
            
            let eth = emailToTable.getContentSize().height
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
            let ecch = emailCcTable.getContentSize().height
            emailCcTable.mas_makeConstraints { (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(36)
                let _ = make?.right.equalTo()(self.emailHeaderView)
                let _ = make?.top.equalTo()(self.emailToTable.mas_bottom)?.with().offset()(ccOffset)
                let _ = make?.height.equalTo()(ecch)
            }
            
            let bccOffset = self.showBcc ? kEmailRecipientsViewMarginTop : 0
            let bccHeight = self.showBcc ? 16 : 0
            emailBcc.mas_updateConstraints { (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(self.emailHeaderView)
                let _ = make?.right.equalTo()(self.emailTitle)
                let _ = make?.top.equalTo()(self.emailCcTable.mas_bottom)?.with().offset()(bccOffset)
                let _ = make?.height.equalTo()(bccHeight)
            }
            let ebcch = emailBccTable.getContentSize().height
            emailBccTable.mas_makeConstraints { (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(36)
                let _ = make?.right.equalTo()(self.emailHeaderView)
                let _ = make?.top.equalTo()(self.emailCcTable.mas_bottom)?.with().offset()(bccOffset)
                let _ = make?.height.equalTo()(ebcch)
            }
            
            self.emailShortTime.mas_updateConstraints({ (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(self.emailHeaderView)
                let _ = make?.width.equalTo()(0)
                let _ = make?.height.equalTo()(self.emailShortTime.frame.size.height)
                let _ = make?.top.equalTo()(self.emailBccTable.mas_bottom)?.with().offset()(self.kEmailTimeViewMarginTop)
            })
            
            self.emailDetailButton.setTitle(LocalString._hide_details, for: UIControl.State())
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
            
            let lbOffset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
            let labelViewHeight = labelsView.getContentSize().height
            self.labelsView.mas_makeConstraints { (make) -> Void in
                make?.removeExisting = true
                make?.left.equalTo()(self.emailHeaderView)
                make?.top.equalTo()(self.emailDetailView.mas_bottom)?.with().offset()(lbOffset)
                make?.right.equalTo()(self)?.with()?.offset()(kEmailHeaderViewMarginRight)
                make?.height.equalTo()(labelViewHeight)
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
                self.emailToTable.alpha = 0.0
                self.emailCc.alpha = 0.0
                self.emailCcTable.alpha = 0.0
                self.emailBcc.alpha = 0.0
                self.emailBccTable.alpha = 0.0
                }, completion: nil)
            
            let efh = emailFromTable.getContentSize().height
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
            emailBcc.mas_updateConstraints { (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(self.emailHeaderView)
                let _ = make?.right.equalTo()(self.emailTitle)
                let _ = make?.top.equalTo()(self.emailCcTable.mas_bottom)?.with().offset()(0)
                let _ = make?.height.equalTo()(0)
            }
            emailBccTable.mas_makeConstraints { (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(36)
                let _ = make?.right.equalTo()(self.emailHeaderView)
                let _ = make?.top.equalTo()(self.emailBcc)?.with().offset()(self.kEmailRecipientsViewMarginTop)
                let _ = make?.height.equalTo()(0)
            }
            
            self.emailDetailButton.setTitle(LocalString._details, for: UIControl.State())
            self.emailDetailButton.mas_updateConstraints({ (make) -> Void in
                make?.removeExisting = true
                let _ = make?.left.equalTo()(self.emailShortTime.mas_right)?.with().offset()(self.kEmailDetailButtonMarginLeft)
                let _ = make?.bottom.equalTo()(self.emailShortTime)
                let _ = make?.top.equalTo()(self.emailShortTime)
                let _ = make?.width.equalTo()(self.emailDetailButton)
            })

            self.emailTo.sizeToFit()
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
            
            let lbOffset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
            let labelViewHeight = labelsView.getContentSize().height
            self.labelsView.mas_makeConstraints { (make) -> Void in
                make?.removeExisting = true
                make?.left.equalTo()(self.emailHeaderView)
                make?.top.equalTo()(self.emailDetailView.mas_bottom)?.with().offset()(lbOffset)
                make?.right.equalTo()(self)?.with()?.offset()(kEmailHeaderViewMarginRight)
                make?.height.equalTo()(labelViewHeight)
            }
        }
        
        self.updateSelf(true)
    }
}

extension EmailHeaderView: UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AttachmentTableViewCell.Constant.identifier, for: indexPath)
        if let cell = cell as? AttachmentTableViewCell {
            let attachment = self.attachmentForIndexPath(indexPath)
            cell.setFilename(attachment.fileName, fileSize: attachment.size)
            cell.configAttachmentIcon(attachment.mimeType)
        }
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.section
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.expend {
            return attachments.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 34
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "expiration_warning_header_cell") as? ExpirationWarningHeaderCell
        
        cell?.isUserInteractionEnabled = true
        cell?.contentView.isUserInteractionEnabled = true
        
        let count = attachments.count
        cell?.ConfigHeader(title: "\(count) Attachments", section: section, expend: self.expend)
        cell?.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 34.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
}

extension EmailHeaderView: ExpirationWarningHeaderCellDelegate {
    func clicked(at section: Int, expend: Bool) {
        self.expend = expend
        //workaround makes the list UI more smooth when folding
        self.attachmentView?.reloadSections([section], with: .automatic)
        self.updateAttConstraints(true)
        
        //workaround first time run updateAttConstraints can't get contentSize correctly second time does. will fix this later
        DispatchQueue.main.async {
             self.updateAttConstraints(false)
        }
    }
}

extension EmailHeaderView: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if attachments.count > indexPath.row {
            let attachment = attachmentForIndexPath(indexPath)
            if !attachment.isDownloaded {
                if let att = attachment.att {
                    downloadAttachment(att, forIndexPath: indexPath)
                }
            } else if let localURL = attachment.localUrl {
                if FileManager.default.fileExists(atPath: localURL.path, isDirectory: nil) {
                    if let att = attachment.att {
                        if let key_packet = att.keyPacket {
                            if let data: Data = Data(base64Encoded:key_packet, options: NSData.Base64DecodingOptions(rawValue: 0)) {
                                let fixedFilename = attachment.fileName.clear
                                self.openLocalURL(localURL, keyPackage: data, fileName: fixedFilename, type: attachment.mimeType)
                            }
                        }
                    } else {
                        let fixedFilename = attachment.fileName.clear
                        self.openLocalURL(localURL, fileName: fixedFilename, type: attachment.mimeType)
                    }
                } else {
                    if let att = attachment.att, let context = att.managedObjectContext {
                        CoreDataService.shared.enqueue(context: context) { (context) in
                            att.localURL = nil
                            let error = context.saveUpstreamIfNeeded()
                            if error != nil  {
                                PMLog.D(" error: \(String(describing: error))")
                            }
                            self.downloadAttachment(att, forIndexPath: indexPath)
                        }
                    }
                }
            }
        }

    }
    
    // MARK: Private methods
    
    fileprivate func downloadAttachment(_ attachment: Attachment, forIndexPath indexPath: IndexPath) {
        //TODO:: fix me
        //TODO:: network call should move out from this view to a vm
//        sharedMessageDataService.fetchAttachmentForAttachment(attachment, downloadTask: { (taskOne : URLSessionDownloadTask) -> Void in
//            if let cell = self.attachmentView?.cellForRow(at: indexPath) as? AttachmentTableViewCell {
//                cell.progressView.alpha = 1.0
//                cell.progressView.progress = 0.0
//                let totalValue = attachment.fileSize.floatValue
//                //TODO::fix me
//
//                let apiService = APIService.shared
//                apiService.getSession().setDownloadTaskDidWriteDataBlock({ (session, taskTwo, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) -> Void in
//                    if taskOne == taskTwo {
//                        var progressPercentage =  ( Float(totalBytesWritten) / totalValue )
//                        if progressPercentage >= 1.000000000 {
//                            progressPercentage = 1.0
//                        }
//                        DispatchQueue.main.async(execute: {
//                            UIView.animate(withDuration: 0.25, animations: { () -> Void in
//                                cell.progressView.progress = progressPercentage
//                            })
//                        })
//                    }
//                })
//            }
//            }, completion: { (_, url, error) -> Void in
//                if let cell = self.attachmentView!.cellForRow(at: indexPath) as? AttachmentTableViewCell {
//                    if let e = error {
//                        cell.progressView.isHidden = true
//                        self.downloadFailed(e)
//                    } else {
//                        UIView.animate(withDuration: 0.25, animations: { () -> Void in
//                            cell.progressView.isHidden = true
//                            if let localURL = attachment.localURL {
//                                if FileManager.default.fileExists(atPath: localURL.path, isDirectory: nil) {
//                                    if let key_packet = attachment.keyPacket {
//                                        if let data: Data = Data(base64Encoded:key_packet, options: NSData.Base64DecodingOptions(rawValue: 0)) {
//                                            let fixedFilename = attachment.fileName.clear
//                                            self.openLocalURL(localURL, keyPackage: data,
//                                                              fileName: fixedFilename,
//                                                              type: attachment.mimeType)
//                                        }
//                                    }
//                                }
//                            }
//                        })
//                    }
//                } else {
//                    if let e = error {
//                        e.alertErrorToast()
//                    }
//                }
//        })
    }
    
    internal func openLocalURL(_ localURL: URL, keyPackage:Data, fileName:String, type: String) {
        self.delegate?.quickLook(attachment: localURL, keyPackage: keyPackage, fileName: fileName, type: type)
    }
    
    
    internal func openLocalURL(_ localURL: URL, fileName:String, type: String) {
        self.delegate?.quickLook(file: localURL, fileName: fileName, type: type)
    }
    
    fileprivate func downloadFailed(_ error : NSError) {
        self.delegate?.downloadFailed(error: error)
    }
    
}
