// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import LifetimeTracker
import MBProgressHUD
import ProtonCoreFoundations
import ProtonCoreUIFoundations
import UIKit

final class ContactDetailViewController: UIViewController, AccessibleView, ComposeSaveHintProtocol {
    typealias Dependencies = HasComposerViewFactory & HasContactViewsFactory

    let viewModel: ContactDetailsViewModel
    lazy var customView = ContactDetailView()
    private var editItem: UIBarButtonItem?
    private(set) var loaded = false
    private let dependencies: Dependencies

    init(viewModel: ContactDetailsViewModel, dependencies: Dependencies) {
        self.viewModel = viewModel
        self.dependencies = dependencies
        super.init(nibName: nil, bundle: nil)
        trackLifetime()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationItems()
        configureTableView()
        configureButtons()
        viewModel.reloadView = { [weak self] in
            self?.configureHeader()
            self?.customView.tableView.reloadData()
        }

        Task {
            do {
                try await viewModel.getDetails(loading: {
                    MBProgressHUD.showAdded(to: self.view, animated: true)
                })
                await MainActor.run(body: { [weak self] in
                    self?.configureHeader()
                    self?.customView.tableView.reloadData()
                    self?.loaded = true
                })
            } catch {
                await MainActor.run(body: {
                    error.alert(at: self.view)
                })
            }
            _ = await MainActor.run(body: {
                MBProgressHUD.hide(for: self.view, animated: true)
            })
        }

        generateAccessibilityIdentifiers()
        navigationItem.assignNavItemIndentifiers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.dependencies.user.undoActionManager.register(handler: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        customView.tableView.sizeHeaderToFit()
        customView.tableView.zeroMargin()
        var insets = customView.tableView.contentInset
        insets.bottom = 100
        customView.tableView.contentInset = insets
    }
}

extension ContactDetailViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections().count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionType = viewModel.sections()[section]
        switch sectionType {
        case .type2_warning:
            return viewModel.verifyType2 ? 0 : 1
        case .type3_warning:
            if !viewModel.type3Error() {
                return viewModel.verifyType3 ? 0 : 1
            }
            return 0
        case .type3_error:
            return viewModel.type3Error() ? 1 : 0
        case .debuginfo:
            return 0
        case .emails:
            return viewModel.emails.count
        case .cellphone:
            return viewModel.phones.count
        case .home_address:
            return viewModel.addresses.count
        case .custom_field:
            return viewModel.fields.count
        case .notes:
            return viewModel.notes.count
        case .url:
            return viewModel.urls.count
        case .display_name:
            return 1
        case .email_header, .encrypted_header, .delete:
            return 0
        case .birthday:
            return viewModel.birthday == nil ? 0 : 1
        case .organization:
            return viewModel.organizations.count
        case .nickName:
            return viewModel.nickNames.count
        case .title:
            return viewModel.titles.count
        case .gender:
            return viewModel.gender == nil ? 0 : 1
        case .anniversary:
            return viewModel.anniversary == nil ? 0 : 1
        case .addNewField, .share:
            return 0
        }
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let titleStyle = FontManager.CaptionStrong.foregroundColor(ColorProvider.BrandNorm)
        let section = indexPath.section
        let row = indexPath.row
        let sectionType = viewModel.sections()[section]

