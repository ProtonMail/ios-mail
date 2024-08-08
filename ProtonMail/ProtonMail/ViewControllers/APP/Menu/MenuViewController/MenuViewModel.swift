//
//  MenuViewModel.swift
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

import Combine
import CoreData
import Foundation
import PromiseKit
import ProtonCoreAccountSwitcher
import ProtonCoreDataModel
import ProtonCoreFeatureFlags
import ProtonCoreUIFoundations
import ProtonMailAnalytics
import UIKit

final class MenuViewModel: NSObject {
    typealias Dependencies = HasCoreDataContextProviderProtocol
    & HasKeyMakerProtocol
    & HasLockCacheStatus
    & HasQueueManager
    & HasUnlockManager
    & HasUsersManager
    & HasMailEventsPeriodicScheduler

    private let dependencies: Dependencies
    private var scheduleSendLocationStatusObserver: MessagesAssignedToLabelIDObserver?
    private var snoozeLocationStatusObserver: MessagesAssignedToLabelIDObserver?

    private var labelDataService: LabelsDataService? {
        guard let labelService = self.currentUser?.labelService else {
            return nil
        }

        return labelService
    }
    private var labelPublisher: LabelPublisher?
    /// To observe the unread number change for message mode label
    private var labelUpdatePublisher: LabelUpdatePublisher?
    private var labelUpdatePublisherCancellable: AnyCancellable?
    /// To observe the unread number change for conversation mode label
    private var conversationCountPublisher: ConversationCountPublisher?
    private var conversationCountPublisherCancellable: AnyCancellable?
    private weak var delegate: MenuUIProtocol?
    var currentUser: UserManager? {
        dependencies.usersManager.firstUser
    }
    /// It is used to check if menu needs to update the view when the active account is changed.
    private var currentUserID: UserID?
    var secondUser: UserManager? {
        dependencies.usersManager.user(at: 1)
    }
    private(set) var menuWidth: CGFloat!

    private var rawData = [MenuLabel]()
    private(set) var sections: [MenuSection]
    private(set) var inboxItems: [MenuLabel]
    private(set) var folderItems: [MenuLabel] = []
    private(set) var labelItems: [MenuLabel] = []
    private(set) var moreItems: [MenuLabel]

    private var selectedItem: MenuLabel? {
        let items = inboxItems + folderItems + labelItems + moreItems
        return items.first(where: { $0.isSelected })
    }

    var reloadClosure: (() -> Void)?
    lazy private(set) var userEnableColorSettingClosure: () -> Bool = { [weak self] in
        self?.currentUser?.userInfo.enableFolderColor == 1
    }
    lazy private(set) var userUsingParentFolderColorClosure: () -> Bool = { [weak self] in
        self?.currentUser?.userInfo.inheritParentFolderColor == 1
    }

    weak var coordinator: MenuCoordinatorProtocol?
    private var mailSettingCancellable: AnyCancellable?
    private var dataFetchTimer: Timer?

