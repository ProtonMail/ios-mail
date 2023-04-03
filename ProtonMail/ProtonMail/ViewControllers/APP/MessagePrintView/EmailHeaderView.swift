//
//  EmailHeaderView.swift
//  Proton Mail - Created on 7/27/15.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_Foundations

protocol EmailHeaderViewProtocol: AnyObject {
    func updateSize()
}

protocol EmailHeaderActionsProtocol: RecipientViewDelegate, ShowImageViewDelegate {
    func star(changed isStarred: Bool)
}

// for new MessageHeaderViewController
extension EmailHeaderView {
    func inject(recepientDelegate: RecipientViewDelegate) {
        self.emailFromTable.delegate = recepientDelegate
        self.emailToTable.delegate = recepientDelegate
        self.emailCcTable.delegate = recepientDelegate
        self.emailBccTable.delegate = recepientDelegate
    }

    override func prepareForInterfaceBuilder() {
        self.backgroundColor = .orange
    }

    func prepareForPrinting(_ beforePrinting: Bool) {
        self.emailDetailButton.clipsToBounds = beforePrinting

        // zero height constraints, first four copied from makeHeaderConstraints()
        emailDetailButton.removeConstraints(emailDetailButton.constraints)
        [
            emailDetailButton.leftAnchor.constraint(equalTo: emailShortTime.rightAnchor, constant: kEmailDetailButtonMarginLeft),
            emailDetailButton.bottomAnchor.constraint(equalTo: emailShortTime.bottomAnchor),
            emailDetailButton.topAnchor.constraint(equalTo: emailShortTime.topAnchor)
        ].activate()

        if beforePrinting {
            emailDetailButton.heightAnchor.constraint(equalToConstant: 0).isActive = true
        }

        self.emailFavoriteButton.isHidden = beforePrinting
    }
}

// TODO: Used in printer mode. Removed this after the improvement of print format
class EmailHeaderView: UIView, AccessibleView {

    private struct Color {
        static let Gray_C9CED4 = UIColor(RRGGBB: UInt(0xC9CED4))
        static let Gray_999DA1 = UIColor(RRGGBB: UInt(0x999DA1))
    }

    weak var viewDelegate: EmailHeaderViewProtocol?
    private weak var _delegate: EmailHeaderActionsProtocol?

