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

class ContactDetailViewController: ProtonMailViewController, ViewModelProtocol {
    
    fileprivate var viewModel : ContactDetailsViewModel!
    
    private let kInvalidEmailShakeTimes: Float         = 3.0
    private let kInvalidEmailShakeOffset: CGFloat      = 10.0
    
    
    fileprivate let kContactDetailsHeaderView : String      = "ContactSectionHeadView"
    fileprivate let kContactDetailsHeaderID : String        = "contact_section_head_view"
    fileprivate let kContactDetailsDisplayCell : String     = "contacts_details_display_cell"
    fileprivate let kContactDetailsUpgradeCell : String     = "contacts_details_upgrade_cell"
    fileprivate let kContactsDetailsShareCell: String       = "contacts_details_share_cell"
    fileprivate let kContactsDetailsWarningCell: String     = "contacts_details_warning_cell"
    
    fileprivate let kEditContactSegue : String              = "toEditContactSegue"
    fileprivate let kToComposeSegue : String                = "toCompose"
    fileprivate let kToUpgradeAlertSegue : String           = "toUpgradeAlertSegue"

    @IBOutlet weak var tableView: UITableView!
    
    fileprivate var doneItem: UIBarButtonItem!
    fileprivate var loaded : Bool = false
    
    func inactiveViewModel() {
    }
    
    func setViewModel(_ vm: Any) {
        viewModel = vm as! ContactDetailsViewModel
    }
    
    ///
    override func viewDidLoad() {
        super.viewDidLoad()
        self.doneItem = UIBarButtonItem(title: NSLocalizedString("Edit", comment: "Action"),
                                        style: UIBarButtonItemStyle.plain,
                                        target: self, action: #selector(didTapEditButton(sender:)))
        self.navigationItem.rightBarButtonItem = doneItem
        
        viewModel.getDetails(loading: {
            ActivityIndicatorHelper.showActivityIndicator(at: self.view)
        }) { (contact, error) in
            if nil != contact {
                self.tableView.reloadData()
                self.loaded = true
            }
            ActivityIndicatorHelper.hideActivityIndicator(at: self.view)
        }
        
        let nib = UINib(nibName: kContactDetailsHeaderView, bundle: nil)
        tableView.register(nib, forHeaderFooterViewReuseIdentifier: kContactDetailsHeaderID)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 60.0
        tableView.noSeparatorsBelowFooter()
        
        if #available(iOS 11.0, *) {
            self.navigationItem.largeTitleDisplayMode = .never
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if loaded && self.viewModel.rebuild() {
            self.tableView.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.zeroMargin()
        var insets = self.tableView.contentInset
        insets.bottom = 100
        self.tableView.contentInset = insets
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == kEditContactSegue) {
            let contact = sender as! Contact
            let addContactViewController = segue.destination.childViewControllers[0] as! ContactEditViewController
            addContactViewController.delegate = self
            sharedVMService.contactEditViewModel(addContactViewController, contact: contact)
        } else if (segue.identifier == kToComposeSegue) {
            let composeViewController = segue.destination.childViewControllers[0] as! ComposeEmailViewController
            let contact = sender as? ContactVO
            sharedVMService.newDraftViewModelWithContact(composeViewController, contact: contact)
        } else if segue.identifier == kToUpgradeAlertSegue {
            let popup = segue.destination as! UpgradeAlertViewController
            self.setPresentationStyleForSelfController(self, presentingController: popup, style: .overFullScreen)
        }
    }
    
    @objc func didTapEditButton(sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: kEditContactSegue, sender: viewModel.getContact())
    }
    
    override func shouldShowSideMenu() -> Bool {
        return false
    }
}

extension ContactDetailViewController: ContactEditViewControllerDelegate {
    func deleted() {
        self.navigationController?.popViewController(animated: true)
    }
    func updated() {
        self.tableView.reloadData()
    }
}

extension ContactDetailViewController : ContactUpgradeCellDelegate {
    func upgrade() {
        self.performSegue(withIdentifier: self.kToUpgradeAlertSegue, sender: self)
    }
}