        if sectionType == .type2_warning {
            if let cell = tableView.dequeueReusableCell(
                withIdentifier: Constants.contactsDetailsWarningCell,
                for: indexPath
            ) as? ContactsDetailsWarningCell {
                cell.configCell(warning: .signatureWarning)
                cell.selectionStyle = .none
                return cell
            }
        } else if sectionType == .type3_error {
            if let cell = tableView.dequeueReusableCell(
                withIdentifier: Constants.contactsDetailsWarningCell,
                for: indexPath
            ) as? ContactsDetailsWarningCell {
                cell.configCell(warning: .decryptionError)
                cell.selectionStyle = .none
                return cell
            }
        } else if sectionType == .type3_warning {
            if let cell = tableView.dequeueReusableCell(
                withIdentifier: Constants.contactsDetailsWarningCell,
                for: indexPath
            ) as? ContactsDetailsWarningCell {
                cell.configCell(warning: .signatureWarning)
                cell.selectionStyle = .none
                return cell
            }
        } else if sectionType == .debuginfo {
            if let cell = tableView.dequeueReusableCell(
                withIdentifier: Constants.contactsDetailsWarningCell,
                for: indexPath
            ) as? ContactsDetailsWarningCell {
                cell.configCell(forlog: "")
                cell.selectionStyle = .none
                return cell
            }
        } else if sectionType == .emails {
            if let cell = tableView.dequeueReusableCell(
                withIdentifier: Constants.contactDetailDisplayEmailCell,
                for: indexPath
            ) as? ContactDetailDisplayEmailCell {
                let emails = viewModel.emails
                let email = emails[row]
                let colors = emails[row].getCurrentlySelectedContactGroupColors()
                cell.configCell(
                    title: email.newType.title,
                    value: email.newEmail,
                    contactGroupColors: colors,
                    titleStyle: titleStyle
                )
                cell.selectionStyle = .default
                return cell
            }
        }

        let cell = tableView.dequeueReusableCell(
            withIdentifier: Constants.contactDetailsDisplayCell,
            for: indexPath
        ) as? ContactDetailsDisplayCell
        cell?.selectionStyle = .default
        switch sectionType {
        case .cellphone:
            let cells = viewModel.phones
            let tel = cells[row]
            cell?.configCell(title: tel.newType.title, value: tel.newPhone, titleStyle: titleStyle)
        case .home_address:
            let addrs = viewModel.addresses
            let addr = addrs[row]
            cell?.configCell(title: addr.newType.title, value: addr.fullAddress(), titleStyle: titleStyle)
        case .gender:
            cell?.configCell(
                title: viewModel.gender?.infoType.title ?? .empty,
                value: viewModel.gender?.newValue ?? .empty,
                titleStyle: titleStyle
            )
        case .birthday:
            cell?.configCell(
                title: viewModel.birthday?.infoType.title ?? .empty,
                value: viewModel.birthday?.newValue ?? .empty,
                titleStyle: titleStyle
            )
        case .organization:
            let org = viewModel.organizations[row]
            cell?.configCell(
                title: org.infoType.title,
                value: org.newValue,
                titleStyle: titleStyle
            )
        case .title:
            let title = viewModel.titles[row]
            cell?.configCell(
                title: title.infoType.title,
                value: title.newValue,
                titleStyle: titleStyle
            )
        case .nickName:
            let nickName = viewModel.nickNames[row]
            cell?.configCell(
                title: nickName.infoType.title,
                value: nickName.newValue,
                titleStyle: titleStyle
            )
        case .custom_field:
            let fields = viewModel.fields
            let field = fields[row]
            cell?.configCell(title: field.newType.title, value: field.newField)
        case .notes:
            let notes = viewModel.notes
            let note = notes[row]
            cell?.configCell(
                title: LocalString._contacts_info_notes,
                value: note.newNote,
                titleStyle: titleStyle
            )
            cell?.value.numberOfLines = 0
        case .url:
            let urls = viewModel.urls
            let url = urls[row]
            cell?.configCell(
                title: url.newType.title,
                value: url.newUrl,
                titleStyle: titleStyle
            )
        case .anniversary:
            cell?.configCell(
                title: viewModel.anniversary?.infoType.title ?? .empty,
                value: viewModel.anniversary?.newValue ?? .empty,
                titleStyle: titleStyle
            )
        case .email_header, .encrypted_header, .delete, .share,
             .type2_warning, .type3_error, .type3_warning, .debuginfo, .emails, .display_name, .addNewField:
            break
        }
        return cell ?? UITableViewCell()
    }
}

// MARK: - UITableViewDelegate