    init(dependencies: Dependencies) {
        self.dependencies = dependencies

        self.sections = [.inboxes, .folders, .labels, .more]
        self.inboxItems = Self.inboxItems(
            almostAllMailIsOn: dependencies.usersManager.firstUser?.mailSettings.almostAllMail ?? false
        )
        let defaultInfo = MoreItemsInfo(
            userIsMember: nil,
            isPinCodeEnabled: dependencies.lockCacheStatus.isPinCodeEnabled,
            isTouchIDEnabled: dependencies.lockCacheStatus.isTouchIDEnabled,
            isReferralEligible: dependencies.usersManager.firstUser?.userInfo.referralProgram?.eligible ?? false
        )
        self.moreItems = Self.moreItems(for: defaultInfo)
        super.init()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: MenuVMProtocol
extension MenuViewModel: MenuVMProtocol {
    /// Initialize needed
    func set(delegate: MenuUIProtocol) {
        self.delegate = delegate
    }

    func set(menuWidth: CGFloat) {
        self.coordinator?.update(menuWidth: menuWidth)
        self.menuWidth = menuWidth
    }

    func userDataInit() {
        assert(self.delegate != nil,
               "delegate can't be nil, use set(delegate:) to setting")
        // Check if the menu can load the user data, if not retry after delay.
        dataFetchTimer?.invalidate()
        dataFetchTimer = nil
        guard currentUser != nil else {
            SystemLogger.log(
                message: "User not found in userDataInit.",
                category: .menuDebug
            )
            dataFetchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { [weak self] _ in
                SystemLogger.log(
                    message: "Retry userDataInit",
                    category: .menuDebug
                )
                self?.userDataInit()
            })
            return
        }

        self.registerNotification()
        self.fetchLabels()
        self.observeLabelUnreadUpdate()
        self.observeContextLabelUnreadUpdate()
        self.observeScheduleSendLocationStatus()
        self.observeSnoozeLocationStatus()
        self.observeAlmostAllMailSettingChange()
        self.highlight(label: MenuLabel(location: .inbox))
        self.setupEventsLoop()
    }

    func setupEventsLoop() {
        let scheduler = dependencies.mailEventsPeriodicScheduler
        scheduler.reset()
        for user in dependencies.usersManager.users where user.isNewEventLoopEnabled {
            scheduler.enableSpecialLoop(forSpecialLoopID: user.userID.rawValue)
        }
        scheduler.start()
    }

    var enableFolderColor: Bool {
        guard let user = self.currentUser else { return false }
        return user.userInfo.enableFolderColor == 1
    }

    var storageAlertVisibility: StorageAlertVisibility {
        guard FeatureFlagsRepository.shared.isEnabled(CoreFeatureFlagType.splitStorage),
              let userInfo = self.currentUser?.userInfo,
              !userInfo.isOnAStoragePaidPlan else {
            return .hidden
        }
        if currentMailStoragePercentage > 0.8 {
            return .mail(currentMailStoragePercentage)
        } else if currentDriveStoragePercentage > 0.8 {
            return .drive(currentDriveStoragePercentage)
        }
        return .hidden
    }

    var currentMailStoragePercentage: CGFloat {
        guard let userInfo = self.currentUser?.userInfo,
              let usedBaseSpace = userInfo.usedBaseSpace,
              let maxBaseSpace = userInfo.maxBaseSpace,
              maxBaseSpace > 0 else {
            return 0
        }
        return CGFloat(usedBaseSpace) / CGFloat(maxBaseSpace)
    }

    var currentDriveStoragePercentage: CGFloat {
        guard let userInfo = self.currentUser?.userInfo,
              let usedDriveSpace = userInfo.usedDriveSpace,
              let maxDriveSpace = userInfo.maxDriveSpace,
              maxDriveSpace > 0 else {
            return 0
        }
        return CGFloat(usedDriveSpace) / CGFloat(maxDriveSpace)
    }

    func menuViewInit() {
        self.updateStorageAlert()
        self.updatePrimaryUserView()
        self.updateMoreItems(shouldReload: false)
        self.updateUnread()
        delegate?.updateMenu(section: nil)
    }

    func menuItemOrError(
        indexPath: IndexPath,
        caller: StaticString
    ) -> Swift.Result<MenuLabel, MailAnalyticsErrorEvent> {
        let section = self.sections[indexPath.section]
        let row = indexPath.row

        let sectionItems: [MenuLabel]
        switch section {
        case .maxStorage:
            return .success(.init(location: .init(id: "maxStorage", name: nil)))
        case .inboxes:
            return .success(self.inboxItems[row])
        case .folders:
            sectionItems = folderItems
            if let item = sectionItems.getFolderItem(at: row) {
                return .success(item)
            }
        case .labels:
            sectionItems = labelItems
            if let item = sectionItems[safe: row] {
                return .success(item)
            }
        case .more:
            sectionItems = moreItems
            if let item = sectionItems[safe: row] {
                return .success(item)
            }
        }

        let error = MailAnalyticsErrorEvent.invalidMenuItemRequested(
            section: section.title,
            row: row,
            itemCount: sectionItems.count,
            caller: caller
        )
        return .failure(error)
    }

    func menuItem(in section: MenuSection, at index: Int) -> MenuLabel? {
        switch section {
        case .maxStorage:
            return .init(location: .init(id: "maxStorage", name: nil))
        case .inboxes:
            return inboxItems[index]
        case .folders:
            return folderItems.getFolderItem(at: index)
        case .labels:
            return labelItems[safe: index]
        case .more:
            return moreItems[safe: index]
        }
    }

    func numberOfRowsIn(section: Int) -> Int {
        switch self.sections[section] {
        case .maxStorage: return 1
        case .inboxes: return self.inboxItems.count
        case .folders:
            return self.folderItems.getNumberOfRows()
        case .labels: return self.labelItems.count
        case .more: return self.moreItems.count
        }
    }

    func clickCollapsedArrow(labelID: LabelID) {
        guard let idx = self.rawData.firstIndex(where: {$0.location.labelID == labelID}) else {
            return
        }
        self.rawData[idx].expanded = !self.rawData[idx].expanded
        self.handleMenuExpandEvent(label: self.rawData[idx])
    }

    func isCurrentUserHasQueuedMessage() -> Bool {
        guard let user = self.currentUser else {
            return false
        }
        return dependencies.queueManager.isAnyQueuedMessage(of: user.userID)
    }

    func removeAllQueuedMessageOfCurrentUser() {
        guard let user = self.currentUser else {
            return
        }
        dependencies.queueManager.deleteAllQueuedMessage(of: user.userID, completeHander: nil)
    }

    func signOut(userID: UserID, completion: (() -> Void)?) {
        guard let user = dependencies.usersManager.getUser(by: userID) else {
            completion?()
            return
        }
        dependencies.mailEventsPeriodicScheduler.disableSpecialLoop(withSpecialLoopID: userID.rawValue)
        dependencies.usersManager.logout(user: user, shouldShowAccountSwitchAlert: false, completion: completion)
    }

    func removeDisconnectAccount(userID: UserID) {
        guard let user = dependencies.usersManager.disconnectedUsers.first(where: {$0.userID == userID.rawValue}) else {return}
        dependencies.usersManager.removeDisconnectedUser(user)
    }

    func highlight(label: MenuLabel) {
        let tmp = self.inboxItems + self.rawData + self.moreItems
        tmp.forEach({$0.isSelected = false})
        let item = tmp.first(where: {$0.location.labelID == label.location.labelID})

        item?.isSelected = true
        self.delegate?.updateMenu(section: nil)
    }

    func appVersion() -> String {
        var appVersion = "Unknown Version"
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            appVersion = "\(version)"
        }
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            appVersion = appVersion + " (\(build))"
        }
        return appVersion
    }

    func getAccountList() -> [AccountSwitcher.AccountData] {
        var list = dependencies.usersManager.users.map {user -> AccountSwitcher.AccountData in
            let id = user.userInfo.userId
            let name = user.defaultDisplayName
            let mail = user.defaultEmail
            let unread = self.getUnread(of: id)
            return AccountSwitcher.AccountData(userID: id, name: name, mail: mail, isSignin: true, unread: unread)
        }

        list += dependencies.usersManager.disconnectedUsers.map {user -> AccountSwitcher.AccountData in
            return AccountSwitcher.AccountData(userID: user.userID, name: user.defaultDisplayName, mail: user.defaultEmail, isSignin: false, unread: 0)
        }
        return list
    }

    func getUnread(of userID: String) -> Int {
        guard let user = dependencies.usersManager.getUser(by: UserID(rawValue: userID)) else { return 0 }
        let labelID = LabelLocation.inbox.toMessageLocation.rawValue
        return user.getUnReadCount(by: labelID)
    }

    func activateUser(id: UserID) {
        guard let user = dependencies.usersManager.getUser(by: id) else {
            return
        }
        dependencies.usersManager.active(by: user.authCredential.sessionID)
        self.userDataInit()
        self.menuViewInit()
        self.delegate?.navigateTo(label: MenuLabel(location: .inbox))
        let msg = String(format: LocalString._signed_in_as, user.defaultEmail)
        self.delegate?.showToast(message: msg)
        currentUserID = currentUser?.userID
    }

    func prepareLogin(userID: UserID) {
        if let user = dependencies.usersManager.disconnectedUsers.first(where: {$0.userID == userID.rawValue}) {
            let label = MenuLabel(id: LabelLocation.addAccount.labelID, name: user.defaultEmail, parentID: nil, path: "tmp", textColor: "", iconColor: "", type: -1, order: -1, notify: false)
            self.delegate?.navigateTo(label: label)
        } else {
            let label = MenuLabel(id: LabelLocation.addAccount.labelID, name: "", parentID: nil, path: "tmp", textColor: nil, iconColor: nil, type: -1, order: -1, notify: false)
            self.delegate?.navigateTo(label: label)
        }
    }

    func prepareLogin(mail: String) {
        let label = MenuLabel(id: LabelLocation.addAccount.labelID, name: mail, parentID: nil, path: "tmp", textColor: nil, iconColor: nil, type: -1, order: -1, notify: false)
        self.delegate?.navigateTo(label: label)
    }

    func getIconColor(of label: MenuLabel) -> UIColor {

        let defaultColor = label.isSelected ? ColorProvider.SidebarIconWeak
            .resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)) : ColorProvider.SidebarIconWeak

        guard label.type == .folder else {
            if let labelColor = label.iconColor {
                return UIColor(hexColorCode: labelColor)
            }
            return defaultColor
        }

        let enableColor = self.userEnableColorSettingClosure()
        let inherit = self.userUsingParentFolderColorClosure()

        guard enableColor else {
            return defaultColor
        }
        if inherit {
            guard let parent = self.folderItems.getRootItem(of: label) else {
                return defaultColor
            }
            if let parentColor = parent.iconColor {
                return UIColor(hexColorCode: parentColor)
            }
            return defaultColor
        } else {
            if let labelColor = label.iconColor {
                return UIColor(hexColorCode: labelColor)
            }
            return defaultColor
        }
    }

    func allowToCreate(type: PMLabelType) -> Bool {
        guard let user = self.currentUser else { return false }
        // Only free user has limitation
        guard user.userInfo.subscribed.isEmpty else { return true }
        switch type {
        case .folder:
            return self.folderItems.getNumberOfRows() < Constants.FreePlan.maxNumberOfFolders
        case .label:
            return self.labelItems.getNumberOfRows() < Constants.FreePlan.maxNumberOfLabels
        default:
            return false
        }
    }

    func go(to labelInfo: MenuLabel) {
        guard selectedItem?.location != labelInfo.location || currentUserID != currentUser?.userID else {
            coordinator?.closeMenu()
            return
        }
        coordinator?.go(to: labelInfo, deepLink: nil)
    }

    func lockTheScreen() {
        // remove mainKey from memory
        dependencies.keyMaker.lockTheApp()
        // provoke mainKey obtaining
        _ = dependencies.unlockManager.isUnlocked()
        coordinator?.lockTheScreen()
    }
}

