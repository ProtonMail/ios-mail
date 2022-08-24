//
//  ContactGroupEditViewController.swift
//  Proton Mail
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

import MBProgressHUD
import PromiseKit
import ProtonCore_Foundations
import ProtonCore_UIFoundations
import UIKit

final class ContactGroupEditViewController: UIViewController, AccessibleView {
    enum ID {
        static var contactGroupEditCell = "ContactGroupEditCell"
        static var contactGroupManageCell = "ContactGroupManageCell"
        static var contactGroupDeleteCell = "ContactGroupDeleteCell"
    }

    @IBOutlet var contactGroupNameInstructionLabel: UILabel!
    @IBOutlet var contactGroupNameLabel: UITextField!
    @IBOutlet var contactGroupImage: UIImageView!

    private var cancelButton: UIBarButtonItem!
    private var doneButton: UIBarButtonItem!

    @IBOutlet var headerContainerView: UIView!

    @IBOutlet var changeColorButton: UIButton!
    @IBOutlet var tableView: UITableView!

    var viewModel: ContactGroupEditViewModel!
    var activeText: UIResponder?

    init(viewModel: ContactGroupEditViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "ContactGroupEditViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissKeyboard()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(viewModel != nil)

        tableView.separatorStyle = .none
        tableView.register(UINib(nibName: "ContactGroupEditViewCell", bundle: Bundle.main),
                           forCellReuseIdentifier: ID.contactGroupEditCell)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: ID.contactGroupDeleteCell)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: ID.contactGroupManageCell)

        viewModel?.delegate = self
        contactGroupNameLabel.delegate = self

        loadDataIntoView()
        tableView.noSeparatorsBelowFooter()

        prepareContactGroupImage()

        doneButton = UIBarButtonItem(title: LocalString._general_done_button,
                                     style: .plain,
                                     target: self, action: #selector(saveAction(_:)))
        let attributes = FontManager.DefaultStrong.foregroundColor(ColorProvider.InteractionNorm)
        doneButton.setTitleTextAttributes(attributes, for: .normal)
        navigationItem.rightBarButtonItem = doneButton

        setupStyle()

        if let viewModel = viewModel as? ContactGroupEditViewModelImpl, viewModel.state == .create {
            doneButton.title = LocalString._general_save_action
        }

        cancelButton = IconProvider.cross.toUIBarButtonItem(target: self,
                                                            action: #selector(self.cancelItem(_:)),
                                                            tintColor: ColorProvider.IconNorm)
        navigationItem.leftBarButtonItem = cancelButton

        contactGroupNameLabel.addBottomBorder()

        emptyBackButtonTitleForNextView()
        generateAccessibilityIdentifiers()
    }

    private func prepareContactGroupImage() {
        contactGroupImage.image = UIImage(named: "contact_groups_icon")
        contactGroupImage.setupImage(tintColor: UIColor.white,
                                     backgroundColor: UIColor(hexString: viewModel.getColor(),
                                                              alpha: 1))
    }

    private func loadDataIntoView() {
        self.title = viewModel.getViewTitle()
        contactGroupNameLabel.text = viewModel.getName()
        contactGroupImage.backgroundColor = UIColor(hexString: viewModel.getColor(),
                                                    alpha: 1.0)
        tableView.reloadData()
    }

    @IBAction private func cancelItem(_ sender: UIBarButtonItem) {
        dismissKeyboard()

        if viewModel.hasUnsavedChanges() {
            let alertController = UIAlertController(title: LocalString._warning,
                                                    message: LocalString._changes_will_discarded,
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: LocalString._general_discard, style: .destructive, handler: { [weak self] _ in
                self?.dismiss(animated: true, completion: nil)
            }))
            present(alertController, animated: true, completion: nil)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    @IBAction private func changeColorTapped(_ sender: UIButton) {
        let refreshHandler = { [weak self] (newColor: String) -> Void in
            self?.viewModel.setColor(newColor: newColor)
        }

        let viewModel = ContactGroupSelectColorViewModelImpl(currentColor: viewModel.getColor(),
                                                             refreshHandler: refreshHandler)
        let newView = ContactGroupSelectColorViewController(viewModel: viewModel)
        show(newView, sender: nil)
    }

    @IBAction private func saveAction(_ sender: UIBarButtonItem) {
        dismissKeyboard()
        save()
    }

    private func setupStyle() {
        view.backgroundColor = ColorProvider.BackgroundNorm
        tableView.backgroundColor = ColorProvider.BackgroundNorm
        headerContainerView.backgroundColor = ColorProvider.BackgroundNorm
        changeColorButton.setTitleColor(ColorProvider.TextHint, for: .normal)
        contactGroupNameInstructionLabel.attributedText = LocalString._contact_groups_group_name_instruction_label.apply(style: .DefaultWeak)
        contactGroupNameLabel.textColor = ColorProvider.TextNorm
    }

    private func dismissKeyboard() {
        if let t = activeText {
            t.resignFirstResponder()
            activeText = nil
        }
    }

    private func dismiss(message: String? = nil) {
        let isOffline = !isOnline
        if presentingViewController != nil {
            dismiss(animated: true) {
                if isOffline {
                    message?.alertToastBottom()
                }
            }
        } else {
            _ = navigationController?.popViewController(animated: true)
        }
    }

    private func save() {
        firstly { () -> Promise<Void> in
            MBProgressHUD.showAdded(to: self.view, animated: true)
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            return viewModel.saveDetail()
        }.done {
            self.dismiss(message: LocalString._contacts_saved_offline_hint)
        }.ensure {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            MBProgressHUD.hide(for: self.view, animated: true)
        }.catch {
            error in
            error.alert(at: self.view)
        }
    }

    private func presentEmailSelectView() {
        let refreshHandler = { [weak self] (emailIDs: Set<EmailEntity>) -> Void in
            self?.viewModel.setEmails(emails: emailIDs)
        }

        let viewModel = ContactGroupSelectEmailViewModelImpl(selectedEmails: viewModel.getEmails(),
                                                             contactService: viewModel.user.contactService,
                                                             refreshHandler: refreshHandler)

        let newView = ContactGroupSelectEmailViewController(viewModel: viewModel)
        show(newView, sender: nil)
    }
}