// MARK: - UITableViewDataSource
extension ContactDetailViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections().count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let s = viewModel.sections()[section]
        switch s {
        case .type2_warning:
            return viewModel.statusType2() ? 0 : 1
        case .type3_warning:
            if !viewModel.type3Error() {
                return viewModel.statusType3() ? 0 : 1
            }
            return 0
        case .type3_error:
            return viewModel.type3Error() ? 1 : 0
        case .debuginfo:
            return viewModel.debugging() ? 1 : 0
        case .emails:
            return viewModel.getEmails().count
        case .cellphone:
            return viewModel.getPhones().count
        case .home_address:
            return viewModel.getAddresses().count
        case .information:
            return viewModel.getInformations().count
        case .custom_field:
            return viewModel.getFields().count
        case .notes:
            return viewModel.getNotes().count
        case .url:
            return viewModel.getUrls().count
        case .display_name, .upgrade, .share:
            return 1
        case .email_header, .encrypted_header, .delete:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: kContactDetailsHeaderID) as? ContactSectionHeadView       
        let s = viewModel.sections()[section]
        switch s {
        case .email_header:
            let signed = viewModel.statusType2()
            cell?.ConfigHeader(title: NSLocalizedString("Contact Details", comment: "contact section title"), signed: signed)
        case .encrypted_header:
            let signed = viewModel.statusType3()
            cell?.ConfigHeader(title: NSLocalizedString("Encrypted Contact Details", comment: "contact section title"), signed: signed)
        default:
            cell?.ConfigHeader(title: "", signed: false)
        }
        return cell;
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let s = viewModel.sections()[section]
        switch s {
        case .email_header, .share:
            return 38.0
        case .encrypted_header:
            if viewModel.hasEncryptedContacts() {
                return 38.0
            } else {
                return 0
            }
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let section = indexPath.section
        let row = indexPath.row
        let s = viewModel.sections()[section]
        
        if s == .upgrade {
            let cell  = tableView.dequeueReusableCell(withIdentifier: kContactDetailsUpgradeCell, for: indexPath) as! ContactDetailsUpgradeCell
            cell.configCell(delegate: self)
            cell.selectionStyle = .none
            return cell
        } else if s == .share {
            let cell  = tableView.dequeueReusableCell(withIdentifier: kContactsDetailsShareCell, for: indexPath) as! ContactEditAddCell
            cell.configCell(value: NSLocalizedString("Share Contact", comment: "action"))
            cell.selectionStyle = .default
            return cell
        }
        
        if s == .type2_warning {
            let cell  = tableView.dequeueReusableCell(withIdentifier: kContactsDetailsWarningCell, for: indexPath) as! ContactsDetailsWarningCell
            cell.configCell(warning: .signatureWarning)
            cell.selectionStyle = .none
            return cell
        } else if s == .type3_error {
            let cell  = tableView.dequeueReusableCell(withIdentifier: kContactsDetailsWarningCell, for: indexPath) as! ContactsDetailsWarningCell
            cell.configCell(warning: .decryptionError)
            cell.selectionStyle = .none
            return cell
        } else if s == .type3_warning {
            let cell  = tableView.dequeueReusableCell(withIdentifier: kContactsDetailsWarningCell, for: indexPath) as! ContactsDetailsWarningCell
            cell.configCell(warning: .signatureWarning)
            cell.selectionStyle = .none
            return cell
        } else if s == .debuginfo {
            let cell  = tableView.dequeueReusableCell(withIdentifier: kContactsDetailsWarningCell, for: indexPath) as! ContactsDetailsWarningCell
            cell.configCell(forlog: self.viewModel.logs)
            cell.selectionStyle = .none
            return cell
        }
        
        let cell  = tableView.dequeueReusableCell(withIdentifier: kContactDetailsDisplayCell, for: indexPath) as! ContactDetailsDisplayCell
        cell.selectionStyle = .none
        switch s {
        case .display_name:
            let profile = viewModel.getProfile();
            cell.configCell(title: NSLocalizedString("Name", comment: "title"), value: profile.newDisplayName)
            cell.selectionStyle = .none
        case .emails:
            let emails = viewModel.getEmails()
            let email = emails[row]
            cell.configCell(title: email.newType.title, value: email.newEmail)
            cell.selectionStyle = .default
        case .cellphone:
            let cells = viewModel.getPhones()
            let tel = cells[row]
            cell.configCell(title: tel.newType.title, value: tel.newPhone)
            cell.selectionStyle = .default
        case .home_address:
            let addrs = viewModel.getAddresses()
            let addr = addrs[row]
            cell.configCell(title: addr.newType.title, value: addr.fullAddress())
            cell.selectionStyle = .default
        case .information:
            let infos = viewModel.getInformations()
            let info = infos[row]
            cell.configCell(title: info.infoType.title, value: info.newValue)
            cell.selectionStyle = .default
        case .custom_field:
            let fields = viewModel.getFields()
            let field = fields[row]
            cell.configCell(title: field.newType.title, value: field.newField)
            cell.selectionStyle = .default
        case .notes:
            let notes = viewModel.getNotes()
            let note = notes[row]
            cell.configCell(title: NSLocalizedString("Notes", comment: "title"), value: note.newNote)
            cell.selectionStyle = .default
        case .url:
            let urls = viewModel.getUrls()
            let url = urls[row]
            cell.configCell(title: url.newType.title, value: url.newUrl)
            cell.selectionStyle = .default
            
        case .email_header, .encrypted_header, .delete, .upgrade, .share,
             .type2_warning, .type3_error, .type3_warning, .debuginfo:
            break
        }
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ContactDetailViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        if (action == #selector(UIResponderStandardEditActions.copy(_:))) {
            return true
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        if (action == #selector(UIResponderStandardEditActions.copy(_:))) {
            var copyString = ""
            let section = indexPath.section
            let row = indexPath.row
            let s = viewModel.sections()[section]
            switch s {
            case .display_name:
                let profile = viewModel.getProfile();
                copyString = profile.newDisplayName
            case .emails:
                let emails = viewModel.getEmails()
                let email = emails[row]
                copyString = email.newEmail
            case .cellphone:
                let cells = viewModel.getPhones()
                let tel = cells[row]
                copyString = tel.newPhone
            case .home_address:
                let addrs = viewModel.getAddresses()
                let addr = addrs[row]
                copyString = addr.fullAddress()
            case .information:
                let infos = viewModel.getInformations()
                let info = infos[row]
                copyString = info.newValue
            case .custom_field:
                let fields = viewModel.getFields()
                let field = fields[row]
                copyString = field.newField
            case .notes:
                let notes = viewModel.getNotes()
                let note = notes[row]
                copyString = note.newNote
            case .url:
                let urls = viewModel.getUrls()
                let url = urls[row]
                copyString = url.newUrl
            default:
                break
            }
            
            UIPasteboard.general.string = copyString
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let s = viewModel.sections()[indexPath.section]
        switch s {
        case .display_name, .emails, .cellphone, .home_address,
             .information, .custom_field, .notes, .url,
             .type2_warning, .type3_error, .type3_warning, .debuginfo:
            return UITableViewAutomaticDimension
        case .email_header, .encrypted_header, .delete:
            return 0.0
        case .upgrade:
            return 200 //  280.0
        case .share:
            return 38.0
        }
    }
    
    func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let section = indexPath.section
        let row = indexPath.row
        let s = viewModel.sections()[section]
        switch s {
        case .emails:
            let emails = viewModel.getEmails()
            let email = emails[row]
            let contact = viewModel.getContact()
            let contactVO = ContactVO(id: contact.contactID,
                                      name: contact.name,
                                      email: email.newEmail,
                                      isProtonMailContact: false)
            self.performSegue(withIdentifier: kToComposeSegue, sender: contactVO)
        case .encrypted_header:
            break
        case .cellphone:
            //TODO::bring up the phone call
            break
        case .home_address:
            let addrs = viewModel.getAddresses()
            let addr = addrs[row]
            let fulladdr = addr.fullAddress()
            if !fulladdr.isEmpty {
                let fullUrl = "http://maps.apple.com/?q=\(fulladdr)"
                if let strUrl = fullUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                    let url = URL(string: strUrl) {
                    UIApplication.shared.openURL(url)
                }
            }
        case .share:
            
            let exported = viewModel.export()
            if !exported.isEmpty {
                let filename = viewModel.exportName()
                let tempFileUri = FileManager.default.attachmentDirectory.appendingPathComponent(filename)
                
                try? exported.write(to: tempFileUri, atomically: true, encoding: String.Encoding.utf8)
                
                // set up activity view controller
                let urlToShare = [ tempFileUri ]
                let activityViewController = UIActivityViewController(activityItems: urlToShare, applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
                
                // exclude some activity types from the list (optional)
                activityViewController.excludedActivityTypes = [ .postToFacebook,
                                                                 .postToTwitter,
                                                                 .postToWeibo,
                                                                 .copyToPasteboard,
                                                                 .saveToCameraRoll,
                                                                 .addToReadingList,
                                                                 .postToFlickr,
                                                                 .postToVimeo,
                                                                 .postToTencentWeibo,
                                                                 .assignToContact]
                if #available(iOS 11.0, *) {
                    activityViewController.excludedActivityTypes?.append(.markupAsPDF)
                    activityViewController.excludedActivityTypes?.append(.openInIBooks)
                }
                self.present(activityViewController, animated: true, completion: nil)
            }
            
        default:
            break
        }
    }
}