    var delegate: EmailHeaderActionsProtocol? {
        get {
            return self._delegate
        }
        set {
            self._delegate = newValue
            // set delegate here
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

    fileprivate var emailFrom: UILabel!    // from or sender
    fileprivate var emailFromTable: RecipientView!

    fileprivate var emailTo: UILabel!    // to
    fileprivate var emailToTable: RecipientView!

    fileprivate var emailCc: UILabel!    // cc
    fileprivate var emailCcTable: RecipientView!

    fileprivate var emailBcc: UILabel!    // bcc
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

    fileprivate var attachmentView: UITableView?

    fileprivate var expirationView: ExpirationView!
    fileprivate var showImageView: ShowImageView!
    fileprivate var spamScoreView: SpamScoreWarningView!

    // separators
    fileprivate var separatorHeader: UIView!
    fileprivate var separatorExpiration: UIView!
    fileprivate var separatorAttachment: UIView!
    fileprivate var separatorShowImage: UIView!

    // const header view
    fileprivate let kEmailHeaderViewMarginTop: CGFloat = 12.0
    fileprivate let kEmailHeaderViewMarginLeft: CGFloat = 16.0
    fileprivate let kEmailHeaderViewMarginRight: CGFloat = -16.0

    fileprivate let kEmailTitleViewMarginRight: CGFloat = -8.0
    fileprivate let kEmailFavoriteButtonHeight: CGFloat = 44
    fileprivate let kEmailFavoriteButtonWidth: CGFloat = 52
    fileprivate let kEmailRecipientsViewMarginTop: CGFloat = 6.0
    fileprivate let kEmailTimeViewMarginTop: CGFloat = 6.0
    fileprivate let kEmailDetailButtonMarginLeft: CGFloat = 5.0
    fileprivate let kEmailHasAttachmentsImageViewMarginRight: CGFloat = -4.0
    fileprivate let kSeparatorBetweenHeaderAndBodyMarginTop: CGFloat = 16.0

    fileprivate let k12HourMinuteFormat = "h:mm a"
    fileprivate let k24HourMinuteFormat = "HH:mm"

    fileprivate var isSentFolder: Bool = false

    func getHeight () -> CGFloat {
        return separatorShowImage.frame.origin.y + 6
    }
    
    fileprivate var visible : Bool = false
    
    fileprivate var title : String!
    fileprivate var sender : ContactVO?
    fileprivate var toList : [ContactVO]?
    fileprivate var ccList : [ContactVO]?
    fileprivate var bccList : [ContactVO]?
    fileprivate var labels : [LabelEntity]?
    fileprivate var attachmentCount : Int = 0
    
    fileprivate var attachments : [AttachmentInfo] = []
    internal let section : Int = 1
    
    fileprivate var date : Date!
    fileprivate var starred : Bool!
    
    fileprivate var hasExpiration : Bool = false
    fileprivate var hasShowImageCheck : Bool = true
    
    fileprivate var spamScore: SpamScore = .others
    
    var isShowingDetail: Bool = true
    fileprivate var expend: Bool = false

    fileprivate var fromSinglelineAttr: NSMutableAttributedString! {
        get {
            let n = self.sender?.name ?? ""
            let e = self.sender?.email ?? ""
            let f = LocalString._general_from_label
            let from = "\(f) \((n.isEmpty ? e : n))"
            let formRange = NSRange(location: 0, length: from.count)
            let attributedString = NSMutableAttributedString(string: from,
                                                             attributes: [NSAttributedString.Key.font: Fonts.h6.medium,
                                                                          NSAttributedString.Key.foregroundColor: UIColor(hexColorCode: "#838897")])
            attributedString.setAttributes([NSAttributedString.Key.font: Fonts.h6.medium,
                                            NSAttributedString.Key.foregroundColor: UIColor(hexColorCode: "#C0C4CE")],
                                           range: formRange)

            return attributedString
        }
    }

    fileprivate var fromShortAttr: NSMutableAttributedString! {
        get {
            let f = LocalString._general_from_label
            let from = "\(f) "
            let formRange = NSRange(location: 0, length: from.count)
            let attributedString = NSMutableAttributedString(string: from,
                                                             attributes: [NSAttributedString.Key.font: Fonts.h6.medium,
                                                                          NSAttributedString.Key.foregroundColor: UIColor(hexColorCode: "#838897")])
            attributedString.setAttributes([NSAttributedString.Key.font: Fonts.h6.medium,
                                            NSAttributedString.Key.foregroundColor: UIColor(hexColorCode: "#C0C4CE")],
                                           range: formRange)
            return attributedString
        }
    }

    fileprivate var toSinglelineAttr: NSMutableAttributedString! {
        get {
            var strTo: String = ""
            var count = (toList?.count ?? 0)
            if count > 0 {
                count += (ccList?.count ?? 0) + (bccList?.count ?? 0)
                if let contact = toList?[0] {
                    let n = contact.name
                    let e = contact.email
                    strTo = n.isEmpty ? e : n
                }
            }

            if count > 1 {
                strTo += " +\(count - 1)"
            }

            let t = LocalString._general_to_label
            let to = "\(t): \(strTo)"
            let formRange = NSRange(location: 0, length: to.count)
            let attributedString = NSMutableAttributedString(string: to,
                                                             attributes: [NSAttributedString.Key.font: Fonts.h6.medium,
                                                                          NSAttributedString.Key.foregroundColor: UIColor(hexColorCode: "#838897")])
            attributedString.setAttributes([NSAttributedString.Key.font: Fonts.h6.medium,
                                            NSAttributedString.Key.foregroundColor: UIColor(hexColorCode: "#C0C4CE")],
                                           range: formRange)
            return attributedString
        }
    }

    fileprivate var toShortAttr: NSMutableAttributedString! {
        get {
            let t = LocalString._general_to_label
            let to = "\(t): "
            let formRange = NSRange(location: 0, length: to.count)
            let attributedString = NSMutableAttributedString(string: to,
                                                             attributes: [NSAttributedString.Key.font: Fonts.h6.medium,
                                                                          NSAttributedString.Key.foregroundColor: UIColor(hexColorCode: "#838897")])
            attributedString.setAttributes([NSAttributedString.Key.font: Fonts.h6.medium,
                                            NSAttributedString.Key.foregroundColor: UIColor(hexColorCode: "#C0C4CE")],
                                           range: formRange)
            return attributedString
        }
    }

    fileprivate var ccShortAttr: NSMutableAttributedString! {
        get {
            let c = LocalString._general_cc_label
            let cc = "\(c): "
            let formRange = NSRange(location: 0, length: cc.count)
            let attributedString = NSMutableAttributedString(string: cc,
                                                             attributes: [NSAttributedString.Key.font: Fonts.h6.medium,
                                                                          NSAttributedString.Key.foregroundColor: UIColor(hexColorCode: "#838897")])
            attributedString.setAttributes([NSAttributedString.Key.font: Fonts.h6.medium,
                                            NSAttributedString.Key.foregroundColor: UIColor(hexColorCode: "#C0C4CE")],
                                           range: formRange)
            return attributedString
        }
    }

    fileprivate var bccShortAttr: NSMutableAttributedString! {
        get {
            let bc = LocalString._general_bcc_label
            let bcc = "\(bc) "
            let formRange = NSRange(location: 0, length: bcc.count)
            let attributedString = NSMutableAttributedString(string: bcc,
                                                             attributes: [NSAttributedString.Key.font: Fonts.h6.medium,
                                                                          NSAttributedString.Key.foregroundColor: UIColor(hexColorCode: "#838897")])
            attributedString.setAttributes([NSAttributedString.Key.font: Fonts.h6.medium,
                                            NSAttributedString.Key.foregroundColor: UIColor(hexColorCode: "#C0C4CE")],
                                           range: formRange)
            return attributedString
        }
    }

    fileprivate var showTo: Bool {
        get {
            return  (self.toList?.count ?? 0) > 0 ? true : false
        }
    }

    fileprivate var showCc: Bool {
        get {
            return (self.ccList?.count ?? 0) > 0 ? true : false
        }
    }

    fileprivate var showBcc: Bool {
        get {
            return (self.bccList?.count ?? 0) > 0 ? true : false
        }
    }

    fileprivate var showLabels: Bool {
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
        self.emailToTable.accessibilityLabel = "\(LocalString._general_to_label):"
        self.emailFromTable.accessibilityLabel = LocalString._general_from_label
        self.emailCcTable.accessibilityLabel = "\(LocalString._general_cc_label):"
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

    func updateExpirationDate ( _ expiration: Date? ) {
        if let expirTime = expiration {
            let offset: Int = Int(expirTime.timeIntervalSince(Date()))
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
                           isStarred : Bool, time : Date?, labels : [LabelEntity]?,
                           showShowImages: Bool, expiration : Date?,
                           score: SpamScore, isSent: Bool) {
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
        self.emailFavoriteButton.accessibilityLabel = self.starred ? LocalString._menu_starred_title : LocalString._locations_add_star_action

        let timeFormat = using12hClockFormat() ? k12HourMinuteFormat : k24HourMinuteFormat
        let isToday = Calendar.current.isDateInToday(self.date)
        let dateOrTimeString = isToday ? self.date.formattedWith(timeFormat): self.date.formattedWith("MMM d")
        self.emailShortTime.text = String(format: isToday  ? LocalString._composer_forward_header_at : LocalString._composer_forward_header_on, dateOrTimeString)
        let date = self.date.formattedWith("E, MMM d, yyyy")
        let detailedDate = String(format: LocalString._composer_forward_header_on_detail, date, self.date.formattedWith(timeFormat))
        self.emailDetailDateLabel.text = String(format: LocalString._date, detailedDate)

        var tmplabels : [LabelEntity] = []
        if let alllabels = labels {
            for l in alllabels {
                if l.type == .messageLabel {
                    if l.name.isEmpty || l.color.isEmpty { //will also check the lable id
                    } else {
                        tmplabels.append(l)
                    }
                }
            }
        }
        self.labels = tmplabels
        // update labels
        self.labelsView.update(tmplabels)

        self.updateExpirationDate(expiration)
        hasShowImageCheck = showShowImages

        // update score information
        self.spamScore = score
        self.spamScoreView.setMessage(msg: self.spamScore.description)

        self.layoutIfNeeded()
    }

    func updateHeaderLayout () {
        self.updateDetailsView(self.isShowingDetail)
    }

    func attachmentForIndexPath(_ indexPath: IndexPath) -> AttachmentInfo {
        return self.attachments[indexPath.row]
    }

    func showingDetail() {
        self.isShowingDetail = !self.isShowingDetail
        self.updateDetailsView(self.isShowingDetail)
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
        self.expirationView = ExpirationView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 0))
        self.addSubview(expirationView!)
    }

    fileprivate func createShowImageView() {
        self.showImageView = ShowImageView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 0))
        self.addSubview(showImageView!)
    }