extension ContactDetailViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        performAction action: Selector,
        forRowAt indexPath: IndexPath,
        withSender sender: Any?
    ) {
        if action == #selector(UIResponderStandardEditActions.copy(_:)) {
            var copyString = ""
            let section = indexPath.section
            let row = indexPath.row
            let sectionType = viewModel.sections()[section]
            switch sectionType {
            case .display_name:
                copyString = viewModel.getProfile().newDisplayName
            case .emails:
                copyString = viewModel.emails[row].newEmail
            case .cellphone:
                copyString = viewModel.phones[row].newPhone
            case .home_address:
                copyString = viewModel.addresses[row].fullAddress()
            case .custom_field:
                copyString = viewModel.fields[row].newField
            case .notes:
                copyString = viewModel.notes[row].newNote
            case .url:
                copyString = viewModel.urls[row].newUrl
            case .organization:
                copyString = viewModel.organizations[row].newValue
            case .nickName:
                copyString = viewModel.nickNames[row].newValue
            case .gender:
                copyString = viewModel.gender?.newValue ?? .empty
            case .title:
                copyString = viewModel.titles[row].newValue
            case .birthday:
                copyString = viewModel.birthday?.newValue ?? .empty
            case .anniversary:
                copyString = viewModel.anniversary?.newValue ?? .empty
            default:
                break
            }

            UIPasteboard.general.string = copyString
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sectionType = viewModel.sections()[indexPath.section]
        switch sectionType {
        case .display_name, .emails, .cellphone, .home_address,
             .custom_field, .notes, .url,
             .type2_warning, .type3_error, .type3_warning, .debuginfo, .birthday, .share, .anniversary:
            return UITableView.automaticDimension
        case .email_header, .encrypted_header, .delete:
            return 0.0
        case .organization, .nickName, .title, .gender, .addNewField:
            return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    // swiftlint:disable:next function_body_length
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let section = indexPath.section
        let row = indexPath.row
        let sectionType = viewModel.sections()[section]
        switch sectionType {
        case .emails:
            guard !viewModel.dependencies.user.isStorageExceeded else {
                LocalString._storage_exceeded.alertToastBottom()
                return
            }
            let emails = viewModel.emails
            let email = emails[row]
            let contact = viewModel.contact
            let contactVO = ContactVO(name: contact.name,
                                      email: email.newEmail,
                                      isProtonMailContact: false)
            presentComposer(contact: contactVO)
        case .encrypted_header:
            break
        case .cellphone:
            openPhone(viewModel.phones[row])
        case .home_address:
            let addrs = viewModel.addresses
            let addr = addrs[row]
            let fulladdr = addr.fullAddress()
            if !fulladdr.isEmpty {
                let fullUrl = "http://maps.apple.com/?q=\(fulladdr)"
                if let strUrl = fullUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                   let url = URL(string: strUrl) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        case .url:
            let urls = viewModel.urls
            let url = urls[row]
            if let urlURL = URL(string: url.origUrl),
               var comps = URLComponents(url: urlURL, resolvingAgainstBaseURL: false) {
                if comps.scheme == nil {
                    comps.scheme = "http"
                }
                if let validUrl = comps.url {
                    let application = UIApplication.shared
                    if application.canOpenURL(validUrl) {
                        application.open(validUrl, options: [:], completionHandler: nil)
                        break
                    }
                }
            }
            LocalString._invalid_url.alertToastBottom()
        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }

    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(
        _ tableView: UITableView,
        canPerformAction action: Selector,
        forRowAt indexPath: IndexPath,
        withSender sender: Any?
    ) -> Bool {
        return action == #selector(UIResponderStandardEditActions.copy(_:))
    }
}

extension ContactDetailViewController {
    private func configureButtons() {
        let emailTap = UITapGestureRecognizer(target: self, action: #selector(self.tapSendContact))
        customView.emailContactImageView.addGestureRecognizer(emailTap)

        let callTap = UITapGestureRecognizer(target: self, action: #selector(self.tapCallContact))
        customView.callContactImageView.addGestureRecognizer(callTap)

        let shareTap = UITapGestureRecognizer(target: self, action: #selector(self.tapShareContact(_:)))
        customView.shareContactImageView.addGestureRecognizer(shareTap)
    }

    private func configureHeader() {
        if let profilePicture = viewModel.profilePicture {
            customView.profileImageView.isHidden = false
            customView.profileImageView.image = profilePicture
            customView.shortNameLabel.isHidden = true
        } else {
            customView.profileImageView.isHidden = true
            customView.shortNameLabel.text = viewModel.getProfile().newDisplayName.initials()
            customView.shortNameLabel.isHidden = false
        }

        let attributes = FontManager
            .Headline
            .alignment(.center)
            .addTruncatingTail()
        customView.displayNameLabel.attributedText = viewModel.getProfile().newDisplayName
            .apply(style: attributes)

        if viewModel.emails.isEmpty {
            customView.emailContactImageView.backgroundColor = .lightGray
            customView.emailContactImageView.isUserInteractionEnabled = false
        } else {
            customView.emailContactImageView.isUserInteractionEnabled = true
            customView.emailContactImageView.backgroundColor = ColorProvider.BrandNorm
        }

        if viewModel.phones.isEmpty {
            customView.callContactImageView.backgroundColor = .lightGray
            customView.callContactImageView.isUserInteractionEnabled = false
        } else {
            customView.callContactImageView.backgroundColor = ColorProvider.BrandNorm
            customView.callContactImageView.isUserInteractionEnabled = true
        }
        customView.shareContactImageView.isUserInteractionEnabled = true
    }

    private func configureNavigationItems() {
        editItem = .init(
            title: LocalString._general_edit_action,
            style: .plain,
            target: self,
            action: #selector(self.openEditContactView)
        )
        let attributes = FontManager.DefaultStrong
            .foregroundColor(ColorProvider.InteractionNorm)
        editItem?.setTitleTextAttributes(attributes, for: .normal)
        navigationItem.rightBarButtonItem = editItem
        navigationItem.largeTitleDisplayMode = .never
    }

    private func configureTableView() {
        customView.tableView.register(
            .init(nibName: Constants.contactsDetailsShareCell, bundle: nil),
            forCellReuseIdentifier: Constants.contactsDetailsShareCell
        )
        customView.tableView.register(
            .init(nibName: Constants.contactsDetailsWarningCell, bundle: nil),
            forCellReuseIdentifier: Constants.contactsDetailsWarningCell
        )
        customView.tableView.register(
            .init(nibName: Constants.contactDetailDisplayEmailCell, bundle: nil),
            forCellReuseIdentifier: Constants.contactDetailDisplayEmailCell
        )
        customView.tableView.register(
            .init(nibName: Constants.contactDetailsDisplayCell, bundle: nil),
            forCellReuseIdentifier: Constants.contactDetailsDisplayCell
        )
        customView.tableView.register(
            .init(nibName: Constants.contactDetailHeaderView, bundle: nil),
            forHeaderFooterViewReuseIdentifier: Constants.contactDetailHeaderView
        )
        customView.tableView.rowHeight = UITableView.automaticDimension
        customView.tableView.estimatedRowHeight = 60.0
        customView.tableView.sectionHeaderHeight = UITableView.automaticDimension
        customView.tableView.estimatedSectionHeaderHeight = UITableView.automaticDimension
        customView.tableView.noSeparatorsBelowFooter()
        customView.tableView.dataSource = self
        customView.tableView.delegate = self
    }
}

// MARK: - Actions

extension ContactDetailViewController {
    @objc
    private func openEditContactView() {
        let newView = dependencies.contactViewsFactory.makeEditView(contact: viewModel.contact)
        newView.delegate = self
        let nav = UINavigationController(rootViewController: newView)
        present(nav, animated: true, completion: nil)
    }

    private func presentComposer(contact: ContactVO) {
        let composer = dependencies.composerViewFactory.makeComposer(
            msg: nil,
            action: .newDraft,
            isEditingScheduleMsg: false,
            toContact: contact
        )
        guard let nav = navigationController else {
            return
        }
        nav.present(composer, animated: true)
    }

    @objc
    private func tapShareContact(_ sender: UIView) {
        let exported = viewModel.export()
        if !exported.isEmpty {
            let filename = viewModel.exportName()
            let tempFileUri = FileManager.default.attachmentDirectory.appendingPathComponent(filename)

            try? exported.write(to: tempFileUri, atomically: true, encoding: String.Encoding.utf8)

            // set up activity view controller
            let urlToShare = [tempFileUri]
            let activityViewController = UIActivityViewController(activityItems: urlToShare, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = view
            activityViewController.popoverPresentationController?.sourceRect = sender.frame
            // exclude some activity types from the list (optional)
            activityViewController.excludedActivityTypes = [
                .postToFacebook,
                .postToTwitter,
                .postToWeibo,
                .copyToPasteboard,
                .saveToCameraRoll,
                .addToReadingList,
                .postToFlickr,
                .postToVimeo,
                .postToTencentWeibo,
                .assignToContact
            ]
            activityViewController.excludedActivityTypes?.append(.markupAsPDF)
            activityViewController.excludedActivityTypes?.append(.openInIBooks)
            present(activityViewController, animated: true, completion: nil)
        }
    }

    @objc
    private func tapCallContact() {
        guard let phone = viewModel.phones.first else { return }
        openPhone(phone)
    }

    private func openPhone(_ phone: ContactEditPhone) {
        var allowedCharactersSet = NSCharacterSet.decimalDigits
        allowedCharactersSet.insert("+")
        allowedCharactersSet.insert(",")
        allowedCharactersSet.insert("*")
        allowedCharactersSet.insert("#")
        let formatedNumber = phone.newPhone.components(separatedBy: allowedCharactersSet.inverted).joined(separator: "")
        let phoneUrl = "tel://\(formatedNumber)"
        if let phoneCallURL = URL(string: phoneUrl) {
            let application = UIApplication.shared
            if application.canOpenURL(phoneCallURL) {
                application.open(phoneCallURL, options: [:], completionHandler: nil)
            }
        }
    }

    @objc
    private func tapSendContact() {
        guard !viewModel.dependencies.user.isStorageExceeded else {
            LocalString._storage_exceeded.alertToastBottom()
            return
        }
        let contactVO = ContactVO(
            name: viewModel.contact.name,
            email: viewModel.emails[0].newEmail,
            isProtonMailContact: false
        )
        presentComposer(contact: contactVO)
    }
}

extension ContactDetailViewController: ContactEditViewControllerDelegate {
    func deleted() {
        navigationController?.popViewController(animated: true)
    }

    func updated() {
        viewModel.rebuild()
        configureHeader()
        customView.tableView.reloadData()
    }
}

extension ContactDetailViewController: LifetimeTrackable {
    class var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }
}

extension ContactDetailViewController {
    enum Constants {
        static let contactsDetailsShareCell = "ContactEditAddCell"
        static let contactsDetailsWarningCell = "ContactsDetailsWarningCell"
        static let contactDetailDisplayEmailCell = "ContactDetailDisplayEmailCell"
        static let contactDetailsDisplayCell = "ContactDetailsDisplayCell"
        static let contactDetailHeaderView = "ContactSectionHeadView"
    }
}

extension ContactDetailViewController: UndoActionHandlerBase {
    var undoActionManager: UndoActionManagerProtocol? {
        nil
    }

    var delaySendSeconds: Int {
        viewModel.dependencies.user.userInfo.delaySendSeconds
    }

    var composerPresentingVC: UIViewController? {
        self
    }

    func showUndoAction(undoTokens: [String], title: String) { }
}
