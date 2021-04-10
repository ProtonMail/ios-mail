//
//  CountryPickerViewController.swift
//  ProtonMail - Created on 12.03.21.
//
//  Copyright (c) 2021 Proton Technologies AG
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
//

import UIKit

public protocol CountryPickerViewControllerDelegate: class {
    func didCountryPickerClose()
    func didSelectCountryCode(countryCode: CountryCode)
}

public class CountryPickerViewController: UIViewController {

    // MARK: Outlets

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var tableBottomConstraint: NSLayoutConstraint!

    private let contryCodeCell = "country_code_table_cell"
    private let countryCodeHeader = "CountryCodeTableHeaderView"
    public weak var delegate: CountryPickerViewControllerDelegate?
    var viewModel: CountryCodeViewModel! { didSet { viewModel.searchText() } }

    // MARK: View controller life cycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setupNotifications()
    }

    deinit {
       NotificationCenter.default.removeObserver(self)
    }

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    // MARK: Actions

    @IBAction func cancelAction(_ sender: UIButton) {
        delegate?.didCountryPickerClose()
        dismiss(animated: true, completion: nil)
    }

    @IBAction func tapAction(_ sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }

    // MARK: Private interface

    private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func configureUI() {
        cancelButton.tintColor = UIColorManager.IconNorm
        contentView.layer.cornerRadius = 4
        searchBar.placeholder = viewModel.getSearchBarPlaceholderText()
        searchBar.delegate = self
        contentView.backgroundColor = UIColorManager.BackgroundNorm
        tableView.backgroundColor = UIColorManager.BackgroundNorm

        let nib = UINib(nibName: countryCodeHeader, bundle: PMUIFoundations.bundle)
        tableView.register(nib, forHeaderFooterViewReuseIdentifier: countryCodeHeader)
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(adjustKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

// MARK: - UITableViewDataSource

extension CountryPickerViewController: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sectionNames.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getCountryCodes(section: section).count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let countryCell = tableView.dequeueReusableCell(withIdentifier: contryCodeCell, for: indexPath) as! CountryCodeTableViewCell
        if let country = viewModel.getCountryCode(indexPath: indexPath) {
            countryCell.configCell(country)
        }
        return countryCell
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: countryCodeHeader)
        if let header = cell as? CountryCodeTableHeaderView {
            header.titleLabel.text = viewModel.sectionNames[section]
        }
        return cell
    }

    public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return viewModel.sectionNames
    }

}

// MARK: - UITableViewDelegate

extension CountryPickerViewController: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 32.0
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48.0
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let countryCode = viewModel.getCountryCode(indexPath: indexPath) {
            delegate?.didSelectCountryCode(countryCode: countryCode)
        }
        dismiss(animated: true, completion: nil)
    }

}

// MARK: - UISearchBarDelegate

extension CountryPickerViewController: UISearchBarDelegate {
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchText(searchText: searchText)
        tableView.reloadData()
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        dismissKeyboard()
    }
}

// MARK: - Keyboard observer

extension CountryPickerViewController {
    @objc private func adjustKeyboard(notification: NSNotification) {
        switch notification.name {
        case UIResponder.keyboardWillShowNotification:
            guard let keyboardFrame = notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
                tableBottomConstraint.constant = 0
                return
            }
            tableBottomConstraint.constant = self.view?.convert(keyboardFrame.cgRectValue, from: nil).size.height ?? 0
        case UIResponder.keyboardWillHideNotification:
            tableBottomConstraint.constant = 0
        default:
            break
        }
    }
}