    fileprivate func createSpamScoreView() {
        self.spamScoreView = SpamScoreWarningView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 0))
        self.spamScoreView.alpha = 0.0
        self.addSubview(spamScoreView!)
    }

    fileprivate func createSeparator() {
        self.separatorHeader = UIView()
        self.separatorHeader.backgroundColor = Color.Gray_C9CED4
        self.addSubview(separatorHeader)
        self.separatorExpiration = UIView()
        self.separatorExpiration.backgroundColor = Color.Gray_C9CED4
        self.addSubview(separatorExpiration)
        self.separatorAttachment = UIView()
        self.separatorAttachment.backgroundColor = Color.Gray_C9CED4
        self.addSubview(separatorAttachment)
        self.separatorShowImage = UIView()
        self.separatorShowImage.backgroundColor = Color.Gray_C9CED4
        self.addSubview(separatorShowImage)
    }

    fileprivate func createHeaderView() {

        // create header container
        self.emailHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 0))
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
        self.emailFavoriteButton.setImage(Asset.mailStarred.image, for: UIControl.State())
        self.emailFavoriteButton.setImage(Asset.mailStarredActive.image, for: .selected)
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
        self.emailShortTime.text = "at \(self.date.formattedWith(self.k12HourMinuteFormat)))".lowercased()
        self.emailShortTime.textColor = UIColor(RRGGBB: UInt(0x838897))
        self.emailShortTime.sizeToFit()
        self.emailHeaderView.addSubview(emailShortTime)

        self.emailDetailButton = UIButton()
        self.emailDetailButton.contentEdgeInsets = UIEdgeInsets.init(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        self.emailDetailButton.titleLabel?.font = Fonts.h6.medium
        self.emailDetailButton.setTitle(LocalString._details, for: UIControl.State())
        self.emailDetailButton.setTitleColor(UIColor(RRGGBB: UInt(0x9397CD)), for: UIControl.State())
        self.emailDetailButton.sizeToFit()
        self.emailHeaderView.addSubview(emailDetailButton)

        self.configureEmailDetailDateLabel()

        self.emailHasAttachmentsImageView = UIImageView(image: Asset.mailAttachment.image)
        self.emailHasAttachmentsImageView.contentMode = UIView.ContentMode.center
        self.emailHasAttachmentsImageView.sizeToFit()
        self.emailHeaderView.addSubview(emailHasAttachmentsImageView)

        self.emailAttachmentsAmount = UILabel()
        self.emailAttachmentsAmount.font = Fonts.h4.regular
        self.emailAttachmentsAmount.numberOfLines = 1
        self.emailAttachmentsAmount.text = "\(self.attachmentCount)"
        self.emailAttachmentsAmount.textColor = Color.Gray_999DA1
        self.emailAttachmentsAmount.sizeToFit()
        self.emailHeaderView.addSubview(emailAttachmentsAmount)

        if self.attachmentCount > 0 {
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
        separatorHeader.removeConstraints(separatorHeader.constraints)
        [
            separatorHeader.leftAnchor.constraint(equalTo: self.leftAnchor),
         separatorHeader.rightAnchor.constraint(equalTo: self.rightAnchor),
         separatorHeader.topAnchor.constraint(equalTo: labelsView.bottomAnchor, constant: kSeparatorBetweenHeaderAndBodyMarginTop),
         separatorHeader.heightAnchor.constraint(equalToConstant: 1)
        ].activate()

        let viewHeight = self.hasExpiration ? 26 : 0
        expirationView.removeConstraints(expirationView.constraints)
        [
            expirationView.leftAnchor.constraint(equalTo: self.leftAnchor),
            expirationView.rightAnchor.constraint(equalTo: self.rightAnchor),
            expirationView.topAnchor.constraint(equalTo: separatorHeader.bottomAnchor),
            expirationView.heightAnchor.constraint(equalToConstant: CGFloat(viewHeight))
        ].activate()

        let separatorHeight = self.hasExpiration ? 1 : 0
        separatorExpiration.removeConstraints(separatorExpiration.constraints)
        [
            separatorExpiration.leftAnchor.constraint(equalTo: self.leftAnchor),
            separatorExpiration.rightAnchor.constraint(equalTo: self.rightAnchor),
            separatorExpiration.topAnchor.constraint(equalTo: expirationView.bottomAnchor),
            separatorExpiration.heightAnchor.constraint(equalToConstant: CGFloat(separatorHeight))
        ].activate()
    }

    func updateSpamScoreConstraints() {
        let size = self.spamScore == .others ? 0.0 : self.spamScoreView.fitHeight()
        self.spamScoreView.alpha = self.spamScore == .others ? 0.0 : 1.0
        spamScoreView.removeConstraints(spamScoreView.constraints)
        [
            spamScoreView.leftAnchor.constraint(equalTo: self.leftAnchor),
            spamScoreView.rightAnchor.constraint(equalTo: self.rightAnchor),
            spamScoreView.topAnchor.constraint(equalTo: separatorAttachment.bottomAnchor),
            spamScoreView.heightAnchor.constraint(equalToConstant: size)
        ].activate()
    }

    func updateShowImageConstraints() {
        let viewHeight = self.hasShowImageCheck ? 36 : 0
        showImageView.removeConstraints(showImageView.constraints)
        [
            showImageView.leftAnchor.constraint(equalTo: self.leftAnchor),
            showImageView.rightAnchor.constraint(equalTo: self.rightAnchor),
            showImageView.topAnchor.constraint(equalTo: spamScoreView.bottomAnchor),
            showImageView.heightAnchor.constraint(equalToConstant: CGFloat(viewHeight))
        ].activate()

        separatorShowImage.removeConstraints(separatorShowImage.constraints)
        [
            separatorShowImage.leftAnchor.constraint(equalTo: self.leftAnchor),
            separatorShowImage.rightAnchor.constraint(equalTo: self.rightAnchor),
            separatorShowImage.topAnchor.constraint(equalTo: showImageView!.bottomAnchor),
            separatorShowImage.heightAnchor.constraint(equalToConstant: 0)
        ].activate()
    }

    func updateAttConstraints (_ animition: Bool) {
        guard self.visible == true else {
            return
        }
        attachmentView!.reloadData()
        attachmentView!.layoutIfNeeded()
        let viewHeight = self.attachmentCount > 0 ? attachmentView!.contentSize.height : 0
        attachmentView!.removeConstraints(attachmentView!.constraints)
        [
            attachmentView!.leftAnchor.constraint(equalTo: self.leftAnchor),
            attachmentView!.rightAnchor.constraint(equalTo: self.rightAnchor),
            attachmentView!.topAnchor.constraint(equalTo: separatorExpiration!.bottomAnchor),
            attachmentView!.heightAnchor.constraint(equalToConstant: viewHeight)
        ].activate()

        let separatorHeight = self.attachmentCount == 0 ? 0 : 1
        separatorAttachment.removeConstraints(separatorAttachment.constraints)
        [
            separatorAttachment.leftAnchor.constraint(equalTo: self.leftAnchor),
            separatorAttachment.rightAnchor.constraint(equalTo: self.rightAnchor),
            separatorAttachment.topAnchor.constraint(equalTo: attachmentView!.bottomAnchor),
            separatorAttachment.heightAnchor.constraint(equalToConstant: CGFloat(separatorHeight))
        ].activate()

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
            let timeFormat = using12hClockFormat() ? k12HourMinuteFormat : k24HourMinuteFormat
            let tm = String(format: LocalString._composer_forward_header_on_detail, messageTime.formattedWith("E, MMM d, yyyy"), messageTime.formattedWith(timeFormat))
            self.emailDetailDateLabel.text = String(format: LocalString._date, tm)
        } else {
            self.emailDetailDateLabel.text = String(format: LocalString._date, "")
        }
        self.emailDetailDateLabel.textColor = UIColor(RRGGBB: UInt(0x838897))
        self.emailDetailDateLabel.sizeToFit()
        self.emailDetailView.addSubview(emailDetailDateLabel)

        self.labelsView = LabelsCollectionView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 0))
        labelsView.backgroundColor = UIColor.red
        self.addSubview(labelsView)
    }

    private func makeHeaderConstraints() {
        emailHeaderView.removeConstraints(emailHeaderView.constraints)
        [
            emailHeaderView.topAnchor.constraint(equalTo: self.topAnchor),
            emailHeaderView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: kEmailHeaderViewMarginLeft),
            emailHeaderView.rightAnchor.constraint(equalTo: self.rightAnchor),
            emailHeaderView.bottomAnchor.constraint(equalTo: emailDetailView.bottomAnchor)
        ].activate()

        emailFavoriteButton.removeConstraints(emailFavoriteButton.constraints)
        [
            emailFavoriteButton.topAnchor.constraint(equalTo: emailHeaderView.topAnchor),
            emailFavoriteButton.rightAnchor.constraint(equalTo: emailHeaderView.rightAnchor),
            emailFavoriteButton.heightAnchor.constraint(equalToConstant: kEmailFavoriteButtonHeight),
            emailFavoriteButton.widthAnchor.constraint(equalToConstant: kEmailFavoriteButtonWidth)
        ].activate()

        emailTitle.removeConstraints(emailTitle.constraints)
        [
            emailTitle.leftAnchor.constraint(equalTo: emailHeaderView.leftAnchor),
            emailTitle.topAnchor.constraint(equalTo: emailHeaderView.topAnchor, constant: kEmailHeaderViewMarginTop),
            emailTitle.rightAnchor.constraint(equalTo: emailFavoriteButton.leftAnchor, constant: -kEmailTitleViewMarginRight)
        ].activate()

        emailDetailView.removeConstraints(emailDetailView.constraints)
        [
            emailDetailView.leftAnchor.constraint(equalTo: emailTitle.leftAnchor),
            emailDetailView.rightAnchor.constraint(equalTo: emailHeaderView.rightAnchor),
            emailDetailView.topAnchor.constraint(equalTo: emailDetailButton.bottomAnchor),
            emailDetailView.heightAnchor.constraint(equalToConstant: 0)
        ].activate()


        emailFrom.removeConstraints(emailFrom.constraints)
        [
            emailFrom.leftAnchor.constraint(equalTo: emailHeaderView.leftAnchor),
            emailFrom.rightAnchor.constraint(equalTo: emailTitle.rightAnchor),
            emailFrom.topAnchor.constraint(equalTo: emailTitle.bottomAnchor, constant: kEmailRecipientsViewMarginTop),
        ].activate()

        let efh = emailFromTable.getContentSize().height
        emailFromTable.removeConstraints(emailFromTable.constraints)
        [
            emailFromTable.leftAnchor.constraint(equalTo: emailHeaderView.leftAnchor, constant: 40),
            emailFromTable.rightAnchor.constraint(equalTo: emailHeaderView.rightAnchor),
            emailFromTable.topAnchor.constraint(equalTo: emailTitle.bottomAnchor, constant: kEmailRecipientsViewMarginTop),
            emailFromTable.heightAnchor.constraint(equalToConstant: efh)
        ].activate()

        let toOffset = self.showTo ? kEmailRecipientsViewMarginTop : 0
        let toHeight = self.showTo ? 16 : 0
        emailTo.removeConstraints(emailTo.constraints)
        [
            emailTo.leftAnchor.constraint(equalTo: emailHeaderView.leftAnchor),
            emailTo.rightAnchor.constraint(equalTo: emailTitle.rightAnchor),
            emailTo.topAnchor.constraint(equalTo: emailFromTable.bottomAnchor, constant: toOffset),
            emailTo.heightAnchor.constraint(equalToConstant: CGFloat(toHeight))
        ].activate()

        let eth = emailToTable.getContentSize().height
        emailToTable.removeConstraints(emailToTable.constraints)
        [
            emailToTable.leftAnchor.constraint(equalTo: emailHeaderView.leftAnchor, constant: 36),
            emailToTable.rightAnchor.constraint(equalTo: self.emailHeaderView.rightAnchor),
            emailToTable.topAnchor.constraint(equalTo: self.emailFromTable.bottomAnchor, constant: toOffset),
            emailToTable.heightAnchor.constraint(equalToConstant: eth)
        ].activate()

        let ccOffset = self.showCc ? kEmailRecipientsViewMarginTop : 0
        emailCc.removeConstraints(emailCc.constraints)
        [
            emailCc.leftAnchor.constraint(equalTo: self.emailHeaderView.leftAnchor),
            emailCc.rightAnchor.constraint(equalTo: self.emailTitle.rightAnchor),
            emailCc.topAnchor.constraint(equalTo: self.emailToTable.bottomAnchor, constant: ccOffset)
        ].activate()

        let ech = emailCcTable.getContentSize().height
        emailCcTable.removeConstraints(emailCcTable.constraints)
        [
            emailCcTable.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 36),
            emailCcTable.rightAnchor.constraint(equalTo: self.emailHeaderView.rightAnchor),
            emailCcTable.topAnchor.constraint(equalTo: self.emailCc.bottomAnchor, constant: ccOffset),
            emailCcTable.heightAnchor.constraint(equalToConstant: ech)
        ].activate()

        let bccOffset = self.showBcc ? kEmailRecipientsViewMarginTop : 0
        emailBcc.removeConstraints(emailBcc.constraints)
        [
            emailBcc.leftAnchor.constraint(equalTo: self.emailHeaderView.leftAnchor),
            emailBcc.rightAnchor.constraint(equalTo: self.emailTitle.rightAnchor),
            emailBcc.topAnchor.constraint(equalTo: self.emailCc.bottomAnchor, constant: bccOffset)
        ].activate()

        let ebh = emailBccTable.getContentSize().height
        emailBccTable.removeConstraints(emailBccTable.constraints)
        [
            emailBccTable.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 36),
            emailBccTable.rightAnchor.constraint(equalTo: self.emailHeaderView.rightAnchor),
            emailBccTable.topAnchor.constraint(equalTo: self.emailBcc.bottomAnchor, constant: bccOffset),
            emailBccTable.heightAnchor.constraint(equalToConstant: ebh)
        ].activate()

        emailShortTime.sizeToFit()
        emailShortTime.removeConstraints(emailShortTime.constraints)
        [
            emailShortTime.leftAnchor.constraint(equalTo: emailHeaderView.leftAnchor),
            emailShortTime.widthAnchor.constraint(equalToConstant: emailShortTime.frame.size.width),
            emailShortTime.heightAnchor.constraint(equalToConstant: emailShortTime.frame.size.height),
            emailShortTime.topAnchor.constraint(equalTo: emailToTable.bottomAnchor, constant: kEmailTimeViewMarginTop)
        ].activate()

        emailShortTime.removeConstraints(emailShortTime.constraints)
        [
            emailShortTime.leftAnchor.constraint(equalTo: self.emailHeaderView.leftAnchor),
            emailShortTime.widthAnchor.constraint(equalToConstant: emailShortTime.frame.size.width),
            emailShortTime.heightAnchor.constraint(equalToConstant: emailShortTime.frame.size.height),
            emailShortTime.topAnchor.constraint(equalTo: self.emailToTable.bottomAnchor, constant: self.kEmailTimeViewMarginTop)
        ].activate()

        emailDetailView.removeConstraints(emailDetailView.constraints)
        [
            emailDetailView.leftAnchor.constraint(equalTo: self.emailTitle.leftAnchor),
            emailDetailView.rightAnchor.constraint(equalTo: self.emailHeaderView.rightAnchor),
            emailDetailView.topAnchor.constraint(equalTo: self.emailDetailButton.bottomAnchor),
            emailDetailView.heightAnchor.constraint(equalToConstant: 0)
        ].activate()

        emailDetailDateLabel.sizeToFit()
        emailDetailDateLabel.removeConstraints(emailDetailDateLabel.constraints)
        [
            emailDetailDateLabel.leftAnchor.constraint(equalTo: self.emailDetailView.leftAnchor),
            emailDetailDateLabel.topAnchor.constraint(equalTo: self.emailDetailView.topAnchor),
            emailDetailDateLabel.rightAnchor.constraint(equalTo: self.emailDetailView.rightAnchor),
            emailDetailDateLabel.heightAnchor.constraint(equalToConstant: self.emailDetailDateLabel.frame.size.height)
        ].activate()

        let lbOffset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
        let labelViewHeight = labelsView.getContentSize().height
        labelsView.removeConstraints(labelsView.constraints)
        [
            labelsView.leftAnchor.constraint(equalTo: self.emailHeaderView.leftAnchor),
            labelsView.topAnchor.constraint(equalTo: self.emailDetailView.bottomAnchor, constant: lbOffset),
            labelsView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: kEmailHeaderViewMarginRight),
            labelsView.heightAnchor.constraint(equalToConstant: labelViewHeight)
        ].activate()

        emailAttachmentsAmount.sizeToFit()
        emailAttachmentsAmount.removeConstraints(emailAttachmentsAmount.constraints)
        [
            emailAttachmentsAmount.rightAnchor.constraint(equalTo: self.emailHeaderView.rightAnchor, constant: -16),
            emailAttachmentsAmount.bottomAnchor.constraint(equalTo: self.emailDetailButton.bottomAnchor),
            emailAttachmentsAmount.heightAnchor.constraint(equalToConstant: emailAttachmentsAmount.frame.height),
            emailAttachmentsAmount.widthAnchor.constraint(equalToConstant: emailAttachmentsAmount.frame.width)
        ].activate()

        emailHasAttachmentsImageView.removeConstraints(emailHasAttachmentsImageView.constraints)
        [
            emailHasAttachmentsImageView.rightAnchor.constraint(equalTo: self.emailAttachmentsAmount.leftAnchor, constant: -kEmailHasAttachmentsImageViewMarginRight),
            emailHasAttachmentsImageView.bottomAnchor.constraint(equalTo: self.emailAttachmentsAmount.bottomAnchor),
            emailHasAttachmentsImageView.heightAnchor.constraint(equalToConstant: emailHasAttachmentsImageView.frame.height),
            emailHasAttachmentsImageView.widthAnchor.constraint(equalToConstant: emailHasAttachmentsImageView.frame.width)
        ].activate()
    }

    @objc internal func emailFavoriteButtonTapped() {
        self.starred = !self.starred
        self.delegate?.star(changed: self.starred)
        self.emailFavoriteButton.isSelected = self.starred
    }

    fileprivate func updateSelf(_ anim: Bool) {
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
    fileprivate func updateDetailsView(_ needsShow: Bool) {
        guard self.visible == true else {
            return
        }
        if needsShow {
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
            emailFromTable.removeConstraints(emailFromTable.constraints)
            [
                emailFromTable.leftAnchor.constraint(equalTo: emailHeaderView.leftAnchor, constant: 40),
                emailFromTable.rightAnchor.constraint(equalTo: emailHeaderView.rightAnchor),
                emailFromTable.topAnchor.constraint(equalTo: emailTitle.bottomAnchor, constant: kEmailRecipientsViewMarginTop),
                emailFromTable.heightAnchor.constraint(equalToConstant: efh)
            ].activate()

            let toOffset = self.showTo ? kEmailRecipientsViewMarginTop : 0
            let toHeight = self.showTo ? 16 : 0
            emailTo.removeConstraints(emailTo.constraints)
            [
                emailTo.leftAnchor.constraint(equalTo: self.emailHeaderView.leftAnchor),
                emailTo.rightAnchor.constraint(equalTo: self.emailTitle.rightAnchor),
                emailTo.topAnchor.constraint(equalTo: self.emailFromTable.bottomAnchor, constant: toOffset),
                emailTo.heightAnchor.constraint(equalToConstant: CGFloat(toHeight))
            ].activate()

            let eth = emailToTable.getContentSize().height
            emailToTable.removeConstraints(emailToTable.constraints)
            [
                emailToTable.leftAnchor.constraint(equalTo: emailHeaderView.leftAnchor, constant: 36),
                emailToTable.rightAnchor.constraint(equalTo: emailHeaderView.rightAnchor),
                emailToTable.topAnchor.constraint(equalTo: emailFromTable.bottomAnchor),
                emailToTable.heightAnchor.constraint(equalToConstant: eth)
            ].activate()

            let ccOffset = self.showCc ? kEmailRecipientsViewMarginTop : 0
            let ccHeight = self.showCc ? 16 : 0
            emailCc.removeConstraints(emailCc.constraints)
            [
                emailCc.leftAnchor.constraint(equalTo: emailHeaderView.leftAnchor),
                emailCc.rightAnchor.constraint(equalTo: emailTitle.rightAnchor),
                emailCc.topAnchor.constraint(equalTo: emailToTable.bottomAnchor, constant: ccOffset),
                emailCc.heightAnchor.constraint(equalToConstant: CGFloat(ccHeight))
            ].activate()

            let ecch = emailCcTable.getContentSize().height
            emailCcTable.removeConstraints(emailCcTable.constraints)
            [
                emailCcTable.leftAnchor.constraint(equalTo: emailHeaderView.leftAnchor, constant: 36),
                emailCcTable.rightAnchor.constraint(equalTo: emailHeaderView.rightAnchor),
                emailCcTable.topAnchor.constraint(equalTo: emailToTable.bottomAnchor),
                emailCcTable.heightAnchor.constraint(equalToConstant: ecch)
            ].activate()

            let bccOffset = self.showBcc ? kEmailRecipientsViewMarginTop : 0
            let bccHeight = self.showBcc ? 16 : 0
            emailBcc.removeConstraints(emailBcc.constraints)
            [
                emailBcc.leftAnchor.constraint(equalTo: emailHeaderView.leftAnchor),
                emailBcc.rightAnchor.constraint(equalTo: emailTitle.rightAnchor),
                emailBcc.topAnchor.constraint(equalTo: emailCcTable.bottomAnchor, constant: bccOffset),
                emailBcc.heightAnchor.constraint(equalToConstant: CGFloat(bccHeight))
            ].activate()

            let ebcch = emailBccTable.getContentSize().height
            emailBccTable.removeConstraints(emailBccTable.constraints)
            [
                emailBccTable.leftAnchor.constraint(equalTo: emailHeaderView.leftAnchor, constant: 36),
                emailBccTable.rightAnchor.constraint(equalTo: emailHeaderView.rightAnchor),
                emailBccTable.topAnchor.constraint(equalTo: emailCcTable.bottomAnchor),
                emailBccTable.heightAnchor.constraint(equalToConstant: ebcch)
            ].activate()

            emailShortTime.removeConstraints(emailShortTime.constraints)
            [
                emailShortTime.leftAnchor.constraint(equalTo: emailHeaderView.leftAnchor),
                emailShortTime.widthAnchor.constraint(equalToConstant: 0),
                emailShortTime.heightAnchor.constraint(equalToConstant: emailShortTime.frame.size.height),
                emailShortTime.topAnchor.constraint(equalTo: emailBccTable.bottomAnchor, constant: kEmailTimeViewMarginTop)
            ].activate()

            self.emailDetailButton.setTitle(LocalString._hide_details, for: UIControl.State())
            emailDetailButton.removeConstraints(emailDetailButton.constraints)
            [
                emailDetailButton.leftAnchor.constraint(equalTo: emailShortTime.rightAnchor),
                emailDetailButton.bottomAnchor.constraint(equalTo: emailShortTime.bottomAnchor),
                emailDetailButton.topAnchor.constraint(equalTo: emailShortTime.topAnchor),
                emailDetailButton.widthAnchor.constraint(equalTo: emailDetailButton.widthAnchor)
            ].activate()

            emailDetailView.removeConstraints(emailDetailView.constraints)
            [
                emailDetailView.leftAnchor.constraint(equalTo: emailTitle.leftAnchor),
                emailDetailView.rightAnchor.constraint(equalTo: emailHeaderView.rightAnchor),
                emailDetailView.topAnchor.constraint(equalTo: emailDetailButton.bottomAnchor, constant: 10)
            ].activate()

            emailDetailDateLabel.sizeToFit()
            emailDetailDateLabel.removeConstraints(emailDetailDateLabel.constraints)
            [
                emailDetailDateLabel.leftAnchor.constraint(equalTo: emailDetailView.leftAnchor),
                emailDetailDateLabel.topAnchor.constraint(equalTo: emailDetailView.topAnchor),
                emailDetailDateLabel.rightAnchor.constraint(equalTo: emailDetailView.rightAnchor),
                emailDetailDateLabel.heightAnchor.constraint(equalToConstant: emailDetailDateLabel.frame.size.height),
                emailDetailDateLabel.bottomAnchor.constraint(equalTo: emailDetailView.bottomAnchor)
            ].activate()

            let lbOffset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
            let labelViewHeight = labelsView.getContentSize().height
            labelsView.removeConstraints(labelsView.constraints)
            [
                labelsView.leftAnchor.constraint(equalTo: emailHeaderView.leftAnchor),
                labelsView.topAnchor.constraint(equalTo: emailDetailView.bottomAnchor, constant: lbOffset),
                labelsView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -kEmailHeaderViewMarginRight),
                labelsView.heightAnchor.constraint(equalToConstant: labelViewHeight)
            ].activate()

        } else {

            UIView.transition(with: self.emailFrom, duration: 0.3, options: kAnimationOption, animations: { () -> Void in
                self.emailFrom.attributedText = self.fromShortAttr // self.fromSinglelineAttr
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
            emailFromTable.removeConstraints(emailFromTable.constraints)
            [
                emailFromTable.leftAnchor.constraint(equalTo: emailHeaderView.leftAnchor, constant: 40),
                emailFromTable.rightAnchor.constraint(equalTo: emailHeaderView.rightAnchor),
                emailFromTable.topAnchor.constraint(equalTo: emailTitle.bottomAnchor, constant: kEmailRecipientsViewMarginTop),
                emailFromTable.heightAnchor.constraint(equalToConstant: efh)
            ].activate()

            let toOffset = self.showTo ? kEmailRecipientsViewMarginTop : 0
            let toHeight = self.showTo ? 16 : 0
            emailTo.removeConstraints(emailTo.constraints)
            [
                emailTo.leftAnchor.constraint(equalTo: self.emailHeaderView.leftAnchor),
                emailTo.rightAnchor.constraint(equalTo: self.emailTitle.rightAnchor),
                emailTo.topAnchor.constraint(equalTo: self.emailFromTable.bottomAnchor, constant: toOffset),
                emailTo.heightAnchor.constraint(equalToConstant: CGFloat(toHeight))
            ].activate()

            let eth = emailToTable.getContentSize().height
            emailToTable.removeConstraints(emailToTable.constraints)
            [
                emailToTable.leftAnchor.constraint(equalTo: emailHeaderView.leftAnchor, constant: 36),
                emailToTable.rightAnchor.constraint(equalTo: emailHeaderView.rightAnchor),
                emailToTable.topAnchor.constraint(equalTo: emailFromTable.bottomAnchor, constant: toOffset),
                emailToTable.heightAnchor.constraint(equalToConstant: eth)
            ].activate()

            emailCc.removeConstraints(emailCc.constraints)
            [
                emailCc.leftAnchor.constraint(equalTo: emailHeaderView.leftAnchor),
                emailCc.rightAnchor.constraint(equalTo: emailTitle.rightAnchor),
                emailCc.topAnchor.constraint(equalTo: emailToTable.bottomAnchor, constant: 0),
                emailCc.heightAnchor.constraint(equalToConstant: 0)
            ].activate()

            emailCcTable.removeConstraints(emailCcTable.constraints)
            [
                emailCcTable.leftAnchor.constraint(equalTo: emailHeaderView.leftAnchor, constant: 36),
                emailCcTable.rightAnchor.constraint(equalTo: emailHeaderView.rightAnchor),
                emailCcTable.topAnchor.constraint(equalTo: emailCc.topAnchor, constant: kEmailRecipientsViewMarginTop),
                emailCcTable.heightAnchor.constraint(equalToConstant: 0)
            ].activate()

            emailBcc.removeConstraints(emailBcc.constraints)
            [
                emailBcc.leftAnchor.constraint(equalTo: emailHeaderView.leftAnchor),
                emailBcc.rightAnchor.constraint(equalTo: emailTitle.rightAnchor),
                emailBcc.topAnchor.constraint(equalTo: emailCcTable.bottomAnchor, constant: 0),
                emailBcc.heightAnchor.constraint(equalToConstant: 0)
            ].activate()

            emailBccTable.removeConstraints(emailBccTable.constraints)
            [
                emailBccTable.leftAnchor.constraint(equalTo: emailHeaderView.leftAnchor, constant: 36),
                emailBccTable.rightAnchor.constraint(equalTo: emailHeaderView.rightAnchor),
                emailBccTable.topAnchor.constraint(equalTo: emailBcc.topAnchor, constant: kEmailRecipientsViewMarginTop),
                emailBccTable.heightAnchor.constraint(equalToConstant: 0)
            ].activate()

            self.emailDetailButton.setTitle(LocalString._details, for: UIControl.State())

            emailDetailButton.removeConstraints(emailDetailButton.constraints)
            [
                emailDetailButton.leftAnchor.constraint(equalTo: emailShortTime.rightAnchor, constant: kEmailDetailButtonMarginLeft),
                emailDetailButton.bottomAnchor.constraint(equalTo: emailShortTime.bottomAnchor),
                emailDetailButton.topAnchor.constraint(equalTo: emailShortTime.topAnchor),
            ].activate()

            self.emailTo.sizeToFit()
            emailTo.removeConstraints(emailTo.constraints)
            [
                emailTo.leftAnchor.constraint(equalTo: emailHeaderView.leftAnchor),
                emailTo.widthAnchor.constraint(equalToConstant: emailTo.frame.size.width),
                emailTo.heightAnchor.constraint(equalToConstant: emailTo.frame.size.height),
                emailTo.topAnchor.constraint(equalTo: emailFromTable.bottomAnchor, constant: toOffset)
            ].activate()

            self.emailShortTime.sizeToFit()
            emailShortTime.removeConstraints(emailShortTime.constraints)
            [
                emailShortTime.leftAnchor.constraint(equalTo: emailHeaderView.leftAnchor),
                emailShortTime.widthAnchor.constraint(equalToConstant: emailShortTime.frame.size.width),
                emailShortTime.heightAnchor.constraint(equalToConstant: emailShortTime.frame.size.height),
                emailShortTime.topAnchor.constraint(equalTo: emailToTable.bottomAnchor, constant: kEmailTimeViewMarginTop)
            ].activate()

            emailDetailView.removeConstraints(emailDetailView.constraints)
            [
                emailDetailView.leftAnchor.constraint(equalTo: emailTitle.leftAnchor),
                emailDetailView.rightAnchor.constraint(equalTo: emailHeaderView.rightAnchor),
                emailDetailView.topAnchor.constraint(equalTo: emailDetailButton.bottomAnchor),
                emailDetailView.heightAnchor.constraint(equalToConstant: 0)
            ].activate()

            let lbOffset = self.showLabels ? kEmailRecipientsViewMarginTop : 0
            let labelViewHeight = labelsView.getContentSize().height
            labelsView.removeConstraints(labelsView.constraints)
            [
                labelsView.leftAnchor.constraint(equalTo: emailHeaderView.leftAnchor),
                labelsView.topAnchor.constraint(equalTo: emailDetailView.bottomAnchor, constant: lbOffset),
                labelsView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -kEmailHeaderViewMarginRight),
                labelsView.heightAnchor.constraint(equalToConstant: labelViewHeight)
            ].activate()
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
            cell.configAttachmentIcon(attachment.type)
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
        cell?.configHeader(title: "\(count) Attachments", section: section, expend: self.expend)
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
        // workaround makes the list UI more smooth when folding
        self.attachmentView?.reloadSections([section], with: .automatic)
        self.updateAttConstraints(true)

        // workaround first time run updateAttConstraints can't get contentSize correctly second time does. will fix this later
        DispatchQueue.main.async {
             self.updateAttConstraints(false)
        }
    }
}

extension EmailHeaderView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