extension MenuViewModel: LabelListenerProtocol {
    func receivedLabels(labels: [LabelEntity]) {
        handle(dbLabels: labels)
    }
}

// MARK: Data source
extension MenuViewModel {
    private func fetchLabels() {
        guard let userID = currentUser?.userID, let service = labelDataService else {
            return
        }

        // The response of api will write into CoreData
        // And the change will trigger the label publiser
        defer {
            service.fetchV4Labels()
        }

        labelPublisher = .init(
            parameters: .init(userID: userID),
            dependencies: dependencies
        )
        labelPublisher?.delegate = self
        labelPublisher?.fetchLabels(labelType: .all)
    }

    private func observeLabelUnreadUpdate() {
        guard let user = self.currentUser else {return}

        labelUpdatePublisher = .init(
            userID: user.userID,
            contextProvider: dependencies.contextProvider
        )
        labelUpdatePublisherCancellable = labelUpdatePublisher?.contentDidChange
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.updateUnread()
                self?.delegate?.updateMenu(section: nil)
            })
        labelUpdatePublisher?.start()
    }

    private func observeContextLabelUnreadUpdate() {
        guard let user = self.currentUser else { return }
        conversationCountPublisher = .init(
            userID: user.userID,
            contextProvider: dependencies.contextProvider
        )
        conversationCountPublisherCancellable = conversationCountPublisher?.contentDidChange
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.updateUnread()
                self?.delegate?.updateMenu(section: nil)
            })
        conversationCountPublisher?.start()
    }

    private func observeScheduleSendLocationStatus() {
        guard let user = self.currentUser else { return }
        let observer =
        MessagesAssignedToLabelIDObserver(
                labelIDToObserve: Message.Location.scheduled.labelID,
                userID: user.userID,
                contextProvider: dependencies.contextProvider
            )

        do {
            let status = try observer.observe { [weak self] currentStatus in
                DispatchQueue.main.async {
                    self?.updateInboxItems(hasScheduledMessage: currentStatus)
                }
            }
            updateInboxItems(hasScheduledMessage: status)
            self.scheduleSendLocationStatusObserver = observer
        } catch {
            PMAssertionFailure(error.localizedDescription)
        }
    }

    private func observeSnoozeLocationStatus() {
        guard let user = self.currentUser else { return }
        let observer = MessagesAssignedToLabelIDObserver(
            labelIDToObserve: Message.Location.snooze.labelID,
            userID: user.userID,
            contextProvider: dependencies.contextProvider
        )
        do {
            let status = try observer.observe { [weak self] currentStatus in
                DispatchQueue.main.async {
                    self?.updateInboxItems(hasSnoozedMessage: currentStatus)
                }
            }
            updateInboxItems(hasSnoozedMessage: status)
            self.snoozeLocationStatusObserver = observer
        } catch {
            PMAssertionFailure(error.localizedDescription)
        }
    }

    private func observeAlmostAllMailSettingChange() {
        mailSettingCancellable = currentUser?.$mailSettings
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] mailSettings in
                guard let weakSelf = self else { return }
                let shouldUpdate = weakSelf.inboxItems.contains(where: { $0.location == .almostAllMail }) != mailSettings.almostAllMail
                if shouldUpdate {
                    weakSelf.updateInboxItems(isAlmostAllMailOn: mailSettings.almostAllMail)
                }
            })
    }

    func updateInboxItems(isAlmostAllMailOn: Bool) {
        if isAlmostAllMailOn && !inboxItems.contains(where: { $0.location == .almostAllMail }) {
            if let insertIndex = inboxItems.firstIndex(where: { $0.location == .allmail }) {
                inboxItems.remove(at: insertIndex)
                inboxItems.insert(MenuLabel(location: .almostAllMail), at: insertIndex)
            }
        } else {
            if let insertIndex = inboxItems.firstIndex(where: { $0.location == .almostAllMail  }) {
                inboxItems.remove(at: insertIndex)
                inboxItems.insert(MenuLabel(location: .allmail), at: insertIndex)
            }
        }
    }

    func updateInboxItems(hasScheduledMessage: Bool) {
        if hasScheduledMessage && !inboxItems.contains(where: { $0.location == .scheduled }) {
            if let insertIndex = inboxItems.firstIndex(where: { $0.location == .sent }) {
                inboxItems.insert(MenuLabel(location: .scheduled), at: insertIndex)
                reloadClosure?()
            }
        } else if hasScheduledMessage == false {
            inboxItems.removeAll(where: { $0.location == .scheduled })
            reloadClosure?()
        }
    }

    func updateInboxItems(hasSnoozedMessage: Bool) {
        if hasSnoozedMessage && !inboxItems.contains(where: { $0.location == .snooze }) {
            if let insertIndex = inboxItems.firstIndex(where: { $0.location == .sent }) {
                inboxItems.insert(MenuLabel(location: .snooze), at: insertIndex)
                reloadClosure?()
            }
        } else if hasSnoozedMessage == false {
            inboxItems.removeAll(where: { $0.location == .snooze })
            reloadClosure?()
        }
    }

    private func handle(dbLabels: [LabelEntity]) {
        let datas: [MenuLabel] = Array(labels: dbLabels, previousRawData: self.rawData)
        self.rawData = datas
        updateUnread()
        sortoutData(data: datas)
    }

    private func sortoutData(data: [MenuLabel]) {
        (self.labelItems, self.folderItems) = data.sortoutData()
        self.appendAddItems()
        self.delegate?.updateMenu(section: nil)
    }

    private func appendAddItems() {
        if self.labelItems.isEmpty {
            let addLabel = MenuLabel(id: LabelLocation.addLabel.labelID, name: LocalString._labels_add_label_action, parentID: nil, path: "tmp", textColor: nil, iconColor: nil, type: 1, order: 9999, notify: false)
            self.labelItems.append(addLabel)
        }

        if self.folderItems.isEmpty {
            let addFolder = MenuLabel(id: LabelLocation.addFolder.labelID, name: LocalString._labels_add_folder_action, parentID: nil, path: "tmp", textColor: nil, iconColor: nil, type: 1, order: 9999, notify: false)
            self.folderItems.append(addFolder)
        }
    }

    private func updateMoreItems(shouldReload: Bool = true) {
        let moreItemsInfo = MoreItemsInfo(userIsMember: currentUser?.userInfo.isMember ?? false,
                                          isPinCodeEnabled: dependencies.lockCacheStatus.isPinCodeEnabled,
                                          isTouchIDEnabled: dependencies.lockCacheStatus.isTouchIDEnabled,
                                          isReferralEligible: currentUser?.userInfo.referralProgram?.eligible ?? false)
        let newMore = Self.moreItems(for: moreItemsInfo)
        if newMore.count != self.moreItems.count {
            self.moreItems = newMore
            if shouldReload {
                let moreSectionIndex = self.sections.firstIndex(where: { $0 == .more })
                self.delegate?.updateMenu(section: moreSectionIndex)
            }
        }
    }

    // Get the tableview row of the given labelID
    private func getFolderItemRow(by labelID: LabelID, source: [MenuLabel]) -> Int? {
        var num = 0
        // DFS
        var queue = source
        while queue.count > 0 {
            let label = queue.remove(at: 0)
            if label.location.labelID == labelID {
                return num
            }
            num += 1
            guard label.expanded else {continue}
            for sub in label.subLabels.reversed() {
                queue.insert(sub, at: 0)
            }
        }
        return nil
    }

    // Query unread number of labels
    private func getUnreadNumbers() {
        let tmp = self.inboxItems + self.rawData
        let labels = tmp.map({ $0.location.labelID })

        guard let labelDataService else {
            return
        }

        let labelUnreadDict = labelDataService.getUnreadCounts(by: labels)
        for item in tmp {
            item.unread = labelUnreadDict[item.location.rawLabelID] ?? 0
        }
        if let unreadOfInbox = labelUnreadDict[Message.Location.inbox.rawValue] {
            UIApplication.setBadge(badge: unreadOfInbox)
        }
    }

    private func aggregateUnreadNumbers() {
        let arr = self.rawData.filter({$0.type == .folder}).reversed()
        // 0 is "add folder" label, skip
        for label in arr {
            guard label.subLabels.count > 0 else {
                label.aggreateUnread = label.unread
                continue
            }

            label.aggreateUnread = label.unread + label.subLabels.reduce(0, { (sum, label) -> Int in
                return sum + label.aggreateUnread
            })
        }
    }
}

