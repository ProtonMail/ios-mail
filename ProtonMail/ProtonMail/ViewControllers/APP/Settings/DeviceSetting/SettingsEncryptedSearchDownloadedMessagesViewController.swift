// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import ProtonCore_UIFoundations
import UIKit

class SettingsEncryptedSearchDownloadedMessagesViewController: ProtonMailTableViewController, ViewModelProtocol, CoordinatedNew {
    internal var viewModel: SettingsEncryptedSearchDownloadedMessagesViewModel!
    internal var coordinator: SettingsDeviceCoordinator?
    
    private lazy var fileByteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = .useAll//[.useMB, .useGB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter
    }()
    
    struct Key  {
        static let cellHeightMessageHistoryComplete: CGFloat = 108.0
        static let cellHeightMessageHistoryPartial: CGFloat = 128.0
        static let cellHeightStorageLimit: CGFloat = 116.0
        static let cellHeightStorageUsage: CGFloat = 96.0
        static let footerHeight: CGFloat = 70.0
        static let headerHeightFirstCell: CGFloat = 32.0
        static let headerHeight: CGFloat = 8.0
        static let headerCell: String = "header_cell"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.updateTitle()

        self.view.backgroundColor = ColorProvider.BackgroundSecondary
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: Key.headerCell)
        self.tableView.register(ThreeLinesTableViewCell.self)
        self.tableView.register(ButtonTableViewCell.self)
        self.tableView.register(SliderTableViewCell.self)

        self.tableView.estimatedSectionFooterHeight = Key.footerHeight
        self.tableView.sectionFooterHeight = Key.footerHeight
        self.tableView.estimatedRowHeight = Key.cellHeightMessageHistoryComplete
        self.tableView.rowHeight = UITableView.automaticDimension
        
        self.tableView.allowsSelection = false  //disable rows to be clickable
    }

    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }

    func set(coordinator: SettingsDeviceCoordinator) {
        self.coordinator = coordinator
    }

    func set(viewModel: SettingsEncryptedSearchDownloadedMessagesViewModel) {
        self.viewModel = viewModel
    }

    private func updateTitle() {
        self.title = LocalString._encrypted_search_downloaded_messages
    }
}

