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

class SettingsEncryptedSearchViewController: ProtonMailTableViewController, ViewModelProtocol, CoordinatedNew, UITextViewDelegate {
    internal var viewModel: SettingsEncryptedSearchViewModel!
    internal var coordinator: SettingsDeviceCoordinator?

    internal var interruption: Bool = false
    internal var hideSections: Bool = true
    internal var banner: BannerView!

    struct Key {
        static let cellHeight: CGFloat = 48.0
        static let cellHeightDownloadProgress = 156.0
        static let cellHeightDownloadProgressNoWifi = 140.0
        static let cellHeightDownloadProgressLowBattery = 188.0
        static let cellHeightDownloadProgressFinished = 108.0
        static let cellHeightDownloadProgressIndexUpdate = 102.0
        static let footerHeight : CGFloat = 48.0
        static let headerHeightFirstCell: CGFloat = 32.0
        static let headerHeight: CGFloat = 24.0
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
        self.view.backgroundColor = ColorProvider.BackgroundSecondary
        self.view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)

        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: Key.headerCell)
        self.tableView.register(SwitchTableViewCell.self)
        self.tableView.register(ProgressBarButtonTableViewCell.self)
        self.tableView.register(ThreeLinesTableViewCell.self)
        self.tableView.register(SpinnerTableViewCell.self)
        self.tableView.estimatedSectionFooterHeight = Key.footerHeight
        self.tableView.sectionFooterHeight = Key.footerHeight
        self.tableView.estimatedRowHeight = Key.cellHeight
        self.tableView.rowHeight = UITableView.automaticDimension

        setupEstimatedTimeUpdateObserver()
        setupProgressUpdateObserver()
        setupIndexingFinishedObserver()
        setupIndexingInterruptionObservers()

        if EncryptedSearchService.shared.state == .undetermined {
            // Determine current encrypted search state
            EncryptedSearchService.shared.determineEncryptedSearchState()

            // If we cannot determine the state - disable encrypted search
            if EncryptedSearchService.shared.state == .undetermined {
                print("Error cannot determine state of ES! set to disabled")
                EncryptedSearchService.shared.state = .disabled
                self.viewModel.isEncryptedSearch = false
            }
        } else if EncryptedSearchService.shared.state == .background || EncryptedSearchService.shared.state == .backgroundStopped {
            EncryptedSearchService.shared.state = .downloading
            print("ENCRYPTEDSEARCH-STATE: downloading - from background")
        }

        //Speed up indexing when on this view
        EncryptedSearchService.shared.speedUpIndexing()
        
        if EncryptedSearchService.shared.state == .downloading || EncryptedSearchService.shared.state == .paused || EncryptedSearchService.shared.state == .refresh {
            self.showInfoBanner()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        //slow down indexing when moving somewhere else in the app
        EncryptedSearchService.shared.slowDownIndexing()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.viewModel.isEncryptedSearch {
            self.hideSections = false
        } else {
            self.hideSections = true
        }
        self.tableView.reloadData()
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
            if EncryptedSearchService.shared.state == .complete || EncryptedSearchService.shared.state == .partial {
                return Key.cellHeightDownloadProgressFinished
            } else if EncryptedSearchService.shared.state == .refresh {
                return Key.cellHeightDownloadProgressIndexUpdate
            } else if EncryptedSearchService.shared.pauseIndexingDueToWiFiNotDetected || EncryptedSearchService.shared.pauseIndexingDueToLowStorage || EncryptedSearchService.shared.pauseIndexingDueToNetworkConnectivityIssues {
                return Key.cellHeightDownloadProgressNoWifi
            } else if EncryptedSearchService.shared.pauseIndexingDueToLowBattery {
                return Key.cellHeightDownloadProgressLowBattery
            } else {
                return Key.cellHeightDownloadProgress
            }
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return Key.headerHeightFirstCell
        }
        if section > 0 && self.hideSections {
            return CGFloat.leastNormalMagnitude
        }
        if section > 0 && !self.hideSections {
            return Key.headerHeight
        }
        return super.tableView(tableView, heightForHeaderInSection: section)
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = ColorProvider.BackgroundSecondary
        headerView.translatesAutoresizingMaskIntoConstraints = false

        if section == 0 {
            headerView.frame = CGRect(x: 0, y: 0, width: 375.0, height: Key.headerHeightFirstCell)
            NSLayoutConstraint.activate([
                headerView.heightAnchor.constraint(equalToConstant: Key.headerHeightFirstCell)
            ])
        } else {
            headerView.frame = CGRect(x: 0, y: 0, width: 375.0, height: Key.headerHeight)
            NSLayoutConstraint.activate([
                headerView.heightAnchor.constraint(equalToConstant: Key.headerHeight)
            ])
        }

        return headerView
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section > 0 && self.hideSections {
            return CGFloat.leastNormalMagnitude
        }
        return Key.footerHeight
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

                    // If cell is active -> start building a search index
                    if self.viewModel.isEncryptedSearch {
                        self.showAlertContentSearchEnabled(for: indexPath, cell: switchCell)
                    } else {
                        if EncryptedSearchService.shared.state == .downloading || EncryptedSearchService.shared.state == .refresh {
                            // Pause indexing
                            EncryptedSearchService.shared.pauseAndResumeIndexingByUser(isPause: true)
                        }
                        // Hide sections
                        self.hideSections = true
                        // Remove banner
                        UIView.performWithoutAnimation {
                            self.banner.remove(animated: false)
                        }
                        // Reload table
                        self.tableView.reloadData()
                    }
                }
            }
            return cell
        case .downloadViaMobileData:
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.CellID, for: indexPath)
            if let switchCell = cell as? SwitchTableViewCell {
                switchCell.configCell(eSection.title, bottomLine: "", status: viewModel.downloadViaMobileData) { _, _, _ in
                    let status = self.viewModel.downloadViaMobileData
                    self.viewModel.downloadViaMobileData = !status

                    if #available(iOS 12, *) {
                        // Disable interupt when mobile data is enabled
                        if self.viewModel.downloadViaMobileData {
                            //check if internet is availabel
                            if EncryptedSearchService.shared.networkMonitor?.currentPath.status == .satisfied {
                                self.interruption = false
                                DispatchQueue.main.async {
                                    let path: IndexPath = IndexPath.init(row: 0, section: SettingsEncryptedSearchViewModel.SettingSection.downloadedMessages.rawValue)

                                    UIView.performWithoutAnimation {
                                        self.tableView.reloadRows(at: [path], with: .none)
                                    }
                                }
                            }
                        }
                        // Check network connection
                        EncryptedSearchService.shared.checkIfNetworkAvailable()
                    } else {
                        // Fallback on earlier versions
                    }
                }
            }
            return cell
        case .downloadedMessages:
            if EncryptedSearchService.shared.state == .refresh {
                let cell = tableView.dequeueReusableCell(withIdentifier: SpinnerTableViewCell.CellID, for: indexPath)
                if let spinnerCell = cell as? SpinnerTableViewCell {
                    spinnerCell.configCell(LocalString._settings_title_of_downloaded_messages_progress, LocalString._settings_encrypted_search_refresh_index)
                }
                return cell
            } else if EncryptedSearchService.shared.state == .complete {
                //index building completely finished
                let cell = tableView.dequeueReusableCell(withIdentifier: ThreeLinesTableViewCell.CellID, for: indexPath)
                if let threeLineCell = cell as? ThreeLinesTableViewCell {
                    let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
                    let userID: String = (usersManager.firstUser?.userInfo.userId)!

                    // Create attributed string for oldest message in search index
                    let oldestMessageString: String = EncryptedSearchIndexService.shared.getOldestMessageInSearchIndex(for: userID)
                    let oldestMessageFullString: String = LocalString._encrypted_search_downloaded_messages_oldest_message + oldestMessageString
                    let oldestMessageAttributedString = NSMutableAttributedString(string: oldestMessageFullString)

                    // Create attributed string for the size of the search index
                    let sizeOfIndexString: String = EncryptedSearchIndexService.shared.getSizeOfSearchIndex(for: userID).asString
                    let sizeOfIndexFullString: String = LocalString._encrypted_search_downloaded_messages_storage_used + sizeOfIndexString
                    let sizeOfIndexAttributedString = NSMutableAttributedString(string: sizeOfIndexFullString)
                    let rangeSizeOfIndex = NSRange(location: LocalString._encrypted_search_downloaded_messages_storage_used.count, length: sizeOfIndexString.count)
                    sizeOfIndexAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: ColorProvider.TextNorm, range: rangeSizeOfIndex)

                    // Create icon for the partial index
                    let image: UIImage = UIImage(named: "contact_groups_check")!
                    let tintableImage = image.withRenderingMode(.alwaysTemplate)
                    threeLineCell.icon.tintColor = ColorProvider.NotificationSuccess

                    threeLineCell.configCell(LocalString._settings_title_of_downloaded_messages, oldestMessageAttributedString, sizeOfIndexAttributedString, tintableImage)
                    threeLineCell.accessoryType = .disclosureIndicator
                }
                return cell 
            } else if EncryptedSearchService.shared.state == .partial {
                let cell = tableView.dequeueReusableCell(withIdentifier: ThreeLinesTableViewCell.CellID, for: indexPath)
                if let threeLineCell = cell as? ThreeLinesTableViewCell {
                    let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
                    let userID: String = (usersManager.firstUser?.userInfo.userId)!

                    // Create attributed string for oldest message in search index
                    let oldestMessageString: String = EncryptedSearchIndexService.shared.getOldestMessageInSearchIndex(for: userID)
                    let oldestMessageFullString: String = LocalString._encrypted_search_downloaded_messages_oldest_message + oldestMessageString
                    let oldestMessageAttributedString = NSMutableAttributedString(string: oldestMessageFullString)
                    let rangeOldestMessage = NSRange(location: LocalString._encrypted_search_downloaded_messages_oldest_message.count, length: oldestMessageString.count)
                    oldestMessageAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: ColorProvider.NotificationError, range: rangeOldestMessage)

                    // Create attributed string for the size of the search index
                    let sizeOfIndexString: String = EncryptedSearchIndexService.shared.getSizeOfSearchIndex(for: userID).asString
                    let sizeOfIndexFullString: String = LocalString._encrypted_search_downloaded_messages_storage_used + sizeOfIndexString
                    let sizeOfIndexAttributedString = NSMutableAttributedString(string: sizeOfIndexFullString)
                    let rangeSizeOfIndex = NSRange(location: LocalString._encrypted_search_downloaded_messages_storage_used.count, length: sizeOfIndexString.count)
                    sizeOfIndexAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: ColorProvider.TextNorm, range: rangeSizeOfIndex)

                    // Create icon for the partial index
                    let image: UIImage = UIImage(named: "ic-exclamation-circle")!
                    let tintableImage = image.withRenderingMode(.alwaysTemplate)
                    threeLineCell.icon.tintColor = ColorProvider.NotificationError

                    threeLineCell.configCell(LocalString._settings_title_of_downloaded_messages, oldestMessageAttributedString, sizeOfIndexAttributedString, tintableImage)
                    threeLineCell.accessoryType = .disclosureIndicator
                }
                return cell
            } else {
                //index building in progress
                let cell = tableView.dequeueReusableCell(withIdentifier: ProgressBarButtonTableViewCell.CellID, for: indexPath)
                if let progressBarButtonCell = cell as? ProgressBarButtonTableViewCell {
                    // Set text for estimate time label
                    var estimatedTimeText: String = ""
                    if EncryptedSearchService.shared.state == .paused {
                        estimatedTimeText = LocalString._encrypted_search_download_paused
                    } else if EncryptedSearchService.shared.state == .downloading {
                        let estimatedTime: Int = self.viewModel.estimatedTimeRemaining.value ?? 0
                        if estimatedTime == 1 {
                            estimatedTimeText = String(estimatedTime) + LocalString._encrypted_search_estimated_time_label_suffix_singular
                        } else {
                            estimatedTimeText = String(estimatedTime) + LocalString._encrypted_search_estimated_time_label_suffix
                        }
                    } else {
                        estimatedTimeText = LocalString._encrypted_search_default_text_estimated_time_label
                    }

                    // Handle UI changes when an interruption occurs
                    if self.interruption {
                        estimatedTimeText = self.viewModel.interruptStatus.value ?? LocalString._encrypted_search_default_text_estimated_time_label
                        progressBarButtonCell.estimatedTimeLabel.textColor = ColorProvider.NotificationError
                        progressBarButtonCell.currentProgressLabel.textColor = ColorProvider.NotificationError
                        if EncryptedSearchService.shared.pauseIndexingDueToWiFiNotDetected || EncryptedSearchService.shared.pauseIndexingDueToNetworkConnectivityIssues || EncryptedSearchService.shared.pauseIndexingDueToLowStorage {
                            progressBarButtonCell.pauseButton.isHidden = true
                            progressBarButtonCell.statusLabel.isHidden = false
                        }
                        if EncryptedSearchService.shared.pauseIndexingDueToLowBattery {
                            progressBarButtonCell.statusLabel.isHidden = false

                            // TODO updating constraints doesn't seem to work
                            NSLayoutConstraint.activate([
                                progressBarButtonCell.pauseButton.topAnchor.constraint(equalTo: progressBarButtonCell.estimatedTimeLabel.bottomAnchor, constant: 48)
                            ])
                            progressBarButtonCell.layoutIfNeeded()
                            //let buttonTopConstraint = progressBarButtonCell.constraints.filter({$0.firstItem == progressBarButtonCell.pauseButton}).first!
                            //NSLayoutConstraint.deactivate([])
                            
                            /*NSLayoutConstraint.activate([
                                progressBarButtonCell.pauseButton.topAnchor.constraint(equalTo: progressBarButtonCell.statusLabel.bottomAnchor, constant: 16),
                            ])*/
                        }
                    } else {
                        progressBarButtonCell.statusLabel.isHidden = true
                        progressBarButtonCell.pauseButton.isHidden = false
                        progressBarButtonCell.estimatedTimeLabel.textColor = ColorProvider.TextWeak
                        progressBarButtonCell.currentProgressLabel.textColor = ColorProvider.TextWeak
                    }

                    // Set title of button
                    var buttonTitle: String = ""
                    if EncryptedSearchService.shared.state == .paused {
                        buttonTitle = LocalString._encrypted_search_resume_button
                    } else {
                        buttonTitle = LocalString._encrypted_search_pause_button
                    }

                    // Set advice text
                    let adviceText: String = self.viewModel.interruptAdvice.value ?? ""

                    progressBarButtonCell.configCell(LocalString._settings_title_of_downloaded_messages_progress, adviceText, estimatedTimeText, self.viewModel.currentProgress.value!, buttonTitle) {
                        if EncryptedSearchService.shared.state == .paused { // Resume indexing
                            // Set the state
                            EncryptedSearchService.shared.state = .downloading

                            // Update UI
                            DispatchQueue.main.async {
                                let path: IndexPath = IndexPath.init(row: 0, section: SettingsEncryptedSearchViewModel.SettingSection.downloadedMessages.rawValue)
                                UIView.performWithoutAnimation {
                                    self.tableView.reloadRows(at: [path], with: .none)
                                }
                            }
                            // Resume indexing
                            EncryptedSearchService.shared.pauseAndResumeIndexingByUser(isPause: false)
                        } else {    // Pause indexing
                            // Set the state
                            EncryptedSearchService.shared.state = .paused

                            // Update UI
                            DispatchQueue.main.async {
                                let path: IndexPath = IndexPath.init(row: 0, section: SettingsEncryptedSearchViewModel.SettingSection.downloadedMessages.rawValue)
                                UIView.performWithoutAnimation {
                                    self.tableView.reloadRows(at: [path], with: .none)
                                }
                            }

                            // Pause indexing
                            EncryptedSearchService.shared.pauseAndResumeIndexingByUser(isPause: true)
                        }
                    }
                }
                return cell
            }
        }
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: Key.headerCell)
        header?.contentView.subviews.forEach { $0.removeFromSuperview() }
        header?.contentView.backgroundColor = ColorProvider.BackgroundSecondary

        if let headerCell = header {
            let eSection = self.viewModel.sections[section]
            switch eSection {
            case .encryptedSearch:
                let textView = UITextView()
                textView.isScrollEnabled = false
                textView.isEditable = false
                textView.backgroundColor = .clear

                let learnMore = LocalString._settings_footer_of_encrypted_search_learn
                let full = String.localizedStringWithFormat(eSection.foot, learnMore)
                let attr = FontManager.CaptionWeak.lineBreakMode(.byWordWrapping)
                let attributedString = NSMutableAttributedString(string: full, attributes: attr)

                if let subrange = full.range(of: learnMore){
                    let nsRange = NSRange(subrange, in: full)
                    attributedString.addAttribute(.link, value: Link.encryptedSearchInfo, range: nsRange)
                    textView.linkTextAttributes = [.foregroundColor: ColorProvider.InteractionNorm]
                }
                textView.attributedText = attributedString
                textView.translatesAutoresizingMaskIntoConstraints = false
                textView.delegate = self

                headerCell.contentView.addSubview(textView)

                NSLayoutConstraint.activate([
                    textView.leadingAnchor.constraint(equalTo: headerCell.contentView.leadingAnchor, constant: 16),
                    textView.trailingAnchor.constraint(equalTo: headerCell.contentView.trailingAnchor, constant: -16)
                ])
                break
            case .downloadViaMobileData, .downloadedMessages:
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

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section

        let eSection = self.viewModel.sections[section]
        switch eSection {
        case .encryptedSearch, .downloadViaMobileData:
            break
        case .downloadedMessages:
            if EncryptedSearchService.shared.state == .complete || EncryptedSearchService.shared.state == .partial {
                let vm = SettingsEncryptedSearchDownloadedMessagesViewModel(encryptedSearchDownloadedMessagesCache: userCachedStatus)
                let vc = SettingsEncryptedSearchDownloadedMessagesViewController()
                vc.set(viewModel: vm)
                //vc.set(coordinator: self.coordinator!)
                show(vc, sender: self)
            }
            break
        }
    }

    func showAlertContentSearchEnabled(for index: IndexPath, cell: SwitchTableViewCell) {
        // Create the alert
        let alert = UIAlertController(title: LocalString._encrypted_search_alert_title, message: LocalString._encrypted_search_alert_text, preferredStyle: UIAlertController.Style.alert)
        // Add the buttons
        alert.addAction(UIAlertAction(title: LocalString._encrypted_search_alert_cancel_button, style: UIAlertAction.Style.cancel){ (action:UIAlertAction!) in
            self.viewModel.isEncryptedSearch = false
            self.tableView.reloadData()
        })
        alert.addAction(UIAlertAction(title: LocalString._encrypted_search_alert_enable_button, style: UIAlertAction.Style.default){ (action:UIAlertAction!) in
            if EncryptedSearchService.shared.state == .paused {
                // If indexing has been paused, automatically resume it when ES is switched on again
                EncryptedSearchService.shared.pauseAndResumeIndexingByUser(isPause: false)
            } else {
                // Start building the search index
                EncryptedSearchService.shared.buildSearchIndex(self.viewModel)
            }

            // Update UI
            self.hideSections = false
            self.tableView.reloadData() // Refresh the view to show changes in UI
            self.showInfoBanner()
        })

        // Show alert
        self.present(alert, animated: true, completion: nil)
    }

    func setupEstimatedTimeUpdateObserver() {
        self.viewModel.estimatedTimeRemaining.bind { (_) in
            if EncryptedSearchService.shared.state == .downloading {
                DispatchQueue.main.async {
                    let path: IndexPath = IndexPath.init(row: 0, section: SettingsEncryptedSearchViewModel.SettingSection.downloadedMessages.rawValue)

                    UIView.performWithoutAnimation {
                        self.tableView.reloadRows(at: [path], with: .none)
                    }
                }
            }
        }
    }

    func setupProgressUpdateObserver() {
        self.viewModel.currentProgress.bind { (_) in
            if EncryptedSearchService.shared.state == .downloading {
                DispatchQueue.main.async {
                    let path: IndexPath = IndexPath.init(row: 0, section: SettingsEncryptedSearchViewModel.SettingSection.downloadedMessages.rawValue)

                    UIView.performWithoutAnimation {
                        self.tableView.reloadRows(at: [path], with: .none)
                    }
                }
            }
        }
    }

    func setupIndexingInterruptionObservers() {
        self.viewModel.interruptStatus.bind {
            (_) in
            self.interruption = true
            DispatchQueue.main.async {
                let path: IndexPath = IndexPath.init(row: 0, section: SettingsEncryptedSearchViewModel.SettingSection.downloadedMessages.rawValue)

                UIView.performWithoutAnimation {
                    self.tableView.reloadRows(at: [path], with: .none)
                    self.showInfoBanner()
                }
            }
        }
    }

    func setupIndexingFinishedObserver() {
        self.viewModel.isIndexingComplete.bind { (_) in
            if EncryptedSearchService.shared.state == .complete || EncryptedSearchService.shared.state == .partial {
                DispatchQueue.main.async {
                    UIView.performWithoutAnimation {
                        if let banner = self.banner {
                            banner.remove(animated: false)
                        }
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }

    private func showInfoBanner() {
        if self.banner != nil {
            UIView.performWithoutAnimation {
                self.banner.remove(animated: false)
            }
        }

        var positionOfBanner: CGFloat = 516
        // If search message content is switched on the state is still disabled -> show banner same as when downloading
        if EncryptedSearchService.shared.state == .disabled || EncryptedSearchService.shared.state == .downloading || EncryptedSearchService.shared.state == .paused {
            if EncryptedSearchService.shared.pauseIndexingDueToWiFiNotDetected || EncryptedSearchService.shared.pauseIndexingDueToNetworkConnectivityIssues || EncryptedSearchService.shared.pauseIndexingDueToLowStorage {
                positionOfBanner = Key.headerHeightFirstCell + (Key.headerHeight * 2) + (Key.footerHeight * 2) + (Key.cellHeight * 2) + Key.cellHeightDownloadProgressNoWifi + 16
            } else if EncryptedSearchService.shared.pauseIndexingDueToLowBattery {
                positionOfBanner = Key.headerHeightFirstCell + (Key.headerHeight * 2) + (Key.footerHeight * 2) + (Key.cellHeight * 2) + Key.cellHeightDownloadProgressLowBattery + 16
            } else {
                positionOfBanner = Key.headerHeightFirstCell + (Key.headerHeight * 2) + (Key.footerHeight * 2) + (Key.cellHeight * 2) + Key.cellHeightDownloadProgress + 16
            }
        } else if EncryptedSearchService.shared.state == .complete || EncryptedSearchService.shared.state == .partial {
            positionOfBanner = Key.headerHeightFirstCell + (Key.headerHeight * 2) + (Key.footerHeight * 2) + (Key.cellHeight * 2) + Key.cellHeightDownloadProgressFinished + 16
        } else if EncryptedSearchService.shared.state == .refresh {
            positionOfBanner = Key.headerHeightFirstCell + (Key.headerHeight * 2) + (Key.footerHeight * 2) + (Key.cellHeight * 2) + Key.cellHeightDownloadProgressIndexUpdate + 16
        }
        self.banner = BannerView(appearance: .esBlack, message: LocalString._encrypted_search_info_banner_text, buttons: nil, button2: nil, offset: positionOfBanner, dismissDuration: Double.infinity)

        UIView.performWithoutAnimation {
            self.view.addSubview(self.banner)
            self.banner.drop(on: self.view, from: .top)
        }
    }
}