extension ContactGroupEditViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.getTotalSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getTotalRows(for: section)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.getSectionTitle(for: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch viewModel.getCellType(at: indexPath) {
        case .manageContact:
            let cell = tableView.dequeueReusableCell(withIdentifier: ID.contactGroupManageCell, for: indexPath)
            cell.textLabel?.attributedText = LocalString._contact_groups_manage_addresses.apply(style: FontManager.Default.foregroundColor(ColorProvider.InteractionNorm))
            cell.addSeparator(padding: 0)
            return cell
        case .email:
            let cell = tableView.dequeueReusableCell(withIdentifier: ID.contactGroupEditCell,
                                                     for: indexPath) as! ContactGroupEditViewCell

            let (emailID, name, email) = viewModel.getEmail(at: indexPath)
            cell.config(emailID: emailID,
                        name: name,
                        email: email,
                        queryString: "",
                        state: .editView,
                        viewModel: viewModel)
            cell.addSeparator(padding: 0)
            return cell
        case .deleteGroup, .error: // TODO: fix this .error state
            let cell = tableView.dequeueReusableCell(withIdentifier: ID.contactGroupDeleteCell, for: indexPath) as UITableViewCell
            cell.textLabel?.text = LocalString._contact_groups_delete
            cell.addSeparator(padding: 0)
            cell.textLabel?.textColor = ColorProvider.NotificationError
            return cell
        }
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let titleView = view as? UITableViewHeaderFooterView {
            titleView.textLabel?.text = titleView.textLabel?.text?.capitalized
        }
    }
}

extension ContactGroupEditViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch viewModel.getCellType(at: indexPath) {
        case .manageContact:
            presentEmailSelectView()
        case .email:
            break
        case .deleteGroup:
            let deleteActionHandler = { ( _: UIAlertAction) -> Void in
                    firstly {
                        () -> Promise<Void> in
                            MBProgressHUD.showAdded(to: self.view, animated: true)
                            UIApplication.shared.isNetworkActivityIndicatorVisible = true
                            return self.viewModel.deleteContactGroup()
                    }.done {
                        self.dismiss(message: LocalString._contacts_deleted_offline_hint)
                    }.ensure {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        MBProgressHUD.hide(for: self.view, animated: true)
                    }.catch {
                        error in
                        error.alert(at: self.view)
                    }
            }

            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button,
                                                    style: .cancel,
                                                    handler: nil))
            alertController.addAction(UIAlertAction(title: LocalString._contact_groups_delete,
                                                    style: .destructive,
                                                    handler: deleteActionHandler))
            let sender = tableView.cellForRow(at: indexPath)
            alertController.popoverPresentationController?.sourceView = self.tableView
            alertController.popoverPresentationController?.sourceRect = (sender == nil ? view.frame : sender!.frame)

            present(alertController, animated: true, completion: nil)
        case .error:
            break
        }
    }
}

extension ContactGroupEditViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeText = textField
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        contactGroupNameLabel.text = textField.text
        viewModel.setName(name: textField.text ?? "")

        activeText = nil
    }
}

extension ContactGroupEditViewController: ContactGroupEditViewControllerDelegate {
    func update() {
        loadDataIntoView()
    }

    func updateAddressSection() {
        tableView.reloadData()
    }
}
