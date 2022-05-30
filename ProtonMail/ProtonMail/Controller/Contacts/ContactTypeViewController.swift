//
//  ContactTypeViewController.swift
//  Proton Mail - Created on 5/4/17.
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

import ProtonCore_UIFoundations
import UIKit

protocol ContactTypeViewControllerDelegate: AnyObject {
    func done(sectionType: ContactEditSectionType)
}

class ContactTypeViewController: UIViewController {
    private let viewModel: ContactTypeViewModel
    weak var delegate: ContactTypeViewControllerDelegate?
    private var tableView: UITableView?
    private var tableViewBottomOffset: NSLayoutConstraint?

    var activeText: UITextField?

    init(viewModel: ContactTypeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        setupTableView()
    }

    private func setupTableView() {
        let newView = UITableView(frame: .zero)
        newView.delegate = self
        newView.dataSource = self

        newView.register(UITableViewCell.self, forCellReuseIdentifier: "ContactTypeCell")
        newView.register(UINib(nibName: "ContactTypeAddCustomCell", bundle: nil), forCellReuseIdentifier: "ContactTypeAddCustomCell")

        view.addSubview(newView)
        [
            newView.topAnchor.constraint(equalTo: view.topAnchor),
            newView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            newView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ].activate()
        tableViewBottomOffset = newView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        tableViewBottomOffset?.isActive = true
        tableView = newView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addKeyboardObserver(self)

        let type = viewModel.getPickedType()
        let types = viewModel.getDefinedTypes()

        if let index = types.firstIndex(where: { left -> Bool in left.rawString == type.rawString }) {
            let indexPath = IndexPath(row: index, section: 0)
            tableView?.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            updateSelection(selectedIndexPath: indexPath)
        } else {
            let custom = viewModel.getCustomType()
            if !custom.isEmpty {
                let indexPath = IndexPath(row: 0, section: 1)
                tableView?.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                updateSelection(selectedIndexPath: indexPath)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeKeyboardObserver(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView?.zeroMargin()
    }

    private func selectAndGoBack(at index: IndexPath) {
        var type: ContactFieldType = .empty
        if index.section == 0 {
            let types = viewModel.getDefinedTypes()
            type = types[index.row]
        } else if index.section == 1 {
            if let cell = tableView?.cellForRow(at: index) {
                if let addCell = cell as? ContactTypeAddCustomCell {
                    type = ContactFieldType.get(raw: addCell.getValue())
                } else {
                    type = ContactFieldType.get(raw: cell.textLabel?.text ?? LocalString._contacts_custom_type)
                }
            } else {
                type = ContactFieldType.get(raw: LocalString._contacts_custom_type)
            }
        }
        viewModel.updateType(t: type)
        delegate?.done(sectionType: viewModel.getSectionType())
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol

extension ContactTypeViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        tableViewBottomOffset?.constant = 0.0
        UIView.animate(withDuration: keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () in
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    func keyboardWillShowNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        let info: NSDictionary = notification.userInfo! as NSDictionary
        if let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            tableViewBottomOffset?.constant = keyboardSize.height
        }
        UIView.animate(withDuration: keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () in
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
}

extension ContactTypeViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeText = textField
    }
}

// MARK: - UITableViewDataSource

extension ContactTypeViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            let l = viewModel.getDefinedTypes()
            return l.count
        }
        let custom = viewModel.getCustomType()
        if !custom.isEmpty {
            return 1
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        let isSelected = indexPath == viewModel.getSelectedIndexPath()
        if section == 0 {
            let outCell = tableView.dequeueReusableCell(withIdentifier: "ContactTypeCell", for: indexPath)
            outCell.backgroundColor = ColorProvider.BackgroundNorm
            outCell.textLabel?.textColor = ColorProvider.TextNorm
            outCell.selectionStyle = .default
            let l = viewModel.getDefinedTypes()
            outCell.textLabel?.text = l[indexPath.row].title
            outCell.accessoryType = isSelected ? .checkmark : .none
            return outCell
        } else {
            if row == 0 {
                let outCell = tableView.dequeueReusableCell(withIdentifier: "ContactTypeCell", for: indexPath)
                outCell.backgroundColor = ColorProvider.BackgroundNorm
                outCell.textLabel?.textColor = ColorProvider.TextNorm
                outCell.selectionStyle = .default
                outCell.selectionStyle = .default
                let text = viewModel.getCustomType()
                outCell.textLabel?.text = text.title
                outCell.accessoryType = isSelected ? .checkmark : .none
                return outCell
            }
        }
        return UITableViewCell()
    }
}

// MARK: - UITableViewDelegate

extension ContactTypeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }

    func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        updateSelection(selectedIndexPath: indexPath)
        selectAndGoBack(at: indexPath)
    }
}

extension ContactTypeViewController {
    private func updateSelection(selectedIndexPath: IndexPath) {
        let indexPaths = tableView?.indexPathsForVisibleRows ?? []
        for index in indexPaths {
            if let cell = tableView?.cellForRow(at: index) {
                if let addCell = cell as? ContactTypeAddCustomCell {
                    addCell.unsetMark()
                }
                cell.accessoryType = .none
            }
        }
        if let cell = tableView?.cellForRow(at: selectedIndexPath) {
            if let addCell = cell as? ContactTypeAddCustomCell {
                addCell.setMark()
            }
            cell.accessoryType = .checkmark
        }
        tableView?.deselectRow(at: selectedIndexPath, animated: true)
    }
}