// MARK: Private functions
extension MenuViewModel {
    private func registerNotification() {
        NotificationCenter.default.removeObserver(self)
        NotificationCenter
            .default
            .addObserver(self,
                         selector: #selector(primaryAccountLogout),
                         name: .didPrimaryAccountLogout,
                         object: nil)
    }

    @objc private func primaryAccountLogout() {
        guard dependencies.usersManager.users.count > 0,
              let user = self.currentUser else {return}
        self.activateUser(id: UserID(user.userInfo.userId))
    }

    private func updateStorageAlert() {
        let previousSectionsCount = self.sections.count
        if storageAlertVisibility == .hidden {
            self.sections.removeAll(where: { $0 == .maxStorage})
        } else if !self.sections.contains(where: { $0 == .maxStorage }) {
            self.sections.insert(.maxStorage, at: 0)
        }
        if self.sections.count != previousSectionsCount {
            self.reloadClosure?()
        }
    }

    private func updatePrimaryUserView() {
        guard let user = self.currentUser else {
            dependencies.usersManager.clean().cauterize()
            return
        }
        self.delegate?.update(email: user.defaultEmail)

        let name = user.defaultDisplayName.isEmpty ? user.defaultEmail: user.defaultDisplayName
        self.delegate?.update(displayName: name)
        self.delegate?.update(avatar: name.initials())
    }

