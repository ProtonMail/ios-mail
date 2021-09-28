//
//  SettingsEncryptedSearchViewController.swift
//  ProtonMail - Created on 2021/7/1.
//
//
//  Copyright © 2021 ProtonMail. All rights reserved.
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

import ProtonCore_UIFoundations
import UIKit

class SettingsEncryptedSearchViewController: ProtonMailTableViewController, ViewModelProtocol, CoordinatedNew {
    internal var viewModel: SettingsEncryptedSearchViewModel!
    internal var coordinator: SettingsDeviceCoordinator?
    
    internal let deleteSearchIndexButton = UIButton(type: UIButton.ButtonType.system) as UIButton
    internal let pauseIndexingButton = UIButton(type: UIButton.ButtonType.system) as UIButton
    internal var progressView: UIProgressView!
    
    internal var hideSections: Bool = true
    
    struct Key {
        static let cellHeight: CGFloat = 48.0
        static let footerHeight : CGFloat = 48.0
        static let headerCell: String = "header_cell"
    }
    
    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        if self.viewModel.isEncryptedSearch {
            self.hideSections = false
        } else {
            self.hideSections = true
        }
        
        self.updateTitle()
        self.view.backgroundColor = UIColorManager.BackgroundSecondary
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: Key.headerCell)
        self.tableView.register(SwitchTableViewCell.self)
        self.tableView.register(ProgressBarButtonTableViewCell.self)
        
        self.tableView.estimatedSectionFooterHeight = Key.footerHeight
        self.tableView.sectionFooterHeight = UITableView.automaticDimension
        
        self.tableView.estimatedRowHeight = Key.cellHeight
        //self.tableView.estimatedRowHeight = 100
        self.tableView.rowHeight = UITableView.automaticDimension
        
        self.deleteSearchIndexButton.frame = CGRect(x: 50, y: 100, width: 150, height: 45)
        self.deleteSearchIndexButton.backgroundColor = UIColor.lightGray
        self.deleteSearchIndexButton.setTitle("delete searchindex", for: UIControl.State.normal)
        self.deleteSearchIndexButton.tintColor = UIColor.black
        self.deleteSearchIndexButton.addTarget(self, action: #selector(self.deleteSearchIndex), for: .touchUpInside)
        self.deleteSearchIndexButton.isHidden = true
        self.deleteSearchIndexButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.deleteSearchIndexButton)
        let deleteSearchIndexButtonCenterXAnchor = self.deleteSearchIndexButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)
        deleteSearchIndexButtonCenterXAnchor.isActive = true
        let deleteSearchIndexButtonWidthAnchor = self.deleteSearchIndexButton.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.9)
        deleteSearchIndexButtonWidthAnchor.isActive = true
        let tAnchor = self.deleteSearchIndexButton.topAnchor.constraint(equalTo: self.tableView.bottomAnchor, constant: 400)
        tAnchor.isActive = true
        
        self.pauseIndexingButton.frame = CGRect(x: 50, y: 100, width: 150, height: 45)
        self.pauseIndexingButton.backgroundColor = UIColor.lightGray
        self.pauseIndexingButton.setTitle("Pause", for: UIControl.State.normal)
        self.pauseIndexingButton.tintColor = UIColor.black
        self.pauseIndexingButton.addTarget(self, action: #selector(self.pauseIndexing), for: .touchUpInside)
        self.pauseIndexingButton.isHidden = true
        self.pauseIndexingButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.pauseIndexingButton)
        let pauseIndexingButtonXAnchor = self.pauseIndexingButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)
        pauseIndexingButtonXAnchor.isActive = true
        let pauseIndexingButtonWidthAnchor = self.pauseIndexingButton.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.9)
        pauseIndexingButtonWidthAnchor.isActive = true
        let pauseIndexingButtonTopAnchor = self.pauseIndexingButton.topAnchor.constraint(equalTo: self.deleteSearchIndexButton.bottomAnchor, constant: 25)
        pauseIndexingButtonTopAnchor.isActive = true
        
        //initialize progress view
        self.progressView = UIProgressView()
        self.progressView.isHidden = true
        self.progressView.progress = 0  //initial value
        self.progressView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.progressView)
        let centerXAnchor = self.progressView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)
        centerXAnchor.isActive = true
        let widthAnchor = self.progressView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.9)
        widthAnchor.isActive = true
        let topAnchor = self.progressView.topAnchor.constraint(equalTo: self.deleteSearchIndexButton.bottomAnchor, constant: 100)
        topAnchor.isActive = true
        
        setupProgressViewObserver()
        setupEstimatedTimeUpdateObserver()
        setupProgressUpdateObserver()
    }
    
    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }
    
    func set(coordinator: SettingsDeviceCoordinator) {
        self.coordinator = coordinator
    }
    
    func set(viewModel: SettingsEncryptedSearchViewModel) {
        self.viewModel = viewModel
    }
    
    private func updateTitle(){
        self.title = LocalString._encrypted_search
    }
}

extension SettingsEncryptedSearchViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section > 0 && self.hideSections {
            return 0
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = indexPath.section
        