extension SettingsEncryptedSearchDownloadedMessagesViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return Key.headerHeightFirstCell
        }
        return Key.headerHeight
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = ColorProvider.BackgroundSecondary
        headerView.translatesAutoresizingMaskIntoConstraints = false

        if section == 0 {
            NSLayoutConstraint.activate([
                headerView.heightAnchor.constraint(equalToConstant: Key.headerHeightFirstCell)
            ])
        } else {
            NSLayoutConstraint.activate([
                headerView.heightAnchor.constraint(equalToConstant: Key.headerHeight)
            ])
        }

        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 2 {
            return Key.footerHeight
        }
        return CGFloat.leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = indexPath.section

        let eSection = self.viewModel.sections[section]
        switch eSection {
        case .messageHistory:
            let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
            let userID: String = (usersManager.firstUser?.userInfo.userId)!
            if EncryptedSearchService.shared.getESState(userID: userID) == .partial {
                return Key.cellHeightMessageHistoryPartial
            } else {
                return Key.cellHeightMessageHistoryComplete
            }
        case .storageLimit:
            return Key.cellHeightStorageLimit
        case .storageUsage:
            return Key.cellHeightStorageUsage
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let section = indexPath.section
        let eSection = self.viewModel.sections[section]
        switch eSection {
        case .messageHistory:
            let cell = tableView.dequeueReusableCell(withIdentifier: ThreeLinesTableViewCell.CellID, for: indexPath)
            if let threeLineCell = cell as? ThreeLinesTableViewCell {
                let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
                if let userID: String = usersManager.firstUser?.userInfo.userId {

                    // If the user has 0 messages - don't show oldest message
                    if userCachedStatus.encryptedSearchTotalMessages == 0 {
                        threeLineCell.middleLabel.isHidden = true
                    }

                    if EncryptedSearchService.shared.getESState(userID: userID) == .lowstorage {
                        // Create attributed string for oldest message in search index
                        let oldestMessageString: String = EncryptedSearchIndexService.shared.getOldestMessageInSearchIndex(for: userID)
                        let oldestMessageFullString: String = LocalString._encrypted_search_downloaded_messages_oldest_message + oldestMessageString
                        let oldestMessageAttributedString = NSMutableAttributedString(string: oldestMessageFullString)
                        let rangeOldestMessage = NSRange(location: LocalString._encrypted_search_downloaded_messages_oldest_message.count, length: oldestMessageString.count)
                        oldestMessageAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: ColorProvider.NotificationError, range: rangeOldestMessage)

                        // Create icon
                        let image: UIImage = UIImage(named: "ic-exclamation-circle")!
                        let tintableImage = image.withRenderingMode(.alwaysTemplate)
                        threeLineCell.icon.tintColor = ColorProvider.NotificationError

                        // Create attributed string for download status
                        let downloadStatus = NSMutableAttributedString(string: LocalString._settings_message_history_status_low_storage)
                        let rangeDownloadStatus = NSRange(location: 0, length: LocalString._settings_message_history_status_low_storage.count)
                        downloadStatus.addAttribute(NSAttributedString.Key.foregroundColor, value: ColorProvider.NotificationError, range: rangeDownloadStatus)

                        // Config cell
                        threeLineCell.configCell(eSection.title, oldestMessageAttributedString, downloadStatus, tintableImage)
                    } else {
                        // Create attributed string for oldest message in search index
                        let oldestMessageString: String = EncryptedSearchIndexService.shared.getOldestMessageInSearchIndex(for: userID)
                        let oldestMessageFullString: String = LocalString._encrypted_search_downloaded_messages_oldest_message + oldestMessageString
                        let oldestMessageAttributedString = NSMutableAttributedString(string: oldestMessageFullString)

                        // Create icon
                        let image: UIImage = UIImage(named: "contact_groups_check")!
                        let tintableImage = image.withRenderingMode(.alwaysTemplate)
                        threeLineCell.icon.tintColor = ColorProvider.NotificationSuccess

                        let expectedESStates: [EncryptedSearchService.EncryptedSearchIndexState] = [.complete, .partial]
                        var downloadStatus = NSMutableAttributedString(string: "")
                        let numberOfMessagesInSearchIndex: Int = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: userID)
                        if userCachedStatus.encryptedSearchTotalMessages == 0 {
                            downloadStatus = NSMutableAttributedString(string: LocalString._settings_message_history_status_no_messages)
                        } else if userCachedStatus.encryptedSearchTotalMessages == numberOfMessagesInSearchIndex || expectedESStates.contains(EncryptedSearchService.shared.getESState(userID: userID)) {
                            downloadStatus = NSMutableAttributedString(string: LocalString._settings_message_history_status_all_downloaded)
                        } else {
                            downloadStatus = NSMutableAttributedString(string: LocalString._settings_message_history_status_download_in_progress)
                        }

                        // Config cell
                        threeLineCell.configCell(eSection.title, oldestMessageAttributedString, downloadStatus, tintableImage)
                    }
                }
            }
            return cell
        case .storageLimit:
            let cell = tableView.dequeueReusableCell(withIdentifier: SliderTableViewCell.CellID, for: indexPath)
            if let sliderCell = cell as? SliderTableViewCell {
                let sliderSteps: [Float] = [0,1,2,3,4,5]
                let sliderStepsDisplay: [Float] = [200_000_000, 400_000_000, 600_000_000, 800_000_000, 1_000_000_000, 1_200_000_000]

                let storageLimit: String = self.fileByteCountFormatter.string(fromByteCount: self.viewModel.storageLimit)
                let bottomLine: String = LocalString._encrypted_search_downloaded_messages_storage_limit_selection + storageLimit

                let index: Int = sliderStepsDisplay.firstIndex(of: Float(self.viewModel.storageLimit)) ?? 2
                //print("index: \(index), limit: \(self.viewModel.storageLimit)")
                let currentSliderValue: Float = sliderSteps[index]
                sliderCell.slider.value = currentSliderValue //initialize here?
                //print("current slider value: \(currentSliderValue)")
                sliderCell.configCell(eSection.title, bottomLine, currentSliderValue: currentSliderValue, sliderMinValue: sliderSteps[0], sliderMaxValue: sliderSteps[sliderSteps.count-1]){ newSliderValue in

                    let newIndex: Int = Int((newSliderValue).rounded())
                    sliderCell.slider.setValue(Float(newIndex), animated: false)  //snap to increments
                    
                    let actualValue:Float = sliderSteps[newIndex]
                    let displayValue: Float = sliderStepsDisplay[newIndex]

                    self.viewModel.storageLimit = Int64(displayValue)

                    // Resize search index
                    let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
                    if let userID = usersManager.firstUser?.userInfo.userId {
                        EncryptedSearchService.shared.resizeSearchIndex(expectedSize: self.viewModel.storageLimit, userID: userID)
                    } else {
                        print("ERROR when resizing the search index. User unknown!")
                    }

                    sliderCell.bottomLabel.text = LocalString._encrypted_search_downloaded_messages_storage_limit_selection + self.fileByteCountFormatter.string(fromByteCount: Int64(displayValue))

                    // Update storageusage row with storage limit
                    let path: IndexPath = IndexPath.init(row: 0, section: SettingsEncryptedSearchDownloadedMessagesViewModel.SettingsSection.storageUsage.rawValue)
                    UIView.performWithoutAnimation {
                        if self.tableView.hasRowAtIndexPath(indexPath: path) {
                            self.tableView.reloadRows(at: [path], with: .none)
                        }
                    }
                }
            }
            return cell
        case .storageUsage:
            let cell = tableView.dequeueReusableCell(withIdentifier: ButtonTableViewCell.CellID, for: indexPath)
            if let buttonCell = cell as? ButtonTableViewCell {
                var sizeOfIndex: String = ""
                let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
                let userID: String? = usersManager.firstUser?.userInfo.userId
                if let userID = userID {
                    sizeOfIndex = EncryptedSearchIndexService.shared.getSizeOfSearchIndex(for: userID).asString
                }

                let storageLimit: String = self.fileByteCountFormatter.string(fromByteCount: self.viewModel.storageLimit)
                let bottomLine = sizeOfIndex + LocalString._encrypted_search_downloaded_messages_storage_used_combiner + storageLimit

                buttonCell.configCell(eSection.title, bottomLine, LocalString._encrypted_search_downloaded_messages_storage_used_button_title){
                    self.showAlertDeleteDownloadedMessages()
                }
            }
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: Key.headerCell)
        header?.contentView.subviews.forEach { $0.removeFromSuperview() }
        header?.contentView.backgroundColor = ColorProvider.BackgroundSecondary

        if let headerCell = header {
            let eSection = self.viewModel.sections[section]
            switch eSection {
            case .messageHistory, .storageLimit:
                break
            case .storageUsage:
                let textLabel = UILabel()
                textLabel.numberOfLines = 0
                textLabel.translatesAutoresizingMaskIntoConstraints = false
                textLabel.attributedText = NSAttributedString(string: eSection.foot, attributes: FontManager.CaptionWeak)
                headerCell.contentView.addSubview(textLabel)

                NSLayoutConstraint.activate([
                    textLabel.topAnchor.constraint(equalTo: headerCell.contentView.topAnchor, constant: 8),
                    textLabel.bottomAnchor.constraint(equalTo: headerCell.contentView.bottomAnchor, constant: -8),
                    textLabel.leadingAnchor.constraint(equalTo: headerCell.contentView.leadingAnchor, constant: 16),
                    textLabel.trailingAnchor.constraint(equalTo: headerCell.contentView.trailingAnchor, constant: -16)
                ])
                break
            }
        }
        return header
    }

    func showAlertDeleteDownloadedMessages() {
        let alert = UIAlertController(title: LocalString._encrypted_search_delete_messages_alert_title, message: LocalString._encrypted_search_delete_messages_alert_message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: LocalString._encrypted_search_delete_messages_alert_button_cancel, style: UIAlertAction.Style.cancel){ (action:UIAlertAction!) in
            self.tableView.reloadData()
        })
        alert.addAction(UIAlertAction(title: LocalString._encrypted_search_delete_messages_alert_button_delete, style: UIAlertAction.Style.destructive){ (action:UIAlertAction!) in
            let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
            if let userID = usersManager.firstUser?.userInfo.userId {
                EncryptedSearchService.shared.deleteSearchIndex(userID: userID)
                EncryptedSearchService.shared.setESState(userID: userID, indexingState: .disabled)
            } else {
                print("Error when deleting the search index. User unknown!")
            }
            self.navigationController?.popViewController(animated: true)
        })

        self.present(alert, animated: true, completion: nil)
    }
}