    // Get the indexPaths should be Expanded / collapsed by the given label
    private func handleMenuExpandEvent(label: MenuLabel) {
        guard let row = self.getFolderItemRow(by: label.location.labelID, source: self.folderItems),
              let sectionOfFolder = sections.firstIndex(of: .folders) else {
            return
        }

        var num = 0
        var queue = label.subLabels
        while queue.count > 0 {
            let item = queue.remove(at: 0)
            num += 1
            guard item.expanded else { continue }
            item.subLabels.forEach { label in
                queue.insert(label, at: 0)
            }
        }
        guard num > 0 else { return }
        var arr = [IndexPath]()
        for idx in 1...num {
            arr.append(IndexPath(row: row + idx, section: sectionOfFolder))
        }

        let updateRow = IndexPath(row: row, section: sectionOfFolder)
        var insertRows: [IndexPath] = []
        var deleteRows: [IndexPath] = []
        if label.expanded {
            insertRows = arr
        } else {
            deleteRows = arr
        }

        self.delegate?.update(rows: [updateRow],
                              insertRows: insertRows,
                              deleteRows: deleteRows)
    }

    private func updateUnread() {
        getUnreadNumbers()
        aggregateUnreadNumbers()
    }
}

// MARK: MenuLabel options builder
extension MenuViewModel {
    struct MoreItemsInfo {
        var userIsMember: Bool?
        var isPinCodeEnabled: Bool
        var isTouchIDEnabled: Bool
        var isReferralEligible: Bool
    }