        let eSection = self.viewModel.sections[section]
        switch eSection {
        case .encryptedSearch:
            return Key.cellHeight
        case .downloadViaMobileData:
            return Key.cellHeight
        case .downloadedMessages:
            return 100.0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section > 0 && self.hideSections {
            return CGFloat.leastNormalMagnitude
        }
        return super.tableView(tableView, heightForHeaderInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section > 0 && self.hideSections {
            return CGFloat.leastNormalMagnitude
        }
        return Key.footerHeight//super.tableView(tableView, heightForFooterInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let section = indexPath.section
        
        let eSection = self.viewModel.sections[section]
        switch eSection {
        case .encryptedSearch:
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.CellID, for: indexPath)
            if let switchCell = cell as? SwitchTableViewCell {
                switchCell.configCell(eSection.title, bottomLine: "", status: viewModel.isEncryptedSearch) {
                    _, _, _ in
                    let status = self.viewModel.isEncryptedSearch
                    self.viewModel.isEncryptedSearch = !status
                    
                    //If cell is active -> start building a search index
                    if self.viewModel.isEncryptedSearch {
                        //show alert
                        self.showAlertContentSearchEnabled(for: indexPath, cell: switchCell)
                    } else {
                        //hide sections
                        self.hideSections = true
                    }
                }
            }
            return cell
        case .downloadViaMobileData:
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.CellID, for: indexPath)
            if let switchCell = cell as? SwitchTableViewCell {
                switchCell.configCell(eSection.title, bottomLine: "", status: viewModel.downloadViaMobileData) { _, _, _ in
                    //TODO code here for enableing download via mobile data
                }
            }
            return cell
        case .downloadedMessages:
            let cell = tableView.dequeueReusableCell(withIdentifier: ProgressBarButtonTableViewCell.CellID, for: indexPath)
            if let progressBarButtonCell = cell as? ProgressBarButtonTableViewCell {
                progressBarButtonCell.configCell("Downloading messages...", self.viewModel.estimatedTimeRemaining.value!, self.viewModel.currentProgress.value!, "Pause", "Resume") { _, _, _ in
                    //TODO code here for pause button
                }
            }
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: Key.headerCell)
        header?.contentView.subviews.forEach { $0.removeFromSuperview() }
        header?.contentView.backgroundColor = UIColorManager.BackgroundSecondary

        if let headerCell = header {
            let textLabel = UILabel()
            textLabel.numberOfLines = 0
            textLabel.translatesAutoresizingMaskIntoConstraints = false

            let eSection = self.viewModel.sections[section]
            textLabel.attributedText = NSAttributedString(string: eSection.foot, attributes: FontManager.CaptionWeak)

            headerCell.contentView.addSubview(textLabel)

            NSLayoutConstraint.activate([
                textLabel.topAnchor.constraint(equalTo: headerCell.contentView.topAnchor, constant: 8),
                textLabel.bottomAnchor.constraint(equalTo: headerCell.contentView.bottomAnchor, constant: -8),
                textLabel.leadingAnchor.constraint(equalTo: headerCell.contentView.leadingAnchor, constant: 16),
                textLabel.trailingAnchor.constraint(equalTo: headerCell.contentView.trailingAnchor, constant: -16)
            ])
        }
        return header
    }
    
    func showAlertContentSearchEnabled(for index: IndexPath, cell: SwitchTableViewCell) {
        //create the alert
        let alert = UIAlertController(title: "Enable content search", message: "Messages will download via WiFi. This could take some time and your device may heat up slightly.\n You can pause the action at any time.", preferredStyle: UIAlertController.Style.alert)
        //add the buttons
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel){ (action:UIAlertAction!) in
            self.viewModel.isEncryptedSearch = false
            self.tableView.reloadData() //refresh the view after
        })
        alert.addAction(UIAlertAction(title: "Enable", style: UIAlertAction.Style.default){ (action:UIAlertAction!) in
            //change UI
            self.progressView.isHidden = false
            self.deleteSearchIndexButton.isHidden = false
            self.pauseIndexingButton.isHidden = false
            self.hideSections = false

            self.tableView.reloadData() //refresh the view to show changes in UI

            //build search index
            EncryptedSearchService.shared.buildSearchIndex(self.viewModel)
        })
        
        //show alert
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func deleteSearchIndex(_ sender: UIButton!){
        EncryptedSearchService.shared.deleteSearchIndex()
        self.viewModel.isEncryptedSearch = false //set toggle button to false
        self.progressView.isHidden = true //hide progress bar
        self.progressView.progress = 0 //reset value of progress bar
        self.deleteSearchIndexButton.isHidden = true
        self.pauseIndexingButton.isHidden = true
        self.hideSections = true
        self.tableView.reloadData() //refresh the view after
    }
    
    @objc func pauseIndexing(_ sender: UIButton!) {
        self.viewModel.pauseIndexing.toggle()
        //set text on button
        if self.viewModel.pauseIndexing {
            self.pauseIndexingButton.setTitle("Resume", for: .normal)
        } else {
            self.pauseIndexingButton.setTitle("Pause", for: .normal)
        }
        EncryptedSearchService.shared.pauseAndResumeIndexing()
    }
        
    func setupProgressViewObserver() {
        self.viewModel.progressViewStatus.bind { [weak self] (_) in
            DispatchQueue.main.async {
                self?.progressView.setProgress((self?.viewModel.progressViewStatus.value)!, animated: true)
            }
        }
    }
    
    func setupEstimatedTimeUpdateObserver() {
        self.viewModel.estimatedTimeRemaining.bind { (_) in
            DispatchQueue.main.async {
                let path: IndexPath = IndexPath.init(row: 0, section: SettingsEncryptedSearchViewModel.SettingSection.downloadedMessages.rawValue)

                UIView.performWithoutAnimation {
                    self.tableView.reloadRows(at: [path], with: .none)
                }
            }
        }
    }
    
    func setupProgressUpdateObserver() {
        self.viewModel.currentProgress.bind { (_) in
            DispatchQueue.main.async {
                let path: IndexPath = IndexPath.init(row: 0, section: SettingsEncryptedSearchViewModel.SettingSection.downloadedMessages.rawValue)

                UIView.performWithoutAnimation {
                    self.tableView.reloadRows(at: [path], with: .none)
                }
            }
        }
    }
}