    static func inboxItems(almostAllMailIsOn: Bool) -> [MenuLabel] {
        var items = [
            MenuLabel(location: .inbox),
            MenuLabel(location: .draft),
            MenuLabel(location: .sent),
            MenuLabel(location: .starred),
            MenuLabel(location: .archive),
            MenuLabel(location: .spam),
            MenuLabel(location: .trash)
        ]
        if almostAllMailIsOn {
            items.append(.init(location: .almostAllMail))
        } else {
            items.append(.init(location: .allmail))
        }
        return items
    }

    static func moreItems(for info: MoreItemsInfo) -> [MenuLabel] {
        var newMore = [MenuLabel(location: .settings),
                       MenuLabel(location: .contacts),
                       MenuLabel(location: .bugs),
                       MenuLabel(location: .lockapp),
                       MenuLabel(location: .referAFriend),
                       MenuLabel(location: .signout)]

        if info.userIsMember == false, Application.arePaymentsEnabled {
            newMore.insert(MenuLabel(location: .subscription), at: 0)
        }

        if !info.isPinCodeEnabled, !info.isTouchIDEnabled {
            newMore = newMore.filter { $0.location != .lockapp }
        }

        if !info.isReferralEligible {
            newMore = newMore.filter { $0.location != .referAFriend }
        }

        return newMore
    }

#if DEBUG
    func setFolderItem(_ items: [MenuLabel]) {
        self.folderItems = items
    }

    func setUserEnableColorClosure(_ closure: @escaping () -> Bool) {
        self.userEnableColorSettingClosure = closure
    }

    func setParentFolderColorClosure(_ closure: @escaping () -> Bool) {
        self.userUsingParentFolderColorClosure = closure
    }
#endif
}

